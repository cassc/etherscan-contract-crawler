//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

//Interest Protocol
import "./interfaces/IVaultController.sol";
import "./interfaces/IUSDI.sol";
import "./interfaces/IOracleMaster.sol";

//Aave
import "./aave/FlashLoanReceiverBase.sol";

//Uniswap V2
import "./interfaces/IUniswapV2Callee.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";

//Uniswap V3
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./uniV3/CallbackValidation.sol";
import "./uniV3/TickMath.sol";

//Balancer
import "./balancer/IVault.sol";
import "./balancer/IFlashLoanRecipient.sol";

//Cap Token
import "./cappedToken/ICappedGovToken.sol";
import "./cappedToken/IVotingVaultController.sol";

//chainlink automation
import "./chainlink/AutomationCompatible.sol";

//OZ
import "@openzeppelin/contracts/access/Ownable.sol";

contract Liquidator is
    Ownable,
    IUniswapV2Callee,
    FlashLoanReceiverBase,
    IUniswapV3SwapCallback,
    IUniswapV3FlashCallback,
    IFlashLoanRecipient,
    AutomationCompatibleInterface
{
    IVaultController public constant CONTROLLER =
        IVaultController(0x4aaE9823Fb4C70490F1d802fC697F3ffF8D5CbE3);

    IUSDI public constant USDI =
        IUSDI(0x2A54bA2964C8Cd459Dc568853F79813a60761B58);

    IUniswapV2Factory public constant FACTORY_V2 =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    ISwapRouter public constant ROUTERV3 =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IUniswapV3Factory public constant FACTORY_V3 =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    //Balancer Vault
    IVault public constant VAULT =
        IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    IVotingVaultController public constant VVC =
        IVotingVaultController(0xaE49ddCA05Fe891c6a5492ED52d739eC1328CBE2);

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IOracleMaster public oracle;

    AutomationParams public automationParams;

    ///@notice a small buffer is needed to account for errors in calculation
    uint256 public costBuffer;

    mapping(address => address) public asset_pool;

    //pre register asset fee
    mapping(address => uint24) public asset_fee;

    enum LiquidationFunction {
        BALANCER,
        AAVE,
        UNIV3,
        UNIV2,
        UNIV2_USDC,
        V3_FLASHSWAP
    }

    struct AutomationParams {
        LiquidationFunction preferredFunction;
        bool profitCheck;
        bool flashSwap;
        uint240 threshold;
    }

    ///@param amount - USDC amount to borrow
    ///@param vault - vault to liquidate
    ///@param asset - asset to liquidate
    ///@param profitCheck - optional check to compare profit to gas cost
    struct FlashParams {
        uint256 amount;
        uint80 vault;
        address asset;
        bool profitCheck;
        bool cappedToken;
    }

    ///@notice data we expect to be returned from the lender
    ///@param amount - USDC amount to borrow
    ///@param vault - vault to liquidate
    ///@param asset - asset to liquidate
    struct FlashCallbackData {
        uint256 amount;
        uint88 vault;
        address asset;
        bool cappedToken;
    }

    ///@notice data we expect to be returned from the lender
    ///@param vault - vault to liquidate
    ///@param asset - asset to liquidate
    struct SimpleCallbackData {
        uint88 vault;
        address asset;
        bool cappedToken;
    }
    struct FlashSwapCallbackData {
        uint96 vault;
        address asset;
        bool cappedToken;
        bytes path;
    }

    /// @notice The identifying key of the pool
    ///@param token0 - Should be DAI in the V3 pool
    ///@param token1 - Should be USDC in the V3 pool
    ///@param fee - should be 100 or 1 bip
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    ///@notice event for each flash liquidation
    ///@param method - Which callback function was called to perform the flash loan
    ///@param assetLiquidated - which asset ws liquidated, will be cap token if capped
    event FlashLiquidate(
        LiquidationFunction method,
        uint96 vault,
        address assetLiquidated
    );

    ///@notice pass in LendingPoolAddressesProvider address to FlashLoanReceiverBase constructor
    constructor()
        FlashLoanReceiverBase(
            ILendingPoolAddressesProvider(
                0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
            )
        )
    {
        setOracle();
        automationParams.preferredFunction = LiquidationFunction.BALANCER;
        automationParams.profitCheck = false;
        automationParams.threshold = 50e18;

        costBuffer = 200;
    }

    ///@notice sets the oracle to Interest Protocol"s oracle master, call this if the oracle changes
    function setOracle() public {
        oracle = IOracleMaster(CONTROLLER.getOracleMaster());
    }

    ///@notice set the function that will be used by automated liquidations
    function setAutomationParams(AutomationParams calldata params)
        external
        onlyOwner
    {
        automationParams = params;
    }

    ///@notice admin can register a pool to utilize flash swaps
    ///@param _asset should be the capToken address if the asset is capped
    ///@param _poolAddress should be a direct USDC/asset pool, with asset being the underlying asset if cap token
    function registerPool(address _asset, address _poolAddress)
        external
        onlyOwner
    {
        asset_pool[_asset] = _poolAddress;
    }

    ///@notice register a fee if the default is not working
    ///@notice default is 500 for non cap token, and 3000 for cap token
    ///@param fee can be 100, 500, 3000, or 10000
    function registerFee(address asset, uint24 fee) external onlyOwner {
        asset_fee[asset] = fee;
    }

    ///@notice adjust the buffer in calculate cost
    ///@param _buffer is in terms / 1000000
    ///@param _buffer = 200 = 200 / 1000000 == 0.0002
    function setCostBuffer(uint256 _buffer) external onlyOwner {
        costBuffer = _buffer;
    }

    ///@notice remove dust from contract
    ///~0.000001 USDi should accumulate per automated liquidation
    function sweep(
        address asset,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        IERC20(asset).transfer(recipient, amount);
    }

    ///@notice about how much USDC is needed to liq completely
    ///@param vault - which vault to liq
    ///@param asset - which asset in @param vault to liq
    ///@return amount - amount to borrow in USDC terms 1e6
    ///@notice it is cheaper in gas to read this first and then pass to the liq function after (~855k vs ~1MM gas for Aave)
    function calculateCost(uint96 vault, address asset)
        public
        view
        returns (uint256 amount)
    {
        //tokens to liquidate
        uint256 t2l = CONTROLLER.tokensToLiquidate(vault, asset);
        uint256 assetValue = getAssetValue(asset, t2l);

        amount =
            truncate(
                assetValue *
                    (1e18 -
                        CONTROLLER._tokenAddress_liquidationIncentive(asset))
            ) /
            1e12;

        //perhaps line 284 of USDI should be set to >=
        //require(_gonBalances[target] > (amount * _gonsPerFragment), "USDI: not enough balance");
        amount += applyBuffer(amount, costBuffer);
    }

    /***************CHAINLINK AUTOMATION**************************/
    ///@notice check if a vault needs to be liquidated
    ///@return upkeepNeeded bool result to perform upkeep
    ///@return performData flashParam encoded data to perform the liquidation
    function checkUpkeep(
        bytes calldata /**checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint96 vaultCount = CONTROLLER.vaultsMinted();

        uint96 vaultID = 0;

        for (uint96 i = 1; i <= vaultCount; i++) {
            if (!CONTROLLER.checkVault(i)) {
                if (
                    (automationParams.threshold <
                        CONTROLLER.amountToSolvency(i))
                ) {
                    vaultID = i;
                    break;
                }
            }
        }

        if (vaultID == 0) {
            return (false, "0x");
        } else {
            upkeepNeeded = true;

            //vault sumary of vaultID
            IVaultController.VaultSummary memory summary = CONTROLLER
                .vaultSummaries(vaultID, vaultID)[0];

            //get asset value of each asset in vault, and determine the most lucrative one? Or the one with the most value
            address assetToLiq;
            uint256 maxValue = 0;
            for (uint256 i = 0; i < summary.tokenAddresses.length; i++) {
                uint256 assetValue = getAssetValue(
                    summary.tokenAddresses[i],
                    summary.tokenBalances[i]
                );
                if (assetValue > maxValue) {
                    maxValue == assetValue;
                    assetToLiq = summary.tokenAddresses[i];
                }
            }

            //if a vault has 0 assets but still has liability - bad debt
            //see vault 65 @ block 16192950
            if (assetToLiq == address(0x0)) {
                return (false, "0x");
            }

            performData = abi.encode(
                FlashParams({
                    amount: calculateCost(vaultID, assetToLiq),
                    vault: uint80(vaultID),
                    asset: assetToLiq,
                    profitCheck: automationParams.profitCheck,
                    cappedToken: (VVC._CappedToken_underlying(assetToLiq) !=
                        address(0x0))
                })
            );
        }
    }

    ///@notice perform liquidation via chainlink automation
    ///@notice uses state global varriable automationParams to determine params contract method for flash loans
    ///@param performData should be abi encoded flashParams provided by checkUpkeep()
    function performUpkeep(bytes calldata performData) external override {
        FlashParams memory params = abi.decode(performData, (FlashParams));

        //if we are allowed to flashSwap and there is a registered pool for the asset
        if (
            asset_pool[params.asset] != address(0x0) &&
            automationParams.flashSwap
        ) {
            //do the flash swap, otherwise, use prefferred function
            _flashSwapLiquidate(params);
        } else if (
            automationParams.preferredFunction == LiquidationFunction.BALANCER
        ) {
            _balFlashLiq(params);
        } else if (
            automationParams.preferredFunction == LiquidationFunction.AAVE
        ) {
            _aaveFlashLiquidate(params);
        } else if (
            automationParams.preferredFunction == LiquidationFunction.UNIV3
        ) {
            _uniV3FlashLiquidate(params);
        } else if (
            automationParams.preferredFunction == LiquidationFunction.UNIV2
        ) {
            _uniV2FlashLiquidate(address(USDI), params);
        } else {
            _uniV2FlashLiquidate(address(USDC), params);
        }
    }

    /***************UNI V3 FLASH SWAP**************************/
    function flashSwapLiquidate(FlashParams calldata params) external {
        _flashSwapLiquidate(params);
    }

    ///@notice we always borrow USDC and repay with underlying asset from the vault
    function _flashSwapLiquidate(FlashParams memory params) internal {
        //check how much gas has been sent at the start of the tx
        uint256 startGas = gasleft();

        IUniswapV3Pool pool = IUniswapV3Pool(asset_pool[params.asset]);
        bytes memory pathData = abi.encode(
            pool.token0(),
            pool.fee(),
            pool.token1()
        );

        //if zeroForOne is true, I give token 0 (USDC) for asset
        bool zeroForOne = (pool.token0() != address(USDC));

        pool.swap(
            address(this),
            zeroForOne,
            -int256(params.amount),
            (
                zeroForOne
                    ? TickMath.MIN_SQRT_RATIO + 1
                    : TickMath.MAX_SQRT_RATIO - 1
            ),
            abi.encode(
                FlashSwapCallbackData({
                    path: pathData,
                    vault: params.vault,
                    asset: params.asset,
                    cappedToken: params.cappedToken
                })
            )
        );

        //gather balances, we should have underlying asset + some USDI dust
        address underlying = pool.token0();
        if (pool.token0() == address(USDC)) {
            underlying = pool.token1();
        }

        //profit is in tokens
        uint256 tokenRevenue = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).transfer(msg.sender, tokenRevenue);

        //optional profit check - happens last to include cost to transfer revenue to user
        if (params.profitCheck) {
            checkGas(startGas, getAssetValue(underlying, tokenRevenue));
        }
    }

    ///@notice V3 pool calls this after we call swap
    ///@notice we receive USDC and return the asset after liquidation
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        FlashSwapCallbackData memory data = abi.decode(
            _data,
            (FlashSwapCallbackData)
        );
        (address token0, uint88 fee, address token1) = abi.decode(
            data.path,
            (address, uint88, address)
        );

        (bool isExactInput, uint256 amountToPay) = amount0Delta > 0
            ? (token0 < token1, uint256(amount0Delta))
            : (token1 < token0, uint256(amount1Delta));

        address repayToken = token0;
        if (token0 == address(USDC)) {
            repayToken = token1;
        }

        //verify that this function is only called by the correct V3 Pool
        CallbackValidation.verifyCallback(
            address(FACTORY_V3),
            PoolAddress.PoolKey({
                token0: token0,
                token1: token1,
                fee: uint24(fee)
            })
        );

        //convert all USDC borrowed into USDI to use in liquidation
        getUSDI();

        //do the liquidation
        liquidate(data.vault, data.asset);

        //emit event - could remove to save ~3k gas
        emit FlashLiquidate(
            LiquidationFunction.V3_FLASHSWAP,
            data.vault,
            data.asset
        );

        //repay
        IERC20(repayToken).transfer(msg.sender, amountToPay);
    } //uniswapV3SwapCallback

    /***************BALANCER FLASH LOANS**************************/
    function balancerFlashLiquidate(FlashParams calldata params) external {
        _balFlashLiq(params);
    }

    ///@notice init a flash loan on balancer
    ///@param params - struct of input params - see FlashParams
    function _balFlashLiq(FlashParams memory params) internal {
        //check how much gas has been sent at the start of the tx
        uint256 startGas = gasleft();

        //Balancer expects an array, even though we are only going to pass 1
        IERC20[] memory assets = new IERC20[](1);
        assets[0] = USDC;

        //Balancer expects an array, even though we are only going to pass 1
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = params.amount;

        VAULT.flashLoan(
            IFlashLoanRecipient(address(this)),
            assets,
            amounts,
            abi.encode(
                SimpleCallbackData({
                    vault: params.vault,
                    asset: params.asset,
                    cappedToken: params.cappedToken
                })
            )
        );

        if (params.profitCheck) {
            //store revenue
            uint256 revenue = USDC.balanceOf(address(this)) * 1e12;

            //transfer USDC to msg.sender
            USDC.transfer(msg.sender, USDC.balanceOf(address(this)));

            //optional profit check - happens last to include cost to transfer revenue to user
            checkGas(startGas, revenue);
        } else {
            //transfer USDC to msg.sender
            USDC.transfer(msg.sender, USDC.balanceOf(address(this)));
        }
    }

    ///@notice Balancer vault calls this after we call flashloan
    ///@param amounts - always length 1 and equal to borrow amount (USDC terms)
    ///@param feeAmounts - fee amount for the flash loan, add to borrowed amount
    ///@param userData - FlashCallbackData
    function receiveFlashLoan(
        IERC20[] memory, /**tokens*/
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        require(msg.sender == address(VAULT), "msg.sender != vault");

        //decode data passed from uniV3FlashLiquidate()
        SimpleCallbackData memory decoded = abi.decode(
            userData,
            (SimpleCallbackData)
        );
        //convert all USDC borrowed into USDI to use in liquidation
        getUSDI();

        //do the liquidation
        liquidate(decoded.vault, decoded.asset);

        //convert all of asset to USDC to repay
        getUSDC(decoded.asset, decoded.cappedToken);

        //convert any remianing USDI back to USDC to repay
        USDI.withdrawAll();

        //calcualte amount owed, balancer will calculate the fee
        uint256 amountOwed = amounts[0] + feeAmounts[0];

        //emit event - could remove to save ~3k gas
        emit FlashLiquidate(
            LiquidationFunction.BALANCER,
            decoded.vault,
            decoded.asset
        );
        USDC.transfer(address(VAULT), amountOwed);
    }

    /***************UNI V3 FLASH LOANS**************************/
    ///@notice liquidate using USDC liquidity from the USDC/DAI pool at 100 fee
    ///@param params - struct of input params - see FlashParams
    function uniV3FlashLiquidate(FlashParams calldata params) external {
        _uniV3FlashLiquidate(params);
    }

    function _uniV3FlashLiquidate(FlashParams memory params) internal {
        //check how much gas has been sent at the start of the tx
        uint256 startGas = gasleft();

        //USDC/DAI pool at 100 fee - this is the lowest fee for borrowing USDC from a uni v3 pool
        IUniswapV3Pool pool = IUniswapV3Pool(
            0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168 ///@notice pool address hard coded for reduced gas
        );

        //initiate the flashloan
        pool.flash(
            address(this), //Send borrowed tokens here
            0, //borrow 0 DAI
            params.amount, //borrow some amount of USDC
            abi.encode( //encode data to pass to uniswapV3FlashCallback
                FlashCallbackData({
                    amount: params.amount,
                    vault: params.vault,
                    asset: params.asset,
                    cappedToken: params.cappedToken
                })
            )
        );

        //calculate revenue in USDC terms
        uint256 revenue = USDC.balanceOf(address(this)) * 1e12;

        //send revenue to user
        USDC.transfer(msg.sender, USDC.balanceOf(address(this)));

        //optional profit check - happens last to include cost to transfer revenue to user
        if (params.profitCheck) {
            checkGas(startGas, revenue);
        }
    }

    ///@notice Uni V3 pool calls this after we call flash()
    ///@param fee1 - how  much to repay token 1 (USDC)
    ///@param data - FlashCallbackData
    function uniswapV3FlashCallback(
        uint256, /**fee0*/
        uint256 fee1,
        bytes calldata data
    ) external override {
        //decode data passed from uniV3FlashLiquidate()
        FlashCallbackData memory decoded = abi.decode(
            data,
            (FlashCallbackData)
        );

        //verify that this function is only called by the correct V3 Pool
        CallbackValidation.verifyCallback(
            address(FACTORY_V3),
            PoolAddress.PoolKey({
                token0: 0x6B175474E89094C44Da98b954EedeAC495271d0F, ///@notice DAI address hard coded to save gas, this is in reference to the USDC/DAI pool at 1BIP fee
                token1: address(USDC),
                fee: 100
            })
        );
        //convert all USDC borrowed into USDI to use in liquidation
        getUSDI();

        //do the liquidation
        liquidate(decoded.vault, decoded.asset);

        //convert all of asset to USDC to repay
        getUSDC(decoded.asset, decoded.cappedToken);

        //convert any remianing USDI back to USDC to repay
        USDI.withdrawAll();

        //calcualte amount owed, the pool will conveniently tell us the fee
        uint256 amountOwed = decoded.amount + fee1;

        //emit event - could remove to save ~3k gas
        emit FlashLiquidate(
            LiquidationFunction.UNIV3,
            decoded.vault,
            decoded.asset
        );
        //repay flash loan - msg.sender is the DAI/USDC 1 bip pool as confirmed above
        USDC.transfer(msg.sender, amountOwed);
    }

    /***************AAVE FLASH LOANS**************************/
    ///@notice liquidate using a flash loan from aave
    ///@param params - struct of input params - see FlashParams
    function aaveFlashLiquidate(FlashParams calldata params) external {
        _aaveFlashLiquidate(params);
    }

    function _aaveFlashLiquidate(FlashParams memory params) internal {
        //check how much gas has been sent at the start of the tx
        uint256 startGas = gasleft();

        //Aave expects an array, even though we are only going to pass 1
        address[] memory assets = new address[](1);
        assets[0] = address(USDC);

        //Aave expects an array, even though we are only going to pass 1
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = params.amount;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        //initiate the flash loan
        LENDING_POOL.flashLoan(
            address(this), //who receives flash loan
            assets, //borrowed assets, can be just 1
            amounts, //amounts to borrow
            modes, //what kind of loan - 0 for full repay
            address(this), //address to receive debt if mode is !0
            abi.encode( //extra data to pass abi.encode(...)
                SimpleCallbackData({
                    vault: params.vault,
                    asset: params.asset,
                    cappedToken: params.cappedToken
                })
            ),
            0 //referralCode - not used
        );

        if (params.profitCheck) {
            //store revenue
            uint256 revenue = USDC.balanceOf(address(this)) * 1e12;

            //transfer USDC to msg.sender, should not leave on here due to griefing attack https://ethereum.stackexchange.com/questions/92391/explain-griefing-attack-on-aave-flash-loan/92457#92457
            USDC.transfer(msg.sender, USDC.balanceOf(address(this)));

            //optional profit check - happens last to include cost to transfer revenue to user
            checkGas(startGas, revenue);
        } else {
            //transfer USDC to msg.sender
            USDC.transfer(msg.sender, USDC.balanceOf(address(this)));
        }
    }

    ///@notice aave calls this after we call flashloan() inside aaveFlashLiquidate()
    ///@param amounts - should always be length 1 and == USDC borrow amount
    ///@param premiums - should always be length 1 and == Fee amount to be added to repay amount
    ///@param params - FlashCallbackData
    function executeOperation(
        address[] calldata, /**assets*/
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address, /**initiator */ //not used
        bytes calldata params
    ) external override returns (bool) {
        SimpleCallbackData memory decoded = abi.decode(
            params,
            (SimpleCallbackData)
        );
        //convert all USDC borrowed into USDI to use in liquidation
        getUSDI();

        //do the liquidation
        liquidate(decoded.vault, decoded.asset);

        //convert all of asset to USDC to repay
        getUSDC(decoded.asset, decoded.cappedToken);

        //convert any remianing USDI back to USDC to repay
        USDI.withdrawAll();

        //calculate amount owed
        uint256 amountOwing = amounts[0] + (premiums[0]);

        //emit event - could remove to save ~3k gas
        emit FlashLiquidate(
            LiquidationFunction.AAVE,
            decoded.vault,
            decoded.asset
        );

        //approve aave to take from this contract to repay
        USDC.approve(address(LENDING_POOL), amountOwing);
        return true;
    }

    /***************UNI V2 FLASH LOANS**************************/
    ///@notice liquidate vault
    ///@param tokenBorrow - USDI to borrow USDI and be paid in USDI, USDC to borrow USDC and be paid in USDC
    function uniV2FlashLiquidate(
        address tokenBorrow,
        FlashParams calldata params
    ) external {
        _uniV2FlashLiquidate(tokenBorrow, params);
    }

    function _uniV2FlashLiquidate(
        address tokenBorrow,
        FlashParams memory params
    ) internal {
        uint256 startGas = gasleft();
        address pair = FACTORY_V2.getPair(tokenBorrow, params.asset);
        require(pair != address(0), "invalid pair");

        // scope for token{0,1}, avoids stack too deep errors
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        //Prepare data for the swap
        uint256 amount0Out = tokenBorrow == token0 ? params.amount : 0;
        uint256 amount1Out = tokenBorrow == token1 ? params.amount : 0;

        bytes memory data = abi.encode(
            tokenBorrow,
            params.amount,
            params.vault,
            params.asset,
            params.cappedToken
        );

        //perform flash swap
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data); //final arg determines if flash swap or normal swap, pass "" for normal swap

        if (tokenBorrow == address(USDI)) {
            if (params.profitCheck) {
                //store revenue
                uint256 revenue = USDI.balanceOf(address(this));

                //transfer USDi to msg.sender
                USDI.transfer(msg.sender, revenue);

                //optional profit check - happens last to include cost to transfer revenue to user
                checkGas(startGas, revenue);
            } else {
                //transfer USDI to msg.sender
                USDI.transfer(msg.sender, USDI.balanceOf(address(this)));
            }
        } else if (tokenBorrow == address(USDC)) {
            if (params.profitCheck) {
                //store revenue
                uint256 revenue = USDC.balanceOf(address(this)) * 1e12;

                //transfer USDC to msg.sender
                USDC.transfer(msg.sender, USDC.balanceOf(address(this)));

                //optional profit check - happens last to include cost to transfer revenue to user
                checkGas(startGas, revenue);
            } else {
                //transfer USDC to msg.sender
                USDC.transfer(msg.sender, USDC.balanceOf(address(this)));
            }
        }
    }

    ///@notice - The V2 pair we are borrowing from calls this after we call swap() in uniV2FlashLiquidate()
    ///@param sender - Who initiated the FlashSwap, should be this contract, there is a check for this below
    ///@param data - data we encoded in uniV2FlashLiquidate() is passed back to us here
    function uniswapV2Call(
        address sender,
        uint256, /**amount0*/
        uint256, /**amount1*/
        bytes calldata data
    ) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        address pair = FACTORY_V2.getPair(token0, token1);
        require(msg.sender == pair, "!pair");

        require(sender == address(this), "!sender");

        (
            address tokenBorrow,
            uint256 amount,
            uint96 vault,
            address asset,
            bool cappedToken
        ) = abi.decode(data, (address, uint256, uint96, address, bool));

        // ~~0.3% pool fee
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = amount + fee;

        if (tokenBorrow == address(USDI)) {
            //do the liquidation
            liquidate(vault, asset);

            //convert all of asset to USDC to repay
            getUSDC(asset, cappedToken);

            getUSDI();
            require(
                USDI.balanceOf(address(this)) > amountToRepay,
                "Insufficient repay"
            );
        } else if (tokenBorrow == address(USDC)) {
            getUSDI();

            //do the liquidation
            liquidate(vault, asset);

            //convert all of asset to USDC to repay
            getUSDC(asset, cappedToken);

            //convert any remianing USDI back to USDC to repay
            USDI.approve(address(USDI), USDC.balanceOf(address(this)));
            USDI.withdrawAll();

            require(
                USDC.balanceOf(address(this)) > amountToRepay,
                "Insufficient repay"
            );
        } else {
            revert("Unsupported borrow");
        }

        if (tokenBorrow == address(USDI)) {
            emit FlashLiquidate(LiquidationFunction.UNIV2, vault, asset);
        } else {
            emit FlashLiquidate(LiquidationFunction.UNIV2_USDC, vault, asset);
        }

        //repay + fee
        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }

    /***************HELPER FUNCTIONS**************************/
    ///@notice - internal function to perform the liquidation on Interest Protocol
    ///@param vault - which vault to liq
    ///@param asset - which asset in @param vault to liq
    function liquidate(uint96 vault, address asset) internal {
        require(!CONTROLLER.checkVault(vault), "Vault is solvent");

        CONTROLLER.liquidateVault(
            vault,
            asset,
            2**256 - 1 //liquidate maximum
        );
    }

    ///@notice convert collateral liquidated to USDC on Uniswap V3
    ///@param asset - convert this asset to USDC
    ///@param capToken - bool flag to determine if @param asset is a cap token
    function getUSDC(address asset, bool capToken) internal {
        uint24 fee = asset_fee[asset];
        if (fee == 0) {
            if (capToken) {
                fee = 3000;
                asset_fee[asset] = 3000;
            } else {
                fee = 500;
                asset_fee[asset] = 500;
            }
        }
        if (capToken) {
            asset = VVC._CappedToken_underlying(asset);
        }

        _getUSDC(asset, IERC20(asset).balanceOf(address(this)), fee);
    }

    ///@notice convert collateral liquidated to USDC on Uniswap V3
    ///@notice Because using V2 flashSwap places a lock on the pair, we can"t use that pair to sell the asset again in the same TX, hence V3
    ///@param asset - convert this asset to USDC
    ///@param amount - convert this amount of @param asset into USDC
    function _getUSDC(
        address asset,
        uint256 amount,
        uint24 fee
    ) internal {
        IERC20(asset).approve(address(ROUTERV3), amount);
        ROUTERV3.exactInputSingle(
            ISwapRouter.ExactInputSingleParams(
                asset,
                address(USDC),
                fee,
                address(this),
                block.timestamp + 10,
                amount,
                0,
                0
            )
        );
    }

    ///@notice converts all USDC held by this contract to USDI by depositing into the reserve of interest protocol
    function getUSDI() internal {
        uint256 amount = USDC.balanceOf(address(this));
        USDC.approve(address(USDI), amount);
        USDI.deposit(amount);
    }

    ///@notice determine the USDI value of an asset
    function getAssetValue(address asset, uint256 amount)
        internal
        view
        returns (uint256 usdi_value)
    {
        uint256 price = oracle.getLivePrice(asset);

        return ((price * amount) / 1e18);
    }

    ///@notice ensure the gas cost does not exceed revenue so tx is always profitable
    ///@param startGas - gas available at the start of the tx
    ///@param revenue - in USDI terms, dollars e18
    function checkGas(uint256 startGas, uint256 revenue) internal view {
        uint256 txCost = (oracle.getLivePrice(WETH) *
            (startGas - gasleft()) *
            tx.gasprice) / 1e18;

        require(int256(revenue) - int256(txCost) > 0, "Gas cost too high");
    }

    ///@notice buffer is in terms / 1000000
    function applyBuffer(uint256 _amount, uint256 buffer)
        internal
        pure
        returns (uint256 amount)
    {
        amount = (_amount * buffer) / 1000000;
    }

    function truncate(uint256 u) internal pure returns (uint256) {
        return u / 1e18;
    }
}