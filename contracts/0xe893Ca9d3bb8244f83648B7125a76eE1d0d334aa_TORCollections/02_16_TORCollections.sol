// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ITORContract.sol";

/*
              ________________       _,.......,_        
          .nNNNNNNNNNNNNNNNNP’  .nnNNNNNNNNNNNNnn..
         ANNC*’ 7NNNN|’’’’’’’ (NNN*’ 7NNNNN   `*NNNn.
        (NNNN.  dNNNN’        qNNN)  JNNNN*     `NNNn
         `*@*’  NNNNN         `*@*’  dNNNN’     ,ANNN)
               ,NNNN’  ..-^^^-..     NNNNN     ,NNNNN’
               dNNNN’ /    .    \   .NNNNP _..nNNNN*’
               NNNNN (    /|\    )  NNNNNnnNNNNN*’
              ,NNNN’ ‘   / | \   ’  NNNN*  \NNNNb
              dNNNN’  \  \'.'/  /  ,NNNN’   \NNNN.
              NNNNN    '  \|/  '   NNNNC     \NNNN.
            .JNNNNNL.   \  '  /  .JNNNNNL.    \NNNN.             .
          dNNNNNNNNNN|   ‘. .’ .NNNNNNNNNN|    `NNNNn.          ^\Nn
                           '                     `NNNNn.         .NND
                                                  `*NNNNNnnn....nnNP’
                                                     `*@NNNNNNNNN**’
*/

contract TORCollections is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    ITORContract public torContractInstance;

    bool public mintingIsActive = false;

    uint256 public currentCollectionNumber = 1;

    // Mapping from collection number to addresses
    mapping (uint256 => mapping (address => bool)) private _collectionAddresses;

    string public baseURI;

    string public provenance;

    constructor(string memory name, string memory symbol, address torAddress) ERC721(name, symbol) {
        torContractInstance = ITORContract(torAddress);
    }

    function setTORContractAddress(address torAddress) public onlyOwner {
        torContractInstance = ITORContract(torAddress);
    }

    function setCurrentCollectionNumber(uint256 newCollectionNumber) public onlyOwner {
        currentCollectionNumber = newCollectionNumber;
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
    * Pause minting if active, make active if paused.
    */
    function flipMintingState() public onlyOwner {
        mintingIsActive = !mintingIsActive;
    }

    /*
    * Mint TOR collection NFTs, woo!
    */
    function mintByBurning(uint256[3] calldata torTokenIds) public {
        require(mintingIsActive, "Minting is not live yet");
        require(_collectionAddresses[currentCollectionNumber][msg.sender], 'This address is not in the snapshot');

        _collectionAddresses[currentCollectionNumber][msg.sender] = false;

        for(uint256 i = 0; i < 3; i++) {
            require(torContractInstance.ownerOf(torTokenIds[i]) == msg.sender, 'You do not own the TOR token');
            torContractInstance.burn(torTokenIds[i]);
        }

        _safeMint(msg.sender, _tokenIdCounter.current() + 1);
        _tokenIdCounter.increment();
    }

    function setSnapshot(uint256 collectionNumber, address[] memory snapshotAddresses) public onlyOwner {
        for(uint256 i = 0; i < snapshotAddresses.length; i++) {
            _collectionAddresses[collectionNumber][snapshotAddresses[i]] = true;
        }
    }

    function canMint(address owner) public view returns (bool) {
        return _collectionAddresses[currentCollectionNumber][owner];
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