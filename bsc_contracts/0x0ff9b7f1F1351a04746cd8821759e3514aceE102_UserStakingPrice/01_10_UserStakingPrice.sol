//SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

import "./interfaces/IPriceFeedData.sol";
import "./interfaces/IPancakeswapV2Pair.sol";
import "./interfaces/IStakingRewards.sol";

contract UserStakingPrice is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event PriceFeedUpdated(address priceFeedAddress);
    event WhitelistTrade(address whitelist, bool allow);

    address public kalm;
    IPriceFeedData public priceFeedData;
    address[] public pool;
    mapping(address => address) public stakingPool;
    mapping(address => bool) public whitelistTrade;

    constructor(
        address _kalm,
        address[] memory _pool,
        address[] memory _stake
    ) public {
        kalm = _kalm;
        require(_pool.length == _stake.length);
        for (uint256 i = 0; i < _pool.length; i++) {
            pool.push(_pool[i]);
            stakingPool[_pool[i]] = _stake[i];
        }
    }

    function addWhitelistTrade(address _whitelist, bool _allow) public onlyOwner
    {
        whitelistTrade[address(_whitelist)] = _allow;
        emit WhitelistTrade(_whitelist, _allow);
    }

    function setPriceFeedData(address _feed) public onlyOwner
    {
        priceFeedData = IPriceFeedData(_feed);
        emit PriceFeedUpdated(_feed);
    }

    function userStakingValue(address user) public view returns (uint256 fee, uint256 totalValue)
    {
        uint256 STEP1 = 100 * 1e18;
        uint256 STEP2 = 500 * 1e18;
        uint256 STEP3 = 1000 * 1e18;
        uint256 STEP4 = 2500 * 1e18;
        uint256 STEP5 = 5000 * 1e18;
        uint256 STEP6 = 10000 * 1e18;
        uint256 total;
        for (uint i; i < pool.length; i++) {
          uint256 userStake = _userStakingPriceUSD(pool[i], user);
          total = total.add(userStake);
        }

        if(whitelistTrade[user] == true){
          return (10000, total); // 0.01%
        }else{
          if(total <= STEP1){
            return (250000, total); // 0.25%
          }else if(STEP1 < total  && total <= STEP2){
            return (200000, total); // 0.20%
          }else if(STEP2 < total && total <= STEP3){
            return (150000, total); // 0.15%
          }else if(STEP3 < total && total <= STEP4){
            return (100000, total); // 0.10%
          }else if(STEP4 < total && total <= STEP5){
            return (50000, total); // 0.05%
          }else if(total <= STEP6){
            return (25000, total); // 0.025%
          }
        }
    }

    /* ================= Internal Function ================= */

    function _geTokenPrice(address token) internal view returns(uint256)
    {
        uint256 price;
        if(token == kalm){
            price = IPriceFeedData(priceFeedData).kalmPriceInUsd();
        }else{
            price = IPriceFeedData(priceFeedData).lpPriceInUsd(token);
        }
        return price;
    }

    function _userStakingPriceUSD(address _pool, address _user) internal view returns (uint256)
    {
        uint256 userStake = IStakingRewards(_pool).balanceOf(_user);
        uint256 userValue = userStake.mul(_geTokenPrice(stakingPool[_pool])).div(1e18);

        return userValue;
    }



}