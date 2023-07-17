// commit da41ad6c9caa5295bc268cc21b1b83764db6226a
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "CoboSafeAccount.sol";
import "FlatRoleManager.sol";
import "ArgusRootAuthorizer.sol";
import "FuncAuthorizer.sol";
import "TransferAuthorizer.sol";
import "DEXBaseACL.sol";

abstract contract ArgusAuthorizerHelper {
    function setFuncAuthorizerParams(
        address authorizerAddress,
        address[] calldata _contracts,
        string[][] calldata funcLists
    ) public {
        if (_contracts.length == 0) return;
        require(_contracts.length == funcLists.length, "Length differs");
        FuncAuthorizer authorizer = FuncAuthorizer(authorizerAddress);
        for (uint i = 0; i < _contracts.length; i++) {
            authorizer.addContractFuncs(_contracts[i], funcLists[i]);
        }
    }

    function unsetFuncAuthorizerParams(
        address authorizerAddress,
        address[] calldata _contracts,
        string[][] calldata funcLists
    ) external {
        if (_contracts.length == 0) return;
        require(_contracts.length == funcLists.length, "Length differs");
        FuncAuthorizer authorizer = FuncAuthorizer(authorizerAddress);
        for (uint i = 0; i < _contracts.length; i++) {
            authorizer.removeContractFuncs(_contracts[i], funcLists[i]);
        }
    }

    function setTransferAuthorizerParams(
        address authorizerAddress,
        TransferAuthorizer.TokenReceiver[] calldata tokenReceivers
    ) public {
        if (tokenReceivers.length == 0) return;
        TransferAuthorizer authorizer = TransferAuthorizer(authorizerAddress);
        authorizer.addTokenReceivers(tokenReceivers);
    }

    function unsetTransferAuthorizerParams(
        address authorizerAddress,
        TransferAuthorizer.TokenReceiver[] calldata tokenReceivers
    ) external {
        if (tokenReceivers.length == 0) return;
        TransferAuthorizer authorizer = TransferAuthorizer(authorizerAddress);
        authorizer.removeTokenReceivers(tokenReceivers);
    }

    function setDexAuthorizerParams(
        address authorizerAddress,
        address[] calldata _swapInTokens,
        address[] calldata _swapOutTokens
    ) public {
        DEXBaseACL authorizer = DEXBaseACL(authorizerAddress);
        if (_swapInTokens.length > 0) {
            authorizer.addSwapInTokens(_swapInTokens);
        }
        if (_swapOutTokens.length > 0) {
            authorizer.addSwapOutTokens(_swapOutTokens);
        }
    }

    function unsetDexAuthorizerParams(
        address authorizerAddress,
        address[] calldata _swapInTokens,
        address[] calldata _swapOutTokens
    ) external {
        DEXBaseACL authorizer = DEXBaseACL(authorizerAddress);
        if (_swapInTokens.length > 0) {
            authorizer.removeSwapInTokens(_swapInTokens);
        }
        if (_swapOutTokens.length > 0) {
            authorizer.removeSwapOutTokens(_swapOutTokens);
        }
    }
}