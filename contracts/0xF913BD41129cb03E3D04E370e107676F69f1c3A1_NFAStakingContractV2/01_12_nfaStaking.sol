// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NFAStakingContractV2 is Initializable, ERC1155HolderUpgradeable, ERC721HolderUpgradeable{

    using SafeMath for uint256;

    struct stake{
        uint256[] _tokenIDs;
        uint256 poolOneStartedAt;
    }

    struct lockNFT{
        uint256 lockAt;
        uint256 unlockAt;
    }

    uint256 private _totalNFTsStaked;
    uint256 private _totalActiveStakers;
    uint256 public poolOneRewardsCount;
    mapping(address => stake) private _stakers;
    
    IERC721Upgradeable private stakeCollection;
    bool public poolOne;
    bool public poolTwo;
    bool public poolThree;

    mapping(address => mapping(uint256 => lockNFT)) public _nftLocker;
    mapping(address => uint256) private _breedingPoints;
    mapping(address => mapping(uint256 => bool)) private _isbreedClaimed;
    uint256 private _totalActiveStakersPoolOne;
    

    function initialize(IERC721Upgradeable _collection) external initializer{
        poolOne = true;
        stakeCollection = _collection;
    }

    function staker(address _user) external view returns( stake memory ){
        return _stakers[_user];
    }

    function name() external pure returns (string memory){
        return "Non Financial Advisors Locker";
    }

    function collection() external view returns( IERC721Upgradeable ){
        return stakeCollection;
    }

    function totalNFTsLocked() external view returns( uint256 ){
        return _totalNFTsStaked;
    }

    function totalActiveStakersPoolOne() external view returns( uint256 ){
        return _totalActiveStakersPoolOne;
    }

    function totalActiveStakers() external view returns( uint256 ){
        return _totalActiveStakers;
    }

    function stakePoolOne(uint256[] memory _tokenids) external{
        uint256 oldStkLength = _stakers[msg.sender]._tokenIDs.length;
        for(uint8 i = 0; i<_tokenids.length; i++){
            require(stakeCollection.ownerOf(_tokenids[i]) == msg.sender, "not owned");
            stakeCollection.safeTransferFrom(msg.sender, address(this), _tokenids[i], "");
            _stakers[msg.sender]._tokenIDs.push(_tokenids[i]);
            _nftLocker[msg.sender][_tokenids[i]] = lockNFT(block.timestamp,0);
        }
        _totalNFTsStaked += _tokenids.length;
        if(oldStkLength == 0){
            _totalActiveStakers++;
        }
        if(_stakers[msg.sender].poolOneStartedAt == 0){
            if(_stakers[msg.sender]._tokenIDs.length >= 5){
                if(_totalActiveStakersPoolOne < 200){
                    _stakers[msg.sender].poolOneStartedAt = block.timestamp;
                    _totalActiveStakersPoolOne++;
                }
            }
        }
    }

    function eligiblePoolOne(address _user) external view returns (bool, uint256){
        uint256 poolStartAt = _stakers[_user].poolOneStartedAt;
        if(poolStartAt > 0){
            uint256 LockedDays = (block.timestamp - _stakers[_user].poolOneStartedAt).div(1 days);
            if(LockedDays > 30){
                return (true,LockedDays);
            }
        }
        return (false,0);
    }

    function claimableBreeds(address _user) external view returns (uint256, uint256[] memory){
        uint256[] memory stakedNFTS = _stakers[_user]._tokenIDs;
        uint256[] memory _days = new uint256[](stakedNFTS.length);
        uint8 claimablePoints;
        uint256 _tempDays;
        if(stakedNFTS.length > 0){
            for(uint8 i = 0; i<stakedNFTS.length; i++){
                _tempDays = (block.timestamp - _nftLocker[_user][stakedNFTS[i]].lockAt).div(1 days);
                _days[i] = (_tempDays);
                if(_tempDays >= 30){
                    if(!_isbreedClaimed[_user][stakedNFTS[i]]){
                        claimablePoints++;
                    }
                }
            }
        }
        return (claimablePoints,_days);
    }

    function claimPoolOne() external {
        uint256[] memory stakedNFTS = _stakers[msg.sender]._tokenIDs;
        require(stakedNFTS.length > 0 , "No NFTs Staked");
        uint8 _any;
        for(uint8 i = 0; i<stakedNFTS.length; i++){
            if((block.timestamp - _nftLocker[msg.sender][stakedNFTS[i]].lockAt).div(1 days) >= 30){
                if(!_isbreedClaimed[msg.sender][stakedNFTS[i]]){
                    _any++;
                    _breedingPoints[msg.sender]++;
                    poolOneRewardsCount++;
                    _isbreedClaimed[msg.sender][stakedNFTS[i]] = true;
                }
            }
        }
        require(_any > 0 , "No Points To Claim");
    }

    function endStakePoolOne() external{
        uint256[] memory stakedNFTS = _stakers[msg.sender]._tokenIDs;
        require(stakedNFTS.length > 0 , "No NFTs Staked");
        for(uint8 i = 0; i<stakedNFTS.length; i++){
            stakeCollection.safeTransferFrom(address(this), msg.sender, stakedNFTS[i], "");
            _nftLocker[msg.sender][stakedNFTS[i]].unlockAt = block.timestamp;
            if((block.timestamp - _nftLocker[msg.sender][stakedNFTS[i]].lockAt).div(1 days) >= 30){
                if(!_isbreedClaimed[msg.sender][stakedNFTS[i]]){
                    _breedingPoints[msg.sender]++;
                    _isbreedClaimed[msg.sender][stakedNFTS[i]] = true;
                }
            }
        }
        delete _stakers[msg.sender]._tokenIDs;
        _totalNFTsStaked -= stakedNFTS.length;
        _totalActiveStakers--;
        if(_stakers[msg.sender].poolOneStartedAt > 0){
            _stakers[msg.sender].poolOneStartedAt = 0;
            _totalActiveStakersPoolOne--;
        }
        
    }
}