// SPDX-License-Identifier: MIT
/**
        888888b.   d8b 888                                              
        888  "88b  Y8P 888                                              
        888  .88P      888                                              
        8888888K.  888 888888 .d8888b .d88b.  888d888 88888b.  .d8888b  
        888  "Y88b 888 888   d88P"   d88""88b 888P"   888 "88b 88K      
        888    888 888 888   888     888  888 888     888  888 "Y8888b. 
        888   d88P 888 Y88b. Y88b.   Y88..88P 888     888  888      X88 
        8888888P"  888  "Y888 "Y8888P "Y88P"  888     888  888  88888P' 
 */
pragma solidity 0.8.18;

import { IERC721A, ERC721A, ERC721AQueryable } from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Only for the best
 * @author The Bitcorns farmers association
 */
contract BitcornsHonoraries is ERC721AQueryable, Ownable, ReentrancyGuard {
    error SwapNotEnabled();
    error SwapNotAuthorizedFor(uint256 tokenId, address sender);

    event TokenSwapped(uint256 tokenId, string btcAddress);

    string public provenanceHash;
    bool public swapEnabled;
    string public baseURI;
    address payable public payee;

    mapping(uint256 => string) public tokenIdToBTCAddress;

    constructor(string memory baseURI_, address payable payee_) ERC721A("Bitcorns Honoraries", "Bitcorns Honoraries") {
        baseURI = baseURI_;
        payee = payee_;
    }

    function mint(address recipient, uint256 amount) external payable onlyOwner {
        _safeMint(recipient, amount);
    }

    function swapForOrdinal(uint256 tokenId, string calldata btcAddress) external payable nonReentrant {
        if (!swapEnabled) revert SwapNotEnabled();
        if (ownerOf(tokenId) != msg.sender) revert SwapNotAuthorizedFor(tokenId, msg.sender);
        tokenIdToBTCAddress[tokenId] = btcAddress;
        _burn(tokenId);
        emit TokenSwapped(tokenId, btcAddress);
    }

    function setSwapStatus(bool swapEnabled_) external onlyOwner {
        swapEnabled = swapEnabled_;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPayee(address payable payee_) external onlyOwner {
        payee = payee_;
    }

    function withdraw() external {
        Address.sendValue(payee, address(this).balance);
    }

    function withdrawERC20(IERC20 token) external onlyOwner {
        uint balance = token.balanceOf(address(this));
        SafeERC20.safeTransfer(token, payee, balance);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory result = string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));

        return bytes(baseURI).length != 0 ? result : "";
    }
}