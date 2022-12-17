// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/*
      __       _____      _____    _____    _____    _______   ______  
     /\_\     ) ___ (   /\  __/\ /\  __/\  ) ___ ( /\_______)\/ ____/\ 
    ( ( (    / /\_/\ \  ) )(_ ) )) )(_ ) )/ /\_/\ \\(___  __\/) ) __\/ 
     \ \_\  / /_/ (_\ \/ / __/ // / __/ // /_/ (_\ \ / / /     \ \ \   
     / / /__\ \ )_/ / /\ \  _\ \\ \  _\ \\ \ )_/ / /( ( (      _\ \ \  
    ( (_____(\ \/_\/ /  ) )(__) )) )(__) )\ \/_\/ /  \ \ \    )____) ) 
     \/_____/ )_____(   \/____\/ \/____\/  )_____(   /_/_/    \____\/  
                                                          
    The Lobstarbots All Rights Reserved 2022
    Developed by ATOMICON.PRO ([email protected])
*/

import "./ERC721A/ERC721A.sol";

import "./utils/Manageable.sol";
import "./utils/operator_filterer/DefaultOperatorFilterer.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Lobstarbots is ERC721A, Manageable, DefaultOperatorFilterer, ReentrancyGuard {

    error ZeroAddressProhibited();
    error CallerCanNotPerformAirdrop();
    error CallerIsNotCrossmintNorWalletOwner();

    error WrongEtherAmmount();
    error ExceedingMaxSupply();
    error ExceedingTokensPerStageLimit();

    error NotInAllowlist();

    error InvalidBookingSlotIndex();
    error NotATokenHolder();
    error SlotAlreadyTaken();

    error HashComparisonFailed();
    error UntrustedSigner();
    error HashAlreadyUsed();
    error SignatureNoLongerValid();

    error SaleIdNotFound();
    error SalesClosed();
    error SalesNotConfigured();
    error ExceedingSaleStageCount();
    error InvalidSalesConfiguration();
    
    error NothingToWithdraw();
   
    struct SaleStage {
        uint32 id; 
        uint32 startTime;

        bool isAirdrop;
        bool isWhitelistSale;

        uint256 weiTokenPrice;
        uint16 maxSupplyByTheEndOfStage;
        uint16 maxTokensPerUser;
    }

    event SlotBooked(uint256 tokenId, uint64 indexed bookedSlotId, uint64 freedSlotId);

    SaleStage[] private _saleStages;
    mapping(uint32 => mapping(address => bool)) private _stageAllowlist;
    mapping(uint32 => mapping(address => uint256)) private _numberMintedDuringStage;

    address private _crossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233 ;

    mapping(uint64 => uint256) private _bookingSlots;
    uint64 private _bookingSlotsCount;

    bytes8 private _hashSalt = 0x9a6f9334e0a49511;
    address private _signerAddress = 0x542eA56F66bbCe7A7704b96fB130f08C03306061;
    mapping(uint64 => bool) private _usedNonces;

    constructor() ERC721A("The Lobstarbots", "LOBBOTS") {}

    function setCrossmintAddress(address crossmintAddress) public onlyOwner {
        _crossmintAddress = crossmintAddress;
    }

    /// @notice Mint tokens during the sales both through crossmint.io and directly by the buyer
    function mint(address to, uint256 quantity)
        external
        payable
        nonReentrant
    {
        SaleStage memory currentStage = getCurrentSaleStage();

        if (currentStage.isAirdrop)
            if(!isManager(msg.sender))
                revert CallerCanNotPerformAirdrop();
        else {
            if (msg.sender != _crossmintAddress && msg.sender != to) 
                revert CallerIsNotCrossmintNorWalletOwner();
        }
        
        if (to == address(0x0)) revert ZeroAddressProhibited();

        if (msg.value != currentStage.weiTokenPrice * quantity) revert WrongEtherAmmount();
        if (totalSupply() + quantity > currentStage.maxSupplyByTheEndOfStage) revert ExceedingMaxSupply();
        if (quantity > numberAbleToMint(to)) revert ExceedingTokensPerStageLimit();

        if (currentStage.isWhitelistSale && !isInAllowlistForStage(currentStage.id, to)) revert NotInAllowlist();

        _numberMintedDuringStage[currentStage.id][to] += quantity;
        _safeMint(to, quantity);
    }

    // @notice Book a timeslot using a token you own
    function bookSlot(bytes32 hash, bytes calldata signature, uint64 signatureValidityTimestamp, uint64 nonce, uint256 tokenId, uint64 slotId) public {
        if (slotId > _bookingSlotsCount || slotId < 1) revert InvalidBookingSlotIndex();
        if (ownerOf(tokenId) != msg.sender) revert NotATokenHolder();
        if (_bookingSlots[slotId] != 0) revert SlotAlreadyTaken();

        if (signatureValidityTimestamp < block.timestamp) revert SignatureNoLongerValid();
        if (_bookOperationHash(msg.sender, slotId, signatureValidityTimestamp, nonce) != hash) revert HashComparisonFailed();
        if (!_isTrustedSigner(hash, signature)) revert UntrustedSigner();
        if (_usedNonces[nonce]) revert HashAlreadyUsed();

        uint64 oldBookingSlotId = tokenBookingSlotId(tokenId);
        
        _bookingSlots[oldBookingSlotId] = 0;
        _bookingSlots[slotId] = tokenId;

        _usedNonces[nonce] = true;

        emit SlotBooked(tokenId, slotId, oldBookingSlotId);
    }

    // @notice Get a booked timeslot of a token. Notice, that booking slot ids begin with 1
    function tokenBookingSlotId(uint256 tokenId) public view returns(uint64) {
        for(uint64 id = 1; id <= _bookingSlotsCount; id++) {
            if (_bookingSlots[id] == tokenId) return id;
        }

        return 0;
    }

    /// @notice Get booking slots of all tokens
    function getBookingSlots() public view returns(uint256[] memory) {
        uint256[] memory bookingSlotsTokenIds = new uint256[](_bookingSlotsCount);

        for(uint64 id = 1; id <= _bookingSlotsCount; id++) {
            bookingSlotsTokenIds[id-1] = _bookingSlots[id];
        }

        return bookingSlotsTokenIds;
    }

    /// @notice Check, whether owner is in an allowlist for a specific sale stage
    function isInAllowlistForStage(uint32 stageId, address owner) public view returns (bool) {
        return _stageAllowlist[stageId][owner];
    }

    /// @notice Number of tokens an address can mint at the given moment
    function numberAbleToMint(address owner) public view returns (uint256) {
        SaleStage memory currentStage = getCurrentSaleStage();
        return currentStage.maxTokensPerUser - numberMintedDuringStage(currentStage.id, owner);
    }

    /// @notice Number of tokens minted by an address during a specific sale stage
    function numberMintedDuringStage(uint32 stageId, address owner) public view returns (uint256) {
        return _numberMintedDuringStage[stageId][owner];
    }

    /// @notice Number of tokens minted by an address during all sale stages
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /// @notice Get current collection size, based on the last token sale stage
    function getCollectionSize() public view returns (uint256) {
        return getSaleStageByIndex(getSaleStagesCount() - 1).maxSupplyByTheEndOfStage;
    }

    /// @notice Get current sale stage
    function getCurrentSaleStage() public view returns (SaleStage memory) {
        return getSaleStageByIndex(getCurrentSaleStageIndex());
    }

    /// @notice Get ammount of currently added sale stages
    function getSaleStagesCount() public view returns (uint8) {
        return uint8(_saleStages.length);
    }

    /// @notice Get sale stage by index
    function getSaleStageById(uint32 stageId) public view returns (SaleStage memory) {
        for(uint8 index = 0; index < _saleStages.length; index++) {
            if (_saleStages[index].id == stageId)
                return _saleStages[index];
        }

        revert SaleIdNotFound();
    }

    /// @notice Get sale stage by index
    function getSaleStageByIndex(uint8 stageIndex) public view returns (SaleStage memory) {
        if (stageIndex >= getSaleStagesCount()) revert ExceedingSaleStageCount();
        return _saleStages[stageIndex];
    }

    /// @notice Get current sale stage index
    function getCurrentSaleStageIndex() public view returns (uint8) {
        if (_saleStages.length == 0) revert SalesNotConfigured();
        if (block.timestamp < _saleStages[0].startTime) revert SalesClosed();

        uint8 latestSaleStageIndex = 0;
        for(uint8 index = 0; index < _saleStages.length; index++) {
            if (block.timestamp > _saleStages[index].startTime)
                latestSaleStageIndex = index;
        }

        return latestSaleStageIndex;
    }

    /// @notice Add a sale stage configuration
    function addSaleStage(SaleStage memory newSaleStage) external onlyManager {
        if (_saleStages.length > 0) {
            SaleStage memory previousSaleStage = getSaleStageByIndex(uint8(_saleStages.length - 1));
        
            if (previousSaleStage.startTime >= newSaleStage.startTime || 
                previousSaleStage.maxSupplyByTheEndOfStage > newSaleStage.maxSupplyByTheEndOfStage
            ) revert InvalidSalesConfiguration();
        }

        if (newSaleStage.isAirdrop && newSaleStage.weiTokenPrice != 0)
            revert InvalidSalesConfiguration();

        _saleStages.push(newSaleStage);
    }

    /// @notice Remove all sale stage configs
    function clearSaleStages() external onlyManager {
        delete _saleStages;
    }

    // @notice Set an allowlist for a specific sale stage
    function setSaleStageAllowlist(uint32 stageId, address[] memory allowlist, bool isAllowed) external onlyManager {
        for(uint256 index = 0; index < allowlist.length; index++) {
            _stageAllowlist[stageId][allowlist[index]] = isAllowed;
        }
    }

    // @notice Set the count of slots available for booking
    function setBookingSlotsCount(uint64 bookingSlotsCount) external onlyManager {
        _bookingSlotsCount = bookingSlotsCount;
    }

    /// @notice Withdraw money from the contract
    function withdrawMoney(address payable to) external onlyManager nonReentrant {
        if (address(this).balance == 0) revert NothingToWithdraw();
        to.transfer(address(this).balance);
    }

    /// @notice Get URI with contract metadata for OpenSea
    function contractURI() public pure returns (string memory) {
        return "ipfs://QmaRuP7Epy2zzuFGoDzMdF6tPDoRSxcxD5rPfp6HtK73D4";
    }

    /// @dev Starting index for the token IDs
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @dev Token metadata folder/root URI
    string private _baseTokenURI = "ipfs://QmcCAZmDysBhWQt2aZJErQJRbFSrsquscbDQjQaV3NyssY/";

    /// @notice Get base token URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Set base token URI
    function setBaseURI(string calldata baseURI) external onlyManager {
        _baseTokenURI = baseURI;
    }

    /// @dev Overrides for marketplace restrictions
    function transferFrom(address from, address to, uint256 tokenId) 
        public 
        override(ERC721A) 
        onlyAllowedOperator(from) 
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public 
        override(ERC721A)
        onlyAllowedOperator(from) 
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) 
        public 
        override(ERC721A) 
        onlyAllowedOperator(from) 
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @dev Generate hash of current slot booking operation
    function _bookOperationHash(address owner, uint64 slotId, uint64 validityTimestamp, uint64 nonce) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            _hashSalt,
            owner,
            block.chainid,
            slotId,
            validityTimestamp,
            nonce
        ));
    }

    /// @dev Check, whether a message was signed by a trusted address
    function _isTrustedSigner(bytes32 hash, bytes memory signature) internal view returns (bool) {
        return _signerAddress == ECDSA.recover(hash, signature);
    }
}