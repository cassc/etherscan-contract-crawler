//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./utils/interfaces/IMetroMintAllocationProvider.sol";
import "./utils/interfaces/IMetroTokenUriProvider.sol";
import "./utils/interfaces/IMetroMintHook.sol";
import "./utils/interfaces/IMetroHibernation.sol";

contract MetroSeriesERC721 is ERC721, Ownable, AccessControl
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    // ====================================================
    // ROLES
    // ====================================================
    bytes32 public constant REWARDS_MINTER_ROLE = keccak256("REWARDS_MINTER_ROLE");

    // ====================================================
    // EVENTS
    // ====================================================
    event SeriesPausedStateChange(uint256 seriesId, bool paused);
    event SeriesPremintStateChange(uint256 seriesId, bool enabled);
    event TokenMinted(
        uint256 indexed tokenIndex,
        uint256 indexed seriesId,
        address minter,
        uint256 maxSupply,
        uint256 mintPrice,
        uint8 saleType
    );
    event CauseBeneficiaryChanged(uint256 seriesId, address indexed causeAddress, uint8 causePercentage );
    event TokenUriProviderChanged(uint256 seriesId, address newProviderAddress);
    event AllocationProviderChanged(uint256 seriesId, address newMintAllocationProvider);

    // ====================================================
    // STRUCT, ENUMS, etc
    // ====================================================
    struct SeriesStruct {
        uint256 privateMintPrice; // 32 bytes
        uint256 publicMintPrice; // 32 bytes
        uint256 tokenMintPrice; // 32 bytes
        address payable causeBeneficiary; // 20 bytes
        uint8 causePercentage; // 1 byte
        bool paused; // 1 byte
        bool privateMintActive; // 1 byte
        bool mintWithTokens; // 1 byte
        uint32 maxSupply; // 4 bytes
        uint32 numMinted; // 4 bytes
        IMetroMintAllocationProvider mintAllocationProvider; // 20 bytes
        IMetroTokenUriProvider tokenUriProvider; // 20 bytes
    }

    // ====================================================
    // STATE
    // ====================================================
    // series related vars
    SeriesStruct[] public series;
    mapping(uint256 => uint256) public tokenSeriesMapping;

    // counters, general vars, etc
    Counters.Counter private _tokenIdCounter;
    mapping(string => string) public contractInfo;

    IMetroMintHook public mintHook;
    IMetroHibernation public hibernation;

    bool private hibernationTransferFlag;

    // ====================================================
    // CONSTRUCTOR
    // ====================================================
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        {
            _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        }

    // ====================================================
    // OVERRIDES
    // ====================================================
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // @notice returns the series-specific-based tokenuri
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        // get tokenuri from a per-series provider. enable future-proof interoperability with upcoming series ;)
        if (address(series[tokenSeriesMapping[tokenId]].tokenUriProvider) != address(0)) {
            return series[tokenSeriesMapping[tokenId]].tokenUriProvider.tokenURI(tokenId);
        }

        return "tokenURI provider not set";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override
    {
        super._beforeTokenTransfer(from, to, tokenId);

        if(address(hibernation) != address(0) && hibernation.getHibernationEnabled() && !hibernationTransferFlag) {
            require(hibernation.getTokenHibernationState(tokenId) == false, "Token currently hibernating");
        }
    }

    // ====================================================
    // ADMIN
    // ====================================================
    function setContractInfo(string memory key, string memory value) public onlyOwner
    {
        contractInfo[key] = value;
    }

    // @notice sets up a new series
    function createSeries(
        uint32 maxSupply,
        uint256 privateMintPrice,
        uint256 publicMintPrice,
        uint256 tokenMintPrice,
        address payable causeBeneficiary,
        uint8 causePercentage,
        bool mintWithTokens,
        IMetroMintAllocationProvider mintAllocationProvider,
        IMetroTokenUriProvider tokenUriProviderContract
    )
        public
        onlyOwner
    {
        series.push(
            SeriesStruct(
                privateMintPrice,
                publicMintPrice,
                tokenMintPrice,
                causeBeneficiary,
                causePercentage,
                true,// paused
                true, // privateMintActive
                mintWithTokens,// mintWithTokens
                maxSupply,
                0, // numMinted
                mintAllocationProvider,
                tokenUriProviderContract
            )
        );
    }

    // @notice pauses a specific series only
    function toggleSeriesPausedState(uint256 seriesId)
        public
        onlyOwner
    {
        series[seriesId].paused = !series[seriesId].paused;
        emit SeriesPausedStateChange(seriesId, series[seriesId].paused);
    }

    // @notice conclude premint & open public mint
    function toggleSeriesPremintState(uint256 seriesId)
        public
        onlyOwner
    {
        series[seriesId].privateMintActive = !series[seriesId].privateMintActive;
        emit SeriesPremintStateChange(seriesId, series[seriesId].privateMintActive);
    }

    function setSeriesTokenUriProvider(uint256 seriesId, IMetroTokenUriProvider newTokenUriProvider)
        external
        onlyOwner
    {
        series[seriesId].tokenUriProvider = newTokenUriProvider;
        emit TokenUriProviderChanged(seriesId, address(newTokenUriProvider));
    }

    function setSeriesAllocationProvider(uint256 seriesId, IMetroMintAllocationProvider newMintAllocationProvider)
        public
        onlyOwner
    {
        series[seriesId].mintAllocationProvider = newMintAllocationProvider;
        emit AllocationProviderChanged(seriesId, address(newMintAllocationProvider));
    }

    function toggleSeriesMintWithTokens(uint256 seriesId) public onlyOwner
    {
        series[seriesId].mintWithTokens = !series[seriesId].mintWithTokens;
    }

    // @notice change the charity cause beneficiary
    function changeSeriesCause(uint256 seriesId, address payable newCauseBeneficiary, uint8 newPercentage)
        public
        onlyOwner
    {
        series[seriesId].causeBeneficiary = newCauseBeneficiary;
        series[seriesId].causePercentage = newPercentage;

        emit CauseBeneficiaryChanged(seriesId, series[seriesId].causeBeneficiary, newPercentage);
    }

    function setCustomMintAction(IMetroMintHook newMintHook) public onlyOwner
    {
        mintHook = newMintHook;
    }

    function setHibernationContractAddress(IMetroHibernation newHibernation) public onlyOwner
    {
        hibernation = newHibernation;
    }

    function reserveToken(uint256 seriesId) public onlyOwner
    {
        internalMint(seriesId, msg.sender, 0);
    }

    function withdrawFunds(address payable recipient, uint256 amount)
        public
        onlyOwner
    {
        require(address(recipient) != address(0), "Invalid recipient");
        recipient.transfer(amount);
    }

    // ====================================================
    // ROLE GATED
    // ====================================================
    /**
    @notice mint using rewards token
    @dev gated by REWARDS_MINTER_ROLE. caller (hibernation or token) will handle receipt of erc20
    tokens and be assigned this role
     */
    function mintWithRewards(uint256 seriesId, address minter) public onlyRole(REWARDS_MINTER_ROLE)
    {
        require(series[seriesId].mintWithTokens, "Minting with rewards not supported");
        internalMint(seriesId, minter, 3);
    }

    // ====================================================
    // INTERNAL
    // ====================================================
    function internalMint(uint256 seriesId, address minter, uint8 saleType)
        internal
    {
        require(!Address.isContract(minter), "Minting from contracts not allowed");
        require(!series[seriesId].paused, "Series minting is paused");
        require(series[seriesId].numMinted < series[seriesId].maxSupply, "All series works have been minted");

        uint256 tokenId = _tokenIdCounter.current();

        series[seriesId].numMinted ++;
        tokenSeriesMapping[tokenId] = seriesId;
        
        _tokenIdCounter.increment();
        _safeMint(minter, tokenId);

        // check causeBeneficiary is set
        if(address(series[seriesId].causeBeneficiary) != address(0))
        {
            // calculate and transfer to cause
            uint256 causeAmount = (series[seriesId].causePercentage * msg.value) / 100;
            series[seriesId].causeBeneficiary.transfer(causeAmount);
        }

        // call hook on custom handler (future implementation)
        if(address(mintHook) != address(0)) {
            mintHook.internalMintHook(seriesId, tokenId, saleType);
        }

        emit TokenMinted(
            tokenId,
            seriesId,
            minter,
            series[seriesId].maxSupply,
            series[seriesId].numMinted,
            saleType);
    }

    // ====================================================
    // PUBLIC API
    // ====================================================
    function privateMint(
        uint256 seriesId,
        bytes32[] calldata merkleProof,
        string memory extraData
    )
        public
        payable
    {
        require(series[seriesId].privateMintActive, "Private mint closed");
        require(msg.value >= series[seriesId].privateMintPrice, "Insufficient value sent (privateMint)");

        // ensure minter has sufficient allocation
        require(
            series[seriesId].mintAllocationProvider.getRemainingAllocation(
                msg.sender, merkleProof, extraData
            ) > 0, "No remaining allocation"
        );

        internalMint(seriesId, msg.sender, 1);

        // use up mint allocation
        series[seriesId].mintAllocationProvider.consumeAllocation(msg.sender, extraData);
    }

    function publicMint(uint256 seriesId)
        public
        payable
    {   
        require(!series[seriesId].privateMintActive, "Private mint in progress");
        require(msg.value >= series[seriesId].publicMintPrice, "Insufficient value sent (publicMint)");

        internalMint(seriesId, msg.sender, 2);
    }

    /**
    @notice places a token in hibernation
     */
    function startHibernation(uint256 tokenId) public
    {
        require(address(hibernation) != address(0), "Hibernation contract not set");
        require(msg.sender == ownerOf(tokenId), "Token not owned");
        hibernation.startHibernation(tokenId);
    }

    /**
    @notice removes a token from hibernation
    @dev owner has rights to force end hibernation
     */
    function endHibernation(uint256 tokenId) public
    {
        require(address(hibernation) != address(0), "Hibernation contract not set");
        require(msg.sender == ownerOf(tokenId) || msg.sender == owner(), "Insufficient access rights");
        hibernation.endHibernation(tokenId);
    }
    
    /**
    @notice a util method for holders to transfer whil in hibernation
     */ 
    function hibernationTransfer(uint256 tokenId, address recipient) public
    {
        require(hibernation.getHibernationEnabled(), "Hibernation not enabled");
        require(msg.sender == ownerOf(tokenId), "Tranfers can only be made by the token holder");

        hibernationTransferFlag = true;
        safeTransferFrom(msg.sender, recipient, tokenId);
        hibernationTransferFlag = false;
    }
}