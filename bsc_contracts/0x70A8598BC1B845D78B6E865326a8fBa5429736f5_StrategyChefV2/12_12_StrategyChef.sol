// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/IPancakeswapFarm.sol";
import "./interfaces/ICakePool.sol";

contract StrategyChefV2 is ReentrancyGuard, Pausable {

    // Maximises yields in pancakeswap
    using SafeERC20 for IERC20;

    bool public isCAKEStaking; 
    bool public immutable isStaking; 
    ICakePool public cakePoolContract = ICakePool(0x45c54210128a065de780C4B0Df3d16664f7f859e);
    address public constant cakeTokenAddress = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;

    address public farmContractAddress; 
    uint256 public pid; 
    address public wantAddress;
    address public earnedAddress;

    address public immutable MasterChefAddress;
    address public govAddress;
    address public feeAddress;

    uint256 public earnDistributeThreshold = 10e18;
    uint256 public wantLockedTotal = 0;

    // Events
    event FeeAddressUpdated(address feeAddress);
    event EarnedAddressUpdated(address earnedAddress);
    event GovUpdated(address govAddress);
    event StuckTokenRemoval(address token, uint256 amount, address to);
    event EarnDistributeThresholdUpdated(uint256 earnDistributeThreshold);

    modifier onlyMasterChef() {
        require(msg.sender == MasterChefAddress, "Only Masterchef!");
        _;
    }

    constructor(
        bool _isStaking,
        address _farmContractAddress,
        uint256 _pid,
        address _wantAddress,
        address _earnedAddress
    ) {
        govAddress = 0x27B788282B3120a254d16bc8d52f16e526F59645;
        MasterChefAddress = 0x78205CE1a7e714CAE95a32e65B6dA7b2dA8D8A10;
        isCAKEStaking = false;
        isStaking = _isStaking;
        wantAddress = _wantAddress;
        feeAddress = 0xA76216D578BdA59d50B520AaF717B187D21F5121;

        if (_isStaking) {
            farmContractAddress = _farmContractAddress;
            pid = _pid;
            earnedAddress = _earnedAddress;
        }

        if (isCAKEStaking){
            IERC20(cakeTokenAddress).approve(address(cakePoolContract), type(uint256).max);
        }
    }

    // Receives new deposits from user
    function deposit(uint256 _wantAmt)
    external
    onlyMasterChef
    whenNotPaused
    nonReentrant
    returns (uint256)
    {
        uint256 wantBalBefore = IERC20(wantAddress).balanceOf(address(this));

        IERC20(wantAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _wantAmt
        );
        uint256 wantBalAfter = IERC20(wantAddress).balanceOf(address(this));

        _wantAmt = wantBalAfter - wantBalBefore;
        if (isStaking) {
            _farm(_wantAmt);
        } else {
            wantLockedTotal = wantLockedTotal + _wantAmt;
        }

        return _wantAmt;
    }

    function _farm(uint256 _wantAmt) internal {
        wantLockedTotal = wantLockedTotal + _wantAmt;
        IERC20(wantAddress).safeIncreaseAllowance(farmContractAddress, _wantAmt);

        if (isCAKEStaking) {
            // _amount, _lockDuration
            cakePoolContract.deposit(_wantAmt, 0); // Just for CAKE staking, we dont use deposit()
        } else {
            IPancakeswapFarm(farmContractAddress).deposit(pid, _wantAmt);
        }
    }

    function withdraw(uint256 _wantAmt)
    external
    onlyMasterChef
    nonReentrant
    returns (uint256)
    {
        require(_wantAmt > 0, "_wantAmt <= 0");
        if (isStaking) {
            if (isCAKEStaking) {
                cakePoolContract.withdrawByAmount(_wantAmt); // Just for CAKE staking, we dont use withdraw()
            } else {
                IPancakeswapFarm(farmContractAddress).withdraw(pid, _wantAmt);
            }
        }

        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        if (wantLockedTotal < _wantAmt) {
            _wantAmt = wantLockedTotal;
        }

        wantLockedTotal = wantLockedTotal - _wantAmt;

        IERC20(wantAddress).safeTransfer(MasterChefAddress, _wantAmt);

        if (isStaking) {
            distributeFee();
        }

        return _wantAmt;
    }

    // 1. Harvest farm tokens
    // 2. Converts farm tokens into want tokens
    // 3. Deposits want tokens

    function earn() external whenNotPaused nonReentrant {
        require(isStaking, "!isStaking");

        // Harvest farm tokens
        if (!isCAKEStaking) {
            IPancakeswapFarm(farmContractAddress).withdraw(pid, 0);
        }

        distributeFee();
    }

    function distributeFee() internal {

        // Converts farm tokens into want tokens
        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));
        if (earnedAmt > earnDistributeThreshold){
            IERC20(earnedAddress).safeTransfer(feeAddress, earnedAmt);
        }
    }

    function pause() external {
        require(msg.sender == govAddress, "Not authorised");
        _pause();
    }

    function unpause() external {
        require(msg.sender == govAddress, "Not authorised");
        _unpause();
    }

    function setGov(address _govAddress) external {
        require(msg.sender == govAddress, "!gov");
        govAddress = _govAddress;
        emit GovUpdated(govAddress);
    }

    function setFeeAddress(address _feeAddress) external {
        require(msg.sender == govAddress, "!gov");
        require(_feeAddress != address(0), "!nonzero");
        feeAddress = _feeAddress;
        emit FeeAddressUpdated(feeAddress);
    }

    function setEarnedAddress(address _earnedAddress) external {
        require(msg.sender == govAddress, "!gov");
        require(_earnedAddress != address(0), "!nonzero");
        earnedAddress = _earnedAddress;
        emit EarnedAddressUpdated(earnedAddress);
    }

    function setEarnDistributeThreshold(uint256 _earnDistributeThreshold) external {
        require(msg.sender == govAddress, "!gov");
        earnDistributeThreshold = _earnDistributeThreshold;
        emit EarnDistributeThresholdUpdated(_earnDistributeThreshold);
    }


    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public {
        require(msg.sender == govAddress, "!gov");
        require(_token != wantAddress, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
        emit StuckTokenRemoval(_to, _amount, _to);
    }


}