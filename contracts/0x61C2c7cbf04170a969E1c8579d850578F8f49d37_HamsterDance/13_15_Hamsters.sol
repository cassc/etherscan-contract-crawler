// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

contract HamsterDance is ERC721, ERC721Enumerable {
    using SafeTransferLib for address payable;

    modifier noContracts() {
        require(msg.sender == tx.origin, "no contracts");
        _;
    }

    constructor() ERC721("Hamster Dance", "Hamster Dance") {}

    function _baseURI() internal pure override returns (string memory) {
        return
            "ipfs://bafybeicojhm7rfnt4qsrquuyagcwwma4dc56ewccqgfxn755mwjxoqmh7y/";
    }

    function mint(uint256 tokenId) external payable noContracts {
        require(msg.value >= 0.01 ether, "min price for bots");
        require(tokenId > 0 && tokenId < 1001, "wrong id");
        require(totalSupply() < 1000, "Supply");

        _safeMint(msg.sender, tokenId);
    }

    function win() external noContracts {
        require(totalSupply() >= 999, "needs to mint out first");
        require(balanceOf(msg.sender) >= 1, "must own at least one");
        payable(msg.sender).safeTransferETH(address(this).balance);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {}
}