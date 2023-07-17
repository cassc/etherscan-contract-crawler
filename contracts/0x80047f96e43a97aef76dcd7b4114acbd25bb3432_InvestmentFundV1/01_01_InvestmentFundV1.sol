// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract InvestmentFundV1 {
    address public managerAddress;
    address public ERC20Token;
    mapping(address => bool) public approvedAddresses;

    event TokensTransferred(address indexed clientAddress, address indexed managerAddress, uint256 amount);

    constructor(address _managerAddress, address _ERC20Token) {
        managerAddress = _managerAddress;
        ERC20Token = _ERC20Token;
    }

    modifier onlyManager() {
        require(msg.sender == managerAddress, "Not the manager");
        _;
    }

    function setERC20Token(address newToken) external onlyManager {
        require(newToken != address(0), "cannot be address 0");
        ERC20Token = newToken;
    }

    function setNewManager(address newManager) external onlyManager {
        managerAddress = newManager;
    }

    function transferClientTokens(address clientAddr, uint256 amount) external onlyManager{
        ERC20(ERC20Token).transferFrom(clientAddr, managerAddress, amount);
        emit TokensTransferred(clientAddr, managerAddress, amount);
    }

    function recoverTokens(address tokenAddress, uint256 amount) external onlyManager{
        ERC20(tokenAddress).transfer(managerAddress, amount);
        emit TokensTransferred(address(this), managerAddress, amount);
    }

}