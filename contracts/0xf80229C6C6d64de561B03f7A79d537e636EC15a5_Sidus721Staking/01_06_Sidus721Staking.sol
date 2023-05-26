// SPDX-License-Identifier: MIT
// Sidus Heroes Staking 
pragma solidity 0.8.11;
import "Ownable.sol";
import "IERC721.sol";
import "IERC721Receiver.sol";



contract Sidus721Staking is Ownable, IERC721Receiver {
    //using ECDSA for bytes32;
    // pool struct
    struct PoolInfo {
        address contractAddress;  // erc721 contract address
        uint256 period;           // stake period.cant claim during stake!
        uint256 activeAfter;      // date of start staking
        uint256 closedAfter;      // date of end staking
    }

    // user struct
    struct UserInfo {
        uint256 tokenId;         // subj
        uint256 stakedAt;        // moment of stake
        uint256 period;          // period in seconds
        uint256 unStaked;        // date of unstaked 
    }

    PoolInfo[] public  pools;
    
    // maping from user  to poolId to tokenId
    mapping(address => mapping(uint256 => UserInfo[])) public userStakes;

    /// Emit in case of any changes: stake or unstake for now
    /// 0 - Staked
    /// 1 - Unstaked 
    event StakeChanged(
        address indexed user, 
        uint256 indexed poolId, 
        uint8   indexed changeType,
        uint256 tokenId, 
        uint256 timestamp
    );


    function deposit(uint256 poolId, uint256 tokenId) external {
        _deposit(msg.sender, poolId, tokenId);
    }

    function depositBatch(uint256 poolId, uint256[] memory tokenIds) external {
         _depositBatch(msg.sender, poolId, tokenIds);
    }

    function withdraw(uint256 _poolId, uint256 _tokenId) external {
        // lets get tokenId index
        uint256 _tokenIndex = _getTokenIndexByTokenId(msg.sender, _poolId, _tokenId);
        _withdraw(msg.sender, _poolId, _tokenIndex); 
    }

    function withdrawBatch(uint256 _poolId) external {
        for (uint256 i = 0; i < userStakes[msg.sender][_poolId].length; i ++) {
            if (userStakes[msg.sender][_poolId][i].unStaked == 0) {
                _withdraw(msg.sender, _poolId, i);        
            }
        }
    }

    
    function getUserStakeInfo(address _user, uint256 _poolId) public view returns(UserInfo[] memory) {
        return userStakes[_user][_poolId];
    }

    function getUserStakeByIndex(address _user, uint256 _poolId, uint256 _index) public view returns(UserInfo memory) {
        return userStakes[_user][_poolId][_index];
    }

    function getUserStakeCount(address _user, uint256 _poolId) public view returns(uint256) {
        return userStakes[_user][_poolId].length;
    }

    function getUserActiveStakesCount(address _user, uint256 _poolId) public view returns(uint256) {
        return _getUserActiveStakesCount(_user, _poolId);
    } 

    ////////////////////////////////////////////////////////////
    /////////// Admin only           ////////////////////////////
    ////////////////////////////////////////////////////////////
    function addPool(
        address _contract, 
        uint256 _period, 
        uint256 _activeAfter, 
        uint256 _closedAfter
    ) public onlyOwner {
        pools.push(
            PoolInfo({
              contractAddress: _contract,  // erc721 contract address
              period: _period,             // stake period.cant claim during stake!
              activeAfter: _activeAfter,   // date of start staking
              closedAfter: _closedAfter    // date of end staking
            })
        );
    }

    function editPool(
        uint256 _poolId, 
        address _contract, 
        uint256 _period, 
        uint256 _activeAfter, 
        uint256 _closedAfter
    ) public onlyOwner {
        pools[_poolId].contractAddress = _contract;    // erc721 contract address
        pools[_poolId].period = _period;               // stake period.cant claim during stake!
        pools[_poolId].activeAfter = _activeAfter;     // date of start staking
        pools[_poolId].closedAfter = _closedAfter;     // date of end staking
    }


    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }


     ////////////////////////////////////////////////////////////
    /////////// internal           /////////////////////////////
    ////////////////////////////////////////////////////////////

    function _depositBatch(address _user, uint256 _poolId, uint256[] memory _tokenId) internal {
        for(uint256 i = 0; i < _tokenId.length; i ++) {
            _deposit(_user, _poolId, _tokenId[i]);
        }
    }

    function _deposit(address _user, uint256 _poolId, uint256 _tokenId) internal {
        require(pools[_poolId].activeAfter < block.timestamp, "Pool not active yet");
        require(pools[_poolId].closedAfter > block.timestamp, "Pool is closed");
        //TokenInfo[] storage theS =  userStakes[_user][_poolId];
        userStakes[_user][_poolId].push(
            UserInfo({
               tokenId: _tokenId,
               stakedAt:block.timestamp,      // moment of stake
               period: pools[_poolId].period, // period in seconds
               unStaked: 0                    // date of unstaked(close stake flag) 
        }));
        IERC721 nft = IERC721(pools[_poolId].contractAddress);
        nft.transferFrom(address(_user), address(this), _tokenId);
        emit StakeChanged(_user, _poolId, 0, _tokenId, block.timestamp);
    }

    function _withdraw(address _user, uint256 _poolId, uint256 _tokenIndex) internal {
        require(
            userStakes[_user][_poolId][_tokenIndex].stakedAt 
            + userStakes[_user][_poolId][_tokenIndex].period < block.timestamp,
            "Sorry, too early for withdraw"
        );
        require(
            userStakes[_user][_poolId][_tokenIndex].unStaked == 0,
            "Already unstaked"
        );

        userStakes[_user][_poolId][_tokenIndex].unStaked = block.timestamp;
        IERC721 nft = IERC721(pools[_poolId].contractAddress);
        nft.transferFrom(address(this), _user, userStakes[_user][_poolId][_tokenIndex].tokenId);
        emit StakeChanged(_user, _poolId, 1, userStakes[_user][_poolId][_tokenIndex].tokenId, block.timestamp);
    }

    function _getUserActiveStakesCount(address _user, uint256 _poolId) 
        internal 
        view 
        returns (uint256 count) 
    {
        for (uint256 i = 0; i < userStakes[_user][_poolId].length; i ++) {
            if (userStakes[_user][_poolId][i].unStaked == 0) {
                count ++;
            }
        }
    }

    function _getTokenIndexByTokenId(address _user, uint256 _poolId, uint256 _tokenId) 
        internal 
        view 
        returns (uint256) 
    {
        for (uint256 i = 0; i < userStakes[_user][_poolId].length; i ++ ) {
            if (userStakes[_user][_poolId][i].tokenId == _tokenId &&
                userStakes[_user][_poolId][i].unStaked == 0 //only active stakes
                ) 
            {
                return i;
            }
        }
        revert("Token not found");
    }
}