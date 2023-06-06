// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault is IVault, Ownable {
    struct Share {
        uint256 amount;
        uint256 uncounted;
        uint256 counted;
    }

    mapping (address => uint256) voterClaims;

    mapping (address => uint256) public totalRewardsToVoter;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 public constant decimals = 10 ** 36;

    address public vesch;
    IERC20 public immutable SCH;

    constructor (address _SCH) {
        vesch = msg.sender;
        SCH = IERC20(_SCH);
    }

    function _getCumulativeFees(uint256 _share) private view returns (uint256) {
        return _share * rewardsPerShare / decimals;
    }

    function setBalance(address _voter, uint256 _amount) external override {
        require(msg.sender == vesch);
        totalShares = totalShares - shares[_voter].amount + _amount;
        shares[_voter].amount = _amount;
        shares[_voter].uncounted = _getCumulativeFees(shares[_voter].amount);
    }

    function claimFees(address _voter) external override returns (uint256) {
        require(msg.sender == vesch);
        if (shares[_voter].amount == 0) return 0;
        uint256 _amount = getUnclaimedFees(_voter);
        if (_amount > 0) {
            voterClaims[_voter] = block.timestamp;
            shares[_voter].counted = shares[_voter].counted + _amount;
            shares[_voter].uncounted = _getCumulativeFees(shares[_voter].amount);
            (bool _success, ) = payable(vesch).call{value: _amount}("");
            require(_success);
            totalDistributed = totalDistributed + _amount;
            totalRewardsToVoter[_voter] = totalRewardsToVoter[_voter] + _amount;
            return _amount;
        } else {
            return 0;
        }
    }

    function deposit(uint256 _amount) external override {
        require(msg.sender == vesch);
        if (totalShares > 0) {
            rewardsPerShare = rewardsPerShare + (decimals * _amount / totalShares);
        }
    }

    function getUnclaimedFees(address _voter) public view returns (uint256) {
        if (shares[_voter].amount == 0) return 0;
        uint256 _voterRewards = _getCumulativeFees(shares[_voter].amount);
        uint256 _voterUncounted = shares[_voter].uncounted;
        if (_voterRewards <= _voterUncounted) return 0;
        return _voterRewards - _voterUncounted;
    }

    function getClaimedRewardsTotal() external view returns (uint256) {
        return totalDistributed;
    }

    function getClaimedRewards(address _voter) external view returns (uint256) {
        return totalRewardsToVoter[_voter];
    }

    function getLastClaim(address _voter) external view returns (uint256) {
        return voterClaims[_voter];
    }

    function balanceOf(address _voter) external view returns (uint256) {
        return shares[_voter].amount;
    }

    receive() external payable {}
}