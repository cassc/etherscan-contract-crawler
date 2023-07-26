// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "./BloctoAccountProxy.sol";
import "./BloctoAccount.sol";

// BloctoAccountFactory for creating BloctoAccountProxy
contract BloctoAccountFactory is Initializable, AccessControlUpgradeable {
    /// @notice this is the version of this contract.
    string public constant VERSION = "1.4.0";
    /// @notice create account role for using createAccount() and createAccount2()
    bytes32 public constant CREATE_ACCOUNT_ROLE = keccak256("CREATE_ACCOUNT_ROLE");
    /// @notice the init implementation address of BloctoAccountCloneableWallet, never change for cosistent address
    address public initImplementation;
    /// @notice the implementation address of BloctoAccountCloneableWallet
    address public bloctoAccountImplementation;
    /// @notice the address from EIP-4337 official implementation
    IEntryPoint public entryPoint;

    event WalletCreated(address wallet, address authorizedAddress, bool full);

    /// @notice initialize
    /// @param _bloctoAccountImplementation the implementation address for BloctoAccountCloneableWallet
    /// @param _entryPoint the entrypoint address from EIP-4337 official implementation
    function initialize(address _bloctoAccountImplementation, IEntryPoint _entryPoint, address _admin)
        public
        initializer
    {
        initImplementation = _bloctoAccountImplementation;
        bloctoAccountImplementation = _bloctoAccountImplementation;
        entryPoint = _entryPoint;
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /// @notice create an account, and return its BloctoAccount.
    ///     returns the address even if the account is already deployed.
    ///     Note that during UserOperation execution, this method is called only if the account is not deployed.
    ///     This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
    /// @param _authorizedAddress the initial authorized address, must not be zero!
    /// @param _cosigner the initial cosigning address for `_authorizedAddress`, can be equal to `_authorizedAddress`
    /// @param _recoveryAddress the initial recovery address for the wallet, can be address(0)
    /// @param _salt salt for create account (used for address calculation in create2)
    /// @param _mergedKeyIndexWithParity the corresponding index of mergedKeys = authVersion + _mergedIndex
    /// @param _mergedKey the corresponding mergedKey (using Schnorr merged key)
    function createAccount(
        address _authorizedAddress,
        address _cosigner,
        address _recoveryAddress,
        uint256 _salt,
        uint8 _mergedKeyIndexWithParity,
        bytes32 _mergedKey
    ) public returns (BloctoAccount ret) {
        require(hasRole(CREATE_ACCOUNT_ROLE, msg.sender), "caller is not a create account role");
        bytes32 salt = keccak256(abi.encodePacked(_salt, _cosigner, _recoveryAddress));
        // to be consistent address
        BloctoAccountProxy newProxy = new BloctoAccountProxy{salt: salt}(initImplementation);
        ret = BloctoAccount(payable(address(newProxy)));
        // to save gas, first deploy using disableInitImplementation()
        // to be consistent address, (after) first upgrade need to call initImplementation
        ret.initImplementation(bloctoAccountImplementation);
        ret.init(
            _authorizedAddress, uint256(uint160(_cosigner)), _recoveryAddress, _mergedKeyIndexWithParity, _mergedKey
        );
        emit WalletCreated(address(ret), _authorizedAddress, false);
    }

    /// @notice create an account with multiple authorized addresses, and return its BloctoAccount.
    ///     returns the address even if the account is already deployed.
    /// @param _authorizedAddresses the initial authorized addresses, must not be zero!
    /// @param _cosigner the initial cosigning address for `_authorizedAddress`, can be equal to `_authorizedAddress`
    /// @param _recoveryAddress the initial recovery address for the wallet, can be address(0)
    /// @param _salt salt for create account (used for address calculation in create2)
    /// @param _mergedKeyIndexWithParitys the corresponding index of mergedKeys = authVersion + _mergedIndex
    /// @param _mergedKeys the corresponding mergedKey
    function createAccount2(
        address[] calldata _authorizedAddresses,
        address _cosigner,
        address _recoveryAddress,
        uint256 _salt,
        uint8[] calldata _mergedKeyIndexWithParitys,
        bytes32[] calldata _mergedKeys
    ) public returns (BloctoAccount ret) {
        require(hasRole(CREATE_ACCOUNT_ROLE, msg.sender), "caller is not a create account role");
        bytes32 salt = keccak256(abi.encodePacked(_salt, _cosigner, _recoveryAddress));
        // to be consistent address
        BloctoAccountProxy newProxy = new BloctoAccountProxy{salt: salt}(initImplementation);

        ret = BloctoAccount(payable(address(newProxy)));
        // to save gas, first deploy use disableInitImplementation()
        // to be consistent address, (after) first upgrade need to call initImplementation()
        ret.initImplementation(bloctoAccountImplementation);
        ret.init2(
            _authorizedAddresses, uint256(uint160(_cosigner)), _recoveryAddress, _mergedKeyIndexWithParitys, _mergedKeys
        );
        // emit event only with _authorizedAddresses[0]
        emit WalletCreated(address(ret), _authorizedAddresses[0], true);
    }

    /// @notice calculate the counterfactual address of this account as it would be returned by createAccount()
    /// @param _cosigner the initial cosigning address
    /// @param _recoveryAddress the initial recovery address for the wallet
    /// @param _salt salt for create account (used for address calculation in create2)
    function getAddress(address _cosigner, address _recoveryAddress, uint256 _salt) public view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_salt, _cosigner, _recoveryAddress));
        return Create2.computeAddress(
            bytes32(salt),
            keccak256(abi.encodePacked(type(BloctoAccountProxy).creationCode, abi.encode(address(initImplementation))))
        );
    }

    /// @notice set the implementation
    /// @param _bloctoAccountImplementation update the implementation address of BloctoAccountCloneableWallet for createAccount and createAccount2
    function setImplementation(address _bloctoAccountImplementation) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "caller is not a admin");
        bloctoAccountImplementation = _bloctoAccountImplementation;
    }

    /// @notice set the entrypoint
    /// @param _entrypoint target entrypoint
    function setEntrypoint(IEntryPoint _entrypoint) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "caller is not a admin");
        entryPoint = _entrypoint;
    }

    /// @notice withdraw value from the deposit
    /// @param withdrawAddress target to send to
    /// @param amount to withdraw
    function withdrawTo(address payable withdrawAddress, uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "caller is not a admin");
        entryPoint.withdrawTo(withdrawAddress, amount);
    }

    /// @notice add stake in etnrypoint for this factory to avoid bundler reject
    /// @param unstakeDelaySec - the unstake delay for this factory. Can only be increased.
    function addStake(uint32 unstakeDelaySec) external payable {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "caller is not a admin");
        entryPoint.addStake{value: msg.value}(unstakeDelaySec);
    }
}