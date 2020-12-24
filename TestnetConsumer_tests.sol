import "remix_tests.sol"; 
import "TestnetConsumer.sol";

contract SenderAndValueTest {
    function beforeAll () public 
        strg = new SimpleStorage();
    }
    // Проверяем если значение ноль. Не нашел методов для проверки на пустоту, выбрал этот метод
    function checkValueIs0 () public returns (bool) {
        Assert.equal(strg.getCurrentPrice(), 0, "Error. Value is 0");
    }
}