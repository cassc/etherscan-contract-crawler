/**
 *Submitted for verification at Etherscan.io on 2023-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


interface ILERC20 {
    function name() external view returns (string memory);
    function admin() external view returns (address);
    function getAdmin() external view returns (address);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool);
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool);
    
    function transferOutBlacklistedFunds(address[] calldata _from) external;
    function setLosslessAdmin(address _newAdmin) external;
    function transferRecoveryAdminOwnership(address _candidate, bytes32 _keyHash) external;
    function acceptRecoveryAdminOwnership(bytes memory _key) external;
    function proposeLosslessTurnOff() external;
    function executeLosslessTurnOff() external;
    function executeLosslessTurnOn() external;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event NewAdmin(address indexed _newAdmin);
    event NewRecoveryAdminProposal(address indexed _candidate);
    event NewRecoveryAdmin(address indexed _newAdmin);
    event LosslessTurnOffProposal(uint256 _turnOffDate);
    event LosslessOff();
    event LosslessOn();
}

interface ILssController {
    // function getLockedAmount(ILERC20 _token, address _account)  returns (uint256);
    // function getAvailableAmount(ILERC20 _token, address _account) external view returns (uint256 amount);
    function whitelist(address _adr) external view returns (bool);
    function blacklist(address _adr) external view returns (bool);
    function admin() external view returns (address);
    function recoveryAdmin() external view returns (address);

    function setAdmin(address _newAdmin) external;
    function setRecoveryAdmin(address _newRecoveryAdmin) external;

    function setWhitelist(address[] calldata _addrList, bool _value) external;
    function setBlacklist(address[] calldata _addrList, bool _value) external;

    function beforeTransfer(address _sender, address _recipient, uint256 _amount) external;
    function beforeTransferFrom(address _msgSender, address _sender, address _recipient, uint256 _amount) external;
    function beforeApprove(address _sender, address _spender, uint256 _amount) external;
    function beforeIncreaseAllowance(address _msgSender, address _spender, uint256 _addedValue) external;
    function beforeDecreaseAllowance(address _msgSender, address _spender, uint256 _subtractedValue) external;
    function beforeMint(address _to, uint256 _amount) external;
    function beforeBurn(address _account, uint256 _amount) external;
    function afterTransfer(address _sender, address _recipient, uint256 _amount) external;

    event AdminChange(address indexed _newAdmin);
    event RecoveryAdminChange(address indexed _newAdmin);
    event PauseAdminChange(address indexed _newAdmin);
}

/// @title Lossless Controller Contract
/// @notice The controller contract is in charge of the communication and senstive data among all Lossless Environment Smart Contracts
contract LosslessControllerV4 is ILssController, Context {
    // IMPORTANT!: For future reference, when adding new variables for following versions of the controller. 
    // All the previous ones should be kept in place and not change locations, types or names.
    // If thye're modified this would cause issues with the memory slots.

    address override public admin;
    address override public recoveryAdmin;

    // --- V3 VARIABLES ---

    mapping(address => bool) override public whitelist;
    mapping(address => bool) override public blacklist;

    constructor(address _admin, address _recoveryAdmin) {
        admin = _admin;
        recoveryAdmin = _recoveryAdmin;
    }

// --- MODIFIERS ---

    /// @notice Avoids execution from other than the Recovery Admin
    modifier onlyRecoveryAdmin() {
        require(msg.sender == recoveryAdmin, "LSS: Must be recoveryAdmin");
        _;
    }

    /// @notice Avoids execution from other than the Lossless Admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "LSS: Must be admin");
        _;
    }


    // --- ADMINISTRATION ---

    /// @notice This function sets a new admin
    /// @dev Only can be called by the Recovery admin
    /// @param _newAdmin Address corresponding to the new Lossless Admin
    function setAdmin(address _newAdmin) override public onlyRecoveryAdmin {
        require(_newAdmin != address(0), "LERC20: Cannot set same address");
        emit AdminChange(_newAdmin);
        admin = _newAdmin;
    }

    /// @notice This function sets a new recovery admin
    /// @dev Only can be called by the previous Recovery admin
    /// @param _newRecoveryAdmin Address corresponding to the new Lossless Recovery Admin
    function setRecoveryAdmin(address _newRecoveryAdmin) override public onlyRecoveryAdmin {
        require(_newRecoveryAdmin != address(0), "LERC20: Cannot set same address");
        emit RecoveryAdminChange(_newRecoveryAdmin);
        recoveryAdmin = _newRecoveryAdmin;
    }

    // --- V3 SETTERS ---

    /// @notice This function removes or adds an array of addresses from the whitelst
    /// @dev Only can be called by the Lossless Admin, only Lossless addresses 
    /// @param _addrList List of addresses to add or remove
    /// @param _value True if the addresses are being added, false if removed
    function setWhitelist(address[] calldata _addrList, bool _value) override public onlyAdmin {
        for(uint256 i = 0; i < _addrList.length;) {
            address adr = _addrList[i];
            whitelist[adr] = _value;
            unchecked {i++;}
        }
    }

    /// @notice This function removes or adds an array of addresses from the whitelst
    /// @dev Only can be called by the Lossless Admin, only Lossless addresses
    /// @param _addrList List of addresses to add or remove
    /// @param _value True if the addresses are being added, false if removed
    function setBlacklist(address[] calldata _addrList, bool _value) override public onlyAdmin {
        for(uint256 i = 0; i < _addrList.length;) {
            address adr = _addrList[i];
            blacklist[adr] = _value;
            unchecked {i++;}
        }
    }
    // --- BEFORE HOOKS ---

    /// @notice If address is protected, transfer validation rules have to be run inside the strategy.
    /// @dev isTransferAllowed reverts in case transfer can not be done by the defined rules.
    function beforeTransfer(address _sender, address _recipient, uint256 _amount) override external {
        if (!whitelist[_sender]) {
            require(!blacklist[_recipient], "LSS: _recipient is blacklisted");
        } else {
            require(!blacklist[_sender], "LSS: _sender is blacklisted");
        }
    }

    /// @notice If address is protected, transfer validation rules have to be run inside the strategy.
    /// @dev isTransferAllowed reverts in case transfer can not be done by the defined rules.
    function beforeTransferFrom(address _msgSender, address _sender, address _recipient, uint256 _amount) override external {
        if (!whitelist[_msgSender] && !whitelist[_sender]) {
            require(!blacklist[_recipient], "LSS: _recipient is blacklisted");
        }
    }

    // The following before hooks are in place as a placeholder for future products.
    // Also to preserve legacy LERC20 compatibility

    function beforeMint(address _to, uint256 _amount) override external {}

    function beforeBurn(address _account, uint256 _amount) override external {}

    function beforeApprove(address _sender, address _spender, uint256 _amount) override external {}

    function beforeIncreaseAllowance(address _msgSender, address _spender, uint256 _addedValue) override external {}

    function beforeDecreaseAllowance(address _msgSender, address _spender, uint256 _subtractedValue) override external {}


    // --- AFTER HOOKS ---
    // * After hooks are deprecated in LERC20 but we have to keep them
    //   here in order to support legacy LERC20.

    function afterMint(address _to, uint256 _amount) external {}

    function afterApprove(address _sender, address _spender, uint256 _amount) external {}

    function afterBurn(address _account, uint256 _amount) external {}

    function afterTransfer(address _sender, address _recipient, uint256 _amount) override external {}

    function afterTransferFrom(address _msgSender, address _sender, address _recipient, uint256 _amount) external {}

    function afterIncreaseAllowance(address _sender, address _spender, uint256 _addedValue) external {}

    function afterDecreaseAllowance(address _sender, address _spender, uint256 _subtractedValue) external {}
}