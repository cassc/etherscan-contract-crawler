// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./interfaces/IERC20.sol";
import "./libraries/SafeERC20.sol";

contract Convert {
    using SafeERC20 for IERC20;

    bool private entered;
    address public owner;
    IERC20 public DC;
    uint256 public snapshotSupply;
    mapping (address => uint256) public balanceOf;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Converted(address indexed sender, uint256 indexed value);
    event Withdrawn(address indexed token, address indexed to, uint256 indexed value);
    event TotalSupplyUpdated(address indexed sender, uint256 indexed totalSupply);

    constructor(address token, uint256 supply) {
        DC = IERC20(token);
        snapshotSupply = supply;

        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier nonReentrant() {
        require(!entered, "reentrant");
        entered = true;
        _;
        entered = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized");
        _;
    }

    function convert(uint256 amount) external nonReentrant {
        require(amount > 0, "invalid amount");
        require(DC.balanceOf(msg.sender) >= amount, "insufficient balance");
        require(DC.allowance(msg.sender, address(this)) >= amount, "insufficient allowance");
        require(DC.totalSupply() <= snapshotSupply, "invalid supply");

        DC.safeTransferFrom(msg.sender, address(this), amount);

        balanceOf[msg.sender] += amount;

        emit Converted(msg.sender, amount);
    }

    function withdraw(address token, address to) external onlyOwner {
        IERC20 erc20 = IERC20(token);
        uint256 balance = erc20.balanceOf(address(this));

        require(balance > 0, "insufficient balance");

        erc20.safeTransfer(to, balance);

        emit Withdrawn(token, to, balance);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    function updateTotalSupply(uint256 totalSupply) external onlyOwner {
        snapshotSupply = totalSupply;
        emit TotalSupplyUpdated(msg.sender, totalSupply);
    }
}