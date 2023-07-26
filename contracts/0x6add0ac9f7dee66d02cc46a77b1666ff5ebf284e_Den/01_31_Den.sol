// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

import {VRFCoordinatorV2Interface} from "@chainlink/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/VRFConsumerBaseV2.sol";

import {IHoneyJarPortal} from "src/interfaces/IHoneyJarPortal.sol";
import {IHibernationDen} from "src/interfaces/IHibernationDen.sol";
import {IHoneyJar} from "src/interfaces/IHoneyJar.sol";
import {IGatekeeper} from "src/interfaces/IGatekeeper.sol";
import {GameRegistryConsumer} from "src/GameRegistryConsumer.sol";
import {CrossChainTHJ} from "src/CrossChainTHJ.sol";
import {Constants} from "src/Constants.sol";

/// @title Den (Mostly taken from HibernationDen.sol)
/// @notice Manages bundling & storage of NFTs. Mints honeyJar ERC721s
contract Den is
    IHibernationDen,
    VRFConsumerBaseV2,
    ERC721TokenReceiver,
    ERC1155TokenReceiver,
    GameRegistryConsumer,
    CrossChainTHJ,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;

    /// @notice Configuration for minting for games occurring at the same time.
    struct MintConfig {
        /// @dev number of free honey jars to be claimed. Should be sum(gates.maxClaimable)
        uint32 maxClaimableHoneyJar; // # of honeyJars that can be claimed (total)
        /// @dev value of the honeyJar in ERC20 -- Ohm is 1e9
        uint256 honeyJarPrice_ERC20;
        /// @dev value of the honeyJar in ETH
        uint256 honeyJarPrice_ETH;
    }

    /**
     *  Game Errors
     */
    // Contract State
    error NotInitialized();
    error AlreadyInitialized();

    // Game state
    error PartyAlreadyWoke(uint8 bundleId);
    error GameInProgress();
    error AlreadyTooManyHoneyJars(uint8 bundleId);
    error FermentedJarNotFound(uint8 bundleId);
    error GeneralMintNotOpen(uint8 bundleId);
    error InvalidBundle(uint8 bundleId);
    error NotSleeping(uint8 bundleId);
    error TooManyBundles();

    // User Errors
    error NotFermentedJarOwner(uint8 bundleId, uint256 honeyJarId);
    error InvalidInput(string method);
    error Claim_InvalidProof();
    error MekingTooManyHoneyJars(uint8 bundleId);
    error ZeroMint();
    error WrongAmount_ETH(uint256 expected, uint256 actual);
    error NotJarOwner();
    error InvalidChain(uint256 expectedChain, uint256 actualChain);

    /**
     * Events
     */
    event Initialized(MintConfig mintConfig);
    event PortalSet(address portal);
    event SlumberPartyStarted(uint8 bundleId);
    event SlumberPartyAdded(uint8 bundleId);
    event FermentedJarsFound(uint8 bundleId, uint256[] honeyJarIds);
    event MintConfigChanged(MintConfig mintConfig);
    event VRFConfigChanged(VRFConfig vrfConfig);
    event HoneyJarClaimed(uint256 bundleId, uint32 gateId, address player, uint256 amount);
    event SleeperAwoke(uint8 bundleId, uint256 tokenId, uint256 jarId, address player);
    event SleeperAdded(uint8 bundleId_, SleepingNFT sleeper);
    event CheckpointsUpdated(uint256 checkpointIndex, uint256[] checkpoints);

    /**
     * Configuration
     */
    IERC20 public immutable paymentToken; // OHM
    MintConfig public mintConfig;

    /**
     * Chainlink VRF Config
     */
    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations

    struct VRFConfig {
        bytes32 keyHash;
        uint64 subId; // https://vrf.chain.link/goerli/new
        uint16 minConfirmations; // Default is 3
        uint32 callbackGasLimit; // enough for ~5 words
    }

    VRFConfig private vrfConfig;

    /**
     * bearPouch
     */
    address payable private immutable paymaster;

    /**
     * Dependencies
     */
    IGatekeeper public immutable gatekeeper;
    IHoneyJar public immutable beraPunk; // BeraPunk tokens implement the same Inferface as THJ.sol
    VRFCoordinatorV2Interface internal immutable vrfCoordinator;
    IHoneyJarPortal public honeyJarPortal;

    /**
     * Internal Storage
     */
    bool public initialized;

    /// @notice the amount a gameAdmin can mint
    uint256 private adminMintAmount;

    /// @notice id of the next party
    /// @dev Required for storage pointers in next mapping
    SlumberParty[] public slumberPartyList;
    /// @notice bundleId --> SlumblerParty
    mapping(uint8 => SlumberParty) public slumberParties;
    /// @notice tracks free claims for a given bundle
    mapping(uint8 => uint32) public claimed;
    /// @notice Chainlink VRF request ID => bundleID
    mapping(uint256 => uint8) public rng;
    /// @notice Reverse mapping for honeyjar to bundle (UI)
    mapping(uint256 => uint8) public honeyJarToParty; // Reverse mapping for honeyJar to bundle (needed for UI)
    /// @notice list of HoneyJars associated with a particular SlumberParty (bundle)
    mapping(uint8 => uint256[]) public honeyJarShelf;

    constructor(
        address _vrfCoordinator,
        address _gameRegistry,
        address _beraPunkAddress,
        address _paymentToken,
        address _gatekeeper,
        address _paymaster
    ) VRFConsumerBaseV2(_vrfCoordinator) GameRegistryConsumer(_gameRegistry) CrossChainTHJ() {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        beraPunk = IHoneyJar(_beraPunkAddress);
        paymentToken = IERC20(_paymentToken);
        gatekeeper = IGatekeeper(_gatekeeper);
        paymaster = payable(_paymaster);
    }

    /// @notice additional parameters that are required to get the game running
    /// @param vrfConfig_ Chainlink  configuration
    /// @param mintConfig_ needed for the specific game
    function initialize(VRFConfig calldata vrfConfig_, MintConfig calldata mintConfig_, uint256 adminMintAmount_)
        external
        onlyRole(Constants.GAME_ADMIN)
    {
        if (initialized) revert AlreadyInitialized();

        initialized = true;
        vrfConfig = vrfConfig_;
        mintConfig = mintConfig_;

        adminMintAmount = adminMintAmount_;

        emit Initialized(mintConfig);
    }

    /// @notice Who is partying without me?
    function getSlumberParty(uint8 _bundleId) external view override returns (SlumberParty memory) {
        return slumberParties[_bundleId];
    }

    /// @notice Once a bundle is configured, transfers the configured assets into this contract.
    /// @notice Starts the gates within the Gatekeeper, which determine who is allowed early access and free claims
    /// @dev Bundles need to be preconfigured using addBundle from gameAdmin
    /// @dev publicMintTime is is configured to be the LAST item in the stageTimes from gameRegistry.
    function puffPuffPassOut(uint8 bundleId_) external payable onlyRole(Constants.GAME_ADMIN) {
        SlumberParty storage slumberParty = slumberParties[bundleId_];
        SleepingNFT[] storage sleepoors = slumberParty.sleepoors;
        uint256 sleeperCount = sleepoors.length;
        if (sleeperCount == 0) revert InvalidBundle(bundleId_);

        uint256[] memory allStages = _getStages();
        uint256 publicMintOffset = allStages[allStages.length - 1];

        slumberParties[bundleId_].publicMintTime = block.timestamp + publicMintOffset;

        for (uint256 i = 0; i < sleeperCount; ++i) {
            _transferSleeper(sleepoors[i], msg.sender, address(this));
        }

        // Only start gates if the configured chainId is the current chain.
        if (slumberParty.mintChainId == getChainId()) {
            gatekeeper.startGatesForBundle(bundleId_);
        } else if (address(honeyJarPortal) != address(0)) {
            // If the portal is set, the xChain message will be sent
            honeyJarPortal.sendStartGame{value: msg.value}(
                payable(msg.sender), slumberParty.mintChainId, bundleId_, sleeperCount, slumberParty.checkpoints
            );
        }
        emit SlumberPartyStarted(bundleId_);
    }

    /// @notice Does the same as function above, except doesn't transfer the NFTs.
    /// @notice is used on the destination chain in an xChain setup.
    /// @dev can only be called by the HoneyJar Portal
    function startGame(uint256 srcChainId, uint8 bundleId_, uint256 numSleepers_, uint256[] calldata checkpoints)
        external
        override
        onlyRole(Constants.PORTAL)
    {
        if (checkpoints.length > numSleepers_) revert InvalidInput("startGame::checkpoints");
        uint256[] memory allStages = _getStages();
        uint256 publicMintOffset = allStages[allStages.length - 1];

        SlumberParty storage party = slumberParties[bundleId_];
        if (party.sleepoors.length != 0) revert InvalidBundle(bundleId_);

        party.bundleId = bundleId_;
        party.checkpoints = checkpoints;
        party.assetChainId = srcChainId;
        party.mintChainId = getChainId(); // On the destination chain you MUST be able to mint.
        party.publicMintTime = block.timestamp + publicMintOffset;

        SleepingNFT memory emptyNft;
        for (uint256 i = 0; i < numSleepers_; ++i) {
            party.sleepoors.push(emptyNft);
        }
        gatekeeper.startGatesForBundle(bundleId_);

        emit SlumberPartyStarted(bundleId_);
        return;
    }

    /// @notice admin function to add more sleepers to the party once a bundle is started
    /// @param sleeper the NFT being added
    /// @param transfer to indicates if a transfer should be called. -- false: if an NFT is yeeted in/airdropped
    /// @dev If this done during a cross chain deployment, you MUST add an empty sleeper to the other chain
    function addToParty(uint8 bundleId_, SleepingNFT calldata sleeper, bool transfer)
        external
        onlyRole(Constants.GAME_ADMIN)
    {
        SlumberParty storage party = slumberParties[bundleId_];
        party.sleepoors.push(sleeper);

        if (transfer) {
            _transferSleeper(sleeper, msg.sender, address(this));
        }

        emit SleeperAdded(bundleId_, sleeper);
    }

    /// @notice method stores the configuration for the sleeping NFTs
    /// @param checkpoints_ number of jarMints that will trigger a VRF call
    // bundleId --> bundle --> []nfts
    function addBundle(
        uint256 mintChainId_,
        uint256[] calldata checkpoints_,
        address[] calldata tokenAddresses_,
        uint256[] calldata tokenIds_,
        bool[] calldata isERC1155_
    ) external onlyRole(Constants.GAME_ADMIN) returns (uint8) {
        uint256 inputLength = tokenAddresses_.length;
        if (inputLength == 0 || inputLength != tokenIds_.length || inputLength != isERC1155_.length) {
            revert InvalidInput("addBundle::inputLength");
        }
        if (inputLength < checkpoints_.length || checkpoints_.length == 0) {
            revert InvalidInput("addBundle::checkpoints");
        }

        if (slumberPartyList.length > 255) revert TooManyBundles();
        uint8 bundleId = uint8(slumberPartyList.length);

        // Add to the bundle mapping & list
        SlumberParty storage slumberParty = slumberPartyList.push(); // 0 initialized Bundle
        slumberParty.bundleId = bundleId;
        slumberParty.assetChainId = getChainId(); // Assets will be on this chain.
        slumberParty.mintChainId = mintChainId_; // minting can occur on another chain
        slumberParty.checkpoints = checkpoints_; //  checkpointIndex is defaulted to zero.

        // Synthesize sleeper configs from input
        for (uint256 i = 0; i < inputLength; ++i) {
            slumberParty.sleepoors.push(SleepingNFT(tokenAddresses_[i], tokenIds_[i], isERC1155_[i]));
        }

        slumberParties[bundleId] = slumberParty;

        emit SlumberPartyAdded(bundleId);
        return bundleId;
    }

    /// @dev internal helper function to perform conditional checks for minting state
    function _canMintHoneyJar(uint8 bundleId_, uint256 amount_) internal view {
        if (!initialized) revert NotInitialized();
        SlumberParty storage party = slumberParties[bundleId_];

        if (party.bundleId != bundleId_) revert InvalidBundle(bundleId_);
        if (party.mintChainId != getChainId()) revert InvalidChain(party.mintChainId, getChainId());
        if (party.publicMintTime == 0) revert NotSleeping(bundleId_);
        if (party.fermentedJars.length == party.sleepoors.length) revert PartyAlreadyWoke(bundleId_); // All the jars be found
        if (party.checkpointIndex == party.checkpoints.length) revert AlreadyTooManyHoneyJars(bundleId_);
        if (honeyJarShelf[bundleId_].length + amount_ > party.checkpoints[party.checkpoints.length - 1]) {
            revert MekingTooManyHoneyJars(bundleId_);
        }
        if (amount_ == 0) revert ZeroMint();
    }

    /// @notice Allows players to mint honeyJar with a valid proof
    /// @param proofAmount the amount of free claims you are entitled to in the claim
    /// @param proof The proof from the gate that allows the player to mint
    /// @param mintAmount actual amount of honeyJars you want to mint.
    function earlyMekHoneyJarWithERC20(
        uint8 bundleId,
        uint32 gateId,
        uint32 proofAmount,
        bytes32[] calldata proof,
        uint256 mintAmount
    ) external returns (uint256) {
        _canMintHoneyJar(bundleId, mintAmount);
        // validateProof checks that gates are open
        bool validProof = gatekeeper.validateProof(bundleId, gateId, msg.sender, proofAmount, proof);
        if (!validProof) revert Claim_InvalidProof();
        return _distributeERC20AndMintHoneyJar(bundleId, mintAmount);
    }

    /// @notice Allows players to mint honeyJar with a valid proof (Taking ETH as payment)
    /// @param proofAmount the amount of free claims you are entitled to in the claim
    /// @param proof The proof from the gate that allows the player to mint
    /// @param mintAmount actual amount of honeyJars you want to mint.
    function earlyMekHoneyJarWithEth(
        uint8 bundleId,
        uint32 gateId,
        uint32 proofAmount,
        bytes32[] calldata proof,
        uint256 mintAmount
    ) external payable returns (uint256) {
        _canMintHoneyJar(bundleId, mintAmount);
        // validateProof checks that gates are open
        bool validProof = gatekeeper.validateProof(bundleId, gateId, msg.sender, proofAmount, proof); // This shit needs to be bulletproof
        if (!validProof) revert Claim_InvalidProof();
        return _distributeETHAndMintHoneyJar(bundleId, mintAmount);
    }

    function mekHoneyJarWithERC20(uint8 bundleId_, uint256 amount_) external returns (uint256) {
        _canMintHoneyJar(bundleId_, amount_);
        if (slumberParties[bundleId_].publicMintTime > block.timestamp) revert GeneralMintNotOpen(bundleId_);
        return _distributeERC20AndMintHoneyJar(bundleId_, amount_);
    }

    function mekHoneyJarWithETH(uint8 bundleId_, uint256 amount_) external payable returns (uint256) {
        _canMintHoneyJar(bundleId_, amount_);
        if (slumberParties[bundleId_].publicMintTime > block.timestamp) revert GeneralMintNotOpen(bundleId_);

        return _distributeETHAndMintHoneyJar(bundleId_, amount_);
    }

    /// @dev internal helper function to collect payment and mint honeyJar
    /// @return tokenID of minted honeyJar
    function _distributeERC20AndMintHoneyJar(uint8 bundleId_, uint256 amount_) internal returns (uint256) {
        _distribute(mintConfig.honeyJarPrice_ERC20 * amount_);

        // Mint da honey
        return _mintHoneyJarForBear(msg.sender, bundleId_, amount_);
    }

    /// @dev internal helper function to collect payment and mint honeyJar
    /// @return tokenID of minted honeyJar
    function _distributeETHAndMintHoneyJar(uint8 bundleId_, uint256 amount_) internal returns (uint256) {
        uint256 price = mintConfig.honeyJarPrice_ETH;
        if (msg.value != price * amount_) revert WrongAmount_ETH(price * amount_, msg.value);

        _distribute(0);

        return _mintHoneyJarForBear(msg.sender, bundleId_, amount_);
    }

    /// @notice internal method to mint for a particular user
    /// @dev if the amount_ is > than multiple checkpoints, accounting WILL mess up.
    /// @param to user to mint to
    /// @param bundleId_ the bea being minted for
    function _mintHoneyJarForBear(address to, uint8 bundleId_, uint256 amount_) internal returns (uint256) {
        uint256 tokenId = beraPunk.nextTokenId();
        beraPunk.batchMint(to, amount_);

        // Have a unique tokenId for a given bundleId
        for (uint256 i = 0; i < amount_; ++i) {
            honeyJarShelf[bundleId_].push(tokenId);
            honeyJarToParty[tokenId] = bundleId_;
            ++tokenId;
        }

        // Find the special honeyJar when a checkpoint is passed.
        uint256 numMinted = honeyJarShelf[bundleId_].length;
        SlumberParty storage party = slumberParties[bundleId_];
        if (numMinted >= party.checkpoints[party.checkpointIndex]) {
            _fermentJars(bundleId_);
        }

        return tokenId - 1; // returns the lastID created
    }

    /// @notice Forcing function to find a winning HoneyJars. 1 for each item in the bundle
    /// @notice Should only be called when the last honeyJars is minted.
    function _fermentJars(uint8 bundleId_) internal {
        SlumberParty storage party = slumberParties[bundleId_];
        uint32 numWords = 1;
        ++party.checkpointIndex;

        // When the index is the length of the checkpoints array, you've overflowed and you ferment remaining jars
        if (party.checkpointIndex == party.checkpoints.length) {
            uint256 numSleepers = slumberParties[bundleId_].sleepoors.length;
            uint256 numFermented = slumberParties[bundleId_].fermentedJars.length;
            numWords = SafeCastLib.safeCastTo32(numSleepers - numFermented);
        }

        uint256 requestId = vrfCoordinator.requestRandomWords(
            vrfConfig.keyHash, vrfConfig.subId, vrfConfig.minConfirmations, vrfConfig.callbackGasLimit, numWords
        );
        rng[requestId] = bundleId_;
    }

    /// @notice the callback method that is called when VRF completes
    /// @param requestId requestId that is generated when initially calling VRF
    /// @param randomness an array of random numbers based on `numWords` config
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomness) internal override {
        /// use requestID to get bundleId
        uint8 bundleId = rng[requestId];
        _setFermentedJars(bundleId, randomness);
    }

    /// @notice sets the winners of each NFT
    /// @param bundleId self-explanatory
    /// @param randomNumbers array of randomNumbers returned by chainlink VRF
    function _setFermentedJars(uint8 bundleId, uint256[] memory randomNumbers) internal {
        SlumberParty storage party = slumberParties[bundleId];

        uint256[] memory honeyJarIds = honeyJarShelf[bundleId];
        uint256 numHoneyJars = honeyJarShelf[bundleId].length;
        uint256 numFermentedJars = randomNumbers.length;
        // In the event more numbers were requested than number of sleepoors.
        if (numFermentedJars + party.fermentedJars.length > party.sleepoors.length) {
            numFermentedJars = party.sleepoors.length - party.fermentedJars.length;
        }
        uint256[] memory fermentedJars = new uint256[](numFermentedJars);

        uint256 fermentedIndex;
        for (uint256 i = 0; i < numFermentedJars; i++) {
            fermentedIndex = randomNumbers[i] % numHoneyJars;
            fermentedJars[i] = honeyJarIds[fermentedIndex];
            party.fermentedJars.push(FermentedJar(honeyJarIds[fermentedIndex], false));
        }
        party.fermentedJarsFound = true;

        emit FermentedJarsFound(bundleId, fermentedJars);
    }

    /// @notice method that _anyone_ can call to send fermented jars across to the asset chain
    /// @dev no permissions since its an idempotent state xfer.
    /// @dev estimated gas round 279628 - 376242
    function sendFermentedJars(uint8 bundleId_) external payable {
        SlumberParty storage party = slumberParties[bundleId_];
        if (party.fermentedJars.length == 0) revert FermentedJarNotFound(bundleId_);
        if (party.assetChainId == getChainId()) revert InvalidInput("chainId");
        if (address(honeyJarPortal) == address(0)) revert InvalidInput("PortalNotSet");
        uint256[] memory jarIds = new uint256[](party.fermentedJars.length);

        for (uint256 i = 0; i < party.fermentedJars.length; ++i) {
            jarIds[i] = party.fermentedJars[i].id;
        }

        honeyJarPortal.sendFermentedJars{value: msg.value}(
            payable(msg.sender), party.assetChainId, party.bundleId, jarIds
        );
    }

    /// @notice called by portal when the fermented jars are found on another chain
    /// @dev should only be called by PORTAL since this changes who is the winner
    function setCrossChainFermentedJars(uint8 bundleId, uint256[] calldata fermentedJarIds)
        external
        override
        onlyRole(Constants.PORTAL)
    {
        if (fermentedJarIds.length == 0) revert InvalidInput("setCrossChainFermentedJars");
        SlumberParty storage party = slumberParties[bundleId];
        party.fermentedJarsFound = true;
        uint256 alreadySaved = party.fermentedJars.length;
        // Only additive updates
        // Don't resave existing jars, because it has internal `isUsed` state.
        for (uint256 i = alreadySaved; i < fermentedJarIds.length; ++i) {
            party.fermentedJars.push(FermentedJar(fermentedJarIds[i], false));
        }

        emit FermentedJarsFound(bundleId, fermentedJarIds);
    }

    /// @notice transfers sleeping NFT to msg.sender if they hold the special honeyJar
    /// @dev The index in which the jarId is stored within party.fermentedJars will be the index of the NFT that will be claimed for party.sleepoors
    function wakeSleeper(uint8 bundleId_, uint256 jarId) external nonReentrant {
        // Validate that the caller of the method holds the honeyjar
        if (beraPunk.ownerOf(jarId) != msg.sender) {
            revert NotJarOwner();
        }

        SlumberParty storage party = slumberParties[bundleId_];
        if (party.assetChainId != getChainId()) revert InvalidChain(party.assetChainId, getChainId()); // Can only claim on chains with the asset
        if (party.numUsed == party.sleepoors.length) revert PartyAlreadyWoke(bundleId_);
        if (!party.fermentedJarsFound) revert FermentedJarNotFound(bundleId_);

        FermentedJar[] storage fermentedJars = party.fermentedJars;

        uint256 numFermentedJars = fermentedJars.length;
        uint256 sleeperIndex = 0;
        for (uint256 i = 0; i < numFermentedJars; ++i) {
            if (fermentedJars[i].id != jarId) continue;
            if (fermentedJars[i].isUsed) continue; // Same jar can win multiple times.
            // The caller is the owner of the Fermented jar and its unused
            fermentedJars[i].isUsed = true;
            sleeperIndex = party.numUsed; // Use the next available sleeper
            party.numUsed++;

            // party.numUsed is the index of the sleeper to wake up
            _transferSleeper(party.sleepoors[sleeperIndex], address(this), msg.sender);
            emit SleeperAwoke(bundleId_, party.sleepoors[i].tokenId, jarId, msg.sender);
            // Early return out of loop if successful
            return;
        }

        // If you complete the for loop without returning then you don't own the right NFT
        revert NotFermentedJarOwner(bundleId_, jarId);
    }

    /// @notice transfers NFT defined by sleeper_ to the caller of of the method
    function _transferSleeper(SleepingNFT memory sleeper_, address from, address to) internal {
        if (sleeper_.isERC1155) {
            // ERC1155
            IERC1155(sleeper_.tokenAddress).safeTransferFrom(from, to, sleeper_.tokenId, 1, "");
        } else {
            //  ERC721
            IERC721(sleeper_.tokenAddress).safeTransferFrom(from, to, sleeper_.tokenId);
        }
    }

    /**
     * BearPouch owner methods
     *      Can move into another contract for portability
     * depends on:
     *     Exclusive: beekeeper, jani, honeyJarShare
     *     shared: paymentToken
     */

    /// @param amountERC20 is zero if we're only distributing the ETH
    function _distribute(uint256 amountERC20) internal {
        if (amountERC20 != 0) {
            paymentToken.safeTransferFrom(msg.sender, paymaster, amountERC20);
        }

        if (msg.value != 0) {
            SafeTransferLib.safeTransferETH(paymaster, msg.value);
        }
    }

    /**
     * Gatekeeper: for claiming free honeyJar
     * BearCave:
     *    - maxMintableHoneyJar per bundle
     *    - claimedHoneyJar per bundle // free
     *    - maxClaimableHoneyJar per bundle
     * Gatekeeper: (per bear)
     * Gates:
     *    - maxhoneyJarAvailable per gate
     *    - maxClaimable per gate
     *
     */

    /// @notice Allows a player to claim free HoneyJar based on eligibility (FCFS)
    /// @dev free claims are determined by the gatekeeper and the accounting is done in this method
    /// @param gateId id of gate from Gatekeeper.
    /// @param amount amount player is claiming
    /// @param proof valid proof that entitles msg.sender to amount.
    function claim(uint8 bundleId_, uint32 gateId, uint32 amount, bytes32[] calldata proof) public nonReentrant {
        // Gatekeeper tracks per-player/per-gate claims
        uint32 numClaim = gatekeeper.calculateClaimable(bundleId_, gateId, msg.sender, amount, proof);
        if (numClaim == 0) {
            return;
        }

        // Track per bear freeClaims
        uint32 claimedAmount = claimed[bundleId_];
        if (numClaim + claimedAmount > mintConfig.maxClaimableHoneyJar) {
            numClaim = mintConfig.maxClaimableHoneyJar - claimedAmount;
        }
        // Check if the HoneyJars can be minted
        _canMintHoneyJar(bundleId_, numClaim); // Validating here because numClaims can change

        // Update the amount minted.
        claimed[bundleId_] += numClaim;

        // Can be combined with calculateClaimable call above, but keeping separate to separate view + modification on gatekeeper
        gatekeeper.addClaimed(bundleId_, gateId, numClaim, proof);

        // If for some reason this fails, GG no honeyJar for you
        _mintHoneyJarForBear(msg.sender, bundleId_, numClaim);

        emit HoneyJarClaimed(bundleId_, gateId, msg.sender, numClaim);
    }

    /// @dev Helper function to process all free cams. More client-sided computation.
    /// @param bundleId_ the bundle to claim tokens for.
    /// @param gateIds the list of gates to claim. The txn will revert if an ID for an inactive gate is included.
    /// @param amounts the list of amounts being claimed for the respective gates.
    /// @param proofs the list of proofs associated with the respective gates
    function claimAll(
        uint8 bundleId_,
        uint32[] calldata gateIds,
        uint32[] calldata amounts,
        bytes32[][] calldata proofs
    ) external {
        uint256 inputLength = proofs.length;
        if (inputLength != gateIds.length) revert InvalidInput("claimAll");
        if (inputLength != amounts.length) revert InvalidInput("claimAll");

        for (uint256 i = 0; i < inputLength; ++i) {
            claim(bundleId_, gateIds[i], amounts[i], proofs[i]);
        }
    }

    //=============== Admin Methods ================//

    /// @notice admin function to mint a specified amount of THJ.
    /// @dev the value is set on initialization.
    function adminMint(uint8 bundleId_, uint256 amount_) external onlyRole(Constants.GAME_ADMIN) {
        if (adminMintAmount == 0) revert MekingTooManyHoneyJars(bundleId_);

        if (amount_ > adminMintAmount) {
            amount_ = adminMintAmount;
        }
        adminMintAmount -= amount_;

        _canMintHoneyJar(bundleId_, amount_);

        _mintHoneyJarForBear(msg.sender, bundleId_, amount_);
    }

    /// @notice sets HoneyJarPortal which is responsible for xChain communication.
    /// @dev intentionally allow 0x0 to disable automatic xChain comms
    function setPortal(address portal_) external onlyRole(Constants.GAME_ADMIN) {
        honeyJarPortal = IHoneyJarPortal(portal_);

        emit PortalSet(portal_);
    }

    /**
     * Game setters
     *  These should not be called while a game is in progress to prevent hostage holding.
     */

    /// @notice sets the number of global free claims available
    function setMaxClaimableHoneyJar(uint32 _maxClaimableHoneyJar) external onlyRole(Constants.GAME_ADMIN) {
        if (_isEnabled(address(this))) revert GameInProgress();
        mintConfig.maxClaimableHoneyJar = _maxClaimableHoneyJar;

        emit MintConfigChanged(mintConfig);
    }

    /// @notice sets the price of the honeyJar in `paymentToken`
    function setHoneyJarPrice_ERC20(uint256 _honeyJarPrice) external onlyRole(Constants.GAME_ADMIN) {
        if (_isEnabled(address(this))) revert GameInProgress();
        mintConfig.honeyJarPrice_ERC20 = _honeyJarPrice;

        emit MintConfigChanged(mintConfig);
    }

    /// @notice sets the price of the honeyJar in `ETH`
    function setHoneyJarPrice_ETH(uint256 _honeyJarPrice) external onlyRole(Constants.GAME_ADMIN) {
        if (_isEnabled(address(this))) revert GameInProgress();
        mintConfig.honeyJarPrice_ETH = _honeyJarPrice;

        emit MintConfigChanged(mintConfig);
    }

    /// @notice checkpoints where there can be one winner.
    /// @param checkpoints the JarNumber that determines winners.
    /// @param checkpointIndex where in the checkpoint array the current game is in
    function setCheckpoints(uint8 bundleId_, uint256 checkpointIndex, uint256[] calldata checkpoints)
        external
        onlyRole(Constants.GAME_ADMIN)
    {
        if (_isEnabled(address(this))) revert GameInProgress();
        if (checkpointIndex >= checkpoints.length) revert InvalidInput("setCheckpoints");

        SlumberParty storage party = slumberParties[bundleId_];
        if (party.sleepoors.length == 0) revert InvalidBundle(bundleId_);

        party.checkpoints = checkpoints;
        party.checkpointIndex = checkpointIndex;

        emit CheckpointsUpdated(checkpointIndex, checkpoints);
    }

    /**
     * Chainlink Setters
     */

    /// @notice Set from the following docs: https://docs.chain.link/docs/vrf-contracts/#configurations
    function setVRFConfig(VRFConfig calldata vrfConfig_) external onlyRole(Constants.GAME_ADMIN) {
        vrfConfig = vrfConfig_;
        emit VRFConfigChanged(vrfConfig_);
    }

    // Needed for LayerZero Refunds
    receive() external payable {}
}