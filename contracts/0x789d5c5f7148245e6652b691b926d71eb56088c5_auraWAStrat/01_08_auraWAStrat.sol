// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IFeeConfig {
    struct FeeCategory {
        uint256 total;
        uint256 owner;
        string label;
        bool active;
    }
    function getFees(address strategy) external view returns (FeeCategory memory);
    function stratFeeId(address strategy) external view returns (uint256);
    function setStratFeeId(uint256 feeId) external;
}

pragma solidity >=0.6.0 <0.9.0;

interface IUniswapRouterETH {
    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function getReward() external;
    function poolInfo(uint256 _pid) external view returns (address, address, address, address, address, bool);
    function witdrawAll(bool _claim) external;
    function withdrawAndUnwrap(uint _amount, bool _claim) external;
}

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface BalancerVault {
    enum SwapKind { GIVEN_IN, GIVEN_OUT }
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }
    
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    function getVault() external view returns(address);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

contract StratFeeManager is Ownable, Pausable {

    struct CommonAddresses {
        address vault;
        address unirouter;
        address keeper;
        address yeller; 
        address feeConfig;
    }

    // common addresses for the strategy
    address public vault;
    address public unirouter;
    address public keeper;
    address public yeller;
    IFeeConfig public feeConfig;

    uint256 constant DIVISOR = 1 ether;
    uint256 constant public WITHDRAWAL_FEE_CAP = 50;
    uint256 constant public WITHDRAWAL_MAX = 10000;
    uint256 public withdrawalFee = 10;

    event SetStratFeeId(uint256 feeId);
    event SetWithdrawalFee(uint256 withdrawalFee);
    event SetVault(address vault);
    event SetUnirouter(address unirouter);
    event SetYeller(address yeller);
    event SetKeeper(address keeper);
    event SetStrategist(address strategist);
    event SetFeeRecipient(address feeRecipient);
    event SetFeeConfig(address feeConfig);

    constructor(
        CommonAddresses memory _commonAddresses
    ) {
        vault = _commonAddresses.vault;
        unirouter = _commonAddresses.unirouter;
        keeper = _commonAddresses.keeper;
        yeller = _commonAddresses.yeller;
        feeConfig = IFeeConfig(_commonAddresses.feeConfig);
    }

    // checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "!manager");
        _;
    }

    // fetch fees from config contract
    function getFees() public view returns (IFeeConfig.FeeCategory memory) {
        return feeConfig.getFees(address(this));
    }

    function getStratFeeId() external view returns (uint256) {
        return feeConfig.stratFeeId(address(this));
    }

    function setStratFeeId(uint256 _feeId) external onlyManager {
        feeConfig.setStratFeeId(_feeId);
        emit SetStratFeeId(_feeId);
    }

    // adjust withdrawal fee
    function setWithdrawalFee(uint256 _fee) public onlyManager {
        require(_fee <= WITHDRAWAL_FEE_CAP, "!cap");
        withdrawalFee = _fee;
        emit SetWithdrawalFee(_fee);
    }

    // set new vault (only for strategy upgrades)
    function setVault(address _vault) external onlyOwner {
        vault = _vault;
        emit SetVault(_vault);
    }

    // set new unirouter
    function setUnirouter(address _unirouter) external onlyOwner {
        unirouter = _unirouter;
        emit SetUnirouter(_unirouter);
    }

    // set new unirouter
    function setYeller(address _yeller) external onlyOwner {
        yeller = _yeller;
        emit SetYeller(_yeller);
    }

    // set new keeper to manage strat
    function setKeeper(address _keeper) external onlyManager {
        keeper = _keeper;
        emit SetKeeper(_keeper);
    }

    // set new fee config address to fetch fees
    function setFeeConfig(address _feeConfig) external onlyOwner {
        feeConfig = IFeeConfig(_feeConfig);
        emit SetFeeConfig(_feeConfig);
    }

    function beforeDeposit() external virtual {}
}

