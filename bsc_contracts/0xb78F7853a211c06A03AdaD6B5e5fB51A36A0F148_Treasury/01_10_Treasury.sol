// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interfaces/ITreasury.sol";

/// ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
/// [Max Supply]             : 250.000.000 Token.
/// -----------------------------------------------------------------------------------------------------------
/// [Liquidity & Incentives] : 23%
/// [Foundation reserve]     : 21.2%
/// [Team & Advisors]        : 17.4% ➔ Unlock 1.45% more every 3 months.
/// [Marketing]              : 10%
/// -----------------------------------------------------------------------------------------------------------
/// [Token Sale]             : 28.4%
/// -----------------------------------------------------------------------------------------------------------
contract Treasury is
    Initializable,
    IERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ITreasury
{
    uint256 internal initializeTime_;
    address internal tokenBase_;
    bool internal canStart_;
    // For storing all vesting stages with structure defined above.
    mapping(address => vesting[]) internal phases;

    uint256 public constant LIQUIDITY_MAX_RELEASE_AMOUNT = 57500000e18; // 23%
    uint256 public constant FOUNDATION_MAX_RELEASE_AMOUNT = 53000000e18; // 21.2%
    uint256 public constant MARKETING_MAX_RELEASE_AMOUNT = 25000000e18; // 10%
    uint256 public constant TOKEN_SALE_MAX_RELEASE_AMOUNT = 71000000e18; // 28.4%
    uint256 public constant TEAM_MAX_RELEASE_AMOUNT = 43500000e18; // 17.4%
    uint256 internal constant RELEASE_AMOUNT = 3625000e18;

    uint256 internal teamReleased_; // 23%
    uint256 internal liquidityReleased_; // 23%
    uint256 internal foundationReleased_; // 21.2%
    uint256 internal marketingReleased_; // 10%
    uint256 internal tokenSaleReleased_; // 28.4%

    mapping(address => bool) internal liquidityAddress_;
    mapping(address => bool) internal foundationAddress_;
    mapping(address => bool) internal marketingAddress_;
    mapping(address => bool) internal tokenSaleAddress_;

    mapping(address => uint256) internal airdrop_;

    struct vesting {
        uint256 date;
        bool vested;
    }

    // Events token released
    event TeamTokenReleased(address indexed wallet, uint256 indexed amount);
    event LiquidityTokenReleased(
        address indexed wallet,
        uint256 indexed amount
    );
    event FoundationTokenReleased(
        address indexed wallet,
        uint256 indexed amount
    );
    event MarketingTokenReleased(
        address indexed wallet,
        uint256 indexed amount
    );
    event TokenSaleReleased(address indexed wallet, uint256 indexed amount);

    // Address changed
    event TokenBaseUpdated(
        address indexed newAddress,
        address indexed previous
    );

    event LiquidityAddressUpdated(
        address indexed newAddress,
        bool indexed actived
    );
    event FoundationAddressUpdated(
        address indexed newAddress,
        bool indexed actived
    );
    event MarketingAddressUpdated(
        address indexed newAddress,
        bool indexed actived
    );
    event TokenSaleAddressUpdated(
        address indexed newAddress,
        bool indexed actived
    );

    /// Withdraw amount exceeds sender's balance of the locked token
    error ExceedsBalance();
    /// Deposit is not possible anymore because the deposit period is over
    error DepositPeriodOver();
    /// Withdraw is not possible because the lock period is not over yet
    error LockPeriodOngoing();
    /// Could not transfer the designated ERC20 token
    error TransferFailed();
    /// ERC-20 function is not supported
    error NotSupported();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
        canStart_ = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setTokenBase(address _token) public onlyOwner {
        emit TokenBaseUpdated(_token, tokenBase_);
        tokenBase_ = _token;
    }

    function balanceOf(address token) external view override returns (uint256) {
        return IERC20Upgradeable(token).balanceOf(address(this));
    }

    function totalSupply() external view override returns (uint256) {
        return IERC20Upgradeable(tokenBase_).balanceOf(address(this));
    }

    function circulatingSupply() external view returns (uint256) {
        return
            teamReleased_ +
            liquidityReleased_ +
            foundationReleased_ +
            marketingReleased_ +
            tokenSaleReleased_;
    }

    /**
     * Change address
     */
    function setLiquidityAddress(address _address, bool active)
        public
        onlyOwner
    {
        require(_address != address(0), "ERC20: transfer to the zero address");
        liquidityAddress_[_address] = active;
        emit LiquidityAddressUpdated(_address, active);
    }

    function setFoundationAddress(address _address, bool active)
        public
        onlyOwner
    {
        require(_address != address(0), "ERC20: transfer to the zero address");
        foundationAddress_[_address] = active;
        emit FoundationAddressUpdated(_address, active);
    }

    function setMarketingAddress(address _address, bool active)
        public
        onlyOwner
    {
        require(_address != address(0), "ERC20: transfer to the zero address");
        marketingAddress_[_address] = active;
        emit MarketingAddressUpdated(_address, active);
    }

    function setTokenSaleAddress(address _address, bool active)
        public
        onlyOwner
    {
        require(_address != address(0), "ERC20: transfer to the zero address");
        tokenSaleAddress_[_address] = active;
        emit TokenSaleAddressUpdated(_address, active);
    }

    /**
     * Release token
     */

    function releaseTokenTeam(
        address token,
        address to,
        uint8 phase
    ) external override onlyOwner {
        require(to != address(0), "ERC20: transfer to the zero address");

        if (block.timestamp < phases[_msgSender()][phase].date) {
            revert LockPeriodOngoing();
        }

        uint256 amount = _phaseRewardOf(_msgSender(), phase);
        if (amount == 0) {
            revert ExceedsBalance();
        }

        _release(token, _msgSender(), amount, phase);
    }

    function releaseTokenLiquidity(
        address token,
        address to,
        uint256 amount
    ) external override whenNotPaused {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            _msgSender() == owner() || liquidityAddress_[_msgSender()],
            "Permission denied"
        );
        require(
            (liquidityReleased_ + amount) < LIQUIDITY_MAX_RELEASE_AMOUNT,
            "Exceeded the total amount"
        );

        liquidityReleased_ += amount;
        emit LiquidityTokenReleased(to, amount);

        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(token), to, amount);
    }

    function releaseTokenFoundation(
        address token,
        address to,
        uint256 amount
    ) external override whenNotPaused {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            _msgSender() == owner() || foundationAddress_[_msgSender()],
            "Permission denied"
        );
        require(
            (foundationReleased_ + amount) < FOUNDATION_MAX_RELEASE_AMOUNT,
            "Exceeded the total amount"
        );

        foundationReleased_ += amount;
        emit FoundationTokenReleased(to, amount);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(token), to, amount);
    }

    function releaseTokenMarketing(
        address token,
        address to,
        uint256 amount
    ) external override whenNotPaused {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            _msgSender() == owner() || marketingAddress_[_msgSender()],
            "Permission denied"
        );
        require(
            (marketingReleased_ + amount) < MARKETING_MAX_RELEASE_AMOUNT,
            "Exceeded the total amount"
        );

        marketingReleased_ += amount;
        emit MarketingTokenReleased(to, amount);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(token), to, amount);
    }

    function releaseTokenTokenSale(
        address token,
        address to,
        uint256 amount
    ) external override whenNotPaused {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            _msgSender() == owner() || tokenSaleAddress_[_msgSender()],
            "Permission denied"
        );
        require(
            (tokenSaleReleased_ + amount) < TOKEN_SALE_MAX_RELEASE_AMOUNT,
            "Exceeded the total amount"
        );

        tokenSaleReleased_ += amount;
        emit TokenSaleReleased(to, amount);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(token), to, amount);
    }

    /**
     * Get amount
     */

    function getTeamReleased() external view override returns (uint256) {
        return teamReleased_;
    }

    function getLiquidityReleased() external view override returns (uint256) {
        return liquidityReleased_;
    }

    function getFoundationReleased() external view override returns (uint256) {
        return foundationReleased_;
    }

    function getMarketingReleased() external view override returns (uint256) {
        return marketingReleased_;
    }

    function getTokenSaleReleased() external view override returns (uint256) {
        return tokenSaleReleased_;
    }

    /**
     *  Start locked token 3 year
     */
    function start() public onlyOwner {
        require(canStart_, "Quantity must be greater than 0");

        canStart_ = false;

        initializeTime_ = block.timestamp;
        uint256 _teamCliff = 90 days;
        // 1 year
        _addPhase(owner(), initializeTime_ + (_teamCliff * 1), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 2), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 3), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 4), false);
        // 2 year
        _addPhase(owner(), initializeTime_ + (_teamCliff * 5), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 6), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 7), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 8), false);
        // 3 year
        _addPhase(owner(), initializeTime_ + (_teamCliff * 9), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 10), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 11), false);
        _addPhase(owner(), initializeTime_ + (_teamCliff * 12), false);
    }

    function phasesLockedOf(address wallet)
        public
        view
        returns (vesting[] memory)
    {
        return phases[wallet];
    }

    function releasedOf(address wallet, uint8 phase)
        public
        view
        returns (uint256)
    {
        return _phaseRewardOf(wallet, phase);
    }

    function _release(
        address token,
        address recever,
        uint256 amount,
        uint8 phase
    ) internal {
        phases[recever][phase].vested = true;
        teamReleased_ += amount;
        emit TeamTokenReleased(recever, amount);
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(token),
            _msgSender(),
            amount
        );
    }

    function _phaseRewardOf(address recever, uint8 phase)
        internal
        view
        returns (uint256)
    {
        if (phases[recever][phase].vested == true) {
            return 0;
        }
        return RELEASE_AMOUNT;
    }

    function _addPhase(
        address wallet,
        uint256 cliff,
        bool vested
    ) internal {
        vesting memory v = vesting(cliff, vested);
        phases[wallet].push(v);
    }

    /// @dev Lock claim tokens are non-transferrable: ERC-20 transfer is not supported
    function transfer(address, uint256) external pure override returns (bool) {
        revert NotSupported();
    }

    /// @dev Lock claim tokens are non-transferrable: ERC-20 allowance is not supported
    function allowance(address, address)
        external
        pure
        override
        returns (uint256)
    {
        revert NotSupported();
    }

    /// @dev Lock claim tokens are non-transferrable: ERC-20 approve is not supported
    function approve(address, uint256) external pure override returns (bool) {
        revert NotSupported();
    }

    /// @dev Lock claim tokens are non-transferrable: ERC-20 transferFrom is not supported
    function transferFrom(
        address,
        address,
        uint256
    ) external pure override returns (bool) {
        revert NotSupported();
    }
}