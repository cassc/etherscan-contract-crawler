// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract DiffusionNftV1 is Ownable, ERC721, ERC721Enumerable
{
    // Subtract Final NEON PLEXUS: Override Collection 0xDd782034307ff54C4F0BF2719C9d8e78FCEFDD40
    uint256 public constant OVERRIDE_TOTAL_SUPPLY = 1006; // 1006 (one indexed)
    uint256 public constant DIFFUSION_MAX_SUPPLY = 9000 - OVERRIDE_TOTAL_SUPPLY; // 7994 (one indexed)
    uint256 public constant DIFFUSION_MAX_SUPPLY_INDEX = OVERRIDE_TOTAL_SUPPLY + DIFFUSION_MAX_SUPPLY ; // 9000

    address public saleContract;
    string public baseURI = "http://cdn.neonplexus.io/collections/neonplexus-diffusion/terminal/metadata/";

    constructor() Ownable() ERC721("NEON PLEXUS: Diffusion", "NPD") { }

    function mintBatch(address to, uint256[] memory tokenIds) public virtual {
        require(msg.sender == saleContract, "Nice try lol");
        uint256 length = tokenIds.length;
        for (uint256 i; i < length; ++i) {
            require(tokenIds[i] > OVERRIDE_TOTAL_SUPPLY, "ID <= OVERRIDE_TOTAL_SUPPLY");
            require(tokenIds[i] <= DIFFUSION_MAX_SUPPLY_INDEX, "ID > DIFFUSION_MAX_SUPPLY_INDEX");
             _safeMint(to, tokenIds[i]);
        }
    }

    function prepareSale(address _saleContract) public onlyOwner {
        saleContract = _saleContract;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}