// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC2981Upgradeable, ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {ERC721BUpgradeable} from "./abstract/ERC721BUpgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "./interfaces/IDelegationRegistry.sol";
import "./interfaces/IThePlague.sol";

/***********************************************************************
 * MMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMWXOxdlllloxOKNWNXXK000OOO000KXXX0OOkOO0XWMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMW0o:,''''''''';cc:;;,,,'''''',,;;;,''''',;cd0WMMMMMMMMMMMMM
 * MMMMMMMMMMNx;'''''''''''''''''''''''''''''''''''''''''',dXMMMMMMMMMMMM
 * MMMMMMMMMM0:',lol;'.';cllc,',''',,,,,''''',''''''''''''''dNMMMMMMMMMMM
 * MMMMMMMMMM0c':kkc'';;;d00x;'',,'','''''',lxl,....,:cll;'';xXWMMMMMMMMM
 * MMMMMMMMMMXo';dx;.':;'lOkc,'',,,,,'''''';dOc'.;c;,o00Ol'''':xXMMMMMMMM
 * MMMMMMMMMWO:'';:,'..'';::,',''''','''''',cd;..,:,,d0Od;''''''lKWMMMMMM
 * MMMMMMMMMKl,''''''''','''',,',,',,'''''''','''''',clc,''''''''cKMMMMMM
 * MMMMMMMMNd,''''','''''''''''''''''',,,'''''''''''''''''''''''''dNMMMMM
 * MMMMMMMWk;'','''''''''''''''''''''''''''''''''''','','','''''''cKMMMMM
 * MMMMMMW0c,','',''''''''''''''',,,,'''''''''''''',,,,;;;,,''''''cKMMMMM
 * MMMMMNkl::;,,,,,,'''''''''''''''',''''''',,,,;;::ccccllc;''''''oNMMMMM
 * MMMMMXo:lllllc:;;;;,,,,,,,,,,,,,,,;;;;::::::ccccllllllc;,''''':OMMMMMM
 * MMMMMWx:cccccccccc::::::::::::::::::::ccccccccllllcc:;,'''''';kWMMMMMM
 * MMMMMW0occlllllcccccccccccccccccccccclllllllcc::;,,,'''''''':OWMMMMMMM
 * MMMMMMWN0xoc:::::ccccclllllllccccccc::::;;,,,,'''''''''''',oKWMMMMMMMM
 * MMMMMMMMMMWX0koc,'',,,,,,,,,,,,,,,''''''',,''''''''''''';o0WMMMMMMMMMM
 * MMMMMMMMMMMMMMWN0xo;'''''''''''''''''''''''''''''''.';lxKWMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMWKko:,''''''''''''''''''''''.',;cdkKWMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMWNKOxolc:;,,'''''',,,;:codk0XWMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXK000OOO00KKXNWMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 ************************************************************************/

/**
 * @title ThePlagueUpgradeable
 * @custom:website https://www.plaguebrands.io/
 * @author @scottybmitch
 * @custom:coauthor @lozzereth (www.allthingsweb3.com)
 * @custom:reference https://etherscan.io/token/0xbe0e87fa5bcb163b614ba1853668ffcd39d18fcb
 * @custom:license CC-BY-NC-4.0
 * @notice Contract is configured to use the DefaultOperatorFilterer, which automatically registers the
 *         token and subscribes it to OpenSea's curated filters. Contract has no minting functionality.
 *         Contract state is synced to a previous contract snapshot via `migrateTokens`. Primary adaptation
 *         from source work is moving towards non-escrow staking and configuration based rewards.
 */
