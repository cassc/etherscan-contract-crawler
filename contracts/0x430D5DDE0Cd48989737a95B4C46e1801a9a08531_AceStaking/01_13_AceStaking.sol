// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/utils/introspection/ERC1820Implementer.sol";

contract AceStaking is
    Ownable,
    ReentrancyGuard,
    IERC721Receiver,
    IERC777Sender,
    IERC777Recipient,
    ERC1820Implementer
{
    // Interfaces for ERC777 and ERC721
    IERC777 public immutable rewardsToken;
    mapping(address => IERC721) public nftContracts;
    address[] public nftContractAddresses;

    // Reward Settings
    mapping(address => uint256) public rewardsForContract;
    mapping(address => mapping(uint256 => uint256))
        public additionalRewardsForToken;

    uint256 public rewardPeriodInSeconds;
    uint256 public totalTokensStakedCount;
    address internal REWARD_UPDATER;

    // Definition of Staker
    struct Staker {
        uint256 unclaimedRewards;
        uint256 lifetimeRewards;
        uint256 lastRewardedAt;
        uint256 lastClaimedAt;
    }

    // This is how we expect Tokens to be sent
    struct TokenData {
        address contractAddress;
        uint256 tokenIdentifier;
    }

    // How we keep track of a Staked token
    struct StakedToken {
        address contractAddress;
        uint256 tokenIdentifier;
        uint256 lastRewardedAt;
        uint256 stakedAt;
    }

    event UnstakedNFT(StakedToken stakedToken, address indexed staker);
    event StakedNFT(StakedToken stakedToken, address indexed staker);
    event RewardClaimed(address indexed staker, uint256 indexed amount);

    address[] public currentStakers;
    mapping(address => Staker) public stakers;
    mapping(address => StakedToken[]) public stakedTokensForAddress;
    mapping(address => mapping(uint256 => address)) public stakedTokenOwner;
    mapping(uint256 => mapping(address => uint256))
        internal sharesForWalletInRound;
    mapping(uint256 => address[]) internal walletsToRewardInRound;
    uint256 internal currentRoundId;

    uint256 public slashingPeriod = 24;

    // ERC777 Definitions
    event TokensToSendCalled(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes data,
        bytes operatorData,
        address token,
        uint256 fromBalance,
        uint256 toBalance
    );

    event TokensReceivedCalled(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes data,
        bytes operatorData,
        address token,
        uint256 fromBalance,
        uint256 toBalance
    );

    bool private _shouldRevertSend;
    bool private _shouldRevertReceive;

    IERC1820Registry internal constant _ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH =
        keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    /**
     * @dev Setsup the new Contract.
     *
     * @param _rewardsToken A ERC777 Token. Can't be changed!
     * @param _rewardPeriodInSeconds Every x Seconds the Reward gets emitted. Can't be changed! Needs to be at least 60 Seconds but at least a day is recommneded.
     */
    constructor(IERC777 _rewardsToken, uint256 _rewardPeriodInSeconds) {
        require(
            _rewardPeriodInSeconds > 60,
            "AceStaking: Rewards need to be paid at least once per minute"
        );
        rewardsToken = _rewardsToken;
        rewardPeriodInSeconds = _rewardPeriodInSeconds;
        REWARD_UPDATER = msg.sender;
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            _TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            _TOKENS_SENDER_INTERFACE_HASH,
            address(this)
        );
    }

    /**
     * @dev Call this function to add a new NFT Contract to be accepted for staking.
     * Each contract can have differen rewards.
     *
     * Requirements: onlyOwner can add new Contracts; Contract needs to be ERC721 compliant.
     * @param _nftContract A ERC721 Contract that can be used for staking.
     * @param _reward ERC777 Token Value that is rewarded for each token every rewardPeriodInSeconds.
     */
    function addNFTContract(IERC721 _nftContract, uint256 _reward)
        public
        onlyOwner
    {
        nftContracts[address(_nftContract)] = _nftContract;
        nftContractAddresses.push(address(_nftContract));
        rewardsForContract[address(_nftContract)] = _reward;
    }

    /**
     * @dev Call this function to remove a NFT contract from beeing accepted for staking.
     * All tokens remain in the contract but wont receive any further rewards. They can be withdrawn by
     * the token owner.
     * Warning: Additional Rewards might stay in place, so call setAdditionalRewardsForTokens first and set their reward to 0.
     *
     * Requirements: onlyOwner can remove Contracts; Contract needs to be ERC721 compliant and already added through addNFTContract.
     * @param _nftContract A ERC721 Contract that should be removed from staking.
     */
    function removeNFTContract(address _nftContract) public onlyOwner {
        require(
            nftContracts[_nftContract] == IERC721(_nftContract),
            "AceStaking: Unkown Contract"
        );

        nftContracts[address(_nftContract)] = IERC721(address(0));
        rewardsForContract[address(_nftContract)] = 0;
        for (uint256 i; i < nftContractAddresses.length; i = unsafe_inc(i)) {
            if (nftContractAddresses[i] == _nftContract) {
                nftContractAddresses[i] = nftContractAddresses[
                    nftContractAddresses.length - 1
                ];
                nftContractAddresses.pop();
            }
        }
    }

    /**
     * @dev This function allows the contract owner to set an additional bonus that is
     * added for each token. The reward is added on top to the default reward for the contract.
     *
     * Requirements: onlyOwner or rewardUpdate (external contract) can remove Contracts; Contract needs to be ERC721 compliant
     * and already added through addNFTContract.
     * @param _nftContract A ERC721 Contract that is accepted by the contract.
     * @param _tokenIdentifiers Array of Identifiers that should receive the additional reward
     * @param _additionalReward ERC777 Token Value that is rewarded for each token every rewardPeriodInSeconds additionally to the default reward.
     */
    function setAdditionalRewardsForTokens(
        IERC721 _nftContract,
        uint256[] memory _tokenIdentifiers,
        uint256 _additionalReward
    ) external onlyRewardUpdater {
        require(
            nftContracts[address(_nftContract)] == IERC721(_nftContract),
            "AceStaking: Unkown Contract"
        );

        uint256 tokenCounter = _tokenIdentifiers.length;
        for (uint256 i; i < tokenCounter; i = unsafe_inc(i)) {
            additionalRewardsForToken[address(_nftContract)][
                _tokenIdentifiers[i]
            ] = _additionalReward;
        }
    }

    /**
     * @dev You need to claim your rewards at least once within this period.
     * If not you won't get any new rewards until you claim again.
     *
     * Requirements: onlyOwner can change that value
     *
     * @param _slashingPeriod Amount of Periods after that rewards get slashed
     */
    function setSlashingPeriod(uint256 _slashingPeriod) external onlyOwner {
        slashingPeriod = _slashingPeriod;
    }

    /**
     * @dev We reward a Bonus depending on different traits in some periods.
     * The choosen traits and to be rewareded tokens are calculated off-chain.
     * Tokens need to be staked when the reward is paid and already staked in the Snapshot of Tokens that is sent.
     * If you want to learn more about how our trait based bonus works take a look at our website.
     *
     * @param _tokens Array of TokenData(contractAddress, tokenId)
     * @param _totalBonus Amount of Tokens that should be distributed among sent tokens
     */
    function rewardBonus(TokenData[] calldata _tokens, uint256 _totalBonus)
        external
        onlyRewardUpdater
    {
        uint256 stakedTokensLength = _tokens.length;
        require(stakedTokensLength > 0, "AceStaking: No Tokens");
        require(
            _totalBonus > 0,
            "AceStaking: No Bonus to be distributed"
        );

        uint256 totalShares;
        currentRoundId += 1;
        for (uint256 i; i < stakedTokensLength; i = unsafe_inc(i)) {
            address _staker = stakedTokenOwner[_tokens[i].contractAddress][
                _tokens[i].tokenIdentifier
            ];
            if (_staker != address(0)) {
                sharesForWalletInRound[currentRoundId][_staker] += 100;
                walletsToRewardInRound[currentRoundId].push(_staker);
                totalShares += 1;
            }
        }

        require(totalShares > 0, "AceStaking: No shares to distribute");

        uint256 walletsToRewardLength = walletsToRewardInRound[currentRoundId]
            .length;
        for (uint256 i; i < walletsToRewardLength; i = unsafe_inc(i)) {
            address walletToCheck = walletsToRewardInRound[currentRoundId][i];
            if (sharesForWalletInRound[currentRoundId][walletToCheck] > 0) {
                uint256 rewardsForWallet = (sharesForWalletInRound[
                    currentRoundId
                ][walletToCheck] / totalShares) * (_totalBonus / 100);

                stakers[walletToCheck].unclaimedRewards += rewardsForWallet;
                stakers[walletToCheck].lifetimeRewards += rewardsForWallet;

                sharesForWalletInRound[currentRoundId][walletToCheck] = 0;
            }
        }
    }

    /**
     * @dev Function to estimate rewards for specific token on a contract in one period.
     * Token ID could be out of range we don't care since this is just for
     * simulating unstaked token rewards for UI.
     *
     * Requirements: nftContractAddress needs to be registereed on the staking contract.
     * @param nftContractAddress A ERC721 Contract of the token
     * @param tokenIdentifier Token Identifier that you want an estimation for
     */
    function estimateRewardsForToken(
        address nftContractAddress,
        uint256 tokenIdentifier
    ) public view returns (uint256) {
        require(
            nftContracts[nftContractAddress] == IERC721(nftContractAddress),
            "AceStaking: Unkown Contract"
        );
        return rewardsForToken(nftContractAddress, tokenIdentifier);
    }

    /**
     * @dev Returns multiple stats for the address. Returns those values:
     * - totalTokensStaked: Count of Tokens for this Wallet on the Staking Contract
     * - unclaimedRewards: Rewards that can be claimed but are unclaimed by the user
     * - unaccountedRewards: Rewards that are not ready to be claimed
     * because the current period did not finish yet. If tokens were staked on different
     * start times this number might never be 0.
     * - lifetimeRewards: Just counting up what a user earned over life
     *
     * @param _stakerAddress Wallet Address that has staked tokens on the contract
     */
    function stakerStats(address _stakerAddress)
        public
        view
        returns (
            uint256 totalTokensStaked,
            uint256 unclaimedRewards,
            uint256 unaccountedRewards,
            uint256 lifetimeRewards
        )
    {
        Staker memory staker = stakers[_stakerAddress];
        uint256 claimableRewards = calculateUnaccountedRewards(
            _stakerAddress,
            false
        );
        return (
            stakedTokensForAddress[_stakerAddress].length,
            staker.unclaimedRewards + claimableRewards,
            calculateUnaccountedRewards(_stakerAddress, true),
            staker.lifetimeRewards + claimableRewards
        );
    }

    /**
     * @dev Function to unstake all tokens for the msg.sender.
     * Also rewards msg.sender for all of his staked tokens his staked tokens and ejects all tokens after this.
     * If you have many tokens staked (50+) we recommend unstaking them in badges to not hit the gas limit of a block.
     */
    function unstakeAllTokens() external nonReentrant {
        StakedToken[] memory stakedTokens = stakedTokensForAddress[msg.sender];
        uint256 stakedTokensLength = stakedTokens.length;
        require(stakedTokensLength > 0, "AceStaking: No Tokens found");
        rewardStaker(msg.sender);
        for (uint256 i; i < stakedTokensLength; i = unsafe_inc(i)) {
            ejectToken(
                stakedTokens[i].contractAddress,
                stakedTokens[i].tokenIdentifier
            );
        }
    }

    /**
     * @dev Unstake a Set of Tokens for msg.sender.
     * Also rewards msg.sender for all of his staked tokens his staked tokens and ejects all sent tokens after this.
     *
     * @param _tokens Array of TokenData(contractAddress, tokenId)
     */
    function unstake(TokenData[] calldata _tokens) external nonReentrant {
        uint256 stakedTokensLength = _tokens.length;
        require(stakedTokensLength > 0, "AceStaking: No Tokens found");
        rewardStaker(msg.sender);
        for (uint256 i; i < stakedTokensLength; i = unsafe_inc(i)) {
            ejectToken(_tokens[i].contractAddress, _tokens[i].tokenIdentifier);
        }
    }

    /**
     * @dev Emergency Unstake Function: Unstake without any reward calculation.
     * !!! NOT RECOMMENDED, YOU MIGHT LOSE UNACCOUNTED REWARDS !!!
     * When to use? This function consumes less gas then the normal unstake since we do not reward all tokens before unstaking.
     * In case you hit the block limit for gas (very unlikely) we have a way to withdrawal your tokens somehow.
     * @param _tokens Array of TokenData(contractAddress, tokenId)
     */
    function emergencyUnstake(TokenData[] calldata _tokens)
        external
        nonReentrant
    {
        uint256 stakedTokensLength = _tokens.length;
        require(stakedTokensLength > 0, "AceStaking: No Tokens in calldata");
        for (uint256 i; i < stakedTokensLength; i = unsafe_inc(i)) {
            ejectToken(_tokens[i].contractAddress, _tokens[i].tokenIdentifier);
        }
    }

    /**
     * @dev This function transfers tokens to the contract with transferFrom.
     * thusfor we need to call addToken manually but we save a little on gas.
     *
     * Requirements: All token contracts need to be added to this contract and be approved by the user.
     *
     * @param _tokens Array of TokenData(contractAddress, tokenId)
     */
    function stake(TokenData[] calldata _tokens) external {
        beforeTokensAdded(msg.sender);
        uint256 tokensLength = _tokens.length;
        for (uint256 i; i < tokensLength; i = unsafe_inc(i)) {
            IERC721(_tokens[i].contractAddress).transferFrom(
                msg.sender,
                address(this),
                _tokens[i].tokenIdentifier
            );
            addToken(
                _tokens[i].contractAddress,
                _tokens[i].tokenIdentifier,
                msg.sender
            );
        }
    }

    /**
     * @dev Call this function to get your ERC777 Token rewards transfered to your wallet.
     * This is an expensive call since we calculate your current earnings and send them in one
     * Transaction to your wallet.
     *
     */
    function claimRewards() external nonReentrant {
        rewardStaker(msg.sender);
        require(
            stakers[msg.sender].unclaimedRewards > 0,
            "AceStaking: Nothing to claim"
        );
        IERC777(rewardsToken).send(
            msg.sender,
            stakers[msg.sender].unclaimedRewards,
            ""
        );
        emit RewardClaimed(msg.sender, stakers[msg.sender].unclaimedRewards);
        stakers[msg.sender].unclaimedRewards = 0;
        stakers[msg.sender].lastClaimedAt = block.timestamp;
    }

    /**
     * @dev This function determains how many periods should be calculated for rewarding.
     *
     * @param _lastRewardedAt timestamp when the token was rewarded last
     * @param _lastClaimedAt timestamp when ist was last claimed
     *
     */
    function rewardPeriods(uint256 _lastRewardedAt, uint256 _lastClaimedAt)
        internal
        view
        returns (uint256 _rewardPeriodCounter)
    {
        uint256 referenceTimestamp = block.timestamp;
        if (
            referenceTimestamp >
            (_lastClaimedAt + slashingPeriod * rewardPeriodInSeconds)
        ) {
            referenceTimestamp =
                _lastClaimedAt +
                slashingPeriod *
                rewardPeriodInSeconds;
        }
        return (referenceTimestamp - _lastRewardedAt) / rewardPeriodInSeconds;
    }

    /**
     * @dev Calculates Rewards for a User and accounts them to his entry.
     *
     * @param _stakerAddress staker that should be rewarded
     *
     */
    function rewardUnaccountedRewards(address _stakerAddress)
        internal
        returns (uint256 _rewards)
    {
        StakedToken[] memory stakedTokens = stakedTokensForAddress[
            _stakerAddress
        ];
        uint256 totalRewards;
        uint256 stakedTokensCount = stakedTokens.length;
        for (uint256 i; i < stakedTokensCount; i = unsafe_inc(i)) {
            uint256 periodsToReward = rewardPeriods(
                stakedTokens[i].lastRewardedAt,
                stakers[_stakerAddress].lastClaimedAt
            );

            if (periodsToReward > 0) {
                totalRewards +=
                    periodsToReward *
                    rewardsForToken(
                        stakedTokens[i].contractAddress,
                        stakedTokens[i].tokenIdentifier
                    );
                if (periodsToReward == slashingPeriod) {
                    stakedTokensForAddress[_stakerAddress][i].lastRewardedAt =
                        stakedTokensForAddress[_stakerAddress][i].stakedAt +
                        (
                            uint256(
                                (block.timestamp -
                                    stakedTokensForAddress[_stakerAddress][i]
                                        .stakedAt) / rewardPeriodInSeconds
                            )
                        ) *
                        rewardPeriodInSeconds;
                } else {
                    stakedTokensForAddress[_stakerAddress][i].lastRewardedAt =
                        stakedTokensForAddress[_stakerAddress][i].stakedAt +
                        periodsToReward *
                        rewardPeriodInSeconds;
                }
            }
        }
        return totalRewards;
    }

    /**
     * @dev Calculates Rewards for a User but does not account them.
     *
     * @param _stakerAddress staker that should be rewarded
     * @param _simulateUnaccounted include unaccounted rewards that can't be claimed yet
     *
     */
    function calculateUnaccountedRewards(
        address _stakerAddress,
        bool _simulateUnaccounted
    ) internal view returns (uint256 _rewards) {
        StakedToken[] memory stakedTokens = stakedTokensForAddress[
            _stakerAddress
        ];
        uint256 totalRewards;
        uint256 stakedTokensCount = stakedTokens.length;
        for (uint256 i; i < stakedTokensCount; i = unsafe_inc(i)) {
            uint256 periodsToReward = rewardPeriods(
                stakedTokens[i].lastRewardedAt,
                stakers[_stakerAddress].lastClaimedAt
            );

            uint256 tokenReward = rewardsForToken(
                stakedTokens[i].contractAddress,
                stakedTokens[i].tokenIdentifier
            );
            if (_simulateUnaccounted) {
                totalRewards +=
                    ((((block.timestamp - stakedTokens[i].lastRewardedAt) *
                        100) / rewardPeriodInSeconds) * tokenReward) /
                    100 -
                    periodsToReward *
                    tokenReward;
            } else {
                totalRewards += tokenReward * periodsToReward;
            }
        }
        return totalRewards;
    }

    /**
     * @dev Summarize rewards for a specific token on a contract.
     * Sums up default rewards for contract and bonus for token identifier.
     *
     * @param nftContractAddress Contract to check
     * @param tokenIdentifier Token Identifier to check
     *
     */
    function rewardsForToken(
        address nftContractAddress,
        uint256 tokenIdentifier
    ) internal view returns (uint256) {
        return
            rewardsForContract[nftContractAddress] +
            additionalRewardsForToken[nftContractAddress][tokenIdentifier];
    }

    /**
     * @dev Function that moves all unaccounted rewards to unclaimed.
     * This call is required to keep our internal balance sheets up to date.
     * Depending on Token Amount this is very expensive to call since we loop through all tokens!
     *
     * @param _address Wallet Address that should be rewarded
     *
     */
    function rewardStaker(address _address) internal {
        uint256 unaccountedRewards = rewardUnaccountedRewards(_address);
        stakers[_address].lastRewardedAt = block.timestamp;
        stakers[_address].unclaimedRewards += unaccountedRewards;
        stakers[_address].lifetimeRewards += unaccountedRewards;
    }

    /**
     * @dev Internal function to send a token back to a user. Also
     * removes / updates all contract internal trackings.
     *
     * Requirements: msg.sender needs to be the wallet that sent the token to the contract.
     *
     * @param nftContractAddress Contract for the token to be ejected
     * @param tokenIdentifier Token Identifier for the token to be ejected
     *
     */
    function ejectToken(address nftContractAddress, uint256 tokenIdentifier)
        internal
    {
        require(
            stakedTokenOwner[nftContractAddress][tokenIdentifier] == msg.sender,
            "AceStaking: Not your token..."
        );

        IERC721(nftContractAddress).transferFrom(
            address(this),
            msg.sender,
            tokenIdentifier
        );

        for (
            uint256 i;
            i < stakedTokensForAddress[msg.sender].length;
            i = unsafe_inc(i)
        ) {
            if (
                stakedTokensForAddress[msg.sender][i].tokenIdentifier ==
                tokenIdentifier &&
                stakedTokensForAddress[msg.sender][i].contractAddress ==
                nftContractAddress
            ) {
                emit UnstakedNFT(
                    stakedTokensForAddress[msg.sender][i],
                    msg.sender
                );
                stakedTokensForAddress[msg.sender][i] = stakedTokensForAddress[
                    msg.sender
                ][stakedTokensForAddress[msg.sender].length - 1];
                stakedTokensForAddress[msg.sender].pop();
            }
        }

        if (stakedTokensForAddress[msg.sender].length == 0) {
            for (uint256 i; i < currentStakers.length; i = unsafe_inc(i)) {
                if (currentStakers[i] == msg.sender) {
                    currentStakers[i] = currentStakers[
                        currentStakers.length - 1
                    ];
                    currentStakers.pop();
                }
            }
        }

        stakedTokenOwner[msg.sender][tokenIdentifier] = address(0);
        totalTokensStakedCount -= 1;
    }

    /**
     * @dev Helper that should be called before any token is added. Needs to be called
     * only once per batch. It basically setup the staker object.
     *
     * @param _staker Wallet Address for Staker
     */
    function beforeTokensAdded(address _staker) internal {
        if (stakedTokensForAddress[_staker].length == 0) {
            if (stakers[_staker].lastRewardedAt > 0) {
                // This wallet already staked before and was at least rewarded once.
                stakers[_staker].lastRewardedAt = block.timestamp;
                stakers[_staker].lastClaimedAt = block.timestamp;
            } else {
                // This wallet is new to us
                stakers[_staker] = Staker(
                    stakers[_staker].unclaimedRewards,
                    stakers[_staker].lifetimeRewards,
                    block.timestamp,
                    block.timestamp
                );
            }
            currentStakers.push(_staker);
        }
    }

    /**
     * @dev Function to add a token and regiter it in all mappings that we need to
     * return and reward a token.
     *
     * @param nftContractAddress Contract of the token
     * @param tokenIdentifier The Identifier of a token
     * @param tokenOwnerAddress The address of the current owner
     */
    function addToken(
        address nftContractAddress,
        uint256 tokenIdentifier,
        address tokenOwnerAddress
    ) internal {
        require(
            nftContracts[nftContractAddress] == IERC721(nftContractAddress),
            "AceStaking: Unkown Contract"
        );

        StakedToken memory newToken = StakedToken(
            nftContractAddress,
            tokenIdentifier,
            block.timestamp,
            block.timestamp
        );
        stakedTokenOwner[nftContractAddress][
            tokenIdentifier
        ] = tokenOwnerAddress;

        stakedTokensForAddress[tokenOwnerAddress].push(newToken);
        totalTokensStakedCount += 1;
        emit StakedNFT(newToken, tokenOwnerAddress);
    }

    function unsafe_inc(uint256 x) private pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}. Also registers token in our TokenRegistry.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address, // operator not required
        address tokenOwnerAddress,
        uint256 tokenIdentifier,
        bytes memory
    ) public virtual override returns (bytes4) {
        beforeTokensAdded(tokenOwnerAddress);
        addToken(msg.sender, tokenIdentifier, tokenOwnerAddress);
        return this.onERC721Received.selector;
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        if (_shouldRevertSend) {
            revert();
        }

        IERC777 token = IERC777(_msgSender());

        uint256 fromBalance = token.balanceOf(from);
        // when called due to burn, to will be the zero address, which will have a balance of 0
        uint256 toBalance = token.balanceOf(to);

        emit TokensToSendCalled(
            operator,
            from,
            to,
            amount,
            userData,
            operatorData,
            address(token),
            fromBalance,
            toBalance
        );
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        if (_shouldRevertReceive) {
            revert();
        }

        IERC777 token = IERC777(_msgSender());

        uint256 fromBalance = token.balanceOf(from);
        // when called due to burn, to will be the zero address, which will have a balance of 0
        uint256 toBalance = token.balanceOf(to);

        emit TokensReceivedCalled(
            operator,
            from,
            to,
            amount,
            userData,
            operatorData,
            address(token),
            fromBalance,
            toBalance
        );
    }


    /**
     * @dev This address is allowed to change the rewards for a specific token.
     * Since opening a chest door results in a different reward, this is implemented in the chest door opener contract later.
     *
     * @param _REWARD_UPDATER Address that is allowed to modify rewards
     */
    function setRewardUpdater(address _REWARD_UPDATER) external onlyOwner {
        REWARD_UPDATER = _REWARD_UPDATER;
    }

    modifier onlyRewardUpdater() {
        require(
            msg.sender == REWARD_UPDATER || msg.sender == owner(),
            "AceStaking: Only REWARD_UPDATE or OWNER."
        );
        _;
    }
}

/** created with bowline.app **/