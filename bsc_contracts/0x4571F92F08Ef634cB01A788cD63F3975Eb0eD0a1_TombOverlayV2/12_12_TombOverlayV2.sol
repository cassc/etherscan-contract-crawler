// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../includes/access/Ownable.sol";
import "../includes/interfaces/IRugZombieNft.sol";
import "../includes/interfaces/IUniswapV2Router02.sol";
import "../includes/interfaces/IPriceConsumerV3.sol";
import "../includes/interfaces/IDrFrankenstein.sol";
import "../includes/token/BEP20/IBEP20.sol";

import "../includes/vrf/VRFConsumerBaseV2.sol";
import "../includes/vrf/VRFCoordinatorV2Interface.sol";import "../includes/utils/ReentrancyGuard.sol";

contract TombOverlayV2 is Ownable, VRFConsumerBaseV2, ReentrancyGuard {
    uint32 public vrfGasLimit = 50000;  // Gas limit for VRF callbacks
    uint16 public vrfConfirms = 3;      // Number of confirmations for VRF randomness returns
    uint32 public vrfWords    = 1;      // Number of random words to get back from VRF

    uint public bracketBStart = 500;      // The percentage of the pool required to be in the second bracket
    uint public bracketCStart = 1000;      // The percentage of the pool required to be in the third bracket

    struct UserInfo {
        uint256 lastNftMintDate;    // The next date the NFT is available to mint
        bool    isMinting;          // Flag for if the user is currently minting
        uint    randomNumber;       // The random number that is returned from Chainlink
    }

    struct PoolInfo {
        uint            poolId;             // The DrFrankenstein pool ID for this overlay pool
        uint256         mintingTime;        // The time it takes to mint the reward NFT
        uint256         mintTimeFromStake;  // The time it takes to mint the reward NFT based on the staking timer from DrF
        IRugZombieNft   commonReward;       // The common reward NFT
        IRugZombieNft   uncommonReward;     // The uncommon reward NFT
        IRugZombieNft   rareReward;         // The rare reward NFT
        IRugZombieNft   legendaryReward;    // The legendary reward NFT
        BracketOdds[]   odds;               // The odds brackets for the pool
    }

    struct BracketOdds {
        uint commonTop;
        uint uncommonTop;
        uint rareTop;
    }

    struct RandomRequest {
        uint poolId;
        address user;
    }

    PoolInfo[]          public  poolInfo;               // The array of pools
    IDrFrankenstein     public  drFrankenstein;         // Dr Frankenstein - the man, the myth, the legend
    IPriceConsumerV3    public  priceConsumer;          // Price consumer for Chainlink Oracle
    VRFCoordinatorV2Interface   public vrfCoordinator;  // Coordinator for requesting randomness
    address             payable treasury;               // Wallet address for the treasury
    bytes32             public  keyHash;                // The Chainlink VRF keyhash
    uint64              public  vrfSubId;               // Chainlink VRF subscription ID
    uint256             public  mintingFee;             // The fee charged in BNB to cover Chainlink costs
    IRugZombieNft       public  topPrize;               // The top prize NFT

    // Mapping of request IDs to requests
    mapping (uint => RandomRequest) public randomRequests;

    // Mapping of user info to address mapped to each pool
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    event MintNft(address indexed to, uint date, address nft, uint indexed id, uint random);
    event FulfillRandomness(uint indexed poolId, address indexed userId, uint randomNumber);

    // Constructor for constructing things
    constructor(
        address _drFrankenstein,
        address payable _treasury,
        address _priceConsumer,
        uint256 _mintingFee,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _vrfSubId,
        address _topPrize
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        drFrankenstein = IDrFrankenstein(_drFrankenstein);
        treasury = _treasury;
        priceConsumer = IPriceConsumerV3(_priceConsumer);
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        mintingFee = _mintingFee;
        keyHash = _keyHash;
        vrfSubId = _vrfSubId;
        topPrize = IRugZombieNft(_topPrize);
    }

    // Modifier to ensure a user can start minting
    modifier canStartMinting(uint _pid) {
        UserInfo memory user = userInfo[_pid][msg.sender];
        PoolInfo memory pool = poolInfo[_pid];
        IDrFrankenstein.UserInfoDrFrankenstien memory tombUser = drFrankenstein.userInfo(pool.poolId, msg.sender);
        require(_pid <= poolInfo.length - 1, 'Overlay: Pool does not exist');
        require(tombUser.amount > 0, 'Overlay: You are not staked in the pool');
        require(!user.isMinting, 'Overlay: You already have a pending minting request');
        require(block.timestamp >= (user.lastNftMintDate + pool.mintingTime) &&
            block.timestamp >= (tombUser.tokenWithdrawalDate + pool.mintTimeFromStake),
            'Overlay: Minting time has not elapsed');
        _;
    }

    // Modifier to ensure a user's pending minting request is ready
    modifier canFinishMinting(uint _pid) {
        UserInfo memory user = userInfo[_pid][msg.sender];
        require(user.isMinting && user.randomNumber > 0, 'Overlay: Minting is not ready');
        _;
    }

    // Function to add a pool
    function addPool(
        uint _poolId,
        uint256 _mintingTime,
        uint256 _mintTimeFromStake,
        address _commonNft,
        address _uncommonNft,
        address _rareNft,
        address _legendaryNft
    ) public onlyOwner() {
        poolInfo.push();
        uint id = poolInfo.length - 1;

        poolInfo[id].poolId = _poolId;
        poolInfo[id].mintingTime = _mintingTime;
        poolInfo[id].mintTimeFromStake = _mintTimeFromStake;
        poolInfo[id].commonReward = IRugZombieNft(_commonNft);
        poolInfo[id].uncommonReward = IRugZombieNft(_uncommonNft);
        poolInfo[id].rareReward = IRugZombieNft(_rareNft);
        poolInfo[id].legendaryReward = IRugZombieNft(_legendaryNft);

        // Lowest bracket: 70% common, 15% uncommon, 10% rare, 5% legendary, 0% mythic
        poolInfo[id].odds.push(BracketOdds({
        commonTop: 7000,
        uncommonTop: 8500,
        rareTop: 9500
        }));

        // Middle bracket: 50% common, 25% uncommon, 15% rare, 10% legendary, 0% mythic
        poolInfo[id].odds.push(BracketOdds({
        commonTop: 5000,
        uncommonTop: 7500,
        rareTop: 9000
        }));

        // Top bracket: 20% common, 30% uncommon, 30% rare, 20% legendary, 0% mythic
        poolInfo[id].odds.push(BracketOdds({
        commonTop: 2000,
        uncommonTop: 5000,
        rareTop: 8000
        }));
    }

    // Uses ChainLink Oracle to convert from USD to BNB
    function mintingFeeInBnb() public view returns(uint) {
        return priceConsumer.usdToBnb(mintingFee);
    }

    // Function to set the common reward NFT for a pool
    function setCommonRewardNft(uint _pid, address _nft) public onlyOwner() {
        poolInfo[_pid].commonReward = IRugZombieNft(_nft);
    }

    // Function to set the uncommon reward NFT for a pool
    function setUncommonRewardNft(uint _pid, address _nft) public onlyOwner() {
        poolInfo[_pid].uncommonReward = IRugZombieNft(_nft);
    }

    // Function to set the rare reward NFT for a pool
    function setRareRewardNft(uint _pid, address _nft) public onlyOwner() {
        poolInfo[_pid].rareReward = IRugZombieNft(_nft);
    }

    // Function to set the legendary reward NFT for a pool
    function setLegendaryRewardNft(uint _pid, address _nft) public onlyOwner() {
        poolInfo[_pid].legendaryReward = IRugZombieNft(_nft);
    }

    // Function to set the minting time for a pool
    function setMintingTime(uint _pid, uint256 _mintingTime) public onlyOwner() {
        poolInfo[_pid].mintingTime = _mintingTime;
    }

    // Function to set the mint time from staking timer for a pool
    function setMintTimeFromStake(uint _pid, uint256 _mintTimeFromStake) public onlyOwner() {
        poolInfo[_pid].mintTimeFromStake = _mintTimeFromStake;
    }

    // Function to set the price consumer
    function setPriceConsumer(address _priceConsumer) public onlyOwner() {
        priceConsumer = IPriceConsumerV3(_priceConsumer);
    }

    // Function to set the treasury address
    function setTreasury(address _treasury) public onlyOwner() {
        treasury = payable(_treasury);
    }

    // Function to set the start of the second bracket
    function setBracketBStart(uint _value) public onlyOwner() {
        bracketBStart = _value;
    }

    // Function to set the start of the third bracket
    function setBracketCStart(uint _value) public onlyOwner() {
        bracketCStart = _value;
    }

    // Function to set the minting fee
    function setmintingFee(uint256 _fee) public onlyOwner() {
        mintingFee = _fee;
    }

    // Function to change the top prize NFT
    function setTopPrize(address _nft) public onlyOwner() {
        topPrize = IRugZombieNft(_nft);
    }

    // Function to set the odds for a pool
    function setPoolOdds(
        uint _pid,
        uint _bracket,
        uint _commonTop,
        uint _uncommonTop,
        uint _rareTop
    ) public onlyOwner() {
        BracketOdds memory odds = BracketOdds({
        commonTop: _commonTop,
        uncommonTop: _uncommonTop,
        rareTop: _rareTop
        });
        poolInfo[_pid].odds[_bracket] = odds;
    }

    // Function to get the number of pools
    function poolCount() public view returns(uint) {
        return poolInfo.length;
    }

    // Function to get a user's NFT mint date
    function nftMintTime(uint _pid, address _userAddress) public view returns (uint256) {
        UserInfo memory user = userInfo[_pid][_userAddress];
        PoolInfo memory pool = poolInfo[_pid];
        IDrFrankenstein.UserInfoDrFrankenstien memory tombUser = drFrankenstein.userInfo(pool.poolId, _userAddress);

        if (tombUser.amount == 0) {
            return 2**256 - 1;
        } else if (block.timestamp >= (user.lastNftMintDate + pool.mintingTime) && block.timestamp >= (tombUser.tokenWithdrawalDate + pool.mintTimeFromStake)) {
            return 0;
        } else if (block.timestamp <= (tombUser.tokenWithdrawalDate + pool.mintTimeFromStake)) {
            return (tombUser.tokenWithdrawalDate + pool.mintTimeFromStake) - block.timestamp;
        } else {
            return (user.lastNftMintDate + pool.mintingTime) - block.timestamp;
        }
    }

    // Function to start minting a NFT
    function startMinting(uint _pid) public payable nonReentrant canStartMinting(_pid) returns (uint) {
        require(msg.value >= mintingFeeInBnb(), 'Minting: Insufficient BNB for minting fee');
        UserInfo storage user = userInfo[_pid][msg.sender];

        safeTransfer(treasury, msg.value);

        user.isMinting = true;
        user.randomNumber = 0;

        RandomRequest memory request = RandomRequest(_pid, msg.sender);
        uint id = vrfCoordinator.requestRandomWords(keyHash, vrfSubId, vrfConfirms, vrfGasLimit, vrfWords);
        randomRequests[id] = request;
        return id;
    }

    // Function to finish minting a NFT
    function finishMinting(uint _pid) public canFinishMinting(_pid) returns (uint, uint) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        IDrFrankenstein.PoolInfoDrFrankenstein memory tombPool = drFrankenstein.poolInfo(pool.poolId);
        IDrFrankenstein.UserInfoDrFrankenstien memory tombUser = drFrankenstein.userInfo(pool.poolId, msg.sender);

        if (block.timestamp < (tombUser.tokenWithdrawalDate + pool.mintTimeFromStake)) {
            user.isMinting = false;
            require(false, 'Overlay: Stake change detected - minting cancelled');
        }

        IBEP20 lptoken = IBEP20(tombPool.lpToken);

        uint poolTotal = lptoken.balanceOf(address(drFrankenstein));
        uint percentOfPool = calcBasisPoints(poolTotal, tombUser.amount);
        BracketOdds memory userOdds;

        if (percentOfPool < bracketBStart) {
            userOdds = pool.odds[0];
        } else if (percentOfPool < bracketCStart) {
            userOdds = pool.odds[1];
        } else {
            userOdds = pool.odds[2];
        }

        uint rarity;
        IRugZombieNft nft;
        if (user.randomNumber <= userOdds.commonTop) {
            nft = pool.commonReward;
            rarity = 0;
        } else if (user.randomNumber <= userOdds.uncommonTop) {
            nft = pool.uncommonReward;
            rarity = 1;
        } else if (user.randomNumber <= userOdds.rareTop) {
            nft = pool.rareReward;
            rarity = 2;
        } else if (user.randomNumber == 10000) {
            nft = topPrize;
            rarity = 3;
        } else {
            nft = pool.legendaryReward;
            rarity = 3;
        }

        uint tokenId = nft.reviveRug(msg.sender);
        user.lastNftMintDate = block.timestamp;
        user.isMinting = false;
        user.randomNumber = 0;
        emit MintNft(msg.sender, block.timestamp, address(nft), tokenId, user.randomNumber);
        return (rarity, tokenId);
    }

    // Function to handle Chainlink VRF callback
    function fulfillRandomWords(uint _requestId, uint[] memory _randomNumbers) internal override {
        RandomRequest memory request = randomRequests[_requestId];
        uint randomNumber = (_randomNumbers[0] % 10000) + 1;
        userInfo[request.poolId][request.user].randomNumber = randomNumber;
        emit FulfillRandomness(request.poolId, request.user, randomNumber);
    }

    // Get basis points (percentage) of _portion relative to _amount
    function calcBasisPoints(uint _amount, uint  _portion) public pure returns(uint) {
        if(_portion == 0 || _amount == 0) {
            return 0;
        } else {
            uint _basisPoints = (_portion * 10000) / _amount;
            return _basisPoints;
        }
    }

    // Must be called with in function with ReentrancyGuard
    function safeTransfer(address _recipient, uint _amount) private {
        (bool _success, ) = _recipient.call{value: _amount}("");
        require(_success, "Transfer failed.");
    }
}