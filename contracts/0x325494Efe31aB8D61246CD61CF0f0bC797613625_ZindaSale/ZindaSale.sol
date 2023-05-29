/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract ZindaSale {
    address public tokenAddress;
    address public owner;
    uint256 public tokenPrice = 0.00000009 ether;
    bool private reentrancyLock;
    event TokensPurchased(address buyer, uint256 amount);
    event TokenPriceChanged(uint256 newPrice);

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can perform this action"
        );
        _;
    }

    modifier nonReentrant() {
        require(!reentrancyLock, "Reentrant call");
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    function changeToken(address newToken) public onlyOwner nonReentrant {
        tokenAddress = newToken;
    }

    function buyTokens() external payable nonReentrant {
        uint256 _amount = msg.value / tokenPrice;
        IERC20 token = IERC20(tokenAddress);
        require(
            token.transfer(msg.sender, (_amount * 10 ** 18)),
            "Token transfer failed"
        );

        emit TokensPurchased(msg.sender, _amount);
    }

    function setTokenPrice(uint256 _newPrice) external onlyOwner nonReentrant {
        require(_newPrice > 0, "Price must be greater than zero");
        tokenPrice = _newPrice;

        emit TokenPriceChanged(_newPrice);
    }

    function withdrawEther() external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No Ether to withdraw");

        (bool success, ) = owner.call{value: contractBalance}("");
        require(success, "Failed to withdraw Ether");
    }

    function withdrawTokens(
        address _token,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        IERC20 token = IERC20(_token);
        require(token.transfer(owner, _amount), "Token transfer failed");
    }
}