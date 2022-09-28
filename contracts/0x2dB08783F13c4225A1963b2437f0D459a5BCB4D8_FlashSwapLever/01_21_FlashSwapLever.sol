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

    //mapping of wallet address to vault IDs []
    mapping(address => uint96[]) public _wallet_vaultIDs;

    //mapping of vault ID to owner
    mapping(uint96 => address) public _vaultID_owner;

    struct SwapCallbackData {
        address asset;
        uint88 vault;
        bool leverUp;
        bytes path;
        address payer;
    }

    ///@param zeroForOne indicates which is token0/token1 with respect the lever up direction
    ///@param zeroForOne is true if token0 is USDC and token1 is asset - when levering up we swap token0(USDC) for token1(asset)
    ///@notice For increasing the position, @param amount is the USD amount to increase by in USDC terms
    ///@notice For decreasing the position, @param amount is the token amount of @param asset by which to decrease position
    ///@param poolAddress should be a USDC/@param asset Uniswap V3 Pool
    struct Params {
        address asset;
        bool zeroForOne;
        uint88 vaultID;
        uint256 amount;
        address poolAddress;
    }

    function getVaults() external view returns (uint96[] memory) {
        return _wallet_vaultIDs[msg.sender];
    }

    ///@notice mint a vault, multiple vaults allowed
    ///@notice All vaults minted will have this contract as the minter, so withdraw needs to happen here
    function mintVault() external {
        CONTROLLER.mintVault();
        uint96 vaultsMinted = CONTROLLER.vaultsMinted();
        _wallet_vaultIDs[msg.sender].push(vaultsMinted);
        _vaultID_owner[vaultsMinted] = msg.sender;
    }

    ///@notice clean up any dust or accidental transfers, there should not be any tokens held by this contract as a result of normal operation
    function sweep(address token, uint256 amount) public {
        IERC20(token).transfer(msg.sender, amount);
    }

    ///@notice Assets in levered vaults can still delegate
    function delegateCompLikeTo(
        uint96 vaultID,
        address compLikeDelegatee,
        address compLikeToken
    ) external {
        IVault vault = IVault(CONTROLLER.vaultAddress((vaultID)));
        require(_vaultID_owner[vaultID] == msg.sender, "not owner");

        vault.delegateCompLikeTo(compLikeDelegatee, compLikeToken);
    }

    ///@notice withdraw assets from the vault, liability allowing
    function withdraw(
        uint96 vaultID,
        address asset,
        uint256 amount
    ) external {
        IVault vault = IVault(CONTROLLER.vaultAddress((vaultID)));
        require(_vaultID_owner[vaultID] == msg.sender, "not owner");

        vault.withdrawErc20(asset, amount);
        IERC20(asset).transfer(msg.sender, amount);
    }

    ///@notice increase position
    ///@notice max position size (in USD terms) is roughly (1-Uniswap pool fee) * x / (1-LTV)
    ///The asset in @param params is in USDC terms, how much USDC value by which to increase your position
    function increasePosition(Params calldata params) external {
        IVault vault = IVault(CONTROLLER.vaultAddress((params.vaultID)));
        require(_vaultID_owner[params.vaultID] == msg.sender, "not owner");

        IUniswapV3Pool pool = IUniswapV3Pool(params.poolAddress);

        ///@notice token0 is USDC, token1 is WETH, we are swapping USDC (borrowed from IP) for ETH (from the pool) so zeroForOne is true
        bytes memory pathData = abi.encode(
            pool.token0(),
            pool.fee(),
            pool.token1()
        );

        pool.swap(
            address(vault), //send tokens directly to vault, increasing borrowing power and saving us a transfer in gas
            params.zeroForOne,
            int256(params.amount), //amount specified
            (
                params.zeroForOne
                    ? TickMath.MIN_SQRT_RATIO + 1
                    : TickMath.MAX_SQRT_RATIO - 1
            ),
            abi.encode(
                SwapCallbackData({
                    path: pathData,
                    payer: msg.sender,
                    asset: params.asset,
                    vault: uint80(params.vaultID),
                    leverUp: true
                })
            )
        );
    }

    ///@notice close out entire position
    ///@notice this will send a small amount of USDi dust to the caller
    ///@notice the amount in @param params is not used
    function closeOutPosition(Params calldata params) external {
        uint192 liability = CONTROLLER.vaultLiability(params.vaultID);
        uint256 assetPrice = ORACLE.getLivePrice(params.asset);
        uint256 assetsOwed = (liability * 1e18) / (assetPrice);
        IUniswapV3Pool pool = IUniswapV3Pool(params.poolAddress);

        _leverDown(
            params.zeroForOne,
            params.vaultID,
            params.asset,
            assetsOwed,
            pool
        );
    }

    ///@notice reduce position
    ///@notice the amount in @param params is in terms of the asset, how many tokens of asset by which to reduce position
    function decreasePosition(Params calldata params) external {
        IUniswapV3Pool pool = IUniswapV3Pool(params.poolAddress);

        _leverDown(
            params.zeroForOne,
            params.vaultID,
            params.asset,
            params.amount,
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
        ///NOTE must verify callback for security, not currently implemented
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