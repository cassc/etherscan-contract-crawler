// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//  ==========  External imports    ==========

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

//  ==========  Extension imports    ==========

import "../extensions/ContractMetadata.sol";
import "../extensions/PlatformFee.sol";
import "../extensions/PrimarySale.sol";
import "../extensions/Royalty.sol";
import "../extensions/Ownable.sol";
import "../extensions/Role.sol";
//  ==========  Internal imports    ==========

import "../interfaces/ISparkbloxContract.sol";
import "./extensions/interface/IDynamicCollection.sol";
import "../openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

//  ==========  Features    ==========

import "../lib/MerkleProof.sol";

contract DynamicCollection is
    Initializable,
    Role,
    ISparkbloxContract,
    IDynamicCollection,
    ContractMetadata,
    PlatformFee,
    PrimarySale,
    Royalty,
    Ownable,
    Multicall,
    ERC2771ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable,
    ERC721AUpgradeable
{   
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    using StringsUpgradeable for uint256;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("DynamicCollection");
    uint256 private constant VERSION = 1;

    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @dev Only FACTORY_ROLE holders can set Platform Fee Informations.
    bytes32 private constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    /// @dev Max bps in the sparkblox system.
    uint256 private constant MAX_BPS = 10_000;

    /// @dev The token ID of the next token to mint.
    uint256 public nextTokenIdToMint;

    /// @dev The max number of NFTs a wallet can mint.
    uint256 public maxWalletMintCount;

    /// @dev Global max total supply of NFTs.
    uint256 public maxTotalSupply;

    /// @dev The set of all sales phases, at any given moment.
    SalesPhaseList public salesPhase;
    
    /// @dev baseURI of token URI
    string internal baseURI;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from address => total number of NFTs a wallet has minted.
    mapping(address => uint256) public walletMintCount;

    using StringsUpgradeable for uint256;
    ///@dev Token ID => sketchId of NFT a wallet has minted
    mapping(uint256 => uint256) public sketchToToken;

    ///@dev Token ID => hash of NFT a wallet has minted
    mapping(uint256 => uint256) hashToToken;

    ///@dev salephase => sketchId for category support
    mapping(uint256 => uint256[]) sketchIdsBySalePhaseId;
    
    /*/////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
                                    Events
     ////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    ///@dev Emitted when minting with hashes and sketchIds
    event HashesAdded(address minter, uint256[] hashes);

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint256 _maxTotalSupply,
        string memory _baseURI
    ) external initializerERC721A initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ERC721A_init(_name, _symbol);
        __ERC2771Context_init(_trustedForwarders);
        __ReentrancyGuard_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupContractURI(_contractURI);

        // Initialize this contract's state.
        _setupOwner(tx.origin);
        baseURI = _baseURI;
        maxTotalSupply = _maxTotalSupply;

        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _setupRole(MINTER_ROLE, tx.origin);
        _setupRole(TRANSFER_ROLE, tx.origin);
        _setupRole(TRANSFER_ROLE, address(0));
        _setupRole(FACTORY_ROLE, msg.sender);

        _setupPrimarySaleRecipient(_saleRecipient);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }
    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view override(ERC721AUpgradeable, IERC721AUpgradeable )returns (string memory) {
        return
            string(
                abi.encodePacked(
                    baseURI,
                    _tokenId.toString(),
                    "/",
                    sketchToToken[_tokenId].toString(),
                    "/",
                    hashToToken[_tokenId].toHexString()
                )
            );
    }
    /* ///////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
                                    Custom function for Orkhan project    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable, AccessControlEnumerableUpgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    ///@dev customize mint function for Orkhan project with sketchId and hash
    function mintTo(
        address recipient,
        bytes32[] calldata proofs,
        uint256 _pricePerToken,
        uint256 _salesPhaseId,
        uint256 _quantityLimitPerWallet,
        uint256[] calldata _hashes,
        uint256[] calldata _sketchIds
    ) external payable nonReentrant {
        require(_hashes.length == _sketchIds.length, "HashData length must match SketchData length");
        uint256 amount = _hashes.length;
        uint256 tokenIdToMint = nextTokenIdToMint;

        verifyMint(_salesPhaseId,  recipient, amount, _pricePerToken, proofs, _quantityLimitPerWallet);

        // If there's a price, collect price.
        collectMintPrice(amount, _pricePerToken);

        // Mint the relevant NFTs to minter.
        _mintTo(recipient, _salesPhaseId, amount, _hashes, _sketchIds);

        emit TokensMinted(_salesPhaseId,  recipient, recipient, tokenIdToMint, amount);
    }

    ///@dev mint token with hash and sketch
    function _mintTo(
        address _to,
        uint256 _salesphaseId,
        uint256 _quantityBeingMinted,
        uint256[] calldata _hashes,
        uint256[] calldata _sketchIds
    ) internal {
        validateCategory(_salesphaseId, _sketchIds);
        salesPhase.phases[_salesphaseId].supplyMinted += _quantityBeingMinted;
        salesPhase.supplyMintedByWallet[_salesphaseId][_to] += _quantityBeingMinted;

        // if transfer minted tokens is called when `to != msg.sender`, it'd use msg.sender's limits.
        // behavior would be similar to `msg.sender` mint for itself, then transfer to `_to`.
        salesPhase.limitLastMintTimestamp[_salesphaseId][_to] = block.timestamp;
        walletMintCount[_to] += _quantityBeingMinted;

        uint256 tokenIdToMint = nextTokenIdToMint;

        require(tokenIdToMint +_quantityBeingMinted <= maxTotalSupply, "Exceed MaxTotal");
        
        for (uint256 i; i < _hashes.length; i++) {
            sketchToToken[tokenIdToMint + i] = _sketchIds[i];
            hashToToken[tokenIdToMint + i] = _hashes[i];
        }
        emit HashesAdded(_to, _hashes);

        _safeMint(_to, _quantityBeingMinted);

        nextTokenIdToMint = tokenIdToMint + _quantityBeingMinted;
        if(nextTokenIdToMint > maxTotalSupply && maxTotalSupply != 0) {
            revert('Exceed maxTotalSupply');
        }
    }

    ///@dev validate if sketchids included in category
    function validateCategory(uint256 _salephaseId, uint256[] memory _sketchIds) public view returns (bool) {
        uint256[] memory sketchIdsOfCurPhase = sketchIdsBySalePhaseId[_salephaseId];

        if (sketchIdsOfCurPhase.length == 0) {
            return true;
        }

        for (uint256 i = 0; i < _sketchIds.length; i++) {
            uint256 _sketchId = _sketchIds[i];
            if (i > 0 && _sketchId == _sketchIds[i - 1]) {
                continue;
            }
            bool bValid = false;

            for (uint256 j = 0; j < sketchIdsOfCurPhase.length; j++) {
                if (_sketchId == sketchIdsOfCurPhase[j]) {
                    bValid = true;
                    break;
                }
            }

            if (bValid == false) {
                revert("sketchIds are invalid");
            }
        }
        return true;
    }

    /// @dev Collects and distributes the primary sale value of NFTs being Minted.
    function collectMintPrice(
        uint256 _quantityToMint,
        uint256 _pricePerToken
    ) internal {
        if (_pricePerToken == 0) {
            return;
        }

        (address platformFeeRecipient, uint16 platformFeeBps) = getPlatformFeeInfo();
        address saleRecipient = primarySaleRecipient();
        
        uint256 totalPrice = _quantityToMint * _pricePerToken;
        uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;

        require(msg.value == totalPrice, "must send total price.");

        if (platformFeeRecipient != address(0) && platformFeeBps > 0) {
            payable(platformFeeRecipient).transfer(platformFees);
        }
        
        payable(saleRecipient).transfer(totalPrice - platformFees);
    }

    ///@dev Let a contract admin set sales phases
    function setSalesPhases(
        SalesPhase[] calldata _phases,
        uint256[][] calldata arrayOfsketchIds,
        bool _resetMintEligibility
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_phases.length == arrayOfsketchIds.length, "Length of sketchId not match to phases' length");

        uint256 existingStartIndex = salesPhase.currentStartId;
        uint256 existingPhaseCount = salesPhase.count;

        uint256 newStartIndex = existingStartIndex;
        if (_resetMintEligibility) {
            newStartIndex = existingStartIndex + existingPhaseCount;
        }

        salesPhase.count = _phases.length;
        salesPhase.currentStartId = newStartIndex;

        for (uint256 i = 0; i < _phases.length; i++) {
            require(_phases[i].endTimestamp > _phases[i].startTimestamp, "ST");

            uint256 supplyMintedAlready = salesPhase.phases[newStartIndex + i].supplyMinted;
            require(supplyMintedAlready <= _phases[i].maxMintableSupply, "max supply minted already");

            salesPhase.phases[newStartIndex + i] = _phases[i];
            salesPhase.phases[newStartIndex + i].supplyMinted = supplyMintedAlready;

            sketchIdsBySalePhaseId[newStartIndex + i] = arrayOfsketchIds[i];
        }
    }

     /// @dev Checks a request to mint NFTs against the active sales phase's criteria.
    function verifyMint(
        uint256 _salesphaseId,
        address _minter,
        uint256 _quantity,
        uint256 _pricePerToken,
        bytes32[] memory _proofs,
        uint256 _quantityLimitPerWallet
    ) public view returns(bool) {
        SalesPhase memory curSalesPhase = salesPhase.phases[_salesphaseId];
        if (curSalesPhase.merkleRoot != bytes32(0)) {
            (bool isValid, ) = MerkleProof.verify(
                _proofs,
                curSalesPhase.merkleRoot,
                keccak256(abi.encodePacked(_minter, _quantityLimitPerWallet))
            );

            require(isValid, "non-whitelisted");
        }
        else{
            require(_quantityLimitPerWallet == curSalesPhase.quantityLimitPerWallet, "invalid QLPW");
        }

        uint256 mintLimit = _quantityLimitPerWallet;
        uint256 mintPrice = curSalesPhase.pricePerToken;
        uint256 lastMintedTime = salesPhase.limitLastMintTimestamp[_salesphaseId][_minter];
        uint256 supplyMintedByWallet = salesPhase.supplyMintedByWallet[_salesphaseId][_minter];

        require (block.timestamp > lastMintedTime + curSalesPhase.waitTimeInSecondsBetweenMints, '!BFT');

        if (_pricePerToken != mintPrice) {
            revert("!PriceOrCurrency");
        }
        if (_quantity == 0 || supplyMintedByWallet + _quantity > mintLimit) {
            revert("!Qty");
        }
        if (curSalesPhase.supplyMinted + _quantity > curSalesPhase.maxMintableSupply) {
            revert("!MaxSupply");
        }
        if (curSalesPhase.startTimestamp > block.timestamp) {
            revert("cant mint yet");
        }
        if (curSalesPhase.endTimestamp < block.timestamp) {
            revert("Sales Phased Ended");
        }

        return true;
    }

     /*///////////////////////////////////////////////////////////////
                        Getter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the number of minted nfts by address and salephase id

    function getSupplyMintedByWallet(uint256 phaseId, address _minter) public view returns (uint256 supplyMintedByWallet) {
        return salesPhase.supplyMintedByWallet[phaseId][_minter];
    }

    /// @dev Returns the timestamp for when a minter is eligible for minting NFTs again.
    function getSalesphaseTimestamp(uint256 _salesphaseId, address _minter)
        public
        view
        returns (uint256 lastMintTimestamp, uint256 nextValidMintTimestamp)
    {
        lastMintTimestamp = salesPhase.limitLastMintTimestamp[_salesphaseId][_minter];

        unchecked {
            nextValidMintTimestamp =
                lastMintTimestamp +
                salesPhase.phases[_salesphaseId].waitTimeInSecondsBetweenMints;

            if (nextValidMintTimestamp < lastMintTimestamp) {
                nextValidMintTimestamp = type(uint256).max;
            }
        }
    }

    /// @dev Returns the sales phase at the given uid.
    function getSalesPhaseById(uint256 _salesphaseId) external view returns (SalesPhase memory condition) {
        condition = salesPhase.phases[_salesphaseId];
    }

    /// @dev Returns the SketchIds of a sale phase
    function getSketchIdsBySalephase(uint256 _salePhaseId) external view returns (uint256[] memory) {
        return sketchIdsBySalePhaseId[_salePhaseId];
    }

    /*///////////////////////////////////////////////////////////////
                        Setter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a contract admin set a mint count for a wallet.
    function setWalletMintCount(address _minter, uint256 _count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        walletMintCount[_minter] = _count;
        emit WalletMintCountUpdated(_minter, _count);
    }

    /// @dev Lets a contract admin set a maximum number of NFTs that can be minted by any wallet.
    function setMaxWalletMintCount(uint256 _count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxWalletMintCount = _count;
        emit MaxWalletMintCountUpdated(_count);
    }

    /// @dev Lets a contract admin set the global maximum supply for collection's NFTs.
    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxTotalSupply = _maxTotalSupply;
        emit MaxTotalSupplyUpdated(_maxTotalSupply);
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        
        _burn(tokenId, true);
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721AUpgradeable) {
        super._beforeTokenTransfers(from, to, firstTokenId, batchSize);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "!TRANSFER_ROLE");
        }
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    override
    {}

    /// @dev Checks whether caller has admin role
   function verifyAdminRole() internal view override returns (bool) {
        if ( hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            return true;
        }
        else {
            revert("!Admin");
        }
    }

    //// @dev Checks whether caller has mint role
    function verifyMintRole() internal view override returns (bool) {
        if(hasRole(MINTER_ROLE, _msgSender())){
            return true;
        }
        else {
            revert("Not authorized");
        }
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal view override returns (bool) {
        return hasRole(FACTORY_ROLE, msg.sender);
    }

    function getMintPrice(uint256 _salesPhaseId, uint256 _amounts) external view returns(uint256 price){
        price = salesPhase.phases[_salesPhaseId].pricePerToken * _amounts;
    } 

   function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }
    
       function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

}