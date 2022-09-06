// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "https://github.com/FrankNFT-labs/ERC721F/blob/v1.0.3/ERC721F.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title KikiCity contract
 * @dev Extends ERC721F Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumarable , but still provide a totalSupply() implementation.
 * @author @FrankNFT.eth
 * 
 */

contract KikiCity is ERC721F {
    
    uint256 public tokenPrice = 0.06 ether; 
    uint256 public tunaPrice = 0.045 ether;   
    uint256 public constant MAX_TOKENS=3333;
    uint public constant MAX_PURCHASE = 26; // set 1 to high to avoid some gas
    uint public constant MAX_RESERVE = 26; // set 1 to high to avoid some gas
    
    bool public saleIsActive;
    bool public preSaleIsActive;
    
    address public mintpass = 0x7973bf63218d305f908307FCD5A89b093b88C594;  
    address public tunaPass = 0x67cA258BDBE0Dc0cB756e4F0b7348F6733CE924a;
    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant RISA = 0xE59dC42b11e78Ba405Fe59D2d4215bbE1dC790B8;
    address private constant FLASH = 0xAD5eBf58e2fa5Dc22357A8B10F4C2ca4D9Cf9AEe;
    address private constant KIKI = 0xfe3b88B371cD268645686b1EeBa9Fb31d10eF874;
    
    event priceChange(address _by, uint256 price);

    constructor() ERC721F("Kiki City Beach Party", "KCBP") {
        setBaseTokenURI("ipfs://QmQ14y73R3dr9DKniL1nHerQu1UMVETNq9MXBiSRoXV6F2/"); 
        _mint( FRANK, 0);
    }

    /**
     * Mint Tokens to a wallet.
     */
    function mint(address to,uint numberOfTokens) public onlyOwner {    
        uint supply = totalSupply();
        require(supply + numberOfTokens <= MAX_TOKENS, "Reserve would exceed max supply of Tokens");
        require(numberOfTokens < MAX_RESERVE, "Can only mint 25 tokens at a time");
        for (uint i = 0; i < numberOfTokens;) {
            _safeMint(to, supply + i);
            unchecked{ i++;}
        }
    }
     /**
     * Mint Tokens to the owners reserve.
     */
    function reserveTokens() external onlyOwner {    
        mint(owner(),MAX_RESERVE-1);
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
        if(saleIsActive){
            preSaleIsActive=false;
        }  
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    /**    
    * Set mintPass contract address
    */
    function setMintPass(address newAddress) external onlyOwner {
         mintpass = newAddress;
    }

        /**    
    * Set mintPass contract address
    */
    function setTunaPass(address newAddress) external onlyOwner {
         tunaPass = newAddress;
    }

    /**     
    * Set price 
    */
    function setPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
        emit priceChange(msg.sender, tokenPrice);
    }
    /**
    * PUBLIC mint method.
    */
    function mint(uint256 numberOfTokens) external payable {
        require(msg.sender == tx.origin);
        require(saleIsActive, "Sale must be active to mint Tokens");
        // add tuna discount
        if(hasTunaPass(msg.sender)){
            require(tunaPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");  
        } else {
            require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");  
        }
        iternalMint(numberOfTokens);
    }
    /**
    * Presale mint method.
    */
    function preSalemint(uint256 numberOfTokens) external {
        require(preSaleIsActive, "Sale must be active to mint Tokens");
        require(IERC1155(mintpass).balanceOf(msg.sender,0)>=numberOfTokens,"Purchase would exceed number of kiki Tickets");
        IERC1155(mintpass).safeTransferFrom(msg.sender,0xca5771eDbf49Bf29bE9407B0429195e2B95a0455,0,numberOfTokens,"");
        iternalMint(numberOfTokens);
    }
    /**
    * returns true if the sender has a mint pass.
    */
    function hasMintPass(address sender) public view returns (bool){
        if(sender==address(0)){
            return false;
        } else if (IERC1155(mintpass).balanceOf(sender,0)>0){  // more then one kikiTicket can mint
            return true;
        } 
        return false;
    }

    /**
     * Does the sender have a Tuna Pass.
     */
     
    function hasTunaPass(address sender) public view returns(bool){
        if(sender==address(0)){
            return false;
        }
        else{
            bool pass = IERC1155(tunaPass).balanceOf(sender,420)>0;
            return pass;
        }
    }
/**
    * returns true if the sender has a mint pass.
    */
    function mintPassBalance(address sender) external view returns (uint){
        return IERC1155(mintpass).balanceOf(sender,0);
    }


    function iternalMint(uint256 numberOfTokens) private{
        require(numberOfTokens != 0, "numberOfNfts cannot be 0");
        require(numberOfTokens < MAX_PURCHASE, "Can only mint 25 tokens at a time");
        uint256 supply = totalSupply();
        require(supply+numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        for(uint256 i; i < numberOfTokens;){
            _safeMint( msg.sender, supply + i );
            unchecked{ i++;}
        }
    }
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");

        _withdraw(FRANK,(balance * 5) / 100);
        _withdraw(RISA,(balance * 10) / 100);
        _withdraw(FLASH,(balance * 20) / 100);
        _withdraw(KIKI,(balance * 20) / 100);
        _withdraw(owner(), address(this).balance);
    }
}