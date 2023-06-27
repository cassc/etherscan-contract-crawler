// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../general-components/LinearVestingMerkle.sol";

contract LinearVestingTreeway is LinearVestingMerkle {
    using SafeERC20 for IERC20;

    event UserVested(address user, uint256 startEpoch, uint256 totalDays, uint256 totalReward);
    event UserCollect(address user, uint256 amount);
    event VestRedirected(address _oldUser, address _newUser);

    uint256 constant DAY = 86400;

    //Token
    IERC20 public bids;

    //User's collected value
    mapping(address => uint256) public claimedAmount;

    constructor(IERC20 _bids) {
        bids = _bids;
    }

    // function vestUser(address _user, uint256 _startEpoch, uint256 _totalDays, uint256 _totalReward) external onlyOwner {
    //     require(!locked, "Contract is locked(forever)");
    //     require(userInfo[_user].startEpoch == 0, "Already vested");
    //     require(_startEpoch != 0, "Bad epoch");

    //     userInfo[_user] = vestInfo(_totalReward,_startEpoch,_totalDays,0);
    //     totalFillable += _totalReward;

    //     emit UserVested(_user,_startEpoch,_totalDays,_totalReward);
    // }

    function calculateTotalClaimable(uint256 _startEpoch,uint256 _totalDays, uint256 _totalReward, uint256 _currentEpoch) internal pure returns(uint256){
        if(_startEpoch>=_currentEpoch){
            return 0;
        }
        uint256 _delta = _currentEpoch - _startEpoch;
        uint256 _doneDays = _delta/DAY;
        if(_doneDays>=_totalDays){
            return _totalReward;
        }

        uint256 _rewardPerDay = _totalReward/_totalDays;
        return _rewardPerDay*_doneDays;
    }

    //reentrancy is futile, logic ignores token state variables and transfer is the last operation
    function release(uint256 _amount,uint256 _totalReward, uint256 _startEpoch,
                     uint256 _totalDays,uint8 _treeId,bytes32[] calldata _merkleProof) external {
        require(_amount>0,"Please enter amount");
        vestInfo memory data = vestInfo(_totalReward,_startEpoch,_totalDays);
        require(_canClaim(msg.sender,_treeId,data,_merkleProof),"Invalid vesting information");

        uint256 _userTotalClaimable = calculateTotalClaimable(_startEpoch,_totalDays,_totalReward,block.timestamp);
        if(_amount <= _userTotalClaimable-claimedAmount[msg.sender]) {
            claimedAmount[msg.sender] += _amount;
            emit UserCollect(msg.sender,_amount);
            bids.safeTransfer(msg.sender, _amount);
        } else {
            revert("Can't release more than max");
        }
    }

    //returns user's totalReward - calculateTotalClaimable
    //TODO IMPLEMENT TREEWAY variation
    function userLockedAmount(address _user, uint256 _totalReward, uint256 _startEpoch,
        uint256 _totalDays,uint8 _treeId,bytes32[] calldata _merkleProof) external view returns(uint256){

        vestInfo memory data = vestInfo(_totalReward,_startEpoch,_totalDays);
        require(_canClaim(_user,_treeId,data,_merkleProof),"Invalid vesting information");
        return data.totalReward - calculateTotalClaimable(data.startEpoch,data.totalDays,data.totalReward,block.timestamp);
    }

    //TODO IMPLEMENT TREEWAY variation
    function userClaimableAmount(address _user, uint256 _totalReward, uint256 _startEpoch,
        uint256 _totalDays,uint8 _treeId,bytes32[] calldata _merkleProof) external view returns(uint256){

        vestInfo memory data = vestInfo(_totalReward,_startEpoch,_totalDays);
        require(_canClaim(_user,_treeId,data,_merkleProof),"Invalid vesting information");
        uint256 _userTotalClaimable = calculateTotalClaimable(data.startEpoch,data.totalDays,data.totalReward,block.timestamp);
        return _userTotalClaimable - claimedAmount[_user];
    }

}