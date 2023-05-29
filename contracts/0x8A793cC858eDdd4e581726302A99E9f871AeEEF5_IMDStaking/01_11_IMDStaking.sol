// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICollegeCredit.sol";
import "./CollegeCredit.sol";

contract IMDStaking is Ownable {
    event Staked(address indexed user, address indexed token, uint256[] tokenIds, uint256 timestamp);
    event Unstaked(address indexed user, address indexed token, uint256[] tokenIds, uint256 timestamp);
    event ClaimDividend(address indexed user, address indexed token, uint256 amount);

    struct StakedToken {
        uint256 stakeTimestamp;
        uint256 nextToken;
        address owner;
    }

    struct StakableTokenAttributes {
        /**
         * The minimum yield per period.
         */
        uint256 minYield;
        /**
         * The maximum yield per period.
         */
        uint256 maxYield;
        /**
         * The amount that yield increases per period.
         */
        uint256 step;
        /**
         * The amount of time needed to earn 1 yield.
         */
        uint256 yieldPeriod;
        /**
         * A mapping from token ids to information about that token's staking.
         */
        mapping(uint256 => StakedToken) stakedTokens;
        /**
         * A mapping from the user's address to their root staked token
         */
        mapping(address => uint256) firstStaked;
        /**
         * A mapping of modifiers to rewards for each staker's
         * address.
         */
        mapping(address => int256) rewardModifier;
    }

    /**
     * The reward token (college credit) to be issued to stakers.
     */
    ICollegeCredit public rewardToken;

    /**
     * A mapping of token addresses to staking configurations.
     */
    mapping(address => StakableTokenAttributes) public stakableTokenAttributes;

    /**
     * The constructor for the staking contract, builds the initial reward token and stakable token.
     * @param _token the first stakable token address.
     * @param _minYield the minimum yield for the stakable token.
     * @param _maxYield the maximum yield for the stakable token.
     * @param _step the amount yield increases per yield period.
     * @param _yieldPeriod the length (in seconds) of a yield period (the amount of period after which a yield is calculated)
     */
    constructor(
        address _token,
        uint256 _minYield,
        uint256 _maxYield,
        uint256 _step,
        uint256 _yieldPeriod
    ) {
        _addStakableToken(_token, _minYield, _maxYield, _step, _yieldPeriod);

        rewardToken = new CollegeCredit();
    }

    /**
     * Mints the reward token to an account.
     * @dev owner only.
     * @param _recipient the recipient of the minted tokens.
     * @param _amount the amount of tokens to mint.
     */
    function mintRewardToken(address _recipient, uint256 _amount)
        external
        onlyOwner
    {
        rewardToken.mint(_recipient, _amount);
    }

    /**
     * Adds a new token that can be staked in the contract.
     * @param _token the first stakable token address.
     * @param _minYield the minimum yield for the stakable token.
     * @param _maxYield the maximum yield for the stakable token.
     * @param _step the amount yield increases per yield period.
     * @param _yieldPeriod the length (in seconds) of a yield period (the amount of period after which a yield is calculated).
     * @dev owner only, doesn't allow adding already staked tokens.
     */
    function addStakableToken(
        address _token,
        uint256 _minYield,
        uint256 _maxYield,
        uint256 _step,
        uint256 _yieldPeriod
    ) external onlyOwner {
        require(!_isStakable(_token), "Already exists");
        _addStakableToken(_token, _minYield, _maxYield, _step, _yieldPeriod);
    }

    /**
     * Stakes a given token id from a given contract.
     * @param _token the address of the stakable token.
     * @param _tokenId the id of the token to stake.
     * @dev the contract must be approved to transfer that token first.
     *      the address must be a stakable token.
     */
    function stake(address _token, uint256 _tokenId) external {
        require(_isStakable(_token), "Not stakable");

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;

        _bulkStakeFor(msg.sender, _token, tokenIds);
        emit Staked(msg.sender, _token, tokenIds, block.timestamp);
    }

    /**
     * Stakes a given token id from a given contract.
     * @param _token the address of the stakable token.
     * @param _tokenIds the ids of the tokens to stake.
     * @dev the contract must be approved to transfer that token first.
     *      the address must be a stakable token.
     */
    function stakeMany(address _token, uint256[] calldata _tokenIds) external {
        require(_isStakable(_token), "Not stakable");
        _bulkStakeFor(msg.sender, _token, _tokenIds);

        emit Staked(msg.sender, _token, _tokenIds, block.timestamp);
    }

    /**
     * Unstakes a given token held by the calling user.
     * @param _token the address of the token contract that the token belongs to.
     * @param _tokenId the id of the token to unstake.
     * @dev reverts if the token is not owned by the caller.
     */
    function unstake(address _token, uint256 _tokenId) external {
        require(_isStakable(_token), "Not stakable");
        require(
            stakableTokenAttributes[_token].stakedTokens[_tokenId].owner ==
                msg.sender,
            "Not owner"
        );

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;

        _unstake(_token, _tokenId);
        emit Unstaked(msg.sender, _token, tokenIds, block.timestamp);
    }

    /**
     * Unstakes the given tokens held by the calling user.
     * @param _token the address of the token contract that the tokens belong to.
     * @param _tokenIds the ids of the tokens to unstake.
     * @dev reverts if the token(s) are not owned by the caller.
     */
    function unstakeMany(address _token, uint256[] calldata _tokenIds)
        external
    {
        require(_isStakable(_token), "Not stakable");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                stakableTokenAttributes[_token]
                    .stakedTokens[_tokenIds[i]]
                    .owner == msg.sender,
                "Not owner"
            );

            _unstake(_token, _tokenIds[i]);
        }

        emit Unstaked(msg.sender, _token, _tokenIds, block.timestamp);
    }

    /**
     * Claims the rewards for the caller.
     * @param _token the token for which we are claiming rewards.
     */
    function claimRewards(address _token) external {
        require(_isStakable(_token), "Not stakable");
        uint256 dividend = _withdrawRewards(msg.sender, _token);

        emit ClaimDividend(msg.sender, _token, dividend);
    }

    /**
     * Gets the College Credit dividend of the provided user.
     * @param _user the user whose dividend we are checking.
     * @param _token the token in which we are checking.
     */
    function dividendOf(address _user, address _token)
        external
        view
        returns (uint256)
    {
        require(_isStakable(_token), "Not stakable");
        return _dividendOf(_user, _token);
    }

    /**
     * Unstakes a given token held by the calling user AND withdraws all dividends.
     * @param _token the address of the token contract that the token belongs to.
     * @param _tokenId the id of the token to unstake.
     * @dev reverts if the token is not owned by the caller.
     */
    function unstakeAndClaimRewards(address _token, uint256 _tokenId) external {
        require(_isStakable(_token), "Not stakable");
        require(
            stakableTokenAttributes[_token].stakedTokens[_tokenId].owner ==
                msg.sender,
            "Not owner"
        );
        uint256 dividend = _withdrawRewards(msg.sender, _token);
        _unstake(_token, _tokenId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;

        emit ClaimDividend(msg.sender, _token, dividend);
        emit Unstaked(msg.sender, _token, tokenIds, block.timestamp);
    }

    /**
     * Unstakes the given tokens held by the calling user AND withdraws all dividends.
     * @param _token the address of the token contract that the token belongs to.
     * @param _tokenIds the ids of the tokens to unstake.
     * @dev reverts if the tokens are not owned by the caller.
     */
    function unstakeManyAndClaimRewards(
        address _token,
        uint256[] calldata _tokenIds
    ) external {
        require(_isStakable(_token), "Not stakable");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                stakableTokenAttributes[_token]
                    .stakedTokens[_tokenIds[i]]
                    .owner == msg.sender,
                "Not owner"
            );
            _unstake(_token, _tokenIds[i]);
        }
        uint256 dividend = _withdrawRewards(msg.sender, _token);

        emit ClaimDividend(msg.sender, _token, dividend);
        emit Unstaked(msg.sender, _token, _tokenIds, block.timestamp);
    }

    /**
     * Gets the total amount of tokens staked for the given user in the given contract.
     * @param _user the user whose stakes are being counted.
     * @param _token the address of the contract whose staked tokens we are skimming.
     * @dev reverts if called on an invalid token address.
     */
    function totalStakedFor(address _user, address _token)
        external
        view
        returns (uint256)
    {
        require(_isStakable(_token), "Not stakable");
        return _totalStaked(_user, _token);
    }

    /**
     * Gets the total amount staked for a given token address.
     * @param _token the address to get the amount staked from.
     */
    function totalStaked(address _token) external view returns (uint256) {
        require(_isStakable(_token), "Not stakable");
        return _totalStaked(_token);
    }

    /**
     * Gets all of the token ids that a user has staked from a given contract.
     * @param _user the user whose token ids are being analyzed.
     * @param _token the address of the token contract being analyzed.
     * @return an array of token ids staked by that user.
     * @dev reverts if called on an invalid token address.
     */
    function stakedTokenIds(address _user, address _token)
        external
        view
        returns (uint256[] memory)
    {
        require(_isStakable(_token), "Not stakable");
        return _stakedTokenIds(_user, _token);
    }

    // --------------- INTERNAL FUNCTIONS -----------------

    /**
     * Gets the total amount staked for a given token address.
     * @param _token the address to get the amount staked from.
     */
    function _totalStaked(address _token) internal view returns (uint256) {
        return IERC721(_token).balanceOf(address(this));
    }

    /**
     * @return if the given token address is stakable.
     * @param _token the address to a token to query for stakability.
     * @dev does not check if is ERC721, that is up to the user.
     */
    function _isStakable(address _token) internal view returns (bool) {
        return stakableTokenAttributes[_token].maxYield != 0;
    }

    /**
     * Adds a given token to the list of stakable tokens.
     * @param _token the first stakable token address.
     * @param _minYield the minimum yield for the stakable token.
     * @param _maxYield the maximum yield for the stakable token.
     * @param _step the amount yield increases per yield period.
     * @param _yieldPeriod the length (in seconds) of a yield period (the amount of period after which a yield is calculated).
     * @dev checks constraints to ensure _isStakable works as well as other logic. Does not check if is already stakable.
     */
    function _addStakableToken(
        address _token,
        uint256 _minYield,
        uint256 _maxYield,
        uint256 _step,
        uint256 _yieldPeriod
    ) internal {
        require(_maxYield > 0, "Invalid max");
        require(_minYield > 0, "Invalid min");
        require(_yieldPeriod >= 1 minutes, "Invalid period");

        stakableTokenAttributes[_token].maxYield = _maxYield;
        stakableTokenAttributes[_token].minYield = _minYield;
        stakableTokenAttributes[_token].step = _step;
        stakableTokenAttributes[_token].yieldPeriod = _yieldPeriod;
    }

    /**
     * Stakes the given token ids from a given contract.
     * @param _user the user from which to transfer the token.
     * @param _token the address of the stakable token.
     * @param _tokenIds the ids of the tokens to stake.
     * @dev the contract must be approved to transfer that token first.
     *      the address must be a stakable token.
     */
    function _bulkStakeFor(
        address _user,
        address _token,
        uint256[] memory _tokenIds
    ) internal {
        uint256 lastStaked = _lastStaked(_user, _token);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721(_token).transferFrom(_user, address(this), _tokenIds[i]);

            StakedToken memory token;
            token.owner = _user;
            token.stakeTimestamp = block.timestamp;

            if (lastStaked == 0)
                stakableTokenAttributes[_token].firstStaked[_user] = _tokenIds[i];
            else
                stakableTokenAttributes[_token]
                    .stakedTokens[lastStaked]
                    .nextToken = _tokenIds[i];

            lastStaked = _tokenIds[i];
            stakableTokenAttributes[_token].stakedTokens[_tokenIds[i]] = token;
        }
    }

    /**
     * Retrieves the dividend owed on a particular token with a given timestamp.
     * @param _tokenAttributes the attributes of the token provided.
     * @param _timestamp the timestamp at which the token was staked.
     * @return the dividend owed for that specific token.
     */
    function _tokenDividend(
        StakableTokenAttributes storage _tokenAttributes,
        uint256 _timestamp
    ) internal view returns (uint256) {
        if (_timestamp == 0) return 0;

        uint256 periods = (block.timestamp - _timestamp) /
            _tokenAttributes.yieldPeriod;

        uint256 dividend = 0;
        uint256 i = 0;
        for (i; i < periods; i++) {
            uint256 uncappedYield = _tokenAttributes.minYield +
                i *
                _tokenAttributes.step;

            if (uncappedYield > _tokenAttributes.maxYield) {
                dividend += _tokenAttributes.maxYield;
                i++;
                break;
            }
            dividend += uncappedYield;
        }

        dividend += (periods - i) * _tokenAttributes.maxYield;

        return dividend;
    }

    /**
     * Gets the total amount of tokens staked for the given user in the given contract.
     * @param _user the user whose stakes are being counted.
     * @param _token the address of the contract whose staked tokens we are skimming.
     * @dev does not check if the token address is stakable.
     */
    function _totalStaked(address _user, address _token)
        internal
        view
        returns (uint256)
    {
        uint256 tokenCount = 0;

        uint256 nextToken = stakableTokenAttributes[_token].firstStaked[_user];
        if (nextToken == 0) return 0;

        while (nextToken != 0) {
            tokenCount++;
            nextToken = stakableTokenAttributes[_token]
                .stakedTokens[nextToken]
                .nextToken;
        }

        return tokenCount;
    }

    /**
     * Gets the last token ID staked by the user.
     * @param _user the user whose last stake is being found.
     * @param _token the address of the contract whose staked tokens we are skimming.
     * @dev does not check if the token address is stakable.
     */
    function _lastStaked(address _user, address _token)
        internal
        view
        returns (uint256)
    {
        uint256 nextToken = stakableTokenAttributes[_token].firstStaked[_user];
        if (nextToken == 0) return 0;

        while (
            stakableTokenAttributes[_token].stakedTokens[nextToken].nextToken !=
            0
        ) {
            nextToken = stakableTokenAttributes[_token]
                .stakedTokens[nextToken]
                .nextToken;
        }

        return nextToken;
    }

    /**
     * Gets the token before the given token id owned by the user.
     * @param _user the user staked tokens are being traversed.
     * @param _token the address of the contract whose staked tokens we are skimming.
     * @param _tokenId the id of the token whose precedent we are looking for
     * @dev does not check if the token address is stakable. throws if not found
     */
    function _tokenBefore(
        address _user,
        address _token,
        uint256 _tokenId
    ) internal view returns (uint256) {
        uint256 nextToken = stakableTokenAttributes[_token].firstStaked[_user];
        require(nextToken != 0, "None staked");

        if (nextToken == _tokenId) return 0;

        while (nextToken != 0) {
            uint256 next = stakableTokenAttributes[_token]
                .stakedTokens[nextToken]
                .nextToken;
            if (next == _tokenId) return nextToken;
            nextToken = next;
        }

        revert("Token not found");
    }

    /**
     * Gets all of the token ids that a user has staked from a given contract.
     * @param _user the user whose token ids are being analyzed.
     * @param _token the address of the token contract being analyzed.
     * @return an array of token ids staked by that user.
     * @dev does not check if the token address is stakable.
     */
    function _stakedTokenIds(address _user, address _token)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 numStaked = _totalStaked(_user, _token);
        uint256[] memory tokenIds = new uint256[](numStaked);

        if (numStaked == 0) return tokenIds;
        uint256 nextToken = stakableTokenAttributes[_token].firstStaked[_user];

        uint256 index = 0;
        while (nextToken != 0) {
            tokenIds[index] = nextToken;
            nextToken = stakableTokenAttributes[_token]
                .stakedTokens[nextToken]
                .nextToken;
            index++;
        }

        return tokenIds;
    }

    /**
     * Gets the College Credit dividend of the provided user.
     * @param _user the user whose dividend we are checking.
     * @param _token the token whose dividends we are checking.
     */
    function _dividendOf(address _user, address _token)
        internal
        view
        returns (uint256)
    {
        uint256 dividend = 0;
        uint256 nextToken = stakableTokenAttributes[_token].firstStaked[_user];

        while (nextToken != 0) {
            dividend += _tokenDividend(
                stakableTokenAttributes[_token],
                stakableTokenAttributes[_token]
                    .stakedTokens[nextToken]
                    .stakeTimestamp
            );

            nextToken = stakableTokenAttributes[_token]
                .stakedTokens[nextToken]
                .nextToken;
        }

        int256 resultantDividend = int256(dividend) +
            stakableTokenAttributes[_token].rewardModifier[_user];

        require(resultantDividend >= 0, "Underflow");
        return uint256(resultantDividend);
    }

    /**
     * Unstakes a given token id.
     * @param _token the address of the token contract that the token belongs to.
     * @param _tokenId the id of the token to unstake.
     * @dev does not check permissions.
     */
    function _unstake(address _token, uint256 _tokenId) internal {
        address owner = stakableTokenAttributes[_token]
            .stakedTokens[_tokenId]
            .owner;

        // will fail to get dividend if not staked or bad token contract
        uint256 dividend = _tokenDividend(
            stakableTokenAttributes[_token],
            stakableTokenAttributes[_token]
                .stakedTokens[_tokenId]
                .stakeTimestamp
        );

        stakableTokenAttributes[_token].rewardModifier[owner] += int256(
            dividend
        );

        // remove link in chain
        uint256 tokenBefore = _tokenBefore(owner, _token, _tokenId);
        if (tokenBefore == 0)
            stakableTokenAttributes[_token].firstStaked[
                owner
            ] = stakableTokenAttributes[_token]
                .stakedTokens[_tokenId]
                .nextToken;
        else
            stakableTokenAttributes[_token]
                .stakedTokens[tokenBefore]
                .nextToken = stakableTokenAttributes[_token]
                .stakedTokens[_tokenId]
                .nextToken;

        delete stakableTokenAttributes[_token].stakedTokens[_tokenId];

        IERC721(_token).safeTransferFrom(address(this), owner, _tokenId);
    }

    /**
     * Claims the dividend for the user.
     * @param _user the user whose rewards are being withdrawn.
     * @param _token the token from which rewards are being withdrawn.
     * @dev does not check is the user has permission to withdraw. Reverts on zero dividend.
     * @return dividend
     */
    function _withdrawRewards(address _user, address _token) internal returns (uint256) {
        uint256 dividend = _dividendOf(_user, _token);
        require(dividend > 0, "Zero dividend");

        stakableTokenAttributes[_token].rewardModifier[_user] -= int256(
            dividend
        );

        rewardToken.mint(_user, dividend);
        return dividend;
    }
}