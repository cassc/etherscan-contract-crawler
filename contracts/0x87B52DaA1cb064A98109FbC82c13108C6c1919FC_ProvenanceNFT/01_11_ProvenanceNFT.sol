// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC1155.sol";
import "Ownable.sol";
import "Strings.sol";

contract ProvenanceNFT is ERC1155, Ownable {
    constructor()
        ERC1155("https://nft.anothernow.io/provenance-art-gallery/provenance/metadata/")
    {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function uri(uint256 _tokenId) override public view returns (string memory)
    {
        return string(
            abi.encodePacked(
                super.uri(_tokenId),
                Strings.toString(_tokenId),
                ".json"
            )
        );
    }
}