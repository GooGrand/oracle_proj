import "remix_tests.sol"; 
import "TestnetConsumer.sol";

contract SenderAndValueTest {
    function beforeAll () public 
        strg = new SimpleStorage();
    }
    // Проверяем если значение ноль. Не нашел методов для проверки на пустоту, выбрал этот метод
    function checkValueWavesIs0 () public returns (bool) {
        Assert.equal(strg.getCurrentStateWaves(), 0, "Error. Value is 0");
    }
    function checkValueEthIs0 () public returns (bool) {
        Assert.equal(strg.getCurrentStateEth(), 0, "Error. Value is 0");
    }
}