// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IDiamondLoupe} from "@lib-diamond/src/diamond/IDiamondLoupe.sol";
import {IDiamondCut} from "@lib-diamond/src/diamond/IDiamondCut.sol";
import {IDiamondInit} from "@lib-diamond/src/diamond/IDiamondInit.sol";

import {IAccessControl} from "@lib-diamond/src/access/access-control/IAccessControl.sol";
import {IAccessControlEnumerable} from "@lib-diamond/src/access/access-control/IAccessControlEnumerable.sol";
import {LibAccessControlEnumerable} from "@lib-diamond/src/access/access-control/LibAccessControlEnumerable.sol";
import {AccessControlStorage} from "@lib-diamond/src/access/access-control/AccessControlStorage.sol";
import {DEFAULT_ADMIN_ROLE} from "@lib-diamond/src/access/access-control/Roles.sol";

import {IERC165} from "@lib-diamond/src/utils/introspection/erc165/IERC165.sol";
import {LibERC165} from "@lib-diamond/src/utils/introspection/erc165/LibERC165.sol";
import {ERC165Storage} from "@lib-diamond/src/utils/introspection/erc165/ERC165Storage.sol";

import {IPausable} from "@lib-diamond/src/security/pausable/IPausable.sol";

import {LibPonzu} from "./libraries/LibPonzu.sol";
import {PonzuStorage} from "./types/ponzu/PonzuStorage.sol";

import {IQRNGReceiver} from "@src/interfaces/IQRNGReceiver.sol";

contract PonzuDiamondInit is IDiamondInit {
  // You can add parameters to this function in order to pass in
  // data to set your own state variables
  function init() external {
    // adding ERC165 data
    ERC165Storage storage ds = LibERC165.DS();
    ds.supportedInterfaces[type(IERC165).interfaceId] = true;
    ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
    ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
    ds.supportedInterfaces[type(IAccessControl).interfaceId] = true;
    ds.supportedInterfaces[type(IAccessControlEnumerable).interfaceId] = true;
    ds.supportedInterfaces[type(IQRNGReceiver).interfaceId] = true;
    ds.supportedInterfaces[type(IPausable).interfaceId] = true;

    // add your own state variables
    // EIP-2535 specifies that the `diamondCut` function takes two optional
    // arguments: address _init and bytes calldata _calldata
    // These arguments are used to execute an arbitrary function using delegatecall
    // in order to set state variables in the diamond during deployment or an upgrade
    // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface

    PonzuStorage storage ps = LibPonzu.DS();
    ps.blackHoleShare = 1000;
  }
}