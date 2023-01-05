// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =========================== CurveAMOv5 =============================
// ====================================================================
// Invests FRAX protocol funds into various Curve & Convex pools for protocol yield.
// New features from older Curve/Convex AMOs:
// Cover interaction with all following types of curve pools (deposit/withdraw/swap):
//   - Basepools and Metapools
//   - Stable pools and Crypto pools
//   - two tokens pools and 3-token pools
// Convex Vaults Interactions LP staking
// FXS Personal Vault interactions for LP Locking 
// Governance update (Owner / Operator)
// Accounting update (multi token based accounting / FRAX + USDC based accounting)

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Amirnader Aghayeghazvini: https://github.com/amirnader-ghazvini

// Reviewer(s) / Contributor(s)
// Travis Moore: https://github.com/FortisFortuna
// Sam Kazemian: https://github.com/samkazemian
// Dennis: https://github.com/denett

import "./interfaces/curve/IMinCurvePool.sol";
import "./interfaces/convex/IConvexBooster.sol";
import "./interfaces/convex/IConvexBaseRewardPool.sol";
import "./interfaces/convex/IVirtualBalanceRewardPool.sol";
import "./interfaces/convex/IConvexClaimZap.sol";
import "./interfaces/convex/IcvxRewardPool.sol";
import "./interfaces/convex/IBooster.sol";
import "./interfaces/convex/IFxsPersonalVault.sol";
import "./interfaces/ICurveAMOv5Helper.sol";
import "./interfaces/IFrax.sol";
import "./interfaces/IFraxAMOMinter.sol";
import './Uniswap/TransferHelper.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract CurveAMOv5 is Ownable {
    // SafeMath automatically included in Solidity >= 8.0.0

    /* ============================================= STATE VARIABLES ==================================================== */
    
    // Addresses Config
    address public operatorAddress;
    IFraxAMOMinter private amoMinter;
    ICurveAMOv5Helper private amoHelper;

    // Constants (ERC20)
    IFrax private constant FRAX = IFrax(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    ERC20 private constant USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ERC20 private constant cvx = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    
    // Curve pools 
    address[] public poolArray;
    struct CurvePool { 
        // General pool parameters
        bool isCryptoPool;
        bool isMetaPool;
        uint coinCount;
        bool hasFrax;
        uint fraxIndex;
        bool hasUsdc;
        uint usdcIndex;
        uint baseTokenIndex;

        // Pool Addresses
        address poolAddress; // Where the actual tokens are in the pool
        address lpTokenAddress; // The LP token address. Sometimes the same as poolAddress

        // Convex Related
        bool hasVault;
        uint256 lpDepositPid;
        address rewardsContractAddress;
        bool hasFxsVault;
        address fxsPersonalVaultAddress;

        // Accounting Parameters
        uint256[] tokenDeposited;
        uint256[] tokenMaxAllocation;
        uint256[] tokenProfitTaken;
        uint256 lpDepositedAsCollateral;
    }
    mapping(address => bool) public poolInitialized;
    mapping(address => CurvePool) private poolInfo;
    mapping(address => address) public lpTokenToPool;
    
    // FXS Personal Vault
    mapping(address => bytes32[]) public vaultKekIds;
    mapping(bytes32 => uint256) public kekIdTotalDeposit;

    // Addresses
    address private constant cvxCrvAddress = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
    address private constant crvAddress = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address private constant fxsAddress = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    
    // Convex-related
    IConvexBooster private constant convexBooster = IConvexBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    IConvexClaimZap private constant convex_claim_zap = IConvexClaimZap(0x4890970BB23FCdF624A0557845A29366033e6Fa2);
    IBooster private constant convexFXSBooster = IBooster(0x569f5B842B5006eC17Be02B8b94510BA8e79FbCa);
    IcvxRewardPool private constant cvx_reward_pool = IcvxRewardPool(0xCF50b810E57Ac33B91dCF525C6ddd9881B139332);
    
    // Parameters
    // Number of decimals under 18, for collateral token
    uint256 private missingDecimals;

    // Discount
    bool public setDiscount;
    uint256 public discountRate;

    /* =============================================== CONSTRUCTOR ====================================================== */

    /// @notice constructor
    /// @param _amoMinterAddress AMO minter address
    /// @param _operatorAddress Address of CurveAMO Operator
    /// @param _amoHelperAddress Address of Curve AMO Helper contract
    constructor (
        address _amoMinterAddress,
        address _operatorAddress,
        address _amoHelperAddress
    ) Ownable() {
        amoMinter = IFraxAMOMinter(_amoMinterAddress);

        operatorAddress = _operatorAddress;

        amoHelper = ICurveAMOv5Helper(_amoHelperAddress);

        missingDecimals = 12;

        // Other variable initializations
        setDiscount = false;

        emit StartAMO(_amoMinterAddress, _operatorAddress, _amoHelperAddress);
    }

    /* ================================================ MODIFIERS ======================================================= */

    modifier onlyByOwnerOperator() {
        require(msg.sender == operatorAddress || msg.sender == owner(), "Not owner or operator");
        _;
    }

    modifier onlyByMinter() {
        require(msg.sender == address(amoMinter), "Not minter");
        _;
    }

    modifier approvedPool(address _poolAddress) {
        require(poolInitialized[_poolAddress], "Pool not approved");
        _;
    }

    modifier onBudget(address _poolAddress) {
        _;
        for(uint256 i = 0; i < poolInfo[_poolAddress].coinCount; i++){
            require(
                poolInfo[_poolAddress].tokenMaxAllocation[i] >= poolInfo[_poolAddress].tokenDeposited[i], 
                "Over token budget"
            );
        }
    }

    modifier hasVault(address _poolAddress) {
        require(poolInfo[_poolAddress].hasVault, "Pool has no vault");
        _;
    }

    modifier hasFxsVault(address _poolAddress) {
        require(poolInfo[_poolAddress].hasFxsVault, "Pool has no FXS vault");
        _;
    }

    /* ================================================= EVENTS ========================================================= */

    /// @notice The ```StartAMO``` event fires when the AMO deploys
    /// @param _amoMinterAddress AMO minter address
    /// @param _operatorAddress Address of operator
    /// @param _amoHelperAddress Address of Curve AMO Helper contract
    event StartAMO(address _amoMinterAddress, address _operatorAddress, address _amoHelperAddress); 

    /// @notice The ```SetOperator``` event fires when the operatorAddress is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetOperator(address _oldAddress, address _newAddress); 

    /// @notice The ```SetAMOHelper``` event fires when the AMO Helper is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetAMOHelper(address _oldAddress, address _newAddress); 

    /// @notice The ```SetAMOMinter``` event fires when the AMO Minter is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetAMOMinter(address _oldAddress, address _newAddress);

    /// @notice The ```AddOrSetPool``` event fires when a pool is added to AMO
    /// @param _poolAddress The pool address
    /// @param _maxAllocations Max allowed allocation of AMO into the pair 
    event AddOrSetPool(address _poolAddress, uint256[] _maxAllocations);

    /// @notice The ```DepositToPool``` event fires when a deposit happens to a pair
    /// @param _poolAddress The pool address
    /// @param _amounts Deposited amounts
    /// @param _minLp Min recieved LP amount
    event DepositToPool(address _poolAddress, uint256[] _amounts, uint256 _minLp);

    /// @notice The ```WithdrawFromPool``` event fires when a withdrawal happens from a pool
    /// @param _poolAddress The pool address
    /// @param _minAmounts Min withdrawal amounts
    /// @param _lp Deposited LP amount
    event WithdrawFromPool(address _poolAddress, uint256[] _minAmounts, uint256 _lp);

    /// @param _poolAddress Address of Curve Pool
    /// @param _inIndex Curve Pool input coin index
    /// @param _outIndex Curve Pool output coin index
    /// @param _inAmount Amount of input coin
    /// @param _minOutAmount Min amount of output coin
    event Swap(address _poolAddress, uint256 _inIndex, uint256 _outIndex, uint256 _inAmount, uint256 _minOutAmount);

    /// @notice The ```DepositToVault``` event fires when a deposit happens to a pair
    /// @param _poolAddress The pool address
    /// @param _lp Deposited LP amount
    event DepositToVault(address _poolAddress, uint256 _lp);

    /// @notice The ```WithdrawFromVault``` event fires when a withdrawal happens from a pool
    /// @param _poolAddress The pool address
    /// @param _lp Withdrawn LP amount
    event WithdrawFromVault(address _poolAddress, uint256 _lp);



    /* ================================================== VIEWS ========================================================= */
    
    /// @notice Show allocations of CurveAMO in FRAX and USDC
    /// @return allocations [Free FRAX in AMO, Free USDC in AMO, Total FRAX Minted into Pools, Total USDC deposited into Pools, Total withdrawable Frax directly from pools, Total withdrawable USDC directly from pool, Total withdrawable Frax from pool and basepool LP, Total withdrawable USDC from pool and basepool LP, Total Frax, Total USDC]
    function showAllocations() public view returns (uint256[10] memory ) {
        return amoHelper.showAllocations(address(this), poolArray.length);
    }

    /// @notice Total FRAX balance
    /// @return fraxValE18 FRAX value
    /// @return collatValE18 FRAX collateral value
    function dollarBalances() external view returns (uint256 fraxValE18, uint256 collatValE18) {
        // Get the allocations
        uint256[10] memory allocations = showAllocations();

        fraxValE18 = (allocations[8]) + ((allocations[9]) * ((10 ** missingDecimals)));
        collatValE18 = ((allocations[8] * fraxDiscountRate())/ 1e6) + ((allocations[9]) * ((10 ** missingDecimals)));
    }

    /// @notice Show all rewards of CurveAMO
    /// @param _poolAddress Address of Curve Pool
    /// @return _crvReward Pool CRV rewards
    /// @return _extraRewardAmounts [CRV claimable, CVX claimable, cvxCRV claimable]
    /// @return _extraRewardTokens [Token Address]
    function showPoolRewards(address _poolAddress) external view returns (uint256, uint256[] memory, address[] memory) {
        address _rewardsContractAddress = poolInfo[_poolAddress].rewardsContractAddress;
        return amoHelper.showPoolRewards(address(this), _rewardsContractAddress);
    }

    /// @notice Show all cvx rewards
    /// @return _cvxReward
    function showCVXRewards() external view returns (uint256 _cvxReward) {
        _cvxReward = cvx_reward_pool.earned(address(this)); // cvxCRV claimable
    }
    
    /// @notice Show lp tokens deposited in Convex vault
    /// @param _poolAddress Address of Curve Pool
    /// @return lp Tokens deposited in the Convex vault
    function lpInVault(address _poolAddress) public view returns (uint256) {
        uint256 _lpInVault = 0;
        if(poolInfo[_poolAddress].hasVault){
            IConvexBaseRewardPool _convexBaseRewardPool = IConvexBaseRewardPool(poolInfo[_poolAddress].rewardsContractAddress);
            _lpInVault += _convexBaseRewardPool.balanceOf(address(this));
       }
       if(poolInfo[_poolAddress].hasFxsVault){
            for (uint256 i = 0; i < vaultKekIds[_poolAddress].length; i++) {
                _lpInVault += kekIdTotalDeposit[vaultKekIds[_poolAddress][i]];
            }
       }
       return _lpInVault;
    }

    /// @notice Get the balances of the underlying tokens for the given amount of LP, 
    /// @notice assuming you withdraw at the current ratio.
    /// @notice May not necessarily = balanceOf(<underlying token address>) due to accumulated fees
    /// @param _poolAddress Address of Curve Pool
    /// @param _lpAmount LP Amount
    /// @return _withdrawables Amount of each token expected
    function getTknsForLPAtCurrRatio(address _poolAddress, uint256 _lpAmount) 
        public view 
        returns (uint256[] memory _withdrawables) 
    {
        CurvePool memory _poolInfo = poolInfo[_poolAddress];
        _withdrawables = amoHelper.getTknsForLPAtCurrRatio(address(this), _poolAddress, _poolInfo.lpTokenAddress, _lpAmount);
    }
    
    /// @notice Calculate recieving amount of FRAX and USDC after withdrawal  
    /// @notice Ignores other tokens that may be present in the LP (e.g. DAI, USDT, SUSD, CRV)
    /// @notice This can cause bonuses/penalties for withdrawing one coin depending on the balance of said coin.
    /// @param _poolAddress Address of Curve Pool
    /// @param _lpAmount LP Amount for withdraw
    /// @return _withdrawables [Total withdrawable Frax directly from pool, Total withdrawable USDC directly from pool, Total withdrawable Frax from pool and basepool lp, Total withdrawable USDC from pool and basepool lp] 
    function calcFraxAndUsdcWithdrawable(address _poolAddress, uint256 _lpAmount) 
        public view 
        returns (uint256[4] memory) 
    {   
        CurvePool memory _poolInfo = poolInfo[_poolAddress];
        return amoHelper.calcFraxAndUsdcWithdrawable(address(this), _poolAddress, _poolInfo.lpTokenAddress, _lpAmount);
    }
    
    /// @notice Calculate expected token amounts if this AMO fully withdraws/exits from the indicated LP
    /// @param _poolAddress Address of Curve Pool
    /// @return _withdrawables Recieving amount of each token after full withdrawal based on current pool ratio 
    function calcAllTknsFromFullLPExit(address _poolAddress) 
        public view 
        returns (uint256[] memory _withdrawables) 
    {
        uint256 _oneStepBurningLp = amoHelper.showOneStepBurningLp(address(this), _poolAddress);
        _withdrawables = getTknsForLPAtCurrRatio(_poolAddress, _oneStepBurningLp);
    }

    /// @notice Calculate expected FRAX and USDC amounts if this AMO fully withdraws/exits from the indicated LP
    /// @notice NOT the same as calcAllTknsFromFullLPExit because you are ignoring / not withdrawing other tokens (e.g. DAI, USDT, SUSD, CRV)
    /// @notice So you have to use calc_withdraw_one_coin and more calculations
    /// @param _poolAddress Address of Curve Pool
    /// @return _withdrawables Total withdrawable Frax directly from pool, Total withdrawable USDC directly from pool, Total withdrawable Frax from pool and basepool lp, Total withdrawable USDC from pool and basepool lp] 
    function calcFraxUsdcOnlyFromFullLPExit(address _poolAddress) 
        public view 
        returns (uint256[4] memory _withdrawables) 
    {
        uint256 _oneStepBurningLp = amoHelper.showOneStepBurningLp(address(this), _poolAddress);
        _withdrawables = calcFraxAndUsdcWithdrawable(_poolAddress, _oneStepBurningLp);
    }

    /// @notice Show allocations of CurveAMO into Curve Pool
    /// @param _poolAddress Address of Curve Pool
    /// @return _assetBalances Pool coins current AMO balances
    function showPoolAssetBalances(address _poolAddress) 
        public view 
        returns (
            uint256[] memory _assetBalances
        ) 
    {
        _assetBalances = amoHelper.showPoolAssetBalances(address(this), _poolAddress);
    }
    
    /// @notice Show allocations of CurveAMO into Curve Pool
    /// @param _poolAddress Address of Curve Pool
    /// @return _assetBalances Pool coins current AMO balances
    /// @return _depositedAmounts Pool coins deposited into pool
    /// @return _profitTakenAmounts Pool coins profit taken from pool
    /// @return _allocations [Current LP balance, LP deposited in metapools, LP deposited in vault]
    function showPoolAccounting(address _poolAddress) 
        public view 
        returns (
            uint256[] memory _assetBalances,
            uint256[] memory _depositedAmounts,
            uint256[] memory _profitTakenAmounts,
            uint256[3] memory _allocations
        ) 
    {
        _assetBalances = showPoolAssetBalances(_poolAddress);
        _depositedAmounts = poolInfo[_poolAddress].tokenDeposited;
        _profitTakenAmounts = poolInfo[_poolAddress].tokenProfitTaken;
        
        ERC20 _lpToken = ERC20(poolInfo[_poolAddress].lpTokenAddress); 
        _allocations[0] = _lpToken.balanceOf(address(this)); // Current LP balance
        
        _allocations[1] = poolInfo[_poolAddress].lpDepositedAsCollateral; // LP deposited in metapools

        _allocations[2] = lpInVault(_poolAddress); // LP deposited in vault
    }

    /// @notice Show FRAX discount rate
    /// @return FRAX discount rate
    function fraxDiscountRate() public view returns (uint256) {
        if(setDiscount){
            return discountRate;
        } else {
            return FRAX.global_collateral_ratio();
        }
    }
    
    /// @notice Backwards compatibility
    /// @return FRAX minted balance of the FraxlendAMO
    function mintedBalance() public view returns (int256) {
        return amoMinter.frax_mint_balances(address(this));
    }

    /// @notice Show Curve Pool parameters
    /// @param _poolAddress Address of Curve Pool
    /// @return _isMetapool
    /// @return _isCrypto
    /// @return _hasFrax
    /// @return _hasVault
    /// @return _hasUsdc
    function showPoolInfo(address _poolAddress) external view returns (bool _isMetapool, bool _isCrypto, bool _hasFrax, bool _hasVault, bool _hasUsdc) {
        _hasVault = poolInfo[_poolAddress].hasVault;
        _isMetapool = poolInfo[_poolAddress].isMetaPool;
        _isCrypto = poolInfo[_poolAddress].isCryptoPool;
        _hasFrax = poolInfo[_poolAddress].hasFrax;
        _hasUsdc = poolInfo[_poolAddress].hasUsdc;
    }

    /// @notice Show Curve Pool parameters regading coins
    /// @param _poolAddress Address of Curve Pool
    /// @return _coinCount
    /// @return _fraxIndex
    /// @return _usdcIndex
    /// @return _baseTokenIndex
    function showPoolCoinIndexes(address _poolAddress) external view returns (uint256 _coinCount, uint256 _fraxIndex, uint256 _usdcIndex, uint256 _baseTokenIndex) {
        _coinCount = poolInfo[_poolAddress].coinCount;
        _fraxIndex = poolInfo[_poolAddress].fraxIndex;
        _usdcIndex = poolInfo[_poolAddress].usdcIndex;
        _baseTokenIndex = poolInfo[_poolAddress].baseTokenIndex;
    }

    /// @notice Show Pool coins max allocations for AMO
    /// @param _poolAddress Address of Curve Pool
    /// @return _tokenMaxAllocation
    function showPoolMaxAllocations(address _poolAddress) external view returns (uint256[] memory _tokenMaxAllocation) {
        _tokenMaxAllocation = poolInfo[_poolAddress].tokenMaxAllocation;
    }

    /// @notice Show Pool LP Token Address
    /// @param _poolAddress Address of Curve Pool
    /// @return _lpTokenAddress
    function showPoolLPTokenAddress(address _poolAddress) external view returns (address _lpTokenAddress) {
        _lpTokenAddress = poolInfo[_poolAddress].lpTokenAddress;
    }

    /// @notice Show Curve Pool parameters regading vaults
    /// @param _poolAddress Address of Curve Pool
    /// @return _lpDepositPid
    /// @return _rewardsContractAddress
    /// @return _fxsPersonalVaultAddress
    function showPoolVaults(address _poolAddress) external view returns (uint256 _lpDepositPid, address _rewardsContractAddress, address _fxsPersonalVaultAddress) {
        _lpDepositPid = poolInfo[_poolAddress].lpDepositPid;
        _rewardsContractAddress = poolInfo[_poolAddress].rewardsContractAddress;
        _fxsPersonalVaultAddress = poolInfo[_poolAddress].fxsPersonalVaultAddress;
    }

    /* ============================================== POOL FUNCTIONS ==================================================== */

    /// @notice Function to deposit tokens to specific Curve Pool 
    /// @param _poolAddress Address of Curve Pool
    /// @param _amounts Amount of Pool coins to be deposited
    /// @param _minLpOut Min LP out after deposit
    function depositToPool(address _poolAddress, uint256[] memory _amounts, uint256 _minLpOut) 
        external         
        approvedPool(_poolAddress)
        onBudget(_poolAddress)
        onlyByOwnerOperator 
    {
        IMinCurvePool pool = IMinCurvePool(_poolAddress);
        for (uint i = 0; i < poolInfo[_poolAddress].coinCount; i++) {
            ERC20 _token = ERC20(pool.coins(i));
            if(_amounts[i] > 0){
                _token.approve(_poolAddress, 0); // For USDT and others
                _token.approve(_poolAddress, _amounts[i]);
                poolInfo[_poolAddress].tokenDeposited[i] += _amounts[i];
                if (poolInfo[_poolAddress].isMetaPool && poolInfo[_poolAddress].baseTokenIndex == i) {
                    address _basePoolAddress = lpTokenToPool[address(_token)];
                    poolInfo[_basePoolAddress].lpDepositedAsCollateral += _amounts[i];
                }
            }
        }
        if (poolInfo[_poolAddress].coinCount == 3){
            uint256[3] memory __amounts;
            __amounts[0] = _amounts[0];
            __amounts[1] = _amounts[1];
            __amounts[2] = _amounts[2];
            pool.add_liquidity(__amounts, _minLpOut);
        } else {
            uint256[2] memory __amounts;
            __amounts[0] = _amounts[0];
            __amounts[1] = _amounts[1];
            pool.add_liquidity(__amounts, _minLpOut);
        }

        emit DepositToPool(_poolAddress, _amounts, _minLpOut);
    }
    
    /// @notice Function to withdraw one token from specific Curve Pool 
    /// @param _poolAddress Address of Curve Pool
    /// @param _lpIn Amount of LP token
    /// @param _coinIndex Curve Pool target coin index
    /// @param _minAmountOut Min amount of target coin out
    function withdrawOneCoin(address _poolAddress, uint256 _lpIn, uint256 _coinIndex, uint256 _minAmountOut) 
        external 
        approvedPool(_poolAddress)
        onlyByOwnerOperator 
        returns (uint256 _amountReceived)
    {
        uint256[] memory _minAmounts = new uint256[](poolInfo[_poolAddress].coinCount);
        _minAmounts[_coinIndex] = _minAmountOut;

        IMinCurvePool pool = IMinCurvePool(_poolAddress);
        ERC20 lpToken = ERC20(poolInfo[_poolAddress].lpTokenAddress);
        lpToken.approve(_poolAddress, 0);
        lpToken.approve(_poolAddress, _lpIn);
        
        ERC20 _token = ERC20(pool.coins(_coinIndex));
        uint256 _balance0 = _token.balanceOf(address(this));
        if(poolInfo[_poolAddress].isCryptoPool) {
            // _amountReceived = pool.remove_liquidity_one_coin(_lpIn, _coinIndex, _minAmountOut);
            pool.remove_liquidity_one_coin(_lpIn, _coinIndex, _minAmountOut);
        } else {
            int128 _index = int128(uint128(_coinIndex));
            // _amountReceived = pool.remove_liquidity_one_coin(_lpIn, _index, _minAmountOut);
            pool.remove_liquidity_one_coin(_lpIn, _index, _minAmountOut);
        }
        uint256 _balance1 = _token.balanceOf(address(this));
        _amountReceived =  _balance1 - _balance0;
        withdrawAccounting(_poolAddress, _amountReceived, _coinIndex);

        emit WithdrawFromPool(_poolAddress, _minAmounts, _lpIn);

        return _amountReceived;
    }

    /// @notice Function to withdraw tokens from specific Curve Pool based on current pool ratio
    /// @param _poolAddress Address of Curve Pool
    /// @param _lpIn Amount of LP token
    /// @param _minAmounts Min amounts of coin out
    function withdrawAtCurrRatio(address _poolAddress, uint256 _lpIn, uint256[] memory _minAmounts) 
        public
        approvedPool(_poolAddress) 
        onlyByOwnerOperator  
        returns (uint256[] memory _amountReceived)
    {
        IMinCurvePool pool = IMinCurvePool(_poolAddress);
        ERC20 lpToken = ERC20(poolInfo[_poolAddress].lpTokenAddress);
        lpToken.approve(_poolAddress, 0);
        lpToken.approve(_poolAddress, _lpIn);
        
        uint256[] memory _assetBalances0 = showPoolAssetBalances(_poolAddress);
        if (poolInfo[_poolAddress].coinCount == 3){
            uint256[3] memory __minAmounts;
            __minAmounts[0] = _minAmounts[0];
            __minAmounts[1] = _minAmounts[1];
            __minAmounts[2] = _minAmounts[2];
            pool.remove_liquidity(_lpIn, __minAmounts);
            _amountReceived = new uint256[](3);
        } else {
            uint256[2] memory __minAmounts;
            __minAmounts[0] = _minAmounts[0];
            __minAmounts[1] = _minAmounts[1];
            pool.remove_liquidity(_lpIn, __minAmounts);
            _amountReceived = new uint256[](2);
        }
        uint256[] memory _assetBalances1 = showPoolAssetBalances(_poolAddress);
        for (uint i = 0; i < poolInfo[_poolAddress].coinCount; i++) {
            _amountReceived[i] = _assetBalances1[i] - _assetBalances0[i];
            withdrawAccounting(_poolAddress, _amountReceived[i], i);
        }

        emit WithdrawFromPool(_poolAddress, _minAmounts, _lpIn);
    }
    
    // @notice Function to perform accounting calculations for withdrawal
    /// @param _poolAddress Address of Curve Pool
    /// @param _amountReceived Coin recieved from withdrawal 
    /// @param _coinIndex Curve Pool target coin index
    function withdrawAccounting(address _poolAddress, uint256 _amountReceived, uint256 _coinIndex) internal {
        IMinCurvePool pool = IMinCurvePool(_poolAddress);
        if (_amountReceived < poolInfo[_poolAddress].tokenDeposited[_coinIndex]) {
            poolInfo[_poolAddress].tokenDeposited[_coinIndex] -= _amountReceived;
        } else {
            poolInfo[_poolAddress].tokenProfitTaken[_coinIndex] += _amountReceived - poolInfo[_poolAddress].tokenDeposited[_coinIndex];
            poolInfo[_poolAddress].tokenDeposited[_coinIndex] = 0;
        }
        if (poolInfo[_poolAddress].isMetaPool && poolInfo[_poolAddress].baseTokenIndex == _coinIndex) {
            address _basePoolAddress = lpTokenToPool[pool.coins(_coinIndex)];
            if (poolInfo[_basePoolAddress].lpDepositedAsCollateral > _amountReceived){
                poolInfo[_basePoolAddress].lpDepositedAsCollateral -= _amountReceived;
            } else {
                poolInfo[_basePoolAddress].lpDepositedAsCollateral = 0;
            }
        }
    }
    // @notice Function to withdraw all tokens from specific Curve Pool based on current pool ratio
    /// @param _poolAddress Address of Curve Pool
    /// @param _minAmounts Min amounts of coin out
    function withdrawAllAtCurrRatio(address _poolAddress, uint256[] memory _minAmounts) 
        public
        approvedPool(_poolAddress) 
        onlyByOwnerOperator 
        returns (uint256[] memory _amountReceived) 
    {
        // Limitation : This function is not working for Crypto pools
        ERC20 lpToken = ERC20(poolInfo[_poolAddress].lpTokenAddress);
        uint256 _allLP = lpToken.balanceOf(address(this));
        _amountReceived = withdrawAtCurrRatio(_poolAddress, _allLP, _minAmounts);
    }

    // @notice Function to use Curve Pool to swap two tokens
    /// @param _poolAddress Address of Curve Pool
    /// @param _inIndex Curve Pool input coin index
    /// @param _outIndex Curve Pool output coin index
    /// @param _inAmount Amount of input coin
    /// @param _minOutAmount Min amount of output coin
    function poolSwap(address _poolAddress, uint256 _inIndex, uint256 _outIndex, uint256 _inAmount, uint256 _minOutAmount) 
        public
        approvedPool(_poolAddress) 
        onlyByOwnerOperator 
    {
        IMinCurvePool pool = IMinCurvePool(_poolAddress);
        ERC20 _token = ERC20(pool.coins(_inIndex));
        _token.approve(_poolAddress, 0); // For USDT and others
        _token.approve(_poolAddress, _inAmount);
        if(poolInfo[_poolAddress].isCryptoPool) {
            pool.exchange(_inIndex, _outIndex, _inAmount, _minOutAmount);
        } else {
            int128 __inIndex = int128(uint128(_inIndex));
            int128 __outIndex = int128(uint128(_outIndex));
            pool.exchange(__inIndex, __outIndex, _inAmount, _minOutAmount);
        }

        emit Swap(_poolAddress, _inIndex, _outIndex, _inAmount, _minOutAmount);
    }

    /* ============================================ BURNS AND GIVEBACKS ================================================= */

    /// @notice Return USDC back to minter
    /// @param _collateralAmount USDC amount
    function giveCollatBack(uint256 _collateralAmount) external onlyOwner {
        USDC.approve(address(amoMinter), _collateralAmount);
        amoMinter.receiveCollatFromAMO(_collateralAmount);
    }
   
    /// @notice Burn unneeded or excess FRAX. Goes through the minter
    /// @param _fraxAmount Amount of FRAX to burn
    function burnFRAX(uint256 _fraxAmount) external onlyOwner {
        FRAX.approve(address(amoMinter), _fraxAmount);
        amoMinter.burnFraxFromAMO(_fraxAmount);
    }

    
    /* ============================================== VAULT FUNCTIONS =================================================== */

    /// @notice Deposit Pool LP tokens, convert them to Convex LP, and deposit into their vault
    /// @param _poolAddress Address of Curve Pool
    /// @param _poolLpIn Amount of LP for deposit
    function depositToVault(address _poolAddress, uint256 _poolLpIn) 
        external 
        onlyByOwnerOperator 
        approvedPool(_poolAddress) 
        hasVault(_poolAddress)
    {
        // Approve the isMetaPool LP tokens for the vault contract
        ERC20 _poolLpToken = ERC20(poolInfo[_poolAddress].lpTokenAddress);
        _poolLpToken.approve(address(convexBooster), _poolLpIn);
        
        // Deposit the isMetaPool LP into the vault contract
        convexBooster.deposit(poolInfo[_poolAddress].lpDepositPid, _poolLpIn, true);

        emit DepositToVault(_poolAddress, _poolLpIn);
    }

    /// @notice Withdraw Convex LP, convert it back to Pool LP tokens, and give them back to the sender
    /// @param _poolAddress Address of Curve Pool
    /// @param amount Amount of LP for withdraw
    /// @param claim if claim rewards or not
    function withdrawAndUnwrapFromVault(address _poolAddress, uint256 amount, bool claim) 
        external 
        onlyByOwnerOperator
        approvedPool(_poolAddress) 
        hasVault(_poolAddress)
    {
        IConvexBaseRewardPool _convexBaseRewardPool = IConvexBaseRewardPool(poolInfo[_poolAddress].rewardsContractAddress);
        _convexBaseRewardPool.withdrawAndUnwrap(amount, claim);

        emit WithdrawFromVault(_poolAddress, amount);
    }

    /// @notice Withdraw rewards
    /// @param crvAmount CRV Amount to withdraw
    /// @param cvxAmount CVX Amount to withdraw
    /// @param cvxCRVAmount cvxCRV Amount to withdraw
    /// @param fxsAmount FXS Amount to withdraw
    function withdrawRewards(
        uint256 crvAmount,
        uint256 cvxAmount,
        uint256 cvxCRVAmount,
        uint256 fxsAmount
    ) external onlyByOwnerOperator {
        if (crvAmount > 0) TransferHelper.safeTransfer(crvAddress, owner(), crvAmount);
        if (cvxAmount > 0) TransferHelper.safeTransfer(address(cvx), owner(), cvxAmount);
        if (cvxCRVAmount > 0) TransferHelper.safeTransfer(cvxCrvAddress, owner(), cvxCRVAmount);
        if (fxsAmount > 0) TransferHelper.safeTransfer(fxsAddress, owner(), fxsAmount);
    }

    /// @notice Deposit Pool LP tokens, convert them to Convex LP, and deposit into their vault
    /// @param _poolAddress Address of Curve Pool
    /// @param _poolLpIn Amount of LP for deposit
    /// @param _secs Lock time in sec
    /// @return _kek_id lock stake ID
    function depositToFxsVault(address _poolAddress, uint256 _poolLpIn, uint256 _secs) 
        external 
        onlyByOwnerOperator 
        approvedPool(_poolAddress) 
        hasFxsVault(_poolAddress)
        returns (bytes32 _kek_id)
    {
        // Approve the LP tokens for the vault contract
        ERC20 _poolLpToken = ERC20(poolInfo[_poolAddress].lpTokenAddress);
        _poolLpToken.approve(poolInfo[_poolAddress].fxsPersonalVaultAddress, _poolLpIn);
        
        // Deposit the LP into the fxs vault contract
        IFxsPersonalVault fxsVault = IFxsPersonalVault(poolInfo[_poolAddress].fxsPersonalVaultAddress);
        _kek_id = fxsVault.stakeLockedCurveLp(_poolLpIn, _secs);
        vaultKekIds[_poolAddress].push(_kek_id);
        kekIdTotalDeposit[_kek_id] = _poolLpIn;
    }

    /// @notice Increase lock time
    /// @param _poolAddress Address of Curve Pool
    /// @param _kek_id lock stake ID
    /// @param new_ending_ts new ending timestamp 
    function lockLongerInFxsVault (address _poolAddress, bytes32 _kek_id, uint256 new_ending_ts ) 
        external 
        onlyByOwnerOperator 
        approvedPool(_poolAddress) 
        hasFxsVault(_poolAddress)
    {
        IFxsPersonalVault fxsVault = IFxsPersonalVault(poolInfo[_poolAddress].fxsPersonalVaultAddress);
        fxsVault.lockLonger(_kek_id, new_ending_ts);
    }

    /// @notice Increase locked LP amount
    /// @param _poolAddress Address of Curve Pool
    /// @param _kek_id lock stake ID
    /// @param _addl_liq Amount of LP for deposit
    function lockMoreInFxsVault (address _poolAddress, bytes32 _kek_id, uint256 _addl_liq ) 
        external 
        onlyByOwnerOperator 
        approvedPool(_poolAddress) 
        hasFxsVault(_poolAddress)
    {
        kekIdTotalDeposit[_kek_id] += _addl_liq;
        // Approve the LP tokens for the vault contract
        ERC20 _poolLpToken = ERC20(poolInfo[_poolAddress].lpTokenAddress);
        _poolLpToken.approve(poolInfo[_poolAddress].fxsPersonalVaultAddress, _addl_liq);

        IFxsPersonalVault fxsVault = IFxsPersonalVault(poolInfo[_poolAddress].fxsPersonalVaultAddress);
        fxsVault.lockAdditionalCurveLp(_kek_id, _addl_liq);
    }

    /// @notice Withdraw Convex LP, convert it back to Pool LP tokens, and give them back to the sender
    /// @param _poolAddress Address of Curve Pool
    /// @param _kek_id lock stake ID
    function withdrawAndUnwrapFromFxsVault(address _poolAddress, bytes32 _kek_id) 
        external 
        onlyByOwnerOperator
        approvedPool(_poolAddress) 
        hasFxsVault(_poolAddress)
    {
        kekIdTotalDeposit[_kek_id] = 0;
        IFxsPersonalVault fxsVault = IFxsPersonalVault(poolInfo[_poolAddress].fxsPersonalVaultAddress);
        fxsVault.withdrawLockedAndUnwrap(_kek_id);
    }

    /// @notice Claim CVX, CRV, and FXS rewards
    /// @param _poolAddress Address of Curve Pool
    /// @param _claimConvexVault Claim convex vault rewards
    /// @param _claimFxsVault Claim FXS personal vault rewards
    function claimRewards(address _poolAddress, bool _claimConvexVault, bool _claimFxsVault) 
        external 
        onlyByOwnerOperator
        approvedPool(_poolAddress) 
    {
        if (_claimConvexVault) {
            address[] memory rewardContracts = new address[](1);
            rewardContracts[0] = poolInfo[_poolAddress].rewardsContractAddress;
            uint256[] memory chefIds = new uint256[](0);

            convex_claim_zap.claimRewards(
                rewardContracts, 
                chefIds, 
                false, 
                false, 
                false, 
                0, 
                0
            );
        }
        if (_claimFxsVault) {
            if(poolInfo[_poolAddress].hasFxsVault){
                IFxsPersonalVault fxsVault = IFxsPersonalVault(poolInfo[_poolAddress].fxsPersonalVaultAddress);
                fxsVault.getReward();
            }
        }
        
    }

    /* ====================================== RESTRICTED GOVERNANCE FUNCTIONS =========================================== */

    /// @notice Add new Curve Pool
    /// @param _configData config data for a new pool
    /// @param _poolAddress Address of Curve Pool
    function addOrSetPool(
        bytes memory _configData,
        address _poolAddress
    ) external onlyOwner {
        (   bool _isCryptoPool,
            bool _hasFrax,
            bool _hasUsdc,
            bool _isMetaPool,
            uint _coinCount,
            uint _fraxIndex,
            uint _usdcIndex,
            uint _baseTokenIndex,
            address _lpTokenAddress
        ) = abi.decode(_configData, (bool, bool, bool, bool, uint, uint, uint, uint, address));
        if (poolInitialized[_poolAddress]){
            poolInfo[_poolAddress].isCryptoPool = _isCryptoPool;
            poolInfo[_poolAddress].hasFrax = _hasFrax;
            poolInfo[_poolAddress].hasUsdc = _hasUsdc;
            poolInfo[_poolAddress].isMetaPool = _isMetaPool;
            poolInfo[_poolAddress].coinCount = _coinCount;
            poolInfo[_poolAddress].fraxIndex = _fraxIndex;
            poolInfo[_poolAddress].usdcIndex = _usdcIndex;
            poolInfo[_poolAddress].baseTokenIndex = _baseTokenIndex;
            poolInfo[_poolAddress].lpTokenAddress = _lpTokenAddress;
        } else {
            poolInitialized[_poolAddress] = true;
            poolArray.push(_poolAddress);
            poolInfo[_poolAddress] = CurvePool({
                isCryptoPool: _isCryptoPool,
                hasFrax: _hasFrax,
                hasUsdc: _hasUsdc,
                isMetaPool: _isMetaPool,
                hasVault: false,
                coinCount: _coinCount,
                fraxIndex: _fraxIndex,
                usdcIndex: _usdcIndex,
                // Pool Addresses
                poolAddress: _poolAddress,
                lpTokenAddress: _lpTokenAddress,
                // Convex Vault Addresses
                lpDepositPid: 0,
                rewardsContractAddress: address(0),
                hasFxsVault: false, 
                fxsPersonalVaultAddress: address(0),
                // Accounting params
                baseTokenIndex: _baseTokenIndex,
                tokenDeposited: new uint256[](_coinCount),
                tokenMaxAllocation: new uint256[](_coinCount),
                tokenProfitTaken: new uint256[](_coinCount),
                lpDepositedAsCollateral: 0
            });
            lpTokenToPool[_lpTokenAddress] = _poolAddress;
        }
        
        emit AddOrSetPool(_poolAddress, new uint256[](_coinCount));
    }

    /// @notice Set Curve Pool Convex vault
    /// @param _poolAddress Address of Curve Pool
    /// @param _rewardsContractAddress Convex Rewards Contract Address
    function setPoolVault(
        address _poolAddress,
        address _rewardsContractAddress
    ) external onlyOwner approvedPool(_poolAddress) {
        poolInfo[_poolAddress].hasVault = true;
        IConvexBaseRewardPool _convexBaseRewardPool = IConvexBaseRewardPool(_rewardsContractAddress);
        uint256 _lpDepositPid = _convexBaseRewardPool.pid();
        poolInfo[_poolAddress].lpDepositPid = _lpDepositPid;
        poolInfo[_poolAddress].rewardsContractAddress = _rewardsContractAddress;
    }

    /// @notice Create a personal vault for that pool
    /// @param _poolAddress Address of Curve Pool
    /// @param _pid Pool id in FXS booster pool registry
    function createFxsVault(address _poolAddress, uint256 _pid) 
        external 
        onlyOwner 
        approvedPool(_poolAddress) 
        hasVault(_poolAddress)
    {
        poolInfo[_poolAddress].hasFxsVault = true;
        address _fxsPersonalVaultAddress = convexFXSBooster.createVault(_pid);
        poolInfo[_poolAddress].fxsPersonalVaultAddress = _fxsPersonalVaultAddress;
        IFxsPersonalVault fxsVault = IFxsPersonalVault(_fxsPersonalVaultAddress);
        require(poolInfo[_poolAddress].lpTokenAddress == fxsVault.curveLpToken(), "LP token is not matching");
    }

    /// @notice Set Curve Pool max allocations
    /// @param _poolAddress Address of Curve Pool
    /// @param _poolMaxAllocations Max allocation for each Pool coin
    function setPoolAllocation(
        address _poolAddress,
        uint256[] memory _poolMaxAllocations
    ) external onlyOwner approvedPool(_poolAddress) {
        for(uint256 i = 0; i < poolInfo[_poolAddress].coinCount; i++){
            poolInfo[_poolAddress].tokenMaxAllocation[i] = _poolMaxAllocations[i];
        }
        emit AddOrSetPool(_poolAddress, poolInfo[_poolAddress].tokenMaxAllocation);
    }

    /// @notice Set Curve Pool accounting params for LP transfer 
    /// @param _poolAddress Address of Curve Pool
    /// @param _amounts pool's coins deposited for acquiring the position
    /// @param _lpAmount Transfered LP token
    /// @param _isDeposit is this a LP deposit or withdraw 
    function setPoolManualLPTrans(
        address _poolAddress,
        uint256[] memory _amounts,
        uint256 _lpAmount,
        bool _isDeposit
    ) public onlyOwner approvedPool(_poolAddress) {
        for(uint256 i = 0; i < poolInfo[_poolAddress].coinCount; i++){
            if(_isDeposit) {
                poolInfo[_poolAddress].tokenDeposited[i] += _amounts[i];
                if (poolInfo[_poolAddress].isMetaPool && poolInfo[_poolAddress].baseTokenIndex == i) {
                    IMinCurvePool pool = IMinCurvePool(_poolAddress);
                    address _baseTokenAddress = pool.coins(i);
                    address _basePoolAddress = lpTokenToPool[_baseTokenAddress];
                    poolInfo[_basePoolAddress].lpDepositedAsCollateral += _amounts[i];
                }
            } else {
                withdrawAccounting(_poolAddress, _amounts[i], i);
            }
        }
        if(_isDeposit) {
            emit DepositToPool(_poolAddress, _amounts, _lpAmount);
        } else {
            emit WithdrawFromPool(_poolAddress, _amounts, _lpAmount);
        }
    }

    /// @notice Set Curve Pool accounting params for vault token transfer 
    /// @param _poolAddress Address of Curve Pool
    /// @param _amounts pool's coins deposited/withdrawn for acquiring the lp position
    /// @param _lpAmount LP token deposited/widrawn for acquiring the vault position
    /// @param _isDeposit is this a LP deposit or withdraw 
    function setPoolManualVaultTokTrans(
        address _poolAddress,
        uint256[] memory _amounts,
        uint256 _lpAmount,
        bool _isDeposit
    ) external onlyOwner approvedPool(_poolAddress) hasVault(_poolAddress) {
        setPoolManualLPTrans(_poolAddress, _amounts, _lpAmount, _isDeposit);
        if(_isDeposit) {
            emit DepositToVault(_poolAddress, _lpAmount);
        } else {
            emit WithdrawFromVault(_poolAddress, _lpAmount);
        }
    }

    /// @notice Change the FRAX Minter
    /// @param _amoMinterAddress FRAX AMO minter
    function setAMOMinter(address _amoMinterAddress) external onlyOwner {
        emit SetAMOMinter(address(amoMinter), _amoMinterAddress);

        amoMinter = IFraxAMOMinter(_amoMinterAddress);
    }

    /// @notice Change the AMO Helper
    /// @param _amoHelperAddress AMO Helper Address
    function setAMOHelper(address _amoHelperAddress) external onlyOwner {
        emit SetAMOHelper(address(amoHelper), _amoHelperAddress);

        amoHelper = ICurveAMOv5Helper(_amoHelperAddress);
    }

    /// @notice Change the Operator address
    /// @param _newOperatorAddress Operator address
    function setOperatorAddress(address _newOperatorAddress) external onlyOwner {
        emit SetOperator(operatorAddress, _newOperatorAddress);

        operatorAddress = _newOperatorAddress;
    }

    /// @notice in terms of 1e6 (overriding global_collateral_ratio)
    /// @param _state overriding / not
    /// @param _discountRate New Discount Rate
    function setDiscountRate(bool _state, uint256 _discountRate) external onlyOwner {
        setDiscount = _state;
        discountRate = _discountRate;
    }

    /// @notice Recover ERC20 tokens 
    /// @param tokenAddress address of ERC20 token
    /// @param tokenAmount amount to be withdrawn
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        // Can only be triggered by owner
        TransferHelper.safeTransfer(address(tokenAddress), msg.sender, tokenAmount);
    }

    // Generic proxy
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value:_value}(_data);
        return (success, result);
    }
}