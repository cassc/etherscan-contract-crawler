// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ERC721 Interface
interface IERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function ownerOf(uint256 _tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
}

contract Staking is ERC721Holder, Ownable, ReentrancyGuard {

    IERC721 private immutable nft;

    uint256 public currentPoolId;
    uint256 public stakingUnlock = 3600; // 3600 seconds

    bool public stakingPaused = true;

    struct Pool {
        uint256 firstTokenAllowed;
        uint256 limitPool;
        uint256 costElectricity;
        uint256 lifeTime;
        string typeMachine;
        string area;
        mapping(uint256 => ItemInfo) tokensPool;
        uint256[] ownedTokensPool;
    }

    struct ItemInfo {
        address owner;
        uint256 poolId;
        uint256 timestamp;
        string addressBTC;
    }

    struct Staker {
        mapping(uint256 => ItemInfo) tokensStaker;
        uint256[] ownedTokensStaker;
    }

    /// @notice mapping of a pool to an id.
    mapping(uint256 => Pool) public poolInfos;

    /// @notice mapping of a staker to its wallet.
    mapping(address => Staker) private stakers;


    /* ********************************** */
    /*             Events                 */
    /* ********************************** */

    event Staked721(address indexed owner, uint256 itemId, uint256 poolId);    /// @notice event emitted when a user has staked a nft.
    event Unstaked721(address indexed owner, uint256 itemId, uint256 poolId);    /// @notice event emitted when a user has unstaked a nft.
    event UnlockPeriodUpdated(uint256 period);    /// @notice event emitted when the unlock period is updated.
    event PauseUpdated(bool notPaused);    /// @notice event emitted when the pause is updated.
    event PoolInformationsUpdated(uint256 poolId, uint256 firstTokenAllowed, uint256 limitPool, uint256 costElectricity, uint256 lifetime, string typeMachine, string area); /// @notice event emitted when the informations in a pool has been updated.
    event PoolCreated(uint256 nextPoolId, uint256 firstTokenAllowed, uint256 limitPool, uint256 costElectricity, uint256 lifeTime, string typeMachine, string area); /// @notice event emitted when a pool has been created.

    /* ********************************** */
    /*             Constructor            */
    /* ********************************** */

    /*
    * @notice Constructor of the contract Staking.
    * @param IERC721 _nft : Address of the mint contract.
    */
    constructor(IERC721 _nft) {
        nft = _nft;
        currentPoolId++;
        poolInfos[currentPoolId].firstTokenAllowed = 1;
        poolInfos[currentPoolId].limitPool = 500;
        poolInfos[currentPoolId].costElectricity = 750;
        poolInfos[currentPoolId].lifeTime = 1799164996;
        poolInfos[currentPoolId].typeMachine = "Bitcoin 25/TH";
        poolInfos[currentPoolId].area = "Iceland";
    }

    /* ********************************** */
    /*             Modifier               */
    /* ********************************** */

    /*
    * @notice Safety checks common to each stake function.
    * @param uint256 _poolId : Id of the pool where to stake.
    * @param string calldata _addressBTC : BTC address that will receive the rewards.
    */
    modifier stakeModifier(uint256 _poolId, string calldata _addressBTC, uint256 _amount) {
        require(!stakingPaused, "Staking unavailable at the moment");
        require(_poolId > 0 && _poolId <= currentPoolId, "Pool doesn't exist");

        require(
            poolInfos[_poolId].ownedTokensPool.length + _amount <= poolInfos[_poolId].limitPool, "Pool limit exceeded"
        );
        _;
    }

    /* ********************************** */
    /*              Pools                 */
    /* ********************************** */

    /*
    * @notice Allows to create a new pool.
    * @param uint256 _firstTokenAllowed : First NFT accepted, only ids greater than or equal to this value will be accepted.
    * @param uint256 _limitPool : Maximum amount of NFT stakable in the pool.
    * @param uint256 _costElectricity : The average cost of electricity.
    * @param uint256 _lifeTime : The life time of the machine.
    * @param string calldata _typeMachine : The type of machine.
    * @param string calldata _area : The area where the machine is located.
    */
    function createPool(uint256 _firstTokenAllowed, uint256 _limitPool, uint256 _costElectricity, uint256 _lifeTime, string calldata _typeMachine, string calldata _area) external onlyOwner {
        currentPoolId++;
        poolInfos[currentPoolId].firstTokenAllowed = _firstTokenAllowed;
        poolInfos[currentPoolId].limitPool = _limitPool;
        poolInfos[currentPoolId].costElectricity = _costElectricity;
        poolInfos[currentPoolId].lifeTime = _lifeTime;
        poolInfos[currentPoolId].typeMachine = _typeMachine;
        poolInfos[currentPoolId].area = _area;
        emit PoolCreated(currentPoolId, _firstTokenAllowed, _limitPool, _costElectricity, _lifeTime, _typeMachine, _area);
    }

    /*
    * @notice Change the one pool information's.
    * @param uint256 _poolId : Id of the pool.
    * @param uint256 _firstTokenAllowed : First NFT accepted, only ids greater than or equal to this value will be accepted.
    * @param uint256 _limitPool : Maximum amount of NFT stakable in the pool.
    * @param uint256 _costElectricity : The average cost of electricity.
    * @param string calldata _area : The area where the machine is located.
    */
    function setPoolInformation(uint256 _poolId, uint256 _firstTokenAllowed, uint256 _limitPool, uint256 _costElectricity,uint256 _lifeTime,string calldata _typeMachine, string calldata _area) external onlyOwner {
        require(_poolId > 0 && _poolId <= currentPoolId, "Pool doesn't exist");
        poolInfos[_poolId].firstTokenAllowed = _firstTokenAllowed;
        poolInfos[_poolId].limitPool = _limitPool;
        poolInfos[_poolId].costElectricity = _costElectricity;
        poolInfos[_poolId].lifeTime = _lifeTime;
        poolInfos[_poolId].typeMachine = _typeMachine;
        poolInfos[_poolId].area = _area;
        emit PoolInformationsUpdated(_poolId, _firstTokenAllowed, _limitPool, _costElectricity, _lifeTime, _typeMachine, _area);
    }

    /* ********************************** */
    /*              Staking               */
    /* ********************************** */

    /*
    * @notice Private function used in stakeERC721.
    * @param uint256 _poolId : Id of the pool where to stake.
    * @param uint256 _tokenId : Id of the token to stake.
    * @param string calldata : _addressBTC BTC address that will receive the rewards.
    */
    function _stakeERC721(uint256 _poolId, uint256 _tokenId, string calldata _addressBTC) private {
        require(_tokenId >= poolInfos[_poolId].firstTokenAllowed, "NFT can't be staked in this pool");
        require(nft.ownerOf(_tokenId) == msg.sender, "Not owner");
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);
        Staker storage staker = stakers[msg.sender];
        Pool storage pool = poolInfos[_poolId];
        ItemInfo memory info = ItemInfo(
            msg.sender,
            _poolId,
            block.timestamp,
            _addressBTC
        );
        staker.tokensStaker[_tokenId] = info;
        staker.ownedTokensStaker.push(_tokenId);
        pool.tokensPool[_tokenId] = info;
        pool.ownedTokensPool.push(_tokenId);
        emit Staked721(msg.sender, _tokenId, _poolId);
    }

    /*
    * @notice Allows to stake an NFT in the desired quantity.
    * @param uint256 _poolId : Id of the pool where to stake.
    * @param uint256 _tokenId : Id of the token to stake.
    * @param string calldata _addressBTC : BTC address that will receive the rewards.
    */
    function stakeERC721(uint256 _poolId, uint256 _tokenId, string calldata _addressBTC) external nonReentrant stakeModifier(_poolId, _addressBTC, 1) {
        _stakeERC721(_poolId, _tokenId, _addressBTC);
    }

    /*
    * @notice Allows to stake several NFT in the desired quantity.
    * @param uint256 _poolId : Id of the pool where to stake.
    * @param uint256[] _tokenIds : List of IDs of the tokens to stake.
    * @param string calldata _addressBTC : BTC address that will receive the rewards.
    */
    function batchStakeERC721(uint256 _poolId, uint256[] calldata _tokenIds, string calldata _addressBTC) external nonReentrant stakeModifier(_poolId, _addressBTC, _tokenIds.length) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _stakeERC721(_poolId, _tokenIds[i], _addressBTC);
        }
    }

    /*
    * @notice Changes the minimum period before it's possible to unstake.
    * @param uint256 _period : New minimum period before being able to unstake.
    */
    function setUnlockPeriod(uint256 _period) external onlyOwner {
        stakingUnlock = _period;
        emit UnlockPeriodUpdated(stakingUnlock);
    }

    /* ********************************** */
    /*              Unstaking             */
    /* ********************************** */

    /*
    * @notice Private function used in unstakeERC721.
    * @param uint256 _tokenId : Id of the token to unstake.
    */
    function _unstakeERC721(uint256 _tokenId) private {
        require(stakers[msg.sender].tokensStaker[_tokenId].timestamp != 0, "No NFT staked");
        uint256 elapsedTime = block.timestamp - stakers[msg.sender].tokensStaker[_tokenId].timestamp;
        require(stakingUnlock < elapsedTime, "Unable to unstake before the minimum period");
        Staker storage staker = stakers[msg.sender];
        uint256 poolId = staker.tokensStaker[_tokenId].poolId;
        Pool storage pool = poolInfos[poolId];

        delete staker.tokensStaker[_tokenId];
        delete pool.tokensPool[_tokenId];

        for (uint256 i = 0; i < staker.ownedTokensStaker.length; i++) {
            if (staker.ownedTokensStaker[i] == _tokenId) {
                staker.ownedTokensStaker[i] = staker.ownedTokensStaker[
                staker.ownedTokensStaker.length - 1
                ];
                staker.ownedTokensStaker.pop();
                break;
            }
        }

        for (uint256 i = 0; i < pool.ownedTokensPool.length; i++) {
            if (pool.ownedTokensPool[i] == _tokenId) {
                pool.ownedTokensPool[i] = pool.ownedTokensPool[
                pool.ownedTokensPool.length - 1
                ];
                pool.ownedTokensPool.pop();
                break;
            }
        }

        nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        emit Unstaked721(msg.sender, _tokenId, poolId);
    }


    /*
    * @notice Allows you to unstake an NFT staked.
    * @param uint256 _tokenId : Id of the token to unstake.
    */
    function unstakeERC721(uint256 _tokenId) external nonReentrant {
        _unstakeERC721(_tokenId);
    }

    /*
    * @notice Allows you to unstake several NFT staked.
    * @param uint256[] _tokenIds : Ids of the token to unstake.
    */
    function batchUnstakeERC721(uint256[] calldata _tokenIds) external nonReentrant {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _unstakeERC721(_tokenIds[i]);
        }
    }

    /* ********************************** */
    /*              Getters               */
    /* ********************************** */


    /*
    * @notice Returns the ItemInfo of a specific NFT staked by a user.
    * @param address _user : Address of the user.
    * @param uint256 : _tokenId Id of the token.
    * @return ItemInfo memory : Details of tokenId.
    */
    function getStakedERC721(address _user, uint256 _tokenId) external view returns (ItemInfo memory) {
        return stakers[_user].tokensStaker[_tokenId];
    }

    /*
    * @notice Returns the list of NFT staked by a user.
    * @param address _user : Address of the user.
    * @return uint256[] : List of tokenIds.
    */
    function getAllStakedERC721(address _user) external view returns (uint256[] memory) {
        return stakers[_user].ownedTokensStaker;
    }

    /*
    * @notice Returns the ItemInfo of a specific NFT staked in a pool.
    * @param uint256 _poolId : Id of the pool.
    * @param uint256 _tokenId : Id of the token.
    * @return ItemInfo : Details of tokenId.
    */
    function getStakedERC721Pool(uint256 _poolId, uint256 _tokenId) external view returns (ItemInfo memory) {
        return poolInfos[_poolId].tokensPool[_tokenId];
    }


    /*
    * @notice Returns the list of NFT staked in a pool.
    * @param uint256 _poolId : Id of the pool.
    * @return uint256[] : List of tokenIds.
    */
    function getAllStakedERC721Pool(uint256 _poolId) external view returns (uint256[] memory) {
        return poolInfos[_poolId].ownedTokensPool;
    }

    /*
    * @notice Returns the list of NFT staked in a pool by a user.
    * @param uint256 _poolId : Id of the pool.
    * @param address _user : Address of the user.
    * @return uint256[] : List of tokenIds.
    */
    function getAllStakedERC721PoolByUser(uint256 _poolId, address _user) external view returns (uint256[] memory) {
        uint totalSupply = nft.totalSupply();
        uint256[] memory tmpList = new uint256[](totalSupply);
        uint256 counter = 0;

        for (uint256 i = 0; i < totalSupply; i++) {
            if (poolInfos[_poolId].tokensPool[i].owner == _user) {
                tmpList[counter] = i;
                counter++;
            }
        }

        uint256[] memory stakedList = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            stakedList[i] = tmpList[i];
        }

        return stakedList;
    }

    /* ********************************** */
    /*               Pauser               */
    /* ********************************** */

    /*
    * @notice Changes the variable notPaused to allow or not the staking.
    */
    function toggleStakingPaused() external onlyOwner {
        stakingPaused = !stakingPaused;
        emit PauseUpdated(stakingPaused);
    }

}