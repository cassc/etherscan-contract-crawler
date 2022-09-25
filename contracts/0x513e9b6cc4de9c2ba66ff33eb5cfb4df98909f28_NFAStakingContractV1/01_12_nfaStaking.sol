// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NFAStakingContractV1 is Initializable, ERC1155HolderUpgradeable, ERC721HolderUpgradeable{

    using SafeMath for uint256;

    struct stake{
        uint256[] _tokenIDs;
        uint256 poolOneStartedAt;
        uint256[] breedIDs;
    }

    uint256 private _totalNFTsStaked;
    uint256 private _totalActiveStakers;
    uint256 public poolOneRewardsCount;
    mapping(address => stake) private _stakers;
    IERC721Upgradeable private stakeCollection;
    bool public poolOne;
    bool public poolTwo;
    bool public poolThree;
    

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

    function totalActiveStakers() external view returns( uint256 ){
        return _totalActiveStakers;
    }

    function stakePoolOne(uint256[] memory _tokenids) external{
        for(uint8 i = 0; i<_tokenids.length; i++){
            require(stakeCollection.ownerOf(_tokenids[i]) == msg.sender, "not owned");
            stakeCollection.safeTransferFrom(msg.sender, address(this), _tokenids[i], "");
            _stakers[msg.sender]._tokenIDs.push(_tokenids[i]);
        }
        _totalNFTsStaked += _tokenids.length;
        if(_stakers[msg.sender].poolOneStartedAt == 0){
            if(_stakers[msg.sender]._tokenIDs.length >= 5){
                _stakers[msg.sender].poolOneStartedAt = block.timestamp;
                _totalActiveStakers++;
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

    function endStakePoolOne() external{
        uint256[] memory stakedNFTS = _stakers[msg.sender]._tokenIDs;
        require(stakedNFTS.length > 0 , "No NFTs Staked");
        for(uint8 i = 0; i<stakedNFTS.length; i++){
            stakeCollection.safeTransferFrom(address(this), msg.sender, stakedNFTS[i], "");
        }
        delete _stakers[msg.sender]._tokenIDs;
        if(_stakers[msg.sender].poolOneStartedAt > 0){
            _stakers[msg.sender].poolOneStartedAt = 0;
            _totalActiveStakers--;
            _totalNFTsStaked -= stakedNFTS.length;
        }
        
    }
}