contract auraWAStrat is StratFeeManager {
    using SafeERC20 for IERC20;

    // Tokens used
    address public native;
    address public outputOne;
    address public outputTwo;
    address public want;
    address public yel;
    address public balancerVault;

    // Third party contracts
    address public chef;
    uint256 public poolId;
    uint256 public yelRewards;
    
    bytes32 public poolIdAuraSwap = 0xa3283e3470d3cd1f18c074e3f2d3965f6d62fff2000100000000000000000267;
    bytes32 public poolIBalSwap = 0x03cd191f589d12b0582a99808cf19851e468e6b500020000000000000000002b;
    bytes32 public poolIMkrSwap = 0xaac98ee71d4f8a156b6abaa6844cdb7789d086ce00020000000000000000001b;

    bool public harvestOnDeposit;

    // Routes
    address[] public outputToNativeToYelRoute;

    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);
    event ChargedFees(uint256 callFees);

    constructor(
        address _want,
        uint256 _poolId,
        address _chef,
        CommonAddresses memory _commonAddresses,
        address[] memory _outputToNativeToYelRoute
    ) StratFeeManager(_commonAddresses) {
        want = _want;
        poolId = _poolId;
        chef = _chef;

        outputOne = _outputToNativeToYelRoute[0];
        outputTwo = _outputToNativeToYelRoute[1];
        native = _outputToNativeToYelRoute[2];
        yel = _outputToNativeToYelRoute[3];
        outputToNativeToYelRoute = _outputToNativeToYelRoute;

        address _balancerVault = BalancerVault(want).getVault();
        balancerVault = _balancerVault;
        _giveAllowances();
    }

    // puts the funds to work
    function deposit() public whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0) {
            IMasterChef(chef).deposit(poolId, wantBal, true);
            emit Deposit(balanceOf());
        }
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 wantBal = IERC20(want).balanceOf(address(this));
        if (wantBal < _amount) {
            (, , , address rewarder, , ) = IMasterChef(chef).poolInfo(poolId);
            IMasterChef(rewarder).withdrawAndUnwrap(_amount - wantBal, false);
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        if (tx.origin != owner() && !paused()) {
            uint256 withdrawalFeeAmount = wantBal * withdrawalFee / WITHDRAWAL_MAX;
            wantBal = wantBal - withdrawalFeeAmount;
        }

        IERC20(want).safeTransfer(vault, wantBal);

        emit Withdraw(balanceOf());
    }

    function beforeDeposit() external virtual override {
        if (harvestOnDeposit) {
            require(msg.sender == vault || msg.sender == yeller, "!vault or !yeller");
            _harvest();
        }
    }

    // compounds earnings and charges performance fee
    function _harvest() internal whenNotPaused {
        (, , , address crvRewards, , ) = IMasterChef(chef).poolInfo(poolId);
        IMasterChef(crvRewards).getReward();
        uint256 rewardsBal = IERC20(outputOne).balanceOf(address(this));
        uint256 rewardsAURA = IERC20(outputTwo).balanceOf(address(this));

        if (rewardsBal > 0 || rewardsAURA > 0) {
            chargeFees(rewardsBal, rewardsAURA);
            transferToYeller();
        }
    }

    // performance fees
    function chargeFees(uint _rewardsBal, uint _rewardsAURA) internal {
        IFeeConfig.FeeCategory memory fees = getFees();
        
        swapRewardsToYel(_rewardsBal, _rewardsAURA);

        uint256 yelBal = IERC20(yel).balanceOf(address(this));
        uint256 ownerFeeAmount = yelBal * fees.owner / DIVISOR;
        IERC20(yel).safeTransfer(keeper, ownerFeeAmount);

        emit ChargedFees(ownerFeeAmount);
    }

    function swapRewardsToYel(uint _rewardsBal, uint _rewardsAURA) internal {
        if(_rewardsBal > 0) {
            BalancerVault.BatchSwapStep[] memory datas = new BalancerVault.BatchSwapStep[](2);
            datas[0] = BalancerVault.BatchSwapStep({
                amount: _rewardsBal,
                assetInIndex: 0,
                assetOutIndex: 1,
                poolId: poolIBalSwap,
                userData: ""
            });

            datas[1] = BalancerVault.BatchSwapStep({
                amount: 0,
                assetInIndex: 1,
                assetOutIndex: 2,
                poolId: poolIMkrSwap,
                userData: ""
            });

            address[] memory assets = new address[](3);
            assets[0] = outputOne;
            assets[1] = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2; //MKR
            assets[2] = native;

            int[] memory limits = new int[](3);
            limits[0] = type(int).max;
            limits[1] = 0;
            limits[2] = 0;

            BalancerVault(balancerVault).batchSwap(
                BalancerVault.SwapKind.GIVEN_IN,
                datas,
                assets,
                BalancerVault.FundManagement({
                    sender: address(this),
                    fromInternalBalance: false,
                    recipient: payable(address(this)),
                    toInternalBalance: false
                }),
                limits,
                block.timestamp
            );
        }

        if(_rewardsAURA > 0) {
            BalancerVault(balancerVault).swap(BalancerVault.SingleSwap({
                poolId: poolIdAuraSwap,
                kind: BalancerVault.SwapKind.GIVEN_IN,
                assetIn: IAsset(outputTwo),
                assetOut: IAsset(native),
                amount: _rewardsAURA,
                userData: ""
            }), BalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            }),
            0,
            block.timestamp
            );
        }
        uint nativeBalance = IERC20(native).balanceOf(address(this));

        address[] memory nativeToYel = new address[](2);
        nativeToYel[0] = native;
        nativeToYel[1] = yel;
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(
            nativeBalance, 0, nativeToYel, address(this), block.timestamp
        );
    }

    // rewards in yel to vault
    function transferToYeller() internal {
        uint256 yelBal = IERC20(yel).balanceOf(address(this));

        if (yelBal > 0) {
            yelRewards = yelBal;
            IERC20(yel).safeTransfer(address(yeller), yelBal);
        }
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        (, , , address crvRewards, , ) = IMasterChef(chef).poolInfo(poolId);
        uint _amount = IERC20(crvRewards).balanceOf(address(this));
        return _amount;
    }

    function setHarvestOnDeposit(bool _harvestOnDeposit) external onlyManager {
        harvestOnDeposit = _harvestOnDeposit;

        if (harvestOnDeposit) {
            setWithdrawalFee(0);
        } else {
            setWithdrawalFee(10);
        }
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        require(msg.sender == vault, "!vault");

        IMasterChef(chef).witdrawAll(true);

        uint256 wantBal = IERC20(want).balanceOf(address(this));
        IERC20(want).transfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        IMasterChef(chef).witdrawAll(true);
    }

    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(chef, type(uint).max);
        IERC20(outputOne).safeApprove(balancerVault, type(uint).max);
        IERC20(outputTwo).safeApprove(balancerVault, type(uint).max);
        IERC20(native).safeApprove(unirouter, type(uint).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(chef, 0);
        IERC20(outputOne).safeApprove(balancerVault, 0);
        IERC20(outputTwo).safeApprove(balancerVault, 0);
        IERC20(native).safeApprove(unirouter, 0);
    }

    function outputToNativeToYel() external view returns (address[] memory) { 
        return outputToNativeToYelRoute;
    }

    function inCaseTokensGetStuck(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    function changeAuraPoolId(bytes32 _newPool) external onlyOwner {
        poolIdAuraSwap = _newPool;
    }

    function changeBalPoolId(bytes32 _newPool) external onlyOwner {
        poolIBalSwap = _newPool;
    }

    function changeMkrPoolId(bytes32 _newPool) external onlyOwner {
        poolIMkrSwap = _newPool;
    }
}