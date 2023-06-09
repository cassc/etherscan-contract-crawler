// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "IVersion.sol";
import "CoboFactory.sol";
import "CoboSafeAccount.sol";
import "BaseAuthorizer.sol";
import "ArgusRootAuthorizer.sol";
import "FuncAuthorizer.sol";
import "TransferAuthorizer.sol";
import "DEXBaseACL.sol";

contract ArgusViewHelper is IVersion {
    bytes32 public constant NAME = "ArgusViewHelper";
    uint256 public constant VERSION = 0;

    struct ModuleInfo {
        address moduleAddress;
        uint version;
        bool isEnabled;
    }

    function getCoboSafes(
        CoboFactory factory,
        address gnosisSafeAddress
    ) external view returns (ModuleInfo[] memory moduleInfos) {
        address[] memory coboSafeAddresses = factory.getAllRecord(gnosisSafeAddress, "CoboSafeAccount");
        moduleInfos = new ModuleInfo[](coboSafeAddresses.length);
        IGnosisSafe gnosisSafe = IGnosisSafe(gnosisSafeAddress);
        for (uint i = 0; i < coboSafeAddresses.length; i++) {
            CoboSafeAccount coboSafe = CoboSafeAccount(payable(coboSafeAddresses[i]));
            moduleInfos[i] = ModuleInfo(
                coboSafeAddresses[i],
                coboSafe.VERSION(),
                gnosisSafe.isModuleEnabled(coboSafeAddresses[i])
            );
        }
    }

    function getAllRoles(address coboSafeAddress) external view returns (bytes32[] memory roles) {
        CoboSafeAccount coboSafe = CoboSafeAccount(payable(coboSafeAddress));
        roles = IFlatRoleManager(coboSafe.roleManager()).getAllRoles();
    }

    function getRolesByDelegate(
        address coboSafeAddress,
        address delegate
    ) external view returns (bytes32[] memory roles) {
        CoboSafeAccount coboSafe = CoboSafeAccount(payable(coboSafeAddress));
        roles = IFlatRoleManager(coboSafe.roleManager()).getRoles(delegate);
    }

    struct DelegateRoles {
        address delegate;
        bytes32[] roles;
    }

    function getAllDelegateRoles(address coboSafeAddress) external view returns (DelegateRoles[] memory delegateRoles) {
        CoboSafeAccount coboSafe = CoboSafeAccount(payable(coboSafeAddress));
        IFlatRoleManager roleManager = IFlatRoleManager(coboSafe.roleManager());
        address[] memory delegates = roleManager.getDelegates();
        delegateRoles = new DelegateRoles[](delegates.length);
        for (uint i = 0; i < delegates.length; i++) {
            delegateRoles[i] = DelegateRoles(delegates[i], roleManager.getRoles(delegates[i]));
        }
    }

    struct AuthorizerInfo {
        address authorizer;
        bytes32 name;
        uint version;
        bytes32 authType;
        bytes32 tag;
    }

    function getAuthorizersByRole(
        address coboSafeAddress,
        bool isDelegateCall,
        bytes32 role
    ) external view returns (AuthorizerInfo[] memory authorizerInfos) {
        CoboSafeAccount coboSafe = CoboSafeAccount(payable(coboSafeAddress));
        ArgusRootAuthorizer rootAuthorizer = ArgusRootAuthorizer(coboSafe.authorizer());
        address[] memory assignedAuthorizers = rootAuthorizer.getAllAuthorizers(isDelegateCall, role);
        authorizerInfos = new AuthorizerInfo[](assignedAuthorizers.length);
        for (uint i = 0; i < assignedAuthorizers.length; i++) {
            BaseAuthorizer authorizer = BaseAuthorizer(assignedAuthorizers[i]);
            authorizerInfos[i] = AuthorizerInfo(
                assignedAuthorizers[i],
                authorizer.NAME(),
                authorizer.VERSION(),
                authorizer.TYPE(),
                authorizer.tag()
            );
        }
    }

    struct FuncAuthorizerInfo {
        address _contract;
        bytes32[] selectors;
    }

    function getFuncAuthorizerParams(
        address funcAuthorizerAddress
    ) external view returns (FuncAuthorizerInfo[] memory authorizerInfos) {
        FuncAuthorizer authorizer = FuncAuthorizer(funcAuthorizerAddress);
        address[] memory _contracts = authorizer.getAllContracts();
        authorizerInfos = new FuncAuthorizerInfo[](_contracts.length);
        for (uint i = 0; i < _contracts.length; i++) {
            authorizerInfos[i] = FuncAuthorizerInfo(_contracts[i], authorizer.getFuncsByContract(_contracts[i]));
        }
    }

    struct TransferAuthorizerInfo {
        address token;
        address[] receivers;
    }

    function getTransferAuthorizerParams(
        address transferAuthorizerAddress
    ) external view returns (TransferAuthorizerInfo[] memory authorizerInfos) {
        TransferAuthorizer authorizer = TransferAuthorizer(transferAuthorizerAddress);
        address[] memory tokens = authorizer.getAllToken();
        authorizerInfos = new TransferAuthorizerInfo[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            authorizerInfos[i] = TransferAuthorizerInfo(tokens[i], authorizer.getTokenReceivers(tokens[i]));
        }
    }

    function getDexAuthorizerParams(
        address dexAuthorizerAddress
    ) external view returns (address[] memory swapInTokens, address[] memory swapOutTokens) {
        DEXBaseACL authorizer = DEXBaseACL(dexAuthorizerAddress);
        swapInTokens = authorizer.getSwapInTokens();
        swapOutTokens = authorizer.getSwapOutTokens();
    }
}