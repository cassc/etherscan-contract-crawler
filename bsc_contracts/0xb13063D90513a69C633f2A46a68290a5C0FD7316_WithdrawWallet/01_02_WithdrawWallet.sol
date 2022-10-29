// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WithdrawWallet {
    address owner;
    address solidusToken;

    uint256 password;

    event ChangeOwner(address oldOwner, address newOwner);

    modifier priceGreaterThanZero(uint256 _price) {
        require(_price > 0, "Price cannot be 0");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }

    modifier isbalanceEnough(address _tokenAddress, uint256 _amount) {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        require(balance >= _amount, "balance not enogh");
        _;
    }

    constructor(
        address _owner,
        address _solidusToken,
        uint256 _pasword
    ) {
        owner = _owner;
        solidusToken = _solidusToken;
        password = _pasword;
    }

    function changePassword(uint256 _password) external onlyOwner {
        password = _password;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit ChangeOwner(msg.sender, _owner);
    }

    function tokenWithdraw(uint256 _amount, uint256 _password)
        external
        isbalanceEnough(solidusToken, _amount)
    {
        require(password == _password, "not match");
        IERC20(solidusToken).transfer(msg.sender, _amount);
    }

    function ownerWithdraw(address _tokenAddress, uint256 _amount)
        external
        onlyOwner
        isbalanceEnough(_tokenAddress, _amount)
    {
        IERC20(_tokenAddress).transfer(msg.sender, _amount);
    }

    function tokenTransaction(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IERC20(_tokenAddress).transferFrom(_from, _to, _amount);
    }
}