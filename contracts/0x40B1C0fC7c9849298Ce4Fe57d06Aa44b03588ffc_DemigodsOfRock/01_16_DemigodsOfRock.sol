// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IEnumerableContract.sol";

/*
I see you nerd! ⌐⊙_⊙
*/

contract DemigodsOfRock is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    IEnumerableContract public gorContractInstance;

    bool public mintingIsActive = false;

    string public baseURI;

    string public provenance;

    constructor(string memory name, string memory symbol, address godsofrockContractAddress) ERC721(name, symbol) {
        gorContractInstance = IEnumerableContract(godsofrockContractAddress);
    }

    function setGodsofRockAddress(address godsofrockContractAddress) public onlyOwner {
        gorContractInstance = IEnumerableContract(godsofrockContractAddress);
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
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(mintAddress, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
    * Mint via burning 3 GOR NFTs
    */
    function mintViaBurn(uint256[3] calldata gorTokenIds) public {
        require(mintingIsActive, 'Minting is not live yet');
        
        for(uint256 i = 0; i < 3; i++) {
            require(gorContractInstance.ownerOf(gorTokenIds[i]) == msg.sender, 'You do not own the GOR token');
            gorContractInstance.burn(gorTokenIds[i]);
        }

        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenIdCounter.current());
    }

    /*
    * Mint via burning multiple GOR NFTs
    */
    function mintViaBurnMultiple(uint256[] calldata gorTokenIds) public {
        require(mintingIsActive, 'Minting is not live yet');
        require(gorTokenIds.length % 3 == 0, 'Provided token IDs should be in multiples of three');

        for (uint256 i = 0; i < gorTokenIds.length; i++) {
            require(gorContractInstance.ownerOf(gorTokenIds[i]) == msg.sender, 'You do not own the GOR token');
            gorContractInstance.burn(gorTokenIds[i]);
        }

        uint256 numberOfMints = gorTokenIds.length / 3;
        for(uint256 i = 0; i < numberOfMints; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
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