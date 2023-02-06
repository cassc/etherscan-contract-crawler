// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IIndelible.sol";

interface IGenericRender {
    function getTraitDetails(uint8 _layerId, uint8 _traitId) external view returns(IIndelible.Trait memory);
    function getTraitData(uint8 _layerId, uint8 _traitId) external view returns(bytes memory);
    function getCollectionName() external view returns(string memory);
}