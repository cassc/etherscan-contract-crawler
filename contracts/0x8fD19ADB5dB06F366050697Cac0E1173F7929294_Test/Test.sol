/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

pragma solidity ^0.8.7;

abstract contract Ownable {
    address _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Test is Ownable {

    ERC20 public token;

    constructor(address tokenAddress) {
        token = ERC20(tokenAddress);
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
    }

    function depositUSDT(
        address clientAddress,
        uint256 amount
    ) external {

        require(amount > 0, "Bad amount");

        token.transferFrom(clientAddress, address(this), amount);

    }

    function withdrawalUSDT (
        address clientAddress,
        uint256 amount
    ) external onlyOwner {

        require(amount > 0, "Bad amount");

        token.transfer(clientAddress, amount);

    }


}