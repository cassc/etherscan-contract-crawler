// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// imported contracts and libraries
import {ERC20} from "solmate/tokens/ERC20.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";

// interfaces
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IShortDurationYieldCoin} from "../../interfaces/IShortDurationYieldCoin.sol";
import {ISDYCOracle} from "../../interfaces/ISDYCOracle.sol";
import {IAllowlist} from "../../interfaces/IAllowlist.sol";

// errors
import "../../config/constants.sol";
import "../../config/errors.sol";

/**
 * @title   ShortDurationYieldCoin
 * @author  dsshap
 * @dev     Represent the shares of the Short Duration Yield Fund
 *             The value of the token should always be positive.
 */
contract ShortDurationYieldCoin is ERC20, IShortDurationYieldCoin, OwnableUpgradeable, UUPSUpgradeable {
    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    /// @notice allowlist manager to check permissions
    IAllowlist public allowlist;

    /// @notice the address that is able to mint new tokens
    address public minter;

    /// @notice the address that receives the management fee
    address public feeRecipient;

    /// @notice the address of the token oracle
    ISDYCOracle public oracle;

    /// @notice management fee charged on accrued interest
    uint256 public managementFee;

    /// @notice previously recorded total interest accrued
    uint256 public cachedTotalInterest;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event AllowlistSet(address allowlist, address newAllowlist);

    event MinterSet(address minter, address newMinter);

    event FeeRecipientSet(address minter, address newMinter);

    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);

    event OracleSet(address oracle, address newOracle);

    event FeeProcessed(address recipient, uint256 fee);

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol, _decimals) initializer {}

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(
        string memory _name,
        string memory _symbol,
        address _owner,
        address _minter,
        address _feeRecipient,
        address _oracle
    ) external initializer {
        // solhint-disable-next-line reason-string
        if (_owner == address(0)) revert();
        _transferOwnership(_owner);

        name = _name;
        symbol = _symbol;

        // solhint-disable-next-line reason-string
        if (_minter == address(0)) revert();
        if (_feeRecipient == address(0)) revert();
        if (_oracle == address(0)) revert();

        minter = _minter;
        feeRecipient = _feeRecipient;
        oracle = ISDYCOracle(_oracle);
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */

    function _authorizeUpgrade(address /*newImplementation*/ ) internal virtual override {
        _checkOwner();
    }

    /*///////////////////////////////////////////////////////////////
                        Management Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the minter role
     * @param _minter is the address of the new minter
     */
    function setMinter(address _minter) external {
        _checkOwner();

        if (_minter == address(0) || _minter == minter) revert BadAddress();

        emit MinterSet(minter, _minter);

        minter = _minter;
    }

    /**
     * @notice Sets the allowlist contract
     * @param _allowlist is the address of the new allowlist contract
     */
    function setAllowlist(address _allowlist) external {
        _checkOwner();

        emit AllowlistSet(address(allowlist), _allowlist);

        allowlist = IAllowlist(_allowlist);
    }

    /**
     * @notice Sets the new fee recipient
     * @param _feeRecipient is the address of the new fee recipient
     */
    function setFeeRecipient(address _feeRecipient) external {
        _checkOwner();

        if (_feeRecipient == address(0) || _feeRecipient == feeRecipient) revert BadAddress();

        emit FeeRecipientSet(feeRecipient, _feeRecipient);

        feeRecipient = _feeRecipient;
    }

    /**
     * @notice Sets the management fee for the token
     * @param _managementFee is the management fee (18 decimals). ex: 2 * 10 ** 18 = 2%
     */
    function setManagementFee(uint256 _managementFee) external {
        _checkOwner();

        if (_managementFee > 100 * FEE_MULTIPLIER) revert BadFee();

        emit ManagementFeeSet(managementFee, _managementFee);

        managementFee = _managementFee;
    }

    /**
     * @notice Sets the oracle for the token
     * @dev used to fetch interest accrued for calculating fee
     * @param _oracle is the address
     */
    function setOracle(address _oracle) external {
        _checkOwner();

        if (_oracle == address(0) || _oracle == address(oracle)) revert BadAddress();

        emit OracleSet(address(oracle), _oracle);

        oracle = ISDYCOracle(_oracle);
    }

    /**
     * @notice Processes fees based on accrued interest
     * @dev takes fee based on new interest accumulated since the last time the function was called
     */
    function processFee() external returns (uint256 fee) {
        if (managementFee == 0) return 0;

        uint256 totalInterest = oracle.totalInterestAccrued();

        // Cannot underflow because a interest will never be less than previously recorded
        uint256 accumulated;
        unchecked {
            accumulated = totalInterest - cachedTotalInterest;
        }

        if (accumulated > 0) {
            cachedTotalInterest = totalInterest;

            fee = FixedPointMathLib.mulDivDown(accumulated, managementFee, 100 * FEE_MULTIPLIER);

            _mint(feeRecipient, fee);

            emit FeeProcessed(feeRecipient, fee);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        ERC20 Functions
    //////////////////////////////////////////////////////////////*/

    function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
        _checkPermissions(msg.sender);
        _checkPermissions(_to);

        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public virtual override returns (bool) {
        _checkPermissions(_from);
        _checkPermissions(_to);

        return super.transferFrom(_from, _to, _amount);
    }

    function mint(address _to, uint256 _amount) external override {
        _checkMinter();
        _checkPermissions(_to);

        _mint(_to, _amount);
    }

    function burn(uint256 _amount) external override {
        _checkPermissions(msg.sender);

        _burn(msg.sender, _amount);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    function _checkMinter() internal view {
        if (msg.sender != minter) revert NoAccess();
    }

    function _checkPermissions(address _address) internal view {
        if (address(allowlist) != address(0) && !allowlist.isAllowed(_address)) revert NotPermissioned();
    }
}