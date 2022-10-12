// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//Interest Protocol
import "./InterestProtocol/IVaultController.sol";
import "./InterestProtocol/IUSDI.sol";
import "./InterestProtocol/IVault.sol";
import "./InterestProtocol/IOracleMaster.sol";

//Uniswap V3
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./uniV3/CallbackValidation.sol";
import "./uniV3/TickMath.sol";

/********************
 *   Use Interest Protocol to leverage your positions
 *   This uses efficient flash swaps on Uniswap V3
 *   Only assets that have a direct pair against USDC on Uniswap V3 will work
 *
 *   Made by Jake B @ GFX labs
 *   https://gfx.cafe/ip/leverage
 *
 ********************* */
contract FlashSwapLever is IUniswapV3SwapCallback {
    IVaultController public constant CONTROLLER =
        IVaultController(0x4aaE9823Fb4C70490F1d802fC697F3ffF8D5CbE3);

    IUSDI public constant USDI =
        IUSDI(0x2A54bA2964C8Cd459Dc568853F79813a60761B58);

    IOracleMaster public constant ORACLE =
        IOracleMaster(0xf4818813045E954f5Dc55a40c9B60Def0ba3D477);

    IUniswapV3Factory public constant FACTORY_V3 =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    //mapping of wallet address to vault ID - one vaultID per wallet
    mapping(address => uint96) public _wallet_vaultID;

    //mapping of vault ID to owner
    mapping(uint96 => address) public _vaultID_owner;

    struct SwapCallbackData {
        address asset;
        bool leverUp;
        uint88 vault;
        bytes path;
        address payer;
    }

    ///@notice For increasing the position, @param borrowAmount is the USD amount to increase by in USDC terms
    ///@notice For decreasing the position, @param borrowAmount is the token amount of @param collateralAsset by which to decrease position
    ///@param poolAddress should be a USDC/@param asset Uniswap V3 Pool
    ///@param fundAmount amount of @param collateralAsset to take from caller and send to @param vaultID to generate borrowing power
    ///@param zeroForOne indicates which is token0/token1 with respect the lever up direction
    ///@param zeroForOne is true if token0 is USDC and token1 is asset - when levering up we swap token0(USDC) for token1(asset)
    struct flashSwapParams {
        address collateralAsset;
        uint256 borrowAmount;
        uint256 fundAmount;
        address poolAddress;
        bool zeroForOne;
    }

    function getVault(address owner) public view returns (uint96) {
        return _wallet_vaultID[owner];
    }

    ///@notice mint a vault, multiple vaults allowed
    ///@notice All vaults minted will have this contract as the minter, so withdraw needs to happen here
    function mintVault() external {
        require(getVault(msg.sender) == 0, "Already minted");
        _mintVault(); //check for existing vault or allow multiple?
    }

    function _mintVault() internal {
        CONTROLLER.mintVault();
        uint96 vaultsMinted = CONTROLLER.vaultsMinted();
        _wallet_vaultID[msg.sender] = vaultsMinted;
        _vaultID_owner[vaultsMinted] = msg.sender;
    }

    ///@notice Assets in levered vaults can still delegate
    function delegateCompLikeTo(
        uint96 vaultID,
        address compLikeDelegatee,
        address compLikeToken
    ) external {
        require(_vaultID_owner[vaultID] == msg.sender, "not owner");
        IVault vault = IVault(CONTROLLER.vaultAddress((vaultID)));

        vault.delegateCompLikeTo(compLikeDelegatee, compLikeToken);
    }

    ///@notice withdraw assets from the vault, liability allowing
    function withdraw(
        uint96 vaultID,
        address asset,
        uint256 amount
    ) external {
        require(_vaultID_owner[vaultID] == msg.sender, "not owner");
        IVault vault = IVault(CONTROLLER.vaultAddress((vaultID)));

        vault.withdrawErc20(asset, amount);
        IERC20(asset).transfer(msg.sender, amount);
    }

    ///@notice this will both mint a vault if needed, and fund it if appropriate allowance is given
    ///@notice gas cost can be very high, but overall gas consumption is less when doing everything all at once
    ///fundAmount in @param params can be 0
    function checkBorrowState(flashSwapParams calldata params)
        internal
        returns (uint96 vaultID)
    {
        vaultID = _wallet_vaultID[msg.sender];

        if (vaultID == 0) {
            _mintVault();
            vaultID = _wallet_vaultID[msg.sender];
        }

        if (params.fundAmount > 0) {
            IERC20(params.collateralAsset).transferFrom(
                msg.sender,
                CONTROLLER.vaultAddress(vaultID),
                params.fundAmount
            );
        }
    }

    ///@notice increase position, this will mint a vault and fund it in the same TX if needed
    ///@notice fundAmount in @param params can be 0 if vault is already funded
    ///@notice max position size (in USD terms) is roughly (1-Uniswap pool fee) * x / (1-LTV)
    ///The borrowAmount in @param params is in USDC terms, how much USDC value by which to increase your position
    function increasePosition(flashSwapParams calldata params) external {
        uint96 vaultID = checkBorrowState(params);
        IUniswapV3Pool pool = IUniswapV3Pool(params.poolAddress);

        bytes memory pathData = abi.encode(
            pool.token0(),
            pool.fee(),
            pool.token1()
        );

        pool.swap(
            CONTROLLER.vaultAddress(vaultID), //send tokens directly to vault, increasing borrowing power and saving us a transfer in gas
            params.zeroForOne,
            int256(params.borrowAmount), //amount specified
            (
                params.zeroForOne
                    ? TickMath.MIN_SQRT_RATIO + 1
                    : TickMath.MAX_SQRT_RATIO - 1
            ),
            abi.encode(
                SwapCallbackData({
                    path: pathData,
                    payer: msg.sender,
                    asset: params.collateralAsset, //not used for lever up, pool deposits asset directly to the vault, so we only deal with borrowed USDC
                    vault: uint88(vaultID),
                    leverUp: true
                })
            )
        );
    }

    ///@notice close out entire position
    ///@notice this will send a small amount of USDi dust to the caller
    ///@notice the amount in @param params is not used
    function closeOutPosition(flashSwapParams calldata params) external {
        uint192 liability = CONTROLLER.vaultLiability(
            _wallet_vaultID[msg.sender]
        );
        uint256 assetPrice = ORACLE.getLivePrice(params.collateralAsset);
        uint256 assetsOwed = (liability * 1e18) / (assetPrice);
        IUniswapV3Pool pool = IUniswapV3Pool(params.poolAddress);

        _leverDown(
            params.zeroForOne,
            uint88(_wallet_vaultID[msg.sender]),
            params.collateralAsset,
            assetsOwed,
            pool
        );
    }

    ///@notice reduce position
    ///@notice the amount in @param params is in terms of the asset, how many tokens of asset by which to reduce position
    function decreasePosition(flashSwapParams calldata params) external {
        IUniswapV3Pool pool = IUniswapV3Pool(params.poolAddress);

        _leverDown(
            params.zeroForOne,
            uint88(_wallet_vaultID[msg.sender]),
            params.collateralAsset,
            params.borrowAmount,
            pool
        );
    }

    function _leverDown(
        bool zeroForOne,
        uint88 vaultID,
        address asset,
        uint256 amount,
        IUniswapV3Pool pool
    ) internal {
        require(_vaultID_owner[vaultID] == msg.sender, "not owner");

        bytes memory pathData = abi.encode(
            pool.token0(),
            pool.fee(),
            pool.token1()
        );

        pool.swap(
            address(this), //destination for tokens from the pool
            !zeroForOne, //opposite of normal zeroForOne as we are levering down, recieve USDC and return wETH
            int256(amount), //amount specified
            (
                !zeroForOne
                    ? TickMath.MIN_SQRT_RATIO + 1
                    : TickMath.MAX_SQRT_RATIO - 1
            ),
            abi.encode(
                SwapCallbackData({
                    path: pathData,
                    payer: msg.sender,
                    asset: asset,
                    vault: vaultID,
                    leverUp: false
                })
            )
        );
    }

    ///@notice pool calls this here after we swap
    ///@notice here we must do any logic and return the expected number of tokens to the pool
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (address token0, uint88 fee, address token1) = abi.decode(
            data.path,
            (address, uint88, address)
        );

        //verify that this function is only called by the correct V3 Pool
        CallbackValidation.verifyCallback(
            address(FACTORY_V3),
            PoolAddress.PoolKey({
                token0: token0,
                token1: token1,
                fee: uint24(fee)
            })
        );

        (bool isExactInput, uint256 amountToPay) = amount0Delta > 0
            ? (token0 < token1, uint256(amount0Delta))
            : (token1 < token0, uint256(amount1Delta));

        if (data.leverUp) {
            CONTROLLER.borrowUSDCto(
                data.vault,
                uint192(amountToPay),
                msg.sender //borrow USDC directly to the pool, saves a transfer in gas
            );
        } else {
            withdrawAsset(data.vault, data.asset, amountToPay);
        }
    }

    function withdrawAsset(
        uint96 vault,
        address asset,
        uint256 amountToPay
    ) internal {
        USDC.approve(address(USDI), USDC.balanceOf(address(this)));
        USDI.deposit(USDC.balanceOf(address(this)));

        uint256 usdiBal = USDI.balanceOf(address(this));

        uint192 liability = CONTROLLER.vaultLiability(vault);

        if (usdiBal > liability) {
            CONTROLLER.repayAllUSDi(vault);
            //send change to the vault owner
            USDI.transfer(_vaultID_owner[vault], USDI.balanceOf(address(this)));
        } else {
            //1 wei corner case
            CONTROLLER.repayUSDi(vault, uint192(usdiBal - 1));
        }

        IVault Vault = IVault(CONTROLLER.vaultAddress((vault)));
        Vault.withdrawErc20(asset, amountToPay);

        IERC20(asset).transfer(msg.sender, amountToPay);
    }
}