//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../interfaces/ITokamakStakerUpgrade.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../common/AccessibleCommon.sol";

contract StakeTONUnstaking is AccessibleCommon {
    using SafeMath for uint256;

    address public ton;
    address public wton;
    address public tos;
    address public depositManager;
    address public seigManager;
    address public layer2;
    uint256 public countStakeTons;
    mapping(uint256 => address) public stakeTons;

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "StakeTONUnstaking: zero address");
        _;
    }
    modifier avaiableIndex(uint256 _index) {
        require(_index > 0, "StakeTONUnstaking: can't use zero index");
        require(_index <= countStakeTons, "StakeTONUnstaking: exceeded maxIndex");
        _;
    }

    constructor() {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function setInfo(
        address _ton,
        address _wton,
        address _tos,
        address _depositManager,
        address _seigManager,
        address _layer2,
        uint256 _countStakeTons
    ) external onlyOwner {
        ton = _ton;
        wton = _wton;
        tos = _tos;
        depositManager = _depositManager;
        seigManager = _seigManager;
        layer2 = _layer2;
        countStakeTons = _countStakeTons;
    }

    function deleteStakeTon(uint256 _index)
        external
        onlyOwner
        avaiableIndex(_index)
    {
        delete stakeTons[_index];
    }

    function addStakeTon(uint256 _index, address addr)
        external
        onlyOwner
        avaiableIndex(_index)
    {
        stakeTons[_index] = addr;
    }

    function addStakeTons(address[] calldata _addr) external onlyOwner {
        require(_addr.length > 0, "StakeTONUnstaking: zero length");
        require(
            _addr.length == countStakeTons,
            "StakeTONUnstaking: diff countStakeTons"
        );

        for (uint256 i = 1; i <= _addr.length; i++) {
            stakeTons[i] = _addr[i - 1];
        }
    }


    function requestUnstakingLayer2All() public nonZeroAddress(layer2)  {
        (bool can, bool[] memory canRequest, bool[] memory canRequestAll) = canRequestUnstakingLayer2All();
        require(can, "StakeTONUnstaking: no available unstaking from layer2");
        for (uint256 i = 1; i <= countStakeTons; i++) {

            if(canRequestAll[i-1]) {
                ITokamakStakerUpgrade(stakeTons[i]).tokamakRequestUnStakingAll(
                    layer2
                );
            } else if(canRequest[i-1] ) {
                ITokamakStakerUpgrade(stakeTons[i]).tokamakRequestUnStaking(
                    layer2,
                    1
                );
            }
        }
    }


    function canRequestUnstakingLayer2All()
        public
        view
        nonZeroAddress(layer2)
        returns (bool can, bool[] memory canRequestUnStaking, bool[] memory canRequestUnStakingAll)
    {
        can = false;
        canRequestUnStaking = new bool[](countStakeTons);
        canRequestUnStakingAll = new bool[](countStakeTons);

        for (uint256 i = 1; i <= countStakeTons; i++) {

            if(ITokamakStakerUpgrade(stakeTons[i]).tokamakLayer2() == layer2){

                (uint256 canUnStakingAmount) = ITokamakStakerUpgrade(stakeTons[i]).canTokamakRequestUnStaking(layer2);
                (bool canUnStaking) = ITokamakStakerUpgrade(stakeTons[i]).canTokamakRequestUnStakingAll(layer2);

                if(canUnStakingAmount > 0 || canUnStaking ) {
                    if(!can) can = true;
                    if(canUnStaking) canRequestUnStakingAll[i-1] = true;
                    else canRequestUnStaking[i-1] = true;
                }

            }
        }
    }
}