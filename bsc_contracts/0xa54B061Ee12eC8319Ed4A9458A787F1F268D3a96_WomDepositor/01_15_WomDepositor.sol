// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./Interfaces/IBaseRewardPool.sol";
import "./Interfaces/IWomDepositor.sol";
import "./Interfaces/IWombatVoterProxy.sol";
import "./Interfaces/IQuollExternalToken.sol";

contract WomDepositor is IWomDepositor, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public wom;

    address public voterProxy;
    address public qWOM;

    uint256 private maxLockDays;
    uint256 public lockTimeInterval;
    uint256 public lastLockTime;

    address public qWomRewardPool;

    function initialize() public initializer {
        __Ownable_init();
    }

    function setParams(
        address _wom,
        address _voterProxy,
        address _qWOM,
        address _qWomRewardPool
    ) external onlyOwner {
        require(voterProxy == address(0), "params has already been set");

        require(_wom != address(0), "invalid _wom!");
        require(_voterProxy != address(0), "invalid _voterProxy!");
        require(_qWOM != address(0), "invalid _qWOM!");
        require(_qWomRewardPool != address(0), "invalid _qWomRewardPool!");

        wom = _wom;

        voterProxy = _voterProxy;
        qWOM = _qWOM;

        qWomRewardPool = _qWomRewardPool;

        maxLockDays = 1461;
        lockTimeInterval = 1 days;
        lastLockTime = block.timestamp;
    }

    function setQWomRewardPool(address _qWomRewardPool) external onlyOwner {
        qWomRewardPool = _qWomRewardPool;
    }

    function setLockTimeInterval(uint256 _lockTimeInterval) external onlyOwner {
        lockTimeInterval = _lockTimeInterval;
    }

    //lock wom
    function _lockWom() internal {
        uint256 womBalance = IERC20(wom).balanceOf(address(this));
        if (womBalance > 0) {
            IERC20(wom).safeTransfer(voterProxy, womBalance);
        }

        //increase amount
        uint256 womBalanceVoterProxy = IERC20(wom).balanceOf(voterProxy);
        if (womBalanceVoterProxy == 0) {
            return;
        }

        //increase amount
        IWombatVoterProxy(voterProxy).lockWom(maxLockDays);
        lastLockTime = block.timestamp;
    }

    function lockWom() external onlyOwner {
        _lockWom();
    }

    //deposit wom for qWom
    function deposit(uint256 _amount, bool _stake) public override {
        require(_amount > 0, "!>0");

        if (block.timestamp > lastLockTime.add(lockTimeInterval)) {
            //lock immediately, transfer directly to voterProxy to skip an erc20 transfer
            IERC20(wom).safeTransferFrom(msg.sender, voterProxy, _amount);
            _lockWom();
        } else {
            //move tokens here
            IERC20(wom).safeTransferFrom(msg.sender, address(this), _amount);
        }

        if (!_stake) {
            //mint for msg.sender
            IQuollExternalToken(qWOM).mint(msg.sender, _amount);
        } else {
            //mint here
            IQuollExternalToken(qWOM).mint(address(this), _amount);
            //stake for msg.sender
            IERC20(qWOM).safeApprove(qWomRewardPool, 0);
            IERC20(qWOM).safeApprove(qWomRewardPool, _amount);
            IBaseRewardPool(qWomRewardPool).stakeFor(msg.sender, _amount);
        }

        emit Deposited(msg.sender, _amount);
    }

    function depositAll(bool _stake) external {
        uint256 womBal = IERC20(wom).balanceOf(msg.sender);
        deposit(womBal, _stake);
    }
}