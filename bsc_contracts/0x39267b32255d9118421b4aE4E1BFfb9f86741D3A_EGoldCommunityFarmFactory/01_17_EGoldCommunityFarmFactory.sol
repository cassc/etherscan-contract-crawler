// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./EGoldCommunityFarm.sol";

contract EGoldCommunityFarmFactory is AccessControl,ReentrancyGuard {
    using SafeCast for *;
    using SafeMath for uint256;
    using Address for address;

    uint256 private ctr;

    IERC20 private baseToken; // Fee Token used to create farm

    mapping(uint256 => address) private FarmList;

    mapping(address => bool) private Farms;

    mapping(address => mapping ( address => bool )) public ActiveUsers;

    event createEvent( address indexed farm);

    event userAdd( address indexed farm , address indexed _user);

    modifier onlyFarms(){
        require(Farms[msg.sender] == true ,"EGoldCommunityFarmFactory : Not Valid Farm");
        _;
    }

    constructor(  ) AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        ctr = 0;
    }

    //Factory Fx
    function create(
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock
    ) external nonReentrant {
        ctr = ctr.add(1);
        EGoldCommunityFarm MWH = new EGoldCommunityFarm( _rewardToken, baseToken, _rewardPerBlock, _startBlock, msg.sender );
        FarmList[ctr] = address(MWH);
        Farms[address(MWH)] = true;
        emit createEvent(address(MWH));
    }

    //Factory Fx


    //Registry Fx
    function addUser( address _farm , address _user ) external onlyFarms {
        ActiveUsers[_farm][_user] = true;
        emit userAdd( _farm , _user );
    }


    //Registry Fx
    function setBaseToken( IERC20 _baseToken ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseToken = _baseToken;
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