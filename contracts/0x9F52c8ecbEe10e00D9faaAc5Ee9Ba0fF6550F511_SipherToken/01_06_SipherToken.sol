//SPDX-License-Identifier: MIT
/*
This Contract is coded and developed by Vihali Technology MTV Company Limited and is entirely transferred to Dopa JSC Limited under the Contract for Software Development Services. Accordingly, the ownership and all intellectual property rights including but not limited to rights which arise in the course of or in connection with the Contract shall belong to and are the sole property of Dopa JSC Limited
*/
pragma solidity ^0.8.7;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract SipherToken is ERC20, Ownable {
    uint256 public constant DECIMALS = 10**18;
    uint256 public constant MAX_SUPPLY = 1_000_000_000*DECIMALS;
    uint256 public constant GAMEPLAY_INCENTIVES_AND_MARKETING_FUND = 304_000_000*DECIMALS;
    uint256 public immutable START_TIME; //= 1638378000
    
    uint256 private _released;
    uint256 private _noScheduledReleased;
    uint256 private _claimAmount;
    uint256 private _claimTimeStamp;

    event RequestRelease(uint amount, uint releaseTime);
    
    constructor(
        string memory name,
        string memory symbol,
        uint256 startTime
    ) ERC20(name, symbol) {
        START_TIME= startTime;
    }
    
    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }
    
     function _releasableAmount(uint256 timeStamp) private view returns(uint256){
        uint256 vestingPoint = (timeStamp - START_TIME)/2635200;
        if (vestingPoint < 3) {
            uint256 vestingOffset =  55000000*DECIMALS;
            return vestingOffset + vestingPoint * (7727273 * DECIMALS) - _released;
        } else if (vestingPoint < 12) {
            uint256 vestingOffset =  70454546 * DECIMALS;
            return vestingOffset + (vestingPoint - 2) *( 7977273 * DECIMALS ) - _released;
        } else if (vestingPoint < 15) {
            uint256 vestingOffset =  142250003 * DECIMALS;
            return vestingOffset + (vestingPoint - 11) * (250000 * DECIMALS) - _released;
        } else if (vestingPoint == 15) {
            uint256 vestingOffset =  143000003 * DECIMALS;
            return vestingOffset - _released;
        } else if (vestingPoint < 30) {
            uint256 vestingOffset =  143000003 *DECIMALS;
            return vestingOffset + (vestingPoint-15)*(19472222*DECIMALS)-_released;
        } else if (vestingPoint <34) {
            uint256 vestingOffset =  415611111*DECIMALS;
            return vestingOffset + (vestingPoint-29)*(25305556*DECIMALS)-_released;
        } else if (vestingPoint <40) {
            uint256 vestingOffset =  516833335*DECIMALS;
            return vestingOffset + (vestingPoint-33)*(16250000*DECIMALS)-_released;    
        } else if (vestingPoint <53) {
            uint256 vestingOffset =  614333335*DECIMALS;
            return vestingOffset + (vestingPoint-39)*(5833333*DECIMALS)-_released;  
        } else {
            return MAX_SUPPLY - GAMEPLAY_INCENTIVES_AND_MARKETING_FUND-_released;
        }
    }
    
    function release() external onlyOwner{
        uint256 timeStamp = block.timestamp;
        require(timeStamp >= START_TIME, "SipherToken.release: vesting has not started yet");
        require(_releasableAmount(timeStamp) > 0, "SipherToken.release: no token to release this time");
        uint256 readyToReleased = _releasableAmount(timeStamp);
        _released = _released + readyToReleased;
        _mint(msg.sender, readyToReleased);
    }

    function requestToClaimNoScheduledFund(uint amount) external onlyOwner{
        uint256 timeStamp = block.timestamp;
        require(_claimAmount == 0, "SipherToken.requestToClaimNoScheduledFund: claim is still pending");
        require(timeStamp >= _claimTimeStamp, "SipherToken.requestToClaimNoScheduledFund: required request before claim");
        require(amount <= GAMEPLAY_INCENTIVES_AND_MARKETING_FUND - _noScheduledReleased, "SipherToken.requestToClaimNoScheduledFund: invalid request amount");

        _claimTimeStamp = timeStamp + 3 days;
        _claimAmount = amount; 

        emit RequestRelease( amount, _claimTimeStamp);
    }

    function claimNoScheduledFund() external onlyOwner{
        uint256 timeStamp = block.timestamp;
        require(timeStamp >= _claimTimeStamp, "SipherToken.claimNoScheduledFund: not the time to claim");
        require(_claimAmount > 0, "SipherToken.claimNoScheduledFund: nothing to claim");
        
        uint releaseAmount = _claimAmount;
        _claimAmount = 0;
        _noScheduledReleased += releaseAmount;
        _mint(msg.sender, releaseAmount);
    }

    function getVestingReleasedAmount() external view returns (uint) {
        return _released;
    }

    function getNoScheduledReleasedAmount() external view returns (uint) {
        return _noScheduledReleased;
    }

    function getCurrentClaimAmount() external view returns (uint) {
        return _claimAmount;
    }

    function getTimeToClaim() external view returns (uint) {
        return _claimTimeStamp;
    }
}