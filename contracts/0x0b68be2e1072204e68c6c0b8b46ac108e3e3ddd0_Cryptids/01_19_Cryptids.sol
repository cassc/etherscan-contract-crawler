/*
   _____         _    _ _______ _____ ____  _   _               
  / ____|   /\  | |  | |__   __|_   _/ __ \| \ | |_             
 | |       /  \ | |  | |  | |    | || |  | |  \| (_)            
 | |      / /\ \| |  | |  | |    | || |  | | . ` |              
 | |____ / ____ \ |__| |  | |   _| || |__| | |\  |_             
  \_____/_/    \_\____/  _|_|  |_____\____/|_|_\_(_)____ _    _ 
  / ____|  /\    / ____|/ __ \| |  | |  /\|__   __/ ____| |  | |
 | (___   /  \  | (___ | |  | | |  | | /  \  | | | |    | |__| |
  \___ \ / /\ \  \___ \| |  | | |  | |/ /\ \ | | | |    |  __  |
  ____) / ____ \ ____) | |__| | |__| / ____ \| | | |____| |  | |
 |_____/_/ ___\_\_____/ \___\_\\____/_/    \_\_|  \_____|_|  |_|
 \ \ / /  |_   _| \ | |/ ____|                                  
  \ V /_____| | |  \| | |  __                                   
   > <______| | | . ` | | |_ |                                  
  / . \    _| |_| |\  | |__| |                                  
 /_/ \_\  |_____|_| \_|\_____|                                  
                                                

An 0nyX Labs Contract - Development by @White_Oak_Kong
0nyXLabs.io

*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IBountyYield {
    function updateReward(address _from, address _to) external;

}

contract Cryptids is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    IBountyYield public BountyYield;
    function setBountyYield(address _bountyYield) external onlyOwner { BountyYield = IBountyYield(_bountyYield); }

    string private baseURI;
    string public verificationHash;

    uint256 public constant MAX_PER_TXN = 10;
    uint256 public constant MAX_PER_WALLET_PRESALE = 4;
    uint256 public maxCryptids;
    uint256 public royaltyPercentage = 5;

    uint256 public SALE_PRICE = 0.08 ether;
    uint256 public constant PRE_SALE_PRICE = 0.06 ether;
    bool public isPublicSaleActive;

    uint256 public maxPreSaleCryptids;
    bytes32 public preSaleMerkleRoot;
    bool public isPreSaleActive;

    bytes32 public claimListMerkleRoot;

    mapping(address => uint256) public mintCounts;
    mapping(address => bool) public claimed;

    address FOUNDER_1 = 0x894F4B4Fc8cF989568383bD9dfE963348f069e71;
    address FOUNDER_2 = 0x86953020A8A0470479FA052AC3f27D1fF688914B;
    address FOUNDER_3 = 0xd629A3A25ff374CF208305243Ff7d38140755a95;
    address DEV = 0x3B36Cb2c6826349eEC1F717417f47C06cB70b7Ea;
    address CM = 0x3cbB9E4caBE9f00Ba636FF179FaB4B238AA219bD;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier preSaleActive() {
        require(isPreSaleActive, "Presale is not open");
        _;
    }

    modifier canMintCryptids(uint256 numberOfTokens) {
        require(
            tokenCounter.current() + numberOfTokens <= maxCryptids,
            "Not enough Cryptids remaining to mint"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

        modifier maxTxn(uint256 numberOfTokens) {
        require(
            numberOfTokens <= MAX_PER_TXN,
            "Max Cryptids to mint is 10"
        );
        _;
    }


    constructor(
        uint256 _maxCryptids,
        uint256 _maxPreSaleCryptids
    ) ERC721("CRYPTIDS", "CRYPTIDS") {
        maxCryptids = _maxCryptids;
        maxPreSaleCryptids = _maxPreSaleCryptids;
    }

    // ---  PUBLIC MINTING FUNCTIONS ---

    // mint allows for regular minting while the supply does not exceed maxCryptids.
    function mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        isCorrectPayment(SALE_PRICE, numberOfTokens)
        publicSaleActive
        canMintCryptids(numberOfTokens)
        maxTxn(numberOfTokens)
    {

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    // mintPreSale allows for minting by allowed addresses during the pre-sale.
    function mintPreSale(
        uint8 numberOfTokens,
        bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        preSaleActive
        canMintCryptids(numberOfTokens)
        isCorrectPayment(PRE_SALE_PRICE, numberOfTokens)
        isValidMerkleProof(merkleProof, preSaleMerkleRoot)
    {
        uint256 numAlreadyMinted = mintCounts[msg.sender];

        require(
            numAlreadyMinted + numberOfTokens <= MAX_PER_WALLET_PRESALE,
            "Max Cryptids to mint in Presale is one"
        );

        require(
            tokenCounter.current() + numberOfTokens <= maxPreSaleCryptids,
            "Not enough Cryptids remaining to mint"
        );

        mintCounts[msg.sender] = numAlreadyMinted + numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    // claim allows for a free mint by allowed addresses.
    function claim(bytes32[] calldata merkleProof)
        external
        isValidMerkleProof(merkleProof, claimListMerkleRoot)
    {
        require(!claimed[msg.sender], "You have already claimed your free Cryptid.");

        claimed[msg.sender] = true;

        _safeMint(msg.sender, nextTokenId());
    }

    // -- OWNER ONLY MINT --
    function ownerMint(uint256 numberOfTokens)
        external
        nonReentrant
        onlyOwner
        canMintCryptids(numberOfTokens)
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    // --- READ-ONLY FUNCTIONS ---

    // getBaseURI returns the baseURI hash for collection metadata.
    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    // getLastTokenId returns the last tokenId minted.
    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    // -- ADMIN FUNCTIONS --

    // setBaseURI sets the base URI for token metadata.
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // capSupply is an emergency function to reduce the maximum supply of Cryptids.
    function capSupply(uint256 _supply) external onlyOwner {
        require(_supply > tokenCounter.current(), "cannot reduce maximum supply below current count.");
        require(_supply > maxCryptids, "cannot increase the maximum supply.");
        maxCryptids = _supply;
    }

    // updatePrice is an emergency function to adjust the price of Cryptids.
    function updatePrice(uint256 _price) external onlyOwner {
        SALE_PRICE = _price;
    } 

    function setVerificationHash(string memory _verificationHash)
        external
        onlyOwner
    {
        verificationHash = _verificationHash;
    }

    // setIsPublicSaleActive toggles the functionality of the public minting function.
    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setRoyaltyAmount(uint256 _royaltyPercentage) external onlyOwner {
        royaltyPercentage = _royaltyPercentage;
    }

    // setIsPreSaleActive toggles the functionality of the presale minting function.
    function setIsPreSaleActive(bool _isPreSaleActive)
        external
        onlyOwner
    {
        isPreSaleActive = _isPreSaleActive;
    }

    // setPresaleListMerkleRoot sets the merkle root for presale allowed addresses.
    function setPresaleListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        preSaleMerkleRoot = merkleRoot;
    }

    // setClaimListMerkleRoot sets the merkle root for free claim addresses.
    function setClaimListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        claimListMerkleRoot = merkleRoot;
    }

    // withdraw allows for the withdraw of all ETH to the assigned wallets.
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(FOUNDER_1, (balance * 300) / 1000);
        _withdraw(FOUNDER_2, (balance * 275) / 1000);
        _withdraw(FOUNDER_3, (balance * 275) / 1000);
        _withdraw(DEV, (balance * 100) / 1000);
        _withdraw(CM, (balance * 50) / 1000);
        
        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    // nextTokenId collects the next tokenId to mint.
    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // Custom Transfer Hook override ERC721 and update yield reward.
    function transferFrom(address from, address to, uint256 tokenId) public override {
        BountyYield.updateReward(from, to);
        ERC721.transferFrom(from, to, tokenId);
    }
    // Custom Transfer Hook override ERC721 and update yield reward.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        BountyYield.updateReward(from, to);
        ERC721.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString()));
    }
    
    /**
     * Override royalty % for future application.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), SafeMath.div(SafeMath.mul(salePrice, royaltyPercentage), 100));
    }
}