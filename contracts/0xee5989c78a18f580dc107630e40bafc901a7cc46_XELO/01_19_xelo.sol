// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC20Base.sol";

contract XELO is ERC20Base {
    bool private _paused; // Whether token transfers are currently paused
    mapping(address => uint256) private _balances; // A mapping of addresses to their balances
    address[] private _restrictedAccounts; // A list of restricted addresses
    mapping(address => uint8) private _accountsToRestrictions; // A mapping of restricted addresses and their restrictions
    mapping(address => uint256) private _accountsToRestrictionsEndDate; // A mapping of addresses to their restriction end dates
    uint256 private _maxTotalSupply; // Max total supply of tokens
    address private _taxRecipient; // The address that receives tax
    uint256 private _taxPercentage; // The percentage of tax to be paid on transfers

    // Restriction types
    uint8 constant NONE = 0;
    uint8 constant SEND = 1;
    uint8 constant RECEIVE = 2;
    uint8 constant BOTH = 3;

    constructor() ERC20Base("XELO", "XELO") {
        _taxRecipient = owner();
        _taxPercentage = 0;
        _maxTotalSupply = 2000000000000000000000000000;
    }

    // Set the maximum total supply of tokens
    function setMaxTotalSupply(uint256 _newMaxTotalSupply) public onlyOwner {
        require(_newMaxTotalSupply >= totalSupply(), "New max total supply must be greater than or equal to current total supply");
        _maxTotalSupply = _newMaxTotalSupply;
    }

    // Get the maximum total supply of tokens
    function getMaxTotalSupply() public view returns (uint256) {
        return _maxTotalSupply;
    }

    // Mint tokens and add them to the specified address
    function mint(address _to, uint256 _amount) public onlyOwner {
        require(!_paused, "Contract is paused");
        require(canReceive(_to), "Recipient is restricted");
        require(totalSupply() + _amount <= _maxTotalSupply, "Max total supply exceeded");
        _mint(_to, _amount);        
    }

    // Mint tokens and add recipient to the specified address with the specified restriction and end date
    function mintWithRestriction(address _to, uint256 _amount, uint8 _restriction, uint256 _endDate) public onlyOwner {
        mint(_to, _amount);
        setRestriction(_to, _restriction, _endDate);
    }

    // Force mint tokens and add them to the specified address
    function forceMint(address _to, uint256 _amount) public onlyOwner {
        require(totalSupply() + _amount <= _maxTotalSupply, "Max total supply exceeded");
        _mint(_to, _amount);        
    }

    // Mint tokens and add them to multiple addresses
    function batchMint(address[] memory _recipients, uint256[] memory _amounts) public onlyOwner {
        require(!_paused, "Contract is paused");
        require(_recipients.length == _amounts.length, "Array lengths do not match");
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(canReceive(_recipients[i]), "Recipient is restricted");
            totalAmount += _amounts[i];
        }
        require(totalSupply() + totalAmount <= _maxTotalSupply, "Max total supply exceeded");
        for (uint256 i = 0; i < _recipients.length; i++) {
            _mint(_recipients[i], _amounts[i]);
        }
    }

    // Transfer tokens from the sender to the specified address
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(!_paused, "Contract is paused");
        require(canSend(msg.sender), "Sender is restricted");
        require(canReceive(_to), "Recipient is restricted");
        uint256 taxAmount = _value * _taxPercentage / 100;
        uint256 transferAmount = _value - taxAmount;
        _transfer(msg.sender, _to, transferAmount);
        if (taxAmount > 0) {
            _transfer(msg.sender, _taxRecipient, taxAmount);
        }
        return true;
    }

    // Burn tokens from the specified address
    function burn(address _from, uint256 _amount) public onlyOwner {
        require(!_paused, "Contract is paused");
        _burn(_from, _amount);
    }

    // Pause token transfers
    function pause() public onlyOwner {
        require(!_paused, "Already paused");
        _paused = true;
    }

    // Unpause token transfers
    function unpause() public onlyOwner {
        require(_paused, "Not paused");
        _paused = false;
    }

    // Check if token transfers are paused
    function isPaused() public view returns (bool) {
        return _paused;
    }

    function _addRestrictedAccount(address _account) private onlyOwner {
        bool alreadyInList = false;
        for (uint256 i = 0; i < _restrictedAccounts.length; i++) {
            if (_restrictedAccounts[i] == _account) {
                alreadyInList = true;
                break;
            }
        }
        if (!alreadyInList) {
            _restrictedAccounts.push(_account);
        }
    }

    // Restrict the specified address with the specified restriction and end date
    function setRestriction(address _account, uint8 _restriction, uint256 _endDate) public onlyOwner {
        require(_account != address(0), "Cannot restrict zero address");
        require(_account != owner(), "Cannot restrict owner");
        require(_restriction >= NONE && _restriction <= BOTH, "Invalid restriction");
        _addRestrictedAccount(_account);
        _accountsToRestrictions[_account] = _restriction;
        _accountsToRestrictionsEndDate[_account] = _endDate;
    }

    // Function to return all restrictions for all users
    function getRestrictions() public onlyOwner view returns (address[] memory, uint8[] memory, uint256[] memory) {
        address[] memory accounts = new address[](_restrictedAccounts.length);
        uint8[] memory restrictions = new uint8[](_restrictedAccounts.length);
        uint256[] memory endDates = new uint256[](_restrictedAccounts.length);
        for (uint256 i = 0; i < _restrictedAccounts.length; i++) {
            address account = _restrictedAccounts[i];
            uint8 restriction = _accountsToRestrictions[account];
            uint256 endDate = _accountsToRestrictionsEndDate[account];
            accounts[i] = account;
            restrictions[i] = restriction;
            endDates[i] = endDate;
        }
        return (accounts, restrictions, endDates);
    }

    // Check if the specified address is restricted with the specified restriction
    function isRestricted(address _account, uint8 _restriction) public view returns (bool) {
        // If the account is in the restriction list, but not restricted (restriction is NONE)
        // Doesn't matter which restriction we require
        if (_accountsToRestrictions[_account] == NONE) {
            return false;
        }
        // If restriction is over
        if (_accountsToRestrictionsEndDate[_account] < block.timestamp) {
            return false;
        }
        // If the account is restricted from both sending and receiving
        if (_accountsToRestrictions[_account] == BOTH) {
            return true;
        }
        // If restriction is _restriction and end date is not over
        if (_accountsToRestrictions[_account] == _restriction) {
            return true;
        }
        return false;
    }

    // Check if the specified address can send tokens
    function canSend(address _account) public view returns (bool) {
        return !isRestricted(_account, SEND);
    }

    // Check if the specified address can receive tokens
    function canReceive(address _account) public view returns (bool) {
        return !isRestricted(_account, RECEIVE);
    }

    // Set the tax recipient address
    function setTaxRecipient(address _newTaxRecipient) public onlyOwner {
        _taxRecipient = _newTaxRecipient;
    }

    // Set the tax percentage
    function setTaxPercentage(uint256 _newTaxPercentage) public onlyOwner {
        require(_newTaxPercentage <= 100, "Tax percentage must be less than or equal to 100");
        _taxPercentage = _newTaxPercentage;
    }

    function getTaxInfo() public onlyOwner view returns (address, uint256) {
        return (_taxRecipient, _taxPercentage);
    }

    /* =================== OVERRIDES =================== */

    function mintTo(address, uint256) public pure override {
        require(false, "Use mint function instead");
    }

    function burn(uint256) public pure override {
        require(false, "Use burn function with address instead");
    }

    function multicall(bytes[] calldata) external pure override returns (bytes[] memory) {
        require(false, "Multicall not supported");
        return new bytes[](0);
    }

    function permit(address, address, uint256, uint256, uint8, bytes32, bytes32) public pure override {
        require(false, "Permit not supported");
    }
}