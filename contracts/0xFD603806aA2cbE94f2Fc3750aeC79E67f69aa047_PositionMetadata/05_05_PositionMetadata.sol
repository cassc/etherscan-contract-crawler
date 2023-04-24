// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../interfaces/IPositionMetadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract PositionMetadata is IPositionMetadata, Ownable {
    using Strings for uint256;
    string public baseURI;
    constructor(string memory _baseURI) {
        baseURI = _baseURI;
    }
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
}