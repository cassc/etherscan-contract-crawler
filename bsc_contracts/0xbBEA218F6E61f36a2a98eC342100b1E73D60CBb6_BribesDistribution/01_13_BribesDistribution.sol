// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import './interfaces/IBribeDistribution.sol';
import './interfaces/IGaugeDistribution.sol';
import './interfaces/IVoter.sol';
import './interfaces/IPair.sol';

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import 'hardhat/console.sol';

contract BribesDistribution is OwnableUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    address[] public pairs;
    address public voter;
    
    mapping(address => bool) public isPair;
    mapping(address => bool) public isAllowed;
   
    constructor() {}
    
    function initialize(address _voter) initializer public {
        __Ownable_init();
        voter = _voter;
    }
   

    function distributeLPFees() external {
        require(msg.sender == owner() || isAllowed[msg.sender]);
        uint i = 0;
        uint len = pairs.length;
        uint _tempBalance = 0;

        address _pair;
        address _gauge;
        address oldIntBribe;
        address newIntBribe;
        address tokenA;
        address tokenB;
        address underlyingLP;

        for(i; i < len; i++){
            _pair = pairs[i];
            _gauge = IVoter(voter).gauges(_pair);
            oldIntBribe = IGaugeDistribution(_gauge).internal_bribe();
            newIntBribe = IVoter(voter).internal_bribes(_gauge);
            underlyingLP = IGaugeDistribution(_gauge).TOKEN();
            (tokenA, tokenB) = IPair(underlyingLP).tokens();

            if(_gauge != address(0) && oldIntBribe != address(0) && newIntBribe != address(0)){
                try IGaugeDistribution(_gauge).claimFees() {}
                catch {}

                if(tokenA != address(0)) {
                    _tempBalance = IERC20Upgradeable(tokenA).balanceOf(oldIntBribe);
                    if(_tempBalance > 0){
                        IBribeDistribution(oldIntBribe).recoverERC20(tokenA, _tempBalance);
                        IERC20Upgradeable(tokenA).approve(newIntBribe, 0);
                        IERC20Upgradeable(tokenA).approve(newIntBribe, _tempBalance);
                        IBribeDistribution(newIntBribe).notifyRewardAmount(tokenA, _tempBalance);
                    }
                }
                if(tokenB != address(0)) {
                    _tempBalance = IERC20Upgradeable(tokenB).balanceOf(oldIntBribe);
                    if(_tempBalance > 0){
                        IBribeDistribution(oldIntBribe).recoverERC20(tokenB, _tempBalance);
                        IERC20Upgradeable(tokenB).approve(newIntBribe, 0);
                        IERC20Upgradeable(tokenB).approve(newIntBribe, _tempBalance);
                        IBribeDistribution(newIntBribe).notifyRewardAmount(tokenB, _tempBalance);
                    }
                }
            }
        }
    }



    function _addPair(address _pair) internal {
        require(isPair[_pair] == false);
        require(_pair != address(0));
        pairs.push(_pair);
        isPair[_pair] = true;
    }
    function addPair(address _pair) external onlyOwner {
        _addPair(_pair);
    }
    
    function addPairs(address[] memory _pairs) external onlyOwner {
        uint i;
        uint len = _pairs.length;
        for(i= 0; i < len; i++){
            _addPair(_pairs[i]);
        }
    }

    function removePair(address _pair) external onlyOwner {
        uint i;
        uint len = pairs.length;
        for(i= 0; i < len; i++){
            if(pairs[i] == _pair){
                address _lastPair = pairs[len - 1];
                pairs[i] = _lastPair;
                pairs.pop();
                isPair[_pair] = false;
                break;
            }
        }
    }

    function setVoter(address _voter) external onlyOwner {
        require(_voter != address(0));
        voter = _voter;
    }

    function setBribeOwner(address _newOwner, address _pair) external onlyOwner {
        address _gauge = IVoter(voter).gauges(_pair);
        address oldIntBribe = IGaugeDistribution(_gauge).internal_bribe();
        console.log('pair: ', _pair);
        console.log('_gauge:' , _gauge);
        console.log('oldb:', oldIntBribe);
        IBribeDistribution(oldIntBribe).setOwner(_newOwner);
        
    }

    function setAllowed(address _allowed) external onlyOwner {
        isAllowed[_allowed] = true;
    }
    function removeAllowed(address _allowed) external onlyOwner {
        isAllowed[_allowed] = false;
    }




}