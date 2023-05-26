// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "https://github.com/FrankNFT-labs/ERC721F/blob/v1.0.3/ERC721F.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/token/ERC721/IERC721.sol";


/**
 * @title DayJob Punks contract
 * @dev Extends ERC721F Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumarable , but still provide a totalSupply() implementation.
 * @author @FrankNFT.eth
 * 
 */

contract DayJobPunks is ERC721F {
    
    uint256 public tokenPrice = 0.0165 ether; 
    uint256 public constant MAX_TOKENS = 10000;
    uint256 public nextPunkIndexToAssign = 0;
    uint256 public punksRemainingToAssign;
    
    uint public constant MAX_PURCHASE = 26; // set 1 to high to avoid some gas
    uint public constant MAX_RESERVE = 26; // set 1 to high to avoid some gas
    
    bool public saleIsActive;
    bool public freeClaimIsActive;

    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    IERC721 private constant V1PUNKS = IERC721(0x282BDD42f4eb70e7A9D9F40c8fEA0825B7f68C5D); 
    
    event priceChange(address _by, uint256 price);
    
    constructor() ERC721F("DayJobPunks", "PEA") {
        setBaseTokenURI("ipfs://QmNSPEx1gqbnjJCU9NwrajwkM4AAHkd1U45kYBcVyt4KEq/"); 
        _mint(FRANK, 0);
        unchecked{
            nextPunkIndexToAssign++;
            punksRemainingToAssign=MAX_TOKENS-1;
        }
    }

    /**
     * Mint Tokens to a wallet.
     */
    function airdrop(address to,uint numberOfTokens) public onlyOwner {    
        require(nextPunkIndexToAssign + numberOfTokens <= MAX_TOKENS, "Reserve would exceed max supply of Tokens");
        require(numberOfTokens < MAX_RESERVE, "Can only mint 25 tokens at a time");
        for (uint i = 0; i < numberOfTokens;) {
            if(!_exists(nextPunkIndexToAssign)){
                _safeMint(to, nextPunkIndexToAssign);
                unchecked{
                    punksRemainingToAssign--;
                }
            }
            unchecked{ 
                nextPunkIndexToAssign++;
                i++;
            }           
        }
    }
     /**
     * Mint Tokens to the owners reserve.
     * Will deactivate the FREE is it was active.
     */   
    function reserveTokens() external onlyOwner {    
        airdrop(owner(),MAX_RESERVE-1);
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
        if(saleIsActive){
            freeClaimIsActive=false;
        }
    }
    /**
     * Pause FREE sale if active, make active if paused
     */
    function flipClaimSaleState() external onlyOwner {
        freeClaimIsActive = !freeClaimIsActive;
    }

    /**     
    * Set price 
    */
    function setPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
        emit priceChange(msg.sender, tokenPrice);
    }

    /**
     * Mint your FREE punks here.
     */
    function getPunk(uint256 tokenId) external {
        require(freeClaimIsActive,"Free claim NOT active"); 
        require(!_exists(tokenId),"Token already minted");
        require(V1PUNKS.ownerOf(tokenId)==msg.sender,"You need to own the V1");
        _safeMint( msg.sender, tokenId );
        unchecked{punksRemainingToAssign--;}
    }

        /**
     * Owner claims.
     */
    function ownerClaim(address to, uint256 tokenId) external onlyOwner{
        require(!_exists(tokenId),"Token already minted");
        require(tokenId<MAX_TOKENS,"Token nr too big");
        _safeMint( to, tokenId );
        unchecked{punksRemainingToAssign--;}
    }

    /*
    * Helper method to reduce gas if a major block would get claimed.
    */
    function movePunkNextPunkIndex(uint256 tokenId) external onlyOwner{
        nextPunkIndexToAssign=tokenId;
    }

    /**
     * Mint your tokens here.
     */
    function mint(uint256 numberOfTokens) external payable{
        require(saleIsActive,"Sale NOT active yet");
        require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");  
        require(numberOfTokens != 0, "numberOfNfts cannot be 0");
        require(numberOfTokens < MAX_PURCHASE, "Can only mint 25 tokens at a time");
        require(numberOfTokens<=punksRemainingToAssign,"Purchase would exceed max supply of Tokens");
        for(uint256 i; i < numberOfTokens && punksRemainingToAssign !=0;){
            if(!_exists(nextPunkIndexToAssign) && nextPunkIndexToAssign < MAX_TOKENS){
                _safeMint( msg.sender, nextPunkIndexToAssign );
                unchecked{ 
                    punksRemainingToAssign--;
                }
            }else if(totalSupply()<MAX_TOKENS && nextPunkIndexToAssign < MAX_TOKENS){ 
                unchecked{numberOfTokens++;}
            }
            unchecked{ 
                i++;             
                nextPunkIndexToAssign++;
            }
        }
    }

    function exists(uint256 tokenId) external view returns (bool){
        return _exists(tokenId);
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(owner(), address(this).balance);
    }
}