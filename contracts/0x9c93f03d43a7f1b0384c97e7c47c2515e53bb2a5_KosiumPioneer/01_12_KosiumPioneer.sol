// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title KosiumPioneer
 * KosiumPioneer - a contract for my non-fungible creatures.
 */
contract KosiumPioneer is ERC721, Ownable {
    using SafeMath for uint256;
    
    string public baseURI;

    bool public saleIsActive = false;
    bool public presaleIsActive = false;

    uint256 public maxPioneerPurchase = 5;
    uint256 public maxPioneerPurchasePresale = 2;
    uint256 public constant pioneerPrice = 0.06 ether;

    uint256 public MAX_PIONEERS;
    uint256 public MAX_PRESALE_PIONEERS = 2000;
    uint256 public PIONEERS_RESERVED = 1000;

    uint256 public numReserved = 0;
    uint256 public numMinted = 0;

    mapping(address => bool) public whitelistedPresaleAddresses;
    mapping(address => uint256) public presaleBoughtCounts;

    constructor(
            uint256 maxNftSupply
        )
        ERC721("Kosium Pioneer", "KPR")
    {
        MAX_PIONEERS = maxNftSupply;
    }

    modifier userOnly{
        require(tx.origin==msg.sender,"Only a user may call this function");
        _;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * Returns base uri for token metadata. Called in ERC721 tokenURI(tokenId)
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Changes URI used to get token metadata
    */
    function setBaseTokenURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * Mints numToMint tokens to an address
    */
    function mintTo(address _to, uint numToMint) internal {
        require(numMinted + numToMint <= MAX_PIONEERS, "Reserving would exceed max number of Pioneers to reserve");
        
        for (uint i = 0; i < numToMint; i++) {
            _safeMint(_to, numMinted);
            ++numMinted;
        }
    }

    /**
     * Set some Kosium Pioneers aside
    */
    function reservePioneers(address _to, uint numberToReserve) external onlyOwner { 
        require(numReserved + numberToReserve <= PIONEERS_RESERVED, "Reserving would exceed max number of Pioneers to reserve");

        mintTo(_to, numberToReserve);
        numReserved += numberToReserve;
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * Pause presale if active, make active if paused
    */
    function flipPresaleState() external onlyOwner {
        presaleIsActive = !presaleIsActive;
    }
    
    /**
    * Mints Kosium Pioneers that have already been bought through pledge
    */
    function mintPioneer(uint numberOfTokens) external payable userOnly {
        require(saleIsActive, "Sale must be active to mint Pioneer");
        require(numberOfTokens <= maxPioneerPurchase, "Can't mint that many tokens at a time");
        require(numMinted + numberOfTokens <= MAX_PIONEERS - PIONEERS_RESERVED + numReserved, "Purchase would exceed max supply of Pioneers");
        require(pioneerPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        mintTo(msg.sender, numberOfTokens);
    }

    /**
    * Mints Kosium Pioneers for presale
    */
    function mintPresalePioneer(uint numberOfTokens) external payable userOnly {
        require(presaleIsActive, "Presale must be active to mint Pioneer");
        require(whitelistedPresaleAddresses[msg.sender], "Sender address must be whitelisted for presale minting");
        require(numberOfTokens + presaleBoughtCounts[msg.sender] <= maxPioneerPurchasePresale, "This whitelisted address cannot mint this many Pioneers in the presale.");
        uint newSupplyTotal = numMinted + numberOfTokens;
        require(newSupplyTotal <= MAX_PRESALE_PIONEERS + numReserved, "Purchase would exceed max supply of Presale Pioneers");
        require(newSupplyTotal <= MAX_PIONEERS - PIONEERS_RESERVED + numReserved, "Purchase would exceed max supply of Pioneers");
        require(pioneerPrice.mul(numberOfTokens) <= msg.value, "Provided ETH is below the required price");
        
        mintTo(msg.sender, numberOfTokens);
        presaleBoughtCounts[msg.sender] += numberOfTokens;
    }

    /*
    * Add users to the whitelist for the presale
    */
    function whitelistAddressForPresale(address[] calldata earlyAdopterAddresses) external onlyOwner{
        for (uint i = 0; i < earlyAdopterAddresses.length; i++){
            whitelistedPresaleAddresses[earlyAdopterAddresses[i]] = true;
        }
    }

    /*
    * Remove users from the whitelist for the presale
    */
    function removeFromWhitelist(address[] calldata earlyAdopterAddresses) external onlyOwner{
        for (uint i = 0; i < earlyAdopterAddresses.length; i++){
            whitelistedPresaleAddresses[earlyAdopterAddresses[i]] = false;
        }
    }

    /*
    * Change the max presale limit
    */
    function setPresaleLimit(uint maxToPresale) public onlyOwner{
        require(maxToPresale <= MAX_PIONEERS, "Presale limit cannot be greater than the max supply of Pioneers.");
        MAX_PRESALE_PIONEERS = maxToPresale;
    }

    /*
    * Change the reserved number of Pioneers
    */
    function setReserveLimit(uint reservedLimit) public onlyOwner{
        require(reservedLimit <= MAX_PIONEERS, "Reserve supply cannot be greater than the max supply of Pioneers.");
        require(numReserved <= reservedLimit, "Reserve supply cannot be less than the number of Pioneers already reserved.");
        require(reservedLimit < PIONEERS_RESERVED, "Can only reduce the number of Pioneers reserved.");
        PIONEERS_RESERVED = reservedLimit;
    }

    /*
    * Change the max number of pioneers each account can purchase at a time in the open sale
    */
    function setPurchaseLimit(uint purchaseLimit) public onlyOwner{
        require(purchaseLimit <= MAX_PIONEERS, "The max number of pioneers to purchase for each account cannot be greater than the maximum number of Pioneers.");
        maxPioneerPurchase = purchaseLimit;
    }

    /*
    * Change the max number of pioneers each account can purchase at a time in the presale
    */
    function setPurchaseLimitPresale(uint purchaseLimit) public onlyOwner{
        require(purchaseLimit <= MAX_PIONEERS, "The max number of pioneers to purchase for each account cannot be greater than the maximum number of Pioneers.");
        maxPioneerPurchasePresale = purchaseLimit;
    }
}