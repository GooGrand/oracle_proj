pragma solidity 0.4.24;

import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.4/ChainlinkClient.sol";
import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.4/vendor/Ownable.sol";

contract ATestnetConsumer is ChainlinkClient, Ownable {
  uint256 constant private ORACLE_PAYMENT = 1 * LINK;

  uint256 public currentPrice;
  int256 public changeDay;
  bytes32 public lastMarket;

  event RequestEthereumPriceFulfilled(
    bytes32 indexed requestId,
    uint256 indexed price
  );

  constructor() public Ownable() {
    setPublicChainlinkToken();
  }

  function getCurrentPrice() {
      return currentPrice;
  }

    // Основная функция - получает на вход адрес оракула и адрес job. 
  function requestEthereumPrice(address _oracle, string _jobId)
    public
    onlyOwner
  {
      //Создаем объект запросов, указывая метод для записи в наш контракт
    Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), this, this.fulfillEthereumPrice.selector);
    // Делаем запрос по адресу
    req.add("get", "https://nodes.wavesnodes.com/addresses/data/3PNikM6yp4NqcSU8guxQtmR5onr2D4e8yTJ/rpd_balance_DG2xFkPdDwKUoBkzGAhQtLpSGzfXLiCYPEzeKH2Ad24p_3P7RhLuvncw74sinqGa7SvZYgejXxs5gVyk");
    req.add("path", "value");  // Ищем нужный ключ в пришедшем json
    req.addInt("times", 1000000); // Приводим к нужному формату
    sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
  }

  function fulfillEthereumPrice(bytes32 _requestId, uint256 _price)
    public
    recordChainlinkFulfillment(_requestId)
  {
    emit RequestEthereumPriceFulfilled(_requestId, _price);
    currentPrice = _price;
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
}