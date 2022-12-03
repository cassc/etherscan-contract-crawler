// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBOX {
    function mintBatch(address account_, uint256 amount_) external returns (uint256[] memory tokenIds);
}

contract BoxMint is Ownable {
    IBOX public nft;
    uint totalAmount = 500;
    uint price = 1e16;
    uint UserMax = 2;
    mapping(address => uint) public publicCanMint;
    mapping(address => bool) public whiteList;
    uint public totalMint;
    uint public startTime;
    constructor(address nft_) {
        nft = IBOX(nft_);
        startTime = 1669971600;
    }

    modifier onlyEOA{
        require(msg.sender == tx.origin, "not eoa");
        _;
    }

    function setWhiteList(address[] memory addr, bool b) external onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            whiteList[addr[i]] = b;
        }
    }

    function setStartTime(uint times) external onlyOwner {
        startTime = times;
    }

    function BuyBox(uint count) external payable onlyEOA {
        require(block.timestamp >= startTime, 'not start yet');
        require(whiteList[msg.sender], 'not whiteList');
        require(msg.value == price * count, "not enough eth");
        require(totalMint + count <= totalAmount, "exceed total amount");
        require(publicCanMint[msg.sender] + count <= UserMax, 'out mint amount');
        publicCanMint[msg.sender] += count;
        nft.mintBatch(msg.sender, count);
        totalMint += count;
    }

    receive() external payable {}

    function divest(address token_, address payee_, uint value_) external onlyOwner {
        if (token_ == address(0)) {
            payable(payee_).transfer(value_);
        } else {
            IERC20(token_).transfer(payee_, value_);
        }
    }


}