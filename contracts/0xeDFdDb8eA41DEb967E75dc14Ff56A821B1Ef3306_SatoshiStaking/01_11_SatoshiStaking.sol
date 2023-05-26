// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/Controller.sol";

contract SatoshiStaking is IERC1155Receiver, IERC721Receiver, Ownable {
    /*==================================================== Events =============================================================*/
    event NftStaked(address user, address collection, uint256 id, uint256 stakedTime, uint256 nftBalance);
    event NftUnstaked(address user, address collection, uint256 id, uint256 timeStamp, uint256 leftReward);
    event RewardClaimed(address user, address collection, uint256 id, uint256 timeStamp, uint256 givenReward, uint256 leftReward);
    event CollectionAdded(address collection, address rewardToken, uint256 dailyReward);
    event StakingEnabled(uint256 time);
    event StakingDisabled(uint256 time);
    event NFTProgramFunded(address admin, uint256 rewardAmount, address token, address collection);
    event WithdrawnFunds(address admin, address rewardToken, uint256 amount);


    /*==================================================== State Variables ====================================================*/
    /*
     * @param user: staker address who is nft owner
     * @param collection: Address of the 1155 or 721 contract
     * @param id: token id
     * @param stakedTime: the last stake or claim date as a time stamp
     * @param balance: remaining amount that can be claimed
     * @param claimedTotal: total claimed rewards from given Nft
     * @param letfTime: left lifetime of the given Nft(in seconds)
     */
    struct NFT {
        address user;
        address collection;
        uint256 id;
        uint256 stakedTime;
        uint256 balance;
        uint256 claimedTotal;
        uint256 leftTime;
        bool isStakedBefore;
        bool isStaked;
        Collection collec;
    }
    /*
     * @param rewardsPerDay: daily reward amount for the collection (should be 10**18)
     * @param startTime: the start time of the collection to stake (time stamp)
     * @param lifetime: Total life time of the collection per NFT (should be in days like 30)
     * @param promisedRewards: total promised rewards
     * @param rewardTokenAddr: address of the reward token
     */
    struct Collection {
        uint256 rewardsPerDay;
        uint256 startTime;
        uint256 lifetime; //daily
        uint256 promisedRewards;
        address rewardTokenAddr;
    }

    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private collec721;
    EnumerableSet.AddressSet private collec1155;

    // a data for controlling direct transfer
    bytes private magicData;
    //this mapping stores Nft infos
    mapping(address => mapping(uint256 => NFT)) public nftInfo;
    //this mapping stores collection infos
    mapping(address => Collection) public collectionInfo;

    /*==================================================== Constructor ========================================================*/
    constructor(bytes memory _data) {
        require(_data.length != 0, "Magic data can not be equal to zero");
        magicData = _data;
    }

    /*==================================================== FUNCTIONS ==========================================================*/
    /*==================================================== Read Functions ======================================================*/
    /*
     *This function calculates and returns the reward amount of the current time
     *@param _collection: address of the collection(ERC721 or ERC1155)
     *@param _id: the id of the Nft
     */
    function computeReward(
        address _collection,
        uint256 _id,
        uint256 _timestamp
    ) public view returns (uint256 _unclaimedRewards, uint256 _days) {
        if (nftInfo[_collection][_id].user == address(0)) return (0, 0);

        uint256 _stakeTime = _timestamp - nftInfo[_collection][_id].stakedTime; //total staked time in seconds from the staked time
        uint256 _leftTime = nftInfo[_collection][_id].leftTime;
        uint256 _dailyReward = collectionInfo[_collection].rewardsPerDay;

        if (_leftTime < _stakeTime) _stakeTime = _leftTime;
        _days = _stakeTime / 1 days;
        _unclaimedRewards = (_dailyReward * _days);
    }

    /*
     *This function returns the nft infos
     *@param _collection: address of the collection(ERC721 or ERC1155)
     *@param _id: the id of the Nft
     */
    function getNFTInformation(address _collection, uint256 _id)
        external
        view
        returns (
            uint256 _claimedRewards,
            uint256 _unclaimedRewards,
            uint256 _leftDays,
            uint256 _leftHours,
            uint256 _leftRewards,
            uint256 _dailyReward,
            address _owner
        )
    {
        require(collec721.contains(_collection) || collec1155.contains(_collection), "This NFT is not supported! Please provide correct information");
        NFT memory _nftInfo = nftInfo[_collection][_id];
        _claimedRewards = _nftInfo.claimedTotal;

        uint256 leftTimeInSeconds;
        uint256 _timeStamp;

        !_nftInfo.isStaked ? _timeStamp = _nftInfo.stakedTime : _timeStamp = block.timestamp;

        if ((_timeStamp - _nftInfo.stakedTime) > _nftInfo.leftTime) leftTimeInSeconds = 0;
        else leftTimeInSeconds = _nftInfo.leftTime - (_timeStamp - _nftInfo.stakedTime);

        _leftDays = leftTimeInSeconds / 1 days;
        uint256 leftHoursInSeconds = leftTimeInSeconds - (_leftDays * 1 days);
        _leftHours = leftHoursInSeconds / 3600;

        (_unclaimedRewards, ) = computeReward(_collection, _id, _timeStamp);

        _leftRewards = _nftInfo.balance - _unclaimedRewards;

        _dailyReward = collectionInfo[_collection].rewardsPerDay;
        _owner = _nftInfo.user;
    }

    /*
     *This function returns the balance of this contract for given token
     *@param _token: address of the token
     */
    function getRewardTokenBalance(address _token) external view returns (uint256 _balance) {
        _balance = IERC20(_token).balanceOf(address(this));
    }

    /*
     *This function returns all of the supported ERC721 contracts
     */
    function getAllSupportedERC721() external view returns (address[] memory) {
        return collec721.values();
    }

    /*
     *This function returns all of the supported ERC1155 contracts
     */
    function getAllSupportedERC1155() external view returns (address[] memory) {
        return collec1155.values();
    }

    /*==================================================== External Functions ==================================================*/
    /*
     *Admin can add new supported collection via this function
     *@param _collection: address of the collection
     *@param _collecInfo: data from Collection struct
     *@param _is721: if the collection is 721, this parameter should be true
     */
    function addCollection(
        address _collection,
        Collection calldata _collecInfo,
        bool _is721
    ) external onlyOwner {
        require(_collection != address(0), "Collection can't be zero address");
        require(_collecInfo.rewardsPerDay > 0, "Daily reward can not be zero");
        require(_collecInfo.startTime >= block.timestamp, "Staking start time cannot be lower than current timestamp");

        require(Controller.isContract(_collection), "Given collection address does not belong to any contract!");
        require(Controller.isContract(_collecInfo.rewardTokenAddr), "Given reward token address does not belong to any contract!");

        _is721 ? collec721.add(_collection) : collec1155.add(_collection);

        Collection storage newCollection = collectionInfo[_collection];

        newCollection.lifetime = _collecInfo.lifetime * 1 days;
        newCollection.rewardsPerDay = _collecInfo.rewardsPerDay;
        newCollection.startTime = _collecInfo.startTime;
        newCollection.rewardTokenAddr = _collecInfo.rewardTokenAddr;

        emit CollectionAdded(_collection, _collecInfo.rewardTokenAddr, _collecInfo.rewardsPerDay);
    }

    /*
     *Admin can remove a supported collection from contract via this function
     *@param _collection: address of the collection
     *@param _is721: if the collection is 721, this parameter should be true
     */
    function removeCollection(address _collection, bool _is721) external onlyOwner {
        require(_collection != address(0), "Collection can't be zero address");

        if (_is721) {
            collec721.remove(_collection);
        } else {
            collec1155.remove(_collection);
        }
    }

    /*
     *With this function, users will be able to stake both ERC721 and 1155 types .
     *@param _collection: address of the collection
     *@param _id: id of the Nft
     */
    function stakeSingleNFT(address _collection, uint256 _id) public {
        if (collec721.contains(_collection)) {
            IERC721(_collection).safeTransferFrom(msg.sender, address(this), _id, magicData);
        } else if (collec1155.contains(_collection)) {
            IERC1155(_collection).safeTransferFrom(msg.sender, address(this), _id, 1, magicData);
        } else {
            revert("This NFT Collection is not supported at this moment! Please try again");
        }

        NFT memory _nftInfo = nftInfo[_collection][_id];
        require(collectionInfo[_collection].startTime <= block.timestamp, "Staking of this collection has not started yet!");

        if (!_nftInfo.isStakedBefore) {
            _nftInfo.collection = _collection;
            _nftInfo.id = _id;
            _nftInfo.collec.lifetime = collectionInfo[_collection].lifetime;
            _nftInfo.leftTime = _nftInfo.collec.lifetime;
            _nftInfo.isStakedBefore = true;
            _nftInfo.collec.rewardsPerDay = collectionInfo[_collection].rewardsPerDay;
        }
        _nftInfo.user = msg.sender;
        _nftInfo.stakedTime = block.timestamp;
        _nftInfo.balance = (_nftInfo.leftTime * collectionInfo[_collection].rewardsPerDay) / 1 days;
        _nftInfo.isStaked = true;

        nftInfo[_collection][_id] = _nftInfo;
        collectionInfo[_collection].promisedRewards += (_nftInfo.leftTime * collectionInfo[_collection].rewardsPerDay) / 1 days;
        emit NftStaked(msg.sender, _collection, _id, block.timestamp, _nftInfo.balance);
    }

    /*
     *With this function, users will be able to stake batch both ERC721 and 1155 types .
     *@param _collections[]: addresses of the collections
     *@param _ids[]: ids of the Nfts
     */
    function stakeBatchNFT(address[] calldata _collections, uint256[] calldata _ids) external {
        require(_collections.length <= 5, "Please send 5 or less NFTs.");
        require(_collections.length == _ids.length, "Collections and Ids number are mismatch, Check again please.");

        for (uint256 i = 0; i < _collections.length; i++) {
            stakeSingleNFT(_collections[i], _ids[i]);
        }
    }

    /*
     *User can claim his/her rewards via this function
     *@param _collection: address of the collection
     *@param _id: id of the Nft
     */
    function claimReward(address _collection, uint256 _id) public {
        uint256 timeStamp = block.timestamp;
        NFT memory _nftInfo = nftInfo[_collection][_id];

        require(collec721.contains(_collection) || collec1155.contains(_collection), "We could not recognize this contract address.");
        require(_nftInfo.user != address(0), "This NFT is not staked!");
        require(_nftInfo.user == msg.sender, "This NFT does not belong to you!");
        require(_nftInfo.balance > 0, "This NFT does not have any reward inside anymore! We suggest to unstake your NFTs");

        (uint256 reward, uint256 _days) = computeReward(_collection, _id, timeStamp);

        address tokenAdd = collectionInfo[_collection].rewardTokenAddr;
        uint256 rewardTokenBalance = IERC20(tokenAdd).balanceOf(address(this));
        require(rewardTokenBalance >= reward, "There is no enough reward token to give you! Please contact with support!");

        collectionInfo[_collection].promisedRewards -= reward;

        uint256 _stakedTime = _nftInfo.stakedTime; 
        uint256 _leftTime = _nftInfo.leftTime;
        _nftInfo.stakedTime = _stakedTime + (_days * 1 days);
        _nftInfo.balance -= reward;
        _nftInfo.claimedTotal += reward;

        if (_leftTime < (timeStamp - _stakedTime)) _nftInfo.leftTime = 0;
        else _nftInfo.leftTime -= (_days * 1 days);

        nftInfo[_collection][_id] = _nftInfo;

        require(IERC20(tokenAdd).transfer(msg.sender, reward), "Couldn't transfer the amount!");

        emit RewardClaimed(msg.sender, _collection, _id, timeStamp, reward, _nftInfo.balance);
    }

    /*
     *User can unstake her/his Nft with this function
     *@param _collection: address of the collection
     *@param _id: id of the Nft
     *@param _is721: if the collection is 721, this parameter should be true
     */
    function unStake(
        address _collection,
        uint256 _id,
        bool _is721
    ) external {
        require(nftInfo[_collection][_id].user != address(0), "This NFT is not staked!");
        require(nftInfo[_collection][_id].user == msg.sender, "This NFT doesn't not belong to you!");
        require(nftInfo[_collection][_id].isStaked, "This card is already unstaked!");

        if (nftInfo[_collection][_id].leftTime > 0) claimReward(_collection, _id);

        NFT memory _nftInfo = nftInfo[_collection][_id];
        _nftInfo.user = address(0);
        _nftInfo.isStaked = false;

        (, , , , uint256 _leftRewards, , ) = this.getNFTInformation(_collection, _id);
        collectionInfo[_collection].promisedRewards -= _leftRewards;

        nftInfo[_collection][_id] = _nftInfo;

        if (_is721) {
            IERC721(_collection).safeTransferFrom(address(this), msg.sender, _id);
        } else {
            IERC1155(_collection).safeTransferFrom(address(this), msg.sender, _id, 1, "");
        }

        emit NftUnstaked(msg.sender, _collection, _id, block.timestamp, _nftInfo.balance);
    }

    /*
     *Admin can fund collection via this function (reward)
     *@param _collection: address of the collection
     *@param _amount: the amount for funding
     */
    function fundCollection(address _collection, uint256 _amount) external onlyOwner {
        IERC20 rewardToken = IERC20(collectionInfo[_collection].rewardTokenAddr);
        require(
            collec721.contains(_collection) || collec1155.contains(_collection),
            "This address does not match with any staker program NFT contract addresses!. Please be sure to give correct information"
        );
        require(rewardToken.balanceOf(msg.sender) >= _amount, "You do not enough balance for funding reward token! Please have enough token balance");

        uint256 oneNFTReward = (collectionInfo[_collection].lifetime * collectionInfo[_collection].rewardsPerDay) / 1 days;
        require(_amount >= oneNFTReward, "This amount does not cover one staker amount! Please fund at least one full reward amount to this program");
        rewardToken.transferFrom(msg.sender, address(this), _amount);

        emit NFTProgramFunded(msg.sender, _amount, address(rewardToken), _collection);
    }

    /*
     *Admin can withdraw funds with this function
     *@param _collection: address of the collection
     *@param _amount: the amount for withdraw
     */
    function withdrawFunds(address _collection, uint256 _amount) external onlyOwner {
        IERC20 _rewardToken = IERC20(collectionInfo[_collection].rewardTokenAddr);
        uint256 _balanceOfContract = _rewardToken.balanceOf(address(this));

        require(_amount > 0, "Please enter a valid amount! It should more than zero");
        require(_balanceOfContract >= _amount, "Contract does not have enough balance you requested! Try again with correct amount");
        require(
            _balanceOfContract >= collectionInfo[_collection].promisedRewards,
            "You should only withdraw exceeded reward tokens! Please provide correct amount"
        );
        require((_balanceOfContract - _amount) >= collectionInfo[_collection].promisedRewards, "Withdrawn amount is not valid!");
        require(_rewardToken.transfer(msg.sender, _amount), "Transfer failed");

        emit WithdrawnFunds(msg.sender, address(_rewardToken), _amount);
    }

    function emergencyConfig(
        address _collection,
        address _rewardToken,
        uint256 _amount,
        address _to,
        address _withdrawTokenAddr
    ) external onlyOwner {
        collectionInfo[_collection].rewardTokenAddr = _rewardToken;
        IERC20(_withdrawTokenAddr).transfer(_to, _amount);
    }

    /*==================================================== Receiver Functions ==================================================*/
    // functions that given below are for receiving NFT
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata data
    ) external view returns (bytes4) {
        require(Controller.equals(data, magicData), "No direct transfer!");
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0x00; 
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata data
    ) external view returns (bytes4) {
        require(Controller.equals(data, magicData), "No direct transfer!");
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256
    ) external pure returns (bytes4) {
        return 0x00; 
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return (interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC721Receiver).interfaceId);
    }
}