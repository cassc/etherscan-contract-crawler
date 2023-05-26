//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// @title:  LETSMILE
// @url:    https://cryptopuppets.io
// @artist: https://www.instagram.com/lapofatai
// @team:   https://cryptopuppets.io
// @author: https://medusa.dev

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract LetSmile is Ownable, ERC721Enumerable, IERC2981 {
    event MetadataRevealed();
    event MintingEnabled();
    event MintingEnded();

    uint256 private constant MAX_SUPPLY = 111;
    mapping(address => uint256) private allowList;
    bool private allowListInitialized;

    address public royaltyReceiver;
    uint256 public royaltyPercentage;
    string public baseURI;
    string public unrevealedTokenURI;
    bool public isMetadataLocked;
    bool public isMetadataRevealed;
    bool public isMintingEnabled;
    bool public hasMintingEnded;

    constructor(string memory unrevealedTokenURI_) ERC721("LetSmile", "LTSML") {
        unrevealedTokenURI = unrevealedTokenURI_;
        royaltyReceiver = owner();
        royaltyPercentage = 1000;
    }

    function initAllowList(
        address[] calldata addresses,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(!allowListInitialized, "Allow list already initialized");
        require(
            addresses.length == amounts.length,
            "Addresses and amounts must have the same length"
        );
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = amounts[i];
            totalAmount += amounts[i];
        }
        require(
            totalAmount == MAX_SUPPLY,
            "Total token amount must be equal to max supply"
        );
        allowListInitialized = true;
    }

    function enableMinting() external onlyOwner {
        require(allowListInitialized, "Allow list is not initialized");
        require(!isMintingEnabled, "Minting already enabled");
        require(!hasMintingEnded, "Minting has ended");
        isMintingEnabled = true;
        emit MintingEnabled();
    }

    function endMinting() external onlyOwner {
        require(isMintingEnabled, "Minting has not been enabled");
        require(!hasMintingEnded, "Minting has been already ended");
        uint256 tokensToMint = MAX_SUPPLY - totalSupply();
        for (uint256 i = 0; i < tokensToMint; i++) {
            _mint(msg.sender, totalSupply() + 1);
        }
        isMintingEnabled = false;
        hasMintingEnded = true;
        emit MintingEnded();
    }

    function mint() external {
        require(allowListInitialized, "Allow list not initialized");
        require(!hasMintingEnded, "Minting has ended");
        require(isMintingEnabled, "Minting is not enabled");
        require(allowList[msg.sender] > 0, "Not allowed to mint");
        require(
            totalSupply() + allowList[msg.sender] <= MAX_SUPPLY,
            "Token supply would exceed"
        );
        for (uint256 i = 0; i < allowList[msg.sender]; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
        allowList[msg.sender] = 0;
        if (totalSupply() == MAX_SUPPLY) {
            isMintingEnabled = false;
            hasMintingEnded = true;
        }
    }

    function revealMetadata() external onlyOwner {
        require(!isMetadataRevealed, "Metadata are already revealed");
        isMetadataRevealed = true;
        emit MetadataRevealed();
    }

    function lockMetadata() external onlyOwner {
        require(!isMetadataLocked, "Metadata are already locked");
        require(isMetadataRevealed, "Metadata are not revealed");
        isMetadataLocked = true;
    }

    function setRoyaltyReceiver(address royaltyReceiver_) external onlyOwner {
        royaltyReceiver = royaltyReceiver_;
    }

    function setRoyaltyPercentage(uint256 royaltyPercentage_)
        external
        onlyOwner
    {
        require(royaltyPercentage_ <= 10000, "Royalty percentage Too high");
        royaltyPercentage = royaltyPercentage_;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        return (royaltyReceiver, (salePrice * royaltyPercentage) / 10000);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        return
            isMetadataRevealed ? super.tokenURI(tokenId) : unrevealedTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        require(!isMetadataLocked, "Metadata are locked");
        baseURI = baseURI_;
    }

    function getReservedTokensCount(address addr)
        public
        view
        returns (uint256)
    {
        return allowList[addr];
    }
}