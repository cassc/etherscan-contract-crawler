//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./EnumerableMap.sol";
import "./ERC721Enumerable.sol";
import "./ERC1155.sol";
import "./token/SafeERC20.sol";

contract DrunkenPandas is ERC721Enumerable, Ownable {

    using SafeMath for uint256;

    // Token detail
    struct DPandasDetail {
        uint256 first_encounter;
    }

    mapping(address => bool) public whitelist;

    // Events
    event TokenMinted(uint256 tokenId, address owner, uint256 first_encounter);

    // Token Detail
    mapping(uint256 => DPandasDetail) private _dPandasDetails;

    // Provenance number
    string public PROVENANCE = "";

    // Max amount of token to purchase per account each time
    uint256 public MAX_PURCHASE = 5;

     // Max amount of token to presale purchase per account each time
    uint256 public PRESALE_MAX_PURCHASE = 3;

    // Maximum amount of tokens to supply.
    uint256 public MAX_TOKENS = 10000;

    // Current price.
    uint256 public CURRENT_PRICE = 88000000000000000;

    // Define if sale is active
    bool public saleIsActive = false;

    // Define if presale is active
    bool public preSaleIsActive = false;

    // Base URI
    string private baseURI;

    /**
   * @dev Throws if called by any account is not whitelisted.
   */
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender],"Sorry, but this address is not on the whitelist. Please message us on Discord.");
    _;
  }

    /**
     * Contract constructor
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    }

    /**
     * With
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
     
     /**
       WhiteList Addresses
      */
    function addAddressesToWhiteList(address[] memory addresses) public onlyOwner
    {
     for(uint i =0;i<addresses.length;i++)
     {
         whitelist[addresses[i]]=true;
     }
    }

    /*
     Whitelist SingleAddress
     */

    function addAddressToWhiteList(address userAddress) public onlyOwner
    {
        whitelist[userAddress]=true;
    }


    /**
      Remove from whitelist
     */
    function removeAddressFromWhiteList(address userAddress) public onlyOwner
    {
        whitelist[userAddress]=false;
    }

    /**
     * Reserve tokens
     */
    function reserveTokens() public onlyOwner {
        uint256 i;
        uint256 tokenId;
        uint256 first_encounter = block.timestamp;

        for (i = 1; i <= 50; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
    }

    /**
     * Mint a specific token.
     */
    function mintTokenId(uint256 tokenId) public onlyOwner {
        require(!_exists(tokenId), "Sorry, but this token was already minted.");
        uint256 first_encounter = block.timestamp;
        _safeMint(msg.sender, tokenId);
        _dPandasDetails[tokenId] = DPandasDetail(first_encounter);
        emit TokenMinted(tokenId, msg.sender, first_encounter);
    }

    /*
     * Set provenance once it's calculated
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }

    /*
     * Set max tokens
     */
    function setMaxTokens(uint256 maxTokens) public onlyOwner {
        MAX_TOKENS = maxTokens;
    }

    /*
     * Pause sale if active, make active if paused
     */
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    /*
     * Pause presale if active, make active if paused
     */
    function setPreSaleState(bool newState) public onlyOwner {
        preSaleIsActive = newState;
    }

    /**
    
     */

     function mintFromWhiteList(uint256 numberOfTokens) public payable onlyWhitelisted {
         require(preSaleIsActive, "Sorry, but the presale minting is not available now.");
         require(
            numberOfTokens <= PRESALE_MAX_PURCHASE,
            "Sorry, but you can only mint 3 tokens during the presale minting."
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Sorry, but we don't have that many Pandas left."
        );
        require(
            CURRENT_PRICE.mul(numberOfTokens) <= msg.value,
            "Sorry, but the value is inaccurate. Please take the number of Pandas times 0.088."
        );
        uint256 first_encounter = block.timestamp;
        uint256 tokenId;

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _dPandasDetails[tokenId] = DPandasDetail(first_encounter);
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }

     }

    /**
     * Mint DPandas
     */
    function mintDPandas(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sorry, but the minting is not available now.");
        require(
            numberOfTokens <= MAX_PURCHASE,
            "Sorry, but you can only mint 5 tokens total."
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Sorry, but we don't have that many Pandas left."
        );
        require(
            CURRENT_PRICE.mul(numberOfTokens) <= msg.value,
            "Sorry, but the value is inaccurate. Please take the number of Pandas times 0.088."
        );
        uint256 first_encounter = block.timestamp;
        uint256 tokenId;

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                _dPandasDetails[tokenId] = DPandasDetail(first_encounter);
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
    }    


    /**
     * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
     */
    function setBaseURI(string memory BaseURI) public onlyOwner {
        baseURI = BaseURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Set the current token price
     */
    function setCurrentPrice(uint256 currentPrice) public onlyOwner {
        CURRENT_PRICE = currentPrice;
    }

    /**
     * Get the token detail
     */
    function getDPandasDetail(uint256 tokenId)
        public
        view
        returns (DPandasDetail memory detail)
    {
        require(_exists(tokenId), "This token was minted.");

        return _dPandasDetails[tokenId];
    }

}