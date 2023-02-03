// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GalaxyArenaToken is ERC20Upgradeable, PausableUpgradeable, OwnableUpgradeable {
    address public feeCollector;
    uint256 public defaultFee;
    uint256 public precision;
    mapping(address => uint256) public feeOverride;
    mapping(address => bool) public isBlocked;

    event AddressBlocked(address indexed addr);
    event AddressUnblocked(address indexed addr);
    event FeeTaken(address indexed sender, address indexed recipient, uint256 recipientAmount, uint256 feeAmount);
    event FeeCollectorSet(address indexed feeCollector);
    event FeeParamsSet(uint256 defaultFee, uint256 precision);

    function initialize(
        string calldata _tokenName,
        string calldata _tokenSymbol,
        uint256 _totalSupply,
        uint256 _defaultFee,
        uint256 _precision,
        address _feeCollector
    ) external initializer {
        __ERC20_init(_tokenName, _tokenSymbol);
        __Pausable_init();
        __Ownable_init();
        _mint(_msgSender(), _totalSupply);
        _setFeeParams(_defaultFee, _precision);
        _setFeeCollector(_feeCollector);
    }

    /**
     * @notice  Function to set fee parameters of token
     */
    function setFeeParams(uint256 _defaultFee, uint256 _precision) external onlyOwner {
        _setFeeParams(_defaultFee, _precision);
    }

    /**
     * @notice  Internal function to set fee parameters of token
     */
    function _setFeeParams(uint256 _defaultFee, uint256 _precision) internal {
        defaultFee = _defaultFee;
        precision = _precision;
        emit FeeParamsSet(_defaultFee, _precision);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     * - 'from' address must not be blocked.
     *
     * Affects only 'transfer' & 'transferFrom'
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "Token paused.");
        require(!isBlocked[from], "Sender address blocked.");
        require(!isBlocked[to], "Recipient address blocked.");
    }

    /**
     * @notice  Function to pause token contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice  Function to unpause token contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice  Function used to block transfers from malicious address in case of breach
     *
     * @param   addressToBlock is an address that needs to be blocked
     */
    function blockAddress(address addressToBlock) external onlyOwner {
        isBlocked[addressToBlock] = true;
        emit AddressBlocked(addressToBlock);
    }

    /**
     * @notice  Function used to unblock an address in case of false block
     *
     * @param   addressToUnblock is an address that needs to be unblocked
     */
    function unblockAddress(address addressToUnblock) external onlyOwner {
        delete isBlocked[addressToUnblock];
        emit AddressUnblocked(addressToUnblock);
    }

    /**
     * @notice  Function for setting the address of the fee collector
     *
     * @param   _feeCollector is address of the fee collector
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        _setFeeCollector(_feeCollector);
    }

    /**
     * @notice  Internal function to set the feeCollector address
     */
    function _setFeeCollector(address _feeCollector) internal {
        require(_feeCollector != address(0x00), "Invalid address.");
        feeCollector = _feeCollector;
        emit FeeCollectorSet(_feeCollector);
    }

    /**
     * @notice  Function for setting the override fee for different addresses
     * @param   accounts is array of addresses to override fees for
     * @param   fees is array of the override fees
     */
    function overrideFees(address[] calldata accounts, uint256[] calldata fees) external onlyOwner {
        require(accounts.length == fees.length, "Array length mismatch.");
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 fee = fees[i];

            require(account != address(0x00), "Invalid address.");
            require(fee <= precision, "Invalid fee value.");

            if (fee == 0) {
                delete feeOverride[account];
            } else {
                feeOverride[account] = fee;
            }
        }
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        (uint256 fee, uint256 recipientAmount) = _getFeeValues(sender, recipient, amount);

        if (fee != 0) {
            super._burn(sender, fee);
            // if fees should be enabled later, uncomment this line and delete burn above
            // super._transfer(sender, feeCollector, fee);
            super._transfer(sender, recipient, recipientAmount);
            // emit FeeTaken(sender, recipient, recipientAmount, fee);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    /**
     * @notice  Get the fee values
     */
    function _getFeeValues(address sender, address recipient, uint256 amount) internal view returns (uint256, uint256) {
        if (precision != 0 && feeOverride[sender] != precision && feeOverride[recipient] != precision) {
            uint256 feePercent = _getFeePercent(sender, recipient);
            uint256 feeAmount = (amount * feePercent) / precision;
            uint256 recipientAmount = amount - feeAmount;
            return (feeAmount, recipientAmount);
        } else {
            return (0, amount);
        }
    }

    /**
     * @notice  Get the lower fee between the sender and the recipient or the default fee
     */
    function _getFeePercent(address sender, address recipient) internal view returns (uint256) {
        uint256 feePercent;
        if (feeOverride[sender] != 0) {
            if (feeOverride[recipient] != 0) {
                feePercent = feeOverride[sender] <= feeOverride[recipient]
                    ? feeOverride[sender]
                    : feeOverride[recipient];
            } else {
                feePercent = feeOverride[sender];
            }
        } else {
            feePercent = feeOverride[recipient] != 0 ? feeOverride[recipient] : defaultFee;
        }

        return feePercent;
    }

    uint256[50] private __gap;
}