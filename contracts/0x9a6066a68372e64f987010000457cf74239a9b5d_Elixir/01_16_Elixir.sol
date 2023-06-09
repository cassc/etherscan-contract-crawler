// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IRoaringLeadersContract.sol";

/*
    ____  ____  ___    ____  _____   ________   __    _________    ____  __________  _____
   / __ \/ __ \/   |  / __ \/  _/ | / / ____/  / /   / ____/   |  / __ \/ ____/ __ \/ ___/
  / /_/ / / / / /| | / /_/ // //  |/ / / __   / /   / __/ / /| | / / / / __/ / /_/ /\__ \ 
 / _, _/ /_/ / ___ |/ _, _// // /|  / /_/ /  / /___/ /___/ ___ |/ /_/ / /___/ _, _/___/ / 
/_/ |_|\____/_/  |_/_/ |_/___/_/ |_/\____/  /_____/_____/_/  |_/_____/_____/_/ |_|/____/  
                                                                                          

I see you nerd! ⌐⊙_⊙
*/

contract Elixir is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    IRoaringLeadersContract private _roaringLeadersContractInstance;

    bool public mintingIsActive = false;

    string public baseURI;

    string public provenance;

    event ElixirConsumed(uint256 elixirTokenId, uint256 roaringLeadersTokenId, string traitName);

    constructor(string memory name, string memory symbol, address roaringLeadersContractAddress) ERC721(name, symbol) {
        _roaringLeadersContractInstance = IRoaringLeadersContract(roaringLeadersContractAddress);
    }

    function setRoaringLeadersContractAddress(address roaringLeadersContractAddress) public onlyOwner {
        _roaringLeadersContractInstance = IRoaringLeadersContract(roaringLeadersContractAddress);
    }

    /*
    * Pause minting if active, make active if paused.
    */
    function flipMintingState() public onlyOwner {
        mintingIsActive = !mintingIsActive;
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount) public onlyOwner {        
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(msg.sender, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(mintAddress, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
    * Mint via burning a Roaring Leaders NFT
    */
    function mintViaBurn(uint256 tokenId) public {
        require(mintingIsActive, 'Minting is not live yet');
        require(_roaringLeadersContractInstance.ownerOf(tokenId) == msg.sender, 'Caller is not owner of the token ID');

        _roaringLeadersContractInstance.burnForElixir(tokenId);
        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenIdCounter.current());
    }

    /*
    * Mint via burning multiple Roaring Leaders NFT
    */
    function mintViaBurnMultiple(uint256[] calldata tokenIds) public {
        require(mintingIsActive, 'Minting is not live yet');

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_roaringLeadersContractInstance.ownerOf(tokenIds[i]) == msg.sender, 'Caller is not owner of the token ID');
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _roaringLeadersContractInstance.burnForElixir(tokenIds[i]);
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function consumeElixir(uint256 elixirTokenId, uint256 roaringLeadersTokenId, string memory traitName) external {
        require(_isApprovedOrOwner(_msgSender(), elixirTokenId), "Caller is not owner nor approved");
        require(_roaringLeadersContractInstance.ownerOf(roaringLeadersTokenId) == msg.sender, 'Caller is not owner of the Roaring Leaders token ID');

        _burn(elixirTokenId);

        emit ElixirConsumed(elixirTokenId, roaringLeadersTokenId, traitName);
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /*     
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}