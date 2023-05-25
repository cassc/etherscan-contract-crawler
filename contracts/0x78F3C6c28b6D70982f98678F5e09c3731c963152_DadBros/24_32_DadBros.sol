// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8;

import "../ONFT721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../../../libraries/OmniLinearCurve.sol";
import {toDaysWadUnsafe} from "solmate/src/utils/SignedWadMath.sol";

/// @title Interface of the AdvancedONFT standard
/// @author exakoss
/// @notice this implementation supports: batch mint, payable public and private mint, reveal of metadata and EIP-2981 on-chain royalties
contract DadBros is  ONFT721, ReentrancyGuard {
    using Strings for uint;
    using OmniLinearCurve for OmniLinearCurve.OmniCurve;


    uint public tax = 1000; // 100% = 10000


    uint16 public nextMintId;

    /*//////////////////////////////////////////////////////////////
                            MINT CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint16 public constant MAX_MINT_ID_FREE = 700;
    uint16 public constant MAX_MINT_ID_TOTAL = 3000;
    uint16 public constant MAX_MINT_ID_FRIENDS = 2300;
    uint8 public constant MAX_TOKENS_PER_MINT_FREE = 4;
    uint8 public constant MAX_TOKENS_PER_MINT_FRIENDS = 5;
    uint8 public constant MAX_TOKENS_PER_MINT_PUBLIC = 20;
   

    uint128 public constant MIN_PUBLIC_PRICE = 0.01 ether;
    uint128 public constant MIN_FRIENDS_PRICE = 0.005 ether;

   
    uint128 public constant PRICE_DELTA_PUBLIC = 0.0001e18;
    uint128 public constant PRICE_DECAY_PUBLIC= 0.00009e18;
    uint128 public constant PRICE_DELTA_FRIENDS = 0.00015e18;
    uint128 public constant PRICE_DECAY_FRIENDS= 0.00009e18;


    uint16 public friendsAndPublicSupply;
    uint16 public freeSupply;

   /*//////////////////////////////////////////////////////////////
                            MINT TYPES
    //////////////////////////////////////////////////////////////*/
    uint8 private constant MINT_FREE_ID = 1;
    uint8 private constant MINT_FRIENDS_ID = 2;
    uint8 private constant MINT_PUBLIC_ID = 3;

    /*//////////////////////////////////////////////////////////////
                             MINTING STATE
    //////////////////////////////////////////////////////////////*/
    uint128 public spotPriceFriends = 0.00995 ether;
    uint128 public spotPricePublic = 0.0199 ether;
    uint256 public lastUpdateFriends = 0;
    uint256 public lastUpdatePublic = 0;



    address payable beneficiary;
    address payable taxRecipient;

    bytes32 public merkleRootFree;
    bytes32 public merkleRootFriends;

    string private baseURI;
    string private hiddenMetadataURI;

    bool public _saleStarted;
    bool public revealed;


    mapping (uint8 => mapping (address => uint16)) public minted;

    modifier onlyBeneficiaryAndOwner() {
        require(msg.sender == beneficiary || msg.sender == owner() , "DadBros: caller is not the beneficiary");
        _;
    }

    /// @notice Constructor for the AdvancedONFT
    /// @param _name the name of the token
    /// @param _symbol the token symbol
    /// @param _layerZeroEndpoint handles message transmission across chains
    /// @param _baseTokenURI the base URI for computing the tokenURI
    /// @param _hiddenURI the URI for computing the hiddenMetadataUri
    /// @param _tax the tax percentage (100% = 10000)
    /// @param _taxRecipient the address that receives the tax
    constructor(
        string memory _name,
        string memory _symbol,
        address _layerZeroEndpoint,
        string memory _baseTokenURI,
        string memory _hiddenURI,
        uint _tax,
        address _taxRecipient
    ) 
    ONFT721(_name, _symbol, _layerZeroEndpoint, 200000) 
    {

        beneficiary = payable(msg.sender);
        baseURI = _baseTokenURI;
        hiddenMetadataURI = _hiddenURI;
        tax = _tax;
        taxRecipient = payable(_taxRecipient);

    }

    function setTax(uint _tax) external onlyOwner {
        tax = _tax;
    }

    function setTaxRecipient(address payable _taxRecipient) external onlyOwner {
        taxRecipient = _taxRecipient;
    }
    

    /// @notice Mint functions for all 3 mint tiers         
    /// @param _nbTokens the number of tokens to mint (Free: 1-4 Friends: 1-5 Public: 1-20)
    /// @param mintType the type of mint (1: Free 2: Friends 3: Public)
    /// @param _merkleProof the merkle proof
    /// @param wlAllocationAmt the amount of tokens allocated to the address
    function mint(uint16 _nbTokens, uint8 mintType, bytes32[] calldata _merkleProof, uint256 wlAllocationAmt) external payable {
        require(_saleStarted == true, "DadBros: Sale has not started yet!");
        require(_nbTokens > 0, "DadBros: Cannot mint 0 tokens");
        require(_nbTokens + nextMintId <= MAX_MINT_ID_TOTAL, "DadBros: Max supply reached");
        require(mintType == MINT_FREE_ID || mintType == MINT_FRIENDS_ID || mintType == MINT_PUBLIC_ID, "DadBros: Invalid mint type");
        uint currMinted = minted[mintType][msg.sender];

        uint128 newSpotPrice;
        uint256 totalPrice;

        if (mintType == MINT_FREE_ID) {
            
            require(freeSupply + _nbTokens <= MAX_MINT_ID_FREE, "DadBros: Max supply reached");
            require(currMinted + _nbTokens <= wlAllocationAmt, "DadBros: Max tokens per address reached");
            require(_nbTokens <= MAX_TOKENS_PER_MINT_FREE, "DadBros: Max tokens per mint reached");
            {
                bool isWl = MerkleProof.verify(_merkleProof, merkleRootFree, keccak256(abi.encodePacked(_msgSender(), wlAllocationAmt)));
                require(isWl == true, "DadBros: Invalid Merkle Proof");
            }

        } else if (mintType == MINT_FRIENDS_ID) {
            require(currMinted + _nbTokens <= wlAllocationAmt, "DadBros: Max tokens per address reached");
            require(friendsAndPublicSupply + _nbTokens <= MAX_MINT_ID_FRIENDS, "DadBros: Max supply reached");
            require(_nbTokens <= MAX_TOKENS_PER_MINT_FRIENDS, "DadBros: Max tokens per mint reached");
            {
                bool isWl = MerkleProof.verify(_merkleProof, merkleRootFriends, keccak256(abi.encodePacked(_msgSender(), wlAllocationAmt)));
                require(isWl == true, "DadBros: Invalid Merkle Proof");
            }

            (newSpotPrice, totalPrice) = getPriceInfo(MINT_FRIENDS_ID, _nbTokens);
            require(msg.value >= totalPrice, "DadBros: Not enough ETH");

        } else if (mintType == MINT_PUBLIC_ID) {
            require(_nbTokens <= MAX_TOKENS_PER_MINT_PUBLIC, "DadBros: Max tokens per mint reached");
            require(friendsAndPublicSupply + _nbTokens <= MAX_MINT_ID_FRIENDS, "DadBros: Max supply reached");


            (newSpotPrice, totalPrice) = getPriceInfo(MINT_PUBLIC_ID, _nbTokens);
        
            require(msg.value >= totalPrice, "DadBros: Not enough ETH");
            
        }

        uint16 localNextMintId = nextMintId;
        for (uint16 i; i < _nbTokens; i++) {
            _mint(msg.sender, ++localNextMintId);
        }
        nextMintId = localNextMintId;

        minted[mintType][msg.sender] += _nbTokens;

        if (mintType == MINT_FRIENDS_ID) {
            spotPriceFriends = newSpotPrice;
            lastUpdateFriends = block.timestamp;
            friendsAndPublicSupply += _nbTokens;
        } else if (mintType == MINT_PUBLIC_ID) {
            spotPricePublic = newSpotPrice;
            lastUpdatePublic = block.timestamp;
            friendsAndPublicSupply += _nbTokens;
        } else {
            freeSupply += _nbTokens;
        }
    
    }

    /// @param mintType  (1: Free 2: Friends 3: Public)
    /// @param amount (1-4 for Free, 1-5 for Friends, 1-20 for Public)
    /// @return new next spot price (in wei)
    /// @return total price (in wei)
    function getPriceInfo(uint8 mintType, uint16 amount) public view returns (uint128, uint256) {
        require(mintType == MINT_FRIENDS_ID || mintType == MINT_PUBLIC_ID, "DadBros: Invalid mint type");
        OmniLinearCurve.OmniCurve memory curve;
        if (mintType == MINT_FRIENDS_ID) {
            
            curve = OmniLinearCurve.OmniCurve({
                lastUpdate: lastUpdateFriends == 0 ? block.timestamp : lastUpdateFriends,
                spotPrice: spotPriceFriends,
                priceDelta: PRICE_DELTA_FRIENDS,
                priceDecay: PRICE_DECAY_FRIENDS,
                minPrice: MIN_FRIENDS_PRICE
            });
        } else if (mintType == MINT_PUBLIC_ID) {
            curve = OmniLinearCurve.OmniCurve({
                lastUpdate: lastUpdatePublic == 0 ? block.timestamp : lastUpdatePublic,
                spotPrice: spotPricePublic,
                priceDelta: PRICE_DELTA_PUBLIC,
                priceDecay: PRICE_DECAY_PUBLIC,
                minPrice: MIN_PUBLIC_PRICE
            });
        }

        (uint128 newSpotPrice, uint256 totalPrice) =  OmniLinearCurve.getBuyInfo(curve, uint256(amount));
        if (mintType == MINT_PUBLIC_ID && amount >= 5) {
            if (amount == 20){
                amount = 19;
            }   
            totalPrice = totalPrice - ((totalPrice * (amount / uint16(5) ) ) / 10);
        }
        return (newSpotPrice, totalPrice);

    }

    function setMerkleRoot(bytes32 tier, bytes32 _merkleRoot) external onlyBeneficiaryAndOwner {
        if (tier == "free") {
            merkleRootFree = _merkleRoot;
        } else if (tier == "friends") {
            merkleRootFriends = _merkleRoot;
        }
    }


    function setBaseURI(string memory uri) public onlyBeneficiaryAndOwner {
        baseURI = uri;
    }

    function setBeneficiary(address payable _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) external onlyBeneficiaryAndOwner {
        hiddenMetadataURI = _hiddenMetadataUri;
    }

    function flipRevealed() external onlyBeneficiaryAndOwner {
        revealed = !revealed;
    }

    function flipSaleStarted() external onlyBeneficiaryAndOwner {
        require(merkleRootFree != bytes32(0) && merkleRootFriends != bytes32(0), "DadBros: Merkle root not set");
        _saleStarted = !_saleStarted;
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw() public virtual onlyBeneficiaryAndOwner {
        require(beneficiary != address(0), "DadBros: Beneficiary not set!");
        uint _balance = address(this).balance;
        // tax: 100% = 10000
        uint _taxFee = _balance * tax / 10000;
        require(payable(beneficiary).send(_balance - _taxFee));
        require(payable(taxRecipient).send(_taxFee));   
    }

    function tokenURI(uint tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!revealed) {
            return hiddenMetadataURI;
        }
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }
    
}