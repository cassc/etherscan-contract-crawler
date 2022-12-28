// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/*
      _______   _______   __   ___    _______   
     /"     "| /"      \ |/"| /  ")  |   __ "\  
    (: ______)|:        |(: |/   /   (. |__) :) 
     \/    |  |_____/   )|    __/    |:  ____/  
     // ___)   //      / (// _  \    (|  /      
    (:  (     |:  __   \ |: | \  \  /|__/ \     
     \__/     |__|  \___)(__|  \__)(_______)    

    Freaky Pass All Rights Reserved 2022
    Developed by ATOMICON.PRO ([email protected])
*/

import "./utils/Manageable.sol";
import "./utils/operator_filterer/DefaultOperatorFilterer.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract FreakyPass is ERC1155, ERC1155Supply, Manageable, DefaultOperatorFilterer {

    error ExceedingCollectionSize();
    error ExceedingMintingLimits();
    error SalesAreClosed();

    error HashComparisonFailed();
    error InvalidSignature();
    error SignatureAlreadyUsed();

    error NothingToWithdraw();    
    error WrongEthAmount();

    enum SALE_STAGE {
        CLOSED,
        PRIVATE,
        WHITELIST
    }    

    string constant TOKEN_URI = "ipfs://QmP4axrTkwpSD6PByi1pvAwcSpANpAVnqHM42WgpYYb32S";
    uint16 constant public COLLECTION_SIZE = 200;

    uint8 constant public MAX_TOKENS_PRIVATE_SALE = 3;
    uint8 constant public MAX_TOKENS_WHITELIST_SALE = 2;

    address constant private CREATOR_PAYOUT_WALLET = 0x57BE09189fF5dC6cDE887E706A2a148D6ABf5FF5;
    address constant private DEVELOPER_PAYOUT_WALLET = 0xf2E4186DF36cbdb2c77fad2BC74d169643B32E86;

    uint256 public privateSaleTokenPrice = 0.1 ether;
    uint256 public whitelistSaleTokenPrice = 0.1 ether;

    uint32 public privateSaleStartTime = 1672228800;
    uint32 public whitelistSaleStartTime = 1672252200;

    bytes8 private _hashSalt = 0xe02197c2f84029f0;
    address private _signerAddress = 0x4018433648F2A6dB1014CBc3027AA950728607C2;

    /// @dev Ammount of tokens an address has minted during different sale stages
    mapping (address => uint256) private _numberMintedDuringPrivateSale;
    mapping (address => uint256) private _numberMintedDuringWhitelistSale;

    /// @dev Used nonces for signatures    
    mapping(uint64 => bool) private _usedNonces;

    constructor() ERC1155(TOKEN_URI) {}

    /// @notice Mint tokens during the sales
    function saleMint(bytes32 hash, bytes memory signature, uint64 nonce, uint256 quantity)
        external
        payable
    {
        SALE_STAGE saleStage = getCurrentSaleStage();

        if(totalSupply() + quantity > COLLECTION_SIZE) revert ExceedingCollectionSize();
        if(quantity > numberAbleToMint(msg.sender)) revert ExceedingMintingLimits();
        if(msg.value != getCurrentStagePrice() * quantity) revert WrongEthAmount();

        if(_mintOperationHash(msg.sender, quantity, nonce) != hash) revert HashComparisonFailed();
        if(!_isTrustedSigner(hash, signature)) revert InvalidSignature();
        if(_usedNonces[nonce]) revert SignatureAlreadyUsed();

        _mint(msg.sender, 1, quantity, "");
        _usedNonces[nonce] = true;

        if(saleStage == SALE_STAGE.PRIVATE)
            _numberMintedDuringPrivateSale[msg.sender] += quantity;
        else if(saleStage == SALE_STAGE.WHITELIST)
            _numberMintedDuringWhitelistSale[msg.sender] += quantity;
    }

    /// @notice Airdrop tokens to a list of accounts
    function airdrop(address[] memory owners, uint256 quantity)
        external
        onlyManager
    {
        if(totalSupply() + quantity > COLLECTION_SIZE) revert ExceedingCollectionSize();

        for(uint64 i = 0; i < owners.length; i++) {
            _mint(owners[i], 1, quantity, "");
        }
    }

    /// @notice Withdraw money from the contract. 80% go to the creator and 20% go to the developer
    function withdrawMoney() external onlyManager {
        if(address(this).balance == 0) revert NothingToWithdraw();

        payable(CREATOR_PAYOUT_WALLET).transfer(address(this).balance * 4 / 5);
        payable(DEVELOPER_PAYOUT_WALLET).transfer(address(this).balance);
    }

    /// @notice Number of tokens an address can mint at the given moment
    function numberAbleToMint(address owner) public view returns (uint256) {
        SALE_STAGE saleStage = getCurrentSaleStage();
        
        if(saleStage == SALE_STAGE.WHITELIST)
            return MAX_TOKENS_WHITELIST_SALE - numberMintedDuringWhitelistSale(owner);
        
        if(saleStage == SALE_STAGE.PRIVATE)
            return MAX_TOKENS_PRIVATE_SALE - numberMintedDuringPrivateSale(owner);

        return 0;
    }

    /// @notice Number of tokens minted by an address during the private sales
    function numberMintedDuringPrivateSale(address owner) public view returns(uint256){
        return _numberMintedDuringPrivateSale[owner];
    }

    /// @notice Number of tokens minted by an address
    function numberMintedDuringWhitelistSale(address owner) public view returns (uint256) {
        return _numberMintedDuringWhitelistSale[owner];
    }

    /// @notice Token price at the currnt sale stage
    function getCurrentStagePrice() public view returns(uint256) {
        SALE_STAGE saleStage = getCurrentSaleStage();

        if(saleStage == SALE_STAGE.CLOSED)
            revert SalesAreClosed();

        if(saleStage == SALE_STAGE.PRIVATE) 
            return privateSaleTokenPrice;
        
        return whitelistSaleTokenPrice;
    }

    /// @notice Change private sales token price
    function setPrivateSaleTokenPrice(uint256 priceInWei) public onlyManager {
        privateSaleTokenPrice = priceInWei;
    }

    /// @notice Change whitelist sales token price
    function setWhitelistSaleTokenPrice(uint256 priceInWei) public onlyManager {
        whitelistSaleTokenPrice = priceInWei;
    }

    /// @notice Get current sale stage
    function getCurrentSaleStage() public view returns (SALE_STAGE) {
        if(block.timestamp >= whitelistSaleStartTime)
            return SALE_STAGE.WHITELIST;
        
        if(block.timestamp >= privateSaleStartTime)
            return SALE_STAGE.PRIVATE;
        
        return SALE_STAGE.CLOSED;
    }

    /// @notice Change private sales start time in unix time format
    function setPrivateSaleStartTime(uint32 unixTime) public onlyManager {
        privateSaleStartTime = unixTime;
    }

    /// @notice Change whitelist sales start time in unix time format
    function setWhitelistSaleStartTime(uint32 unixTime) public onlyManager {
        whitelistSaleStartTime = unixTime;
    }

    /// @notice URI with contract metadata for opensea
    function contractURI() public pure returns (string memory) {
        return "ipfs://QmQXZBQm6MujcLDdiKXNQWaWFC8zkPc17mjpqaXFRQibJo";
    }

    /// @dev Generate hash of current mint operation
    function _mintOperationHash(address buyer, uint256 quantity, uint64 nonce) internal view returns (bytes32) {
        SALE_STAGE saleStage = getCurrentSaleStage();

        if(saleStage == SALE_STAGE.CLOSED)
            revert SalesAreClosed();

        return keccak256(abi.encodePacked(
            _hashSalt,
            buyer,
            uint64(block.chainid),
            uint64(saleStage),
            uint64(quantity),
            uint64(nonce)
        ));
    }

    /// @dev Test whether a message was signed by a trusted address
    function _isTrustedSigner(bytes32 hash, bytes memory signature) internal view returns(bool) {
        return _signerAddress == ECDSA.recover(hash, signature);
    }

    /// @dev Overrides for marketplace restrictions
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /// @dev Overrides for ERC1155Supply support
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /// @notice Total amount of tokens minted
    function totalSupply() public view returns (uint256) {
        return totalSupply(1);
    }

    /// @notice Amount of tokens of the specified account
    function balanceOf(address account) public view returns (uint256) {
        return balanceOf(account, 1);
    }
}