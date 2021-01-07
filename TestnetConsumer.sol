{
  uint256 constant private ORACLE_PAYMENT = 1 * LINK;

  uint256 public currentStateWaves;
  uint256 public currentStateEth;
  uint256 public currentStates;
  int256 public changeDay;
  bytes32 public lastMarket;
  
  uint256 public supplyA;
  uint256 public supplyB;
  uint256 public amountA;
  uint256 public amountB;
  uint64 public tolerance;
  int256 public mainAsset;
  uint256 public secondAsset;


  event RequestStateFulfilled(
    bytes32 indexed requestId,
    uint256 indexed price
  );
  

  constructor() public Ownable() {
    setPublicChainlinkToken();
  }

    // Основная функция - получает на вход адрес оракула и адрес job. 
  function requestWavesState(address _oracle, string _jobId)
    public
    onlyOwner
  {
      //Создаем объект запросов, указывая метод для записи в наш контракт
    Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), this, this.fulfillWavesState.selector);
    // Делаем запрос по адресу
    req.add("get", "https://nodes.wavesnodes.com/addresses/data/3PNikM6yp4NqcSU8guxQtmR5onr2D4e8yTJ/rpd_balance_DG2xFkPdDwKUoBkzGAhQtLpSGzfXLiCYPEzeKH2Ad24p_3P7RhLuvncw74sinqGa7SvZYgejXxs5gVyk");
    req.add("path", "value");  // Ищем нужный ключ в пришедшем json
    req.addInt("times", 1000000); // Приводим к нужному формату
    sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
  }

     // Вторая функция получения данных с ethereum
  function requestEthereumState(address _oracle, string _jobId)
    public
    onlyOwner
  {
      //Создаем объект запросов, указывая метод для записи в наш контракт
    Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), this, this.fulfillEthereumState.selector);
    // Делаем запрос по адресу
    req.add("get", "https://supplies.waves.exchange/supplies/USDN");
    req.add("path", "supplies.1.confirmed");  // Ищем нужный ключ в пришедшем json
    req.addInt("times", 1000000); // Приводим к нужному формату
    sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
  }

  function handlePrices(address _oracle, string _jobId)
  public
  {
    requestEthereumState(_oracle, _jobId);
    requestWavesState(_oracle, _jobId);
    currentStates = currentStateWaves - currentStateEth;
  }

  function fulfillEthereumState(bytes32 _requestId, uint256 _price)
    public
    recordChainlinkFulfillment(_requestId)
  {
    emit RequestStateFulfilled(_requestId, _price);
    currentStateEth = _price;
  }
  
    function fulfillWavesState(bytes32 _requestId, uint256 _price)
    public
    recordChainlinkFulfillment(_requestId)
  {
    emit RequestStateFulfilled(_requestId, _price);
    currentStateWaves = _price;
  }

  function getChainlinkToken() public view returns (address) {
    return chainlinkTokenAddress();
  }

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
  }

  function cancelRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunctionId,
    uint256 _expiration
  )
    public
    onlyOwner
  {
    cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
  }

  function stringToBytes32(string memory source) private pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }
    assembly { // solhint-disable-line no-inline-assembly
      result := mload(add(source, 32))
    }
  }
  
//   Вычисляем цены для платформ

  function calculatePriceMainAsset() {
      uint256 k = supplyA * supplyB;
      int256 b = (-1 * (int256(k) / (int256(supplyA) - int256(amountA)))) + int256(supplyB);
      int256 fee = b * int256(3 / 1000); // 0.3 fee of every transaction
      b = b - fee;
      b = int256(1/2) * b;  //1 - tolerance -> 1 - 0.5 (of swop.fi) -> 0.5
      mainAsset = b;
  }
  
  function calculatePriceSecondaryAsset() {
      uint256 k = supplyA * supplyB;
      uint256 a = (k / (supplyB - amountB)) + supplyA;
      uint256 fee = a * uint256(3 / 1000);
      a = a - fee;
      a = uint256(1/2) * a; // (1 - tolerance) * a -> (1 - 0.5) -> 0.5
      secondAsset = a;
  }
}