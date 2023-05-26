// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import { Base64 } from "./libraries/Base64.sol";

contract AlphaFlyersNFT is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public immutable whitelistMintPrice = 0.15 ether;
    uint256 public immutable maxIds = 333;

    bool public whitelistMintState;

    mapping(address => uint256) public allowlist;
    uint256 public minted = 0;

    modifier whitelistOnly() {
        require(whitelistMintState, "Whitelist mint has not started yet.");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    event NewAlphaFlyersNFTMinted(address sender, uint256 tokenId);

    constructor() ERC721("Alpha Flyers", "FLYER") {
        whitelistMintState = false;
    }

    function seedAllowlist(
        address[] memory addresses,
        uint256[] memory numSlots
    ) external onlyOwner {
        require(
            addresses.length == numSlots.length,
            "addresses does not match numSlots length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
        }
    }

    function devMint(uint256 quantity) external onlyOwner {
        for (uint256 i = 0; i < quantity; i++) {
            uint256 currentTokenIds = _tokenIds.current();

            string memory combinedTokenURI =
                string(abi.encodePacked("https://ipfs.io/ipfs/bafybeibwfqrtp6q4on4t7cdr55zx4j4uephpp6vswc4773uji32shjou4u/", Strings.toString(currentTokenIds), ".token.json"));
            
            _safeMint(msg.sender, currentTokenIds);
            _setTokenURI(currentTokenIds, combinedTokenURI);
            _tokenIds.increment();
            minted++;

            emit NewAlphaFlyersNFTMinted(msg.sender, currentTokenIds);
        }
    }

    function openWhiteListMint() public onlyOwner {
        whitelistMintState = true;
    }

    function closeWhiteListMint() public onlyOwner {
        whitelistMintState = false;
    }

    function whitelistMint() external payable callerIsUser whitelistOnly {
        require(whitelistMintState == true, "whitelist sale has not begun yet");

        // To check if the sender is whitelisted
        require(allowlist[msg.sender] > 0, "not eligible for whitelist mint");

        // To double check the mint price
        require(
            msg.value >= whitelistMintPrice,
            "change your mint price to 0.15 eth"
        );

        allowlist[msg.sender]--;

        uint256 currentTokenIds = _tokenIds.current();

        string memory combinedTokenURI =
            string(abi.encodePacked("https://ipfs.io/ipfs/bafybeibwfqrtp6q4on4t7cdr55zx4j4uephpp6vswc4773uji32shjou4u/", Strings.toString(currentTokenIds), ".token.json"));

        _safeMint(msg.sender, currentTokenIds);
        _setTokenURI(currentTokenIds, combinedTokenURI);
        _tokenIds.increment();
        minted++;
        emit NewAlphaFlyersNFTMinted(msg.sender, currentTokenIds);
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}