// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRegistryProvider.sol";
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';


/**
 * @title Provider interface for Revest FNFTs
 */
interface IOutputReceiver is IRegistryProvider, IERC165 {

    function receiveRevestOutput(
        uint fnftId,
        address asset,
        address payable owner,
        uint quantity
    ) external;

    function getCustomMetadata(uint fnftId) external view returns (string memory);

    function getValue(uint fnftId) external view returns (uint);

    function getAsset(uint fnftId) external view returns (address);

    function getOutputDisplayValues(uint fnftId) external view returns (bytes memory);

}