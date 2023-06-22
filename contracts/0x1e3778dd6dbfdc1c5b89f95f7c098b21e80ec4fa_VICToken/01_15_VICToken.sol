// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title   Victory Impact Token
 * @notice  Burnable, transfer-taxed ERC-20 token
 * @author  Tuxedo Development
 * @custom:developer    BowTiedPickle
 * @custom:developer    BowTiedAnomaly
 */
contract VICToken is ERC20, ERC20Burnable, AccessControl {
    using SafeERC20 for IERC20;

    /// @notice MINTER_ROLE represents the role required to mint new VIC tokens
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice TAX_MANAGER_ROLE represents the role required to manage VIC token transfer taxes
    bytes32 public constant TAX_MANAGER_ROLE = keccak256("TAX_MANAGER_ROLE");

    /// @notice The address that will receive transfer tax
    address public feeReceiver;

    /// @notice The transfer tax rate in basis points, as a percentage of the transferred amount
    uint256 public transferTaxRate;

    /// @notice The maximum transfer tax rate in basis points (100% = 10,000 BPS)
    uint256 public constant MAX_TRANSFER_TAX_RATE = 1000; // 10%

    /// @notice The maximum supply of tokens
    uint256 public constant MAX_SUPPLY = 500_000_000 ether;

    /// @notice Allowable tax statuses
    enum TaxStatus {
        NONE,
        TAXED,
        EXEMPT
    }

    /// @notice The tax statuses of all addresses
    mapping(address => TaxStatus) public status;

    /**
     * @dev     Initializes the VIC token with a given transfer tax rate and sets up role-based access control
     * @dev     The transfer tax rate cannot exceed the maximum transfer tax rate
     * @dev     The admin, minter, and tax manager addresses cannot be the zero address
     * @param   _transferTaxRate    The initial transfer tax rate, expressed as a percentage of the transferred amount
     * @param   _admin              The address that will be assigned the default admin role
     * @param   _minter             The address that will be assigned the minter role
     * @param   _taxManager         The address that will be assigned the tax manager role
     */
    constructor(uint256 _transferTaxRate, address _admin, address _minter, address _taxManager) ERC20("VIC Token", "VIC") {
        require(_admin != address(0) && _minter != address(0) && _taxManager != address(0), "VICToken: zero address");
        require(_transferTaxRate <= MAX_TRANSFER_TAX_RATE, "VICToken: tax rate exceeds max");

        transferTaxRate = _transferTaxRate;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MINTER_ROLE, _minter);
        _grantRole(TAX_MANAGER_ROLE, _taxManager);
    }

    //-----------------------------Minter functions-------------------------------

    /**
     * @notice  Mints new VIC tokens to the specified account
     * @param   _to       The address that will receive the minted tokens
     * @param   _amount   The amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) {
        require(totalSupply() + _amount <= MAX_SUPPLY, "VICToken: Total supply exceeds max supply limit");
        _mint(_to, _amount);
    }

    /**
     * @notice  Mints new VIC tokens to multiple accounts at once
     * @param   _to       An array of addresses that will receive the minted tokens
     * @param   _amount   An array of amounts to mint, where each amount corresponds to the same index in the `_to` array
     */
    function batchMint(address[] calldata _to, uint256[] calldata _amount) external onlyRole(MINTER_ROLE) {
        require(_to.length == _amount.length, "VICToken: array length mismatch");
        for (uint256 i; i < _to.length; ) {
            _mint(_to[i], _amount[i]);
            unchecked {
                ++i;
            }
        }
        require(totalSupply() <= MAX_SUPPLY, "VICToken: Total supply exceeds max supply limit");
    }

    //-----------------------------Admin functions-------------------------------

    /**
     * @notice  Sets the address that will receive transfer tax fees
     * @param   _feeReceiver  The new address to receive transfer tax fees
     */
    function setFeeReceiver(address _feeReceiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_feeReceiver != address(0), "VICToken: feeReceiver is the zero address");
        emit FeeReceiverChanged(feeReceiver, _feeReceiver);
        feeReceiver = _feeReceiver;
    }

    /**
     * @notice  Sets the transfer tax rate for the token
     * @param   _transferTaxRate  The new transfer tax rate
     */
    function setTransferTaxRate(uint256 _transferTaxRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_transferTaxRate <= MAX_TRANSFER_TAX_RATE, "VICToken: transfer tax rate exceeds maximum");
        emit TransferTaxRateChanged(transferTaxRate, _transferTaxRate);
        transferTaxRate = _transferTaxRate;
    }

    /**
     * @notice  Sweeps ERC-20 tokens from this contract to the calling account
     * @param   _token      The address of the token to sweep
     * @param   _receiver   The address to sweep tokens to
     */
    function sweepTokens(IERC20 _token, address _receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(_receiver, balance);
    }

    //-----------------------------Tax Manager functions-------------------------------

    /**
     * @notice  Sets an account's tax status
     * @param   _account    The account to set tax status for
     * @param   _status     The tax status to set for the account
     */
    function setTaxStatus(address _account, TaxStatus _status) external onlyRole(TAX_MANAGER_ROLE) {
        status[_account] = _status;
        emit TaxStatusSet(_account, _status);
    }

    /**
     * @notice  Sets tax status for multiple accounts at once
     * @param   _accounts   The accounts to set tax status for
     * @param   _values     The tax statuses to set for the accounts
     */
    function setTaxStatusBatch(address[] calldata _accounts, TaxStatus[] calldata _values) external onlyRole(TAX_MANAGER_ROLE) {
        require(_accounts.length == _values.length, "VICToken: array length mismatch");

        for (uint256 i; i < _accounts.length; ) {
            status[_accounts[i]] = _values[i];
            emit TaxStatusSet(_accounts[i], _values[i]);
            unchecked {
                ++i;
            }
        }
    }

    //-----------------------------Overrides-------------------------------

    /**
     * @dev Transfers are optionally transfer taxed.
     *
     * If `from` or `to` is tax exempt, no tax is applied.
     * The transfer tax rate cannot exceed the maximum tax rate.
     *
     * If neither `from` nor `to` is tax exempt, the transfer is subject to a transfer tax,
     * which is calculated as `amount` multiplied by `transferTaxRate` and divided by 10,000.
     * The tax amount is transferred to the `feeReceiver` account.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual override {
        uint256 taxAmount;
        TaxStatus fromStatus = status[from];
        TaxStatus toStatus = status[to];

        if (fromStatus != TaxStatus.EXEMPT && toStatus != TaxStatus.EXEMPT) {
            if (fromStatus == TaxStatus.TAXED || toStatus == TaxStatus.TAXED) {
                taxAmount = (amount * transferTaxRate) / 10000;
            }
        }

        if (taxAmount > 0) {
            amount -= taxAmount;
            super._transfer(from, feeReceiver, taxAmount);
        }

        super._transfer(from, to, amount);
    }

    //-----------------------------Events-------------------------------

    /**
     * @notice  Emitted when an account is set as taxed or not taxed
     * @param   account   The account whose tax status is being set
     * @param   value     0 for no tax, 1 for taxed, 2 for exempt
     */
    event TaxStatusSet(address indexed account, TaxStatus value);

    /**
     * @notice  Emitted when the fee receiver address is changed
     * @param   previousFeeReceiver   The previous fee receiver address
     * @param   newFeeReceiver        The new fee receiver address
     */
    event FeeReceiverChanged(address indexed previousFeeReceiver, address indexed newFeeReceiver);

    /**
     * @notice  Emitted when the transfer tax rate is changed
     * @param   previousTransferTaxRate   The previous transfer tax rate
     * @param   newTransferTaxRate        The new transfer tax rate
     */
    event TransferTaxRateChanged(uint256 previousTransferTaxRate, uint256 newTransferTaxRate);
}