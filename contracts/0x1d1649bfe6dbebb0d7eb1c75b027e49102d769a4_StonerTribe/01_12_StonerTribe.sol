// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
                  |
                 |.|
                 |.|
                |\./|
                |\./|
.               |\./|               .
 \^.\          |\\.//|          /.^/
  \--.|\       |\\.//|       /|.--/
    \--.| \    |\\.//|    / |.--/
     \---.|\    |\./|    /|.---/
        \--.|\  |\./|  /|.--/
           \ .\  |.|  /. /
 _ -_^_^_^_-  \ \\ // /  -_^_^_^_- _
   - -/_/_/- ^ ^  |  ^ ^ -\_\_\- -
            stoner tribe
*/

/**
 * @title Stoner Tribe ERC-721 Smart Contract
 */

contract StonerTribe is ERC721, Ownable, ReentrancyGuard {

    string private baseURI;
    uint256 public constant MAX_TOKENS = 9421;
    uint256 public numTokensMinted = 0;
    uint256 public numTokensBurned = 0;

    uint256 public constant MAX_TOKENS_PURCHASE = 21;
    constructor() ERC721("Tribe", "TRBE") {}

    /**
    *  @notice public mint function
    */
    function mint(uint256 numberOfTokens) external nonReentrant{
        require(tx.origin == msg.sender);
        require(numberOfTokens < MAX_TOKENS_PURCHASE, "You went over max tokens per transaction");
        require(numTokensMinted + numberOfTokens < MAX_TOKENS, "Not enough tokens left to mint that many");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = numTokensMinted;
            numTokensMinted++;
            _safeMint(msg.sender, mintIndex);
        }
    }

    /**
    *  @notice  get total token supply
    */
    function totalSupply() external view returns (uint) { 
        return numTokensMinted - numTokensBurned;
    }

    /**
    *  @notice  burn token id
    */
    function burn(uint256 tokenId) public virtual {
	    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        numTokensBurned++;
        _burn(tokenId);
    }

    /**
    *  @notice get token base uri
    */
     function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // OWNER FUNCTIONS
    /**
    *  @notice withdraw funds to contract's owners wallet
    */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    /**
    *  @notice reserve mint n numbers of tokens
    */
    function mintReserveTokens(uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = numTokensMinted;
            numTokensMinted++;
            _safeMint(msg.sender, mintIndex);
        }
    }

    /**
    *  @notice mint a token id to a wallet
    */
    function mintTokenToWallet(address toWallet, uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = numTokensMinted;
            numTokensMinted++;
            _safeMint(toWallet, mintIndex);
        }
    }

    // @title SETTER FUNCTIONS
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    // Toggle this function if pausing should suspend transfers
    function _beforeTokenTransfer(
	    address from,
	    address to,
	    uint256 tokenId
    ) internal virtual override(ERC721) {
	    super._beforeTokenTransfer(from, to, tokenId);
    }
}