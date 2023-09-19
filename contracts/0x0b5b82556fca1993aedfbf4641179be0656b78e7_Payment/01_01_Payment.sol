// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20 {
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint256);
}

contract Payment {
    address payable public owner;
    mapping (uint256 => uint256) public options;

    event PaymentTo(address indexed payer, uint256 indexed id, uint256 purchaseId, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    constructor() payable {
        owner = payable(msg.sender);
    }

    function changeOwner(address payable _owner) external onlyOwner() {
        owner = _owner;
    }

    function setOptions(uint256[] calldata ids, uint256[] calldata prices) external onlyOwner() {
        require(ids.length == prices.length);

        for (uint256 i = 0; i < ids.length; ++i) {
            options[ids[i]] = prices[i];
        }
    }

    function pay(uint256 tokenId, uint256 purchaseId) public payable {
        require(options[purchaseId] > 0 && options[purchaseId] == msg.value, "Not valid purchase");

        (bool success, ) = owner.call{value:msg.value}("");
        require(success, "Transfer failed.");

        emit PaymentTo(address(msg.sender), tokenId, purchaseId, msg.value);
    }

    function pull(IERC20 token) external onlyOwner() {
        if (address(token) == address(0)) {
            (bool success, ) = owner.call{value:address(this).balance}("");
            require(success, "Transfer failed.");
        } else {
            uint256 balance = token.balanceOf(address(this));
            token.transfer(owner, balance);
        }
    }
}