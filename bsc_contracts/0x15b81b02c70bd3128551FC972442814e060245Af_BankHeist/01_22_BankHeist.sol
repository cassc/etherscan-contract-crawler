import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

pragma solidity ^0.8.7;

abstract contract ManageableUpgradeable is OwnableUpgradeable {
    mapping(address => bool) private _managers;
    event ManagerAdded(address indexed manager_);
    event ManagerRemoved(address indexed manager_);

    function managers(address manager_) public view virtual returns (bool) {
        return _managers[manager_];
    }

    modifier onlyManager() {
        require(_managers[_msgSender()], "Manageable: caller is not the owner");
        _;
    }

    function removeManager(address manager_) public virtual onlyOwner {
        _managers[manager_] = false;
        emit ManagerRemoved(manager_);
    }

    function addManager(address manager_) public virtual onlyOwner {
        require(
            manager_ != address(0),
            "Manageable: new owner is the zero address"
        );
        _managers[manager_] = true;
        emit ManagerAdded(manager_);
    }
}

contract BankHeist is
    Initializable,
    IERC20Upgradeable,
    OwnableUpgradeable,
    ManageableUpgradeable
{
    uint256 public override totalSupply;
    string public name;
    uint8 public decimals;
    string public symbol;

    IERC20Upgradeable public LP;
    address public BANK;

    uint256 public maxStakingsPerTier;
    bool public transfersEnabled;

    address[] public tokens;

    struct Rewards {
        uint256 timestamp;
        uint256[] totalStaked;
        address token;
        uint256 amount;
    }

    Rewards[] public rewards;

    struct Tier {
        uint256 duration;
        uint256 totalStaked;
        uint256 allocation;
    }

    Tier[] public tiers;

    struct Lock {
        uint256 tier;
        uint256 amount;
        uint256 start;
        uint256 release;
        uint256 claim;
    }

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => uint256[]) public stakings;
    mapping(address => Lock[]) public lockedTokens;
    mapping(address => bool) public isBlacklisted;
    mapping(address => uint256) public thresholds;
    mapping(address => uint256) public counter;

    function initialize(
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol,
        address lp,
        address bank,
        uint256 maxStakings
    ) public initializer {
        __Ownable_init();
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;

        LP = IERC20Upgradeable(lp);
        BANK = bank;

        maxStakingsPerTier = maxStakings;
        transfersEnabled = false;

        tokens = [
            0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,
            0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56,
            0xf22894d191212b6871182417dF61aD832bCe57C7
        ];

        tiers.push(Tier(30 days, 0, 5));
        tiers.push(Tier(90 days, 0, 15));
        tiers.push(Tier(180 days, 0, 30));
        tiers.push(Tier(365 days, 0, 50));

        emit OwnershipTransferred(address(0), _msgSender());
    }

    function getTiers() public view returns (Tier[] memory) {
        return tiers;
    }

    function getLockedTokens(address user) public view returns (Lock[] memory) {
        return lockedTokens[user];
    }

    function getStakings(address user) public view returns (uint256[] memory) {
        return stakings[user];
    }

    function unsafe_inc8(uint8 x) private pure returns (uint8) {
        unchecked {
            return x + 1;
        }
    }

    function unsafe_inc(uint256 x) private pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    function getAvailableRewards(address user)
        public
        view
        returns (uint256[] memory)
    {
        Lock[] memory lock = lockedTokens[user];
        Rewards[] memory rewards_ = rewards;
        Tier[] memory tiers_ = tiers;
        address[] memory tokens_ = tokens;

        uint256[] memory values = new uint256[](tokens.length);

        for (uint8 i = 0; i < lock.length; i = unsafe_inc8(i)) {
            for (uint256 j = 0; j < rewards_.length; j = unsafe_inc(j)) {
                if (lock[i].claim < rewards_[j].timestamp) {
                    for (uint8 k = 0; k < tokens_.length; k = unsafe_inc8(k)) {
                        if (rewards_[j].token == tokens_[k]) {
                            values[k] +=
                                (((rewards_[j].amount *
                                    tiers_[lock[i].tier].allocation) / 100) *
                                    lock[i].amount) /
                                rewards_[j].totalStaked[lock[i].tier];
                            break;
                        }
                    }
                }
            }
        }
        return values;
    }

    function _claimRewards(address user) internal {
        uint256[] memory values = getAvailableRewards(user);

        Lock[] memory lock = lockedTokens[user];

        for (uint256 i = 0; i < lock.length; i++) {
            lockedTokens[user][i].claim = block.timestamp;
        }

        for (uint256 i = 0; i < values.length; i++) {
            if (values[i] > 0) {
                IERC20Upgradeable(tokens[i]).transferFrom(
                    BANK,
                    user,
                    values[i]
                );
            }
        }
    }

    function claimRewards() public {
        _claimRewards(_msgSender());
    }

    function _addRewards(address token, uint256 amount) internal {
        uint256[] memory totalStaked = new uint256[](tiers.length);

        for (uint256 i = 0; i < tiers.length; i++) {
            totalStaked[i] = tiers[i].totalStaked;
        }

        rewards.push(
            Rewards({
                timestamp: block.timestamp,
                totalStaked: totalStaked,
                token: token,
                amount: amount
            })
        );
    }

    function addRewards(address token, uint256 amount) public onlyManager {
        IERC20Upgradeable(token).transfer(BANK, amount);
        counter[token] += amount;
        if (counter[token] >= thresholds[token]) {
            _addRewards(token, amount);
            counter[token] = 0;
        }
    }

    function addRewardsOwner(address token, uint256 amount) public onlyOwner {
        _addRewards(token, amount);
    }

    function stake(uint256 tierId, uint256 amount) public {
        require(tierId < tiers.length, "STAKE: Invalid tier");
        if (stakings[_msgSender()].length == 0) {
            for (uint256 i = 0; i < tiers.length; i++) {
                stakings[_msgSender()].push(0);
            }
        }
        stakings[_msgSender()][tierId] += 1;
        require(
            stakings[_msgSender()][tierId] <= maxStakingsPerTier,
            "STAKE: You have too many stakings running for that tier."
        );
        LP.transferFrom(_msgSender(), BANK, amount);
        lockedTokens[_msgSender()].push(
            Lock(
                tierId,
                amount,
                block.timestamp,
                block.timestamp + tiers[tierId].duration,
                block.timestamp
            )
        );
        tiers[tierId].totalStaked += amount;
        _mint(_msgSender(), amount);
    }

    function unstake(uint256 lockId) public {
        Lock memory lock = lockedTokens[_msgSender()][lockId];
        require(
            block.timestamp >= lock.release,
            "UNSTAKE: Not yet unstakeable."
        );
        _claimRewards(_msgSender());
        if (lockedTokens[_msgSender()].length > 1) {
            lockedTokens[_msgSender()][lockId] = lockedTokens[_msgSender()][
                lockedTokens[_msgSender()].length - 1
            ];
        }
        lockedTokens[_msgSender()].pop();
        stakings[_msgSender()][lock.tier] -= 1;
        tiers[lock.tier].totalStaked -= lock.amount;
    }

    function increaseStake(uint256 lockId, uint256 amount) public {
        require(
            lockId < lockedTokens[_msgSender()].length,
            "INCREASE: Invalid tier"
        );
        _claimRewards(_msgSender());
        Lock memory lock = lockedTokens[_msgSender()][lockId];
        LP.transferFrom(_msgSender(), BANK, amount);
        tiers[lock.tier].totalStaked += amount;
        lock.amount += amount;
        lock.start = block.timestamp;
        lock.release = block.timestamp + tiers[lock.tier].duration;
        lock.claim = block.timestamp;
        lockedTokens[_msgSender()][lockId] = lock;
        _mint(_msgSender(), amount);
    }

    function moveStake(uint256 lockId, uint256 tierId) public {
        require(
            lockId < lockedTokens[_msgSender()].length,
            "MOVE: Invalid tier"
        );
        require(tierId < tiers.length, "MOVE: Invalid tier");
        Lock memory lock = lockedTokens[_msgSender()][lockId];
        require(lock.tier < tierId, "MOVE: Can only move up.");
        tiers[lock.tier].totalStaked -= lock.amount;
        tiers[tierId].totalStaked += lock.amount;
        stakings[_msgSender()][tierId] += 1;
        stakings[_msgSender()][lock.tier] -= 1;
        require(
            stakings[_msgSender()][tierId] <= maxStakingsPerTier,
            "STAKE: You have too many stakings running for that tier."
        );
        _claimRewards(_msgSender());
        lock.tier = tierId;
        lock.start = block.timestamp;
        lock.release = block.timestamp + tiers[tierId].duration;
        lock.claim = block.timestamp;
        lockedTokens[_msgSender()][lockId] = lock;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) private {
        require(
            _from != address(0),
            "TRANSFER: Transfer from the dead address"
        );
        require(_to != address(0), "TRANSFER: Transfer to the dead address");
        require(_value > 0, "TRANSFER: Invalid amount");
        require(isBlacklisted[_from] == false, "TRANSFER: isBlacklisted");
        require(balances[_from] >= _value, "TRANSFER: Insufficient balance");
        require(transfersEnabled, "TRANSFER: Transfers are disabled.");
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool success)
    {
        _transfer(_msgSender(), _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool success) {
        if (allowances[_from][_msgSender()] < type(uint256).max) {
            allowances[_from][_msgSender()] -= _value;
        }
        _transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)
        public
        override
        returns (bool success)
    {
        _approve(_msgSender(), _spender, _value);
        return true;
    }

    function _approve(
        address _sender,
        address _spender,
        uint256 _value
    ) private returns (bool success) {
        allowances[_sender][_spender] = _value;
        emit Approval(_sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowances[_owner][_spender];
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        balances[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }

    function unstake(address user, uint256 lockId) public onlyOwner {
        Lock memory lock = lockedTokens[user][lockId];
        lockedTokens[user][lockId] = lockedTokens[user][
            lockedTokens[user].length - 1
        ];
        lockedTokens[user].pop();
        stakings[user][lock.tier] -= 1;
        tiers[lock.tier].totalStaked -= lock.amount;
        _burn(user, lock.amount);
        LP.transferFrom(BANK, user, lock.amount);
    }

    function setTransfersEnabled(bool value) public onlyOwner {
        transfersEnabled = value;
    }

    function setIsBlacklisted(address user, bool value) public onlyOwner {
        isBlacklisted[user] = value;
    }

    function setTokens(address[] memory tokens_) public onlyOwner {
        tokens = tokens_;
    }

    function setLp(address lp) public onlyOwner {
        LP = IERC20Upgradeable(lp);
    }

    function setThresholds(address token, uint256 amount) public onlyOwner {
        thresholds[token] = amount;
    }

    function withdrawTokens() public onlyOwner {
        _transfer(address(this), owner(), balanceOf(address(this)));
    }
}