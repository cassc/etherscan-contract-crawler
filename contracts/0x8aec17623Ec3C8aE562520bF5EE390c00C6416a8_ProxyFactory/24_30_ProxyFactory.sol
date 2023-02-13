// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14; 


import '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import '@rari-capital/solmate/src/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../interfaces/ethereum/IProxyFactory.sol';
import '../interfaces/ethereum/IOps.sol';
import './ozUpgradeableBeacon.sol';
import './ozAccountProxy.sol';
import '../Errors.sol';


/**
 * @title Factory of user proxies (aka accounts)
 * @notice Creates the accounts where users will receive their ETH on L1. 
 * Each account is the proxy (ozAccountProxy) connected -through the Beacon- to ozPayMe (the implementation)
 */
contract ProxyFactory is IProxyFactory, ReentrancyGuard, Initializable, UUPSUpgradeable { 

    using Address for address;

    address private immutable beacon;
    address private immutable ops;
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier onlyOwner() {
        if(!(_getAdmin() == msg.sender)) revert NotAuthorized(msg.sender);
        _;
    }

    constructor(address ops_, address beacon_) {
        ops = ops_;
        beacon = beacon_;
    }


    /// @inheritdoc IProxyFactory
    function createNewProxy(
        StorageBeacon.AccountConfig calldata acc_
    ) external nonReentrant returns(address) {
        bytes calldata name = bytes(acc_.name);
        address token = acc_.token;
        StorageBeacon sBeacon = StorageBeacon(_getStorageBeacon(0));

        if (name.length == 0) revert CantBeZero('name'); 
        if (name.length > 18) revert NameTooLong();
        if (acc_.user == address(0) || token == address(0)) revert CantBeZero('address');
        if (acc_.slippage < 1 || acc_.slippage > 500) revert CantBeZero('slippage');
        if (!sBeacon.queryTokenDatabase(token)) revert TokenNotInDatabase(token);

        ozAccountProxy newAccount = new ozAccountProxy(
            beacon,
            new bytes(0)
        );

        bytes2 slippage = bytes2(uint16(acc_.slippage));
        bytes memory dataForL2 = bytes.concat(bytes20(acc_.user), bytes20(acc_.token), slippage);
    
        bytes memory createData = abi.encodeWithSignature(
            'initialize(address,bytes)',
            beacon, dataForL2
        );
        (bool success, ) = address(newAccount).call(createData);
        require(success);

        bytes32 id = _startTask(address(newAccount), ops);

        sBeacon.multiSave(bytes20(address(newAccount)), acc_, id);

        return address(newAccount);
    }

    /*///////////////////////////////////////////////////////////////
                                Helpers
    //////////////////////////////////////////////////////////////*/

    /// @dev Creates the Gelato task of each proxy/account
    function _startTask(address account_, address ops_) private returns(bytes32 id) { 
        id = IOps(ops_).createTaskNoPrepayment( 
            account_,
            bytes4(abi.encodeWithSignature('sendToArb(uint256)')),
            account_,
            abi.encodeWithSignature('checker()'),
            ETH
        );
    }

    /// @dev Gets a version of the Storage Beacon
    function _getStorageBeacon(uint version_) private view returns(address) {
        return ozUpgradeableBeacon(beacon).storageBeacon(version_);
    }

    /// @inheritdoc IProxyFactory
    function initialize() external initializer {
        _changeAdmin(msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                            Ownership methods
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address newImplementation_) internal override onlyOwner {}

    /// @inheritdoc IProxyFactory
    function getOwner() external view onlyProxy returns(address) {
        return _getAdmin();
    }

    /// @inheritdoc IProxyFactory
    function changeOwner(address newOwner_) external onlyProxy onlyOwner {
        _changeAdmin(newOwner_);
    }
}