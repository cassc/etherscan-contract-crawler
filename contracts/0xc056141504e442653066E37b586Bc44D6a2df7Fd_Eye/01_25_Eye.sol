/* --------------------------------- ******* ----------------------------------- 
                                       THE

                            ███████╗██╗   ██╗███████╗
                            ██╔════╝╚██╗ ██╔╝██╔════╝
                            █████╗   ╚████╔╝ █████╗  
                            ██╔══╝    ╚██╔╝  ██╔══╝  
                            ███████╗   ██║   ███████╗
                            ╚══════╝   ╚═╝   ╚══════╝
                                 FOR ADVENTURERS
                                                                                   
                             .-=++=-.........-=++=-                  
                        .:..:++++++=---------=++++++:.:::            
                     .=++++----=++-------------===----++++=.         
                    .+++++=---------------------------=+++++.
                 .:-----==------------------------------------:.     
                =+++=---------------------------------------=+++=    
               +++++=---------------------------------------=++++=   
               ====-------------=================-------------===-   
              -=-------------=======================-------------=-. 
            :+++=----------============ A ============----------=+++:
            ++++++--------======= MAGICAL DEVICE =======---------++++=
            -++=----------============ THAT ============----------=++:
             ------------=========== CONTAINS ==========------------ 
            :++=---------============== AN =============----------=++-
            ++++++--------========== ON-CHAIN =========--------++++++
            :+++=----------========== WORLD ==========----------=+++:
              .==-------------=======================-------------=-  
                -=====----------===================----------======   
               =+++++---------------------------------------++++++   
                =+++-----------------------------------------+++=    
                  .-=----===---------------------------===-----:.     
                      .+++++=---------------------------=+++++.        
                       .=++++----=++-------------++=----++++=:         
                         :::.:++++++=----------++++++:.:::            
                                -=+++-.........-=++=-.                 

                            HTTPS://EYEFORADVENTURERS.COM
   ----------------------------------- ******* ---------------------------------- */

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import {IEye} from "./interfaces/IEye.sol";
import {ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import {ERC721ABurnableUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";
import {ERC721AQueryableUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IEyeConstants} from "./interfaces/IEyeConstants.sol";
import {IEyeMetadata} from "./interfaces/IEyeMetadata.sol";

contract Eye is
    IEye,
    ERC721AUpgradeable,
    ERC721ABurnableUpgradeable,
    ERC721AQueryableUpgradeable,
    ERC2981,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    /* --------------------------------- MINTING -------------------------------- */
    uint256 public mintCost;
    uint256 public maxSupply;
    uint256 public maxArtifactSupply;
    uint256 public currentArtifactSupply;
    uint16 private _reservedSupply;

    /* -------------------------------- ROYALTIES ------------------------------- */
    uint256 private constant _ROYALTY = 640;

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    /* --------------------------------- MINTING -------------------------------- */
    uint256 private _artifactId;
    bytes32 private _preMintMerkleRoot;
    bytes32 private _friendMerkleRoot;
    Phase public mintingPhase;
    mapping(uint256 => mapping(address => bool)) public friendMintClaimed;
    mapping(uint256 => mapping(address => uint256)) public preMintClaimed;
    bool public friendMintOpen;
    /* -------------------------------- RENDERER -------------------------------- */
    address public metadataAddress;
    /* ------------------------------  CORE TRAITS------------------------------- */
    string private _artifactName;
    address private _eyeConstantsAddress;
    /* -------------------------- COLLECTION CURATION --------------------------- */
    bytes32[] public curatedLibrariumIds;
    uint16[] public curatedStoryIds;
    address public curatorAddress;
    /* -------------------------- INDIVIDUAL CURATION --------------------------- */
    mapping(uint256 => bytes32[]) private _selectedStories;

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /* --------------------------------- MINTING -------------------------------- */
    event MintingPhaseStarted(Phase phase);
    event FriendMintingIsOpen(bool isOpen);

    /* -------------------------------- RENDERER -------------------------------- */
    event MetadataAddressUpdated(address addr);

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error NotEyeOwner();
    error EyeNotFound();
    error MerkleProofInvalid();
    error InvalidAddress();
    error PaymentAmountInvalid();

    error MintMaxReached();
    error MintNotAuthorized();
    error MintPhaseNotOpen();
    error MintAlreadyClaimed();
    error MintTooManyEyes();

    error NoBalance();
    error WithdrawFailed();

    error StoryIdExists();
    error NotCurator();
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */
    /// @notice Requires the caller to be the owner of the specified tokenId.
    modifier onlyOwnerOf(uint256 tokenId) {
        if (msg.sender != ownerOf(tokenId)) revert NotEyeOwner();
        _;
    }
    /* -------------------------------- PAYMENTS -------------------------------- */
    /// @notice Requires msg.value be exactly the specified amount.
    modifier onlyIfPaymentAmountValid(uint256 value) {
        if (msg.value != value) revert PaymentAmountInvalid();
        _;
    }
    /* --------------------------------- MINTING -------------------------------- */

    /// @notice Requires the current total Eye supply to be less than the max supply
    modifier onlyIfSupplyMintable(uint256 amount) {
        if ((currentArtifactSupply + amount) > maxArtifactSupply)
            revert MintMaxReached();
        _;
    }
    /// @notice Requires the a valid merkle proof for the specified merkle root.
    modifier onlyIfValidMerkleProof(bytes32 root, bytes32[] calldata proof) {
        if (
            !MerkleProof.verify(
                proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert MerkleProofInvalid();
        _;
    }
    /// @notice Requires Friends and Family mint to be open
    modifier onlyIfFriendMintIsOpen() {
        if (!friendMintOpen) revert MintPhaseNotOpen();
        _;
    }
    /// @notice Requires the specified minting phase be active or have been active before
    modifier onlyIfMintingPhaseIsSetToOrAfter(Phase minimumPhase) {
        if (mintingPhase < minimumPhase) revert MintPhaseNotOpen();
        _;
    }
    /// @notice Requires the specified minting phase be active.
    modifier onlyIfMintingPhaseIsSetTo(Phase phase) {
        if (mintingPhase != phase) revert MintPhaseNotOpen();
        _;
    }
    /// @notice Requires that an address only claims one token per address.
    modifier onlyIfNotAlreadyClaimedFriendMint() {
        if (friendMintClaimed[_artifactId][msg.sender])
            revert MintAlreadyClaimed();
        _;
    }

    /// @notice Requires that an address only pre-mints <= 10 tokens
    modifier onlyIfLessThanPreMintMax(uint256 amount) {
        if (preMintClaimed[_artifactId][msg.sender] + amount > 10)
            revert MintTooManyEyes();
        _;
    }
    /* --------------------------------- CURATING -------------------------------- */
    /// @notice Requires the caller to be the owner of the specified tokenId.
    modifier onlyCurator() {
        if (msg.sender != curatorAddress) revert NotCurator();
        _;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    function initialize(
        address eyeConstantsAddress_,
        uint256 maxSupply_,
        address curatorAddress_
    ) public initializerERC721A initializer {
        __ERC721A_init("The Eye", "EYE");
        __ERC721ABurnable_init();
        __ERC721AQueryable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        _eyeConstantsAddress = eyeConstantsAddress_;
        maxSupply = maxSupply_;
        curatorAddress = curatorAddress_;
        mintingPhase = Phase.INIT;
        friendMintOpen = false;
        _artifactId = 0;
    }

    /* ---------------------------------- ADMIN --------------------------------- */
    /// @notice Initializes an artifact for mint. Only execute to restarting/start a new minting cycle.
    /// @param _artifactName_ The name of the artifact.
    /// @param mintCost_ Price in wei to mint an eye.
    /// @param maxArtifactSupply_ The maximum supply of the artifact.
    /// @param reservedSupply_ The amount of supply to reserve for the artifact.
    function initializeArtifact(
        string memory _artifactName_,
        uint256 mintCost_,
        uint256 maxArtifactSupply_,
        uint16 reservedSupply_
    ) external onlyOwner {
        _artifactName = _artifactName_;
        mintCost = mintCost_;
        maxArtifactSupply = maxArtifactSupply_;
        _reservedSupply = reservedSupply_;
        currentArtifactSupply = 0;
        mintingPhase = Phase.ADMIN;
        friendMintOpen = false;
        _preMintMerkleRoot = "";
        _friendMerkleRoot = "";
        _artifactId += 1;
    }

    /// @notice Allows owner to set a merkle root for Pre Mint Access List.
    /// @param newRoot The new merkle root to set.
    function setPreMintMerkleRoot(bytes32 newRoot) external onlyOwner {
        _preMintMerkleRoot = newRoot;
    }

    /// @notice Allows owner to set a merkle root for Friends and Family Access List.
    /// @param newRoot The new merkle root to set.
    function setFriendMerkleRoot(bytes32 newRoot) external onlyOwner {
        _friendMerkleRoot = newRoot;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   MINTING                                  */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- ADMIN --------------------------------- */
    /// @notice Allows owner to mint  Eyes for every 7 contributor addresses.
    /// @param amount The number of Eyes to mint per address.
    /// @param addr An array of 7 addresses.
    function mintDistribution(uint256 amount, address[] calldata addr)
        external
        onlyOwner
        onlyIfMintingPhaseIsSetTo(Phase.ADMIN)
        onlyIfSupplyMintable(amount)
        nonReentrant
    {
        // insert some check for max minting during distribution phase
        if (currentArtifactSupply + amount > (_reservedSupply))
            revert MintMaxReached();
        for (uint16 i; i < addr.length; ) {
            _safeMint(addr[i], amount);
            currentArtifactSupply += amount;
            unchecked {
                i++;
            }
        }
    }

    /* ------------------------------ Friend & Family ----------------------------- */
    /// @notice Mint your Eye if you're on the Friends and Family list.
    /// @param merkleProof A Merkle proof of the caller's address in the Friends and Family list.
    function mintFriend(bytes32[] calldata merkleProof) external nonReentrant {
        if (!isFriendMintClaimable(merkleProof)) revert MintNotAuthorized();

        _safeMint(msg.sender, 1);
        friendMintClaimed[_artifactId][msg.sender] = true;
    }

    /// @notice Provides the msg.sender mint status
    /// @param merkleProof A Merkle proof of the caller's address in the Friends and Family list.
    function isFriendMintClaimable(bytes32[] calldata merkleProof)
        public
        view
        onlyIfFriendMintIsOpen
        onlyIfMintingPhaseIsSetToOrAfter(Phase.ADMIN)
        onlyIfNotAlreadyClaimedFriendMint
        onlyIfValidMerkleProof(_friendMerkleRoot, merkleProof)
        onlyIfSupplyMintable(1)
        returns (bool)
    {
        return true;
    }

    /// @notice Allows the owner to start the Friends and Family minting phase.
    function toggleFriendMintOpen() external onlyOwner {
        if (friendMintOpen) {
            friendMintOpen = false;
        } else {
            friendMintOpen = true;
        }

        emit FriendMintingIsOpen(friendMintOpen);
    }

    /* -------------------------------- PRE-MINT -------------------------------- */
    /// @notice Mint your Eye if you're on the Early Birds list.
    /// @param merkleProof A Merkle proof of the caller's address in the Early Birds list.
    function preMint(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
        onlyIfPaymentAmountValid(mintCost * amount)
        onlyIfSupplyMintable(amount)
        onlyIfLessThanPreMintMax(amount)
        nonReentrant
    {
        if (!isPreMintClaimable(merkleProof)) revert MintNotAuthorized();
        _safeMint(msg.sender, amount);
        currentArtifactSupply += amount;
        preMintClaimed[_artifactId][msg.sender] += amount;
    }

    /// @notice Provides the msg.sender mint status
    /// @param merkleProof A Merkle proof of the caller's address in the Early Birds list.
    function isPreMintClaimable(bytes32[] calldata merkleProof)
        public
        view
        onlyIfMintingPhaseIsSetTo(Phase.PREMINT)
        onlyIfValidMerkleProof(_preMintMerkleRoot, merkleProof)
        returns (bool)
    {
        return true;
    }

    /// @notice Allows the owner to start the Public minting phase.
    function startPreMint()
        external
        onlyOwner
        onlyIfMintingPhaseIsSetTo(Phase.ADMIN)
    {
        mintingPhase = Phase.PREMINT;
        emit MintingPhaseStarted(mintingPhase);
    }

    /// @notice Get the price for an Eye based on your wallet.
    function getPrice() external view returns (uint256) {
        return mintCost;
    }

    /* --------------------------------- PUBLIC --------------------------------- */
    /// @notice Mint your Eye.
    /// @param amount The amount of Eye's to mint.
    function mint(uint256 amount)
        external
        payable
        onlyIfMintingPhaseIsSetTo(Phase.PUBLIC)
        onlyIfPaymentAmountValid(mintCost * amount)
        onlyIfSupplyMintable(amount)
        nonReentrant
    {
        if (amount > 10) revert MintTooManyEyes();
        _safeMint(msg.sender, amount);
        currentArtifactSupply += amount;
    }

    /// @notice Allows the owner to start the Public minting phase.
    function startPublicMint()
        external
        onlyOwner
        onlyIfMintingPhaseIsSetTo(Phase.PREMINT)
    {
        mintingPhase = Phase.PUBLIC;
        emit MintingPhaseStarted(mintingPhase);
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                            COLLECTION CURATION                             */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- ADMIN --------------------------------- */
    /// @notice Update the curated story list
    function updateCollectionCuration(Story[] memory stories)
        external
        onlyCurator
    {
        curatedLibrariumIds = new bytes32[](stories.length);
        curatedStoryIds = new uint16[](stories.length);
        for (uint16 i = 0; i < stories.length; ) {
            curatedLibrariumIds[i] = stories[i].librariumId;
            curatedStoryIds[i] = stories[i].id;
            unchecked {
                i++;
            }
        }
    }

    /// @notice Update the curator address
    function updateCuratorAddress(address curator) external onlyOwner {
        curatorAddress = curator;
    }

    /* --------------------------------- PUBLIC --------------------------------- */
    /// @notice Get the librarium IDs of all storyIds
    function getCollectionCuration()
        external
        view
        returns (Story[] memory storiesList)
    {
        storiesList = new Story[](curatedLibrariumIds.length);
        for (uint16 i = 0; i < curatedLibrariumIds.length; ) {
            storiesList[i] = Story(curatedStoryIds[i], curatedLibrariumIds[i]);
            unchecked {
                i++;
            }
        }
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                            INDIVIDUAL CURATION                             */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- ADMIN --------------------------------- */
    /// @notice Adds a new librarium ID to a specific storyId
    function updateIndividualCurationByCurator(
        uint256 tokenId,
        bytes32[] calldata librariumIds
    ) external onlyCurator {
        _selectedStories[tokenId] = librariumIds;
    }

    /* --------------------------------- PUBLIC --------------------------------- */
    /// @notice Get the librarium IDs of all storyIds
    function getIndividualCuration(uint256 tokenId)
        external
        view
        returns (bytes32[] memory storiesOnNFT)
    {
        return _selectedStories[tokenId];
    }

    /// @notice Get the librarium IDs of all storyIds
    function updateIndividualCuration(
        uint256 tokenId,
        bytes32[] calldata librariumIds
    ) external onlyOwnerOf(tokenId) {
        _selectedStories[tokenId] = librariumIds;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                  RENDERER                                  */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- ADMIN --------------------------------- */
    /// @notice Updates the metadata address for Eye.
    /// @param addr The new metadata address. Must conform to IEyeMetadata.
    function setMetadataAddress(address addr) external onlyOwner {
        if (addr == address(0)) revert InvalidAddress();
        metadataAddress = addr;
        emit MetadataAddressUpdated(addr);
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                 CORE TRAITS                                */
    /* -------------------------------------------------------------------------- */
    /// @notice Get the item's artifact name
    function getArtifactName() external view returns (string memory) {
        return _artifactName;
    }

    /// @notice Get the item's attunement
    function getAttunement(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return (getAttunementIndex(tokenId) == 0) ? "Dark" : "Light";
    }

    /// @notice Get the item's order name
    function getOrder(uint256 tokenId) public view returns (string memory) {
        return
            IEyeConstants(_eyeConstantsAddress).getOrderName(
                getOrderIndex(tokenId)
            );
    }

    /// @notice Get the item's name prefix
    function getNamePrefix(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return
            IEyeConstants(_eyeConstantsAddress).getNamePrefix(
                _randomEYE(_toString(tokenId)) %
                    IEyeConstants(_eyeConstantsAddress).getNamePrefixCount()
            );
    }

    /// @notice Get the item's name suffix
    function getNameSuffix(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return
            IEyeConstants(_eyeConstantsAddress).getNameSuffix(
                _randomEYE(_toString(tokenId)) %
                    IEyeConstants(_eyeConstantsAddress).getNameSuffixCount()
            );
    }

    /// @notice Get the item's vision name
    function getVision(uint256 tokenId) public view returns (string memory) {
        return
            IEyeConstants(_eyeConstantsAddress).getVisionName(
                getVisionIndex(tokenId)
            );
    }

    /// @notice Get the NFTs name based on the Loot contract pluck function.
    function getName(uint256 tokenId) public view returns (string memory) {
        string memory name = _artifactName;
        uint256 greatness = getGreatness(tokenId);
        if (greatness > 14) {
            name = string(abi.encodePacked(name, " of ", getOrder(tokenId)));
        }
        if (greatness >= 19) {
            name = string(
                abi.encodePacked(
                    unicode"“",
                    getNamePrefix(tokenId),
                    " ",
                    getNameSuffix(tokenId),
                    unicode"” ",
                    name
                )
            );
            if (greatness > 19) {
                name = string(abi.encodePacked(name, " +1"));
            }
        }
        return name;
    }

    /// @notice Get the item's vision index
    function getConditionIndex(uint256 tokenId) public view returns (uint256) {
        return
            _randomEYE(_toString(tokenId)) %
            IEyeConstants(_eyeConstantsAddress).getConditionCount();
    }

    /// @notice Get the item's vision index
    function getVisionIndex(uint256 tokenId) public view returns (uint256) {
        return
            _randomEYE(_toString(tokenId)) %
            IEyeConstants(_eyeConstantsAddress).getVisionCount();
    }

    /// @notice Get the item's order index
    function getOrderIndex(uint256 tokenId) public view returns (uint256) {
        return
            _randomEYE(_toString(tokenId)) %
            IEyeConstants(_eyeConstantsAddress).getOrderCount();
    }

    /// @notice Get the item's attunement index
    function getAttunementIndex(uint256 tokenId) public view returns (uint256) {
        if (getOrderIndex(tokenId) > 8) {
            return 0; //Dark
        } else {
            return 1; //Light
        }
    }

    /// @notice Get the greatness attribute
    function getGreatness(uint256 tokenId) public pure returns (uint256) {
        return _randomEYE(_toString(tokenId)) % 21;
    }

    /* -------------------------------- INTERNAL -------------------------------- */
    /// @notice "randomizer" based on the tokenId and category EYE
    function _randomEYE(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked("EYE", input)));
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                  ROYALTIES                                 */
    /* -------------------------------------------------------------------------- */
    /* --------------------------------- PUBLIC --------------------------------- */
    /// @notice EIP2981 royalty standard
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (salePrice * _ROYALTY) / 10000);
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   ERC721A                                  */
    /* -------------------------------------------------------------------------- */
    /* --------------------------------- PUBLIC --------------------------------- */
    /// @notice The standard ERC721 tokenURI function. Routes to the Metadata contract.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert EyeNotFound();
        return IEyeMetadata(metadataAddress).tokenURI(tokenId);
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawERC20(IERC20 token) public nonReentrant {
        uint256 b = token.balanceOf(address(this));
        if (b == 0) revert NoBalance();
        bool success = token.transfer(owner(), b);
        if (!success) revert WithdrawFailed();
    }

    /* -------------------------------- INTERNAL -------------------------------- */
    /// @notice ERC721A override to start tokenId's at 1 instead of 0.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
    /* --------------------------------- ****** --------------------------------- */
}