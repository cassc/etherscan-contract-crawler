// SPDX-License-Identifier: GPL-3.0
// Refactored synthetix StakingRewards.sol for general purpose mining pool logic.
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "../../../core/tokens/COMMIT.sol";
import "../../../core/emission/interfaces/ITokenEmitter.sol";
import "../../../core/emission/interfaces/IMiningPool.sol";
import "../../../utils/ERC20Recoverer.sol";

abstract contract MiningPool is
    ReentrancyGuard,
    Pausable,
    ERC20Recoverer,
    ERC165,
    IMiningPool
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private _baseToken;
    address private _token;
    address private _tokenEmitter;

    uint256 private _miningEnds = 0;
    uint256 private _miningRate = 0;
    uint256 private _lastUpdateTime;
    uint256 private _tokenPerMiner;
    uint256 private _totalMiners;

    mapping(address => uint256) private _paidTokenPerMiner;
    mapping(address => uint256) private _mined;
    mapping(address => uint256) private _dispatchedMiners;

    modifier onlyTokenEmitter() {
        require(
            msg.sender == address(_tokenEmitter),
            "Only the token emitter can call this function"
        );
        _;
    }

    modifier recordMining(address account) {
        _tokenPerMiner = tokenPerMiner();
        _lastUpdateTime = lastTimeMiningApplicable();
        if (account != address(0)) {
            _mined[account] = mined(account);
            _paidTokenPerMiner[account] = _tokenPerMiner;
        }
        _;
    }

    function initialize(address tokenEmitter_, address baseToken_)
        public
        virtual
        override
    {
        address token_ = ITokenEmitter(tokenEmitter_).token();

        require(address(_token) == address(0), "Already initialized");
        require(token_ != address(0), "Token is zero address");
        require(tokenEmitter_ != address(0), "Token emitter is zero address");
        require(baseToken_ != address(0), "Base token is zero address");
        _token = token_;
        _tokenEmitter = tokenEmitter_;
        _baseToken = baseToken_;
        // ERC20Recoverer
        address[] memory disable = new address[](2);
        disable[0] = token_;
        disable[1] = baseToken_;
        ERC20Recoverer.initialize(msg.sender, disable);
        // ERC165
        bytes4 _INTERFACE_ID_ERC165 = 0x01ffc9a7;
        _registerInterface(_INTERFACE_ID_ERC165);
        _registerInterface(MiningPool(0).allocate.selector);
    }

    function allocate(uint256 amount)
        public
        override
        onlyTokenEmitter
        recordMining(address(0))
    {
        uint256 miningPeriod = ITokenEmitter(_tokenEmitter).EMISSION_PERIOD();
        if (block.timestamp >= _miningEnds) {
            _miningRate = amount.div(miningPeriod);
        } else {
            uint256 remaining = _miningEnds.sub(block.timestamp);
            uint256 leftover = remaining.mul(_miningRate);
            _miningRate = amount.add(leftover).div(miningPeriod);
        }

        // Ensure the provided mining amount is not more than the balance in the contract.
        // This keeps the mining rate in the right range, preventing overflows due to
        // very high values of miningRate in the mined and tokenPerMiner functions;
        // (allocated_amount + leftover) must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(_miningRate <= balance.div(miningPeriod), "not enough balance");

        _lastUpdateTime = block.timestamp;
        _miningEnds = block.timestamp.add(miningPeriod);
        emit Allocated(amount);
    }

    function token() public view override returns (address) {
        return _token;
    }

    function tokenEmitter() public view override returns (address) {
        return _tokenEmitter;
    }

    function baseToken() public view override returns (address) {
        return _baseToken;
    }

    function miningEnds() public view override returns (uint256) {
        return _miningEnds;
    }

    function miningRate() public view override returns (uint256) {
        return _miningRate;
    }

    function lastUpdateTime() public view override returns (uint256) {
        return _lastUpdateTime;
    }

    function lastTimeMiningApplicable() public view override returns (uint256) {
        return Math.min(block.timestamp, _miningEnds);
    }

    function tokenPerMiner() public view override returns (uint256) {
        if (_totalMiners == 0) {
            return _tokenPerMiner;
        }
        return
            _tokenPerMiner.add(
                lastTimeMiningApplicable()
                    .sub(_lastUpdateTime)
                    .mul(_miningRate)
                    .mul(1e18)
                    .div(_totalMiners)
            );
    }

    function mined(address account) public view override returns (uint256) {
        // prev mined + ((token/miner - paidToken/miner) 1e18 unit) * dispatchedMiner
        return
            _dispatchedMiners[account]
                .mul(tokenPerMiner().sub(_paidTokenPerMiner[account]))
                .div(1e18)
                .add(_mined[account]);
    }

    function getMineableForPeriod() public view override returns (uint256) {
        uint256 miningPeriod = ITokenEmitter(_tokenEmitter).EMISSION_PERIOD();
        return _miningRate.mul(miningPeriod);
    }

    function paidTokenPerMiner(address account)
        public
        view
        override
        returns (uint256)
    {
        return _paidTokenPerMiner[account];
    }

    function dispatchedMiners(address account)
        public
        view
        override
        returns (uint256)
    {
        return _dispatchedMiners[account];
    }

    function totalMiners() public view override returns (uint256) {
        return _totalMiners;
    }

    function _dispatchMiners(uint256 miners) internal {
        _dispatchMiners(msg.sender, miners);
    }

    function _dispatchMiners(address account, uint256 miners)
        internal
        nonReentrant
        whenNotPaused
        recordMining(account)
    {
        require(miners > 0, "Cannot stake 0");
        _totalMiners = _totalMiners.add(miners);
        _dispatchedMiners[account] = _dispatchedMiners[account].add(miners);
        emit Dispatched(account, miners);
    }

    function _withdrawMiners(uint256 miners) internal {
        _withdrawMiners(msg.sender, miners);
    }

    function _withdrawMiners(address account, uint256 miners)
        internal
        nonReentrant
        recordMining(account)
    {
        require(miners > 0, "Cannot withdraw 0");
        _totalMiners = _totalMiners.sub(miners);
        _dispatchedMiners[account] = _dispatchedMiners[account].sub(miners);
        emit Withdrawn(account, miners);
    }

    function _mine() internal {
        _mine(msg.sender);
    }

    function _mine(address account)
        internal
        nonReentrant
        recordMining(account)
    {
        uint256 amount = _mined[account];
        if (amount > 0) {
            _mined[account] = 0;
            IERC20(_token).safeTransfer(account, amount);
            emit Mined(account, amount);
        }
    }
}