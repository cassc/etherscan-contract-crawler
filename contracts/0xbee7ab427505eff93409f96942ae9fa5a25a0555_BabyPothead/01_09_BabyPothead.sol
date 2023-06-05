//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/common/ERC2981.sol";

error IncorrectEtherValue();
error MaxMint();

contract BabyPothead is ERC721A, ERC2981, Ownable {
    uint256 price = 0.0042 ether;
    string private baseURI;
    uint maxSupply = 4420;

    constructor(string memory _baseUri) ERC721A("Baby OG PotHeads", "BOGPH") {
        baseURI = _baseUri;
        _mint(msg.sender, 20);
        _setDefaultRoyalty(msg.sender, 250);
    }

    function mint(uint256 quantity) external payable {
        if (msg.value != price * quantity) {
            revert IncorrectEtherValue();
        }
        if (quantity > 20) {
            revert MaxMint();
        }
        if (totalSupply() + quantity > maxSupply) {
            revert MaxMint();
        }
        _mint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, "/", _toString(tokenId), ".json")) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    //ERC2981 stuff
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}