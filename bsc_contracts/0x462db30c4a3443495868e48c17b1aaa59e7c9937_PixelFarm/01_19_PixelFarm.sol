// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";

// import "./PIXELToken.sol";
abstract contract PIXELToken is ERC20 {
    function mint(address _to, uint256 _amount) public virtual;
}

// For intereacting with NFTv1
interface INftV1 is IERC721 {
    function generateRARITYofTokenById(uint256 _tokenId)
        external
        view
        returns (uint256);
}

// For interacting with our own strategy
interface IStrategy {
    // Total want tokens managed by stratfegy
    function wantLockedTotal() external view returns (uint256);

    // Sum of all shares of users to wantLockedTotal
    function sharesTotal() external view returns (uint256);

    // Main want token compounding function
    function earn() external;

    // Transfer want tokens autoFarm -> strategy
    function deposit(address _userAddress, uint256 _wantAmt)
        external
        returns (uint256);

    // Transfer want tokens strategy -> autoFarm
    function withdraw(address _userAddress, uint256 _wantAmt)
        external
        returns (uint256);

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}

contract PixelFarm is Ownable, ReentrancyGuard, ERC165, IERC721Receiver {
    using SafeERC20 for IERC20;
    using Address for address;

    // Info of each user.
    struct UserInfo {
        uint256 shares; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 boostedShares; // If no NFT staked boostedShares = shares
        uint256 penalty; // Current penalty multiplier for the user, if no nf staked penalty = 1
        uint256 lastActionTimeStamp; // timestamp for penalty calculation
        uint256 nftId1; // id of boost nft
        uint256 nftId2; // id of pentalty nft

        // We do some fancy math here. Basically, any point in time, the amount of PIXEL
        // entitled to a user but is pending to be distributed is:
        //
        //   amount = user.shares / sharesTotal * wantLockedTotal
        //   pending reward = (boostedShares * pool.accPIXELPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws want tokens to a pool. Here's what happens:
        //   1. The pool's `accPIXELPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `boostedShares` gets updated.
        //   5. Users 'lastActionTimeStamp' gets updated
        //   6. User's `rewardDebt` gets updated.
    }

    struct PoolInfo {
        IERC20 want; // Address of the want token.
        uint256 allocPoint; // How many allocation points assigned to this pool. PIXEL to distribute per block.
        uint256 lastRewardBlock; // Last block number that PIXEL distribution occurs.
        uint256 accPIXELPerShare; // Accumulated PIXEL per share, times 1e12. See below.
        address strat; // Strategy address that will auto compound want tokens
        uint16 depositFeeBP; // Deposit fee in basis points. Only for non vault farms/pools
        uint256 totalBoostedShares; // Represents the shares of the users, with according boosts.
    }
    // setup reward token and nft addresses
    address public PIXEL;
    INftV1 public _nftV1 = INftV1(0xdB553FA278e962a75105b84267B7cC42FE12a3e2);
    INftV1 public _nftV2 = INftV1(0x71c74e21EB22d0FF66A05Fb9086418bEA51cF2da);

    // Deposit Fee address - only for no-vault native farms and pools
    address public feeAddress = 0xFEB2df0A1db88c3d304A0a172a3C176370b9368d;

    address public zapAddress = 0x000000000000000000000000000000000000dEaD;

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    // 10%
    uint256 public ownerPIXELReward = 100;

    // penaltyBase in seconds - after that the penalty is 0 - 172800 2 days
    uint24 public penaltyBase = 172800;

    uint256 public PIXELMaxSupply = 10000e18;
    uint256 public PIXELPerBlock = 9e16;
    uint256 public startBlock = 21555183;

    // const
    uint16 constant TEN_THOUSAND = 10000;
    uint16 constant FOUR = 4;
    uint16 constant TWENTY_FIVE_HUNDRED = 2500;

    PoolInfo[] public poolInfo; // Info of each pool.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // Info of each user that stakes LP tokens.
    uint256 public totalAllocPoint = 0; // Total allocation points. Must be the sum of all allocation points in all pools.

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event DepositNFT(address indexed user, uint256 indexed pid, uint256 nftId);
    event WithdrawNFT(address indexed user, uint256 indexed pid, uint256 nftId);

    /// @dev Avoid to create pool twice with same LP token address.
    mapping(IERC20 => bool) public poolExistence;

    constructor(address _PIXEL) {
        PIXEL = _PIXEL;
    }

 /*    modifier nonDuplicated(IERC20 _lpToken) {
        require(!poolExistence[_lpToken], "nonDuplicated: duplicated");
        _;
    } */

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do. (Only if want tokens are stored here.)

    function add(
        uint256 _allocPoint,
        IERC20 _want,
        bool _withUpdate,
        address _strat,
        uint16 _depositFeeBP
    ) external onlyOwner /* nonDuplicated(_want) */ {
        require(
            _depositFeeBP <= 1000,
            "add: deposit fee can't be more than 10%"
        );

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint + (_allocPoint);
        poolExistence[_want] = true;
        poolInfo.push(
            PoolInfo({
                want: _want,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accPIXELPerShare: 0,
                strat: _strat,
                depositFeeBP: _depositFeeBP,
                totalBoostedShares: 0
            })
        );
    }

    // Update the given pool's PIXEL allocation point. Can only be called by the owner.
    function set(
        uint16 _pid,
        uint256 _allocPoint,
        bool _withUpdate,
        uint16 _depositFeeBP
    ) public onlyOwner {
        require(
            _depositFeeBP <= 1500,
            "add: deposit fee can't be more than 15%"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint =
            totalAllocPoint -
            (poolInfo[_pid].allocPoint) +
            (_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (IERC20(PIXEL).totalSupply() >= PIXELMaxSupply) {
            return 0;
        }
        return _to - (_from);
    }

    // View function to see pending PIXEL on frontend.
    function pendingPIXEL(uint16 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPIXELPerShare = pool.accPIXELPerShare;
        uint256 totalBoostedShares = pool.totalBoostedShares;
        if (block.number > pool.lastRewardBlock && totalBoostedShares != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 PIXELReward = (multiplier *
                PIXELPerBlock *
                pool.allocPoint) / totalAllocPoint;
            accPIXELPerShare =
                accPIXELPerShare +
                ((PIXELReward * 1e12) / totalBoostedShares);
        }
        uint256 pending = (user.boostedShares * accPIXELPerShare) /
            1e12 -
            user.rewardDebt;
        return pending;
    }

    // View function to see withdraw penalty on frontend. 5000 = 50%
    // uint256 defaults to 0 so user.nftId1 is 0 by default
    function currentPenalty(uint16 _pid, address _user)
        public
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_pid][_user];
        if ((block.timestamp - user.lastActionTimeStamp) < penaltyBase) {
            return
                TEN_THOUSAND -
                ((TWENTY_FIVE_HUNDRED *
                    (FOUR - user.nftId1) *
                    ((block.timestamp - user.lastActionTimeStamp))) /
                    penaltyBase);
        } else {
            return 0;
        }
    }

    // View function to see staked Want tokens on frontend.
    function stakedWantTokens(uint16 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 sharesTotal = IStrategy(pool.strat).sharesTotal();
        uint256 wantLockedTotal = IStrategy(poolInfo[_pid].strat)
            .wantLockedTotal();
        if (sharesTotal == 0) {
            return 0;
        }
        return (user.shares * wantLockedTotal) / sharesTotal;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint16 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint16 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        //uint256 sharesTotal = IStrategy(pool.strat).sharesTotal();
        if (pool.totalBoostedShares == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        if (multiplier <= 0) {
            return;
        }
        uint256 PIXELReward = (multiplier * PIXELPerBlock * pool.allocPoint) /
            totalAllocPoint;

        PIXELToken(PIXEL).mint(
            owner(),
            (PIXELReward * ownerPIXELReward) / (1000)
        );
        PIXELToken(PIXEL).mint(address(this), PIXELReward);

        pool.accPIXELPerShare =
            pool.accPIXELPerShare +
            ((PIXELReward * 1e12) / (pool.totalBoostedShares));

        pool.lastRewardBlock = block.number;
    }

    // Want tokens moved from user -> PIXELFarm (PIXEL allocation) -> Strat (compounding)
    function deposit(
        uint16 _pid,
        uint256 _wantAmt,
        address _to
    ) external nonReentrant {
        require(msg.sender == zapAddress || msg.sender == _to);

        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_to];

        if (user.shares > 0) {
            uint256 pending = (user.boostedShares * pool.accPIXELPerShare) /
                1e12 -
                user.rewardDebt;
            if ((block.timestamp - user.lastActionTimeStamp) < penaltyBase) {
                uint256 pendingAfterPenalty = (pending -
                    ((currentPenalty(_pid, _to) * pending) / TEN_THOUSAND));

                if (pending > 0) {
                    safePIXELTransfer(_to, pendingAfterPenalty);
                    safePIXELTransfer(
                        burnAddress,
                        pending - pendingAfterPenalty
                    );
                }
            } else if (pending > 0) {
                safePIXELTransfer(_to, pending);
            }
        }
        if (_wantAmt > 0) {
            uint256 _beforeDeposit = pool.want.balanceOf(address(this));
            pool.want.safeTransferFrom(
                address(msg.sender),
                address(this),
                _wantAmt
            );
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = (_wantAmt * pool.depositFeeBP) / 10000;
                pool.want.safeTransfer(feeAddress, depositFee);
            }
            uint256 _afterDeposit = pool.want.balanceOf(address(this));
            _wantAmt = _afterDeposit - _beforeDeposit;

            pool.want.safeIncreaseAllowance(pool.strat, _wantAmt);

            uint256 sharesAdded = IStrategy(poolInfo[_pid].strat).deposit(
                _to,
                _wantAmt
            );
            user.shares = user.shares + sharesAdded;
        }
        _updateBoostedShares(_pid, _to);
        user.rewardDebt = (user.boostedShares * pool.accPIXELPerShare) / 1e12;
        user.lastActionTimeStamp = block.timestamp;
        emit Deposit(_to, _pid, _wantAmt);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(
        uint16 _pid,
        uint256 _wantAmt,
        address _to
    ) external nonReentrant {
        require(msg.sender == zapAddress || msg.sender == _to);
        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_to];

        uint256 wantLockedTotal = IStrategy(poolInfo[_pid].strat)
            .wantLockedTotal();
        uint256 sharesTotal = IStrategy(poolInfo[_pid].strat).sharesTotal();

        require(user.shares > 0, "user.shares is 0");
        require(sharesTotal > 0, "sharesTotal is 0");

        // Withdraw pending PIXEL
        uint256 pending = (user.boostedShares * pool.accPIXELPerShare) /
            1e12 -
            user.rewardDebt;
        if ((block.timestamp - user.lastActionTimeStamp) < penaltyBase) {
            uint256 pendingAfterPenalty = pending -
                ((currentPenalty(_pid, _to) * pending) / TEN_THOUSAND);
            if (pending > 0) {
                safePIXELTransfer(_to, pendingAfterPenalty);
                safePIXELTransfer(burnAddress, pending - pendingAfterPenalty);
            }
        } else if (pending > 0) {
            safePIXELTransfer(_to, pending);
        }

        // Withdraw want tokens
        uint256 amount = (user.shares * wantLockedTotal) / sharesTotal;
        if (_wantAmt > amount) {
            _wantAmt = amount;
        }
        if (_wantAmt > 0) {
            uint256 sharesRemoved = IStrategy(poolInfo[_pid].strat).withdraw(
                _to,
                _wantAmt
            );

            if (sharesRemoved > user.shares) {
                user.shares = 0;
            } else {
                user.shares = user.shares - sharesRemoved;
            }

            uint256 wantBal = IERC20(pool.want).balanceOf(address(this));
            if (wantBal < _wantAmt) {
                _wantAmt = wantBal;
            }
            pool.want.safeTransfer(address(msg.sender), _wantAmt);
        }
        _updateBoostedShares(_pid, _to);
        user.rewardDebt = (user.boostedShares * pool.accPIXELPerShare) / 1e12;
        user.lastActionTimeStamp = block.timestamp;
        emit Withdraw(_to, _pid, _wantAmt);
    }

    /// @dev Deposit NFTv1 to masterchef to get reduced withdraw penalty.
    function depositNFTv1(uint16 _pid, uint256 _nftId) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.nftId1 == 0, "user already has a NFTv1");
        if (user.nftId1 == 0) {
            _nftV1.safeTransferFrom(address(msg.sender), address(this), _nftId);
            user.nftId1 = _nftId;
        } else {
            revert("Invalid NFT");
        }
        updatePool(_pid);
        uint256 pending = (user.boostedShares * pool.accPIXELPerShare) /
            1e12 -
            user.rewardDebt;
        if ((block.timestamp - user.lastActionTimeStamp) < penaltyBase) {
            uint256 pendingAfterPenalty = pending -
                ((currentPenalty(_pid, msg.sender) * pending) / TEN_THOUSAND);
            if (pending > 0) {
                safePIXELTransfer(msg.sender, pendingAfterPenalty);
                safePIXELTransfer(burnAddress, pending - pendingAfterPenalty);
            }
        } else if (pending > 0) {
            safePIXELTransfer(msg.sender, pending);
        }

        _updateBoostedShares(_pid, msg.sender);
        user.rewardDebt = (user.boostedShares * pool.accPIXELPerShare) / 1e12;
        user.lastActionTimeStamp = block.timestamp;
    }

    /// @dev Deposit NFTv2 to masterchef to get multiplier in farming.
    function depositNFTv2(uint16 _pid, uint256 _nftId) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.nftId2 == 0, "user already has a NFTv2");

        if (user.nftId2 == 0) {
            _nftV2.safeTransferFrom(address(msg.sender), address(this), _nftId);
            user.nftId2 = _nftId;
        } else {
            revert("Invalid NFT");
        }

        updatePool(_pid);
        uint256 pending = (user.boostedShares * pool.accPIXELPerShare) /
            1e12 -
            user.rewardDebt;
        if ((block.timestamp - user.lastActionTimeStamp) < penaltyBase) {
            uint256 pendingAfterPenalty = pending -
                ((currentPenalty(_pid, msg.sender) * pending) / TEN_THOUSAND);
            if (pending > 0) {
                safePIXELTransfer(msg.sender, pendingAfterPenalty);
                safePIXELTransfer(burnAddress, pending - pendingAfterPenalty);
            }
        } else if (pending > 0) {
            safePIXELTransfer(msg.sender, pending);
        }

        _updateBoostedShares(_pid, msg.sender);
        user.rewardDebt = (user.boostedShares * pool.accPIXELPerShare) / 1e12;
        user.lastActionTimeStamp = block.timestamp;
        emit DepositNFT(msg.sender, _pid, _nftId);
    }

    /// @dev Withdraw NFTv1 from masterchef.
    function withdrawNFTv1(uint16 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.nftId1 > 0, "user has no NFT");

        updatePool(_pid);
        uint256 pending = (user.boostedShares * pool.accPIXELPerShare) /
            1e12 -
            user.rewardDebt;
        if ((block.timestamp - user.lastActionTimeStamp) < penaltyBase) {
            uint256 pendingAfterPenalty = pending -
                ((currentPenalty(_pid, msg.sender) * pending) / TEN_THOUSAND);
            if (pending > 0) {
                safePIXELTransfer(msg.sender, pendingAfterPenalty);
                safePIXELTransfer(burnAddress, pending - pendingAfterPenalty);
            }
        } else if (pending > 0) {
            safePIXELTransfer(msg.sender, pending);
        }

        uint256 _nftId = user.nftId1;
        _nftV1.transferFrom(address(this), address(msg.sender), user.nftId1);
        user.nftId1 = 0;

        _updateBoostedShares(_pid, msg.sender);
        user.rewardDebt = (user.boostedShares * pool.accPIXELPerShare) / 1e12;
        user.lastActionTimeStamp = block.timestamp;
        emit WithdrawNFT(msg.sender, _pid, _nftId);
    }

    /// @dev Withdraw NFTv2 from masterchef.
    function withdrawNFTv2(uint16 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.nftId2 > 0, "user has no NFT");

        updatePool(_pid);
        uint256 pending = (user.boostedShares * pool.accPIXELPerShare) /
            1e12 -
            user.rewardDebt;
        if ((block.timestamp - user.lastActionTimeStamp) < penaltyBase) {
            uint256 pendingAfterPenalty = pending -
                ((currentPenalty(_pid, msg.sender) * pending) / TEN_THOUSAND);
            if (pending > 0) {
                safePIXELTransfer(msg.sender, pendingAfterPenalty);
                safePIXELTransfer(burnAddress, pending - pendingAfterPenalty);
            }
        } else if (pending > 0) {
            safePIXELTransfer(msg.sender, pending);
        }

        uint256 _nftId = user.nftId2;
        _nftV2.transferFrom(address(this), address(msg.sender), user.nftId2);
        user.nftId2 = 0;

        _updateBoostedShares(_pid, msg.sender);
        user.rewardDebt = (user.boostedShares * pool.accPIXELPerShare) / 1e12;
        user.lastActionTimeStamp = block.timestamp;
        emit WithdrawNFT(msg.sender, _pid, _nftId);
    }

    // Withdraw without caring about rewards and nfts. EMERGENCY ONLY.
    function emergencyWithdraw(uint16 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 wantLockedTotal = IStrategy(poolInfo[_pid].strat)
            .wantLockedTotal();
        uint256 sharesTotal = IStrategy(poolInfo[_pid].strat).sharesTotal();
        uint256 amount = (user.shares * wantLockedTotal) / sharesTotal;

        IStrategy(poolInfo[_pid].strat).withdraw(msg.sender, amount);

        pool.want.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
        user.shares = 0;
        user.boostedShares = 0;
        user.rewardDebt = 0;
        user.nftId1 = 0;
        user.nftId2 = 0;
    }

    /// @dev Update the strength of the user. This is the portion from the pool of the user.
    function _updateBoostedShares(uint16 _pid, address _to) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_to];

        uint256 oldBoostedShares = user.boostedShares;

        user.boostedShares = user.shares;
        if (user.nftId2 > 0) {
            uint256 bonus = _nftV2.generateRARITYofTokenById(user.nftId2);
            user.boostedShares =
                user.boostedShares +
                ((user.boostedShares * (bonus)) / 10);
        }
        pool.totalBoostedShares =
            pool.totalBoostedShares +
            (user.boostedShares) -
            (oldBoostedShares);
    }

    // Safe PIXEL transfer function, just in case if rounding error causes pool to not have enough
    function safePIXELTransfer(address _to, uint256 _PIXELAmt) internal {
        uint256 PIXELBal = IERC20(PIXEL).balanceOf(address(this));
        if (_PIXELAmt > PIXELBal) {
            IERC20(PIXEL).transfer(_to, PIXELBal);
        } else {
            IERC20(PIXEL).transfer(_to, _PIXELAmt);
        }
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount)
        public
        onlyOwner
    {
        require(_token != PIXEL, "!safe");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function setPenaltyBase(uint24 _penaltyBase) external onlyOwner {
        require(_penaltyBase < 172800, "must be lower than 172800");
        penaltyBase = _penaltyBase;
    }

    function setZapAddress(address _address) external onlyOwner {
        zapAddress = _address;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}