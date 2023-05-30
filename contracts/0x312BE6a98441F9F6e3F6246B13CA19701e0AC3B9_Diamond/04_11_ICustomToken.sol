// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { Trait } from "../libraries/LibAppStorage.sol";

interface ICustomToken {
    function addTraitType(uint256 _traitTypeIndex, Trait[] memory traits) external;
    function walletOfOwner(address _wallet) external view returns (uint256[] memory);
    function hashToMetadata(string memory _hash, uint256 _tokenId) external view returns (string memory);
    function hashToSVG(string memory _hash) external view returns (string memory);
    function contractURI() external view returns (string memory);
    function clearTraits() external;
    function mint() external;
}