// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../../timelock/TimelockCallable.sol";
import "../../common/Basic.sol";
import "./IControllerLink.sol";

interface IControllerLibSub {
    function initialize(
        address _adapterManager,
        address _autoExecutor,
        bytes memory data
    ) external;
}

contract ProxyWallet is TransparentUpgradeableProxy {
    event Received(address addr, uint256 amount);

    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, _admin, _data) {}

    function getProxyAdmin() external view returns (address) {
        return _getAdmin();
    }

    receive() external payable override {
        emit Received(msg.sender, msg.value);
    }
}

contract WalletFactory is TimelockCallable, Basic {
    address public immutable userDatabase;
    bytes32 public immutable trustProxyAdminCodeHash; //proxyAdmin for ControllerLib
    address public trustAccountLogic; //ControllerLib
    address public trustSubAccountLogic; //ControllerLibSub

    event updateTrustLogic(
        address _trustAccountLogic,
        address _trustSubAccountLogic
    );

    event mainAccountCreate(address _userAddress, address _newAccount);
    event subAccountCreate(address _mainAccount, address _newSubAccount);

    constructor(
        address _userDatabase,
        address _trustAccountLogic,
        address _trustSubAccountLogic,
        address _timelock,
        bytes32 _trustProxyAdminCodeHash
    ) TimelockCallable(_timelock) {
        userDatabase = _userDatabase;
        trustAccountLogic = _trustAccountLogic;
        trustSubAccountLogic = _trustSubAccountLogic;
        trustProxyAdminCodeHash = _trustProxyAdminCodeHash;
    }

    function setTrustLogic(
        address _trustAccountLogic,
        address _trustSubAccountLogic
    ) external onlyTimelock {
        trustAccountLogic = _trustAccountLogic;
        trustSubAccountLogic = _trustSubAccountLogic;

        emit updateTrustLogic(trustAccountLogic, trustSubAccountLogic);
    }

    function proxyAdminCheck(address defaultProxyAdmin)
        internal
        returns (address)
    {
        if (defaultProxyAdmin == address(0)) {
            ProxyAdmin newProxyAdmin = new ProxyAdmin();
            address newProxyAdminAddr = address(newProxyAdmin);
            Ownable(newProxyAdminAddr).transferOwnership(msg.sender);
            return newProxyAdminAddr;
        }
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(defaultProxyAdmin)
        }
        require(
            Ownable(defaultProxyAdmin).owner() == msg.sender &&
                codeHash == trustProxyAdminCodeHash,
            "!trustProxyAdmin"
        );
        return defaultProxyAdmin;
    }

    function upgradableWalletCreate(
        address _logic,
        address _admin,
        bytes memory _data
    ) internal returns (address) {
        ProxyWallet newAccount = new ProxyWallet(_logic, _admin, _data);
        address newAccountAddr = address(newAccount);
        OwnableUpgradeable(newAccountAddr).transferOwnership(msg.sender);
        IControllerLink(userDatabase).addAuth(msg.sender, newAccountAddr);

        emit mainAccountCreate(msg.sender, newAccountAddr);
        return newAccountAddr;
    }

    function createAccount(address _admin, bytes memory _data)
        external
        payable
        returns (address proxyAdmin, address newAccount)
    {
        proxyAdmin = proxyAdminCheck(_admin);
        newAccount = upgradableWalletCreate(
            trustAccountLogic,
            proxyAdmin,
            _data
        );
        safeTransferETH(newAccount, msg.value);
    }

    function createSubAccount(
        address _adapterManager,
        address _autoExecutor,
        bytes memory _data
    ) external payable returns (address newAccount) {
        require(
            IControllerLink(userDatabase).existing(msg.sender) == true,
            "!cianUser"
        );
        newAccount = Clones.clone(trustSubAccountLogic);
        IControllerLibSub(newAccount).initialize(
            _adapterManager,
            _autoExecutor,
            _data
        );
        Ownable(newAccount).transferOwnership(msg.sender);
        IControllerLink(userDatabase).addAuth(msg.sender, newAccount);
        safeTransferETH(newAccount, msg.value);

        emit subAccountCreate(msg.sender, address(newAccount));
    }
}