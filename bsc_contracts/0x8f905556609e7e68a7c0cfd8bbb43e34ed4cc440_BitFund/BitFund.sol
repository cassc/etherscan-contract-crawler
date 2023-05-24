/**
 *Submitted for verification at BscScan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface DGOLDContract {
    function getWeightsInfo(address account)
        external
        view
        returns (uint256, uint256);
}

contract BitFund is Ownable, Pausable, ReentrancyGuard {
    DGOLDContract public constant DGContract =
        DGOLDContract(0x24AeF4416Ff267AfC2d9Fe9141C1002555bed0a6);
    address public constant marketingWallet =
        0xD711139985384365dBDB5C9c871bC367FebE1Afc;
    bool public started;

    uint8[4] public INIT_PERCENTAGES = [20, 15, 10, 5];
    uint256[4] public INIT_AMOUNTS = [
        80000000000000000000,
        30000000000000000000,
        2000000000000000000,
        100000000000000000
    ];

    mapping(address => bool) public left;
    mapping(address => Stake) public stake;
    mapping(address => uint256) public claimed;

    uint256 public minDepositAmount = 1e17;
    uint256 public minDGAmount = 100000 * 1e18;
    uint256 public rewardPerSecond;
    uint256 public rewardStartTime;

    struct Stake {
        uint256 stake;
        uint256 notWithdrawn;
        uint256 timestamp;
        uint8 percentage;
        bool firstInvest;
    }

    event StakeChanged(
        address indexed user,
        address indexed partner,
        uint256 amount
    );

    modifier whenStarted() {
        require(started, "Not started yet");
        _;
    }

    modifier DGHolder() {
        require(
            IERC20(address(DGContract)).balanceOf(msg.sender) >= minDGAmount,
            "Not enough Defi Gold for using BitFund."
        );
        _;
    }

    receive() external payable onlyOwner {}

    function start() external payable onlyOwner {
        started = true;
    }

    function deposit(address partner)
        external
        payable
        whenStarted
        DGHolder
        nonReentrant
    {
        require(msg.value >= minDepositAmount, "Too low amount to deposit");
        require(
            partner != _msgSender(),
            "Cannot set your own address as partner"
        );
        _updateNotWithdrawn();

        uint256 investAmount = msg.value;

        if (!stake[_msgSender()].firstInvest) {
            if (partner != address(0x0)) {
                _giveReferral(partner, investAmount);
                investAmount -= ((investAmount * 5) / 100);
            }
            stake[_msgSender()].firstInvest = true;
        }

        stake[_msgSender()].stake += investAmount;
        _updatePercentage(_msgSender());

        emit StakeChanged(_msgSender(), partner, stake[_msgSender()].stake);
    }

    function compound(uint256 amount)
        external
        whenStarted
        DGHolder
        nonReentrant
    {
        require(amount > 0, "Zero amount");
        _updateNotWithdrawn();
        require(
            amount <= stake[_msgSender()].notWithdrawn,
            "Balance is less than compound amount"
        );
        stake[_msgSender()].notWithdrawn -= amount;
        stake[_msgSender()].stake += amount;
        _updatePercentage(_msgSender());
        emit StakeChanged(
            _msgSender(),
            address(0x0),
            stake[_msgSender()].stake
        );
    }

    function withdraw(uint256 amount)
        external
        whenStarted
        DGHolder
        whenNotPaused
        nonReentrant
    {
        require(amount > 0, "Zero amount");
        require(!left[_msgSender()], "Left");
        _updateNotWithdrawn();
        require(
            amount <= stake[_msgSender()].notWithdrawn,
            "Balance is less than withdraw amount"
        );
        uint256 fee = (amount * 5) / 100;
        stake[_msgSender()].notWithdrawn -= amount;
        payable(owner()).transfer(fee);
        payable(_msgSender()).transfer(amount - fee);
    }

    function withdrawByTeam(address account, uint256 amount)
        external
        whenStarted
        whenNotPaused
        nonReentrant
        onlyOwner
    {
        require(amount <= stake[account].stake, "Exceeds staked amount.");
        _updateNotWithdrawn();
        uint256 withdrawInvestAmount = amount == 0
            ? stake[account].stake
            : amount;
        uint256 withdrawAmount = withdrawInvestAmount +
            stake[account].notWithdrawn;
        uint256 fee = (withdrawAmount * 5) / 100;

        stake[account].notWithdrawn = 0;
        stake[account].stake -= withdrawInvestAmount;
        stake[account].percentage = 0;
        _updatePercentage(account);

        payable(owner()).transfer(fee);
        payable(account).transfer(withdrawAmount - fee);
    }

    function pendingReward(address account) public view returns (uint256) {
        return ((stake[account].stake *
            ((block.timestamp - stake[account].timestamp) / 86400) *
            stake[account].percentage) / 1000);
    }

    function _updateNotWithdrawn() private {
        uint256 pending = pendingReward(_msgSender());
        stake[_msgSender()].timestamp = block.timestamp;
        stake[_msgSender()].notWithdrawn += pending;
    }

    function _giveReferral(address account, uint256 value) private {
        if (
            stake[account].stake > 0 &&
            IERC20(address(DGContract)).balanceOf(msg.sender) >= minDGAmount
        ) stake[account].notWithdrawn += (value * 5) / 100;
        else stake[marketingWallet].notWithdrawn += (value * 5) / 100;
    }

    function _updatePercentage(address account) private {
        for (uint256 i; i < INIT_AMOUNTS.length; i++) {
            if (stake[account].stake >= INIT_AMOUNTS[i]) {
                stake[account].percentage = INIT_PERCENTAGES[i];
                break;
            }
        }
    }

    function stopMining(address[] calldata account, bool[] calldata _left)
        external
        onlyOwner
    {
        require(account.length == _left.length, "Non-matching length");
        for (uint256 i; i < account.length; i++) {
            left[account[i]] = _left[i];
        }
    }

    function updateBaseData(
        uint256[] calldata investAmounts,
        uint8[] calldata percentages
    ) external onlyOwner {
        require(investAmounts.length == 4, "length should be 4");
        require(
            investAmounts.length == percentages.length,
            "Non-matching length"
        );

        for (uint256 i; i < investAmounts.length; i++) {
            INIT_AMOUNTS[i] = investAmounts[i];
            INIT_PERCENTAGES[i] = percentages[i];
        }
    }

    function deinitialize() external onlyOwner {
        _pause();
    }

    function initialize() external onlyOwner {
        _unpause();
    }

    function arbitrageTransfer(uint256 amount) external onlyOwner {
        payable(_msgSender()).transfer(amount);
    }

    function updateMinDepositAmount(uint256 _minDepositAmount)
        external
        onlyOwner
    {
        minDepositAmount = _minDepositAmount;
    }

    function updateMinDGAmount(uint256 _minDGAmount) external onlyOwner {
        minDGAmount = _minDGAmount;
    }

    function startReward(uint256 _rewardPerSecond) external onlyOwner {
        rewardPerSecond = _rewardPerSecond;
        rewardStartTime = block.timestamp;
    }

    function updateRewardPerSecond(uint256 _rewardPerSecond)
        external
        onlyOwner
    {
        rewardPerSecond = _rewardPerSecond;
    }

    function getReward(address account) public view returns (uint256) {
        if (rewardStartTime == 0 || rewardPerSecond == 0) return 0;

        (
            uint256 userTotalWeightSeconds,
            uint256 totalWeightSeconds
        ) = DGContract.getWeightsInfo(account);

        uint256 reward = (rewardPerSecond *
            (block.timestamp - rewardStartTime) *
            userTotalWeightSeconds) / totalWeightSeconds;
        if (reward > claimed[msg.sender]) return reward - claimed[msg.sender];
        return 0;
    }

    function claimReward() external DGHolder {
        uint256 reward = getReward(msg.sender);
        if (reward > 0) {
            claimed[msg.sender] += reward;
            IERC20(address(DGContract)).transfer(msg.sender, reward);
        }
    }
}