// SPDX-License-Identifier: GPL-3.0 License
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract NFTGA is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    Ownable,
    ERC721Burnable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;


    constructor() ERC721("M.A. Global account", "MAGA") {
       
    }

    function createToken(string memory tokenURI1) public onlyOwner returns  (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI1);
        return newItemId;
    }

     function createTokenBulk(string memory tokenURI1, address Tokown,  uint256  mintxtimes) public onlyOwner returns (uint[] memory) {       
        uint[] memory Tokens;
        
        for (uint256 i = 1; i <= mintxtimes; i++)
        {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(Tokown, newItemId);
        _setTokenURI(newItemId, tokenURI1);        
        Tokens[i] = newItemId;
        
        }
        return Tokens;
    }

    function createTokenfmint(string memory tokenURI1, uint256 price)
        public
        returns (uint256)
    {
        IERC20 wsps = IERC20(0x8033064Fe1df862271d4546c281AfB581ee25C4A);
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        require(
            wsps.allowance(msg.sender, address(this)) >= price,
            "Insuficient Allowance"
        );
        require(
            wsps.balanceOf(msg.sender) >= price,
            "No tiene saldo suficiente"
        );
        require(
            wsps.transferFrom(
                msg.sender,
                address(0x621DEa0C53115189E8C14D59157419F27aeeDF60),
                price
            )
        );
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI1);        
        return newItemId;
    }

    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    ) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function transferToken(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == from, "From address must be token owner");
        _transfer(from, to, tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
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