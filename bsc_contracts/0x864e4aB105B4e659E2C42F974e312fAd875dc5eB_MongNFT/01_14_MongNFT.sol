// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MongNFT is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    address public minter;

    event NewMinter(address newMinter);

    constructor() ERC721("MongBNB NFT", "MONGNFT") {}

    modifier onlyMinter() {
        require(_msgSender() == minter, "MongNFT: forbidden");
        _;
    }

    function safeMint(address to) external onlyMinter returns (uint) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _mint(to, newItemId);
        return newItemId;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public pure override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "ipfs://bafybeign3mp2mavafmizslfkqed5tf4its6s4aeukqtgxwlsfxnqysi75m/",
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function setMinter(address _newMinter) external onlyOwner {
        require(minter == address(0), "MongNFT: initialized");
        minter = _newMinter;
        emit NewMinter(_newMinter);
    }
}