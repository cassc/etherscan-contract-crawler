// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8;

import "../ONFT721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../../libraries/OmniLinearCurve.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {toDaysWadUnsafe} from "solmate/src/utils/SignedWadMath.sol";

/// @title Interface of the AdvancedONFT standard
/// @author exakoss
/// @notice this implementation supports: batch mint, payable public and private mint, reveal of metadata and EIP-2981 on-chain royalties
contract DadBrosV2 is  ERC721, ReentrancyGuard, Ownable, DefaultOperatorFilterer {
    using Strings for uint;
    using OmniLinearCurve for OmniLinearCurve.OmniCurve;


    uint public tax = 1000; // 100% = 10000


    uint16 public nextMintId = 1302;

    /*//////////////////////////////////////////////////////////////
                            MINT CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint16 public constant MAX_MINT_ID_TOTAL = 3000;
    uint16 public maxClaimId = 1302;
    uint8 public  MAX_TOKENS_PER_MINT_FRIENDS = 5;
    uint8 public MAX_TOKENS_PER_MINT_PUBLIC = 20;
   

    uint128 public MIN_PUBLIC_PRICE = 0.018 ether;
    uint128 public MAX_PRICE_PUBLIC  = 0.03 ether;

    uint128 public FLAT_PRICE_FRIENDS = 0.01 ether;

   
    uint128 public PRICE_DELTA_PUBLIC = 0.00008e18;
    uint128 public PRICE_DECAY_PUBLIC= 0.002e18;



    uint16 public friendsAndPublicSupply;
    uint16 public claimSupply;

   /*//////////////////////////////////////////////////////////////
                            MINT TYPES
    //////////////////////////////////////////////////////////////*/
    uint8 private constant MINT_FRIENDS_ID = 2;
    uint8 private constant MINT_PUBLIC_ID = 3;

    /*//////////////////////////////////////////////////////////////
                             MINTING STATE
    //////////////////////////////////////////////////////////////*/
    uint128 public spotPricePublic = 0.01992 ether;
    uint256 public lastUpdatePublic = 0;



    address payable beneficiary;
    address payable taxRecipient;


    bytes32 public merkleRootFriends;
    bytes32 public merkleRootClaim;

    string private baseURI;


    bool public _saleStarted;
    bool public revealed;


    mapping (uint8 => mapping (address => uint16)) public minted;
    mapping (address => bool) public claimed;


    modifier onlyBeneficiaryAndOwner() {
        require(msg.sender == beneficiary || msg.sender == owner() , "DadBros: caller is not the beneficiary");
        _;
    }

    /// @notice Constructor for the AdvancedONFT
    /// @param _name the name of the token
    /// @param _symbol the token symbol
    /// @param _baseTokenURI the base URI for computing the tokenURI
    /// @param _tax the tax percentage (100% = 10000)
    /// @param _taxRecipient the address that receives the tax
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        uint _tax,
        address _taxRecipient
    ) 
    ERC721(_name, _symbol)
    {

        beneficiary = payable(msg.sender);
        baseURI = _baseTokenURI;
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
    /// @param _nbTokens the number of tokens to mint (Friends: 1-5 Public: 1-20)
    /// @param mintType the type of mint (2: Friends 3: Public)
    /// @param _merkleProof the merkle proof
    /// @param wlAllocationAmt the amount of tokens allocated to the address
    function mint(uint16 _nbTokens, uint8 mintType, bytes32[] calldata _merkleProof, uint256 wlAllocationAmt) external payable {
        require(_saleStarted == true, "DadBros: Sale has not started yet!");
        require(_nbTokens > 0, "DadBros: Cannot mint 0 tokens");
        require(_nbTokens + nextMintId <= MAX_MINT_ID_TOTAL, "DadBros: Max supply reached");
        require(mintType == MINT_FRIENDS_ID || mintType == MINT_PUBLIC_ID, "DadBros: Invalid mint type");
        uint currMinted = minted[mintType][msg.sender];

        uint128 newSpotPrice;
        uint256 totalPrice;

    

        if (mintType == MINT_FRIENDS_ID) {
            require(currMinted + _nbTokens <= wlAllocationAmt, "DadBros: Max tokens per address reached");
            require(_nbTokens <= MAX_TOKENS_PER_MINT_FRIENDS, "DadBros: Max tokens per mint reached");
            {
                bool isWl = MerkleProof.verify(_merkleProof, merkleRootFriends, keccak256(abi.encodePacked(_msgSender(), wlAllocationAmt)));
                require(isWl == true, "DadBros: Invalid Merkle Proof");
            }

            require(msg.value >= FLAT_PRICE_FRIENDS * uint128(_nbTokens), "DadBros: Not enough ETH");

        } else if (mintType == MINT_PUBLIC_ID) {
            require(_nbTokens <= MAX_TOKENS_PER_MINT_PUBLIC, "DadBros: Max tokens per mint reached");


            (newSpotPrice, totalPrice) = getPriceInfo(MINT_PUBLIC_ID, _nbTokens);
        
            require(msg.value >= totalPrice, "DadBros: Not enough ETH");
            
        }

        uint16 localNextMintId = nextMintId;
        for (uint16 i; i < _nbTokens; i++) {
            _mint(msg.sender, ++localNextMintId);
        }
        nextMintId = localNextMintId;

        minted[mintType][msg.sender] += _nbTokens;

    
        if (mintType == MINT_PUBLIC_ID) {
            spotPricePublic = newSpotPrice;
            lastUpdatePublic = block.timestamp;
        }
        friendsAndPublicSupply += _nbTokens;
    }

    function claim(uint256[] memory tokenIds, address to, bytes32[] calldata _merkleProof) external {
        require(_saleStarted == true, "DadBros: claim has not started yet!");
        require(claimed[to] == false, "DadBros: Already claimed");
        require(tokenIds.length > 0, "DadBros: Cannot claim 0 tokens");
        require(tokenIds.length + claimSupply <= maxClaimId, "DadBros: Max claim supply reached");


        {
            bool isWl = MerkleProof.verify(_merkleProof, merkleRootClaim, keccak256(abi.encodePacked(to, tokenIds)));
            require(isWl == true, "DadBros: Invalid Merkle Proof");
        }

        for (uint16 i; i < tokenIds.length; i++) {
            _mint(to, tokenIds[i]);
        }
        
        claimed[to] = true;
        claimSupply += uint16(tokenIds.length);

    }

    /// @param mintType  (2: Friends 3: Public)
    /// @param amount (1-5 for Friends, 1-20 for Public)
    /// @return new next spot price (in wei)
    /// @return total price (in wei)
    function getPriceInfo(uint8 mintType, uint16 amount) public view returns (uint128, uint256) {
        require( mintType == MINT_FRIENDS_ID || mintType == MINT_PUBLIC_ID, "DadBros: Invalid mint type");
        OmniLinearCurve.OmniCurve memory curve;
        
        if (mintType == MINT_FRIENDS_ID) {
            return (FLAT_PRICE_FRIENDS, FLAT_PRICE_FRIENDS * uint128(amount));
        } else if (mintType == MINT_PUBLIC_ID) {
            curve = OmniLinearCurve.OmniCurve({
                lastUpdate: lastUpdatePublic == 0 ? block.timestamp : lastUpdatePublic,
                spotPrice: spotPricePublic,
                priceDelta: PRICE_DELTA_PUBLIC,
                priceDecay: PRICE_DECAY_PUBLIC,
                minPrice: MIN_PUBLIC_PRICE,
                maxPrice: MAX_PRICE_PUBLIC
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

        if (tier == "friends") {
            merkleRootFriends = _merkleRoot;
        } else if (tier == "claim") {
            merkleRootClaim = _merkleRoot;
        }
    }


    function setBaseURI(string memory uri) public onlyBeneficiaryAndOwner {
        baseURI = uri;
    }

    function setBeneficiary(address payable _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }



    function flipRevealed() external onlyBeneficiaryAndOwner {
        revealed = !revealed;
    }

    function flipSaleStarted() external onlyBeneficiaryAndOwner {
        require(merkleRootClaim != bytes32(0) && merkleRootFriends != bytes32(0), "DadBros: Merkle root not set");
        _saleStarted = !_saleStarted;
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setMaxClaimId(uint16 _maxClaimId) external onlyBeneficiaryAndOwner {
        maxClaimId = _maxClaimId;
    }

    function setMaxTokensPerMint(bytes32 _param, uint8 _value) external onlyBeneficiaryAndOwner {
        if (_param == "MAX_TOKENS_PER_MINT_FRIENDS") {
            MAX_TOKENS_PER_MINT_FRIENDS = _value;
        } else if (_param == "MAX_TOKENS_PER_MINT_PUBLIC") {
            MAX_TOKENS_PER_MINT_PUBLIC = _value;
        } else {
            revert("DadBros: Invalid param");
        }
    }

    function setPriceParams(bytes32 _param, uint128 _value) external onlyBeneficiaryAndOwner {

        if (_param == "PRICE_DELTA_PUBLIC") {
            PRICE_DELTA_PUBLIC = _value;
        } else if (_param == "PRICE_DECAY_PUBLIC") {
            PRICE_DECAY_PUBLIC = _value;
        } else if (_param == "MIN_PUBLIC_PRICE") {
            MIN_PUBLIC_PRICE = _value;
        } else if (_param == "spotPricePublic"){
            spotPricePublic = _value;
        } else if (_param == "MAX_PRICE_PUBLIC"){
            MAX_PRICE_PUBLIC = _value;
        } else if (_param == "FLAT_PRICE_FRIENDS"){
            FLAT_PRICE_FRIENDS = _value;
        } else {
            revert("DadBros: Invalid param");
        }
    }
    
    function setNextMintId(uint16 _nextMintId) external onlyBeneficiaryAndOwner {
        nextMintId = _nextMintId;
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
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

     function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
}