// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import "./IStakingV2Vendor.sol";
import './IStakingV2Factory.sol';
import './IStakingDelegate.sol';

/**
 * @title Token Staking
 * @dev BEP20 compatible token.
 */
contract StakingV2 is Ownable, AccessControl {
    using SafeERC20 for IERC20;
    using Address for address;

    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 public constant MAINTAINER_ROLE = keccak256('MAINTAINER_ROLE');

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt; // backwards compatibility
        uint256 pendingRewards; // backwards compatibility
        uint256 lockedTimestamp;
        uint256 lockupTimestamp;
        uint256 lockupTimerange;
        uint256 virtAmount;
    }

    struct PoolInfo {
        uint256 lastBlock;
        uint256 tokenPerShare;
        uint256 tokenRealStaked;
        uint256 tokenVirtStaked;
        uint256 tokenRewarded;
        uint256 tokenTotalLimit;
        uint256 lockupMaxTimerange;
        uint256 lockupMinTimerange;
    }

    IERC20 public token;

    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public tokenPerBlock; // backwards compatibility
    uint256 public startBlock;
    uint256 public closeBlock;
    uint256 public maxPid;
    uint256 private constant MAX = ~uint256(0);

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => address) public vendorInfo;
    address[] public vendors;
    address[] public delistedVendors;
    mapping(address => bool) public allowedStakingInstances;
    uint256[] public multipliers = [
         12742, 13081, 13428, 13785, 14152, 14528, 14914, 15311, 15718, 16136, 16565, 17005,
         17457, 17921, 18398, 18887, 19389, 19904, 20433, 20976, 21534, 22107, 22694, 23298,
         23917, 24553, 25205, 25876, 26563, 27270, 27995, 28732, 29503, 30287, 31092, 31919,
         32767, 33638, 34533, 35451, 36393, 37360, 38354, 39373, 40420, 41494, 42598, 43730,
         44892, 46086, 47311, 48569, 49860, 51185, 52546, 53943, 55377, 56849, 58360, 59912,
         61505, 63140, 64818, 66541, 68310, 70126, 71990, 73904, 75869, 77886, 79956, 82082,
         84264, 86504, 88803, 91164, 93587, 96075, 98629,101251,103943,106706,109543,112455,
        115444,118513,121664,124898,128218,131627,135126,138718,142406,146192,150078,154067
    ];

    IStakingDelegate public delegate;
    IStakingV2Factory public factory;

    event PoolAdded(uint256 minTimer, uint256 maxTimer, uint256 limit);
    event Deposited(address indexed user, uint256 indexed pid, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed pid, address indexed token, uint256 amount);
    event WithdrawnReward(address indexed user, uint256 indexed pid, address indexed token, uint256 amount);
    event WithdrawnRemain(address indexed user, uint256 indexed pid, address indexed token, uint256 amount);
    event TokenVendorChanged(address indexed token, address indexed vendor);
    event DelegateAddressChanged(address indexed addr);
    event FactoryAddressChanged(address indexed addr);
    event AllowedAmountsChanged(uint256 minAmount, uint256 maxAmount);
    event StakingInstanceChanged();

    event StartBlockChanged(uint256 block);
    event CloseBlockChanged(uint256 block);

    modifier onlyAuthority {
        require(msg.sender == owner() || hasRole(MAINTAINER_ROLE, msg.sender), 'Staking: only authorities can call this method');
        _;
    }

    constructor(IERC20 _token, uint256 _minPoolTimer, uint256 _maxPoolTimer, uint256 _minAmount, uint256 _maxAmount, uint256 _poolLimit) {
        require(address(_token) != address(0), 'Staking: token address needs to be different than zero!');
        token = _token;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        addPool(_minPoolTimer, _maxPoolTimer, _poolLimit);
        tokenPerBlock = 1e4; // in this interface tokenPerBlock serves purpose as a precision gadget

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MAINTAINER_ROLE, ADMIN_ROLE);

        _setupRole(ADMIN_ROLE, address(this));
        _setupRole(MAINTAINER_ROLE, owner());
    }

    function addMaintainer(address account) external onlyOwner returns (bool) {
        bytes4 selector = this.grantRole.selector;
        address(this).functionCall(abi.encodeWithSelector(selector, MAINTAINER_ROLE, account));
        return true;
    }

    function delMaintainer(address account) external onlyOwner returns (bool) {
        bytes4 selector = this.revokeRole.selector;
        address(this).functionCall(abi.encodeWithSelector(selector, MAINTAINER_ROLE, account));
        return true;
    }

    function isMaintainer(address account) external view returns (bool) {
        return hasRole(MAINTAINER_ROLE, account);
    }

    // staking instances need to be added to properly chain multiple staking instances
    function addStakingInstances(address[] memory stakingInstances, bool status) public onlyOwner {
        for (uint i=0; i<stakingInstances.length; ++i) {
            allowedStakingInstances[stakingInstances[i]] = status;
        }
        emit StakingInstanceChanged();
    }

    // factory is used to instantiate staking vendors to decrease size of this contract
    function setFactoryAddress(IStakingV2Factory _factory) public onlyOwner {
        require(address(_factory) != address(0), 'Staking: factory address needs to be different than zero!');
        factory = _factory;
        emit FactoryAddressChanged(address(factory));
    }

    // set min/max amount possible
    function setAllowedAmounts(uint256 _minAmount, uint256 _maxAmount) public onlyOwner {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        emit AllowedAmountsChanged(minAmount, maxAmount);
    }

    // set token reward with infinite time range
    function setTokenPerBlock(IERC20 _token, uint256 _tokenPerBlock) public onlyAuthority {
        require(startBlock != 0, 'Staking: cannot add reward before setting start block');
        require(address(_token) != address(0), 'Staking: token address needs to be different than zero!');

        address addr = vendorInfo[address(_token)];
        // if vendor for asset already exists and is not closed then overwrite its reward schedule instead of invoking new one
        if (addr != address(0)) {
            IStakingV2Vendor vendor = IStakingV2Vendor(addr);
            uint256 _prevCloseBlock = vendor.closeBlock();
            if (_prevCloseBlock == 0 || block.number <= _prevCloseBlock) {
                // we need to update the pool manually in this case because of premature return
                for (uint i=0; i<maxPid; i++) updatePool(i);
                _token.approve(address(vendor), MAX);
                vendor.setTokenPerBlock(_tokenPerBlock, vendor.startBlock(), vendor.closeBlock());
                return;
            }
        }

        setTokenPerBlock(_token, _tokenPerBlock, 0);
    }

    // set token reward for some specific time range
    function setTokenPerBlock(IERC20 _token, uint256 _tokenPerBlock, uint256 _blockRange) public onlyAuthority {
        require(startBlock != 0, 'Staking: cannot add reward before setting start block');
        require(address(_token) != address(0), 'Staking: token address needs to be different than zero!');

        address addr = vendorInfo[address(_token)];
        uint256 _startBlock = block.number > startBlock ? block.number : startBlock;
        uint256 _closeBlock = _blockRange == 0 ? 0 : _startBlock + _blockRange;

        // if vendor for asset already exists overwrite startBlock with the value that vendor initally held instead
        if (addr != address(0)) {
            // start block has to remain same regardless of current timestamp and block range
            _startBlock = IStakingV2Vendor(addr).startBlock();
        }

        setTokenPerBlock(_token, _tokenPerBlock, _startBlock, _closeBlock);
    }

    // set token reward for some specific time range by specifying start and close blocks
    function setTokenPerBlock(IERC20 _token, uint256 _tokenPerBlock, uint256 _startBlock, uint256 _closeBlock) public onlyAuthority {
        require(startBlock != 0, 'Staking: cannot add reward before setting start block');
        require(_startBlock >= startBlock, 'Staking: token start block needs to be different than zero!');
        require(_closeBlock > _startBlock || _closeBlock == 0, 'Staking: token close block needs to be higher than start block!');
        require(address(_token) != address(0), 'Staking: token address needs to be different than zero!');

        for (uint i=0; i<maxPid; i++) {
            updatePool(i); // pool needs to be updated to keep vendor data consistent
        }

        address addr = vendorInfo[address(_token)];
        IStakingV2Vendor vendor;

        // if vendor for asset already exists and is not closed overwrite its reward schedule
        if (addr != address(0)) {
            vendor = IStakingV2Vendor(addr);
            uint256 _prevStartBlock = vendor.startBlock();
            uint256 _prevCloseBlock = vendor.closeBlock();

            // not closed
            if (_prevCloseBlock == 0 || block.number <= _prevCloseBlock) {
                require(_startBlock == _prevStartBlock || block.number < _prevStartBlock,
                    'Staking: token start block cannot be changed');
                _token.approve(address(vendor), MAX);
                vendor.setTokenPerBlock(_tokenPerBlock, _startBlock, _closeBlock);
                return;
            }

            // if it is closed though, then treat it the same as if vendor was not created yet - new one is needed
            if (_prevCloseBlock != 0 && _prevCloseBlock < _startBlock) {
                addr = address(0);
            }
        }

        // if vendor for asset does not exist (or expired) create a new one
        if (addr == address(0)) {
            updateVendors();
            require(vendors.length < 20, 'Staking: limit of actively distributed tokens reached');

            addr = factory.createVendor(address(this), _token);
            vendor = IStakingV2Vendor(addr);
            _token.approve(address(vendor), MAX);
            vendor.setTokenPerBlock(_tokenPerBlock, _startBlock, _closeBlock);

            vendorInfo[address(_token)] = address(vendor);
            vendors.push(address(_token));
            emit TokenVendorChanged(address(_token), address(vendor));
            return;
        }

        revert('Staking: invalid configuration provided');
    }

    function setStartBlock(uint256 _startBlock) public onlyOwner {
        require(startBlock == 0 || startBlock > block.number, 'Staking: start block already set');
        require(_startBlock > 0, 'Staking: start block needs to be higher than zero!');
        startBlock = _startBlock;

        IStakingV2Vendor vendor;
        for (uint i=0; i<vendors.length; i++) {
            vendor = IStakingV2Vendor(vendorInfo[vendors[i]]);
            if (vendor.startBlock() == 0 || vendor.startBlock() < startBlock) vendor.setStartBlock(startBlock);
        }
        emit StartBlockChanged(startBlock);
    }

    function setCloseBlock(uint256 _closeBlock) public onlyOwner {
        require(startBlock != 0, 'Staking: start block needs to be set first');
        require(closeBlock == 0 || closeBlock > block.number, 'Staking: close block already set');
        require(_closeBlock > startBlock, 'Staking: close block needs to be higher than start one!');
        closeBlock = _closeBlock;

        IStakingV2Vendor vendor;
        for (uint i=0; i<vendors.length; i++) {
            vendor = IStakingV2Vendor(vendorInfo[vendors[i]]);
            if (vendor.closeBlock() == 0 || vendor.closeBlock() > closeBlock) vendor.setCloseBlock(closeBlock);
        }
        emit CloseBlockChanged(closeBlock);
    }

    // set delegate to which events about staking amounts should be send to
    function setDelegateAddress(IStakingDelegate _delegate) public onlyOwner {
        require(address(_delegate) != address(0), 'Staking: delegate address needs to be different than zero!');
        delegate = _delegate;
        emit DelegateAddressChanged(address(delegate));
    }

    function withdrawRemaining() public onlyOwner {
        for (uint i=0; i<vendors.length; i++) withdrawRemaining(vendors[i]);
    }

    function withdrawRemaining(address asset) public onlyOwner {
        require(startBlock != 0, 'Staking: start block needs to be set first');
        require(closeBlock != 0, 'Staking: close block needs to be set first');
        require(block.number > closeBlock, 'Staking: withdrawal of remaining funds not ready yet');

        for (uint i=0; i<maxPid; i++) {
            updatePool(i);
        }
        getVendor(asset).withdrawRemaining(owner());
    }

    function pendingRewards(uint256 pid, address addr, address asset) external view returns (uint256) {
        require(pid < maxPid, 'Staking: invalid pool ID provided');
        require(startBlock > 0 && block.number >= startBlock, 'Staking: not started yet');
        return getVendor(asset).pendingRewards(pid, addr);
    }

    function getVAmount(uint256 pid, uint256 amount, uint256 timerange) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        if (pool.lockupMaxTimerange == 0) return amount;
        uint256 indx = multipliers.length * timerange / pool.lockupMaxTimerange;
        if (indx == 0) indx = 1;
        return amount * (1e5 + multipliers[indx-1]) / 1e5;
    }

    function deposit(uint256 pid, address addr, uint256 amount, uint256 timerange) external {
        _deposit(pid, msg.sender, addr, amount, timerange);
    }

    // restake is custom functionality in which funds can be restaked between allowed instances without
    function restake(uint256 pid, address addr, uint256 pocket, uint256 amount, uint256 timerange) external {
        require(allowedStakingInstances[addr], 'Staking: unable to restake funds to specified address');
        if (pocket > 0) token.safeTransferFrom(address(msg.sender), address(this), pocket);
        _withdraw(pid, msg.sender, address(this), amount);
        token.approve(addr, pocket+amount);
        StakingV2(addr).deposit(pid, msg.sender, pocket+amount, timerange);
    }

    function withdraw(uint256 pid, address /*addr*/, uint256 amount) external { // keep this method for backward compatibility
        _withdraw(pid, msg.sender, msg.sender, amount);
    }

    function _deposit(uint256 pid, address from, address addr, uint256 amount, uint256 timerange) internal {
        // amount eq to zero is allowed
        require(pid < maxPid, 'Staking: invalid pool ID provided');
        require(startBlock > 0 && block.number >= startBlock, 'Staking: not started yet');
        require(closeBlock == 0 || block.number <= closeBlock,
            'Staking: staking has ended, please withdraw remaining tokens');

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][addr];

        require(timerange <= pool.lockupMaxTimerange && timerange >= pool.lockupMinTimerange,
            'Staking: cannot lock funds for that amount of time!');
        require(timerange + block.timestamp >= user.lockedTimestamp,
            'Staking: timerange needs to be equal or higher from previous');

        require(pool.tokenTotalLimit == 0 || pool.tokenTotalLimit >= pool.tokenRealStaked + amount,
            'Staking: you cannot deposit over the limit!');
        require(minAmount == 0 || user.amount + amount >= minAmount, 'Staking: amount needs to be higher');
        require(maxAmount == 0 || user.amount + amount <= maxAmount, 'Staking: amount needs to be lesser');
        require(user.lockedTimestamp <= block.timestamp + timerange, 'Staking: cannot decrease lock time');

        updatePool(pid);

        uint256 virtAmount = getVAmount(pid, user.amount + amount, timerange);
        for (uint i=0; i<vendors.length; i++) getVendor(vendors[i]).update(pid, addr, virtAmount);

        if (amount > 0) {
            user.amount = user.amount + amount;
            pool.tokenRealStaked = pool.tokenRealStaked + amount;

            pool.tokenVirtStaked = pool.tokenVirtStaked - user.virtAmount + virtAmount;
            user.virtAmount = virtAmount;

            token.safeTransferFrom(address(from), address(this), amount); // deposit is from sender
        }
        user.lockedTimestamp = block.timestamp + timerange;
        user.lockupTimestamp = block.timestamp;
        user.lockupTimerange = timerange;
        emit Deposited(addr, pid, address(token), amount);

        if (address(delegate) != address(0)) {
            delegate.balanceChanged(addr, user.amount);
        }
    }

    function _withdraw(uint256 pid, address from, address addr, uint256 amount) internal {
        // amount eq to zero is allowed
        require(pid < maxPid, 'Staking: invalid pool ID provided');
        require(startBlock > 0 && block.number >= startBlock, 'Staking: not started yet');

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][from];

        require((addr == address(this)) || (block.timestamp >= user.lockedTimestamp)
            || (closeBlock > 0 && closeBlock <= block.number), 'Staking: you cannot withdraw yet!');
        require(user.amount >= amount, 'Staking: you cannot withdraw more than you have!');

        updatePool(pid);

        uint256 virtAmount = getVAmount(pid, user.amount - amount, user.lockupTimerange);
        for (uint i=0; i<vendors.length; i++) getVendor(vendors[i]).update(pid, addr, virtAmount);

        if (amount > 0) {
            user.amount = user.amount - amount;
            pool.tokenRealStaked = pool.tokenRealStaked - amount;

            pool.tokenVirtStaked = pool.tokenVirtStaked + user.virtAmount - virtAmount;
            user.virtAmount = virtAmount;

            if (addr != address(this)) token.safeTransfer(address(addr), amount);
        }
        user.lockedTimestamp = 0;
        user.lockupTimestamp = 0;
        emit Withdrawn(from, pid, address(token), amount);

        if (address(delegate) != address(0)) {
            delegate.balanceChanged(from, user.amount);
        }
    }

    function claim(uint256 pid) public {
        for (uint i=0; i<vendors.length; i++) claim(pid, vendors[i]);
    }

    function claim(uint256 pid, address asset) public {
        claimFromVendor(pid, address(getVendor(asset)));
    }

    function claimFromVendor(uint256 pid, address addr) public {
        require(pid < maxPid, 'Staking: invalid pool ID provided');
        require(startBlock > 0 && block.number >= startBlock, 'Staking: not started yet');
        updatePool(pid);
        IStakingV2Vendor(addr).claim(pid, msg.sender);
    }

    function addPool(uint256 _lockupMinTimerange, uint256 _lockupMaxTimerange, uint256 _tokenTotalLimit) internal {
        require(maxPid < 10, 'Staking: Cannot add more than 10 pools!');

        poolInfo.push(PoolInfo({
            lastBlock: 0,
            tokenPerShare: 0,
            tokenRealStaked: 0,
            tokenVirtStaked: 0,
            tokenRewarded: 0,
            tokenTotalLimit: _tokenTotalLimit,
            lockupMaxTimerange: _lockupMaxTimerange,
            lockupMinTimerange: _lockupMinTimerange
        }));
        maxPid++;

        emit PoolAdded(_lockupMinTimerange, _lockupMaxTimerange, _tokenTotalLimit);
    }

    function updatePool(uint256 pid) internal {
        if (pid >= maxPid) {
            return;
        }
        if (startBlock == 0 || block.number < startBlock) {
            return;
        }
        PoolInfo storage pool = poolInfo[pid];
        if (pool.lastBlock == 0) {
            pool.lastBlock = startBlock;
        }
        uint256 lastBlock = getLastRewardBlock();
        if (lastBlock <= pool.lastBlock) {
            return;
        }
        uint256 poolTokenVirtStaked = pool.tokenVirtStaked;
        if (poolTokenVirtStaked == 0) {
            return;
        }
        uint256 multiplier = lastBlock - pool.lastBlock;
        uint256 tokenAward = multiplier * tokenPerBlock;
        pool.tokenRewarded = pool.tokenRewarded + tokenAward;
        pool.tokenPerShare = pool.tokenPerShare + (tokenAward * 1e12 / poolTokenVirtStaked);
        pool.lastBlock = lastBlock;
    }

    function updateVendors() public {
        require(msg.sender == address(this) || msg.sender == owner() || hasRole(MAINTAINER_ROLE, msg.sender),
            'Staking: this method can only be called internally or by authority');
        address[] memory _newVendors = new address[](vendors.length);
        uint256 _size;
        address _addr;
        for (uint i=0; i<vendors.length; i++) {
            _addr = vendorInfo[vendors[i]];
            uint256 _closeBlock = IStakingV2Vendor(_addr).closeBlock();
            if (_closeBlock != 0 && _closeBlock < block.number) {
                delistedVendors.push(_addr);
            } else {
                _newVendors[_size++] = vendors[i];
            }
        }
        delete vendors;
        for (uint i=0; i<_size; i++) {
            vendors.push(_newVendors[i]);
        }
    }

    function getLastRewardBlock() internal view returns (uint256) {
        if (startBlock == 0) return 0;
        if (closeBlock == 0) return block.number;
        return (closeBlock < block.number) ? closeBlock : block.number;
    }

    function getVendor(address asset) internal view returns (IStakingV2Vendor) {
        address addr = vendorInfo[asset];
        require(addr != address(0), 'Staking: vendor for this token does not exist');
        return IStakingV2Vendor(addr);
    }
}