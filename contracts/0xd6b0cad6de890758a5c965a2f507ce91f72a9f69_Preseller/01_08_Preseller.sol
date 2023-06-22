// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { INexusGaming } from "./interface/INexusGaming.sol";

/**
 * <<< nexus-gaming.io >>>
 *
 * @title   Nexus Gaming Preseller
 * @notice  Prepurchase and claim Nexus Gaming NFTs
 * @dev     The preseller must be authorized to mint the NFTs
 * @author  Tuxedo Development
 * @custom:developer BowTiedPickle
 * @custom:developer Lumoswiz
 * @custom:developer BowTiedOriole
 */
contract Preseller is Ownable {
    // ----- Structs -----

    /**
     * @notice  The mint info for a given mint id
     * @dev     Price array must be of length 5
     * @param   startTime       The start time of the presale
     * @param   endTime         The end time of the presale
     * @param   claimTime       The time when the presale NFTs can be claimed
     * @param   merkleRoot      The merkle root of the presale allocations
     * @param   maxPurchased    The max amount of NFTs that can be purchased during this mint id
     * @param   totalPurchased  The total amount of NFTs that have been purchased during this mint id
     * @param   prices          The price of each level in units of USDC
     */
    struct MintInfo {
        uint48 startTime;
        uint48 endTime;
        uint48 claimTime;
        bytes32 merkleRoot;
        uint256 maxPurchased;
        uint256 totalPurchased;
        uint256[] prices;
    }

    // ----- Storage -----

    /// @notice The Nexus Gaming NFT contract
    INexusGaming public immutable nft;

    /// @notice The next mint id
    uint256 public nextMintId;

    /// @notice The mint info for each mint id
    mapping(uint256 => MintInfo) public mintInfos;

    /// @notice The number of Nexus Gaming NFTs of each tier purchased by each user for each mint id
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public numberPurchased;

    /// @notice The USDC token contract
    IERC20 public immutable usdc;

    uint256 internal constant TRANCHE_COUNT = 5;

    // ----- Constructor -----

    /**
     * @notice  Construct a new Preseller contract
     * @param   _owner  The owner of the contract
     * @param   _nft    The Nexus Gaming NFT contract
     * @param   _usdc   The USDC token contract
     */
    constructor(address _owner, address _nft, address _usdc) {
        if (_owner == address(0) || _nft == address(0) || _usdc == address(0)) revert Preseller__ZeroAddressInvalid();

        _transferOwnership(_owner);

        nft = INexusGaming(_nft);
        usdc = IERC20(_usdc);
    }

    // ----- User Actions -----

    /**
     * @notice  Purchase Nexus Gaming NFTs during the presale
     * @dev     The amounts and allocations must be in the same order, and of length 5
     * @param   mintId      The mint id to purchase from
     * @param   amounts     The number of Nexus Gaming NFTs to purchase at each price level
     * @param   allocations The maximum number of Nexus Gaming NFTs that can be purchased at each price level
     * @param   proof       The merkle proof of the user's allocation
     */
    function purchasePresale(
        uint256 mintId,
        uint256[] calldata amounts,
        uint256[] calldata allocations,
        bytes32[] calldata proof
    ) external {
        MintInfo storage info = mintInfos[mintId];

        if (block.timestamp < info.startTime || block.timestamp >= info.endTime)
            revert Preseller__NotTimeForPresalePurchases();

        if (amounts.length != allocations.length) revert Preseller__ArrayLengthMismatch();
        if (amounts.length != TRANCHE_COUNT) revert Preseller__ArrayLengthInvalid();

        if (!_verifyMerkleProof(allocations, info.merkleRoot, proof)) revert Preseller__ProofInvalid();

        uint256 cost;
        uint256 amount;
        uint256[] memory cachedPrices = info.prices;
        for (uint256 i; i < TRANCHE_COUNT; ) {
            if (amounts[i] + numberPurchased[mintId][msg.sender][i] > allocations[i])
                revert Preseller__ExceedsMaxAllocation(); // The correctness of the sum of the allocations is left implicit in the whitelist

            cost += amounts[i] * cachedPrices[i];
            amount += amounts[i];
            numberPurchased[mintId][msg.sender][i] += amounts[i];

            unchecked {
                ++i;
            }
        }

        if (info.totalPurchased + amount > info.maxPurchased) revert Preseller__ExceedsMaxSupply();
        if (amount == 0) revert Preseller__ZeroAmount();

        info.totalPurchased += amount;

        if (!usdc.transferFrom(msg.sender, address(this), cost)) {
            revert Preseller__USDCTransferFailed();
        }

        emit PresalePurchase(msg.sender, amount);
    }

    /**
     * @notice  Claim Nexus Gaming NFTs after the presale
     * @param   user    The user to claim for
     * @param   mintId  The mint id to claim from
     */
    function claimPresale(address user, uint256 mintId) external {
        _claimPresale(user, mintId);
    }

    /**
     * @notice  Claim Nexus Gaming NFTs after the presale for multiple users and/or mint ids
     * @param   users   The users to claim for
     * @param   mintIds The mint ids to claim from
     */
    function claimPresaleBatch(address[] calldata users, uint256[] calldata mintIds) external {
        if (users.length != mintIds.length) revert Preseller__ArrayLengthMismatch();
        for (uint256 i; i < users.length; ) {
            _claimPresale(users[i], mintIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    // ----- Internal -----

    function _claimPresale(address user, uint256 mintId) internal {
        uint256 amount;
        MintInfo memory info = mintInfos[mintId];

        if (block.timestamp < info.claimTime) revert Preseller__NotTimeForClaim();

        for (uint256 i; i < TRANCHE_COUNT; ) {
            amount += numberPurchased[mintId][user][i];
            numberPurchased[mintId][user][i] = 0;
            unchecked {
                ++i;
            }
        }
        if (amount == 0) revert Preseller__ZeroAmount();

        nft.mint(user, amount);
    }

    // ----- Admin -----

    /**
     * @notice Setup a mint phase
     * @param   _startTime      The start time of the mint phase
     * @param   _endTime        The end time of the mint phase
     * @param   _claimTime      The time when the mint phase can be claimed
     * @param   _merkleRoot     The merkle root of the mint phase
     * @param   _maxPurchased   The maximum number of Nexus Gaming NFTs that can be purchased at each price level
     * @param   _prices         The price of each Nexus Gaming NFT at each price level
     */
    function setupMintPhase(
        uint48 _startTime,
        uint48 _endTime,
        uint48 _claimTime,
        bytes32 _merkleRoot,
        uint256 _maxPurchased,
        uint256[] calldata _prices
    ) external onlyOwner returns (uint256) {
        if (_startTime >= _endTime || _startTime <= block.timestamp || _claimTime <= _endTime)
            revert Preseller__MintTimesInvalid();

        if (_merkleRoot == bytes32(0)) revert Preseller__ZeroRootInvalid();
        if (_prices.length != TRANCHE_COUNT) revert Preseller__ArrayLengthInvalid();

        uint256 mintId = nextMintId;

        mintInfos[mintId] = MintInfo({
            startTime: _startTime,
            endTime: _endTime,
            claimTime: _claimTime,
            merkleRoot: _merkleRoot,
            maxPurchased: _maxPurchased,
            totalPurchased: 0,
            prices: _prices
        });

        unchecked {
            ++nextMintId;
        }

        emit NewMintPhaseCreated(mintId);
        return mintId;
    }

    /**
     * @notice  Update the price of each Nexus Gaming NFT at each price level for a mint id
     * @param   mintId  The mint id to update
     * @param   _prices The new price of each Nexus Gaming NFT at each price level
     */
    function updatePrices(uint256 mintId, uint256[] calldata _prices) external onlyOwner {
        if (mintId >= nextMintId) revert Preseller__MintIdInvalid();
        if (_prices.length != TRANCHE_COUNT) revert Preseller__ArrayLengthInvalid();

        mintInfos[mintId].prices = _prices;
        emit PricesUpdated(mintId);
    }

    /**
     * @notice  Update the start time for a mint id
     * @param   mintId      The mint id to update
     * @param   _startTime  The new start time in unix epoch seconds
     */
    function updateMintStartTime(uint256 mintId, uint48 _startTime) external onlyOwner {
        if (mintId >= nextMintId) revert Preseller__MintIdInvalid();
        if (_startTime >= mintInfos[mintId].endTime || _startTime <= block.timestamp) {
            revert Preseller__MintTimesInvalid();
        }

        emit StartTimeUpdated(mintId, _startTime, mintInfos[mintId].startTime);
        mintInfos[mintId].startTime = _startTime;
    }

    /**
     * @notice  Update the end time for a mint id
     * @param   mintId      The mint id to update
     * @param   _endTime    The new end time in unix epoch seconds
     */
    function updateMintEndTime(uint256 mintId, uint48 _endTime) external onlyOwner {
        if (mintId >= nextMintId) revert Preseller__MintIdInvalid();
        if (mintInfos[mintId].startTime >= _endTime || mintInfos[mintId].claimTime <= _endTime) {
            revert Preseller__MintTimesInvalid();
        }

        emit EndTimeUpdated(mintId, _endTime, mintInfos[mintId].endTime);
        mintInfos[mintId].endTime = _endTime;
    }

    /**
     * @notice  Update the claim time for a mint id
     * @param   mintId      The mint id to update
     * @param   _claimTime  The new claim time in unix epoch seconds
     */
    function updateMintClaimTime(uint256 mintId, uint48 _claimTime) external onlyOwner {
        if (mintId >= nextMintId) revert Preseller__MintIdInvalid();
        if (_claimTime <= mintInfos[mintId].endTime) {
            revert Preseller__MintTimesInvalid();
        }

        emit ClaimTimeUpdated(mintId, _claimTime, mintInfos[mintId].claimTime);
        mintInfos[mintId].claimTime = _claimTime;
    }

    /**
     * @notice  Update the merkle root for a mint id
     * @param   mintId      The mint id to update
     * @param   _merkleRoot The new merkle root
     */
    function updateMintMerkleRoot(uint256 mintId, bytes32 _merkleRoot) external onlyOwner {
        if (mintId >= nextMintId) revert Preseller__MintIdInvalid();

        emit MerkleRootUpdated(mintId, _merkleRoot, mintInfos[mintId].merkleRoot);
        mintInfos[mintId].merkleRoot = _merkleRoot;
    }

    /**
     * @notice  Update the max purchased for a mint id
     * @param   mintId          The mint id to update
     * @param   _maxPurchased   The new max purchased amount
     */
    function updateMintMaxPurchased(uint256 mintId, uint256 _maxPurchased) external onlyOwner {
        if (mintId >= nextMintId) revert Preseller__MintIdInvalid();
        if (_maxPurchased < mintInfos[mintId].totalPurchased) revert Preseller__MaxPurchasedInvalid();

        emit MaxPurchasedUpdated(mintId, _maxPurchased, mintInfos[mintId].maxPurchased);
        mintInfos[mintId].maxPurchased = _maxPurchased;
    }

    /**
     * @notice Withdraw the USDC balance from the contract
     */
    function withdraw() external onlyOwner {
        uint256 balance = usdc.balanceOf(address(this));
        usdc.transfer(owner(), balance);
        emit Withdrawal(balance);
    }

    // ----- Verification -----

    function _verifyMerkleProof(
        uint256[] calldata _allocations,
        bytes32 _merkleRoot,
        bytes32[] calldata _proof
    ) private view returns (bool) {
        // Use of abi.encode here instead of abi.encodePacked due to: https://github.com/ethereum/solidity/issues/11593
        bytes32 leaf = keccak256(abi.encode(msg.sender, _allocations));
        return MerkleProof.verifyCalldata(_proof, _merkleRoot, leaf);
    }

    // ----- View -----

    /**
     * @notice  Get a mint's information by ID
     */
    function getMintInfo(uint256 mintId) external view returns (MintInfo memory) {
        return mintInfos[mintId];
    }

    /**
     * @notice  Check if a mint id is active
     * @param   mintId  The mint id to check
     * @return  True if the mint id is active, false otherwise
     */
    function isMintActive(uint256 mintId) external view returns (bool) {
        MintInfo storage info = mintInfos[mintId];
        return (block.timestamp >= info.startTime) && (block.timestamp < info.endTime);
    }

    /**
     * @notice  Returns user purchases by tier for given mintId
     * @dev     Will only be accurate prior to user claiming their NFTs
     * @param   mintId  Mint id
     * @param   user    User address
     * @return  Array of user purchases by tier
     */
    function getUserPurchasesPerMintId(uint256 mintId, address user) external view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](5);
        for (uint256 i; i < TRANCHE_COUNT; ) {
            amounts[i] = numberPurchased[mintId][user][i];
            unchecked {
                ++i;
            }
        }

        return amounts;
    }

    // ----- Events -----

    event PricesUpdated(uint256 indexed mintId);

    event StartTimeUpdated(uint256 indexed mintId, uint48 startTime, uint48 oldStartTime);

    event EndTimeUpdated(uint256 indexed mintId, uint48 endTime, uint48 oldEndTime);

    event ClaimTimeUpdated(uint256 indexed mintId, uint48 claimTime, uint48 oldClaimTime);

    event MerkleRootUpdated(uint256 indexed mintId, bytes32 merkleRoot, bytes32 oldMerkleRoot);

    event MaxPurchasedUpdated(uint256 indexed mintId, uint256 supply, uint256 oldSupply);

    event NewMintPhaseCreated(uint256 indexed mintId);

    event Withdrawal(uint256 balance);

    event PresalePurchase(address indexed purchaser, uint256 indexed amount);

    // ----- Errors -----

    error Preseller__ZeroAddressInvalid();

    error Preseller__ZeroRootInvalid();

    error Preseller__ZeroAmount();

    error Preseller__ArrayLengthMismatch();

    error Preseller__ArrayLengthInvalid();

    error Preseller__ProofInvalid();

    error Preseller__MintTimesInvalid();

    error Preseller__MintIdInvalid();

    error Preseller__MaxPurchasedInvalid();

    error Preseller__USDCTransferFailed();

    error Preseller__ExceedsMaxSupply();

    error Preseller__ExceedsMaxAllocation();

    error Preseller__NotTimeForClaim();

    error Preseller__NotTimeForPresalePurchases();
}