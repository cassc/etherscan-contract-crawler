// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// File: contracts/StreetMachineUnlocked.sol

/**
 * @title StreetMachineUnlocked contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract StreetMachineUnlocked is
    ERC721,
    ERC721Enumerable,
    Ownable,
    Pausable,
    ReentrancyGuard,
    VRFConsumerBase
{
    using SafeMath for uint256;

    // Constant variables
    // ------------------------------------------------------------------------
    uint256 public constant MAX_SUPPLY = 8000;
    address public constant nftContract =
        0xaaA7A35e442a77e37cDE2f445b359AAbF5AD0387;
    address public constant burnAddress =
        0x000000000000000000000000000000000000dEaD;

    // State variables
    // ------------------------------------------------------------------------
    string private _baseUri;
    string private _baseCid;
    bool public isRevealActive = false;
    uint256[] private revealedIds;
    uint256 private cidIndex = 0;

    // Sale mappings
    // ------------------------------------------------------------------------
    mapping(uint256 => string) public cids;
    mapping(uint256 => bool) public revealed;

    // Chainlink
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomNumber;

    // Events
    event TokenRevealed(address _from, uint256 _tokenId, string _cid);

    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyRevealActive() {
        require(isRevealActive, "Reveal is not active");
        _;
    }

    modifier onlyEOA() {
        require(
            tx.origin == msg.sender,
            "Contract caller must be externally owned account"
        );
        _;
    }

    modifier revealCompliance(uint256 tokenId) {
        require(totalSupply() + 1 <= MAX_SUPPLY, "Exceeds max supply");
        require(!revealed[tokenId], "Already revealed");
        _;
    }

    // Constructor
    // ------------------------------------------------------------------------
    constructor(
        string memory name,
        string memory symbol,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _link) ERC721(name, symbol) {
        keyHash = _keyHash;
        fee = _fee;
    }

    // URI functions
    // ------------------------------------------------------------------------
    function setBaseURI(string memory baseUri) public onlyOwner {
        _baseUri = baseUri;
    }

    function setBaseCID(string memory baseCid) public onlyOwner {
        _baseCid = baseCid;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        if (revealed[tokenId] && bytes(cids[tokenId]).length > 0) {
            return string(abi.encodePacked(_baseUri, cids[tokenId]));
        }

        return string(abi.encodePacked(_baseUri, _baseCid, "/", tokenId));
    }

    // Operational functions
    // ------------------------------------------------------------------------
    function flipRevealActive() public onlyOwner {
        isRevealActive = !isRevealActive;
    }

    function setCids(string[] memory _cids) public onlyOwner {
        for (uint256 i = 0; i < _cids.length; i++) {
            cids[cidIndex] = _cids[i];
            cidIndex += 1;
        }
    }

    function emergencySetCid(uint256 tokenId, string memory cid)
        public
        onlyOwner
        returns (string memory)
    {
        return cids[tokenId] = cid;
    }

    function getCid(uint256 tokenId) public view returns (string memory) {
        return cids[tokenId];
    }

    function getRevealedIds() public view returns (uint256[] memory) {
        return revealedIds;
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _tokensOfOwner = new uint256[](
            ERC721.balanceOf(owner)
        );
        uint256 i;

        for (i = 0; i < ERC721.balanceOf(owner); i++) {
            _tokensOfOwner[i] = ERC721Enumerable.tokenOfOwnerByIndex(owner, i);
        }
        return (_tokensOfOwner);
    }

    // Override functions
    // ------------------------------------------------------------------------
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
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

    // Chainlink
    // ------------------------------------------------------------------------
    function shuffle() public onlyOwner {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomNumber = (randomness % 7999) + 1;
    }

    // Reveal functions
    // ------------------------------------------------------------------------

    function reveal(uint256 tokenId)
        public
        nonReentrant
        whenNotPaused
        onlyEOA
        onlyRevealActive
        revealCompliance(tokenId)
    {
        IERC721 nft = IERC721(nftContract);
        address tokenOwner = nft.ownerOf(tokenId);
        require(tokenOwner == msg.sender, "Not token owner");
        require(
            nft.isApprovedForAll(msg.sender, address(this)),
            "No permission to transfer"
        );
        nft.transferFrom(msg.sender, burnAddress, tokenId);

        uint256 sequenceId = (tokenId + randomNumber) % MAX_SUPPLY;
        _mint(_msgSender(), sequenceId);
        revealed[sequenceId] = true;
        revealedIds.push(sequenceId);

        emit TokenRevealed(msg.sender, sequenceId, cids[sequenceId]);
    }
}