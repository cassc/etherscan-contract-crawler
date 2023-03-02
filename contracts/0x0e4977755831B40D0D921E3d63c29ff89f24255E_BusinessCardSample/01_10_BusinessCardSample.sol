// SPDX-License-Identifier: MIT

pragma solidity >=0.5.8 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract BusinessCardSample is Ownable, ERC721A, Pausable, ReentrancyGuard {
    uint256 public mintedSize = 0;
    string private baseURI;

    constructor() ERC721A("BusinessCardSample", "BCS") {}

    modifier validateMintable(uint256 quantity) {
        require(quantity > 0, "The quantity cannot be less than 0.");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Invalid tokenId.");
        return string(abi.encodePacked(baseURI, "metadata.json"));
    }

    function mint(address to, uint256 quantity) external validateMintable(quantity) onlyOwner {
        _safeMint(to, quantity);
        mintedSize += quantity;
    }
}