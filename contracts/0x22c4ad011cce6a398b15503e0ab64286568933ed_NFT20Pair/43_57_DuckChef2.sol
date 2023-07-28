pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IERC20MintBurn.sol";
import "../interfaces/INFT20.sol";
import "./NFT20.sol";

import "hardhat/console.sol";

interface IMigratorChef {
    // Perform LP token migration from legacy UniswapV2 to tokenSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // tokenSwap must mint EXACTLY the same amount of tokenSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// MasterChef is the master of token. He can make token and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once token is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract DuckChef2 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct NftInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.acctokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `acctokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that tokens distribution occurs.
        uint256 accTokenPerShare; // Accumulated tokens per share, times 1e12. See below.
    }
    // The token TOKEN!
    IERC20MintBurn public token;

    // the NFT20 Contract
    INFT20 public nft20;

    // Dev address.
    address public devaddr;
    // Block number when bonus token period ends.
    uint256 public bonusEndBlock;
    // token tokens created per block.
    uint256 public tokenPerBlock;
    // Bonus muliplier for early token makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;
    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each NFT that registered to get rewards.
    mapping(uint256 => NftInfo) public nftInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when token mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        IERC20MintBurn _token,
        INFT20 _nft20,
        address _devaddr,
        uint256 _tokenPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        token = _token;
        nft20 = _nft20;
        devaddr = _devaddr;
        tokenPerBlock = _tokenPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accTokenPerShare: 0
            })
        );
    }

    // Update the given pool's token allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    // View function to see pending tokens on frontend.
    function pendingToken(uint256 _pid, uint256 _nftId)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        NftInfo storage nft = nftInfo[_nftId];
        console.log("amount", nft.amount);
        uint256 accTokenPerShare = pool.accTokenPerShare;
        console.log("accTokenPerShare", accTokenPerShare);

        uint256 lpSupply = nft20.totalStaked(address(pool.lpToken));

        console.log("lpSupply", lpSupply);

        // uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward =
                multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accTokenPerShare = accTokenPerShare.add(
                tokenReward.mul(1e12).div(lpSupply)
            );

            console.log("accTokenPerShare", accTokenPerShare);
        }

        console.log(
            "last",
            nft.amount.mul(accTokenPerShare).div(1e12).sub(nft.rewardDebt)
        );
        console.log("nft.rewardDebt", nft.rewardDebt);

        return nft.amount.mul(accTokenPerShare).div(1e12).sub(nft.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = nft20.totalStaked(address(pool.lpToken));
        // uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward =
            multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        token.mint(devaddr, tokenReward.div(10));
        token.mint(address(this), tokenReward);
        pool.accTokenPerShare = pool.accTokenPerShare.add(
            tokenReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Register NFT20 token to DuckChef for $TOKEN allocation.
    function register(uint256 _pid, uint256 _nftId) public {
        PoolInfo storage pool = poolInfo[_pid];
        (address _erc20address, uint256 _amount, ) = nft20.getNFTInfo(_nftId);
        require(_erc20address == address(pool.lpToken), "NFT don't match pool");
        require(nft20.ownerOf(_nftId) == msg.sender, "!owner");
        NftInfo storage nft = nftInfo[_nftId];

        require(nft.amount == 0, "Can't register twice");

        updatePool(_pid);

        nft.amount = _amount;

        // @Maybe we can ake this out as it will be by single NFT each time and when withdraw
        // NFT info is deleted.

        // TODO! check this, without this was returning 0 all the time.
        // nft.rewardDebt = nft.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _nftId);
    }

    // Withdraw all earnings and unregister NFT.
    function withdraw(uint256 _pid, uint256 _nftId) public {
        PoolInfo storage pool = poolInfo[_pid];
        // does nft token match pool?
        (address _erc20address, , ) = nft20.getNFTInfo(_nftId);
        require(_erc20address == address(pool.lpToken), "NFT don't match pool");
        // make sure msg.sender is owner of nft
        require(nft20.ownerOf(_nftId) == msg.sender, "!owner");
        NftInfo storage nft = nftInfo[_nftId];

        updatePool(_pid);
        uint256 pending =
            nft.amount.mul(pool.accTokenPerShare).div(1e12).sub(nft.rewardDebt);
        if (pending > 0) {
            safeTokenTransfer(msg.sender, pending);
        }

        // delete this NFT as it is paying off all earnings up until this point.
        delete nftInfo[_nftId];

        emit Withdraw(msg.sender, _pid, _nftId);
    }

    //if staker owned many NFTs with same lp tokens use batch withdraw
    function withdrawBatch(uint256 _pid, uint256[] memory _nftIds) public {
        for (uint256 i = 0; i < _nftIds.length; i++) {
            withdraw(_pid, _nftIds[i]);
        }
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough tokens.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = token.balanceOf(address(this));
        if (_amount > tokenBal) {
            token.transfer(_to, tokenBal);
        } else {
            token.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}