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
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IVestingMaster.sol";
import "./interfaces/IMinoFarm.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IMinoVault.sol";
import "./interfaces/INFTController.sol";

contract MinoFarm is IMinoFarm, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct NFTSlot {
        address slot;
        uint256 tokenId;
    }
 
    /* ========== CONSTANTS ============= */

    // Denominator for fee calculations.
    uint256 public constant FEE_DENOM = 10000;

    // Mino token
    IERC20 public immutable override mino;

    // The block number when mining starts.
    uint256 public immutable override startBlock;

    // Early withdrawal period. User withdrawals within this period will be charged an exit fee.
    uint256 public immutable override earlyExitPeriod;

    IMinoVault public immutable minoVault;

    /* ========== STATE VARIABLES ========== */

    // Info of each pool.
    PoolInfo[] public override poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public override userInfo;

    // Mino tokens rewarded per block.
    uint256 public override minoPerBlock;
    
    // The block number when mining ends.
    uint256 public override endBlock;
  
    // Fee paid for early withdrawals
    uint256 public override earlyExitFee;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public override totalAllocPoint;

    // Supply percentage allocated to IFC.
    uint256 public override stakingSupply;

    // Supply percentage allocated to IFC.
    uint256 public override ifcSupply;

    // Last block IFC harvested rewards
    uint256 public override lastBlockIfcWithdraw;

    // Vesting contract that vested rewards get sent to.
    IVestingMaster public override vestingMaster;
    
    // IFC pool address.
    address public override ifcPool;

    // Developer address.
    address public devAddress;

    // Supply percentage allocated to the developer.
    uint256 public devSupply;

    address public govAddress;

    uint256 public govSupply;

    INFTController public nftController;

    mapping(address => mapping(uint256 => NFTSlot)) internal _depositedNft;

    /* ========== MODIFIERS ========== */

    modifier validatePid(uint256 _pid) {
        require(
            _pid < poolInfo.length,
            "MinoFarm::validatePid: Not exist"
        );
        _;
    }

    modifier onlyGovernance() {
        require(
            (msg.sender == devAddress || msg.sender == owner()),
            "MinoFarm::onlyGovernance: Not gov"
        );
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address[] memory _addresses,
        uint256 _minoPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _earlyExitFee,
        uint256 _earlyExitPeriod
    ) {
        require(
            _startBlock < _endBlock,
            "MinoFarm::constructor: End less than start"
        );
        vestingMaster = IVestingMaster(_addresses[0]);
        mino = IERC20(_addresses[1]);
        minoVault = IMinoVault(_addresses[2]);
        devAddress = _addresses[3];
        govAddress = _addresses[4];
        ifcPool = _addresses[5];
        minoPerBlock = _minoPerBlock;
        startBlock = _startBlock;
        lastBlockIfcWithdraw = _startBlock;
        endBlock = _endBlock;
        stakingSupply = 6700;
        devSupply = 1400;
        govSupply = 300;
        ifcSupply = 600;
        earlyExitFee = _earlyExitFee;
        earlyExitPeriod = _earlyExitPeriod;
    }

    /* ========== VIEWS ========== */

    function getDepositedNft(address _user, uint256 _pid) external view returns (address nftAddress, uint256 tokenId) {
        NFTSlot memory nftSlot = _depositedNft[msg.sender][_pid];
        nftAddress = nftSlot.slot;
        tokenId = nftSlot.tokenId;
    }

    function poolLength() external view override returns (uint256) {
        return poolInfo.length;
    }

    function pendingMino(uint256 _pid, address _user)
        external
        override
        view
        validatePid(_pid)
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 _sharesTotal = IStrategy(pool.strat).sharesTotal();
        if (block.number > pool.lastRewardBlock && _sharesTotal != 0) {
            uint256 tokenReward = getStakingReward(_pid);
            accTokenPerShare = accTokenPerShare + (
                tokenReward * 1e12 / _sharesTotal
            );
        }
        return user.shares * accTokenPerShare / 1e12 - user.rewardDebt;
    }

    function sharesTotal(uint256 _pid)
        external
        override
        view
        validatePid(_pid)
        returns (uint256)
    {
        return IStrategy(poolInfo[_pid].strat).sharesTotal();
    }

    function stakedWantTokens(uint256 _pid, address _user)
        external
        override
        view
        returns (uint256)
    {
        return userInfo[_pid][_user].shares;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function massUpdatePools() public override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public override validatePid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock || pool.lastRewardBlock >= endBlock) {
            return;
        }
        uint256 lastRewardBlock = block.number >= endBlock ? endBlock : block.number;
        uint256 strategyShares = IStrategy(pool.strat).sharesTotal();
        if (strategyShares == 0 || pool.allocPoint == 0) {
            return;
        }
        
        uint256 tokenReward = getStakingReward(_pid);
        pool.accTokenPerShare = pool.accTokenPerShare + (
            tokenReward * 1e12 / strategyShares
        );

        pool.lastRewardBlock = lastRewardBlock;

    }

    function deposit(uint256 _pid, uint256 _wantAmt)
        external
        override
        validatePid(_pid)
        nonReentrant
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        NFTSlot memory nftSlot = _depositedNft[msg.sender][_pid];
        updatePool(_pid);
        if (user.shares > 0) {
            uint256 pending =
                (user.shares + nftController.boostRate(nftSlot.slot, nftSlot.tokenId) * user.shares / FEE_DENOM)
                * pool.accTokenPerShare / 1e12 - (
                    user.rewardDebt
                );
            if (pending > 0) {
                uint256 locked;
                if (address(vestingMaster) != address(0)) {
                    locked = pending * vestingMaster.lockedPeriodAmount() / (vestingMaster.lockedPeriodAmount() + 1);
                }
                safeTokenTransfer(msg.sender, pending - locked);
                if (locked > 0) {
                    uint256 actualAmount = safeTokenTransfer(
                        address(vestingMaster),
                        locked
                    );
                    vestingMaster.lock(msg.sender, actualAmount);
                }
            }
        }
        if (_wantAmt > 0) {
            pool.want.safeTransferFrom(
                address(msg.sender),
                address(this),
                _wantAmt
            );

            pool.want.safeIncreaseAllowance(pool.strat, _wantAmt);
            uint256 sharesAdded = IStrategy(pool.strat).deposit(_wantAmt);
            user.shares = user.shares + sharesAdded;
            user.lastDepositedTime = block.timestamp;
        }
        user.rewardDebt = user.shares * pool.accTokenPerShare / 1e12;
        emit Deposit(msg.sender, _pid, _wantAmt);
    }

    function withdraw(uint256 _pid, uint256 _wantAmt)
        public
        override
        validatePid(_pid)
        nonReentrant
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        NFTSlot memory nftSlot = _depositedNft[msg.sender][_pid];
        updatePool(_pid);
        if (user.shares > 0) {
            uint256 pending =
                (user.shares + nftController.boostRate(nftSlot.slot, nftSlot.tokenId) * user.shares / FEE_DENOM)
                * pool.accTokenPerShare / 1e12 - (
                    user.rewardDebt
                );
            if (pending > 0) {
                uint256 locked;
                if (address(vestingMaster) != address(0)) {
                    locked = pending / (vestingMaster.lockedPeriodAmount() + 1) * vestingMaster.lockedPeriodAmount();
                }
                safeTokenTransfer(msg.sender, pending - locked);
                if (locked > 0) {
                    uint256 actualAmount = safeTokenTransfer(
                        address(vestingMaster),
                        locked
                    );
                    vestingMaster.lock(msg.sender, actualAmount);
                }
            }
        }

        if (_wantAmt > user.shares) {
            _wantAmt = user.shares;
        }
        if (_wantAmt > 0) {
            uint256 realAmt = IStrategy(pool.strat).withdraw(_wantAmt);
            if (realAmt > user.shares) {
                realAmt = user.shares;
                user.shares = 0;
            } else {
                user.shares = user.shares - realAmt;
            }

            _wantAmt = realAmt;
            if (block.timestamp - user.lastDepositedTime < earlyExitPeriod) {
                _wantAmt = _wantAmt * earlyExitFee / FEE_DENOM;
                pool.want.safeTransfer(pool.strat, realAmt - _wantAmt);
            }
            pool.want.safeTransfer(address(msg.sender), _wantAmt);
        }
        user.rewardDebt = user.shares * pool.accTokenPerShare / 1e12;
        emit Withdraw(msg.sender, _pid, _wantAmt);
    }

    function withdrawAll(uint256 _pid) external override {
        withdraw(_pid, type(uint256).max);
    }

    function emergencyWithdraw(uint256 _pid)
        external
        override
        validatePid(_pid)
        nonReentrant
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 realAmt = IStrategy(pool.strat).withdraw(user.shares);
        if (realAmt > user.shares) {
            realAmt = user.shares;
        }
        user.shares = 0;
        user.rewardDebt = 0;
        pool.want.safeTransfer(address(msg.sender), realAmt);
        emit EmergencyWithdraw(msg.sender, _pid, realAmt);
    }

    function depositNft(address _nft, uint256 _tokenId, uint256 _pid) external {
        require(nftController.whitelistedNFT(_nft), "MinoFarm::depositNft: NFT !approved");
        NFTSlot storage _nftSlot = _depositedNft[msg.sender][_pid];
        require(_nftSlot.slot != address(0),"MinoFarm::depositNft: NFT slot already used");
        IERC1155(_nft).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        _nftSlot.slot = _nft;
        _nftSlot.tokenId = _tokenId;
    }

    function withdrawNft(uint256 _pid) external {
        NFTSlot storage _nftSlot = _depositedNft[msg.sender][_pid];
        require(_nftSlot.slot != address(0), "MinoFarm::withdrawNft: NFT slot empty");
        IERC1155(_nftSlot.slot).safeTransferFrom(address(this), msg.sender, _nftSlot.tokenId, 1, "");

        _nftSlot.slot = address(0);
        _nftSlot.tokenId = 0;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    
    function add(
        uint256 _allocPoint,
        IERC20 _want,
        bool _withUpdate,
        address _strat
    )
        external
        override
        onlyGovernance
    {
        require(
            block.number < endBlock,
            "MinoFarm::add: Exceed endblock"
        );
        require(_strat != address(0), "MinoFarm::add: Strat can not be zero address.");

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                want: _want,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accTokenPerShare: 0,
                strat: _strat
            })
        );
    }

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    )
        external
        override
        onlyGovernance
        validatePid(_pid)
    {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint -= poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function updateMinoPerBlock(uint256 _minoPerBlock)
        external
        override
        onlyGovernance
    {
        massUpdatePools();
        minoPerBlock = _minoPerBlock;
        emit UpdateEmissionRate(msg.sender, _minoPerBlock);
    }

    function updateEndBlock(uint256 _endBlock)
        external
        override
        onlyGovernance
    {
        require(_endBlock > startBlock, "MinoFarm::updateEndBlock: Less");
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            require(
                _endBlock > poolInfo[pid].lastRewardBlock,
                "MinoFarm::updateEndBlock: Less"
            );
        }
        massUpdatePools();
        endBlock = _endBlock;
        emit UpdateEndBlock(msg.sender, _endBlock);
    }

    function setEarlyExitFee(uint256 _earlyExitFee)
        external
        override
        onlyGovernance
    {
        earlyExitFee = _earlyExitFee;
        emit SetEarlyExitFee(msg.sender, _earlyExitFee);
    }

    function setVestingMaster(address _vestingMaster) 
        external 
        override 
        onlyGovernance 
    {   
        // require(_vestingMaster != address(0), "MinoFarm::set: Zero address");
        vestingMaster = IVestingMaster(_vestingMaster);
        emit SetVestingMaster(msg.sender, _vestingMaster);
    }

    function setDevAddress(address _devAddress)
        external
        override
        onlyGovernance
    {   
        // require(_devAddress != address(0), "MinoFarm::set: Zero address");
        devAddress = _devAddress;
        emit SetDevAddress(msg.sender, _devAddress);
    }

    function setDevSupply(uint256 _devSupply) 
        external 
        override 
        onlyGovernance 
    {   
        devSupply = _devSupply;
        emit SetDevSupply(msg.sender, _devSupply);
    }

    function setNftController(address _nftController) external onlyGovernance {
        nftController = INFTController(_nftController);
    }

    function ifcWithdraw() external override {
        if (lastBlockIfcWithdraw >= block.number) {
            return;
        }
        uint256 multiplier = block.number - lastBlockIfcWithdraw;
        if (block.number >= endBlock) {
            multiplier = lastBlockIfcWithdraw - endBlock;
        }
        uint256 minoReward = multiplier * minoPerBlock;
        safeTokenTransfer(ifcPool, minoReward * ifcSupply / FEE_DENOM);
        safeTokenTransfer(devAddress, minoReward * devSupply / FEE_DENOM);
        safeTokenTransfer(govAddress, minoReward * govSupply / FEE_DENOM);
        
        lastBlockIfcWithdraw = block.number;
    } 

    function finalizeGovAddress(address _govAddress) external {
        require(msg.sender == govAddress, "MinoFarm::finalizeGovAddress: Unauthorized");
        govAddress = _govAddress;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function getStakingReward(uint256 _pid)
        internal
        view
        returns (uint256 tokenReward)
    {
        PoolInfo storage pool = poolInfo[_pid];
        require(
            pool.lastRewardBlock < block.number,
            "MinoFarm::getStakingReward: Must less than block number"
        );
        uint256 multiplier = block.number - pool.lastRewardBlock;
        if (block.number >= endBlock) {
            multiplier = pool.lastRewardBlock - endBlock;
        } 
        tokenReward = multiplier * minoPerBlock * pool.allocPoint / totalAllocPoint * stakingSupply / FEE_DENOM;
    }

    /* ========== UTILITY FUNCTIONS ========== */

    function safeTokenTransfer(address _to, uint256 _amount)
        internal
        returns (uint256)
    {
        uint256 balance = mino.balanceOf(address(this));
        if (_amount > balance) {
            _amount = minoVault.minoFarmWithdraw(_amount - balance);
        }

        require(
            mino.transfer(_to, _amount),
            "MinoFarm::safeTokenTransfer: Transfer failed"
        );
        return _amount;
    }
}