// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721A.sol";

interface IFLOWTYSTAKING {
    function depositsOf(address account)
        external
        view
        returns (uint256[] memory);
}
/*
Morphys V2
*/
contract MorphysV2 is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    IERC20 public INKToken = IERC20(0xB8BC04A8be09C4734e3B1a6169dcC0a4CD6d5efA);
    uint256 public constant MAX_MORPHYS = 10000;
    uint256 public quantityMultiplier = 1;
    uint256 public quantityMultiplierStaked = 3;
    uint256 public maxPerMint = 50;
    bool public mintingIsActive = false;
    bool public morphingIsActive = false;
    // Minting (only once): Flowty => Morphy current collection
    string public currentSeasonalCollectionURI;

    // Maximum price per minting one Morphy for a Flowty owner;
    uint256 public mintingPrice = 500 ether; // $INK price = 500 $INK
    uint256 public morphingPrice = 300 ether; // $INK price = 300 $INK
    uint256 public MINT_STAGE = 1;

    mapping(uint256 => mapping(address => uint256)) private _mintingClaimedMap;
    // Mapping between tokenId => seasonal collectiong baseURI
    mapping(uint256 => string) private _morphysRegistry;

    address public flowtysContract = 0x52607cb9c342821ea41ad265B9Bb6a23BEa49468;
    address public stakingContract = 0x1C9EFa5e7b6DDCc50634267037dc8514FD1B0152;
    address public stakingContractMorphyV2;

    constructor() ERC721A("MorphysV2", "MORPH2", 50, MAX_MORPHYS) {}

    /*
    * Withdraw funds
    */
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");

        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    /*
    * The ground cost of Morphying, unless free because a Flowty has required age stage
    */
    function setMorphingCost(uint256 newCost) public onlyOwner {
        morphingPrice = newCost;
    }

     function setQuantityMultiplier(uint256 newQuantity, uint256 newQuantityStaked) public onlyOwner {
        quantityMultiplier = newQuantity;
        quantityMultiplierStaked = newQuantityStaked;
    }

    /*
    * Minting tiers, starts with Free for holders
    */
    function setMintingMaxCost(uint256 newCost) public onlyOwner {
        mintingPrice = newCost;
    }

    function setMintMax(uint256 newMax) public onlyOwner {
        maxPerMint = newMax;
    }

    function setStakingContract(address stakingContractV2) public onlyOwner {
        stakingContractMorphyV2 = stakingContractV2;
    }
    //---------------------------------------------------------------------------------
    /**
    * Current on-going collection that is avaiable to morph or use as base for minting
    */
    function setCurrentCollectionBaseURI(string memory newuri) public onlyOwner {
        currentSeasonalCollectionURI = newuri;
    }

    /*
    * Pause morphing if active, make active if paused
    */
    function flipMorphingState() public onlyOwner {
        morphingIsActive = !morphingIsActive;
    }

    /*
    * Pause minting if active, make active if paused
    */
    function flipMintingState() public onlyOwner {
        mintingIsActive = !mintingIsActive;
    }

    /**
     * Reserve Morphyd from the current Flowtys reserve
    */
    function reserveMorphys(uint256 quantity, address account) public onlyOwner {        
        for(uint i = totalSupply(); i < (totalSupply() + quantity); ) {
            _morphysRegistry[i] = currentSeasonalCollectionURI;
            unchecked { ++i; }
        }
        _safeMint(account, quantity);
    }

    /**
    * Mints Morphy (only allowed if you holding Flowty and corresponding Morphy has not been minted)
    */
    function mintMorphy(uint256 quantity) external nonReentrant {
        require(mintingIsActive, "Minting must be active to mint Morphy");

        uint256[] memory staked = IFLOWTYSTAKING(stakingContract).depositsOf(msg.sender);
        uint256 ownned = IERC721(flowtysContract).balanceOf(msg.sender);
        uint256 maxCount = staked.length * quantityMultiplierStaked + ownned * quantityMultiplier;

        require(quantity <= maxPerMint, "Minting too much at once is not supported");
        require(quantity <= maxCount, "Minting over max cap");
        require(_mintingClaimedMap[MINT_STAGE][msg.sender].add(quantity) <= maxCount, "Mint would exceed max tokens allowed");
        require((totalSupply() + quantity) <= MAX_MORPHYS, "Mint would exceed max supply of Morhpys");

        uint256 price = mintingPrice * quantity;
        uint256 buyerINKBalance = INKToken.balanceOf(msg.sender);
        require(price < buyerINKBalance, "Insufficient funds: Not enough $INK for sale price");      
        INKToken.transferFrom(msg.sender, address(this), price); 

        for(uint i = totalSupply(); i < (totalSupply() + quantity); ) {
            _morphysRegistry[i] = currentSeasonalCollectionURI;
            unchecked { ++i; }
        }
        _safeMint(msg.sender, quantity);
        _mintingClaimedMap[MINT_STAGE][msg.sender] += quantity;
    }

    /**
    * Morphing existing Morphys.
    * Changing current baseURI of a token to a new one, that is current Season topic.
    */
    function morphSeason(uint256[] memory tokenIds) external nonReentrant {
        require(morphingIsActive, "Morphing must be active to change season");
        uint256[] memory staked = IFLOWTYSTAKING(stakingContractMorphyV2).depositsOf(msg.sender);
        for(uint i = 0; i < tokenIds.length; i++) {
            require(_exists(tokenIds[i]), "Attempt to morph Morphy for non existing tokenId");
            // Allow morphing for owner only
            if (ownerOf(tokenIds[i]) != msg.sender) {
                if (!hasTokenId(staked, tokenIds[i])) {
                  require(false, "Trying to morph non existing/not owned Morphy");
                }
            }
        }
        uint256 price = morphingPrice * tokenIds.length;
        uint256 buyerINKBalance = INKToken.balanceOf(msg.sender);
        require(price < buyerINKBalance, "Insufficient funds: Not enough $INK for sale price");      
        INKToken.transferFrom(msg.sender, address(this), price); 

        for(uint i = 0; i < tokenIds.length;) {
            _morphysRegistry[tokenIds[i]] = currentSeasonalCollectionURI;
            unchecked { ++i; }
        }
    }

    /// Internal
    function hasTokenId(uint256[] memory tokenIds, uint256 tokenId) private pure returns (bool) {
        for(uint i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
              return true;
            }
        }
        return false;
    }

    /// ERC721 related
    /**
     * @dev See {ERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _morphysRegistry[tokenId];
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return currentSeasonalCollectionURI;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
      external
      view
      returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

}