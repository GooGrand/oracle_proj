// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.7/ChainlinkClient.sol";

contract ATestnetConsumer is ChainlinkClient {
  uint256 constant private ORACLE_PAYMENT =  0.1 * 10 ** 18; // 0.1 LINK;

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
  

  constructor() {
    setPublicChainlinkToken();
  }

    // Основная функция - получает на вход адрес оракула и адрес job. 
  function requestWavesState(address _oracle, string memory _jobId)
    public
  {
      //Создаем объект запросов, указывая метод для записи в наш контракт
    Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), address(this), this.fulfillWavesState.selector);
    sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
  }

     // Вторая функция получения данных с ethereum
  function requestEthereumState(address _oracle, string memory _jobId)
    public
  {
      //Создаем объект запросов, указывая метод для записи в наш контракт
    Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), address(this), this.fulfillEthereumState.selector);
    // Делаем запрос по адресу
    sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
  }

  function handlePrices(address _oracle, string memory _jobId)
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

  function withdrawLink() public {
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

  function getCurrentSupplies(address _oracle, string memory _jobId)
  public
  {
    Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), address(this), this.fulfillEthereumState.selector);
    sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
  }

  function calculatePriceMainAsset() 
  public
  {
      uint256 k = supplyA * supplyB;
      int256 b = (-1 * (int256(k) / (int256(supplyA) - int256(amountA)))) + int256(supplyB);
      int256 fee = 3 * b / 1000; // 0.3 fee of every transaction
      b = b - fee;
      b = b / 2;  //1 - tolerance -> 1 - 0.5 (of swop.fi) -> 0.5
      mainAsset = b;
  }
  
  function calculatePriceSecondaryAsset() 
  public
  {
      uint256 k = supplyA * supplyB;
      uint256 a = (k / (supplyB - amountB)) + supplyA;
      uint256 fee = 3 * a / 1000;
      a = a - fee;
      a = a / 2; // (1 - tolerance) * a -> (1 - 0.5) -> 0.5
      secondAsset = a;
  }
}