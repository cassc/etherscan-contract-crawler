// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title NFTKEY Goal Token
 * NFTKEY participation reward token
 */
contract Goal is ERC20, Ownable, ReentrancyGuard {
    using Address for address;

    event Mint(address indexed account, uint256 amount);
    event Redeem(address indexed account, uint256 ethAmount, uint256 amount);
    event AddReward(uint256 amount);

    constructor() ERC20("Goal Token", "GOAL") {}

    uint256 public unitValue = 50000000000000000; // 0.05 is the minimum Goal token unit value
    uint256 public expireTimestamp = 1640995200; // Sat Jan 01 2022 00:00:00 GMT+0000

    /**
     * @dev Update floor unit value of Goal token to be minted
     * @param _newValue new value of Goal token
     */
    function updateUnitValue(uint256 _newValue) external onlyOwner {
        require(_newValue >= 50000000000000000, "Minimum unit value is 0.05");
        require(
            (totalSupply() * _newValue) / 1e18 <= address(this).balance,
            "Can't increase unit value more than total redeemable amount"
        );

        unitValue = _newValue;
    }

    /**
     * @dev Mint Goal to account
     * @param account address to mint tokens to
     * @param amount amount of GOAL tokens to mint
     */
    function mint(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Should not mint to 0 address");
        require(
            ((amount + totalSupply()) * unitValue) / 1e18 <= address(this).balance,
            "Don't have enough fund to mint tokens"
        );

        _mint(account, amount);

        emit Mint(account, amount);
    }

    /**
     * @dev Redeem Goal to ETH
     * @param amount Amount of Goal to redeem for ETH
     * Goal is burnt when redeemed to ETH
     */
    function redeem(uint256 amount) external nonReentrant {
        require(amount > 0, "Redeeming 0 GOAL");
        require(amount <= balanceOf(msg.sender), "Attemping to redeem more than owned GOAL");

        uint256 ethAmount = (amount * unitValue) / 1e18;

        _burn(msg.sender, amount);

        Address.sendValue(payable(msg.sender), ethAmount);

        emit Redeem(msg.sender, ethAmount, amount);
    }

    receive() external payable {
        emit AddReward(msg.value);
    }

    /**
     * @dev withdraw all ETH
     * Withdraw ETH to owner
     */
    function withdraw() external onlyOwner {
        require(block.timestamp >= expireTimestamp, "Can't withdraw fund before expiration");

        Address.sendValue(payable(msg.sender), address(this).balance);
    }
}