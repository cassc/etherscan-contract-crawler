// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/*
 _____ _         _____               
|     |_|___ ___|   __|_ _ _ ___ ___ 
| | | | |   | . |__   | | | | .'| . |
|_|_|_|_|_|_|___|_____|_____|__,|  _|
                                |_| 
*
* MIT License
* ===========
*
* Copyright (c) 2022 MinoSwap
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE

*/

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IVestingMaster.sol";
import "../interfaces/IMinoDistributor.sol";
import "../interfaces/IMinoFarm.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CncFarm is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 deposit;
        uint256 lastDeposit;
        uint256 minoRewardDebt;
        uint256 cncWithdrawalDebt;
    }

    /* ========== CONSTANTS ============= */

    // Denominator for fee calculations.
    uint256 public constant FEE_DENOM = 10000;

    // Mino token
    IERC20 public immutable mino;

    // CNC token
    IERC20 public immutable cnc;

    uint256 public constant PERIOD = 86400;

    /* ========== STATE VARIABLES ========== */

    uint256 public totalDeposit;

    uint256 public ratePerDay = 10007;

    mapping(address => UserInfo) public userInfo;

    uint256 public accMinoPerShare;

    uint256 public minoPerBlock;

    uint256 public lastRewardBlock;

    uint256 public withdrawalFee;

    uint256 public accWithdrawalRewardPerShare;
    
    address public devAddress;

    // Vesting contract that vested rewards get sent to.
    IVestingMaster public vestingMaster;

    IMinoFarm public minoFarm;

    IMinoDistributor public distributor;

    /* ========== MODIFIER ========== */

    modifier onlyGovernance() {
        require(
            (msg.sender == devAddress || msg.sender == owner()),
            "CncFarm::onlyGovernance: Not gov"
        );
        _;
    }

    constructor(
        address _mino, 
        address _cnc, 
        address _vestingMaster,
        address _devAddress,
        uint256 _minoPerBlock
    ) {
        mino = IERC20(_mino);
        cnc = IERC20(_cnc);
        vestingMaster = IVestingMaster(_vestingMaster);
        devAddress = _devAddress;
        minoPerBlock = _minoPerBlock;
    }

    // @todo Optmize this
    function initMinoFarm(address _minoFarm) external onlyOwner {
        require(address(minoFarm) == address(0), "CncFarm::initMinoFarm: MinoFarm already set");
        minoFarm = IMinoFarm(_minoFarm);
    }

    function initDistributor(address _minoDistributor) external {
        require(address(distributor) == address(0), "CncFarm::initDistributor: MinoFarm already set");
        distributor = IMinoDistributor(_minoDistributor);
    }


    // investment * interest rate ^ x
    // investment * (interest rate ** x) / 1 ** x)
    // x = (current block - start block) / PERIOD

    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (totalDeposit == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 minoReward = (lastRewardBlock - block.number) * minoPerBlock;
        accMinoPerShare += minoReward + (
            minoReward * 1e12 / totalDeposit
        );
        IMinoFarm(minoFarm).ifcWithdraw();
        distributor.withdrawReward(0);
        lastRewardBlock = block.number;
    }

    function deposit(uint256 _cncAmt) external nonReentrant {
        UserInfo storage _userInfo = userInfo[msg.sender];
        updatePool();
        if (_userInfo.deposit > 0) {
            
            uint256 pendingMino = _userInfo.deposit * accMinoPerShare / 1e12 - _userInfo.minoRewardDebt;
            if (pendingMino > 0) {
                uint256 locked;
                if (address(vestingMaster) != address(0)) {
                    locked = pendingMino * (vestingMaster.lockedPeriodAmount() + 1) / vestingMaster.lockedPeriodAmount();
                }
                safeMinoTransfer(msg.sender, pendingMino - locked);
                if (locked > 0) {
                    uint256 actualAmount = safeMinoTransfer(
                        address(vestingMaster),
                        locked
                    );
                    vestingMaster.lock(msg.sender, actualAmount);
                }
            }
        }
        if (_cncAmt > 0) {
            uint256 period = (block.number - _userInfo.lastDeposit) / PERIOD;
            uint256 pendingCnc = _userInfo.deposit * (ratePerDay ** period / 1 ** period); 
            safeCncTransfer(msg.sender, pendingCnc);
            
            cnc.safeTransferFrom(msg.sender, address(this), _cncAmt);
            
            _userInfo.lastDeposit = block.number;
            _userInfo.deposit += _cncAmt;
            totalDeposit += _cncAmt;
        }

    }

    function withdraw(uint256 _cncAmt) external nonReentrant {
        UserInfo storage _userInfo = userInfo[msg.sender];
        updatePool();
        if (_userInfo.deposit > 0) {
            
            uint256 pendingMino = _userInfo.deposit * accMinoPerShare / 1e12 - _userInfo.minoRewardDebt;
            if (pendingMino > 0) {
                uint256 locked;
                if (address(vestingMaster) != address(0)) {
                    locked = pendingMino * (vestingMaster.lockedPeriodAmount() + 1) / vestingMaster.lockedPeriodAmount();
                }
                safeMinoTransfer(msg.sender, pendingMino - locked);
                if (locked > 0) {
                    uint256 actualAmount = safeMinoTransfer(
                        address(vestingMaster),
                        locked
                    );
                    vestingMaster.lock(msg.sender, actualAmount);
                }
            }
        }
        if (_cncAmt > 0) {
            uint256 period = (block.number - _userInfo.lastDeposit) / PERIOD;
            uint256 pendingCnc = _userInfo.deposit * (ratePerDay ** period / 1 ** period);
            uint256 _withdrawalFee = _cncAmt * withdrawalFee / FEE_DENOM;
            accWithdrawalRewardPerShare += _withdrawalFee * 1e12 / totalDeposit;

            cnc.safeTransfer(msg.sender, _cncAmt - _withdrawalFee);
            _userInfo.lastDeposit = block.number;
            _userInfo.deposit -= _cncAmt;
            totalDeposit -= _cncAmt;
            safeCncTransfer(msg.sender, pendingCnc);
        }
    }

    function safeCncTransfer(address _to, uint256 _amount)
        internal
        returns (uint256) 
    {
        if (_amount == 0) return 0;
        uint256 balance = cnc.balanceOf(address(this)) - totalDeposit;
        if (_amount > balance) {
            _amount = balance;
        }

        require(
            cnc.transfer(_to, _amount),
            "CncFarm::safeCncTransfer: Transfer failed"
        );
        return _amount;
    }

    function safeMinoTransfer(address _to, uint256 _amount) 
        internal 
        returns (uint256) 
    {
        if (_amount == 0) return 0;
        uint256 balance = mino.balanceOf(address(this));
        if (_amount > balance) {
            _amount = balance;
        }

        require(
            mino.transfer(_to, _amount),
            "CncFarm::safeMinoTransfer: Transfer failed"
        );
        return _amount;
    }
}