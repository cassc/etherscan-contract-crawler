// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract UnboxedApeIt is ERC721AQueryable, ERC721Holder, ERC2981, Ownable {
    address private constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public immutable _boxedApeIt;
    string public _metadataBaseURI = "ipfs://bafybeieg5hl56fqk6z3hukobgxgrb7wup6xlttgyvuh4zvxvwnw2jqkooq/";

    constructor(address boxedApeIt) ERC721A("illapeit", "iai") {
        _boxedApeIt = boxedApeIt;
        setFee(owner(), 750);
    }

    function unboxMultiple(uint256[] calldata tokenIds) external {
        if (tokenIds.length == 0) {
            return;
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(_boxedApeIt).transferFrom(msg.sender, DEAD_ADDRESS, tokenIds[i]);
        }

        _mint(msg.sender, tokenIds.length);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public virtual override returns (bytes4) {
        if (msg.sender == _boxedApeIt) {
            IERC721(_boxedApeIt).transferFrom(address(this), DEAD_ADDRESS, tokenId);
            _mint(operator, 1);
        }

        return this.onERC721Received.selector;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataBaseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _metadataBaseURI;
        return string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || ERC721A.supportsInterface(interfaceId);
    }

    function setFee(address feeRecipient, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(feeRecipient, feeNumerator);
    }
}