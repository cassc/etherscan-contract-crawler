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

contract TORVIPPass is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    uint256 public maxTokenSupply;

    Counters.Counter private _tokenIdCounter;

    ITORContract private _torContractInstance;

    bool public claimingIsActive = false;

    bool public burningIsActive = false;

    // Mapping from token ID to whether it has been claimed or not
    mapping(uint256 => bool) private _claimed;

    string public baseURI;

    string public provenance;

    constructor(string memory name, string memory symbol, uint256 maxVIPPassSupply, address torContractAddress) ERC721(name, symbol) {
        maxTokenSupply = maxVIPPassSupply;
        _torContractInstance = ITORContract(torContractAddress);
    }

    function setMaxTokenSupply(uint256 maxVIPPassSupply) public onlyOwner {
        maxTokenSupply = maxVIPPassSupply;
    }

    function setTorContractAddress(address torContractAddress) public onlyOwner {
        _torContractInstance = ITORContract(torContractAddress);
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
    * Get claimable token IDs
    */
    function getClaimableTokens(address owner) external view returns (uint256[] memory) {
        uint256[] memory tokenIds;

        uint256 balance = _torContractInstance.balanceOf(owner);
        uint256 count = 0;

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = _torContractInstance.tokenOfOwnerByIndex(owner, i);
            if (! _claimed[tokenId]) {
                count++;
            }
        }

        tokenIds = new uint256[](count);
        uint256 j = 0;

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = _torContractInstance.tokenOfOwnerByIndex(owner, i);
            if (! _claimed[tokenId]) {
                tokenIds[j] = tokenId;
                j++;
            }
        }

        return tokenIds;
    }

    /*
    * Check whether the given token ID can be claimed
    */
    function canClaim(uint256 tokenId) external view returns (bool) {
        return ! _claimed[tokenId];
    }

    /*
    * Mint via claiming VIP passes with 3 TOR NFTs
    */
    function mintViaClaim(uint256[] calldata tokenIds) public {
        require(claimingIsActive, 'Minting via claiming is not live yet');
        require(_tokenIdCounter.current() + (tokenIds.length / 3) <= maxTokenSupply, "Purchase would exceed max available VIP Passes");
        require(tokenIds.length % 3 == 0, 'Provided token IDs should be in multiples of three');

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_torContractInstance.ownerOf(tokenIds[i]) == msg.sender && ! _claimed[tokenIds[i]], 'Caller is either not owner of the token ID or it has already been claimed');
            _claimed[tokenIds[i]] = true;
        }

        uint256 numberOfPasses = tokenIds.length / 3;
        for(uint256 i = 0; i < numberOfPasses; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    /*
    * Mint via burning 2 TOR NFTs
    */
    function mintViaBurn(uint256[] calldata tokenIds) public {
        require(burningIsActive, 'Minting via burning is not live yet');
        require(_tokenIdCounter.current() + (tokenIds.length / 2) <= maxTokenSupply, "Purchase would exceed max available VIP Passes");
        require(tokenIds.length % 2 == 0, 'Provided token IDs should be in multiples of two');

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_torContractInstance.ownerOf(tokenIds[i]) == msg.sender, 'Caller is not owner of the token ID');
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _torContractInstance.burn(tokenIds[i]);
        }

        uint256 numberOfPasses = tokenIds.length / 2;
        for(uint256 i = 0; i < numberOfPasses; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    /*
    * Pause claiming if active, make active if paused.
    */
    function flipClaimingState() public onlyOwner {
        claimingIsActive = !claimingIsActive;
    }

    /*
    * Pause burning if active, make active if paused.
    */
    function flipBurningState() public onlyOwner {
        burningIsActive = !burningIsActive;
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