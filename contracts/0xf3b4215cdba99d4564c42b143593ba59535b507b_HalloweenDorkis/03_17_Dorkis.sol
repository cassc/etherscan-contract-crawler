// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./Royalties.sol";

/**
 * @title Dorkis contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 * 
 */
 //  Twitter @FrankPoncelet
 //
contract Dorkis is Ownable, ERC721Enumerable, Royalties {
    using SafeMath for uint256;

    string public DORKIS_PROVENANCE = "";

    uint256 public dorksPrice = 70000000000000000; //0.07 ETH

    uint public constant MAX_PURCHASE = 10;
    uint public constant MAX_RESERVE = 30;
    uint public constant MAX_SUPPLY_PER_ADDRESS = 100;

    uint256 public MAX_DORKS;
    bool public saleIsActive;
    bool public paybackIsActive;
    
    address payable[] private addr = new address payable[](1);
    uint256[] private royalties = new uint256[](1);
    
    // Base URI for Meta data
    string private _baseTokenURI = "ipfs://Qmb5xMEc738Ra25j4jTiAGNfqtQ17E9kUWGpJWN3utAdGm/"; 
    
    event PaymentReleased(address to, uint256 amount);
    address private constant TORI = 0x51Be0a47282afbE3a330F7738A0Ab5b277810Fe4;
    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant FCCVIEW = 0xf450a5d6C4205ca8151fb1c6FAF49A02c8A527FC;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    

    constructor() ERC721("Dorkis", "DRK") {
        MAX_DORKS = 10000; 
        addr[0]=payable(owner());
        royalties[0]=650; //6.5 % on Rarible
        _safeMint( TORI, 0);
        _safeMint( FRANK, 1);
        _safeMint( FCCVIEW, 2);
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override (ERC721Enumerable,Royalties) returns  (bool){
        return ERC721.supportsInterface(interfaceId) || Royalties.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }
    
    
    function withdraw() public onlyOwner {
        uint256 artists = address(this).balance / 5;
        require(payable(TORI).send(artists));
        require(payable(FRANK).send(artists));
        require(payable(FCCVIEW).send(artists));
        require(payable(owner()).send(artists*2));
        emit PaymentReleased(owner(), artists*2);
    }

    /**
     * Set some Dorkis aside for giveaways.
     */
    function reserveDorkis() public onlyOwner {    
        require(totalSupply().add(MAX_RESERVE) <= MAX_DORKS, "Reserve would exceed max supply of Dorkis");
        uint supply = totalSupply();
        for (uint i = 0; i < MAX_RESERVE; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /*     
     * Set provenance once it's calculated
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        DORKIS_PROVENANCE = provenanceHash;
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
    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /*
     * Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    /*
     * Pause payback on burn if active, make active if paused
     */
    function flipBurnPaybakState() public onlyOwner {
        paybackIsActive = !paybackIsActive;
    }

    /**
     * Mints Dorkis
     */
    function mintDorkis(uint numberOfTokens) public payable {
        require(numberOfTokens > 0, "numberOfNfts cannot be 0");
        require(saleIsActive, "Sale must be active to mint Dorkis");
        require(numberOfTokens <= MAX_PURCHASE, "Can only mint 10 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_DORKS, "Purchase would exceed max supply of Dorkis");
        require(dorksPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        require(balanceOf(msg.sender) + numberOfTokens <= MAX_SUPPLY_PER_ADDRESS, "Exceeds max minted tokens for this address (100)");
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_DORKS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
    
    function preSale(address _to, uint256 numberOfTokens) external onlyOwner() {
        require(totalSupply().add(numberOfTokens) <= MAX_DORKS, "Reserve would exceed max supply of Dorkis");
        require(numberOfTokens <= MAX_PURCHASE, "Can only mint 10 tokens at a time");
        uint256 supply = totalSupply();
        for(uint256 i; i < numberOfTokens; i++){
            _safeMint( _to, supply + i );
        }
    }
    
     /**
      * @dev See {IERC721-transferFrom}.
      * override transfer, to do the payback 80%, when a payback option is active
      * and adapt rare properties to the burn.
      * 
      */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        if (paybackIsActive && to == DEAD){
            Address.sendValue(payable(from), (dorksPrice/100)*80);
            emit PaymentReleased(from, (dorksPrice/100)*80);
        }
    }
  
        /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = super.ownerOf(tokenId);
        require(owner != DEAD, "ERC721: owner query for nonexistent token");
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * adapt rare properties to the burn.
     * 
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(super.ownerOf(tokenId) != DEAD, "ERC721Metadata: URI query for nonexistent token");
        return super.tokenURI(tokenId);
    }
    
    /**
     * Burn multiple tokens but only pay gas once.
     * Will check that you own each of the tokens before it starts burning.
     * 
     */
     
    function multiBurn(uint256[] memory tokenId) public {
         for (uint i = 0; i < tokenId.length; i++) {
             if (_isApprovedOrOwner(_msgSender(), tokenId[i])){
                transferFrom(_msgSender(),DEAD,tokenId[i]);
             }
         }
    }
    
   /**
    * Get all tokens for a specific wallet
    * 
    */
    
    function getTokensForAddress(address fromAddress) external view returns (uint256 [] memory){
        uint256 tokenCount = balanceOf(fromAddress);
        uint256 [] memory result = new uint256[](tokenCount); 
        uint256 total = totalSupply();
        uint256 resultIndex = 0;
        for (uint id = 0; id < total; id++) {
            if (super.ownerOf(id)==fromAddress){
                result[resultIndex] = id;
                resultIndex++;
            }
        }
        return result;
    }
    
    // contract can recieve Ether
    fallback() external payable { }
    receive() external payable { }

    // Royalties implemetations 

    function getFeeRecipients(uint256 tokenId) external view override returns (address payable[] memory){
        require(_exists(tokenId), "DORKIS: FeeRecipients query for nonexistent token");
        return addr;
    }
    // fees.value is the royalties percentage, by default this value is 1000 on Rarible which is a 10% royalties fee.
    function getFeeBps(uint256 tokenId) external view override returns (uint[] memory){
        require(_exists(tokenId), "DORKIS: FeesBPS query for nonexistent token");
        return royalties;
    }

    function getFees(uint256 tokenId) external view override returns (address payable[] memory, uint256[] memory){
        require(_exists(tokenId), "DORKIS: Fees query for nonexistent token");
        return (addr, royalties);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256){
        require(_exists(tokenId), "DORKIS: royaltyInfo query for nonexistent token");
        return (address(this),(salePrice*royalties[0]/10000));
    }
    
    
}