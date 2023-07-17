// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AlgoPool is Ownable, ERC721Enumerable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // Native NFT -> Every Time you create a token it gives the token an id
    Counters.Counter private _tokenIdTracker;

    address public stablecoin;
    address public avscoin;

    constructor(
        address _stablecoin,
        string memory name,
        string memory symbol,
        address _avscoin
    ) ERC721(name, symbol) {
        stablecoin = _stablecoin;
        avscoin = _avscoin;
    }

    struct PoolInfo {
        uint256 minDeposit;
        uint256 periodInterestRate;
        uint256 noncesToUnlock;
        bool locked;
    }

    struct BondInfo {
        uint256 depositTimestamp;
        uint256 amount;
        uint256 pendingInterest;
        uint256 currentNonce;
        bool withdrawn;
    }

    struct StakeInfo {
        uint256 amount;
        uint256 stakedAt;
    }

    // Info of each pool.
    PoolInfo[] public poolInfo;

    uint256 public inTrading;
    uint256 public noncePeriod = 1 weeks; // 604800

    mapping(uint256 => mapping(uint256 => BondInfo)) public bondInfo;
    mapping(uint256 => uint256) public bondPool;
    mapping(address => StakeInfo) public stakesInfo;
    mapping(address => uint256) public totalDeposit;

    uint256 public rewardAPY = 800;
    uint256 public stakingAmount = 0; // Can be updated by the Owner
    uint256 public rewardAvsCoinBalance = 0;

    function addRewards(uint256 _amount) public onlyOwner {
        IERC20(avscoin).transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        rewardAvsCoinBalance = rewardAvsCoinBalance.add(_amount);
    }

    function setStakingAmount(uint256 _stakingAmount) public onlyOwner {
        stakingAmount = _stakingAmount;
    }

    function createPool(
        uint256 _minDeposit,
        uint256 _periodInterestRate,
        uint256 _noncesToUnlock,
        bool _locked
    ) external onlyOwner {
        poolInfo.push(
            PoolInfo({
                minDeposit: _minDeposit,
                periodInterestRate: _periodInterestRate,
                noncesToUnlock: _noncesToUnlock,
                locked: _locked
            })
        );
    }

    function lockPool(uint256 _poolId, bool _lock) public onlyOwner {
        PoolInfo storage pool = poolInfo[_poolId];
        pool.locked = _lock;
    }

    // Calculate how many pools exist.
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function depositAvsToken(uint256 _amount) public returns (bool) {
        require(
            _amount > stakingAmount,
            "Amount must be greater than stakingAmount"
        );
        IERC20(avscoin).transferFrom(msg.sender, address(this), _amount);
        StakeInfo storage stakeInfo = stakesInfo[msg.sender];
        stakeInfo.stakedAt = block.timestamp;
        stakeInfo.amount = stakeInfo.amount.add(_amount);
        return true;
    }

    function withdrawAvsToken() public returns (bool) {
        StakeInfo storage stakeInfo = stakesInfo[msg.sender];
        require(stakeInfo.amount > 0, "You have nothing deposited to withdraw");
        require(
            balanceOf(msg.sender) == 0,
            "Cant withdraw you have an active bond"
        );
        uint256 timePassed = block.timestamp.sub(stakeInfo.stakedAt);
        // 31,536,000 -> Seconds in a year
        uint256 rewardsPending = stakeInfo
            .amount
            .mul(rewardAPY)
            .div(10000)
            .mul(timePassed)
            .div(31536000);
        require(
            rewardsPending <= rewardAvsCoinBalance,
            "Pending rewards is greater than available reward balance"
        );

        uint256 withdrawAmount = stakeInfo.amount.add(rewardsPending);
        delete stakesInfo[msg.sender];
        rewardAvsCoinBalance = rewardAvsCoinBalance.sub(rewardsPending);
        IERC20(avscoin).transfer(msg.sender, withdrawAmount);
        return true;
    }

    function depositToPool(uint256 _poolId, uint256 _amount) public {
        StakeInfo storage stakeInfo = stakesInfo[msg.sender];
        require(
            stakeInfo.amount.mul(10) >= totalDeposit[msg.sender].add(_amount),
            "Not enough AVS staked in the pool"
        );
        PoolInfo storage pool = poolInfo[_poolId];
        require(pool.locked == false, "Pool is locked!");
        require(
            pool.minDeposit <= _amount,
            "Amount is less than minimum amount"
        );
        IERC20(stablecoin).transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _tokenIdTracker.current());
        bondPool[_tokenIdTracker.current()] = _poolId;
        BondInfo storage bond = bondInfo[_poolId][_tokenIdTracker.current()];
        bond.depositTimestamp = block.timestamp;
        bond.amount = _amount;
        bond.pendingInterest = _amount.mul(pool.periodInterestRate).div(10000);
        bond.currentNonce = 0;
        totalDeposit[msg.sender] = totalDeposit[msg.sender].add(_amount);
        _tokenIdTracker.increment();
    }

    function withdrawPrinciple(uint256 _bondId) public {
        require(ownerOf(_bondId) == msg.sender, "Not your contract");
        BondInfo storage bond = bondInfo[bondPool[_bondId]][_bondId];
        PoolInfo storage pool = poolInfo[bondPool[_bondId]];
        require(
            bond.currentNonce == pool.noncesToUnlock,
            "Can't withdraw before unlock."
        );
        require(bond.withdrawn == false, "Already Claimed");
        // Mark as Claimed
        bond.withdrawn = true;
        // Send back the principle.
        _burn(_bondId);
        totalDeposit[msg.sender] = totalDeposit[msg.sender].sub(bond.amount);
        IERC20(stablecoin).transfer(msg.sender, bond.amount);
    }

    function claimInterest(uint256 _bondId) public nonReentrant {
        require(ownerOf(_bondId) == msg.sender, "Not your contract");
        BondInfo storage bond = bondInfo[bondPool[_bondId]][_bondId];
        PoolInfo storage pool = poolInfo[bondPool[_bondId]];
        uint256 oldNonce = bond.currentNonce;
        require(oldNonce < pool.noncesToUnlock, "Everything Claimed");

        require(
            block.timestamp >=
                bond.depositTimestamp.add(
                    noncePeriod.mul(bond.currentNonce.add(1))
                ),
            "Wait until next claim."
        );

        uint256 timePassed = block.timestamp.sub(bond.depositTimestamp);
        uint256 noncesToClaim = timePassed.div(noncePeriod);

        if (noncesToClaim > pool.noncesToUnlock) {
            noncesToClaim = pool.noncesToUnlock;
        }

        bond.currentNonce = noncesToClaim;

        IERC20(stablecoin).transfer(
            msg.sender,
            bond.pendingInterest.div(pool.noncesToUnlock).mul(
                bond.currentNonce - oldNonce
            )
        );
    }

    function withdrawToTradingAdmin(uint256 _amount) external onlyOwner {
        inTrading = inTrading.add(_amount);
        IERC20(stablecoin).transfer(msg.sender, _amount);
    }

    function depositAdmin(uint256 _amount) external onlyOwner {
        require(inTrading >= _amount, "Withdraw amount smaller than deposit.");
        inTrading = inTrading.sub(_amount);
        IERC20(stablecoin).transferFrom(msg.sender, address(this), _amount);
    }

    function depositStableCoin(uint256 _amount) external onlyOwner {
        IERC20(stablecoin).transferFrom(msg.sender, address(this), _amount);
    }

    function changeNoncePeriod(uint256 _newPeriod) external onlyOwner {
        noncePeriod = _newPeriod;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from != address(0)) require(to == address(0));
    }
}