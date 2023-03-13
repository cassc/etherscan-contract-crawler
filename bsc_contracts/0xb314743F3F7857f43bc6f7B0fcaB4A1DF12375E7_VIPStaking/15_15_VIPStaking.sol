// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol" ;
import "@openzeppelin/contracts/security/Pausable.sol" ;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol" ;
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol" ;
import "../Common/MyMath.sol";

contract VIPStaking is Pausable, ReentrancyGuard, AccessControlEnumerable {

    // MIT token contract address
    IERC20 public MITToken ;

    // min mit precision
    uint256 public precision = 1 ether ;

    // min stake period
    uint64 public minStakePriod = 30 * 24 * 60 * 60 ;

    using MyMath for uint256 ;

    // stake info
    struct StakeInfo {
        // stake amount
        uint256 amount ;

        // stake time
        uint64 stakeTime ;
    }

    // account => stakeInfo
    mapping(address => StakeInfo) public accountStakeInfo ;

    //////////////////////////////////////
    //           events
    //////////////////////////////////////
    event VipStakeEvent(address owner, uint256 amount, uint256 total, uint256 time) ;
    event VipUnStakeEvent(address owner) ;

    constructor (address mitToken) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        MITToken = IERC20(mitToken) ;
    }

    function setMitToken(address mitToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MITToken = IERC20(mitToken) ;
    }

    function setPrecision(uint256 _precision) external onlyRole(DEFAULT_ADMIN_ROLE) {
        precision = _precision ;
    }

    function setMinStakePriod(uint64 _minStakePriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minStakePriod = _minStakePriod ;
    }

    function backStakeInfo(address [] memory addrs) external onlyRole(DEFAULT_ADMIN_ROLE){
        for(uint256 i = 0; i < addrs.length; i++) {
            unStake(addrs[i]) ;
        }
    }

    function vipStake(uint256 amount) external nonReentrant whenNotPaused {
        require(amount % precision == 0 && amount > 0, "Staking precision is incorrect") ;

        // transfer
        bool isOk = MITToken.transferFrom(_msgSender(), address(this), amount) ;
        require(isOk, "Mit token transfer failed") ;

        if(accountStakeInfo[_msgSender()].amount > 0) {
            accountStakeInfo[_msgSender()].amount = accountStakeInfo[_msgSender()].amount.add(amount, "stake amount add failed") ;
            accountStakeInfo[_msgSender()].stakeTime = uint64(block.timestamp) ;
        } else {
            accountStakeInfo[_msgSender()] = StakeInfo({ amount: amount, stakeTime:  uint64(block.timestamp) }) ;
        }
        emit VipStakeEvent(_msgSender(), amount, accountStakeInfo[_msgSender()].amount, block.timestamp) ;
    }

    function vipUnStake() external nonReentrant whenNotPaused {
        require(accountStakeInfo[_msgSender()].amount > 0, "Insufficient pledge") ;
        require(block.timestamp - accountStakeInfo[_msgSender()].stakeTime >= minStakePriod, "The pledge period is not over yet") ;

        unStake(_msgSender()) ;
    }

    function unStake(address account) private {
        if(accountStakeInfo[account].amount > 0) {
            bool isOk = MITToken.transfer(account, accountStakeInfo[account].amount) ;
            require(isOk, "Return mit transfer failed") ;

            delete accountStakeInfo[account] ;
            emit VipUnStakeEvent(account) ;
        }
    }
}