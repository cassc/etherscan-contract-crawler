// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {IERC2981Upgradeable, ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {IERC721AUpgradeable, ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {ERC4907AUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC4907AUpgradeable.sol";
import {ERC721AQueryableUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import {ERC721ABurnableUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "./interfaces/IDelegationRegistry.sol";
import "./interfaces/IChompiesV2.sol";

/**
 * @title Chompies
 * @notice Chompies are here to redefine the web3 gaming experience!
 * ALREADY PLAYABLE/FREE MOBILE GAME Paratoother 🦷🪂
 * @author @chompies_nft
 */
contract ChompiesV2 is
    ERC721AQueryableUpgradeable,
    ERC721ABurnableUpgradeable,
    ERC2981Upgradeable,
    ERC4907AUpgradeable,
    OperatorFilterer,
    OwnableUpgradeable,
    IChompiesV2
{
    using StringsUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;

    /// @notice Base uri
    string public baseURI;

    /// @dev Treasury
    address public treasury;

    /// @notice Public mint
    bool public isPublicOpen;

    /// @notice Maximum supply for the collection
    uint256 public maxSupply;

    /// @dev The max per wallet (n-1)
    uint256 public maxPerWallet;

    /// @notice ETH mint price
    uint256 public ethPrice;

    /// @notice OG FRG mint price (min)
    FRGPricing public frgPrices;

    /// @notice Live timestamp
    uint256 public liveAt;

    /// @notice Expires timestamp
    uint256 public expiresAt;

    /// @notice The FRG contract address
    address public frgContractAddress;

    /// @notice OG merkle
    bytes32 ogMerkleRoot;

    /// @notice Molar merkle
    bytes32 molarMerkleRoot;

    /// @notice Operator filter toggle switch
    bool private operatorFilteringEnabled;

    /// @notice An address mapping mints
    mapping(address => uint256) public addressToMinted;

    /// @notice The base stake configuration to use on stake
    uint256 private baseStakeConfigId;

    /// @notice Delegation registry
    address public delegationRegistryAddress;

    /// @notice ERC20 Reward address
    address public erc20RewardsAddress;

    /// @notice Track the deposit and claim state of tokens
    mapping(uint256 => StakedToken) public staked;

    /// @notice Set configurations for staking rewards
    mapping(uint256 => StakeConfiguration) public configuration;

    /// @notice Store valid reward configuration ids
    mapping(uint256 => bool) public validConfigurations;

    /// @notice Store 1/1 token ids for rewards reference
    mapping(uint256 => bool) public oneOfOneLookup;

    /// @notice Store honorary token ids for rewards reference
    mapping(uint256 => bool) public honoraryLookup;

    modifier withinThreshold(uint256 _amount) {
        require(totalSupply() + _amount < maxSupply, "!supply");
        require(
            addressToMinted[_msgSenderERC721A()] + _amount < maxPerWallet,
            "!able"
        );
        _;
    }

    modifier isWhitelisted(bytes32 _merkleRoot, bytes32[] calldata _proof) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSenderERC721A()));
        require(
            MerkleProofUpgradeable.verify(_proof, _merkleRoot, leaf),
            "!valid"
        );
        _;
    }

    modifier isDelegate(address vault) {
        bool isDelegateValid = IDelegationRegistry(delegationRegistryAddress)
            .checkDelegateForContract(_msgSender(), vault, address(this));
        require(isDelegateValid, "Invalid delegate-vault pairing");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory baseURI_,
        address _frgContractAddress
    ) public initializer initializerERC721A {
        __ERC721A_init("Chompies", "CHOMP");
        __Ownable_init();
        __ERC2981_init();
        __ERC4907A_init();
        // Setup filter registry
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        // Setup royalties to 7% (default denominator is 10000)
        _setDefaultRoyalty(_msgSender(), 700);
        // Set metadata
        baseURI = baseURI_;
        // Set treasury
        treasury = payable(_msgSender());
        // Mint setup
        frgContractAddress = _frgContractAddress;
        maxSupply = 358; // OG basis, total max supply 1235 (n-1)
        ethPrice = 0.055 ether; // ~100 USD @ 1825
        frgPrices = FRGPricing({
            og: 625 ether, // Minimum ~$25 USD @ 0.04
            molar: 1825 ether, // Minimum ~$75,
            pub: 2500 ether // Minimum ~$100
        });
        liveAt = 1684414800;
        expiresAt = 1684544400;
        maxPerWallet = 2;
        isPublicOpen = false;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev OG mint function - Can mint with min amount of FRG or ETH
     * @param _frgAmount The amount of frg to mint with
     * @param _proof The merkle proof for whitelist check
     */
    function ogWLMint(
        uint256 _frgAmount,
        bytes32[] calldata _proof
    ) external payable withinThreshold(1) isWhitelisted(ogMerkleRoot, _proof) {
        require(isLive(), "!live");
        require(_frgAmount >= frgPrices.og || msg.value >= ethPrice, "!enough");
        _processMint(_frgAmount, 1);
    }

    /**
     * @dev Molar whitelist mint function - Can mint with min amount of FRG or ETH
     * @param _frgAmount The amount of frg to mint with
     * @param _proof The merkle proof for whitelist check
     */
    function molarWLMint(
        uint256 _frgAmount,
        bytes32[] calldata _proof
    )
        external
        payable
        withinThreshold(1)
        isWhitelisted(molarMerkleRoot, _proof)
    {
        require(isLive(), "!live");
        require(
            _frgAmount >= frgPrices.molar || msg.value >= ethPrice,
            "!enough"
        );
        _processMint(_frgAmount, 1);
    }

    /**
     * @dev Public mint function
     * @param _frgAmount The amount of frg to mint with
     * @param _amount The amount to mint
     */
    function mint(
        uint256 _frgAmount,
        uint256 _amount
    ) external payable withinThreshold(_amount) {
        require(isLive() && isPublicOpen, "!live");
        require(
            _frgAmount >= _amount * frgPrices.pub ||
                msg.value >= _amount * ethPrice,
            "!enough"
        );
        _processMint(_frgAmount, _amount);
    }

    /**
     * @dev Process minting with any FRG transfers
     * @param _frgAmount The amount of frg to mint with
     * @param _amount The amount to mint
     */
    function _processMint(uint256 _frgAmount, uint256 _amount) internal {
        address sender = _msgSenderERC721A();
        // Transfer any FRG
        if (_frgAmount > 0) {
            IERC20(frgContractAddress).transferFrom(
                sender,
                address(this),
                _frgAmount
            );
        }
        addressToMinted[sender] += _amount;
        _mint(sender, _amount);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        require(isUnlocked(tokenId), "!unlocked");
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        require(isUnlocked(tokenId), "!unlocked");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        require(isUnlocked(tokenId), "!unlocked");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        require(isUnlocked(tokenId), "!unlocked");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Stake by token id
     * @param tokenIds - token ids to stake
     */
    function stake(uint256[] calldata tokenIds) external {
        _deposit(baseStakeConfigId, tokenIds, _msgSender());
    }

    /**
     * @notice Stake by token id & config. Disallows setting stake to legacy stake config.
     * @param configId - The config id to stake
     * @param tokenIds - token ids to stake
     */
    function stakeByConfigId(
        uint256 configId,
        uint256[] calldata tokenIds
    ) external {
        _deposit(configId, tokenIds, _msgSender());
    }

    /**
     * @notice Delegate stake call
     * @param tokenIds - token ids to stake
     * @param vault - The cold wallet
     */
    function delegatedStake(
        uint256[] calldata tokenIds,
        address vault
    ) external isDelegate(vault) {
        _deposit(baseStakeConfigId, tokenIds, vault);
    }

    /**
     * @notice Delegate stake call
     * @param configId - The config id to stake
     * @param tokenIds - token ids to stake
     * @param vault - The cold wallet
     */
    function delegatedStakeByConfigId(
        uint256 configId,
        uint256[] calldata tokenIds,
        address vault
    ) external isDelegate(vault) {
        _deposit(configId, tokenIds, vault);
    }

    /**
     * @notice Unstake by token id
     * @param tokenIds - token ids to unstake
     */
    function unstake(uint256[] calldata tokenIds) external {
        _withdraw(tokenIds, _msgSender());
    }

    /**
     * @notice Delegate unstake call
     * @param tokenIds - token ids to unstake
     * @param vault - The cold wallet
     */
    function delegatedUnstake(
        uint256[] calldata tokenIds,
        address vault
    ) external isDelegate(vault) {
        _withdraw(tokenIds, vault);
    }

    /**
     * @notice Stake tokens into the contract, locking all token ids. Sets stake config id to leverage during rewards calculation.
     * @param configId - The config id
     * @param tokenIds - Array of token ids
     * @param requester - Address of depositor
     */
    function _deposit(
        uint256 configId,
        uint256[] calldata tokenIds,
        address requester
    ) internal {
        require(validConfigurations[configId], "!config");
        for (uint256 i; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            // Check token isn't already locked is owned by the `requester` (sender or delegate)
            require(isUnlocked(tokenId), "!unlocked");
            require(ownerOf(tokenId) == requester, "!owner");
            staked[tokenId].configId = uint16(configId);
            staked[tokenId].stakedAt = uint120(block.timestamp);
            // Emit event for marketplaces to track staked tokens
            emit Stake(tokenId);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Withdraw tokens from stake, unlocking all token ids
     * @param tokenIds - Array of token ids
     * @param requester - Address of withdraw requester
     */
    function _withdraw(
        uint256[] calldata tokenIds,
        address requester
    ) internal {
        // Claim pending rewards before unstaking
        _claimRewards(tokenIds, requester);
        // Process each token unstaking, also validating whether minimum lock in thresholds were hit
        StakeConfiguration storage config;
        for (uint256 i; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            // Check is owned by the `requester` (sender or delegate)
            require(ownerOf(tokenId) == requester, "!owner");
            uint120 lastStakedAt = staked[tokenId].stakedAt;
            config = configuration[staked[tokenId].configId];
            // Reset state
            delete staked[tokenId];
            // Emit event for marketplaces to track unstaked tokens
            emit Unstake(tokenId, uint256(lastStakedAt), block.timestamp);
            unchecked {
                ++i;
            }
        }
    }

    function _accruedRewards(
        uint256 tokenId,
        StakeConfiguration memory config,
        uint256 periodsTotal
    ) internal view returns (uint256) {
        uint256 next = 0;
        uint256 maxIterations = config.bonusIntervals.length;
        uint256 bonusMin = 0;
        uint256 periodsChecked = 0;
        uint256 accrued = 0;
        uint256[] memory periodEmissions = config.molar;

        // OG
        if (tokenId <= 357) {
            periodEmissions = config.og;
        } else if (oneOfOneLookup[tokenId]) {
            // 1 of 1
            periodEmissions = config.oneOfOne;
        } else if (honoraryLookup[tokenId]) {
            // Honorary
            periodEmissions = config.honorary;
        }

        do {
            bonusMin = config.bonusIntervals[next];
            // Bonus met
            if (bonusMin < periodsTotal) {
                accrued += periodEmissions[next] * (bonusMin - periodsChecked);
                periodsChecked = bonusMin;
                next += 1;
            } else {
                maxIterations = 0;
            }
        } while (next < maxIterations);

        // Add in diff from periods total of the last bonus
        if (next == 0 && periodsTotal > 0) {
            // Never hit bonus interval
            accrued += periodEmissions[next] * periodsTotal;
        } else if (periodsChecked < periodsTotal) {
            // Remaining diff
            accrued += periodEmissions[next] * (periodsTotal - periodsChecked);
        }

        return accrued;
    }

    /**
     * @notice Calculates the rewards for specific token
     * @param tokenId - token id to check against
     */
    function calculateReward(uint256 tokenId) public view returns (uint256) {
        uint120 stakedAt = staked[tokenId].stakedAt;
        require(stakedAt > 0, "!staked");

        uint256 configId = staked[tokenId].configId;
        uint120 claimedAt = staked[tokenId].claimedAt;

        StakeConfiguration storage config = configuration[configId];

        // Total accrued since stake time
        uint120 sinceDeposit = (uint120(block.timestamp) - stakedAt);
        uint256 totalPeriods = uint256(sinceDeposit) / config.periodDenominator;
        uint256 accrued = _accruedRewards(tokenId, config, totalPeriods);

        // Subtract out previous claim amounts
        if (claimedAt > stakedAt) {
            uint256 sinceClaim = claimedAt - stakedAt;
            uint256 sinceClaimPeriods = uint256(sinceClaim) /
                config.periodDenominator;
            uint256 alreadyClaimed = _accruedRewards(
                tokenId,
                config,
                sinceClaimPeriods
            );
            accrued = accrued - alreadyClaimed;
        }
        return accrued;
    }

    /**
     * @notice Calculates the rewards for specific tokens under an address
     * @param tokenIds - token ids to check against
     * @return rewards - reward totals
     */
    function calculateRewards(
        uint256[] calldata tokenIds
    ) external view returns (uint256[] memory rewards) {
        rewards = new uint256[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; ) {
            rewards[i] = calculateReward(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        return rewards;
    }

    /**
     * @notice Claim the rewards for the tokens
     * @param tokenIds - Array of token ids
     */
    function claimRewards(uint256[] calldata tokenIds) public {
        _claimRewards(tokenIds, _msgSender());
    }

    /**
     * @notice Delegate claim rewards
     * @param tokenIds - token ids to claim rewards on
     * @param vault - The cold wallet
     */
    function delegatedClaimRewards(
        uint256[] calldata tokenIds,
        address vault
    ) external isDelegate(vault) {
        _claimRewards(tokenIds, vault);
    }

    /**
     * @notice Claim the rewards for the tokens
     * @param tokenIds - Array of token ids
     * @param requester - Address for rewards
     */
    function _claimRewards(
        uint256[] calldata tokenIds,
        address requester
    ) internal {
        uint256 reward;
        for (uint256 i; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == requester, "!owner");
            unchecked {
                reward += calculateReward(tokenId);
            }
            staked[tokenId].claimedAt = uint120(block.timestamp);
            unchecked {
                ++i;
            }
        }
        if (reward > 0) {
            _safeTransferRewards(requester, reward * 1e18);
        }
    }

    /**
     * @notice Gets whether a particular token is locked from staking
     * @param tokenId - token id to check
     * @return bool
     */
    function isUnlocked(uint256 tokenId) public view returns (bool) {
        return staked[tokenId].configId == 0;
    }

    /**
     * @dev Issues tokens only if there is a sufficient balance in the contract
     * @param recipient - Address of recipient
     * @param amount - Amount in wei to transfer
     */
    function _safeTransferRewards(address recipient, uint256 amount) internal {
        uint256 balance = IERC20(erc20RewardsAddress).balanceOf(address(this));
        if (amount <= balance) {
            IERC20(erc20RewardsAddress).transfer(recipient, amount);
        }
    }

    /**
     * @notice Set stake config by `configId`
     * @param configId - The config id by int
     * @param config - The configuration tuple that defines period emissions, bonus intervals, and period denominator
     */
    function setStakeConfig(
        uint256 configId,
        StakeConfiguration calldata config
    ) external onlyOwner {
        configuration[configId] = config;
        validConfigurations[configId] = true;
    }

    /**
     * @notice Sets the base stake config id
     * @param _baseStakeConfigId The id of the stake configuration to use
     */
    function setStakedBaseConfigId(
        uint256 _baseStakeConfigId
    ) external onlyOwner {
        require(validConfigurations[_baseStakeConfigId], "!valid");
        baseStakeConfigId = _baseStakeConfigId;
    }

    /**
     * @notice Sets the 1/1 token ids
     * @param _tokenIds The token ids that are 1/1s
     * @param _flag The state of the one of ones
     */
    function setOneOfOnes(
        uint256[] calldata _tokenIds,
        bool _flag
    ) external onlyOwner {
        for (uint256 i; i < _tokenIds.length; ) {
            oneOfOneLookup[_tokenIds[i]] = _flag;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Sets the 1/1 token ids
     * @param _tokenIds The token ids that are 1/1s
     * @param _flag The state of the one of ones
     */
    function setHonoraries(
        uint256[] calldata _tokenIds,
        bool _flag
    ) external onlyOwner {
        for (uint256 i; i < _tokenIds.length; ) {
            honoraryLookup[_tokenIds[i]] = _flag;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Emergency stake configuration update. Can be used to unlock all tokens from staking rewards system.
     * @param tokenIds - Array of token ids to update stake
     * @param stakeInfo - The staked info
     */
    function emergencyStakeUpdate(
        uint256[] calldata tokenIds,
        StakedToken calldata stakeInfo
    ) external onlyOwner {
        for (uint256 i; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            staked[tokenId] = stakeInfo;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Staked transfers allow users to move staked assets to different wallets
     *         without losing the contextual history. This could facilitate OTC staked
     *         trading that may bypass royalties but probably good for this.
     * @param to - The address to transfer to
     * @param tokenIds - The token ids to transfer
     */
    function stakedBatchTransfer(
        address to,
        uint256[] calldata tokenIds
    ) public {
        for (uint256 i; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == _msgSender(), "!owner");
            super.transferFrom(_msgSender(), to, tokenId);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Withdraw FRG tokens from the staking contract
     * @param amount - Amount in wei to withdraw
     */
    function withdrawFRG(uint256 amount) external onlyOwner {
        _safeTransferRewards(_msgSender(), amount);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(
            IERC721AUpgradeable,
            ERC721AUpgradeable,
            ERC2981Upgradeable,
            ERC4907AUpgradeable
        )
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId) ||
            ERC4907AUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice Sets the delegation registry address
     * @param _delegationRegistryAddress The delegation registry address
     */
    function setDelegationRegistry(
        address _delegationRegistryAddress
    ) external onlyOwner {
        delegationRegistryAddress = _delegationRegistryAddress;
    }

    /**
     * @notice Sets the erc20 address
     * @param _erc20RewardsAddress The ERC20 address
     */
    function setRewardsAddress(
        address _erc20RewardsAddress
    ) external onlyOwner {
        erc20RewardsAddress = _erc20RewardsAddress;
    }

    /**
     * @notice Token uri
     * @param tokenId The token id
     */
    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), "!exists");
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /// @dev Check if mint is live
    function isLive() public view returns (bool) {
        return block.timestamp >= liveAt && block.timestamp <= expiresAt;
    }

    /**
     * @notice Returns current mint state for a particular address
     * @param _address The address
     */
    function getMintState(
        address _address
    ) external view returns (MintState memory) {
        return
            MintState({
                isPublicOpen: isPublicOpen,
                liveAt: liveAt,
                expiresAt: expiresAt,
                maxSupply: maxSupply,
                totalSupply: totalSupply(),
                ethPrice: ethPrice,
                frgPrices: frgPrices,
                minted: addressToMinted[_address]
            });
    }

    /**
     * @notice Sets the collection max supply
     * @param _maxSupply The max supply of the collection
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Sets public mint is open
     * @param _isPublicOpen The public mint is open
     */
    function setIsPublicOpen(bool _isPublicOpen) external onlyOwner {
        isPublicOpen = _isPublicOpen;
    }

    /**
     * @notice Sets timestamps for live and expires timeframe
     * @param _liveAt A unix timestamp for live date
     * @param _expiresAt A unix timestamp for expiration date
     */
    function setMintWindow(
        uint256 _liveAt,
        uint256 _expiresAt
    ) external onlyOwner {
        liveAt = _liveAt;
        expiresAt = _expiresAt;
    }

    /**
     * @notice Sets the collection max per wallet
     * @param _maxPerWallet The max per wallet
     */
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice Sets prices
     * @param _ethPrice The eth price in wei
     * @param _frgPrices The frg prices in wei (minimum for og/molar/pub)
     */
    function setPrices(
        uint256 _ethPrice,
        FRGPricing calldata _frgPrices
    ) external onlyOwner {
        ethPrice = _ethPrice;
        frgPrices = _frgPrices;
    }

    /**
     * @notice Sets the treasury recipient
     * @param _treasury The treasury address
     */
    function setTreasury(address _treasury) public onlyOwner {
        treasury = payable(_treasury);
    }

    /**
     * @notice Sets the base uri for the token metadata
     * @param _baseURI The base uri
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the og merkle root for the mint
     * @param _ogMerkleRoot The og merkle root to set
     */
    function setOGMerkleRoot(bytes32 _ogMerkleRoot) external onlyOwner {
        ogMerkleRoot = _ogMerkleRoot;
    }

    /**
     * @notice Sets the molar merkle root for the mint
     * @param _molarMerkleRoot The molar merkle root to set
     */
    function setMolarMerkleRoot(bytes32 _molarMerkleRoot) external onlyOwner {
        molarMerkleRoot = _molarMerkleRoot;
    }

    /**
     * @notice Set default royalty
     * @param receiver The royalty receiver address
     * @param feeNumerator A number for 10k basis
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice Withdraws ETH funds from contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = treasury.call{value: balance}("");
        require(success, "Unable to withdraw ETH");
    }

    /// @notice Withdraws a FRG ERC20 token from contract
    function withdrawERC20(uint256 _amount) public onlyOwner {
        IERC20(frgContractAddress).transfer(treasury, _amount);
    }

    /**
     * @dev Airdrop function
     * @param _to The addresses to mint to airdrop too
     */
    function airdrop(address[] calldata _to) external onlyOwner {
        require(totalSupply() + _to.length < maxSupply, "Max mint reached.");
        for (uint256 i = 0; i < _to.length; ) {
            _mint(_to[i], 1);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Sets whether the operator filter is enabled or disabled
     * @param operatorFilteringEnabled_ A boolean value for the operator filter
     */
    function setOperatorFilteringEnabled(
        bool operatorFilteringEnabled_
    ) public onlyOwner {
        operatorFilteringEnabled = operatorFilteringEnabled_;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    /**
     * @notice Returns the locked information of specific token ids
     * @param tokenIds - token ids to check against
     */
    function areTokensLocked(
        uint256[] memory tokenIds
    ) external view returns (bool[] memory) {
        bool[] memory lockedStates = new bool[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            lockedStates[i] = !isUnlocked(tokenIds[i]);
        }
        return lockedStates;
    }

    /**
     * @notice Returns the staked information of specific token ids as an array of bytes.
     * @param tokenIds - token ids to check against
     * @return bytes[]
     */
    function stakedInfoOf(
        uint256[] memory tokenIds
    ) external view returns (bytes[] memory) {
        bytes[] memory stakedTimes = new bytes[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            stakedTimes[i] = abi.encode(
                tokenId,
                staked[tokenId].stakedAt,
                staked[tokenId].claimedAt,
                staked[tokenId].configId
            );
        }
        return stakedTimes;
    }
}