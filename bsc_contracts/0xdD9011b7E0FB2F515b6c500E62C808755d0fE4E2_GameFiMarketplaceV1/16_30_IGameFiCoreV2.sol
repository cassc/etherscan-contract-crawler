// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "./component/IProfileV2.sol";
import "./component/IPropertyV2.sol";
import "./component/ICollectionV2.sol";
import "./component/ITokenV2.sol";
import "../other/ITrustedForwarder.sol";

interface IGameFiCoreV2 is IProfileV2, IPropertyV2, ICollectionV2, ITokenV2, ITrustedForwarder {
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address profileVaultImpl_
    ) external;

    function versionHash() external view returns (bytes4);

    function isAdmin(address target) external view returns (bool);

    function isOperator(address target) external view returns (bool);
}