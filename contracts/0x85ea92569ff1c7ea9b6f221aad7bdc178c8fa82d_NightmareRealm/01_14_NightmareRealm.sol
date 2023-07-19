// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9 <0.9.0;

import "https://github.com/FrankNFT-labs/ERC721F/blob/v1.0.3/ERC721F.sol";
import "./library/AllowList.sol";

library TimestampHelper {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;

    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
}


contract NightmareRealm is ERC721F,AllowList {
    using Strings for uint256;

    uint256 public tokenPrice = 0.029 ether; 
    uint256 public preSaleTokenPrice = 0.019 ether; 
    uint256 public constant MAX_TOKENS = 4400;
    uint public constant MAX_PURCHASE = 26; // set 1 to high to avoid some gas
    uint public constant MAX_RESERVE = 26; // set 1 to high to avoid some gas
    
    bool public saleIsActive;
    bool public allowListSaleIsActive;

    mapping(address => uint256) private mintAmount;

    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant FFK = 0xd105eA47f73A120Fd2EfE1151E73231A0f9445FD;

    // NIGHT Base URI for Meta data
    string private _nightBaseTokenURI;
    
    constructor() ERC721F("NightmareRealm", "NMR") {
        setBaseTokenURI("ipfs://Qmcd6G7GeFrPbSqin5rRpigHzDVnB5T2bu7XYiMThx4BUA/"); 
        setNightBaseTokenURI("ipfs://Qmcd6G7GeFrPbSqin5rRpigHzDVnB5T2bu7XYiMThx4BUA/"); 
        _mint(FRANK, 0);
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
     * Will deactivate the FREE is it was active.
     */   
    function reserveTokens() external onlyOwner {    
        mint(owner(),MAX_RESERVE-1);
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
        if(saleIsActive){
            allowListSaleIsActive=false;
        }
    }
    /**
     * Pause FREE sale if active, make active if paused
     */
    function flipAllowlistSaleState() external onlyOwner {
        allowListSaleIsActive = !allowListSaleIsActive;
    }

    /**
     * Mint your tokens here.
     */
    function mint(uint256 numberOfTokens) external payable{
        if(allowListSaleIsActive){
            require(isAllowList(msg.sender),"sender is NOT Whitelisted ");
            require(preSaleTokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");  
            require(mintAmount[msg.sender]+numberOfTokens<6,"Purchase would exceed max mint for walet");
            mintAmount[msg.sender] = mintAmount[msg.sender]+numberOfTokens;

        }else{
            require(saleIsActive,"Sale NOT active yet");
            require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");  
            require(numberOfTokens < MAX_PURCHASE, "Can only mint 25 tokens at a time");
        }
        require(numberOfTokens != 0, "numberOfNfts cannot be 0");
        uint256 supply = totalSupply();
        require(supply + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        for(uint256 i; i < numberOfTokens;){
            _safeMint( msg.sender, supply + i );
            unchecked{ i++;}
        }
    }

    /**
     * @dev Set the NIGHT base token URI
     */
    function setNightBaseTokenURI(string memory baseURI) public onlyOwner {
        _nightBaseTokenURI = baseURI;
    }

    function leftToMint(address wallet) external view returns (uint){
        if (isAllowList(wallet)){
            return 5 - mintAmount[wallet];
        }else{
            return 0;
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint currentHour = TimestampHelper.getHour(block.timestamp);
        if (currentHour >= 5 && currentHour <= 17){
            // DAY mode
            return super.tokenURI(tokenId);
        }else{
            // NIGHT mode
            string memory baseURI = _nightBaseTokenURI;
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
        }
    }
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(FFK,(balance * 13) / 100);
        _withdraw(owner(), address(this).balance);
    }

}