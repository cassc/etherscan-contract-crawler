/* solhint-disable max-states-count */
/* solhint-disable ordering */
/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-unused-vars */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ReentrancyGuardUpgradeable} from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import {PausableUpgradeable} from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {MerkleProofUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol';
import {ECDSAUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import {IERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import {AddressUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import {IAtlanteans} from '../interfaces/IAtlanteans.sol';
import {IWETH} from '../interfaces/IWETH.sol';

/**
 * ▄▀█ ▀█▀ █░░ ▄▀█ █▄░█ ▀█▀ █ █▀   █░█░█ █▀█ █▀█ █░░ █▀▄
 * █▀█ ░█░ █▄▄ █▀█ █░▀█ ░█░ █ ▄█   ▀▄▀▄▀ █▄█ █▀▄ █▄▄ █▄▀
 *
 *
 * Atlantis World is building the Web3 social metaverse by connecting Web3 with social,
 * gaming and education in one lightweight virtual world that's accessible to everybody.
 *
 * @title AtlanteansSale
 * @author Carlo Miguel Dy, Rachit Anand Srivastava
 * @dev Implements the Ducth Auction for Atlanteans Collection, code is exact same from Forgotten Runes.
 */
contract AtlanteansSale is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;

    struct InitializerArgs {
        address atlanteans;
        address treasury;
        address weth;
        address server;
        uint256 mintlistStartTime;
        uint256 daStartTime;
        uint256 publicStartTime;
        uint256 publicEndTime;
        uint256 claimsStartTime;
        uint256 claimsEndTime;
        uint256 startPrice;
        uint256 lowestPrice;
        uint256 dropPerStep;
        uint256 daPriceCurveLength;
        uint256 daDropInterval;
        uint256 mintlistPrice;
        uint256 maxMintlistSupply;
        uint256 maxDaSupply;
        uint256 maxForSale;
        uint256 maxForClaim;
        uint256 maxTreasurySupply;
    }

    /// @notice The treasury address
    address public treasury;

    /// @notice The wrapped ether address
    address public weth;

    /// @notice The server address
    address public server;

    /// @notice The start timestamp for mintlisters
    /// @dev This is the start of minting. DA phase will follow after 24 hrs
    uint256 public mintlistStartTime;

    /// @notice The start timestamp for the Dutch Auction (DA) sale and price
    uint256 public daStartTime;

    /// @notice The start timestamp for the public sale
    uint256 public publicStartTime;

    /// @notice The end timestamp for the public sale
    uint256 public publicEndTime;

    /// @notice The start timestamp for the claims
    uint256 public claimsStartTime;

    /// @notice The end timestamp for the claims
    uint256 public claimsEndTime;

    /// @notice The start timestamp for self refunds,
    /// it starts after 24 hrs the issueRefunds is called
    uint256 public selfRefundsStartTime;

    /// @notice The main Merkle root
    bytes32 public mintlist1MerkleRoot;

    /// @notice The secondary Merkle root
    /// @dev Having a backup merkle root lets us atomically update the merkletree without downtime on the frontend
    bytes32 public mintlist2MerkleRoot;

    /// @notice The address of the Atlanteans contract
    address public atlanteans;

    /// @notice The start price of the DA
    uint256 public startPrice;

    /// @notice The lowest price of the DA
    uint256 public lowestPrice;

    /// @notice The price drop for each hour
    uint256 public dropPerStep;

    /// @notice The length of time for the price curve in the DA
    uint256 public daPriceCurveLength;

    /// @notice The interval of time in which the price steps down
    uint256 public daDropInterval;

    /// @notice The last price of the DA from the last minter. Will be updated everytime someone calls bidSummon
    uint256 public lastPrice;

    /// @notice The mintlist price
    uint256 public mintlistPrice;

    /// @notice An array of the addresses of the DA minters
    /// @dev An entry is created for every da minting tx, so the same minter address is quite likely to appear more than once
    address[] public daMinters;

    /// @notice Tracks the total amount paid by a given address in the DA
    mapping(address => uint256) public daAmountPaid;

    /// @notice Tracks the total amount refunded to a given address for the DA
    mapping(address => uint256) public daAmountRefunded;

    /// @notice Tracks the total count of NFTs minted by a given address in the DA
    mapping(address => uint256) public daNumMinted;

    /// @notice Tracks the total count of minted NFTs on mintlist phase
    mapping(address => uint256) public mintlistMinted;

    /**
     * @notice Tracks the remaining claimable for a Founding Atlantean during claim phase
     */
    mapping(address => uint256) public faToRemainingClaim;

    /**
     * @notice Tracks if a Founding Atlantean is registered
     */
    mapping(address => bool) public faRegistered;

    /// @notice The max supply for mintlist allocation sale
    uint256 public maxMintlistSupply;

    /// @notice Tracks the total count of NFTs sold on mintlist phase
    uint256 public numMintlistSold;

    /// @notice The total number of tokens reserved for the DA phase
    uint256 public maxDaSupply;

    /// @notice Tracks the total count of NFTs sold (vs. freebies)
    uint256 public numSold;

    /// @notice Tracks the total count of NFTs for sale
    uint256 public maxForSale;

    /// @notice Tracks the total count of NFTs claimed for free
    uint256 public numClaimed;

    /// @notice Tracks the total count of NFTs that can be claimed
    /// @dev While we will have a merkle root set for this group, putting a hard cap helps limit the damage of any problems with an overly-generous merkle tree
    uint256 public maxForClaim;

    /// @notice The total number of tokens reserved for AW treasury
    uint256 public maxTreasurySupply;

    /// @notice Tracks the total count of NFTs minted to treasury
    uint256 public numTreasuryMinted;

    /**
     * @notice Validates if given address is not empty
     */
    modifier validAddress(address _address) {
        require(_address != address(0), 'AtlanteansSale: Invalid address');
        _;
    }

    /**
     * @notice Common modifier for 2 functions mintlistSummon but with different arguments
     */
    modifier mintlistValidations(
        bytes32[] calldata _merkleProof,
        uint256 numAtlanteans,
        uint256 amount
    ) {
        require(msg.sender == tx.origin && !AddressUpgradeable.isContract(msg.sender), 'AtlanteansSale: Not EOA');

        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProofUpgradeable.verify(_merkleProof, mintlist1MerkleRoot, node) ||
                MerkleProofUpgradeable.verify(_merkleProof, mintlist2MerkleRoot, node),
            'AtlanteansSale: Invalid proof'
        );

        require(numSold < maxForSale, 'AtlanteansSale: Sold out');
        require(numMintlistSold < maxMintlistSupply, 'AtlanteansSale: Sold out for mintlist phase');
        require(mintlistStarted(), 'AtlanteansSale: Mintlist phase not started');
        require(amount == mintlistPrice * numAtlanteans, 'AtlanteansSale: Ether value incorrect');
        require(mintlistMinted[msg.sender] < 2, 'AtlanteansSale: Already minted twice');
        require(numAtlanteans < 3, 'AtlanteansSale: Can only request max of 2');
        _;
    }

    /**
     * @notice Common modifier for 2 functions bidSummon but with different arguments
     */
    modifier daValidations(uint256 numAtlanteans) {
        require(msg.sender == tx.origin && !AddressUpgradeable.isContract(msg.sender), 'AtlanteansSale: Not EOA');
        require(numSold < maxDaSupply + mintlistRemainingSupply(), 'AtlanteansSale: Auction sold out');
        require(numAtlanteans <= remainingForSale(), 'AtlanteansSale: Not enough remaining');
        require(daStarted(), 'AtlanteansSale: Auction not started');
        require(!claimsStarted(), 'AtlanteansSale: Auction phase over');
        require(
            // slither-disable-next-line reentrancy-eth,reentrancy-benign
            numAtlanteans > 0 && numAtlanteans <= IAtlanteans(atlanteans).MAX_QUANTITY_PER_TX(),
            'AtlanteansSale: You can summon no more than 19 atlanteans at a time'
        );
        _;
    }

    /**
     * @notice Common modifier for 2 functions publicSummon but with different arguments
     */
    modifier publicValidations(uint256 numAtlanteans, uint256 amount) {
        require(msg.sender == tx.origin && !AddressUpgradeable.isContract(msg.sender), 'AtlanteansSale: Not EOA');
        require(publicStarted(), 'AtlanteansSale: Public sale not started');
        require(!publicEnded(), 'AtlanteansSale: Public sale has ended');
        require(numSold < maxForSale, 'AtlanteansSale: Sold out');
        require(numSold + numAtlanteans <= maxForSale, 'AtlanteansSale: Not enough remaining');
        require(
            numAtlanteans > 0 && numAtlanteans <= IAtlanteans(atlanteans).MAX_QUANTITY_PER_TX(),
            'AtlanteansSale: You can summon no more than 19 Atlanteans at a time'
        );
        // slither-disable-next-line incorrect-equality
        require(amount == lastPrice * numAtlanteans, 'AtlanteansSale: Ether value sent is incorrect');
        _;
    }

    /**
     * @notice Emits event when someone mints during mintlist phase
     */
    event MintlistSummon(address indexed minter);

    /**
     * @notice Emits event when someone buys during DA
     */
    event BidSummon(address indexed minter, uint256 indexed numAtlanteans);

    /**
     * @notice Emits event when someone mints during public phase
     */
    event PublicSummon(address indexed minter, uint256 indexed numAtlanteans);

    /**
     * @notice Emits event when someone claims a free character
     */
    event ClaimSummon(address indexed minter, uint256 indexed numAtlanteans);

    /**
     * @notice Emits event minting via teamSummon
     */
    event TeamSummon(address indexed recipient, uint256 indexed numAtlanteans);

    /**
     * @notice Emits event when any arbitrary mint tx is called
     */
    event AtlanteanMint(address indexed to, uint256 indexed quantity);

    /**
     * @notice Emits event when a new DA start time is set
     */
    event SetDaStartTime(uint256 indexed oldStartTime, uint256 indexed newStartTime);

    /**
     * @notice Emits event when a new mintlist start time is set
     */
    event SetMintlistStartTime(uint256 indexed oldStartTime, uint256 indexed newStartTime);

    /**
     * @notice Emits event when a new claims start time is set
     */
    event SetClaimsStartTime(uint256 indexed oldStartTime, uint256 indexed newStartTime);

    /**
     * @notice Emits event when phase times are set
     */
    event SetPhaseTimes(uint256 indexed newDaStartTime, uint256 indexed newMintlistStartTime, uint256 indexed newClaimsStartTime);

    /**
     * @notice Emits event when mintlist1 merkle root is set
     */
    event SetMintlist1MerkleRoot(bytes32 indexed oldMerkleRoot, bytes32 indexed newMerkleRoot);

    /**
     * @notice Emits event when mintlist2 merkle root is set
     */
    event SetMintlist2MerkleRoot(bytes32 indexed oldMerkleRoot, bytes32 indexed newMerkleRoot);

    /**
     * @notice Emits event when a new treasury is set
     */
    event SetTreasury(address indexed oldTreasury, address indexed newTreasury);

    /**
     * @notice Emits event when a new address for Atlanteans ERC721A is set
     */
    event SetAtlanteans(address indexed oldAtlanteans, address indexed newAtlanteans);

    /**
     * @notice Emits event when a new weth address is set
     */
    event SetWeth(address indexed oldWeth, address indexed newWeth);

    /**
     * @notice Emits event when a new server address is set
     */
    event SetServer(address indexed oldServer, address indexed newServer);

    fallback() external payable {}

    receive() external payable {}

    /**
     * @dev Create the contract and set the initial baseURI
     * @param _initializerArgs The initializer args.
     */
    function initialize(InitializerArgs calldata _initializerArgs) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        atlanteans = _initializerArgs.atlanteans;
        treasury = _initializerArgs.treasury;
        weth = _initializerArgs.weth;
        server = _initializerArgs.server;

        mintlistStartTime = _initializerArgs.mintlistStartTime;
        daStartTime = _initializerArgs.daStartTime;
        publicStartTime = _initializerArgs.publicStartTime;
        publicEndTime = _initializerArgs.publicEndTime;
        claimsStartTime = _initializerArgs.claimsStartTime;
        claimsEndTime = _initializerArgs.claimsEndTime;

        // initial val, but will be updated for every mint during auction phase
        lastPrice = _initializerArgs.startPrice;

        startPrice = _initializerArgs.startPrice;
        lowestPrice = _initializerArgs.lowestPrice;
        dropPerStep = _initializerArgs.dropPerStep;
        daPriceCurveLength = _initializerArgs.daPriceCurveLength;
        daDropInterval = _initializerArgs.daDropInterval;
        mintlistPrice = _initializerArgs.mintlistPrice;

        maxMintlistSupply = _initializerArgs.maxMintlistSupply;
        maxDaSupply = _initializerArgs.maxDaSupply;
        maxForSale = _initializerArgs.maxForSale;
        maxForClaim = _initializerArgs.maxForClaim;
        maxTreasurySupply = _initializerArgs.maxTreasurySupply;

        selfRefundsStartTime = type(uint256).max;
    }

    /*
     * Timeline:
     *
     * mintlistSummon  : |------------|
     * bidSummon       :              |------------|
     * publicSummon    :                           |------------|
     * claimSummon     :                           |------------|------------------------|
     * teamSummon      : |---------------------------------------------------------------|
     */

    /**
     * @notice Mint an Atlantean in the mintlist phase (paid)
     * @param _merkleProof bytes32[] your proof of being able to mint
     */
    function mintlistSummon(
        bytes32[] calldata _merkleProof,
        uint256 numAtlanteans
    ) external payable nonReentrant whenNotPaused mintlistValidations(_merkleProof, numAtlanteans, msg.value) {
        _mintlistMint(numAtlanteans);
    }

    /**
     * @notice Mint an Atlantean in the mintlist phase (paid)
     * @param _merkleProof bytes32[] your proof of being able to mint
     * @param amount uint256 of the wrapped ether amount sent by caller
     */
    function mintlistSummon(
        bytes32[] calldata _merkleProof,
        uint256 numAtlanteans,
        uint256 amount
    ) external payable nonReentrant whenNotPaused mintlistValidations(_merkleProof, numAtlanteans, amount) {
        _sendWethPayment(mintlistPrice * numAtlanteans);
        _mintlistMint(numAtlanteans);
    }

    /**
     * @notice Mint an Atlantean in the Dutch Auction phase
     * @param numAtlanteans uint256 of the number of atlanteans you're trying to mint
     */
    function bidSummon(uint256 numAtlanteans) external payable nonReentrant whenNotPaused daValidations(numAtlanteans) {
        uint256 bidPrice = _bidPrice(numAtlanteans);
        require(msg.value == bidPrice, 'AtlanteansSale: Ether value incorrect');

        _daMint(numAtlanteans);
    }

    /**
     * @notice Mint an Atlantean in the Dutch Auction phase
     * @param numAtlanteans uint256 of the number of atlanteans you're trying to mint
     * @param amount uint256 of the wrapped ether amount sent by caller
     */
    function bidSummon(uint256 numAtlanteans, uint256 amount) external payable nonReentrant whenNotPaused daValidations(numAtlanteans) {
        uint256 bidPrice = _bidPrice(numAtlanteans);
        require(amount == bidPrice, 'AtlanteansSale: Ether value incorrect');

        _sendWethPayment(bidPrice);
        _daMint(numAtlanteans);
    }

    /**
     * @notice Mint an Atlantean in the Public phase (paid)
     * @param numAtlanteans uint256 of the number of atlanteans you're trying to mint
     */
    function publicSummon(uint256 numAtlanteans) external payable nonReentrant whenNotPaused publicValidations(numAtlanteans, msg.value) {
        _publicMint(numAtlanteans);
    }

    /**
     * @notice Mint an Atlantean in the Public phase (paid)
     * @param numAtlanteans uint256 of the number of atlanteans you're trying to mint
     * @param amount uint256 of the wrapped ether amount sent by caller
     */
    function publicSummon(
        uint256 numAtlanteans,
        uint256 amount
    ) external payable nonReentrant whenNotPaused publicValidations(numAtlanteans, amount) {
        _sendWethPayment(lastPrice * numAtlanteans);
        _publicMint(numAtlanteans);
    }

    /**
     * @dev claim a free Atlantean(s) if wallet is part of snapshot
     * @param signature bytes server side generated signature
     * @param scrollsAmount uint256 can be fetched from server side
     * @param numAtlanteans uint256 the amount to be minted during claiming
     */
    function claimSummon(bytes calldata signature, uint256 scrollsAmount, uint256 numAtlanteans) external nonReentrant whenNotPaused {
        require(claimsStarted(), 'AtlanteansSale: Claim phase not started');
        require(numClaimed < maxForClaim, 'AtlanteansSale: No more claims');

        bytes32 hash = keccak256(
            abi.encodePacked(
                msg.sender,
                scrollsAmount,
                numAtlanteans,
                !faRegistered[msg.sender] ? scrollsAmount : faToRemainingClaim[msg.sender]
            )
        );
        require(hash.toEthSignedMessageHash().recover(signature) == server, 'AtlanteansSale: Invalid signature.');

        if (!faRegistered[msg.sender]) {
            faRegistered[msg.sender] = true;
            faToRemainingClaim[msg.sender] = scrollsAmount;
        }

        require(faRegistered[msg.sender] && faToRemainingClaim[msg.sender] >= numAtlanteans, 'AtlanteansSale: Not enough remaining for claim.');

        numClaimed += numAtlanteans;
        faToRemainingClaim[msg.sender] -= numAtlanteans;
        _mint(msg.sender, numAtlanteans);

        emit ClaimSummon(msg.sender, numAtlanteans);
    }

    /**
     * @notice Mint an Atlantean (owner only)
     * @param recipient address the address of the recipient
     * @param numAtlanteans uint256 of the number of atlanteans you're trying to mint
     */
    function teamSummon(address recipient, uint256 numAtlanteans) external onlyOwner {
        require(address(recipient) != address(0), 'AtlanteansSale: Address req');

        _mint(recipient, numAtlanteans);
        emit TeamSummon(recipient, numAtlanteans);
    }

    function _mint(address to, uint256 quantity) private {
        // slither-disable-next-line reentrancy-eth,reentrancy-no-eth,reentrancy-benign,reentrancy-events
        IAtlanteans(atlanteans).mintTo(to, quantity);
        emit AtlanteanMint(to, quantity);
    }

    /**
     * @notice Minting relevant for mintlist phase
     */
    function _mintlistMint(uint256 numAtlanteans) private {
        mintlistMinted[msg.sender] += numAtlanteans;
        numMintlistSold += numAtlanteans;
        numSold += numAtlanteans;

        _mint(msg.sender, numAtlanteans);
        emit MintlistSummon(msg.sender);
    }

    /**
     * @notice Minting relevant for auction phase
     * @param numAtlanteans uint256 The quantity of tokens to be minted
     */
    function _daMint(uint256 numAtlanteans) private {
        daMinters.push(msg.sender);
        daAmountPaid[msg.sender] += msg.value;
        daNumMinted[msg.sender] += numAtlanteans;
        numSold += numAtlanteans;
        lastPrice = currentDaPrice();

        _mint(msg.sender, numAtlanteans);
        emit BidSummon(msg.sender, numAtlanteans);
    }

    /**
     * @notice Minting for public phase
     * @param numAtlanteans uint256 The quantity of tokens to be minted
     */
    function _publicMint(uint256 numAtlanteans) private {
        numSold += numAtlanteans;

        _mint(msg.sender, numAtlanteans);
        emit PublicSummon(msg.sender, numAtlanteans);
    }

    /*
     * View utilities
     */

    /**
     * @notice returns the current dutch auction price
     */
    function currentDaPrice() public view returns (uint256) {
        if (!daStarted()) {
            return startPrice;
        }
        if (block.timestamp >= daStartTime + daPriceCurveLength) {
            // end of the curve
            return lowestPrice;
        }

        uint256 elapsed = block.timestamp - daStartTime;
        // slither-disable-next-line divide-before-multiply
        uint256 steps = elapsed / daDropInterval;
        uint256 stepDeduction = steps * dropPerStep;

        // don't go negative in the next step
        if (stepDeduction > startPrice) {
            return lowestPrice;
        }
        uint256 currentPrice = startPrice - stepDeduction;
        return currentPrice > lowestPrice ? currentPrice : lowestPrice;
    }

    /**
     * @notice returns whether the mintlist has started
     */
    function mintlistStarted() public view returns (bool) {
        return block.timestamp > mintlistStartTime;
    }

    /**
     * @notice returns whether the dutch auction has started
     */
    function daStarted() public view returns (bool) {
        return block.timestamp > daStartTime;
    }

    /**
     * @notice returns whether the public mint has started
     */
    function publicStarted() public view returns (bool) {
        return block.timestamp > publicStartTime;
    }

    /**
     * @notice returns whether the public phase has end
     */
    function publicEnded() public view returns (bool) {
        return block.timestamp > publicEndTime;
    }

    /**
     * @notice returns whether the claims phase has started
     */
    function claimsStarted() public view returns (bool) {
        return block.timestamp > claimsStartTime;
    }

    /**
     * @notice returns whether the claims phase has end
     */
    function claimsEnded() public view returns (bool) {
        return block.timestamp > claimsEndTime;
    }

    /**
     * @notice returns whether self refunds phase has started
     */
    function selfRefundsStarted() public view returns (bool) {
        return block.timestamp > selfRefundsStartTime;
    }

    /**
     * @notice returns the number of minter addresses in the DA phase (includes duplicates)
     */
    function numDaMinters() public view returns (uint256) {
        return daMinters.length;
    }

    /**
     * @dev util function, getting the bid price
     * @param numAtlanteans uint256 The quantity of tokens to be minted
     */
    function _bidPrice(uint256 numAtlanteans) private view returns (uint256) {
        uint256 daPrice = currentDaPrice();
        return (daPrice * numAtlanteans);
    }

    /**
     * @notice returns the mintlist remaining supply
     */
    function mintlistRemainingSupply() public view returns (uint256) {
        return maxMintlistSupply - numMintlistSold;
    }

    /**
     * @notice returns the auction remaining supply
     */
    function remainingForSale() public view returns (uint256) {
        return maxForSale - numSold;
    }

    /*
     * Only the owner can do these things
     */

    /**
     * @notice pause the contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice unpause the contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice set the dutch auction start timestamp
     */
    function setDaStartTime(uint256 _newTime) external onlyOwner {
        emit SetDaStartTime(daStartTime, _newTime);
        daStartTime = _newTime;
    }

    /**
     * @notice set the mintlist start timestamp
     */
    function setMintlistStartTime(uint256 _newTime) external onlyOwner {
        emit SetMintlistStartTime(mintlistStartTime, _newTime);
        mintlistStartTime = _newTime;
    }

    /**
     * @notice set the claims phase start timestamp
     */
    function setClaimsStartTime(uint256 _newTime) external onlyOwner {
        emit SetClaimsStartTime(claimsStartTime, _newTime);
        claimsStartTime = _newTime;
    }

    /**
     * @notice A convenient way to set all phase times at once
     * @param newDaStartTime uint256 the dutch auction start time
     * @param newMintlistStartTime uint256 the mintlst phase start time
     * @param newPublicStartTime uint256 the public phase start time
     * @param newPublicEndTime uint256 the public phase end time
     * @param newClaimsStartTime uint256 the claims phase start time
     * @param newClaimsEndTime uint256 the claims phase end time
     */
    function setPhaseTimes(
        uint256 newDaStartTime,
        uint256 newMintlistStartTime,
        uint256 newPublicStartTime,
        uint256 newPublicEndTime,
        uint256 newClaimsStartTime,
        uint256 newClaimsEndTime
    ) external onlyOwner {
        // we put these checks here instead of in the setters themselves
        // because they're just guardrails of the typical case
        require(newDaStartTime >= newMintlistStartTime, 'AtlanteansSale: Set auction after mintlist');
        require(newClaimsStartTime >= newDaStartTime, 'AtlanteansSale: Set claims after auction');
        require(newClaimsEndTime > newClaimsStartTime, 'AtlanteansSale: The claims end time must be greater than claims start time');

        daStartTime = newDaStartTime;
        mintlistStartTime = newMintlistStartTime;
        publicStartTime = newPublicStartTime;
        publicEndTime = newPublicEndTime;
        claimsStartTime = newClaimsStartTime;
        claimsEndTime = newClaimsEndTime;

        emit SetPhaseTimes(newDaStartTime, newMintlistStartTime, newClaimsStartTime);
    }

    /**
     * @notice set the merkle root for the mintlist phase
     */
    function setMintlist1MerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        emit SetMintlist1MerkleRoot(mintlist1MerkleRoot, newMerkleRoot);
        mintlist1MerkleRoot = newMerkleRoot;
    }

    /**
     * @notice set the alternate merkle root for the mintlist phase
     * @dev we have two because it lets us idempotently update the website without downtime
     */
    function setMintlist2MerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        emit SetMintlist2MerkleRoot(mintlist2MerkleRoot, newMerkleRoot);
        mintlist2MerkleRoot = newMerkleRoot;
    }

    /**
     * @notice set the vault address where the funds are withdrawn
     */
    function setTreasury(address _treasury) external onlyOwner validAddress(_treasury) {
        emit SetTreasury(treasury, _treasury);
        treasury = _treasury;
    }

    /**
     * @notice set the atlanteans token address
     */
    function setAtlanteans(address _atlanteans) external onlyOwner validAddress(_atlanteans) {
        emit SetAtlanteans(atlanteans, _atlanteans);
        atlanteans = _atlanteans;
    }

    /**
     * @notice set the wrapped ether address
     */
    function setWeth(address _weth) external onlyOwner validAddress(_weth) {
        emit SetWeth(weth, _weth);
        weth = _weth;
    }

    /**
     * @notice set the server address
     */
    function setServer(address _server) external onlyOwner validAddress(_server) {
        emit SetServer(server, _server);
        server = _server;
    }

    /**
     * @notice Sends payment to treasury and returns excess amount back to caller.
     * @param price The current auction price or final price.
     */
    function _sendWethPayment(uint256 price) private {
        // slither-disable-next-line unchecked-transfer,reentrancy-events
        IWETH(weth).transferFrom(msg.sender, address(this), price);
    }

    /*
     * Refund logic
     */

    /**
     * @notice issues refunds for the accounts in minters between startIdx and endIdx inclusive
     * @param startIdx uint256 the starting index of daMinters
     * @param endIdx uint256 the ending index of daMinters, inclusive
     */
    function issueRefunds(uint256 startIdx, uint256 endIdx) public onlyOwner nonReentrant {
        selfRefundsStartTime = block.timestamp + 24 hours;
        for (uint256 i = startIdx; i < endIdx + 1; i++) {
            _refundAddress(daMinters[i]);
        }
    }

    /**
     * @notice issues a refund for the address
     * @param minter address the address to refund
     */
    function refundAddress(address minter) public onlyOwner nonReentrant {
        _refundAddress(minter);
    }

    /**
     * @notice refunds msg.sender what they're owed
     */
    function selfRefund() public nonReentrant {
        require(selfRefundsStarted(), 'Self refund period not started');
        _refundAddress(msg.sender);
    }

    function _refundAddress(address minter) private {
        uint256 owed = refundOwed(minter);

        if (owed > 0) {
            daAmountRefunded[minter] += owed;
            _safeTransferETH(minter, owed);
        }
    }

    /**
     * @notice returns the amount owed the address
     * @param minter address the address of the account that wants a refund
     */
    function refundOwed(address minter) public view returns (uint256) {
        uint256 totalCostOfMints = lastPrice * daNumMinted[minter];
        uint256 refundsPaidAlready = daAmountRefunded[minter];
        return daAmountPaid[minter] - totalCostOfMints - refundsPaidAlready;
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     * @param to account who to send the ETH to
     * @param value uint256 how much ETH to send
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }

    /**
     * @notice Withdraws all funds out to treasury
     */
    function withdrawAll() external onlyOwner returns (bool, bool) {
        (bool success, ) = payable(treasury).call{value: address(this).balance, gas: 30_000}(new bytes(0));
        bool successERC20 = IWETH(weth).transfer(treasury, IWETH(weth).balanceOf(address(this)));

        return (success, successERC20);
    }

    /// @notice To update mint price
    function updateMintPrice(uint256 newPrice) external onlyOwner {
        mintlistPrice = newPrice;
    }

    /// @notice To change DA lowest price
    function daConfig(uint256 _startPrice, uint256 _lowestAmount, uint256 size) external onlyOwner {
        startPrice = _startPrice;
        lowestPrice = _lowestAmount;
        dropPerStep = size;
    }
}