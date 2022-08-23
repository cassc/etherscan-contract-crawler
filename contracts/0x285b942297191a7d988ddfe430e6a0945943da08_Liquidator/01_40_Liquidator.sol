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
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./uniV3/CallbackValidation.sol";

//Balancer
import "./balancer/IVault.sol";
import "./balancer/IFlashLoanRecipient.sol";

//Cap Token
import "./cappedToken/ICappedGovToken.sol";
import "./cappedToken/IVotingVaultController.sol";

contract Liquidator is
    IUniswapV2Callee,
    FlashLoanReceiverBase,
    IUniswapV3FlashCallback,
    IFlashLoanRecipient
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
    ///@param tokenBorrow - will be USDC unless borrowing USDi on Uni V2
    ///@param assetLiquidated - which asset ws liquidated and then sold for USDC
    ///@param amountBorrow - e6 terms for USDC, e18 for USDi
    ///@param amountRepaid - Should be @param amountBorrow + fee unless Balancer
    event FlashLiquidate(
        string method,
        address tokenBorrow,
        uint96 vault,
        address assetLiquidated,
        uint256 amountBorrow,
        uint256 amountRepaid
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
    }

    ///@notice sets the oracle to Interest Protocol"s oracle master, call this if the oracle changes
    function setOracle() public {
        oracle = IOracleMaster(CONTROLLER.getOracleMaster());
    }

    ///@notice about how much USDC is needed to liq completely
    ///@param vault - which vault to liq
    ///@param asset - which asset in @param vault to liq
    ///@return amount - amount to borrow in USDC terms 1e6
    ///@notice it is cheaper in gas to read this first and then pass to the liq function after (~855k vs ~1MM gas for Aave)
    function calculateCost(uint96 vault, address asset)
        external
        view
        returns (uint256 amount)
    {
        //tokens to liquidate
        uint256 t2l = CONTROLLER.tokensToLiquidate(vault, asset);

        ///@notice need to take into account the liquidation incentive, or we will over borrow by that amount, resulting in a higher fee for the flash loan
        uint256 adjustedPrice = truncate(
            oracle.getLivePrice(asset) *
                (1e18 - CONTROLLER._tokenAddress_liquidationIncentive(asset))
        );
        amount = ((truncate((adjustedPrice + 1e18) * t2l)) / 1e12);
    }

    /***************BALANCER FLASH LOANS**************************/
    ///@notice init a flash loan on balancer
    ///@param params - struct of input params - see FlashParams
    function balancerFlashLiquidate(FlashParams memory params) external {
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
        getUSDC(
            decoded.asset,
            IERC20(decoded.asset).balanceOf(address(this)),
            decoded.cappedToken
        );

        //convert any remianing USDI back to USDC to repay
        USDI.withdrawAll();

        //calcualte amount owed, balancer will calculate the fee
        uint256 amountOwed = amounts[0] + feeAmounts[0];

        //emit event - could remove to save ~3k gas
        emit FlashLiquidate(
            "receiveFlashLoan",
            address(USDC),
            decoded.vault,
            decoded.asset,
            amounts[0],
            amountOwed
        );
        USDC.transfer(address(VAULT), amountOwed);
    }

    /***************UNI V3 FLASH LOANS**************************/
    ///@notice liquidate using USDC liquidity from the USDC/DAI pool at 100 fee
    ///@param params - struct of input params - see FlashParams
    function uniV3FlashLiquidate(FlashParams memory params) external {
        //check how much gas has been sent at the start of the tx
        uint256 startGas = gasleft();

        //USDC/DAI pool at 100 fee - this is the lowest fee for borrowing USDC
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
        getUSDC(
            decoded.asset,
            IERC20(decoded.asset).balanceOf(address(this)),
            decoded.cappedToken
        );

        //convert any remianing USDI back to USDC to repay
        USDI.withdrawAll();

        //calcualte amount owed, the pool will conveniently tell us the fee
        uint256 amountOwed = decoded.amount + fee1;

        //emit event - could remove to save ~3k gas
        emit FlashLiquidate(
            "uniswapV3FlashCallback",
            address(USDC),
            decoded.vault,
            decoded.asset,
            decoded.amount,
            amountOwed
        );
        //repay flash loan - msg.sender is the DAI/USDC 1 bip pool as confirmed above
        USDC.transfer(msg.sender, amountOwed);
    }

    /***************AAVE FLASH LOANS**************************/
    ///@notice liquidate using a flash loan from aave
    ///@param params - struct of input params - see FlashParams
    function aaveFlashLiquidate(FlashParams memory params) external {
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
        address /**initiator */, //not used
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
        getUSDC(
            decoded.asset,
            IERC20(decoded.asset).balanceOf(address(this)),
            decoded.cappedToken
        );

        //convert any remianing USDI back to USDC to repay
        //USDI.approve(address(USDI), USDC.balanceOf(initiator));
        USDI.withdrawAll();

        //calculate amount owed
        uint256 amountOwing = amounts[0] + (premiums[0]);

        //emit event - could remove to save ~3k gas
        emit FlashLiquidate(
            "executeOperation",
            address(USDC),
            decoded.vault,
            decoded.asset,
            amounts[0],
            amountOwing
        );

        //approve aave to take from this contract to repay
        USDC.approve(address(LENDING_POOL), amountOwing);
        return true;
    }

    /***************UNI V2 FLASH LOANS**************************/
    ///@notice liquidate vault
    ///@param tokenBorrow - USDI to borrow USDI and be paid in USDI, USDC to borrow USDC and be paid in USDC

    function uniV2FlashLiquidate(address tokenBorrow, FlashParams memory params)
        external
    {
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
                //transfer USDC to msg.sender
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
            getUSDC(asset, IERC20(asset).balanceOf(address(this)), cappedToken);

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
            getUSDC(asset, IERC20(asset).balanceOf(address(this)), cappedToken);

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

        //emit event - could remove to save ~3k gas
        emit FlashLiquidate(
            "uniswapV2Call",
            token0,
            vault,
            asset,
            amount,
            amountToRepay
        );

        //repay + fee
        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }

    /***************HELPER FUNCS**************************/
    ///@notice - internal function to perform the liquidation on Interest Protocol
    ///@param vault - which vault to liq
    ///@param asset - which asset in @param vault to liq
    function liquidate(uint96 vault, address asset) internal {
        require(!CONTROLLER.checkVault(vault), "Vault is solvent");

        IVaultController(address(CONTROLLER)).liquidateVault(
            vault,
            asset,
            2**256 - 1 //liquidate maximum
        );
    }

    ///@notice convert collateral liquidated to USDC on Uniswap V3
    ///@param asset - convert this asset to USDC
    ///@param amount - convert this amount of @param asset into USDC
    ///@param capToken - bool flag to determine if @param asset is a cap token
    function getUSDC(
        address asset,
        uint256 amount,
        bool capToken
    ) internal {
        if (capToken) {
            getUSDCforCapToken(
                asset,
                IERC20(VVC._CappedToken_underlying(asset)).balanceOf(
                    address(this)
                )
            );
        } else {
            getUSDC(asset, amount);
        }
    }

    ///@notice convert collateral liquidated to USDC on Uniswap V3
    ///@notice Because using V2 flashSwap places a lock on the pair, we can"t use that pair to sell the asset again in the same TX, hence V3
    ///@param asset - convert this asset to USDC
    ///@param amount - convert this amount of @param asset into USDC
    function getUSDC(address asset, uint256 amount) internal {
        IERC20(asset).approve(address(ROUTERV3), amount);
        ROUTERV3.exactInputSingle(
            ISwapRouter.ExactInputSingleParams(
                asset,
                address(USDC),
                500,
                address(this),
                block.timestamp + 10,
                amount,
                0,
                0
            )
        );
    }

    ///@notice For cap tokens, we need to sell the underlying for USDC rather than the asset we are passed
    ///@param capToken - address for the cap token, the asset we received from liquidation is not this, but the underlying
    ///@param amount - convert this amount of the underlying asset of @param asset into USDC
    function getUSDCforCapToken(address capToken, uint256 amount) internal {
        //get underlying asset
        address asset = VVC._CappedToken_underlying(capToken);

        IERC20(asset).approve(address(ROUTERV3), amount);
        ROUTERV3.exactInputSingle(
            ISwapRouter.ExactInputSingleParams(
                asset,
                address(USDC),
                3000, //higher fee tier for cap tokens, less liquidity
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

    ///@notice ensure the gas cost does not exceed revenue so tx is always profitable
    ///@param startGas - gas available at the start of the tx
    ///@param revenue - in USDI terms, dollars e18
    function checkGas(uint256 startGas, uint256 revenue) internal view {
        uint256 txCost = (oracle.getLivePrice(WETH) *
            (startGas - gasleft()) *
            tx.gasprice) / 1e18;

        require(int256(revenue) - int256(txCost) > 0, "Gas cost too high");
    }

    function truncate(uint256 u) internal pure returns (uint256) {
        return u / 1e18;
    }
}