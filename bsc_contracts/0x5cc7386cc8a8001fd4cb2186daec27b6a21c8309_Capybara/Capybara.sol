/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

// File: contracts/MyToken.sol

// создаем контракт
contract Capybara {
    
    string public name = "Capybara";
    string public constant symbol = "CAP";
    uint256 public totalSupply = 25000000;
    uint256 public decimals = 18;
    uint256 public price = 0.00000015 ether;
    uint256 public minBuyAmount = 1;
    uint256 public minSendAmount = 1;
    address payable public admin = payable(0xCA0D0bebd68Fd7192378D563fc85a30dE112C475);
    uint256 public commission = 1;
    
    mapping(address => uint256) public balanceOf;
    
    // событие для уведомления о новой транзакции
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // функция для отправки токенов
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(_value > 0, "Invalid amount");
        require(_value <= balanceOf[msg.sender], "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    // функция для покупки токенов
    function buy() public payable returns (bool success) {
        require(msg.value > 0, "Invalid amount");
        uint256 amount = msg.value / price;
        require(amount >= minBuyAmount, "Minimum buy amount not reached");
        balanceOf[msg.sender] += amount;
        balanceOf[admin] -= amount;
        emit Transfer(admin, msg.sender, amount);
        return true;
    }
    
    // функция для продажи токенов
    function sell(uint256 _value) public returns (bool success) {
        require(_value > 0, "Invalid amount");
        require(_value <= balanceOf[msg.sender], "Insufficient balance");
        uint256 amount = _value * price;
        require(amount > 0, "Invalid amount");
        require(amount >= commission, "Insufficient commission");
        balanceOf[msg.sender] -= _value;
        balanceOf[admin] += _value;
        uint256 commissionAmount = amount * commission / 100;
        admin.transfer(commissionAmount);
        emit Transfer(msg.sender, admin, _value);
        return true;
    }
    
}