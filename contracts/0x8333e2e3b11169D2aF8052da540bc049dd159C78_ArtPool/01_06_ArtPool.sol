// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import './libraries/TimeConverter.sol';
import './logic/StakingPoolLogic.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract ArtPool {

    using StakingPoolLogic for PoolData;

    constructor(address rewardAsset_) public {
        rewardAsset = IERC20(rewardAsset_);
        _admin = msg.sender;
    }

    address public _admin;

    struct PoolData {
        string poolName;
        uint256 rewardPerSecond;
        uint256 rewardIndex;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 totalPrincipal;
        uint256 lastUpdateTimestamp;
        uint256 totalNFT;
        uint256 voteMax;
        bool isFullLockup;
        uint256 lockupTimestamp;
        uint256 totalVoted;
        uint256 voteStartTimestamp;
        uint256 voteEndTimestamp;
        bool hasTaxCollected;
        mapping(address => WhitelistNFT) whitelistNFT;
        mapping(address => uint256) userIndex;
        mapping(address => uint256) userReward;
        mapping(address => uint256) userPrincipal;
        mapping(address => uint256) userVoted;
        mapping(address => UserNFT) userNFT;
        NFT[] votedNFT;
    }

    struct UserNFT {
        mapping(address => uint256[]) stakedTokens;
        // mapping(address => mapping(uint256 => uint256)) indexOfToken;
        mapping(address => mapping(uint256 => uint256)) startStakeTimestamp;
        uint256 amountStaked;
    }

    struct WhitelistNFT {
        bool isWhitelisted;
        bool isAllWhitelisted;
        uint256 multiplier;
        mapping(uint256 => bool) tokenIsWhitelisted;
        mapping(uint256 => VoteInfo) voteInfo;
    }

    struct VoteInfo {
        address[] voters;
        mapping(address => uint256) votingCount;
        uint256 voted;
    }

    struct NFT {
        address nftAddress;
        uint256 tokenId;
    }

    mapping(uint8 => PoolData) internal _rounds;

    mapping(address => mapping(uint256 => address)) public tokenOwners;

    uint8 public lastRound;

    IERC20 public rewardAsset;

    event InitRound(
        uint256 rewardPerSecond,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint8 roundNumber
    );

    event Stake(
        address indexed user,
        address nftAddress,
        uint256 tokenId,
        uint8 round
    );

    event Unstake(
        address indexed user,
        address nftAddress,
        uint256 tokenId,
        uint8 round
    );

    event Claim(
        address indexed user,
        uint256 reward,
        uint8 round
    );

    event Vote(
        address indexed user,
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint8 round
    );

    function setVoteTime(uint8 round, uint256 startTimestamp, uint256 endTimestamp) external onlyAdmin {
        PoolData storage poolData = _rounds[round];

        poolData.voteStartTimestamp = startTimestamp;
        poolData.voteEndTimestamp = endTimestamp;
    }

    function initNewRound(
        string calldata poolName,
        bool isFullLockup,
        uint256 lockupTimestamp,
        uint256 rewardPerSecond,
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 duration,
        uint256 voteMax
    ) external onlyAdmin {
        uint256 roundstartTimestamp = TimeConverter.toTimestamp(year, month, day, hour);

        uint8 newRound = lastRound + 1;
        (uint256 startTimestamp, uint256 endTimestamp) = _rounds[newRound].initRound(
            poolName,
            isFullLockup,
            lockupTimestamp,
            rewardPerSecond,
            roundstartTimestamp,
            duration,
            voteMax
        );

        lastRound = newRound;

        emit InitRound(
            rewardPerSecond,
            startTimestamp,
            endTimestamp,
            newRound
        );
    }

    modifier onlyAdmin() {
        if (msg.sender != _admin) revert("OnlyAdmin");
        _;
    }

    function getVoteData(uint8 round, address nftAddress, uint256 tokenId)
    external
    view
    returns(
        uint256 totalVoters,
        uint256 totalVoted
    )
    {
        PoolData storage poolData = _rounds[round];
        WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];
        VoteInfo storage voteInfo = whitelistNFT.voteInfo[tokenId];

        return(
        voteInfo.voters.length,
        voteInfo.voted
        );
    }

    function getUserVoteData(uint8 round, address nftAddress, uint256 tokenId, address user)
    external
    view
    returns(
        uint256 totalVoted,
        uint256 totalVoter,
        uint256 userVoted
    )
    {
        PoolData storage poolData = _rounds[round];
        WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];
        VoteInfo storage voteInfo = whitelistNFT.voteInfo[tokenId];

        return (
        voteInfo.voters.length,
        voteInfo.voted,
        voteInfo.votingCount[user]
        );
    }

    function getPoolData(uint8 round)
    external
    view
    returns (
        string memory poolName,
        bool isFullLockup,
        uint256 lockupTimestamp,
        uint256 rewardPerSecond,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 totalNFT,
        uint256 voteMax,
        uint256 voteStartTimestamp,
        uint256 voteEndTimestamp
    )
    {
        PoolData storage poolData = _rounds[round];

        return (
        poolData.poolName,
        poolData.isFullLockup,
        poolData.lockupTimestamp,
        poolData.rewardPerSecond,
        poolData.startTimestamp,
        poolData.endTimestamp,
        poolData.totalNFT,
        poolData.voteMax,
        poolData.voteStartTimestamp,
        poolData.voteEndTimestamp
        );
    }

    function getPoolDataETC(uint8 round)
    external
    view
    returns(
        uint256 totalVoted,
        uint256 totalPrincipal,
        bool hasTaxCollected,
        uint256 votedNFTs
    )
    {
        PoolData storage poolData = _rounds[round];

        return (
        poolData.totalVoted,
        poolData.totalPrincipal,
        poolData.hasTaxCollected,
        poolData.votedNFT.length
        );
    }

    function getUserData(uint8 round, address user)
    external
    view
    returns (
        uint256 userIndex,
        uint256 userReward,
        uint256 userPrincipal,
        uint256 amountStaked,
        uint256 amountVoted
    )
    {
        PoolData storage poolData = _rounds[round];
        UserNFT storage userNFT = poolData.userNFT[user];

        return (
        poolData.userIndex[user],
        poolData.userReward[user],
        poolData.userPrincipal[user],
        userNFT.amountStaked,
        poolData.userVoted[user]
        );
    }

    function getUserReward(address user, uint8 round) external view returns (uint256) {
        PoolData storage poolData = _rounds[round];
        return poolData.getUserReward(user);
    }

    function getUserDataNFT(uint8 round, address user, address nftAddress)
    external
    view
    returns (
        uint256[] memory tokenId
    )
    {
        PoolData storage poolData = _rounds[round];
        UserNFT storage userNFT = poolData.userNFT[user];

        return (userNFT.stakedTokens[nftAddress]);
    }

    function getWhitelistNFTData(uint8 round, address nftAddress)
    external
    view
    returns (
        bool isWhitelisted,
        bool isAllWhitelisted,
        uint256 multiplier
    )
    {
        PoolData storage poolData = _rounds[round];
        WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];

        return (
        whitelistNFT.isWhitelisted,
        whitelistNFT.isAllWhitelisted,
        whitelistNFT.multiplier
        );
    }

    function checkWhiteListed(uint8 round, address nftAddress, uint256 tokenId)
    external
    view
    returns(
        bool isWhitelisted
    )
    {
        PoolData storage poolData = _rounds[round];
        WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];

        if(whitelistNFT.isWhitelisted){
            if(whitelistNFT.isAllWhitelisted) {
                return true;
            }else {
                return whitelistNFT.tokenIsWhitelisted[tokenId];
            }
        }else {
            return false;
        }
    }

    function addWhitelist(uint8 round, address nftAddress, bool isAllWhitelisted, uint256[] calldata whitelistedToken, uint256 multiplier) external onlyAdmin {
        PoolData storage poolData = _rounds[round];
        WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];

        if(poolData.whitelistNFT[nftAddress].isWhitelisted) revert("Already whitelisted");

        whitelistNFT.isWhitelisted = true;
        whitelistNFT.isAllWhitelisted = isAllWhitelisted;
        whitelistNFT.multiplier = multiplier;
        for(uint256 i = 0; i < whitelistedToken.length; i ++ ){
            whitelistNFT.tokenIsWhitelisted[whitelistedToken[i]] = true;
        }
    }

    function claim(uint8 round) external {
        _claim(msg.sender, round);
    }

    function stake(uint8 round, address nftAddress, uint256 tokenId) external {
        _stake(msg.sender, round, nftAddress, tokenId);
    }

    function batchStake(uint8 round, address nftAddress, uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _stake(msg.sender, round, nftAddress, tokenIds[i]);
        }
    }

    function unstake(uint8 round, address nftAddress, uint256 tokenId) external {
        _unstake(msg.sender, round, nftAddress, tokenId);
    }

    function batchUnstake(uint8 round, address nftAddress, uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _unstake(msg.sender, round, nftAddress, tokenIds[i]);
        }
    }

    function _stake(address userAddress, uint8 round, address nftAddress, uint256 tokenId) internal {
        PoolData storage poolData = _rounds[round];
        UserNFT storage user = poolData.userNFT[userAddress];
        WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];

        if (round == 0) revert("StakingNotInitiated");

        if (poolData.endTimestamp < block.timestamp || poolData.startTimestamp > block.timestamp)
            revert("NotInRound");

        if(!whitelistNFT.isWhitelisted)
            revert("NotWhitelistedNFT");

        if(!whitelistNFT.isAllWhitelisted){
            if(!whitelistNFT.tokenIsWhitelisted[tokenId])
                revert("NotWhiteListedToken");
        }

        uint256 amount = whitelistNFT.multiplier > 0 ? whitelistNFT.multiplier : 1;

        poolData.updateStakingPool(round, userAddress);

        // nft 전송
        IERC721(nftAddress).transferFrom(userAddress, address(this), tokenId);

        poolData.userPrincipal[userAddress] = add(poolData.userPrincipal[userAddress], amount);
        poolData.totalPrincipal = add(poolData.totalPrincipal, amount);
        poolData.totalNFT = add(poolData.totalNFT, 1);


        user.stakedTokens[nftAddress].push(tokenId);
        // user.indexOfToken[nftAddress][tokenId] = user.stakedTokens[nftAddress].length;
        user.amountStaked += 1;


        user.startStakeTimestamp[nftAddress][tokenId] = block.timestamp;
        tokenOwners[nftAddress][tokenId] = msg.sender;

        emit Stake(
            msg.sender,
            nftAddress,
            tokenId,
            round
        );
    }

    function _unstake(address userAddress, uint8 round, address nftAddress, uint256 tokenId) internal {
        require(tokenOwners[nftAddress][tokenId] == userAddress, "NotOwnerOfThisToken");

        PoolData storage poolData = _rounds[round];
        UserNFT storage user = poolData.userNFT[userAddress];
        WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];

        if(poolData.isFullLockup){
            if(poolData.endTimestamp > block.timestamp) {
                revert ("LockupNotFinished");
            }
        }

        if(poolData.lockupTimestamp > 0 && block.timestamp < poolData.endTimestamp) {
            if(block.timestamp - user.startStakeTimestamp[nftAddress][tokenId] < poolData.lockupTimestamp){
                revert ("LockupNotFinished");
            }
        }

        poolData.updateStakingPool(round, msg.sender);

        for (uint256 i; i<user.stakedTokens[nftAddress].length; i++) {
            if (user.stakedTokens[nftAddress][i] == tokenId) {
                user.stakedTokens[nftAddress][i] = user.stakedTokens[nftAddress][user.stakedTokens[nftAddress].length - 1];
                user.stakedTokens[nftAddress].pop();
                break;
            }
        }

        delete tokenOwners[nftAddress][tokenId];

        user.amountStaked -= 1;
        poolData.totalNFT = sub(poolData.totalNFT, 1);

        uint256 amount = whitelistNFT.multiplier > 0 ? whitelistNFT.multiplier : 1;

        poolData.userPrincipal[userAddress] = sub(poolData.userPrincipal[userAddress], amount);
        poolData.totalPrincipal = sub(poolData.totalPrincipal, amount);

        IERC721(nftAddress).transferFrom(
            address(this),
            userAddress,
            tokenId
        );

        emit Stake(
            msg.sender,
            nftAddress,
            tokenId,
            round
        );
    }

    function _claim(address user, uint8 round) internal {
        PoolData storage poolData = _rounds[round];

        uint256 reward = poolData.getUserReward(user);

        if (reward == 0) revert("ZeroReward");

        poolData.userReward[user] = 0;
        poolData.userIndex[user] = poolData.getRewardIndex();

        rewardAsset.transfer(user, reward);

        emit Claim(user, reward, round);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function vote(uint8 round, address nftAddress, uint256 tokenId, uint256 amount) external {
        PoolData storage poolData = _rounds[round];
        WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];
        VoteInfo storage voteInfo = whitelistNFT.voteInfo[tokenId];

        if(tokenOwners[nftAddress][tokenId] == address(0)) revert("NotStakedNFT");

        if (poolData.voteEndTimestamp < block.timestamp || poolData.voteStartTimestamp > block.timestamp)
            revert("NotInVoteTime");

        if(amount > poolData.voteMax) revert("GreaterThanMaximum");

        uint userTotalVotingCount = poolData.userVoted[msg.sender];

        uint256 userVotingCount = voteInfo.votingCount[msg.sender];

        if(add(amount, userTotalVotingCount) > poolData.voteMax) revert("ExceedsMaximum");

        if(userVotingCount > 0) {
            // if(add(amount, userVotingCount) > poolData.voteMax) revert("ExceedsMaximum");
        }else {
            voteInfo.voters.push(msg.sender);
        }

        if(voteInfo.voted <= 0) {
            poolData.votedNFT.push(NFT({
            nftAddress: nftAddress,
            tokenId: tokenId
            }));
        }

        voteInfo.votingCount[msg.sender] = add(userVotingCount, amount);
        voteInfo.voted = add(voteInfo.voted, amount);
        poolData.totalVoted = add(poolData.totalVoted, amount);
        poolData.userVoted[msg.sender] = add(userTotalVotingCount, amount);

        rewardAsset.transferFrom(msg.sender, address(this), amount);

        emit Vote(
            msg.sender,
            nftAddress,
            tokenId,
            amount,
            round
        );
    }

    function forcedTransferFrom(address to, address nftAddress, uint256 tokenId) external onlyAdmin {
        IERC721(nftAddress).transferFrom(address(this), to, tokenId);
    }

    function withdraw() external onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken() external onlyAdmin {
        uint256 balance = rewardAsset.balanceOf(address(this));
        rewardAsset.transfer(msg.sender, balance);
    }

    function finishVote(uint8 round, address taxCollector, uint256 taxRate) external onlyAdmin {
        PoolData storage poolData = _rounds[round];

        if(poolData.hasTaxCollected) revert("AlreadyCollectedTax");
        if(taxRate > 100 ) revert("RateCannotOver100");
        if(poolData.endTimestamp > block.timestamp) revert("NotFinishedRound");

        uint256 totalVoted = poolData.totalVoted;
        uint256 tax = totalVoted * taxRate / 100;
        uint256 totalPrize = totalVoted - tax;

        uint256 winningVoteCount = 0;
        uint256 winningIndex = 0;

        for (uint256 i = 0; i < poolData.votedNFT.length; i++) {
            address nftAddress = poolData.votedNFT[i].nftAddress;
            uint256 tokenId = poolData.votedNFT[i].tokenId;

            WhitelistNFT storage whitelistNFT = poolData.whitelistNFT[nftAddress];
            VoteInfo storage voteInfo = whitelistNFT.voteInfo[tokenId];

            if (voteInfo.voted > winningVoteCount) {
                winningVoteCount = voteInfo.voted;
                winningIndex = i;

                if(voteInfo.voted * 2 >= totalVoted){
                    break;
                }
            }
        }

        address winnerNFT = poolData.votedNFT[winningIndex].nftAddress;
        uint256 winnerTokenId = poolData.votedNFT[winningIndex].tokenId;

        WhitelistNFT storage winnerNFTInfo = poolData.whitelistNFT[winnerNFT];
        VoteInfo storage winnerVoteInfo = winnerNFTInfo.voteInfo[winnerTokenId];

        for (uint256 v = 0 ; v < winnerVoteInfo.voters.length; v ++){
            address voter = winnerVoteInfo.voters[v];
            uint256 userVotingCount = winnerVoteInfo.votingCount[voter];

            uint256 prize = ((userVotingCount * 10000) / winnerVoteInfo.voted) * totalPrize / 10000;
            rewardAsset.transfer(voter, prize);
        }

        rewardAsset.transfer(taxCollector, tax);

        poolData.hasTaxCollected = true;
    }

    function getWinners(uint8 round)
    external
    view
    returns(
        uint256 votedNFTs,
        uint256 voted,
        uint256 winningVoteCount,
        address winnerNFT,
        uint256 winnerTokenId,
        address[] memory winners
    )
    {
        PoolData storage poolData = _rounds[round];

        uint256 totalVoted = poolData.totalVoted;

        winningVoteCount = 0;
        uint256 winningIndex = 0;


        votedNFTs = poolData.votedNFT.length;

        for (uint256 i = 0; i < poolData.votedNFT.length; i++) {
            address nftAddress = poolData.votedNFT[i].nftAddress;
            uint256 tokenId = poolData.votedNFT[i].tokenId;

            VoteInfo storage voteInfo = poolData.whitelistNFT[nftAddress].voteInfo[tokenId];

            voted = voteInfo.voted;

            if (voteInfo.voted > winningVoteCount) {
                winningVoteCount = voteInfo.voted;
                winningIndex = i;

                if(voteInfo.voted * 2 >= totalVoted){
                    break;
                }
            }
        }


        winnerNFT = poolData.votedNFT[winningIndex].nftAddress;
        winnerTokenId = poolData.votedNFT[winningIndex].tokenId;

        WhitelistNFT storage winnerNFTInfo = poolData.whitelistNFT[winnerNFT];
        VoteInfo storage winnerVoteInfo = winnerNFTInfo.voteInfo[winnerTokenId];

        return (
            votedNFTs,
            voted,
            winningVoteCount,
            winnerNFT,
            winnerTokenId,
            winnerVoteInfo.voters
        );
    }
}