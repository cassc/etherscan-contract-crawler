// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../library/Initializable.sol";
import "../library/ReentrancyGuard.sol";
import "../library/Ownable.sol";
import "../library/ERC20.sol";

import "../interface/IInterestRateModelInterface.sol";
import {IControllerInterface} from "../interface/IControllerInterface.sol";

/**
 * @title dForce's lending Token storage Contract
 * @author dForce
 */
contract TokenStorage is Initializable, ReentrancyGuard, Ownable, ERC20 {
    //----------------------------------
    //********* Token Storage **********
    //----------------------------------

    uint256 constant BASE = 1e18;

    /**
     * @dev Whether this token is supported in the market or not.
     */
    bool public constant isSupported = true;

    /**
     * @dev Maximum borrow rate(0.1% per block, scaled by 1e18).
     */
    uint256 constant maxBorrowRate = 0.001e18;

    /**
     * @dev Interest ratio set aside for reserves(scaled by 1e18).
     */
    uint256 public reserveRatio;

    /**
     * @dev Maximum interest ratio that can be set aside for reserves(scaled by 1e18).
     */
    uint256 constant maxReserveRatio = 1e18;

    /**
     * @notice This ratio is relative to the total flashloan fee.
     * @dev Flash loan fee rate(scaled by 1e18).
     */
    uint256 public flashloanFeeRatio;

    /**
     * @notice This ratio is relative to the total flashloan fee.
     * @dev Protocol fee rate when a flashloan happens(scaled by 1e18);
     */
    uint256 public protocolFeeRatio;

    /**
     * @dev Underlying token address.
     */
    IERC20Upgradeable public underlying;

    /**
     * @dev Current interest rate model contract.
     */
    IInterestRateModelInterface public interestRateModel;

    /**
     * @dev Core control of the contract.
     */
    IControllerInterface public controller;

    /**
     * @dev Initial exchange rate(scaled by 1e18).
     */
    uint256 constant initialExchangeRate = 1e18;

    /**
     * @dev The interest index for borrows of asset as of blockNumber.
     */
    uint256 public borrowIndex;

    /**
     * @dev Block number that interest was last accrued at.
     */
    uint256 public accrualBlockNumber;

    /**
     * @dev Total amount of this reserve borrowed.
     */
    uint256 public totalBorrows;

    /**
     * @dev Total amount of this reserves accrued.
     */
    uint256 public totalReserves;

    /**
     * @dev Container for user balance information written to storage.
     * @param principal User total balance with accrued interest after applying the user's most recent balance-changing action.
     * @param interestIndex The total interestIndex as calculated after applying the user's most recent balance-changing action.
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    /**
     * @dev 2-level map: userAddress -> assetAddress -> balance for borrows.
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 chainId, uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x576144ed657c8304561e56ca632e17751956250114636e8c01f64a7f2c6d98cf;
    mapping(address => uint256) public nonces;
}