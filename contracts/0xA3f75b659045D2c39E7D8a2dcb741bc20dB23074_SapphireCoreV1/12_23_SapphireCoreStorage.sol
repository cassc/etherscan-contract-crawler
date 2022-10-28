// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {ISapphireOracle} from "../oracle/ISapphireOracle.sol";
import {ISapphireAssessor} from "./ISapphireAssessor.sol";

import {SapphireTypes} from "./SapphireTypes.sol";

 // solhint-disable max-states-count

contract SapphireCoreStorageV1 {

    /* ========== Constants ========== */

    uint256 public constant BASE = 10**18;

    /* ========== Public Variables ========== */

    /**
     * @notice Determines whether the contract is paused or not
     */
    bool public paused;

    /**
     * @notice The details about a vault, identified by the address of the owner
     */
    mapping (address => SapphireTypes.Vault) public vaults;

    /**
    * @notice The high/default collateral ratio for an untrusted borrower.
    */
    uint256 public highCollateralRatio;

    /**
    * @notice The lowest collateral ratio for an untrusted borrower.
    */
    uint256 public lowCollateralRatio;

    /**
     * @notice How much should the liquidation penalty be, expressed as a percentage
     *      with 18 decimals
     */
    uint256 public liquidatorDiscount;

    /**
     * @notice How much of the profit acquired from a liquidation should ARC receive
     */
    uint256 public liquidationArcFee;

    /**
     * @notice The percentage fee that is added as interest for each loan
     */
    uint256 public borrowFee;

    /**
    * @notice The assessor that will determine the collateral-ratio.
    */
    ISapphireAssessor public assessor;

    /**
    * @notice The address which collects fees when liquidations occur.
    */
    address public feeCollector;

    /**
     * @notice The instance of the oracle that reports prices for the collateral
     */
    ISapphireOracle public oracle;

    /**
     * @notice If a erc20 asset is used that has less than 18 decimal places
     *      a precision scalar is required to calculate the correct values.
     */
    mapping(address => uint256) public precisionScalars;

    /**
     * @notice The actual address of the collateral used for this core system.
     */
    address public collateralAsset;

    /**
     * @notice The address of the SapphirePool - the contract where the borrowed tokens come from
     */
    address public borrowPool;

    /**
    * @notice The actual amount of collateral provided to the protocol.
    *      This amount will be multiplied by the precision scalar if the token
    *      has less than 18 decimals precision.
    *
    * Proxy upgrade: restricting this variable as it was not used, and its calculation was incorrect
    */
    uint256 private totalCollateral;

    /**
     * @notice An account of the total amount being borrowed by all depositors. This includes
     *      the amount of interest accrued.
     */
    uint256 public normalizedTotalBorrowed;

    /**
     * @notice The accumulated borrow index. Each time a borrows, their borrow amount is expressed
     *      in relation to the borrow index.
     */
    uint256 public borrowIndex;

    /**
     * @notice The last time the updateIndex() function was called. This helps to determine how much
     *      interest has accrued in the contract since a user interacted with the protocol.
     */
    uint256 public indexLastUpdate;

    /**
     * @notice The interest rate charged to borrowers. Expressed as the interest rate per second and 18 d.p
     */
    uint256 public interestRate;

    /**
     * @notice Ratio determining the portion of the interest that is being distributed to the
     * borrow pool. The remaining of the pool share will go to the feeCollector.
     */
    uint256 public poolInterestFee;

    /**
     * @notice Which address can set interest rates for this contract
     */
    address public interestSetter;

    /**
     * @notice The address that can call `setPause()`
     */
    address public pauseOperator;

    /**
     * @notice The minimum amount which has to be borrowed by a vault. This includes
     *         the amount of interest accrued.
     */
    uint256 public vaultBorrowMinimum;

    /**
     * @notice The maximum amount which has to be borrowed by a vault. This includes
     *      the amount of interest accrued.
     */
    uint256 public vaultBorrowMaximum;

    /**
     * @notice The default borrow limit to be used if a borrow limit proof is not passed
     * in the borrow action. If it is set to 0, then a borrow limit proof is required.
     */
    uint256 public defaultBorrowLimit;

    /**
     * @notice Stores the epoch (of the vault owner) at which it becomes required 
     * for the liquidator to include their score proof
     */
    mapping (address => uint256) public expectedEpochWithProof;

    /* ========== Internal Variables ========== */

    /**
     * @dev The array with protocols' values
     *      Index 0 - The protocol value to be used in the credit score proofs
     *      Index 1 - The protocol value to be used in the borrow limit proofs
     */
    bytes32[] internal _scoreProtocols;
}

// solhint-disable-next-line no-empty-blocks
contract SapphireCoreStorage is SapphireCoreStorageV1 {}