contract ThePlagueUpgradeable is
    Initializable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    ERC721BUpgradeable,
    OperatorFilterer,
    IThePlague
{
    using StringsUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;

    /// @notice Base uri
    string public baseURI;

    /// @notice Maximum supply for the collection
    uint256 public constant MAX_SUPPLY = 11000;

    /// @notice Total supply
    uint256 private _totalMinted;

    /// @notice The base stake configuration to use on stake
    uint256 private baseStakeConfigId;

    /// @notice Operator filter toggle switch
    bool private operatorFilteringEnabled;

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
        address _erc20RewardsAddress,
        address _delegationRegistryAddress,
        string memory baseURI_
    ) public virtual initializer {
        __ERC721B_init("The Plague", "FROG");
        __Ownable_init();
        __ERC2981_init();
        // Setup filter registry
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        // Setup royalties to 10% (default denominator is 10000)
        _setDefaultRoyalty(_msgSender(), 1000);
        // Set baseline configuration
        baseStakeConfigId = 2;
        // Setup contracts
        erc20RewardsAddress = _erc20RewardsAddress;
        delegationRegistryAddress = _delegationRegistryAddress;
        // Set metadata
        baseURI = baseURI_;
    }

    /**
     * @notice Migrate NFTs from a snapshot
     * @param tokenIds - The token ids
     * @param owners - The token owners
     * @param stakedTokens - The token staking information
     */
    function migrateTokens(
        uint256[] calldata tokenIds,
        address[] calldata owners,
        StakedToken[] calldata stakedTokens
    ) external onlyOwner {
        uint256 inputSize = tokenIds.length;
        uint256 newTotalMinted = _totalMinted + inputSize;
        require(owners.length == inputSize);
        require(newTotalMinted <= MAX_SUPPLY);

        uint256 tokenId;
        address owner;

        for (uint256 i; i < inputSize; ) {
            tokenId = tokenIds[i];
            owner = owners[i];
            // Mint new token token id to previous owner
            _mint(owner, tokenId);
            // Sync stake state
            if (stakedTokens[i].configId == 1) {
                staked[tokenId] = stakedTokens[i];
                // To allow marketplaces to block listings of staked tokens
                emit Stake(tokenId);
            }
            unchecked {
                i++;
            }
        }
        _totalMinted = newTotalMinted;
    }

    /**
     * @notice Total supply of the collection
     * @return uint256 The total supply
     */
    function totalSupply() external view returns (uint256) {
        return _totalMinted;
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
        require(configId > 1 && validConfigurations[configId], "!config");
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Check token isn't already locked is owned by the `requester` (sender or delegate)
            require(isUnlocked(tokenId), "!unlocked");
            require(ownerOf(tokenId) == requester, "!owner");
            staked[tokenId].configId = uint16(configId);
            staked[tokenId].stakedAt = uint120(block.timestamp);
            // Emit event for marketplaces to track staked tokens
            emit Stake(tokenId);
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
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Check is owned by the `requester` (sender or delegate)
            require(ownerOf(tokenId) == requester, "!owner");
            uint120 lastStakedAt = staked[tokenId].stakedAt;
            config = configuration[staked[tokenId].configId];
            // Check minimum threshold for lock ins
            if (config.minimumStakePeriod > 0) {
                uint120 timePassed = (uint120(block.timestamp) - lastStakedAt);
                require(timePassed > config.minimumStakePeriod, "!minimum");
            }
            // Reset state
            delete staked[tokenId];
            // Emit event for marketplaces to track unstaked tokens
            emit Unstake(tokenId, uint256(lastStakedAt), block.timestamp);
        }
    }

    function _accruedRewards(
        StakeConfiguration memory config,
        uint256 periodsTotal,
        uint256 totalTimePassed
    ) internal view returns (uint256) {
        uint256 next = 0;
        uint256 maxIterations = config.bonusIntervals.length;
        uint256 bonusMin = 0;
        uint256 periodsChecked = 0;
        uint256 accrued = 0;

        do {
            bonusMin = config.bonusIntervals[next];
            // Bonus met
            if (bonusMin < periodsTotal) {
                accrued +=
                    config.periodEmissions[next] *
                    (bonusMin - periodsChecked);
                periodsChecked = bonusMin;
                next += 1;
            } else {
                maxIterations = 0;
            }
        } while (next < maxIterations);

        // Add in diff from periods total of the last bonus
        if (next == 0 && periodsTotal > 0) {
            // Never hit bonus interval
            accrued += config.periodEmissions[next] * periodsTotal;
        } else if (periodsChecked < periodsTotal) {
            // Remaining diff
            accrued +=
                config.periodEmissions[next] *
                (periodsTotal - periodsChecked);
        }

        // Apply additional bonus yields based on minimum stake period
        if (
            config.minimumStakePeriod > 0 &&
            totalTimePassed > config.minimumStakePeriod &&
            !config.isRetroactiveBonus &&
            periodsTotal > bonusMin
        ) {
            uint256 baseReward = config.periodEmissions[next];
            uint256 previousLevelReward = config.periodEmissions[next - 1];
            return
                baseReward *
                (periodsTotal - bonusMin) +
                previousLevelReward *
                bonusMin;
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
        uint256 accrued = _accruedRewards(config, totalPeriods, sinceDeposit);

        // Subtract out previous claim amounts
        if (claimedAt > stakedAt) {
            uint256 sinceClaim = claimedAt - stakedAt;
            uint256 sinceClaimPeriods = uint256(sinceClaim) /
                config.periodDenominator;
            uint256 alreadyClaimed = _accruedRewards(
                config,
                sinceClaimPeriods,
                sinceDeposit
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
        for (uint256 i; i < tokenIds.length; i++) {
            rewards[i] = calculateReward(tokenIds[i]);
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
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == requester, "!owner");
            unchecked {
                reward += calculateReward(tokenId);
            }
            staked[tokenId].claimedAt = uint120(block.timestamp);
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
     * @notice Emergency stake configuration update. Can be used to unlock all tokens from staking rewards system.
     * @param tokenIds - Array of token ids to update stake
     * @param stakeInfo - The staked info
     */
    function emergencyStakeUpdate(
        uint256[] calldata tokenIds,
        StakedToken calldata stakeInfo
    ) external onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            staked[tokenId] = stakeInfo;
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
            _safeTransfer(_msgSender(), to, tokenId, "");
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
        override(ERC721BUpgradeable, ERC2981Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            ERC721BUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721BUpgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        override(ERC721BUpgradeable, IERC721Upgradeable)
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
        override(ERC721BUpgradeable, IERC721Upgradeable)
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
        override(ERC721BUpgradeable, IERC721Upgradeable)
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
        override(ERC721BUpgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        require(isUnlocked(tokenId), "!unlocked");
        super.safeTransferFrom(from, to, tokenId, data);
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
    ) public view override returns (string memory) {
        require(_exists(tokenId), "!exists");
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @notice Sets the base uri for the token metadata
     * @param _baseURI The base uri
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
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

    /**
     * @notice Return token ids owned by user
     * @param account Account to query
     * @return tokenIds
     */
    function tokensOfOwner(
        address account
    ) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balanceOf(account);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i; tokenIdsIdx != tokenIdsLength; ++i) {
                if (!_exists(i)) {
                    continue;
                }
                if (ownerOf(i) == account) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}