// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721EnumerableChaos.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
             (               )    )                    )       (    (    (     
  *   )      )\ )         ( /( ( /(    (            ( /(       )\ ) )\ ) )\ )  
` )  /( (   (()/(    (    )\()))\())   )\ )    (    )\()) (   (()/((()/((()/(  
 ( )(_)))\   /(_))   )\ |((_)\((_)\   (()/(    )\  ((_)\  )\   /(_))/(_))/(_)) 
(_(_())((_) (_))  _ ((_)|_ ((_) ((_)   /(_))_ ((_)  _((_)((_) (_)) (_)) (_))   
|_   _|| __|| _ \| | | || |/ / / _ \  (_)) __|| __|| \| || __|/ __||_ _|/ __|  
  | |  | _| |   /| |_| |  ' < | (_) |   | (_ || _| | .` || _| \__ \ | | \__ \  
  |_|  |___||_|_\ \___/  _|\_\ \___/     \___||___||_|\_||___||___/|___||___/  
**/

/**
 * @title Teruko Genesis ERC-721 Smart Contract
 */

contract TerukoGenesis is ERC721EnumerableChaos, Ownable, Pausable {

    string private baseURI;
    uint256 public mintTokenIndex = 1;
    uint256 public numTokensMinted = 0;
    uint256 public numTokensBurned = 0;

    constructor() ERC721("Teruko Genesis", "TERUKOG") {}

    /**
    *  @notice mint n numbers of tokens
    */
    function mintTokens(uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = mintTokenIndex;
            numTokensMinted++;
            mintTokenIndex++;
            _safeMint(msg.sender, mintIndex);
        }
    }

    /**
    *  @notice mint a token id to a wallet
    */
    function mintToWallet(address toWallet, uint256 numberOfTokens) public onlyOwner {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = mintTokenIndex;
            numTokensMinted++;
            mintTokenIndex++;
            _safeMint(toWallet, mintIndex);
        }
    }

    /**
    *  @notice get total supply
    */
    function totalSupply() external view returns (uint) { 
        return numTokensMinted - numTokensBurned;
    }

    // BURN IT 
    function burn(uint256 tokenId) external virtual {
	    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        numTokensBurned++;
	    _burn(tokenId);
    }

    // Set BaseURI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    // Withdraw eth if for some stange reason this contract is sent eth
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    /**
    *  @notice Set current mint token index - mintTokenIndex
    */
    function setMintTokenIndex(uint256 tokenIndex) external onlyOwner {
        require(tokenIndex >= 0, "Must be greater or equal than zer0");
        require(!_exists(tokenIndex), "The token already exists");       
        mintTokenIndex = tokenIndex;
    }

    // Pause Contract
    function setPaused(bool _setPaused) external onlyOwner {
	    return (_setPaused) ? _pause() : _unpause();
    }

    // Toggle this function if pausing should suspend transfers
    function _beforeTokenTransfer(
	    address from,
	    address to,
	    uint256 tokenId
    ) internal virtual override(ERC721EnumerableChaos) {
	    require(!paused(), "Pausable: paused");
	    super._beforeTokenTransfer(from, to, tokenId);
    }
}