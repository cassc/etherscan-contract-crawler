// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

//    F R A G M E N T S
//    E \             E \
//    T   \           T   \
//    E     \         E     \
//    R       \       R       \
//    N         F R A G M E N T S
//    A         E     A         E
//    F R A G M T N T S         T
//      \       E       \       E
//        \     R         \     R
//          \   N           \   N
//            \ A             \ A
//              F R A G M E N T S

/** @title Fragment */
contract Fragment is ERC721Enumerable, Ownable {

    bool public mintingActive = false;
    uint256 public constant mintPrice = 0.06 * 1e18;
    uint256 public constant txQtyLimit = 10;
    uint256 public constant maxSupply = 2828;
    uint256 public constant reservedTokens = 28;
    string private currentBaseURI = "";

    event Received(address, uint);

    constructor() ERC721("Fragment", "EF") {
    }

    /** @dev Mints a token
    * @param quantity The quantity of tokens to mint
    */
    function mint(uint256 quantity) public payable {
        require(mintingActive == true, "Minting is not active");
        require(msg.value >= getValue(quantity), "Insuffucient payment");
        require(quantity <= txQtyLimit, "Quantity exceeds transaction limit");
        uint supply = totalSupply();
        /// Disallow transactions that would exceed the maxSupply
        require(supply + quantity < maxSupply, "Supply is exhausted");

        /// mint the requested quantity
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
        }
    }

    /**
    * @dev Toggle minting state
    */
    function toggleMintingActive() public onlyOwner {
        mintingActive = !mintingActive;
    }

    /** @dev Calculate the transaction value necessary for a given token quantity
    * @param quantity The quantity of tokens to mint
    * @return The amount of ether (in GWEI) required to fulfil the mint
    */
    function getValue(uint256 quantity) private pure returns(uint256) {
        return SafeMath.mul(mintPrice, quantity);
    }

    /** @dev Update the base URI
    * @param baseURI_ New value of the base URI
    */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        currentBaseURI = baseURI_;
    }
    
    /** @dev Get the current base URI
    * @return currentBaseURI
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return currentBaseURI;
    }

    /**
    * @dev Set some tokens aside for the creators
    */
    function reserveTokens() public onlyOwner {        
        for (uint256 i = 0; i < reservedTokens; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
        }
    }

    /**
     * @dev Withdraw ether to owner's wallet
     */
    function withdrawEth() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}(''); 
        require(success, "Withdraw failed");
    }   

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}