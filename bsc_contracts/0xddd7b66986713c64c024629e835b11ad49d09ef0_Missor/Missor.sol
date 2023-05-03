/**
 *Submitted for verification at BscScan.com on 2023-05-03
*/

pragma solidity ^0.8.0;

contract Missor {
    string public name = "Missor";
    string public symbol = "Missor";
    uint256 public totalSupply = 100000000 * 10 ** 18;
    uint8 public decimals = 18;
    address public owner;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    bool public isOwnerShipRenounced = false;
    bool public isMintingAllowed = false;
    uint256 public totalBurned = 0;
    uint256 public totalAuthorized = 0;
    uint256 public totalDeauthorized = 0;
    uint256 public buyTax = 1;
    uint256 public sellTax = 2;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    event MintingAllowed();
    event MintingDisabled();
    event Burn(address indexed from, uint256 value);
    event Authorized(address indexed owner, address indexed spender, uint256 value);
    event Deauthorized(address indexed owner, address indexed spender, uint256 value);
    event BuyTaxChanged(uint256 newTax);
    event SellTaxChanged(uint256 newTax);

    constructor() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyAuthorized(address spender, uint256 value) {
        require(allowance[msg.sender][spender] >= value, "Not enough authorized tokens.");
        _;
    }

    modifier notMintingAllowed() {
        require(!isMintingAllowed, "Minting is still allowed.");
        _;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Not enough balance.");
        uint256 tax = value * buyTax / 100;
        balanceOf[msg.sender] -= value + tax;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        emit Transfer(msg.sender, address(0), tax);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public onlyAuthorized(to, value) returns (bool success) {
        require(balanceOf[from] >= value, "Not enough balance.");
        uint256 tax = value * sellTax / 100;
        balanceOf[from] -= value + tax;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        emit Transfer(from, address(0), tax);
        return true;
    }

    function renounceOwnership() public onlyOwner {
        isOwnerShipRenounced = true;
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function allowMinting() public onlyOwner {
        isMintingAllowed = true;
        emit MintingAllowed();
    }

    function disableMinting() public onlyOwner notMintingAllowed {
        isMintingAllowed = false;
        emit MintingDisabled();
    }

    function mint(address to, uint256 value) public onlyOwner notMintingAllowed {
        require(totalSupply + value <= 100000000 * 10 ** uint256(decimals), "Total supply exceeds the limit.");
        balanceOf[to] += value;
        totalSupply += value;
        emit Transfer(address(0), to, value);
    }

    function burn(uint256 value) public {
        require(balanceOf[msg.sender] >= value, "Not enough balance.");
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        totalBurned += value;
        emit Transfer(msg.sender, address(0), value);
        emit Burn(msg.sender, value);
    }

    function authorize(address spender, uint256 value) public {
        require(balanceOf[msg.sender] >= value, "Not enough balance.");
        allowance[msg.sender][spender] += value;
        balanceOf[msg.sender] -= value;
        totalAuthorized += value;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        emit Authorized(msg.sender, spender, value);
    }

    function deauthorize(address spender, uint256 value) public onlyAuthorized(spender, value) {
        allowance[msg.sender][spender] -= value;
        balanceOf[msg.sender] += value;
        totalDeauthorized += value;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        emit Deauthorized(msg.sender, spender, value);
    }

    function changeBuyTax(uint256 newTax) public onlyOwner {
        require(newTax <= 10, "Buy tax cannot exceed 10%.");
        buyTax = newTax;
        emit BuyTaxChanged(newTax);
    }

    function changeSellTax(uint256 newTax) public onlyOwner {
        require(newTax <= 10, "Sell tax cannot exceed 10%.");
        sellTax = newTax;
        emit SellTaxChanged(newTax);
    }
}