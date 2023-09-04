// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface IERC20Burnable {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}


contract LostboyArtistXPIII is ERC721, ERC721Enumerable, Ownable {

    using Strings for uint256;

    IERC20Burnable public lostToken;

    
    uint256 public constant ARTISTXPSUPPLY = 20;
    uint256 public constant ARTISTXPPRICE = 30000 * 10**18;
    string private _metaBaseUri = "https://lostboy.mypinata.cloud/ipfs/Qme4PmNV3Euv5wBjoW4RRkggaZFsmyX9UgWZpZtmCCrCWs/";
    bool private _saleIsActive;

    mapping (address => bool) private trackOwners;
    uint256 [] private mintedTracks;

    constructor(address _lostToken) ERC721("LostboyArtistXPIII", "LBXPIII") {
        lostToken = IERC20Burnable(_lostToken);
        _saleIsActive = false;
    }

    // Only Owner Functions
    function setSaleIsActive(bool active) external onlyOwner {
        _saleIsActive = active;
    }

    function setMetaBaseURI(string memory baseURI) external onlyOwner {
        _metaBaseUri = baseURI;
    }

    function mintArtistXP(uint256 tokenId) public {
        // can only mint 1 per wallet
        require(_checkTrack(msg.sender), "Only 1 track per wallet");
        // token must not be already minted
        require(!_exists(tokenId), "Track already minted");
        // check total supply
        require(totalSupply() < ARTISTXPSUPPLY, "Collection is sold out");
        // sale must be active
        require(saleIsActive(), "Sale not active yet");

        // must have minimum amount of lost tokens
        require(lostToken.balanceOf(msg.sender) >= ARTISTXPPRICE, "Not enough LOST");

        // update mapping for nft owners
        trackOwners[msg.sender] = true;

        // add id to mintedTracks
        mintedTracks.push(tokenId);

        // burn lost tokens
        burnToken(ARTISTXPPRICE);

        // mint tokenid to msg.sender
        _mintTokens(msg.sender, tokenId);
    }

    // View Functions
    function tokenURI(uint256 tokenId) override public view returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        return string(abi.encodePacked(_baseURI(), uint256(tokenId).toString()));
    }

    // Get Minted Tracks
    function getMintedTracks() public view returns (uint[] memory) {
        return mintedTracks;
    }

    // Check if sale is active
    function saleIsActive() public view returns(bool) {
        return _saleIsActive;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    // Internal Functions

    // mint token using erc721 safe mint
    function _mintTokens(address _to, uint256 _tokenId) internal {
        _safeMint(_to, _tokenId);
    }

    // Burn lost tokens
    function burnToken(uint256 _amountOfLostTokens) internal {
        lostToken.burnFrom(msg.sender, _amountOfLostTokens);
    }

    function _baseURI() override internal view returns(string memory) {
        return _metaBaseUri;
    }

    function approve(uint256 _tokenId, address _from) internal virtual {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner");
        isApprovedForAll(_from, address(this));
    }

    function _checkTrack(address owner) internal view returns (bool) {
        return !trackOwners[owner];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}