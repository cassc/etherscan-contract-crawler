// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../core/NPass.sol";
import "../interfaces/IN.sol";

/**
 * @title Flat-n contract
 * @author Ashiq Amien
 * @notice This contract allows n-project holders to mint a flat-n
 */
contract FlatN is NPass {
    using Strings for uint256;

    constructor(
        string memory name,
        string memory symbol,
        bool onlyNHolders
    ) NPass(name, symbol, onlyNHolders) {}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://ipfs.io/ipfs/Qmbfw3NtUXw8kX9EoEefWswNobjTaewECeNa6itQiPRNNt/";
    }
}