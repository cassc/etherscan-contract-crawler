// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/*
    ____  ____  ___    ____  _____   ________   __    _________    ____  __________  _____
   / __ \/ __ \/   |  / __ \/  _/ | / / ____/  / /   / ____/   |  / __ \/ ____/ __ \/ ___/
  / /_/ / / / / /| | / /_/ // //  |/ / / __   / /   / __/ / /| | / / / / __/ / /_/ /\__ \ 
 / _, _/ /_/ / ___ |/ _, _// // /|  / /_/ /  / /___/ /___/ ___ |/ /_/ / /___/ _, _/___/ / 
/_/ |_|\____/_/  |_/_/ |_/___/_/ |_/\____/  /_____/_____/_/  |_/_____/_____/_/ |_|/____/  
                                                                                          

I see you nerd! ⌐⊙_⊙
*/

contract LeadersFund is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    IERC721 private _elixirContractInstance;

    bool public mintingIsActive = false;

    string public baseURI;

    string public provenance;

    // Tokens before the start token cannot claim fund shares as they were reserved for giveaways
    uint256 public startToken;

    // Mapping from elixir token ID to whether it has been claimed or not
    mapping(uint256 => bool) private _claimed;

    constructor(string memory name, string memory symbol, address elixirContractAddress) ERC721(name, symbol) {
        _elixirContractInstance = IERC721(elixirContractAddress);
        startToken = 86;
    }

    function setElixirContractAddress(address elixirContractAddress) public onlyOwner {
        _elixirContractInstance = IERC721(elixirContractAddress);
    }

    function setStartToken(uint256 startTokenId) public onlyOwner {
        startToken = startTokenId;
    }

    /*
    * Pause minting if active, make active if paused.
    */
    function flipMintingState() public onlyOwner {
        mintingIsActive = !mintingIsActive;
    }

    /*
    * Mint reserved NFTs for giveaways, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(mintAddress, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
    * Mint via claiming the fund NFT via an elixir token
    */
    function mintViaClaim(uint256 tokenId) public {
        require(mintingIsActive, 'Minting is not live yet');
        require(_elixirContractInstance.ownerOf(tokenId) == msg.sender, 'Caller is not owner of the token ID');
        require(! _claimed[tokenId] && tokenId >= startToken, 'This token has already been claimed');

        _claimed[tokenId] = true;
        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenIdCounter.current());
    }

    /*
    * Mint via burning claiming multiple elixir tokens
    */
    function mintViaClaimMultiple(uint256[] calldata tokenIds) public {
        require(mintingIsActive, 'Minting is not live yet');

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_elixirContractInstance.ownerOf(tokenIds[i]) == msg.sender, 'Caller is not owner of the token ID');
            require(! _claimed[tokenIds[i]] && tokenIds[i] >= startToken, 'This token has already been claimed');
            _claimed[tokenIds[i]] = true;
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    /*
    * Check whether the given token ID can be claimed
    */
    function canClaim(uint256 tokenId) external view returns (bool) {
        return ! _claimed[tokenId] && tokenId >= startToken;
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