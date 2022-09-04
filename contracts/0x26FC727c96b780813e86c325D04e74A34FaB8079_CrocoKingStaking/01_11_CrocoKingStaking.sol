// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CrocoKingStaking is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address public rewardToken;
    address public collectionAddress;
    uint256 public minTokenReward = 12 ether;
    bool public getRewardPaused;

    uint256[3] public defaultPackageIndex = [0, 1, 2];
    uint256[3] public defaultLockTime = [90 days, 180 days, 270 days];
    uint256[3] public defaultReward = [11.66 ether, 9.5 ether, 7 ether];

    struct Stake {
        uint256 tokenId;
        uint256 stakeTime;
        uint256 lastTimeClaimed;
        uint256 totalClaimed;
        uint256 index;
    }

    mapping(address => Stake[]) public userStakes;
    mapping(uint256 => address) public usersToken;

    constructor(
        address _collectionAddress,
        address _rewardToken
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        collectionAddress = _collectionAddress;
        rewardToken = _rewardToken;
    }

    modifier onlyAdmin {
        require(hasRole(ADMIN_ROLE, msg.sender), "! Only Admin");
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(IERC721(collectionAddress).ownerOf(_tokenId) == msg.sender, 'Staking: Only Token Owner');
        _;
    }

    modifier onlyTokenStaker(uint256 _tokenId) {
        require(usersToken[_tokenId] == msg.sender, 'Only Token Staker');
        _;
    }

    function stake(
        uint256 _tokenId,
        uint256 _packageIndex
    ) public onlyTokenOwner(_tokenId) {
        bool validIndex;
        for (uint i = 0; i < defaultPackageIndex.length; i++) {
            if (defaultPackageIndex[i] == _packageIndex) validIndex = true;
        }
        require(validIndex, 'Invalid Package');

        IERC721(collectionAddress).transferFrom(msg.sender, address(this), _tokenId);
        userStakes[msg.sender].push(Stake({
            tokenId: _tokenId,
            stakeTime: block.timestamp,
            lastTimeClaimed: block.timestamp,
            totalClaimed: 0,
            index: _packageIndex
        }));
        usersToken[_tokenId] = msg.sender;
    }

    function earned(uint256 _tokenId) public view returns(uint256 reward){
        address user = usersToken[_tokenId];
        if(user == address(0)) return reward;
        for (uint i = 0; i < userStakes[user].length; i++) {
            if (userStakes[user][i].tokenId == _tokenId) {
                uint256 rewardPerSecond = defaultReward[userStakes[user][i].index] /
                                          defaultLockTime[userStakes[user][i].index];
                uint256 claimedPeriod = block.timestamp - userStakes[user][i].lastTimeClaimed;
                uint256 reward_ = rewardPerSecond * claimedPeriod;
                uint256 remainingReward = defaultReward[userStakes[user][i].index] - userStakes[user][i].totalClaimed;
                if (reward_ <= remainingReward) {
                    reward = reward_;
                } else {
                    reward = remainingReward;
                }
                break;
            }
        }
    }

    function getReward(
        uint256 _tokenId
    ) public onlyTokenStaker(_tokenId){
        require(getRewardPaused, 'Paused');
        uint256 reward = earned(_tokenId);
        require(reward >= minTokenReward, 'Less Than Min Token');
        IERC20(rewardToken).transfer(msg.sender, reward);
        address user = usersToken[_tokenId];
        for (uint i = 0; i < userStakes[user].length; i++) {
            if (userStakes[user][i].tokenId == _tokenId) {
                userStakes[user][i].lastTimeClaimed = block.timestamp;
                userStakes[user][i].totalClaimed += reward;
                break;
            }
        }
    }

    function unstake(uint256 _tokenId) public onlyTokenStaker(_tokenId) {
        address user = usersToken[_tokenId];
        for (uint i = 0; i < userStakes[user].length; i++) {
            if (userStakes[user][i].tokenId == _tokenId) {
                require(block.timestamp - userStakes[user][i].stakeTime >=
                        defaultLockTime[userStakes[user][i].index],
                        'Period Time Limitation');
                uint256 totalReward = defaultReward[userStakes[user][i].index] - userStakes[user][i].totalClaimed;
                if (totalReward > 0) {
                    IERC20(rewardToken).transfer(msg.sender, totalReward);
                }
                IERC721(collectionAddress).transferFrom(address(this), msg.sender, _tokenId);
                userStakes[user][i] = userStakes[user][userStakes[user].length - 1];
                userStakes[user].pop();
                delete usersToken[_tokenId];
                break;
            }
        }
    }

    function setUsdtAddress(address _rewardToken) public onlyAdmin {
        rewardToken = _rewardToken;
    }

    function setGetRewardPause(bool _newVal) public onlyAdmin {
        getRewardPaused = _newVal;
    }

    function setCollectionAddress(address _collection) public onlyAdmin {
        collectionAddress = _collection;
    }

    function setMinTokenReward(uint256 _minReward) public onlyAdmin {
        minTokenReward = _minReward;
    }

    function setDefaultLockTime(uint256[3] memory _lockTimes) public onlyAdmin {
        defaultLockTime = _lockTimes;
    }

    function setDefaultReward(uint256[3] memory _rewards) public onlyAdmin {
        defaultReward = _rewards;
    }

    function userInfo(address user) public view returns(Stake[] memory stakes){
        stakes = new Stake[](userStakes[user].length);
        for (uint i = 0; i < stakes.length; i++) {
            stakes[i] = userStakes[user][i];
        }
    }

    function adminWithdrawTokens(address _tokenAddr, address _to, uint _amount) public onlyAdmin{
        require(_to != address(0), "0x0");
        if(_tokenAddr == address(0)){
            payable(_to).transfer(_amount);
        }else{
            IERC20(_tokenAddr).transfer(_to, _amount);
        }
    }

    function adminWithdrawNfts(address _to, uint256[] memory _tokenIds) public onlyAdmin{
        for (uint i = 0; i < _tokenIds.length; i++) {
            IERC721(collectionAddress).transferFrom(address(this), _to, _tokenIds[i]);
            //remove from usersTokens
            delete usersToken[_tokenIds[i]];
            address user = usersToken[_tokenIds[i]];
            for (uint j = 0; j < userStakes[user].length; j++) {
                if (userStakes[user][j].tokenId == _tokenIds[i]) {
                    userStakes[user][j] = userStakes[user][userStakes[user].length - 1];
                    userStakes[user].pop();
                    break;
                }
            }
        }
    }

}