// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// imported contracts and libraries
import {ERC20} from "solmate/tokens/ERC20.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";

// interfaces
import {IERC20Metadata} from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import {IMintableBurnable} from "../../interfaces/IMintableBurnable.sol";
import {IYieldTokenOracle} from "../../interfaces/IYieldTokenOracle.sol";
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
contract ShortDurationYieldCoin is ERC20, IMintableBurnable, OwnableUpgradeable, UUPSUpgradeable {
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20Metadata;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event MinterConfigured(address minter, uint256 amount);

    event FeeRecipientSet(address minter, address newMinter);

    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);

    event OracleSet(address oracle, address newOracle);

    event UnderlyingSet(address token);

    event FeeProcessed(address indexed recipient, uint256 fee);

    event Deposit(address indexed from, uint256 amount);

    event BurnToFiat(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    event TradeToFiat(address indexed recipient, address token, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                         Immutables
    //////////////////////////////////////////////////////////////*/

    /// @notice allowlist manager to check permissions
    IAllowlist public immutable allowlist;

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    /// @notice ***DEPRECATED*** allowlist manager to check permissions
    IAllowlist public _a;

    /// @notice ***DEPRECATED*** the address that is able to mint new tokens
    address public _m;

    /// @notice the address that receives the management fee
    address public feeRecipient;

    /// @notice the address of the token oracle
    IYieldTokenOracle public oracle;

    /// @notice management fee charged on accrued interest
    uint256 public managementFee;

    /// @notice DEPRECATED previously recorded total interest accrued
    uint256 public _cti;

    /*///////////////////////////////////////////////////////////////
                         State Variables V2
    //////////////////////////////////////////////////////////////*/

    IERC20Metadata public underlying;

    /*///////////////////////////////////////////////////////////////
                         State Variables V3
    //////////////////////////////////////////////////////////////*/

    /// @notice the addresses that are able to mint new tokens
    mapping(address => uint256) public minters;

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _allowlist)
        ERC20(_name, _symbol, _decimals)
        initializer
    {
        // solhint-disable-next-line reason-string
        if (_allowlist == address(0)) revert();

        allowlist = IAllowlist(_allowlist);
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(
        string memory _name,
        string memory _symbol,
        address _owner,
        address _minter,
        address _feeRecipient,
        address _oracle,
        address _underlying
    ) external initializer {
        // solhint-disable-next-line reason-string
        if (_owner == address(0)) revert();
        // solhint-disable-next-line reason-string
        if (_minter == address(0)) revert();
        // solhint-disable-next-line reason-string
        if (_feeRecipient == address(0)) revert();
        // solhint-disable-next-line reason-string
        if (_oracle == address(0)) revert();
        // solhint-disable-next-line reason-string
        if (_underlying == address(0)) revert();

        _transferOwnership(_owner);

        name = _name;
        symbol = _symbol;

        minters[_minter] = type(uint256).max;
        feeRecipient = _feeRecipient;
        oracle = IYieldTokenOracle(_oracle);
        underlying = IERC20Metadata(_underlying);
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
    function setMinter(address _minter, uint256 _amount) external {
        _checkOwner();

        if (_minter == address(0)) revert BadAddress();

        emit MinterConfigured(_minter, _amount);

        minters[_minter] = _amount;
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

        oracle = IYieldTokenOracle(_oracle);

        if (oracle.decimals() < decimals) revert BadOracleDecimals();
    }

    /**
     * @notice Sets underlying token
     * @param _token is the address of token
     */
    function setUnderlying(address _token) external {
        _checkOwner();

        if (_token == address(0)) revert BadAddress();

        emit UnderlyingSet(_token);

        underlying = IERC20Metadata(_token);
    }

    function setNameSymbol(string memory _name, string memory _symbol) external {
        _checkOwner();

        name = _name;
        symbol = _symbol;
    }

    /**
     * @notice Processes fees based on accrued interest
     * @dev takes fee based on new interest accumulated since the last time the function was called
     * @param _interest is the balance with 2 decimals of precision
     * @param _price is the last round price of SDYC/USD with 8 decimals of precision
     */
    function processFees(uint256 _interest, uint256 _price) external returns (uint256 fee) {
        if (msg.sender != address(oracle)) revert NoAccess();

        uint256 mgmtFee = managementFee;

        if (mgmtFee == 0) return 0;

        // converting to SDYC decimal {6} + price decimals {8}
        _interest *= 1e12;

        // take fee as percentage of interest in terms of SDYC price
        fee = _interest.mulDivDown(mgmtFee, 100 * FEE_MULTIPLIER * _price);

        _mint(feeRecipient, fee);

        emit FeeProcessed(feeRecipient, fee);
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
        if (minters[msg.sender] < _amount) revert NoAccess();
        _checkPermissions(_to);

        _mint(_to, _amount);
    }

    function burn(uint256 _amount) external override {
        _checkPermissions(msg.sender);

        _burn(msg.sender, _amount);

        emit BurnToFiat(msg.sender, _amount);
    }

    /**
     * @notice burns tokens for a user
     * @dev only callable by minter
     * @param _from The address to burn tokens for
     * @param _amount The amount of tokens to burn
     */
    function burnFor(address _from, uint256 _amount) external {
        if (minters[msg.sender] == 0) revert NoAccess();
        _checkPermissions(_from);

        _burn(_from, _amount);

        emit BurnToFiat(_from, _amount);
    }

    /*///////////////////////////////////////////////////////////////
                    Stable Coin Depositing Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposits a stable coin to mint SDYC
     * @param _amount is the amount of stable coin to deposit
     */
    function deposit(uint256 _amount) external returns (uint256) {
        return _depositFor(msg.sender, _amount);
    }

    /**
     * @notice Deposits a stable coin to mint SDYC to a recipient
     * @param _recipient is the address of the recipient
     * @param _amount is the amount of stable coin to deposit
     */
    function depositFor(address _recipient, uint256 _amount) external returns (uint256) {
        return _depositFor(_recipient, _amount);
    }

    /**
     * @notice Withdraws a stable coin by burning SDYC
     * @param _amount is the amount of SDYC to burn
     */
    function withdraw(uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s) external returns (uint256) {
        return _withdrawTo(msg.sender, _amount, _v, _r, _s);
    }

    /**
     * @notice Withdraws a stable coin by burning SDYC and sends to a recipient
     * @param _recipient is the address of the recipient
     * @param _amount is the amount of SDYC to burn
     */
    function withdrawTo(address _recipient, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s) external returns (uint256) {
        return _withdrawTo(_recipient, _amount, _v, _r, _s);
    }

    function tradeToFiat(address _token, uint256 _amount, address _recipient) external virtual {
        _checkOwner();

        if (!allowlist.isOTC(_recipient)) revert NotPermissioned();

        emit TradeToFiat(_recipient, _token, _amount);

        IERC20Metadata(_token).safeTransfer(_recipient, _amount);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposits a stable coin to mint SDYC to a recipient
     * @param _recipient is the address of the recipient
     * @param _amount is the amount of stable coin to deposit
     */
    function _depositFor(address _recipient, uint256 _amount) internal returns (uint256 amount) {
        if (!allowlist.isSystem(msg.sender)) revert NotPermissioned();
        _checkPermissions(_recipient);

        if (address(underlying) == address(0)) revert BadAddress();

        uint256 underlyingDecimals = underlying.decimals();

        // rounding to 2 decimals
        if (underlyingDecimals > 2) amount = _amount / 10 ** (underlyingDecimals - 2);
        else if (underlyingDecimals < 2) amount = _amount * (10 ** (2 - underlyingDecimals));
        // scaling to 6 decimals
        amount *= 1e4;

        (, int256 answer,,,) = oracle.latestRoundData();
        amount = amount.mulDivDown(1e8, uint256(answer));

        _mint(_recipient, amount);

        emit Deposit(msg.sender, _amount);

        underlying.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Withdraws a stable coin by burning SDYC and sends to a recipient
     * @param _recipient is the address of the recipient
     * @param _amount is the amount of SDYC to burn
     */
    function _withdrawTo(address _recipient, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s)
        internal
        returns (uint256 amount)
    {
        _checkPermissions(msg.sender);
        // Not checking _recipient permissions because it could be a LP
        _assertWithdrawSignature(_recipient, _amount, _v, _r, _s);

        if (address(underlying) == address(0)) revert BadAddress();

        _burn(msg.sender, _amount);

        (, int256 answer,,,) = oracle.latestRoundData();
        amount = _amount.mulDivDown(uint256(answer), 1e8);

        uint256 underlyingDecimals = underlying.decimals();

        // scaling to cents
        amount = amount / 1e4;
        // scaling to underlying decimals
        if (underlyingDecimals > 2) amount = amount * (10 ** (underlyingDecimals - 2));
        else if (underlyingDecimals < 2) amount = amount / (10 ** (2 - underlyingDecimals));

        emit Withdrawal(_recipient, amount);

        underlying.safeTransfer(_recipient, amount);
    }

    function _assertWithdrawSignature(address _to, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s) internal {
        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256("Withdraw(address to,uint256 amount,uint256 nonce)"), _to, _amount, nonces[_to]++
                            )
                        )
                    )
                ),
                _v,
                _r,
                _s
            );

            if (recoveredAddress == address(0) || recoveredAddress != owner()) revert InvalidSignature();
        }
    }

    function _checkPermissions(address _address) internal view {
        if (!allowlist.hasTokenPrivileges(_address)) revert NotPermissioned();
    }
}