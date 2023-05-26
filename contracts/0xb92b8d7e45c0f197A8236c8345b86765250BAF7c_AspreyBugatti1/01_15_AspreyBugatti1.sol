// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AspreyBugatti1 is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256 public constant MAX_PRESALE = 261;
    uint256 public redeemTime;
    string public baseURI;
    mapping(uint256 => address) public redeemed;

    constructor() ERC721("Asprey Bugatti La Voiture Noire Collection", "AB:C1") {
        redeemTime = 1664539200;
        baseURI = "https://asprey-nft-minting-metadata-ab-01.s3.eu-west-2.amazonaws.com/";
    }

    /**
    * Returns base uri of the tokens' metadata
    */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
    * Only owner of the smart contract can update the uri of tokens' metadata
    */
    function updateBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    } 

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
    * Only owner of the smart contract can mint predefined {MAX_PRESALE} presale tokens
    * Only one token can be minted at a time
    */
    function presale(address to) external onlyOwner {
        require(totalSupply() <= MAX_PRESALE, "Presale supply exceeded");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    /**
    * Current owner of a token can redeem their token for a physical artifact
    * Current owner of the token must enter tokenId as input
    * Current owner of the token must use redeem webpage at aspreybugatti.com
    * They are recommended to enter their personal details for shipping on that page
    * Owner of the smart contract reserves the right to pause this function
    * Tokens can be redeemed only before {redeemTime} (seconds since unix epoch UTC)
    */
    function redeem(uint256 tokenId) external whenNotPaused{
        require(ownerOf(tokenId) == _msgSender(), "Not the current owner of token");
        require(redeemed[tokenId] == address(0), "Token redeemed");
        require(block.timestamp<=redeemTime, "Redeem time finished");
        redeemed[tokenId] = msg.sender;
    }

    /**
    * Anyone can check list of unredeemed sculptures
    * Input: address of the owner
    * Output: Array of tokenIds unredeemed with redeemed tokenIds set to zero
    * Users are recommeded to use given redeem webpage for redeeming tokens
    */
    function getIdsOwnedUnRedeemed(address user) public view returns(uint256[] memory) {    
    uint256 numTokens = balanceOf(user);
    uint256[] memory uriList = new uint256[](numTokens);
    for (uint256 i; i < numTokens; i++) {
        uint256 tok  = tokenOfOwnerByIndex(user, i);
        if(redeemed[tok]==address(0)){
            uriList[i] = tok;
        }
    }
    return(uriList);
    }

    /**
    * Owner of the smart contract can update redeem time at any point
    */
    function updateRedeemTime(uint256 _time) external onlyOwner {
        redeemTime = _time;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
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