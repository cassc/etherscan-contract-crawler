// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/token/ERC1155/IERC1155.sol";


/**
 * @title KikiCity contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 * @author @FrankPoncelet
 * 
 */

contract KikiCity is Ownable, ERC721Enumerable {
    using SafeMath for uint256;

    uint256 public tokenPrice = 0.06 ether; 
    uint256 public presaleTokenPrice = 0.045 ether; 
    uint256 public MAX_TOKENS;

    uint public constant maxPurchase = 25;

    bool public saleIsActive;
    bool public preSaleIsActive;
    
    // Base URI for badge data
    string private _baseTokenURI ="ipfs://QmU2FaP4Ds23DujkR9g2x1UX1ShFjxBVXmtnf56B9Aedm5/"; 
    
    // link to the mintpass
    address public mintPass;
    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant PROF = 0x22217814CDFF567Ac861a4f0E70d345f694f00E8;
    address private constant PEACH = 0x517fFB296abEcf29652e0C478b9cB721E24a84b5;
    address private constant PROX = 0xe7325ac09D0F8a0a0fc80606D3Db3FFF00706C69;
    address private constant HIENA = 0x8E838Ae5e4528BdB1e6A6a102AB3F31dEF399C82;
    address private constant KIKI = 0xfe3b88B371cD268645686b1EeBa9Fb31d10eF874;
    address private constant FLASH = 0xCfdf1EFf7049Bbc761292eb31528072BbD2a880b;
    address private constant MORTY = 0x2E06c573B9fbe304cD1796ebC2a0bA4b82C311c9;
    address private constant BLAKK = 0x458CA06D92777c19Dd16c93C898BE0215f6D462e;
             
    event PaymentReleased(address to, uint256 amount);

    constructor() ERC721("Kiki City", "KIKI") {
        MAX_TOKENS = 10000;
        mintPass = 0x67cA258BDBE0Dc0cB756e4F0b7348F6733CE924a; 
        _safeMint( FRANK, 0);
    }

     /**    
    * Set mintPass contract address
    */
    function setMintPass(address newAddress) external onlyOwner {
         mintPass = newAddress;
    }

    /**
     * Used to mint Toens to the teamMembers
     */
    function reserveTokens(address to,uint numberOfTokens) public onlyOwner {    
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Reserve would exceed max supply of Tokens");
        require(numberOfTokens <= maxPurchase, "Can only mint 20 tokens at a time");
        uint supply = totalSupply();
        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(to, supply + i);
        }
    }
    
    function reserveTokens() external onlyOwner {    
        reserveTokens(msg.sender,maxPurchase);
    }
    
    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    /**
   * @dev Set the base token URI
   */
    function setBaseTokenURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * Pause pre-sale if active, make active if paused
    */
    function flipPreSaleState() external onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }
    
    /**
    * Mints Tokens
    */
    function mintTokens(uint numberOfTokens) external payable {
        require(numberOfTokens > 0, "numberOfNfts cannot be 0");
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= maxPurchase, "Can only mint 25 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        require(tokenPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
    
    /**
    * Mints Tokens
    */
    function mintPreSaleTokens(uint numberOfTokens) external payable {
        require(numberOfTokens > 0, "numberOfNfts cannot be 0");
        require(preSaleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= maxPurchase, "Can only mint 25 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        require(presaleTokenPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        require(IERC1155(mintPass).balanceOf(msg.sender,420)>0,"You MUST have a mintpass to use mintPreSaleTokens");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
    
    /**
     * Does the sender have a Tuna Pass.
     */
     
    function hasTunaPass() external view returns(bool){
        if(msg.sender==address(0)){
            return false;
        }
        else{
            bool pass = IERC1155(mintPass).balanceOf(msg.sender,420)>0;
            return pass;
        }
    }
    
    /**
    * Get all tokens for a specific wallet
    * 
    */
    function getTokensForAddress(address fromAddress) external view returns (uint256 [] memory){
        uint tokenCount = balanceOf(fromAddress);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(fromAddress, i);
        }
        return tokensId;
    }
    
    /**
     *  Withdraw funds from the contract
     */
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(FRANK, ((balance * 5) / 100));
        _withdraw(PROF, ((balance * 5) / 100));
        _withdraw(PEACH, ((balance * 2) / 100));
        _withdraw(PROX, ((balance ) / 100));        
        _withdraw(HIENA, ((balance * 5) / 100));
        _withdraw(KIKI, ((balance * 15) / 100));
        _withdraw(FLASH, ((balance * 15) / 100));
        _withdraw(MORTY, ((balance * 10) / 100));
        _withdraw(BLAKK, ((balance * 10) / 100));
        _withdraw(owner(), address(this).balance);
        emit PaymentReleased(owner(), balance);
    }
    
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }
    
    // contract can recieve Ether
    fallback() external payable { }
    receive() external payable { }
}