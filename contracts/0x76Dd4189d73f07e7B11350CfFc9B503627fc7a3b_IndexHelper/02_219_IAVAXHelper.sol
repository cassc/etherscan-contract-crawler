// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";

import "./IIndexRouter.sol";
import "./IManagedIndexFactory.sol";

interface IAVAXHelper {
    function mintSwapValue(IIndexRouter.MintSwapValueParams calldata _params, address _asset) external payable;

    function createIndex(
        address[] calldata _assets,
        uint8[] calldata _weights,
        IManagedIndexFactory.NameDetails calldata _nameDetails,
        address _asset
    ) external;

    function registry() external view returns (IAccessControl);

    function router() external view returns (IIndexRouter);

    function factory() external view returns (IManagedIndexFactory);
}