// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title  LoanCurrencyWhitelist
 * @author Solarr
 * @notice
 */
contract LoanCurrencyWhitelist is Ownable {
    /* ********** */
    /* DATA TYPES */
    /* ********** */

    /**
     * @param loanCurrencyAddress - The address of the smart contract of the LoanCurrency.
     * @param name - The name the nft LoanCurrency.
     * @param activeDate - The date that the LoanCurrency is listed.
     */
    struct LoanCurrency {
        address loanCurrencyAddress;
        string name;
        uint256 activeDate;
    }

    /* ********** */
    /* STORAGE */
    /* ********** */

    bool private INITIALIZED = false;

    mapping(address => LoanCurrency) public whitelistedLoanCurrencys; // LoanCurrencys information that have been added to whitelist

    /* *********** */
    /* EVENTS */
    /* *********** */

    /**
     * @notice This event is fired whenever the LoanCurrency is listed to Whitelist.
     */
    event LoanCurrencyListed(address, string, uint256);

    /**
     * @notice This event is fired whenever the LoanCurrency is unlisted from Whitelist.
     */
    event LoanCurrencyUnlisted(address, string, uint256);

    /* *********** */
    /* MODIFIERS */
    /* *********** */

    modifier whenNotZeroLoanCurrencyAddress(address _loanCurrencyAddress) {
        require(
            _loanCurrencyAddress != address(0),
            "LoanCurrency address must not be zero address"
        );
        _;
    }

    modifier whenLoanCurrencyWhitelisted(address _loanCurrencyAddress) {
        require(
            _isLoanCurrencyWhitelisted(_loanCurrencyAddress),
            "LoanCurrency is not whitelisted"
        );
        _;
    }

    modifier whenLoanCurrencyNotWhitelisted(address _loanCurrencyAddress) {
        require(
            !_isLoanCurrencyWhitelisted(_loanCurrencyAddress),
            "LoanCurrency already whitelisted"
        );
        _;
    }

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /* *********** */
    /* RECEIVE FUNCTIONS */
    /* *********** */

    /* *********** */
    /* EXTERNAL FUNCTIONS */
    /* *********** */

    function initialize() external {
        require(!INITIALIZED, "Contract is already initialized");
        _transferOwnership(msg.sender);
        INITIALIZED = true;
    }

    /**
     * @notice This function can be called by Owner to list LoanCurrency to Whitelist.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     * @param _name - The name of the LoanCurrency.
     */
    function whitelistLoanCurrency(
        address _loanCurrencyAddress,
        string calldata _name
    ) external {
        _whitelistLoanCurrency(_loanCurrencyAddress, _name);
    }

    /**
     * @notice This function can be called by Owner to unlist LoanCurrency from Whitelist.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     */
    function unwhitelistLoanCurrency(address _loanCurrencyAddress) external {
        _unwhitelistLoanCurrency(_loanCurrencyAddress);
    }

    /**
     * @notice This function can be called by Anyone to know the LoanCurrency is listed in Whitelist or not.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     *
     * @return Returns whether the LoanCurrency is whitelisted
     */
    function isLoanCurrencyWhitelisted(address _loanCurrencyAddress)
        external
        view
        returns (bool)
    {
        return _isLoanCurrencyWhitelisted(_loanCurrencyAddress);
    }

    /* *********** */
    /* PUBLIC FUNCTIONS */
    /* *********** */

    /* *********** */
    /* INTERNAL FUNCTIONS */
    /* *********** */

    /**
     * @notice This function can be called by Owner to list LoanCurrency to Whitelist.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     * @param _name - The name of the LoanCurrency.
     */
    function _whitelistLoanCurrency(
        address _loanCurrencyAddress,
        string calldata _name
    )
        internal
        whenNotZeroLoanCurrencyAddress(_loanCurrencyAddress)
        onlyOwner
        whenLoanCurrencyNotWhitelisted(_loanCurrencyAddress)
    {
        // create LoanCurrency instance and list to whitelist
        whitelistedLoanCurrencys[_loanCurrencyAddress] = LoanCurrency(
            _loanCurrencyAddress,
            _name,
            block.timestamp
        );

        emit LoanCurrencyListed(_loanCurrencyAddress, _name, block.timestamp);
    }

    /**
     * @notice This function can be called by Owner to unlist LoanCurrency from Whitelist.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     */
    function _unwhitelistLoanCurrency(address _loanCurrencyAddress)
        internal
        whenNotZeroLoanCurrencyAddress(_loanCurrencyAddress)
        onlyOwner
        whenLoanCurrencyWhitelisted(_loanCurrencyAddress)
    {
        // remove LoanCurrency instance and unlist from whitelist
        LoanCurrency memory loanCurrency = whitelistedLoanCurrencys[
            _loanCurrencyAddress
        ];
        string memory name = loanCurrency.name;
        delete whitelistedLoanCurrencys[_loanCurrencyAddress];

        emit LoanCurrencyUnlisted(_loanCurrencyAddress, name, block.timestamp);
    }

    /**
     * @notice This function can be called by Anyone to know the LoanCurrency is listed in Whitelist or not.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     *
     * @return Returns whether the LoanCurrency is whitelisted
     */
    function _isLoanCurrencyWhitelisted(address _loanCurrencyAddress)
        internal
        view
        returns (bool)
    {
        return
            whitelistedLoanCurrencys[_loanCurrencyAddress]
                .loanCurrencyAddress != address(0);
    }

    /* *********** */
    /* PRIVATE FUNCTIONS */
    /* *********** */
}