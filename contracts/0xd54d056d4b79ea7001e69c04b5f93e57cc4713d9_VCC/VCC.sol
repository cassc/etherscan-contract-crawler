/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

pragma solidity ^0.4.24;

library Math {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if(a == 0) { return 0; }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    
    address public owner_;
    mapping(address => bool) locked_;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public { owner_ = 0xB87bd5bBC5cC4B41E1FCb890Cb3EAF9BCa3b3044; }

    modifier onlyOwner() {
        require(msg.sender == owner_);
        _;
    }

    modifier locked() {
        require(!locked_[msg.sender]);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner_, newOwner);
        owner_ = newOwner;
    }

    function lock(address owner) public onlyOwner {
        locked_[owner] = true;
    }

    function unlock(address owner) public onlyOwner {
        locked_[owner] = false;
    }
}


contract ERC20Token {
    
    using Math for uint256;
    
    event Burn(address indexed burner, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 totalSupply_;
    mapping(address => uint256) balances_;
    mapping (address => mapping (address => uint256)) internal allowed_;

    function totalSupply() public view returns (uint256) { return totalSupply_; }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances_[msg.sender]);

        balances_[msg.sender] = balances_[msg.sender].sub(value);
        balances_[to] = balances_[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) { return balances_[owner]; }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {

        require(to != address(0));
        require(value <= balances_[from]);
        require(value <= allowed_[from][msg.sender]);

        balances_[from] = balances_[from].sub(value);
        balances_[to] = balances_[to].add(value);
        emit Transfer(from, to, value);
        
        allowed_[from][msg.sender] = allowed_[from][msg.sender].sub(value);
        emit Approval(from, msg.sender, allowed_[from][msg.sender]);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed_[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed_[owner][spender];
    }

    function burn(uint256 value) public {
        require(value <= balances_[msg.sender]);
        address burner = msg.sender;
        balances_[burner] = balances_[burner].sub(value);
        emit Transfer(burner, burner, value);
        totalSupply_ = totalSupply_.sub(value);
        emit Burn(burner, value);
    }    
}

contract VCC is Ownable, ERC20Token {

    using Math for uint;

    uint8 constant public decimals = 18;
    string constant public symbol = "28VCC";
    string constant public name = "28VCC";
    
    constructor(address company, uint amount) public {
        totalSupply_ = amount;
        initSetting(company, totalSupply_);
    }

    function withdrawTokens(address cont) external onlyOwner {
        VCC tc = VCC(cont);
        tc.transfer(owner_, tc.balanceOf(this));
    }    

    function initSetting(address addr, uint amount) internal returns (bool) {
        balances_[addr] = amount;
        emit Transfer(address(0x0), addr, amount);
        return true;
    }

    function transfer(address to, uint256 value) public locked returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public locked returns (bool) {
        require(!locked_[from]);
        return super.transferFrom(from, to, value);
    }
}