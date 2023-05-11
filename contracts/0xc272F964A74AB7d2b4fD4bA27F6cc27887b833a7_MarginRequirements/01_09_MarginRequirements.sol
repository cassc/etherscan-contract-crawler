/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.6.10;

pragma experimental ABIEncoderV2;

import {Ownable} from "../packages/oz/Ownable.sol";
import {OtokenInterface} from "../interfaces/OtokenInterface.sol";
import {OracleInterface} from "../interfaces/OracleInterface.sol";
import {AddressBookInterface} from "../interfaces/AddressBookInterface.sol";
import {MarginVault} from "../libs/MarginVault.sol";
import {SafeMath} from "../packages/oz/SafeMath.sol";
import {ERC20Interface} from "../interfaces/ERC20Interface.sol";

/**
 * @title MarginRequirements
 * @author Ribbon Team
 * @notice Contract that defines margin requirements and operations
 */
contract MarginRequirements is Ownable {
    using MarginVault for MarginVault.Vault;
    using SafeMath for uint256;

    OracleInterface public oracle;

    /************************************************
     *  CONSTANTS
     ***********************************************/

    /// @notice Max initial margin value - equivalent to 100%
    uint256 public constant MAX_INITIAL_MARGIN = 100 * 10**2;

    /// @notice Number of decimals in notional variable
    uint256 public constant NOTIONAL_DECIMALS = 6;

    /// @notice Number of decimals in price output from oracle
    uint256 public constant ORACLE_DECIMALS = 8;

    /************************************************
     *  STORAGE
     ***********************************************/

    /// @notice AddressBook module
    address public addressBook;

    ///@dev mapping between a hash of (underlying asset, collateral asset, isPut) and a mapping of an account to an initial margin value
    mapping(bytes32 => mapping(address => uint256)) public initialMargin;
    ///@dev mapping between an account owner and a specific vault id to a maintenance margin value
    mapping(uint256 => uint256) public maintenanceMargin;

    /************************************************
     *  CONSTRUCTOR
     ***********************************************/

    /**
     * @notice constructor
     * @param _addressBook AddressBook address
     */
    constructor(address _addressBook) public {
        require(_addressBook != address(0), "Invalid address book");

        addressBook = _addressBook;

        oracle = OracleInterface(AddressBookInterface(_addressBook).getOracle());
    }

    /**
     * @notice modifier to check if the sender is the Keeper address
     */
    modifier onlyKeeper() {
        require(
            msg.sender == AddressBookInterface(addressBook).getKeeper(),
            "MarginRequirements: Sender is not Keeper"
        );

        _;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice sets the initial margin %
     * @dev can only be called by owner
     * @param _underlying underlying asset address
     * @param _collateralAsset collateral asset address
     * @param _isPut option type the vault is selling
     * @param _account account address
     * @param _initialMargin initial margin percentage (eg. 10% = 10 * 10**2 = 1000)
     */
    function setInitialMargin(
        address _underlying,
        address _collateralAsset,
        bool _isPut,
        address _account,
        uint256 _initialMargin
    ) external onlyOwner {
        require(
            _initialMargin > 0 && _initialMargin <= MAX_INITIAL_MARGIN,
            "MarginRequirements: initial margin cannot be 0 or higher than 100%"
        );
        require(_underlying != address(0), "MarginRequirements: invalid underlying");
        require(_collateralAsset != address(0), "MarginRequirements: invalid collateral");
        require(_account != address(0), "MarginRequirements: invalid account");

        initialMargin[keccak256(abi.encode(_underlying, _collateralAsset, _isPut))][_account] = _initialMargin;
    }

    /**
     * @notice sets the maintenance margin absolute amount
     * @dev can only be called by keeper
     * @param _vaultID id of the vault
     * @param _maintenanceMargin maintenance margin absolute amount with its respective token decimals
     */
    function setMaintenanceMargin(uint256 _vaultID, uint256 _maintenanceMargin) external onlyKeeper {
        require(_maintenanceMargin > 0, "MarginRequirements: maintenance margin cannot be 0");

        maintenanceMargin[_vaultID] = _maintenanceMargin;
    }

    /**
     * @dev updates the configuration of the margin requirements. can only be called by the owner
     */
    function refreshConfiguration() external onlyOwner {
        oracle = OracleInterface(AddressBookInterface(addressBook).getOracle());
    }

    /************************************************
     *  MARGIN OPERATIONS
     ***********************************************/

    /**
     * @notice checks if there is enough collateral to mint the desired amount of otokens
     * @param _account account address
     * @param _notional order notional amount (USD value with 6 decimals)
     * @param _underlying underlying asset address
     * @param _isPut option type the vault is selling
     * @param _collateralAsset collateral asset address
     * @param _collateralAmount collateral amount (with its respective token decimals)
     * @return boolean value stating whether there is enough collateral to mint
     */
    function checkMintCollateral(
        address _account,
        uint256 _notional,
        address _underlying,
        bool _isPut,
        uint256 _collateralAmount,
        address _collateralAsset
    ) external view returns (bool) {
        // retrieve collateral decimals
        uint256 collateralDecimals = uint256(ERC20Interface(_collateralAsset).decimals());

        // retrieve initial margin
        uint256 initialMarginRequired = initialMargin[keccak256(abi.encode(_underlying, _collateralAsset, _isPut))][
            _account
        ];

        // initial margin must have been set up before this call
        require(
            initialMarginRequired > 0,
            "MarginRequirements: initial margin cannot be 0 when checking mint collateral"
        );

        // InitialMargin <= Collateral

        // Starts with:
        // notional (USD) * (initial margin/100) <= collateral (#tokens) * collateral price (in USD)

        // initial margin is dividing by 100 since it is a %. Then, 100 moves to the other equation side multiplying:
        // notional (USD) * initial margin <= collateral (#tokens) * collateral price * 100

        // Remaining values are added to ensure both sides of the equation are scaled equally given they differ in decimal amounts

        return
            _notional.mul(initialMarginRequired).mul(10**collateralDecimals).mul(10**ORACLE_DECIMALS) <=
            _collateralAmount.mul(oracle.getPrice(_collateralAsset)).mul(MAX_INITIAL_MARGIN).mul(10**NOTIONAL_DECIMALS);
    }

    /**
     * @notice checks if there is enough collateral to withdraw the desired amount
     * @param _account account address
     * @param _notional order notional amount (USD value with 6 decimals)
     * @param _withdrawAmount desired amount to withdraw (with its respective token decimals)
     * @param _otokenAddress otoken address
     * @param _vaultID id of the vault
     * @param _vault vault struct
     * @return boolean value stating whether there is enough collateral to withdraw
     */
    function checkWithdrawCollateral(
        address _account,
        uint256 _notional,
        uint256 _withdrawAmount,
        address _otokenAddress,
        uint256 _vaultID,
        MarginVault.Vault memory _vault
    ) external view returns (bool) {
        // retrieve collateral decimals
        uint256 collateralDecimals = uint256(ERC20Interface(_vault.collateralAssets[0]).decimals());

        // avoids subtraction overflow
        if (_withdrawAmount.add(maintenanceMargin[_vaultID]) > _vault.collateralAmounts[0]) {
            return false;
        }

        //     InitialMargin + MaintenanceMargin <= Collateral - WithdrawAmount
        // (=) InitialMargin <= Collateral - WithdrawAmount - MaintenanceMargin

        // Starts with:
        // notional (USD) * (initial margin/100) <= [collateral (#tokens) - withdrawAmount (#tokens) - maintenanceMargin (#tokens)] * collateral price (in USD)

        // initial margin is dividing by 100 since it is a %. Then, 100 moves to the other equation side multiplying:
        // notional (USD) * initial margin <= [collateral (#tokens) - WithdrawAmount (#tokens) - MaintenanceMargin (#tokens)] * collateral price (in USD) * 100

        // Remaining values are added to ensure both sides of the equation are scaled equally given they differ in decimal amounts

        return
            _notional.mul(_getInitialMargin(_otokenAddress, _account)).mul(10**collateralDecimals).mul(
                10**ORACLE_DECIMALS
            ) <=
            (_vault.collateralAmounts[0].sub(_withdrawAmount).sub(maintenanceMargin[_vaultID]))
                .mul(oracle.getPrice(_vault.collateralAssets[0]))
                .mul(MAX_INITIAL_MARGIN)
                .mul(10**NOTIONAL_DECIMALS);
    }

    /**
     * @notice returns the initial margin value (avoids stack too deep)
     * @param _otoken otoken address
     * @param _account account address
     * @return inital margin value
     */
    function _getInitialMargin(address _otoken, address _account) internal view returns (uint256) {
        OtokenInterface otoken = OtokenInterface(_otoken);

        uint256 initialMarginRequired = initialMargin[
            keccak256(abi.encode(otoken.underlyingAsset(), otoken.collateralAsset(), otoken.isPut()))
        ][_account];

        // initial margin must have been set up before this call
        require(
            initialMarginRequired > 0,
            "MarginRequirements: initial margin cannot be 0 when checking withdraw collateral"
        );

        return initialMarginRequired;
    }
}