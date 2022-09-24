// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =========================== FraxlendAMO ============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Amirnader Aghayeghazvini: https://github.com/amirnader-ghazvini

// Reviewer(s) / Contributor(s)
// Drake Evans: https://github.com/DrakeEvans
// Travis Moore: https://github.com/FortisFortuna
// Dennis: https://github.com/denett

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFraxAMOMinter.sol";
import "./interfaces/IFrax.sol";
import "./interfaces/IFraxlendPair.sol";
import "./interfaces/IFraxlendPairDeployer.sol";
import "./interfaces/IFraxlendPairHelper.sol";
import "./interfaces/IFraxUnifiedFarm_ERC20.sol";

contract FraxlendAMO is Ownable {
    /* ============================================= STATE VARIABLES ==================================================== */

    // Fraxlend pairs with FRAX as asset
    address[] public pairsArray;
    mapping(address => bool) public pairsInitialized;
    mapping(address => uint256) public pairsMaxAllocation;
    mapping(address => uint256) public pairsMintedFrax;
    mapping(address => uint256) public pairsProfitTaken;

    // Fraxlend pairs with FRAX as collateral
    address[] public borrowPairsArray;
    mapping(address => bool) public borrowPairsInitialized;
    mapping(address => uint256) public borrowPairsMaxCollateral;
    mapping(address => uint256) public borrowPairsMaxLTV;
    mapping(address => uint256) public borrowPairsCollateralFrax;

    // Constants (ERC20)
    IFrax public immutable FRAX;

    // Addresses COnfig
    address public operatorAddress;
    IFraxAMOMinter public amoMinter;
    IFraxlendPairDeployer public fraxlendPairDeployer;
    IFraxlendPairHelper public fraxlendPairHelper;

    // Settings
    uint256 public constant PRICE_PRECISION = 1e6;

    /* =============================================== CONSTRUCTOR ====================================================== */

    /// @notice constructor
    /// @param amoMinterAddress_ AMO minter address
    /// @param operatorAddress_ address of FraxlendPairDeployer
    /// @param fraxlendPairDeployerAddress_ address of FraxlendPairDeployer
    /// @param fraxlendPairHelperAddress_ address of FraxlendPairHelper
    /// @param fraxAddress_ address of FraxlendPairDeployer
    constructor(
        address amoMinterAddress_,
        address operatorAddress_,
        address fraxlendPairDeployerAddress_,
        address fraxlendPairHelperAddress_,
        address fraxAddress_
    ) Ownable() {
        amoMinter = IFraxAMOMinter(amoMinterAddress_);

        operatorAddress = operatorAddress_;

        fraxlendPairDeployer = IFraxlendPairDeployer(fraxlendPairDeployerAddress_);

        fraxlendPairHelper = IFraxlendPairHelper(fraxlendPairHelperAddress_);

        FRAX = IFrax(fraxAddress_);

        emit StartAMO(amoMinterAddress_, operatorAddress_, fraxlendPairDeployerAddress_, fraxlendPairHelperAddress_);
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

    modifier approvedPair(address _pair) {
        require(pairsMaxAllocation[_pair] > 0, "Pair not approved for allocation");
        _;
    }

    modifier onBudget(address _pair) {
        _;
        require(
            pairsMaxAllocation[_pair] >= pairsMintedFrax[_pair],
            "Over allocation budget"
        );
    }

    modifier approvedBorrowPair(address _pair) {
        require(borrowPairsMaxCollateral[_pair] > 0, "Pair not approved for borrow");
        _;
    }

    modifier borrowOnBudget(address _pair) {
        _;
        require(
            borrowPairsMaxCollateral[_pair] >= borrowPairsCollateralFrax[_pair],
            "Over collateral budget"
        );
    }

    modifier borrowOnLTV(address _pair) {
        _;
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pair);
        uint256 _exchangeRate = fraxlendPairHelper.previewUpdateExchangeRate(_pair);
        (uint256 _LTV_PRECISION, , , , uint256 _EXCHANGE_PRECISION, , , ) = _fraxlendPair.getConstants();
        uint256 _borrowShare = _fraxlendPair.userBorrowShares(address(this));
        (uint256 _borrowAmount, , ) = fraxlendPairHelper.toBorrowAmount(_pair, _borrowShare, block.timestamp, block.number, false);
        uint256 _collateralAmount = _fraxlendPair.userCollateralBalance(address(this));
        require(_EXCHANGE_PRECISION > 0, "EXCHANGE_PRECISION is zero.");
        require(_collateralAmount > 0, "Collateral amount is zero.");
        uint256 _ltv = (((_borrowAmount * _exchangeRate) / _EXCHANGE_PRECISION) * _LTV_PRECISION) / _collateralAmount;
        require(_ltv <= borrowPairsMaxLTV[_pair], "Max LTV limit for borrowing");
    }

    /* ================================================== EVENTS ======================================================== */

    /// @notice The ```StartAMO``` event fires when the AMO deploy
    /// @param amoMinterAddress_ AMO minter address
    /// @param operatorAddress_ address of FraxlendPairDeployer
    /// @param fraxlendPairDeployerAddress_ address of FraxlendPairDeployer
    /// @param fraxlendPairHelperAddress_ address of FraxlendPairHelper
    event StartAMO(address amoMinterAddress_, address operatorAddress_, address fraxlendPairDeployerAddress_, address fraxlendPairHelperAddress_); 

    /// @notice The ```SetOperator``` event fires when the operatorAddress is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetOperator(address _oldAddress, address _newAddress); 

    /// @notice The ```SetAMOMinter``` event fires when the AMO Minter is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetAMOMinter(address _oldAddress, address _newAddress);

    /// @notice The ```SetFraxlendPairHelper``` event fires when the FraxlendPairHelper is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetFraxlendPairHelper(address _oldAddress, address _newAddress);

    /// @notice The ```SetFraxlendPairDeployer``` event fires when the FraxlendPairDeployer is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetFraxlendPairDeployer(address _oldAddress, address _newAddress);

    /// @notice The ```SetPair``` event fires when a pair is added to AMO
    /// @param _pairAddress The pair address
    /// @param _maxAllocation Max allowed allocation of AMO into the pair 
    event SetPair(address _pairAddress, uint256 _maxAllocation);

    /// @notice The ```SetBorrowPair``` event fires when a pair is added to AMO for borrowing
    /// @param _pairAddress The pair address
    /// @param _maxCollateralAllocation Max allowed collateral allocation of AMO into the pair 
    /// @param _maxLTV Max allowed LTV for AMO for borrow position 
    event SetBorrowPair(address _pairAddress, uint256 _maxCollateralAllocation, uint256 _maxLTV);

    /// @notice The ```DepositToPair``` event fires when a deposit happen to a pair
    /// @param _pairAddress The pair address
    /// @param _amount Deposited FRAX amount
    /// @param _shares Deposited shares
    event DepositToPair(address _pairAddress, uint256 _amount, uint256 _shares);

    /// @notice The ```WithdrawFromPair``` event fires when a withdrawal happen from a pair
    /// @param _pairAddress The pair address
    /// @param _amount Withdrawn FRAX amount
    /// @param _shares Withdrawn shares
    event WithdrawFromPair(address _pairAddress, uint256 _amount, uint256 _shares);

    /// @notice The ```AddCollateral``` event fires when collateral add to a pair
    /// @param _pairAddress The pair address
    /// @param _amount Collateral FRAX amount
    event AddCollateral(address _pairAddress, uint256 _amount);

    /// @notice The ```RemoveCollateral``` event fires when collateral remove from a pair
    /// @param _pairAddress The pair address
    /// @param _amount Collateral FRAX amount
    event RemoveCollateral(address _pairAddress, uint256 _amount);

    /// @notice The ```BorrowFromPair``` event fires when a borrow happen from a pair
    /// @param _pairAddress The pair address
    /// @param _amount Borrowed asset amount
    /// @param _shares Borrowed asset shares
    event BorrowFromPair(address _pairAddress, uint256 _amount, uint256 _shares);

    /// @notice The ```RepayToPair``` event fires when a repay happen to a pair
    /// @param _pairAddress The pair address
    /// @param _amount Repay borrowed asset amount
    /// @param _shares Repay borrowed asset shares
    event RepayToPair(address _pairAddress, uint256 _amount, uint256 _shares);


    /* =================================================== VIEWS ======================================================== */
    
    /// @notice Show allocations of FraxlendAMO in FRAX
    /// @return _allocations : [Unallocated FRAX, Lent FRAX, Used as Collateral FRAX, Total FRAX]
    function showAllocations() public view returns (uint256[4] memory _allocations) {
        // Note: All numbers given are in FRAX unless otherwise indicated
        
        // Unallocated FRAX
        _allocations[0] = FRAX.balanceOf(address(this));
        
        // Allocated FRAX (FRAX in Fraxlend Pairs)
        address[] memory _pairsArray = pairsArray;
        for (uint256 i = 0; i < _pairsArray.length; i++) {
            IFraxlendPair _fraxlendPair = IFraxlendPair(_pairsArray[i]);
            uint256 _shares = _fraxlendPair.balanceOf(address(this));
            (uint256 _amount, , ) = fraxlendPairHelper.toAssetAmount(_pairsArray[i], _shares, block.timestamp, block.number, false);

            _allocations[1] += _amount;
        }


        // FRAX used as collateral in Fraxlend Pairs
        address[] memory _borrowPairsArray = borrowPairsArray;
        for (uint256 i = 0; i < _borrowPairsArray.length; i++) {
            IFraxlendPair _fraxlendPair = IFraxlendPair(_borrowPairsArray[i]);
            uint256 _amount = _fraxlendPair.userCollateralBalance(address(this));
            _allocations[2] += _amount;
        }
        // Total FRAX possessed in various forms
        uint256 sumFrax = _allocations[0] + _allocations[1] + _allocations[2];
        _allocations[3] = sumFrax;
    }

    /// @notice Show allocations of FraxlendAMO into Fraxlend pair in FRAX
    /// @param _pairAddress Address of FraxlendPair
    /// @return _allocations :[Minted FRAX into the pair, Current AMO owned FRAX in pair, AMO FRAX Profit Taken from pair, CR of FRAX in pair, CR Precision]
    function showPairAccounting(address _pairAddress) public view returns (uint256[5] memory _allocations) {
        // All numbers given are in FRAX unless otherwise indicated
        _allocations[0] = pairsMintedFrax[_pairAddress];
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        uint256 _shares = _fraxlendPair.balanceOf(address(this));
        (uint256 _assetAmount,, ) = fraxlendPairHelper.toAssetAmount(_pairAddress, _shares, block.timestamp, block.number, false);
        _allocations[1] = _assetAmount;
        _allocations[2] = pairsProfitTaken[_pairAddress];
         
        // Calculate Pair CR (CR related items are not in FRAX)
        (uint128 _totalAssetAmount, , uint128 _totalBorrowAmount, , uint256 _totalCollateral) = fraxlendPairHelper.getPairAccounting(_pairAddress);
        uint256 _exchangeRate = fraxlendPairHelper.previewUpdateExchangeRate(_pairAddress);
        (uint256 _LTV_PRECISION, , , , uint256 _EXCHANGE_PRECISION, , , ) = _fraxlendPair.getConstants();
        if (_totalCollateral > 0 && _totalAssetAmount > 0 && _totalBorrowAmount > 0) {
            uint256 _borrowedLTV = (((_totalBorrowAmount * _exchangeRate) / _EXCHANGE_PRECISION) * _LTV_PRECISION) / _totalCollateral;
            _allocations[3] = ((((_totalBorrowAmount * _LTV_PRECISION) / _borrowedLTV)) * _LTV_PRECISION) / _totalAssetAmount;
        } else {
            _allocations[3] = 0; 
        }
        _allocations[4] = _LTV_PRECISION;
    }

    /// @notice Show borrow pairs accounting in FRAX
    /// @param _pairAddress Address of borrow FraxlendPair
    /// @return _allocations :[ Minted FRAX into the pair, Current AMO owned FRAX in pair, Current AMO owned Asset, Current AMO borrowed amount pair ]
    function showBorrowPairAccounting(address _pairAddress) public view returns (uint256[4] memory _allocations) {
        // All numbers given are in FRAX unless otherwise stated
        _allocations[0] = borrowPairsCollateralFrax[_pairAddress];
        IFraxlendPair fraxlendPair = IFraxlendPair(_pairAddress);
        _allocations[1] = fraxlendPair.userCollateralBalance(address(this));
        IERC20 _asset = IERC20(fraxlendPair.asset());
        // Asset related items are not in FRAX
        uint256 _totalAssetBalance = _asset.balanceOf(address(this));
        _allocations[2] = _totalAssetBalance;
        uint256 borrowShare = fraxlendPair.userBorrowShares(address(this));
        ( uint256 _borrowAmount ,,) = fraxlendPairHelper.toBorrowAmount(_pairAddress, borrowShare, block.timestamp, block.number, false);
        _allocations[3] = _borrowAmount;
    }

    /// @notice total FRAX balance
    /// @return fraxValE18 FRAX value
    /// @return collatValE18 FRAX collateral value
    function dollarBalances() public view returns (uint256 fraxValE18, uint256 collatValE18) {
        fraxValE18 = showAllocations()[3];
        collatValE18 = (fraxValE18 * FRAX.global_collateral_ratio()) / (PRICE_PRECISION);
    }

    /// @notice Backwards compatibility
    /// @return FRAX minted balance of the FraxlendAMO
    function mintedBalance() public view returns (int256) {
        return amoMinter.frax_mint_balances(address(this));
    }

/* =============================================== PAIR FUNCTIONS =================================================== */
    
    /// @notice accrue Interest of a FraxlendPair
    /// @param _pairAddress Address of FraxlendPair
    function accrueInterestFraxlendPair(address _pairAddress) public onlyByOwnerOperator {
        IFraxlendPair(_pairAddress).addInterest();
    }

    /// @notice  accrue Interest of all whitelisted FraxlendPairs
    function accrueInterestAllFraxlendPair() external onlyByOwnerOperator {
        address[] memory _pairsArray = pairsArray;
        for (uint256 i = 0; i < _pairsArray.length; i++) {
            if (pairsInitialized[_pairsArray[i]]) {
                accrueInterestFraxlendPair(_pairsArray[i]);
            }
        }
        address[] memory _borrowPairsArray = borrowPairsArray;
        for (uint256 i = 0; i < _borrowPairsArray.length; i++) {
            if (pairsInitialized[_borrowPairsArray[i]]) {
                accrueInterestFraxlendPair(_borrowPairsArray[i]);
            }
        }
    }

    /// @notice Add new FraxlendPair with FRAX as asset address to list
    /// @param _pairAddress Address of FraxlendPair
    /// @param _maxAllocation Max Allocation amount for FraxlendPair
    function setPair(
        address _pairAddress,
        uint256 _maxAllocation
    ) public onlyOwner {
        require(address(IFraxlendPair(_pairAddress).asset()) == address(FRAX), "Pair asset is not FRAX");
        pairsMaxAllocation[_pairAddress] = _maxAllocation;
        
        if (pairsInitialized[_pairAddress] == false) {
            pairsInitialized[_pairAddress] = true;
            pairsArray.push(_pairAddress);
        }
        emit SetPair(_pairAddress, _maxAllocation);
    }

    /// @notice Add new FraxlendPair with FRAX as collateral address to list
    /// @param _pairAddress Address of FraxlendPair
    /// @param _maxCollateral Max Collateral amount for borrowing from FraxlendPair
    /// @param _maxLTV Max LTV for borrowing from FraxlendPair 
    function setBorrowPair(
        address _pairAddress,
        uint256 _maxCollateral,
        uint256 _maxLTV
    ) public onlyOwner {
        require(address(IFraxlendPair(_pairAddress).collateralContract()) == address(FRAX), "Pair collateral is not FRAX");
        borrowPairsMaxCollateral[_pairAddress] = _maxCollateral;
        borrowPairsMaxLTV[_pairAddress] = _maxLTV;
        if (borrowPairsInitialized[_pairAddress] == false) {
            borrowPairsInitialized[_pairAddress] = true;
            borrowPairsArray.push(_pairAddress);
        }
        emit SetBorrowPair(_pairAddress, _maxCollateral, _maxLTV);
    }

/* ============================================= LENDING FUNCTIONS ================================================== */

    /// @notice Function to deposit FRAX to specific FraxlendPair
    /// @param _pairAddress Address of FraxlendPair
    /// @param _fraxAmount Amount of FRAX to be deposited
    function depositToPair(address _pairAddress, uint256 _fraxAmount)
        public
        approvedPair(_pairAddress)
        onBudget(_pairAddress)
        onlyByOwnerOperator
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        FRAX.approve(_pairAddress, _fraxAmount);
        uint256 _shares = _fraxlendPair.deposit(_fraxAmount, address(this));
        pairsMintedFrax[_pairAddress] += _fraxAmount;

        emit DepositToPair(_pairAddress, _fraxAmount, _shares);
    }

    /// @notice Function to withdraw FRAX from specific FraxlendPair
    /// @param _pairAddress Address of FraxlendPair
    /// @param _shares shares to be withdrawed
    function withdrawFromPair(address _pairAddress, uint256 _shares) public onlyByOwnerOperator returns (uint256 _amountWithdrawn) {      
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        
        // Calculate current amount balance
        uint256 _currentBalanceShares = _fraxlendPair.balanceOf(address(this));
        (uint256 _currentBalanceAmount,,) = fraxlendPairHelper.toAssetAmount(_pairAddress, _currentBalanceShares, block.timestamp, block.number, false);
        
        // Withdraw amount
        _amountWithdrawn = _fraxlendPair.redeem(_shares, address(this), address(this));

        // Effects
        if (pairsMintedFrax[_pairAddress] < _currentBalanceAmount) {
            uint256 _profit = _currentBalanceAmount - pairsMintedFrax[_pairAddress];
            if (_profit > _amountWithdrawn) {
                pairsProfitTaken[_pairAddress] = pairsProfitTaken[_pairAddress] + _amountWithdrawn;
            } else {
                pairsProfitTaken[_pairAddress] = pairsProfitTaken[_pairAddress] + _profit;
                pairsMintedFrax[_pairAddress] = pairsMintedFrax[_pairAddress] - (_amountWithdrawn - _profit);
            }
        } else {
            pairsMintedFrax[_pairAddress] = pairsMintedFrax[_pairAddress] - _amountWithdrawn;
        }
        emit WithdrawFromPair(_pairAddress, _amountWithdrawn, _shares);
    }

    /// @notice Function to withdraw FRAX from all FraxlendPair
    /// @param _pairAddress Address of FraxlendPair
    function withdrawMaxFromPair(address _pairAddress) public onlyByOwnerOperator returns (uint256 _amountWithdrawn) {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        uint256 _shares = _fraxlendPair.balanceOf(address(this));
        if (_shares == 0) {
            return 0;
        }
        _fraxlendPair.addInterest();
        (uint128 _totalAssetAmount, ) = _fraxlendPair.totalAsset();
        (uint128 _totalBorrowAmount, ) = _fraxlendPair.totalBorrow();  
        uint256 _availableAmount = _totalAssetAmount - _totalBorrowAmount;
        uint256 _availableShares = _fraxlendPair.toAssetShares(_availableAmount,false);
        if (_shares <= _availableShares) {
            _amountWithdrawn = withdrawFromPair(_pairAddress, _shares);
        } else {
            _amountWithdrawn = withdrawFromPair(_pairAddress, _availableShares);
        }
    }
    
    /// @notice Function to withdraw FRAX from all FraxlendPair
    function withdrawMaxFromAllPairs() public onlyByOwnerOperator {
        address[] memory _pairsArray = pairsArray;
        for (uint256 i = 0; i < _pairsArray.length; i++) {
            withdrawMaxFromPair(_pairsArray[i]);
        }
    }

    /* ============================================ BORROWING FUNCTIONS ================================================= */

    /// @notice Function to deposit FRAX to specific FraxlendPair as collateral and borrow another token
    /// @param _pairAddress Address of FraxlendPair
    /// @param _fraxAmount Amount of FRAX to be deposited as collateral
    /// @param _borrowAmount Amount of asset to be borrowed
    function openBorrowPosition(
        address _pairAddress,
        uint256 _fraxAmount,
        uint256 _borrowAmount
    ) public approvedBorrowPair(_pairAddress) borrowOnBudget(_pairAddress) borrowOnLTV(_pairAddress) onlyByOwnerOperator {
        IFraxlendPair fraxlendPair = IFraxlendPair(_pairAddress);
        require(FRAX.balanceOf(address(this)) >= _fraxAmount, "AMO funds too low");
    
        FRAX.approve(_pairAddress, _fraxAmount);
        uint256 _shares = fraxlendPair.borrowAsset(_borrowAmount, _fraxAmount, address(this));
        borrowPairsCollateralFrax[_pairAddress] += _fraxAmount;

        emit AddCollateral(_pairAddress, _fraxAmount);
        emit BorrowFromPair(_pairAddress, _borrowAmount, _shares);
    }

    /// @notice Function to deposit FRAX to specific FraxlendPair as collateral
    /// @param _pairAddress Address of FraxlendPair
    /// @param _fraxAmount Amount of FRAX to be deposited as collateral
    function addCollateralToPair(
        address _pairAddress,
        uint256 _fraxAmount
    ) public approvedBorrowPair(_pairAddress) borrowOnBudget(_pairAddress) onlyByOwnerOperator {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        require(FRAX.balanceOf(address(this)) >= _fraxAmount, "AMO funds too low");
        emit AddCollateral(_pairAddress, _fraxAmount);

        FRAX.approve(_pairAddress, _fraxAmount);
        _fraxlendPair.addCollateral(_fraxAmount, address(this));
        borrowPairsCollateralFrax[_pairAddress] += _fraxAmount;
    }

    /// @notice Function to remove FRAX from specific FraxlendPair collateral
    /// @param _pairAddress Address of FraxlendPair
    /// @param _fraxAmount Amount of FRAX to be removed from collateral
    function removeCollateralFromPair(
        address _pairAddress,
        uint256 _fraxAmount
    ) public approvedBorrowPair(_pairAddress) borrowOnBudget(_pairAddress) borrowOnLTV(_pairAddress) onlyByOwnerOperator {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        require(borrowPairsCollateralFrax[_pairAddress] >= _fraxAmount, "AMO collateral too low");
        emit RemoveCollateral(_pairAddress, _fraxAmount);

        _fraxlendPair.removeCollateral(_fraxAmount, address(this));
        borrowPairsCollateralFrax[_pairAddress] -= _fraxAmount;
    }
    
    /// @notice Function to repay loan on FraxlendPair
    /// @param _pairAddress Address of FraxlendPair
    /// @param _shares The number of Borrow Shares which will be repaid by the call
    function repayBorrowPosition(
        address _pairAddress,
        uint256 _shares
    ) public approvedBorrowPair(_pairAddress) borrowOnBudget(_pairAddress) onlyByOwnerOperator {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        IERC20 _asset = IERC20(_fraxlendPair.asset());
        _fraxlendPair.addInterest();
        uint256 _amount = _fraxlendPair.toBorrowAmount(_shares, true);
        _asset.approve(_pairAddress, _amount);
        uint256 _finalAmount = _fraxlendPair.repayAsset(_shares, address(this));

        emit RepayToPair(_pairAddress, _finalAmount, _shares);
    }
    
    /// @notice Function to repay loan on FraxlendPair
    /// @param _pairAddress Address of FraxlendPair
    /// @param _swapperAddress The address of the whitelisted swapper to use for token swaps
    /// @param _collateralToSwap The amount of Collateral Tokens to swap for Asset Tokens
    /// @param _amountAssetOutMin The minimum amount of Asset Tokens to receive during the swap
    /// @param _path An array containing the addresses of ERC20 tokens to swap.  Adheres to UniV2 style path params.
    function repayBorrowPositionWithCollateral(
        address _pairAddress,
        address _swapperAddress,
        uint256 _collateralToSwap,
        uint256 _amountAssetOutMin,
        address[] calldata _path
    ) public approvedBorrowPair(_pairAddress) borrowOnBudget(_pairAddress) onlyByOwnerOperator returns (uint256 _amountAssetOut){
        IFraxlendPair _fraxlendPair = IFraxlendPair(_pairAddress);
        _amountAssetOut = _fraxlendPair.repayAssetWithCollateral(_swapperAddress, _collateralToSwap, _amountAssetOutMin, _path);
        uint256 _sharesOut = _fraxlendPair.toBorrowShares(_amountAssetOut, false);
        emit RepayToPair(_pairAddress, _amountAssetOut, _sharesOut);
    }

    /* ============================================ BURNS AND GIVEBACKS ================================================= */

    /// @notice Burn unneeded or excess FRAX. Goes through the minter
    /// @param _fraxAmount Amount of FRAX to burn
    function burnFRAX(uint256 _fraxAmount) public onlyOwner {
        FRAX.approve(address(amoMinter), _fraxAmount);
        amoMinter.burnFraxFromAMO(_fraxAmount);
    }

    /// @notice recoverERC20 recovering ERC20 tokens 
    /// @param _tokenAddress address of ERC20 token
    /// @param _tokenAmount amount to be withdrawn
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        SafeERC20.safeTransfer(token, msg.sender, _tokenAmount);
    }

    /* ====================================== RESTRICTED GOVERNANCE FUNCTIONS =========================================== */

    /// @notice Change the FRAX Minter
    /// @param _newAmoMinterAddress FRAX AMO minter
    function setAMOMinter(address _newAmoMinterAddress) external onlyOwner {
        emit SetAMOMinter(address(amoMinter), _newAmoMinterAddress);
        amoMinter = IFraxAMOMinter(_newAmoMinterAddress);
    }

    /// @notice Change the FraxlendPairHelper
    /// @param _newFraxlendPairHelperAddress FraxlendPairHelper Address
    function setFraxlendPairHelper(address _newFraxlendPairHelperAddress) external onlyOwner {
        emit SetFraxlendPairHelper(address(fraxlendPairHelper), _newFraxlendPairHelperAddress);
        fraxlendPairHelper = IFraxlendPairHelper(_newFraxlendPairHelperAddress);

    }

    /// @notice Change the FraxlendDeployer
    /// @param _newFraxlendPairDeployerAddress FRAX AMO minter
    function setFraxlendPairDeployer(address _newFraxlendPairDeployerAddress) external onlyOwner {
        emit SetFraxlendPairDeployer(address(fraxlendPairDeployer), _newFraxlendPairDeployerAddress);
        fraxlendPairDeployer = IFraxlendPairDeployer(_newFraxlendPairDeployerAddress);
    }


    /// @notice Change the Operator address
    /// @param _newOperatorAddress Operator address
    function setOperatorAddress(address _newOperatorAddress) external onlyOwner {
        emit SetOperator(operatorAddress, _newOperatorAddress);
        operatorAddress = _newOperatorAddress;
    }

    // Generic proxy
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{ value: _value }(_data);
        return (success, result);
    }
}