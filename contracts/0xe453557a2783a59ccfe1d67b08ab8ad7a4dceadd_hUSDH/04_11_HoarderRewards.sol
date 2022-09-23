// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "./interfaces/IHoarderRewards.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IhUSDH.sol";
import "./interfaces/IUSDH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HoarderRewards is IHoarderRewards, ReentrancyGuard {
    struct Share {
        uint256 amount;
        uint256 uncounted;
        uint256 counted;
    }

    mapping (address => uint256) hoarderClaims;

    mapping (address => uint256) public totalRewardsToHoarder;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalRewards;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 public constant decimals = 10 ** 36;

    IhUSDH public immutable hoarder;
    IUSDH public immutable usdh;
    IERC20 public immutable Usdh;

    address public governance;

    modifier onlyHoarder {
        require(msg.sender == hoarder.checkStrategy() || msg.sender == address(hoarder));
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance);
        _;
    }

    constructor (address _usdh, address _governance) {
        hoarder = IhUSDH(msg.sender);
        usdh = IUSDH(_usdh);
        Usdh = IERC20(_usdh);
        governance = _governance;
    }

    function _getCumulativeUSDH(uint256 _share) private view returns (uint256) {
        return _share * rewardsPerShare / decimals;
    }

    function setBalance(address _hoarder, uint256 _amount) external override onlyHoarder {
        if (shares[_hoarder].amount > 0) _claimUSDH(_hoarder);
        totalShares = totalShares - shares[_hoarder].amount + _amount;
        shares[_hoarder].amount = _amount;
        shares[_hoarder].uncounted = _getCumulativeUSDH(shares[_hoarder].amount);
    }

    function _claimUSDH(address _hoarder) private {
        if (shares[_hoarder].amount == 0) return;
        uint256 _amount = getUnclaimedUSDH(_hoarder);
        if (_amount > 0) {
            hoarderClaims[_hoarder] = block.timestamp;
            shares[_hoarder].counted = shares[_hoarder].counted + _amount;
            shares[_hoarder].uncounted = _getCumulativeUSDH(shares[_hoarder].amount);
            Usdh.transfer(_hoarder, _amount);
            totalDistributed = totalDistributed + _amount;
            totalRewardsToHoarder[_hoarder] = totalRewardsToHoarder[_hoarder] + _amount;
        }
    }

    function claimUSDH(address _hoarder) external onlyHoarder {
        _claimUSDH(_hoarder);
    }

    function deposit(uint256 _amount) external override onlyHoarder {
        require(Usdh.balanceOf(msg.sender) >= _amount);
        require(Usdh.allowance(msg.sender, address(this)) >= _amount);
        uint256 balance = Usdh.balanceOf(address(this));
        Usdh.transferFrom(msg.sender, address(this), _amount);
        require(Usdh.balanceOf(address(this)) == balance + _amount);
        totalRewards = totalRewards + _amount;
        rewardsPerShare = rewardsPerShare + (decimals * _amount / totalShares);
    }

    function getUnclaimedUSDH(address _hoarder) public view returns (uint256) {
        if (shares[_hoarder].amount == 0) return 0;
        uint256 _hoarderRewards = _getCumulativeUSDH(shares[_hoarder].amount);
        uint256 _hoarderUncounted = shares[_hoarder].uncounted;
        if (_hoarderRewards <= _hoarderUncounted) return 0;
        return _hoarderRewards - _hoarderUncounted;
    }

    function getClaimedRewardsTotal() external view returns (uint256) {
        return totalDistributed;
    }

    function getClaimedRewards(address _hoarder) external view returns (uint256) {
        return totalRewardsToHoarder[_hoarder];
    }

    function getLastClaim(address _hoarder) external view returns (uint256) {
        return hoarderClaims[_hoarder];
    }

    function rescue(address token) external onlyGovernance {
        if (token == 0x0000000000000000000000000000000000000000) {
            payable(msg.sender).call{value: address(this).balance}("");
        } else {
            require(token != address(usdh));
            IERC20 Token = IERC20(token);
            Token.transfer(msg.sender, Token.balanceOf(address(this)));
        }
    }

    function setGovernance(address _newGovernanceContract) external nonReentrant onlyGovernance {
        governance = _newGovernanceContract;
    }

    receive() external payable {}
}