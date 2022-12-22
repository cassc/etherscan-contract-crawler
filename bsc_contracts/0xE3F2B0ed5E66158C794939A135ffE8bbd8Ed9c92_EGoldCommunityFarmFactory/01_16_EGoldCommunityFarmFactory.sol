// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./EGoldCommunityFarm.sol";

contract EGoldCommunityFarmFactory is AccessControl {
    using SafeCast for *;
    using SafeMath for uint256;
    using Address for address;

    uint256 private ctr;

    IERC20 private baseToken;

    uint256 private tokenRate;

    address private benificiary;

    mapping(uint256 => address) private FarmList;

    event createFarmEvent( address indexed farm);

    constructor(  ) AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        ctr = 0;
    }

    //Factory Fx
    function createFarm(
        uint256 _reward,
        uint256 _startBlock,
        uint256 _endBlock,
        IERC20 _rewardToken
    ) external  {
        ctr = ctr.add(1);
        require( _startBlock > block.number , "EGoldCommunityFarmFactory : Start Block less than current block");
        require( _endBlock > _startBlock , "EGoldCommunityFarmFactory : End Block less than Start block");
        require( _endBlock > block.number , "EGoldCommunityFarmFactory : End Block less than current block");
        uint256 _rewardPerBlock = (( _reward ) / ( _endBlock - _startBlock ));
        EGoldCommunityFarm MWH = new EGoldCommunityFarm( baseToken , _rewardPerBlock , _startBlock , _rewardToken , msg.sender );
        _rewardToken.transferFrom(msg.sender , address(MWH) , _reward );
        baseToken.transferFrom(msg.sender , benificiary , tokenRate );
        FarmList[ctr] = address(MWH);
        emit createFarmEvent(address(MWH));
    }

    //Factory Fx

    function setTokenRate( uint256 _tokenRate ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenRate = _tokenRate;
    }

    function setTokenRate( IERC20 _baseToken ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseToken = _baseToken;
    }
    function setBenificiary( address _benificiary ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        benificiary = _benificiary;
    }


    function getTokenRate() external view returns (uint256) {
        return tokenRate;
    }

    function getBenificiary() external view returns (address) {
        return benificiary;
    }

    function getBaseToken() external view returns (IERC20) {
        return baseToken;
    }

    function getFarm(uint256 _ctr) external view returns (address) {
        return FarmList[_ctr];
    }

    function getCtr() external view returns (uint256) {
        return ctr;
    }
}