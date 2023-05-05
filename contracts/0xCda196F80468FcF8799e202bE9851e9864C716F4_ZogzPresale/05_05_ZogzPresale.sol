// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IZogzEditions {
    function mintBatch(
        address __account,
        uint256[] memory __ids,
        uint256[] memory __amounts
    ) external;
}

contract ZogzPresale is Ownable, Pausable, ReentrancyGuard {
    error AmountExceedsTransactionLimit();
    error Forbidden();
    error HasEnded();
    error HasNotStarted();
    error IncorrectPrice();
    error InvalidAddress();
    error InvalidAmount();
    error WithdrawFailed();

    event FullSetPurchase(address __account, uint256 __amount);
    event TransactionLimit(uint256 __transactionLimit);
    event Withdraw(uint256 __amount);

    uint256 public constant PRICE = 1.234 ether;
    uint256 public constant SUPPLY = 100;

    uint256 public constant START = 1683306000;
    uint256 public constant END = 1683565199;

    uint256 public transactionLimit = 10;

    IZogzEditions public _zogzEditionsContract;

    constructor(address __zogzEditionsContractAddress) {
        if (__zogzEditionsContractAddress == address(0)) {
            revert InvalidAddress();
        }
        _zogzEditionsContract = IZogzEditions(__zogzEditionsContractAddress);
    }

    ////////////////////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////////////////////

    modifier onlyEOA() {
        if (tx.origin != msg.sender) {
            revert Forbidden();
        }
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    // OWNER
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Used to pause sales.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Used to unpause sales.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Used to set new transaction limit.
     */
    function setTransactionLimit(
        uint256 __transactionLimit
    ) external onlyOwner {
        transactionLimit = __transactionLimit;

        emit TransactionLimit(__transactionLimit);
    }

    /**
     * @dev Used to withdraw funds from the contract.
     */
    function withdraw(uint256 __amount) external onlyOwner {
        (bool success, ) = owner().call{value: __amount}("");

        if (!success) revert WithdrawFailed();

        emit Withdraw(__amount);
    }

    /**
     * @dev Used to withdraw all funds from the contract.
     */
    function withdrawAll() external onlyOwner {
        uint256 amount = address(this).balance;

        (bool success, ) = owner().call{value: amount}("");

        if (!success) revert WithdrawFailed();

        emit Withdraw(amount);
    }

    ////////////////////////////////////////////////////////////////////////////
    // WRITES
    ////////////////////////////////////////////////////////////////////////////

    function buyFullSet(
        uint256 __amount
    ) external payable nonReentrant whenNotPaused onlyEOA {
        if (__amount == 0) {
            revert InvalidAmount();
        }

        if (__amount > transactionLimit) {
            revert AmountExceedsTransactionLimit();
        }

        if (msg.value != __amount * PRICE) {
            revert IncorrectPrice();
        }

        if (block.timestamp < START) {
            revert HasNotStarted();
        }

        if (block.timestamp > END) {
            revert HasEnded();
        }

        uint256[] memory ids = new uint256[](SUPPLY);
        uint256[] memory amounts = new uint256[](SUPPLY);
        for (uint256 i = 0; i < SUPPLY; i++) {
            ids[i] = i + 1;
            amounts[i] = __amount;
        }

        _zogzEditionsContract.mintBatch(_msgSender(), ids, amounts);

        emit FullSetPurchase(_msgSender(), __amount);
    }
}