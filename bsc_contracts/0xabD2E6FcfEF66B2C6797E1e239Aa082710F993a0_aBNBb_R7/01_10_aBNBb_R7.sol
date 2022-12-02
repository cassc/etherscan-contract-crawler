// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "../interface/ICertToken.sol";
import "../interface/IBondToken_R2.sol";

import "../lib/ERC20ModUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract aBNBb_R7 is OwnableUpgradeable, ERC20ModUpgradeable, IBondToken_R2 {
    /**
     * Variables
     */

    address private _operator;
    address private _crossChainBridge;
    address private _binancePool;
    uint256 private _ratio;
    uint256 private _totalStaked;
    uint256 private _totalUnbondedBonds;
    int256 private _lockedShares;

    mapping(address => uint256) private _pendingBurn;
    uint256 private _pendingBurnsTotal;
    uint256 private _collectableFee;

    ICertToken private _aBNBc;

    address private _swapFeeOperator;

    uint256 private _swapFeeRatio;

    uint256[] public historicalRatios;

    uint256 private _lastUpdate;
    uint256 public latestOffset;

    /**
     * Modifiers
     */

    modifier onlyOperator() {
        require(
            msg.sender == owner() || msg.sender == _operator,
            "Operator: not allowed"
        );
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == _crossChainBridge, "Minter: not allowed");
        _;
    }

    modifier onlyBondMinter() {
        require(msg.sender == _binancePool, "Minter: not allowed");
        _;
    }

    function initialize(address operator) public initializer {
        __Ownable_init();
        __ERC20_init_unchained("Ankr BNB Reward Earning Bond", "aBNBb");
        _operator = operator;
        _ratio = 1e18;
    }

    function name() public pure override returns (string memory) {
        return "Ankr Reward Earning BNB";
    }

    function ratio() public view override returns (uint256) {
        return _ratio;
    }

    function averagePercentageRate(uint256 day)
        external
        view
        returns (uint256)
    {
        require(day > 0 && day < 8, "day should be from 1 to 7");
        uint256 _latestOffset = latestOffset;

        uint256 oldestRatio = historicalRatios[((_latestOffset - day) % 8)];
        uint256 newestRatio = historicalRatios[((_latestOffset) % 8)];

        if (oldestRatio < newestRatio) {
            return 0;
        }

        return
            ((oldestRatio - newestRatio) * 10**20 * 365) / (oldestRatio * day);
    }

    /// @dev new_ratio = total_shares/(total_staked + total_reward - unbonds)
    function updateRatio(uint256 totalRewards) external onlyOperator {
        uint256 totalShares = totalSharesSupply();
        uint256 denominator = _totalStaked + totalRewards - _totalUnbondedBonds;
        _ratio = multiplyAndDivideFloor(totalShares, 1e18, denominator); // (totalShares * 1e18) / denominator;
        if (historicalRatios.length == 0) {
            historicalRatios = new uint256[](8);
        }
        if (block.timestamp - _lastUpdate > 1 days - 1 minutes) {
            uint256 _latestOffset = latestOffset;
            historicalRatios[((_latestOffset + 1) % 8)] = _ratio;
            latestOffset = _latestOffset + 1;
            _lastUpdate = block.timestamp;
        }
        emit RatioUpdated(_ratio);
    }

    function repairRatio(uint256 newRatio) external onlyOwner {
        _ratio = newRatio;
        emit RatioUpdated(_ratio);
    }

    function lockShares(uint256 shares) external override {
        address spender = msg.sender;
        // transfer tokens from aETHc to aETHb
        _aBNBc.transferFrom(spender, address(this), shares);
        // calc swap fee (default swap fee ratio is 0.1%=0.1/100*1e18, fee can't be greater than 1%)
        uint256 fee = (shares * _swapFeeRatio) / 1e18;
        if (msg.sender == _swapFeeOperator) {
            fee = 0;
        }
        uint256 sharesWithFee = shares - fee;
        // increase senders and operator balances
        _balances[_swapFeeOperator] += fee;
        _balances[spender] += sharesWithFee;
        emit Locked(spender, shares);
    }

    function lockSharesFor(
        address spender,
        address account,
        uint256 shares
    ) external override onlyMinter {
        require(spender == msg.sender, "invalid spender");
        _aBNBc.transferFrom(spender, address(this), shares);
        _balances[account] += shares;
        emit Locked(account, shares);
    }

    function transferAndLockShares(address account, uint256 shares)
        external
        override
        onlyBondMinter
    {
        _aBNBc.transferFrom(account, address(this), shares);
        _balances[account] += shares;
        emit Locked(account, shares);
    }

    function unlockShares(uint256 shares) external override {
        address account = address(msg.sender);
        // make sure user has enough balance
        require(super.balanceOf(account) >= shares, "insufficient balance");
        // calc swap fee
        uint256 fee = (shares * _swapFeeRatio) / 1e18;
        if (msg.sender == _swapFeeOperator) {
            fee = 0;
        }
        uint256 sharesWithFee = shares - fee;
        // update balances
        _balances[_swapFeeOperator] += fee;
        _balances[account] -= shares;
        // transfer tokens to the user
        _aBNBc.transfer(account, sharesWithFee);
        emit Unlocked(account, shares);
    }

    function unlockSharesFor(address account, uint256 bonds)
        external
        override
        onlyBondMinter
    {
        uint256 shares = bondsToShares(bonds);
        // make sure user has enough balance
        require(_balances[account] >= shares, "insufficient balance");
        // update balance
        _balances[account] -= shares;
        // transfer tokens to the user
        _aBNBc.transfer(account, shares);
        emit Unlocked(account, bonds);
    }

    function mintBonds(address account, uint256 amount)
        external
        override
        onlyBondMinter
    {
        _totalStaked += amount;
        uint256 shares = bondsToShares(amount);
        _mint(account, shares);
        _aBNBc.mint(address(this), shares);
        emit Transfer(address(0), account, amount);
    }

    function mint(address account, uint256 shares)
        external
        override
        onlyMinter
    {
        require(
            _lockedShares - int256(shares) <= _lockedShares,
            "overflow of _lockedShares"
        );
        _lockedShares -= int256(shares);
        _mint(account, shares);
        emit Transfer(address(0), account, shares);
    }

    function burnBonds(address account, uint256 amount)
        external
        override
        onlyMinter
    {
        uint256 shares = bondsToShares(amount);
        require(
            _lockedShares + int256(shares) >= _lockedShares,
            "overflow of _lockedShares"
        );
        _lockedShares += int256(shares);
        _burn(account, shares);
        emit Transfer(account, address(0), amount);
    }

    function pendingBurn(address account)
        external
        view
        override
        returns (uint256)
    {
        return _pendingBurn[account];
    }

    function burnAndSetPending(address account, uint256 amount)
        external
        override
        onlyBondMinter
    {
        _pendingBurn[account] += amount;
        _pendingBurnsTotal += amount;
        _totalUnbondedBonds += amount;
        uint256 sharesToBurn = bondsToShares(amount);
        _burn(account, sharesToBurn);
        _aBNBc.burn(address(this), sharesToBurn);
        emit Transfer(account, address(0), amount);
    }

    function burnAndSetPendingFor(
        address owner,
        address account,
        uint256 amount
    ) external override onlyBondMinter {
        _pendingBurn[account] += amount;
        _pendingBurnsTotal += amount;
        _totalUnbondedBonds += amount;
        uint256 sharesToBurn = bondsToShares(amount);
        _burn(owner, sharesToBurn);
        _aBNBc.burn(address(this), sharesToBurn);
        emit Transfer(account, address(0), amount);
    }

    function updatePendingBurning(address account, uint256 amount)
        external
        override
        onlyBondMinter
    {
        uint256 pendingBurnableAmount = _pendingBurn[account];
        require(pendingBurnableAmount >= amount, "amount is wrong");
        _pendingBurn[account] -= amount;
        _pendingBurnsTotal -= amount;
        _totalUnbondedBonds -= amount;
        _totalStaked -= amount;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        uint256 shares = bondsToShares(amount);
        super.transfer(recipient, shares);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 shares = bondsToShares(amount);
        super.transferFrom(sender, recipient, shares);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return sharesToBonds(super.allowance(owner, spender));
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        uint256 shares = bondsToShares(addedValue);
        super.increaseAllowance(spender, shares);
        emit Approval(
            msg.sender,
            spender,
            sharesToBonds(_allowances[msg.sender][spender])
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 shares = bondsToShares(subtractedValue);
        super.decreaseAllowance(spender, shares);
        emit Approval(
            msg.sender,
            spender,
            sharesToBonds(_allowances[msg.sender][spender])
        );
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        uint256 shares = bondsToShares(amount);
        super.approve(spender, shares);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        uint256 supply = totalSharesSupply();
        return sharesToBonds(supply);
    }

    function totalSharesSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 shares = super.balanceOf(account);
        return sharesToBonds(shares);
    }

    function lockedSharesOf(address account) public view returns (uint256) {
        return super.balanceOf(account);
    }

    function bondsToShares(uint256 amount)
        public
        view
        override
        returns (uint256)
    {
        return multiplyAndDivideCeil(amount, _ratio, 1e18);
    }

    function sharesToBonds(uint256 amount)
        public
        view
        override
        returns (uint256)
    {
        return multiplyAndDivideFloor(amount, 1e18, _ratio);
    }

    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    function totalUnbondedBonds() public view returns (uint256) {
        return _totalUnbondedBonds;
    }

    function changeOperator(address operator) external onlyOwner {
        require(operator != address(0), "zero address");
        _operator = operator;
        emit OperatorChanged(operator);
    }

    function changeBinancePool(address binancePool) external onlyOwner {
        require(binancePool != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(binancePool),
            "non-contract address"
        );
        _binancePool = binancePool;
        emit BinancePoolChanged(binancePool);
    }

    function changeCrossChainBridge(address crossChainBridge)
        external
        onlyOwner
    {
        require(crossChainBridge != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(crossChainBridge),
            "non-contract address"
        );
        _crossChainBridge = crossChainBridge;
        emit CrossChainBridgeChanged(crossChainBridge);
    }

    function changeABNBcToken(address aBNBcAddress) external onlyOwner {
        require(aBNBcAddress != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(aBNBcAddress),
            "non-contract address"
        );
        _aBNBc = ICertToken(aBNBcAddress);
        emit CertTokenChanged(aBNBcAddress);
    }

    function changeSwapFeeParams(address swapFeeOperator, uint256 swapFeeRatio)
        external
        onlyOwner
    {
        require(swapFeeOperator != address(0), "zero address");
        require(swapFeeRatio <= 10000000000000000, "not greater than 1%");
        _swapFeeOperator = swapFeeOperator;
        _swapFeeRatio = swapFeeRatio;
        emit SwapFeeParamsChanged(swapFeeOperator, swapFeeRatio);
    }

    function lockedSupply() public view returns (int256) {
        return _lockedShares;
    }

    function isRebasing() public pure override returns (bool) {
        return true;
    }

    function saturatingMultiply(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            if (a == 0) return 0;
            uint256 c = a * b;
            if (c / a != b) return type(uint256).max;
            return c;
        }
    }

    function saturatingAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return type(uint256).max;
            return c;
        }
    }

    // Preconditions:
    //  1. a may be arbitrary (up to 2 ** 256 - 1)
    //  2. b * c < 2 ** 256
    // Returned value: min(floor((a * b) / c), 2 ** 256 - 1)
    function multiplyAndDivideFloor(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return
            saturatingAdd(
                saturatingMultiply(a / c, b),
                ((a % c) * b) / c // can't fail because of assumption 2.
            );
    }

    // Preconditions:
    //  1. a may be arbitrary (up to 2 ** 256 - 1)
    //  2. b * c < 2 ** 256
    // Returned value: min(ceil((a * b) / c), 2 ** 256 - 1)
    function multiplyAndDivideCeil(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return
            saturatingAdd(
                saturatingMultiply(a / c, b),
                ((a % c) * b + (c - 1)) / c // can't fail because of assumption 2.
            );
    }
}