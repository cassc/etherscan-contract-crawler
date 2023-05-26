// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ITopDogBeachClub.sol";
import "./ITopDogPortalizer.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title TCBC contract v1
 * @author @darkp0rt
 */
contract TopCatBeachClub is ERC721Enumerable, IERC721Receiver, Ownable, ReentrancyGuard {
    uint256 private constant MAX_CATS = 8000;
    uint256 private constant DEV_CATS = 100;

    string public TCBC_PROVENANCE;
    address private _tdbcAddress;
    address private _tdptAddress;
    string private _baseTokenURI;
    bool private _claimPeriodIsOpen = false;
    bool private _canReserve = true;
    mapping (uint256 => uint256) private _catBirthdays;

    constructor (string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address tdbcAddress,
        address tdptAddress) ERC721(name, symbol)
    {
        _baseTokenURI = baseTokenURI;
        _tdbcAddress = tdbcAddress;
        _tdptAddress = tdptAddress;
    }

    function toggleClaimPeriod() external onlyOwner {
        _claimPeriodIsOpen = !_claimPeriodIsOpen;
    }

    function claimPeriodIsOpen() external view returns (bool status) {
        return _claimPeriodIsOpen;
    }

    /*
    * A SHA256 hash representing all cats. Will be set once the mint period has ended
    */
    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        TCBC_PROVENANCE = provenanceHash;
    }

    function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    /*
    * Message Jakub "I heard you like chicken" on Discord
    */
    function stepThroughThePortal(uint256[] memory claimIds) external nonReentrant() {
        require(_claimPeriodIsOpen, "Claim period is not open");
        
        for (uint256 i = 0; i < claimIds.length; i++) {
            uint256 tokenId = claimIds[i];
            require(ITopDogBeachClub(_tdbcAddress).ownerOf(tokenId) == msg.sender || ITopDogPortalizer(_tdptAddress).ownerOf(tokenId) == msg.sender, "Claimant is not the owner");

            _mintCat(msg.sender, tokenId);
        }
    }

    /*
    * Called once by the dev team to mint unclaimed cats after the claim period ends. Used for giveaways, marketing, etc.
    */
    function reserve(uint256[] memory tokenIds) external onlyOwner {
        require(block.timestamp > 1633903200, "Not yet");
        require(!_claimPeriodIsOpen, "Claim is still open..?");
        require(_canReserve, "Already called");
        require(tokenIds.length <= DEV_CATS, "Too many cats");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mintCat(msg.sender, tokenIds[i]);
        }

        _canReserve = false;
    }

    /*
    * 🔥 🔥 🔥 
    */
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * @notice Returns a list of all tokenIds assigned to an address - used by the TDBC website
     * Taken from https://ethereum.stackexchange.com/questions/54959/list-erc721-tokens-owned-by-a-user-on-a-web-page
     * @param user get tokens of a given user
     */
    function tokensOfOwner(address user) external view returns (uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(user);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory output = new uint256[](tokenCount);

            for (uint256 index = 0; index < tokenCount; index++) {
                output[index] = tokenOfOwnerByIndex(user, index);
            }
            
            return output;
        }
    }

    /*
     * I hope you bought cake?
    */
    function getBirthday(uint256 tokenId) external view returns (uint256) {
        return _catBirthdays[tokenId];
    }

    function _mintCat(address owner, uint256 tokenId) private {
        require(totalSupply() + 1 <= MAX_CATS, "Mint would exceed max supply of cats");

        _safeMint(owner, tokenId);
        _catBirthdays[tokenId] = block.timestamp;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}