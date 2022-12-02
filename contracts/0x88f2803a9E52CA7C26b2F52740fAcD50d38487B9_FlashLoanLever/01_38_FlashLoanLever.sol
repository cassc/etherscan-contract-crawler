// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//Interest Protocol
import "./InterestProtocol/IVaultController.sol";
import "./InterestProtocol/IUSDI.sol";
import "./InterestProtocol/IVault.sol";
import "./InterestProtocol/IOracleMaster.sol";
import "./InterestProtocol/ICappedGovToken.sol";
import "./InterestProtocol/IVotingVaultController.sol";
import "./InterestProtocol/IVotingVault.sol";

//Uniswap V3
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./uniV3/CallbackValidation.sol";
import "./uniV3/TickMath.sol";

//Balancer
import "./balancer/IBalancerVault.sol";
import "./balancer/IFlashLoanRecipient.sol";

//Paraswap
import "./Paraswap/Utils.sol";
import "./Paraswap/IAugustusSwapper.sol";
import "./Paraswap/IParaswap.sol";

//OZ
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/****************************************
 *
 *   Utilize Interest Protocol and Balancer flash loans to leverage your positions
 *   Made by Jake B @ GFX labs
 *   https://gfx.cafe/ip/leverage
 *
 **************************************** */
contract FlashLoanLever is IFlashLoanRecipient {
    using SafeERC20 for IERC20;

    IVaultController public constant CONTROLLER =
        IVaultController(0x4aaE9823Fb4C70490F1d802fC697F3ffF8D5CbE3);

    IUSDI public constant USDI =
        IUSDI(0x2A54bA2964C8Cd459Dc568853F79813a60761B58);

    IOracleMaster public constant ORACLE =
        IOracleMaster(0xf4818813045E954f5Dc55a40c9B60Def0ba3D477);

    IVotingVaultController public constant VVC =
        IVotingVaultController(0xaE49ddCA05Fe891c6a5492ED52d739eC1328CBE2);

    IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    IBalancerVault public constant BALANCER_VAULT =
        IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    //give approval to this before executing aggregator TX
    address public immutable TOKEN_TRANSFER_PROXY =
        IAugustusSwapper(0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57)
            .getTokenTransferProxy();

    IParaswap public constant PARASWAP =
        IParaswap(0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57);

    //mapping of wallet address to its vault IDs - multiple allowed per wallet
    mapping(address => uint96[]) public _wallet_vaultID;
    //mapping of a single vault ID to its owner
    mapping(uint96 => address) public _vaultID_owner;

    //need to store data locally to support multiple contract methods
    Utils.SimpleData private _simpleData;

    Utils.SellData private _multiData;

    Utils.MegaSwapSellData private _megaData;

    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    event flashLoanLever(
        ContractMethod contractMethod,
        bool increasePosition,
        uint96 vault,
        address borrowedToken,
        uint256 borrowedAmount
    );

    ///@notice these are the supported contract methods from the aggregator
    enum ContractMethod {
        multiSwap,
        simpleSwap,
        swapOnUniswap,
        swapOnUniswapFork,
        swapOnUniswapV2Fork,
        megaSwap
    }

    ///@notice reference FlashParams.boolData
    enum whichBool {
        increasePosition,
        capToken
    }

    ///@notice use for swapOnUniswap and swapOnUniswapFork
    ///@param factory && @param initCode are not used for swapOnUniswap and should be set to null values
    struct uniData {
        address factory;
        bytes32 initCode;
        uint256 amountIn;
        uint256 amountOutMin;
        address[] path;
    }
    uniData private _uniData;

    ///@notice use for swapOnUniswapV2
    struct v2Data {
        address tokenIn;
        uint256 amountInMax;
        uint256 amountOut;
        address weth;
        uint256[] pools;
    }
    v2Data private _v2Data;

    ///@notice This data is encoded when we call flash, and we can decode it in the callback function
    struct flashCallbackData {
        address asset;
        uint96 vault;
        ContractMethod contractMethod;
        uint8 boolData;
        uint256 usdcBuffer;
        uint256 withdrawAmount;
    }

    /**
    @notice For increasing the position, @param borrowAmount is the token amount of @param collateralAsset by which to increase position
    @notice For decreasing the position, @param borrowAmount is the USD amount to decrease the liability by in USDC terms
    @param boolData - 0 => false,false, 1 => true,false, 2 => false,true, 3 => true,true
    @param fundAmount amount of @param collateralAsset to take from caller and send to @param vaultID to generate borrowing power
    @notice if @param fundAmount is not 0 && @param increasePosition is false, then we close and withdraw all assets to the vault owner
    @param increasePosition true for lever up - borrow asset, false for lever down - borrow USDC
    @param usdcBuffer is the USDC buffer for increasing position
    @param usdcBuffer is the withdraw buffer for decrease position, in percentage terms out of 1000 -- buffer = 900 => withdraw 90%
     */
    struct FlashParams {
        address collateralAsset;
        uint96 vaultID;
        uint8 boolData;
        uint256 borrowAmount;
        uint256 fundAmount;
        uint256 usdcBuffer;
    }

    ///@notice get all vaults minted by this contract owned by @param owner
    ///@notice multiple vaults can be owned by a single wallet
    function getVaults(address owner) public view returns (uint96[] memory) {
        return _wallet_vaultID[owner];
    }

    ///@notice mint both a vault and a voting vault, multiple vaults allowed per owner
    ///@notice All vaults minted will have this contract as the minter, so withdraw needs to happen here
    ///@notice Vaults minted by this function have msg.sender as the owner
    function mintVault() external {
        _mintVault();
    }

    ///@notice this mints both a standard and a voting vault, both are tied to the same ID
    function _mintVault() internal returns (uint96 vaultID) {
        CONTROLLER.mintVault();
        vaultID = CONTROLLER.vaultsMinted();
        VVC.mintVault(vaultID);
        _wallet_vaultID[msg.sender].push(vaultID);
        _vaultID_owner[vaultID] = msg.sender;
    }

    ///@notice clean up any dust or accidental transfers, there should not be any tokens held by this contract as a result of normal operation
    function sweep(address token, uint256 amount) public {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    ///@notice Assets in levered vaults can still delegate
    ///@param vaultID which vault to delegate from, votingVault ID is the same
    ///@param compLikeDelegatee - who to delegate to
    ///@param compLikeToken if capToken, this should be the cap token address, not underlying
    ///@param capToken bool flag
    function delegateCompLikeTo(
        uint96 vaultID,
        address compLikeDelegatee,
        address compLikeToken,
        bool capToken
    ) external {
        require(_vaultID_owner[vaultID] == msg.sender, "not owner");
        if (capToken) {
            IVotingVault vault = IVotingVault(
                VVC._vaultId_votingVaultAddress((vaultID))
            );
            vault.delegateCompLikeTo(compLikeDelegatee, compLikeToken);
        } else {
            IVault vault = IVault(CONTROLLER.vaultAddress((vaultID)));
            vault.delegateCompLikeTo(compLikeDelegatee, compLikeToken);
        }
    }

    ///@notice withdraw assets from the vault, liability allowing
    ///@param vaultID which vault to withdraw from
    ///@param asset to withdraw, if cap token, this should be the cap token address, not underlying
    ///@param capToken bool flag
    ///@param amount of tokens to withdraw
    function withdraw(
        uint88 vaultID,
        address asset,
        bool capToken,
        uint256 amount
    ) external {
        IVault vault = IVault(CONTROLLER.vaultAddress((vaultID)));
        require(_vaultID_owner[vaultID] == msg.sender, "not owner");

        vault.withdrawErc20(asset, amount);

        if (capToken) {
            asset = VVC._CappedToken_underlying(asset);
        }

        IERC20(asset).safeTransfer(msg.sender, amount);
    }

    /**
     * These external functions are the primary functionality of the lever contract
     * Each one will initate a flash loan, as well as borrow/repay assets via Interest Protocol
     * These function can modify the position in both the positive and negative direction
     */

    function modifyPositionSwapOnUniswapV2Fork(
        FlashParams calldata params,
        v2Data calldata data
    ) external noReentrant {
        _v2Data = v2Data({
            tokenIn: data.tokenIn,
            amountInMax: data.amountInMax,
            amountOut: data.amountOut,
            weth: data.weth,
            pools: data.pools
        });

        if (!getBoolean(params.boolData, whichBool.increasePosition)) {
            flash(params, ContractMethod.swapOnUniswapV2Fork, params.vaultID);
            return;
        }

        uint96 vaultID = params.vaultID;
        if (params.vaultID == 0) {
            vaultID = _mintVault();
        }
        if (params.fundAmount != 0) {
            fundVault(
                vaultID,
                params.collateralAsset,
                params.fundAmount,
                getBoolean(params.boolData, whichBool.capToken)
            );
        }

        flash(params, ContractMethod.swapOnUniswapV2Fork, vaultID);
    }

    function modifyPositionSwapOnUniswap(
        FlashParams calldata params,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external noReentrant {
        _uniData = uniData({
            factory: address(0x0), //used for v3 fork only
            initCode: 0x0, //used for v3 fork only
            amountIn: amountIn,
            amountOutMin: amountOutMin,
            path: path
        });

        if (!getBoolean(params.boolData, whichBool.increasePosition)) {
            flash(params, ContractMethod.swapOnUniswap, params.vaultID);
            return;
        }

        uint96 vaultID = params.vaultID;
        if (params.vaultID == 0) {
            vaultID = _mintVault();
        }
        if (params.fundAmount != 0) {
            fundVault(
                vaultID,
                params.collateralAsset,
                params.fundAmount,
                getBoolean(params.boolData, whichBool.capToken)
            );
        }

        flash(params, ContractMethod.swapOnUniswap, vaultID);
    }

    function modifyPositionSwapOnUniswapFork(
        FlashParams calldata params,
        uniData calldata data
    ) external noReentrant {
        _uniData = uniData({
            factory: data.factory,
            initCode: data.initCode,
            amountIn: data.amountIn,
            amountOutMin: data.amountOutMin,
            path: data.path
        });

        if (!getBoolean(params.boolData, whichBool.increasePosition)) {
            flash(params, ContractMethod.swapOnUniswapFork, params.vaultID);
            return;
        }

        uint96 vaultID = params.vaultID;
        if (params.vaultID == 0) {
            vaultID = _mintVault();
        }
        if (params.fundAmount != 0) {
            fundVault(
                vaultID,
                params.collateralAsset,
                params.fundAmount,
                getBoolean(params.boolData, whichBool.capToken)
            );
        }

        flash(params, ContractMethod.swapOnUniswapFork, vaultID);
    }

    function modifyPositionMegaSwap(
        FlashParams calldata params,
        Utils.MegaSwapSellData calldata megaData
    ) external noReentrant {
        _megaData = megaData;

        if (!getBoolean(params.boolData, whichBool.increasePosition)) {
            flash(params, ContractMethod.megaSwap, params.vaultID);
            return;
        }

        uint96 vaultID = params.vaultID;
        if (params.vaultID == 0) {
            vaultID = _mintVault();
        }
        if (params.fundAmount != 0) {
            fundVault(
                vaultID,
                params.collateralAsset,
                params.fundAmount,
                getBoolean(params.boolData, whichBool.capToken)
            );
        }

        flash(params, ContractMethod.megaSwap, vaultID);
    }

    function modifyPositionMultiSwap(
        FlashParams calldata params,
        Utils.SellData calldata multiData
    ) external noReentrant {
        _multiData = multiData;

        if (!getBoolean(params.boolData, whichBool.increasePosition)) {
            flash(params, ContractMethod.multiSwap, params.vaultID);
            return;
        }

        uint96 vaultID = params.vaultID;
        if (params.vaultID == 0) {
            vaultID = _mintVault();
        }
        if (params.fundAmount != 0) {
            fundVault(
                vaultID,
                params.collateralAsset,
                params.fundAmount,
                getBoolean(params.boolData, whichBool.capToken)
            );
        }

        flash(params, ContractMethod.multiSwap, vaultID);
    }

    function modifyPositionSimpleSwap(
        FlashParams calldata params,
        Utils.SimpleData calldata simpleData
    ) external noReentrant {
        _simpleData = simpleData;

        if (!getBoolean(params.boolData, whichBool.increasePosition)) {
            flash(params, ContractMethod.simpleSwap, params.vaultID);
            return;
        }

        uint96 vaultID = params.vaultID;
        if (params.vaultID == 0) {
            vaultID = _mintVault();
        }
        if (params.fundAmount != 0) {
            fundVault(
                vaultID,
                params.collateralAsset,
                params.fundAmount,
                getBoolean(params.boolData, whichBool.capToken)
            );
        }
        flash(params, ContractMethod.simpleSwap, vaultID);
    }

    ///@notice internal function to allow funding of vault in a single transaction
    ///@notice this is only reachable if fundAmount != 0 and increasePosition == true
    function fundVault(
        uint96 vaultID,
        address collateralAsset,
        uint256 fundAmount,
        bool capToken
    ) internal {
        if (capToken) {
            IERC20 underlying = IERC20(
                VVC._CappedToken_underlying(collateralAsset)
            );

            //get underlying assets
            underlying.safeTransferFrom(msg.sender, address(this), fundAmount);

            //approve
            underlying.approve(collateralAsset, fundAmount);

            //deposit
            ICappedGovToken(collateralAsset).deposit(fundAmount, vaultID);
        } else {
            IERC20(collateralAsset).safeTransferFrom(
                msg.sender,
                CONTROLLER.vaultAddress(vaultID),
                fundAmount
            );
        }
    }

    ///@notice this is what actually initiates the flash loan
    ///@param vault may be different than params.vault if a new one was minted this TX
    function flash(
        FlashParams calldata params,
        ContractMethod contractMethod,
        uint96 vault
    ) internal {
        require(_vaultID_owner[vault] == msg.sender, "not owner");

        //Balancer expects an array, even though we are only going to pass 1
        IERC20[] memory assets = new IERC20[](1);
        assets[0] = USDC;
        if (getBoolean(params.boolData, whichBool.increasePosition)) {
            //increasePosition - borrow asset
            if (getBoolean(params.boolData, whichBool.capToken)) {
                assets[0] = IERC20(
                    VVC._CappedToken_underlying(params.collateralAsset)
                );
            } else {
                assets[0] = IERC20(params.collateralAsset);
            }
        }

        // amounts should be in USDC terms for lever down, and asset terms for lever up
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = params.borrowAmount;

        BALANCER_VAULT.flashLoan(
            IFlashLoanRecipient(address(this)),
            assets,
            amounts,
            abi.encode(
                flashCallbackData({
                    asset: params.collateralAsset,
                    vault: vault,
                    contractMethod: contractMethod,
                    usdcBuffer: params.usdcBuffer,
                    boolData: params.boolData,
                    withdrawAmount: params.fundAmount
                })
            )
        );
    }

    /**
     * @notice these internal functions are performing the actual swap via the aggregator
     */
    function swapOnUniswapV2Fork() internal {
        _approveProxy(_v2Data.tokenIn, _v2Data.amountInMax);

        PARASWAP.swapOnUniswapV2Fork(
            _v2Data.tokenIn,
            _v2Data.amountInMax,
            _v2Data.amountOut,
            _v2Data.weth,
            _v2Data.pools
        );

        //reset storage - saves gas
        delete _v2Data;
    }

    function swapOnUniswap() internal {
        _approveProxy(
            _uniData.path[0],
            IERC20(_uniData.path[0]).balanceOf(address(this))
        );

        PARASWAP.swapOnUniswap(
            _uniData.amountIn,
            _uniData.amountOutMin,
            _uniData.path
        );

        //reset storage - saves gas
        delete _uniData;
    }

    function swapOnUniswapFork() internal {
        _approveProxy(
            _uniData.path[0],
            IERC20(_uniData.path[0]).balanceOf(address(this))
        );

        PARASWAP.swapOnUniswapFork(
            _uniData.factory,
            _uniData.initCode,
            _uniData.amountIn,
            _uniData.amountOutMin,
            _uniData.path
        );

        //reset storage - saves gas
        delete _uniData;
    }

    function doMegaSwap() internal {
        _approveProxy(_megaData.fromToken, _megaData.fromAmount);

        PARASWAP.megaSwap(_megaData);

        //reset storage - saves gas
        delete _megaData;
    }

    function doMultiSwap() internal {
        _approveProxy(_multiData.fromToken, _multiData.fromAmount);

        PARASWAP.multiSwap(_multiData);

        //reset storage - saves gas
        delete _multiData;
    }

    function doSimpleSwap() internal {
        _approveProxy(_simpleData.fromToken, _simpleData.fromAmount);

        PARASWAP.simpleSwap(_simpleData);

        //reset storage - saves gas
        delete _simpleData;
    }

    ///@notice the proxy must be approved so it can take the tokens and do the swap
    function _approveProxy(address token, uint256 amount) internal {
        IERC20(token).safeIncreaseAllowance(TOKEN_TRANSFER_PROXY, amount);
    }

    ///@notice callback function for balancer flash loans
    ///@notice after calling flash, the balancer vault calls this function here
    ///NOTE This function should only be called by the Balancer vault
    ///@param tokens[0] is the asset we borrowed and will need to repay
    ///@param amounts[0] amount @param tokens[0] we borrowed, we need to repay this + @param feeAmounts[0]
    ///@param feeAmounts[0] should currently be 0, this logic should be able to handle fees if they are ever added
    ///@param userData is encoded data, see struct flashCallbackData
    function receiveFlashLoan(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata feeAmounts,
        bytes calldata userData
    ) external override {
        require(
            msg.sender == address(BALANCER_VAULT),
            "msg.sender != BALANCER_VAULT"
        );

        //decode callback data
        flashCallbackData memory decoded = abi.decode(
            userData,
            (flashCallbackData)
        );

        //calculate amount of tokens[0] to repay, fees should be 0 unless altered by balancer DAO
        uint256 amountOwed = amounts[0] + feeAmounts[0];

        //get the underlying asset if borrowedAsset is a cap token
        address asset = decoded.asset;
        if (getBoolean(decoded.boolData, whichBool.capToken)) {
            asset = VVC._CappedToken_underlying(decoded.asset);
        }

        //get vault object
        IVault vault = IVault(CONTROLLER.vaultAddress((decoded.vault)));

        //add borrowed asset to borrowing power - only increasePosition
        if (
            getBoolean(decoded.boolData, whichBool.capToken) &&
            getBoolean(decoded.boolData, whichBool.increasePosition)
        ) {
            //if cap token and increasePosition == true
            IERC20(asset).approve(
                decoded.asset,
                IERC20(asset).balanceOf(address(this))
            );
            ICappedGovToken(decoded.asset).deposit(
                IERC20(asset).balanceOf(address(this)),
                decoded.vault
            );
        } else if (getBoolean(decoded.boolData, whichBool.increasePosition)) {
            //if not cap token but still increasePosition == true
            IERC20(asset).safeTransfer(
                address(vault),
                IERC20(asset).balanceOf(address(this))
            );
        }

        //here we handle logic having to do with Interest Protocol and the aggregator
        if (getBoolean(decoded.boolData, whichBool.increasePosition)) {
            //if increasePosition, we flash loaned asset into the vault, increasing borrowing power

            uint256 price = ORACLE.getLivePrice(decoded.asset); //use decoded asset here, oracle expects cap token addr to get correct price
            uint256 valueOwed = ((price * amountOwed)) / 1e18;

            CONTROLLER.borrowUSDCto(
                decoded.vault,
                uint192(valueOwed / 1e12) + uint192(decoded.usdcBuffer),
                address(this)
            );
            //use USDC borrowed from IP to purchase asset via aggregator to repay flash loan
            _aggregatorIncrease(decoded.contractMethod);
        } else {
            //use flash loaned USDC to repay liability
            _repayLiability(decoded.vault);

            //withdraw asset from vault and sell via aggregator to repay USDC flash loan
            _aggregatorDecrease(
                decoded.contractMethod,
                decoded.withdrawAmount,
                decoded.asset,
                vault,
                decoded.usdcBuffer
            );
        }

        //repay flash loan
        require(
            tokens[0].balanceOf(address(this)) > amountOwed,
            "Not enough to repay Flash"
        );
        tokens[0].safeTransfer(address(BALANCER_VAULT), amountOwed);

        //send any USDC change back to the vault owner
        if (!getBoolean(decoded.boolData, whichBool.increasePosition)) {
            USDC.safeTransfer(
                _vaultID_owner[decoded.vault],
                USDC.balanceOf(address(this))
            );
        }

        //if withdrawAmount > 0 then the user expects funds back to their wallet, so send the asset we have there
        //otherwise, we send any change back to the vault
        if (
            decoded.withdrawAmount > 0 &&
            !getBoolean(decoded.boolData, whichBool.increasePosition)
        ) {
            IERC20(asset).safeTransfer(
                _vaultID_owner[decoded.vault],
                IERC20(asset).balanceOf(address(this))
            );
        } else {
            /**if withdrawAmount == 0 || increasePosition */
            if (getBoolean(decoded.boolData, whichBool.capToken)) {
                //Cap tokens must be deposited via the deposit function
                IERC20(asset).approve(
                    decoded.asset,
                    IERC20(asset).balanceOf(address(this))
                );
                ICappedGovToken(decoded.asset).deposit(
                    IERC20(asset).balanceOf(address(this)),
                    decoded.vault
                );
            } else {
                //uncapped assets can just be transferred to the vault
                IERC20(asset).safeTransfer(
                    address(vault),
                    IERC20(asset).balanceOf(address(this))
                );
            }
        }

        emit flashLoanLever(
            decoded.contractMethod,
            getBoolean(decoded.boolData, whichBool.increasePosition),
            decoded.vault,
            address(tokens[0]),
            amounts[0]
        );
    }

    ///@notice if increasePosition, simply do the swap via the correct aggregator function
    ///@notice the aggregator data has already been written to storage
    function _aggregatorIncrease(ContractMethod contractMethod) internal {
        if (contractMethod == ContractMethod.multiSwap) {
            doMultiSwap();
        } else if (contractMethod == ContractMethod.simpleSwap) {
            doSimpleSwap();
        } else if (contractMethod == ContractMethod.swapOnUniswap) {
            swapOnUniswap();
        } else if (contractMethod == ContractMethod.swapOnUniswapFork) {
            swapOnUniswapFork();
        } else if (contractMethod == ContractMethod.swapOnUniswapV2Fork) {
            swapOnUniswapV2Fork();
        } else if (contractMethod == ContractMethod.megaSwap) {
            doMegaSwap();
        }
    }

    ///@notice if decreasePosition, we need to withdraw some amount of asset to repay flash loan
    ///@notice this amount is increased by any amount we may want to withdraw in the same transaction
    function _aggregatorDecrease(
        ContractMethod contractMethod,
        uint256 withdrawAmount,
        address asset,
        IVault vault,
        uint256 buffer
    ) internal {
        if (contractMethod == ContractMethod.multiSwap) {
            withdrawAmount += _multiData.fromAmount;
            _withdrawAsset(asset, withdrawAmount, vault, buffer);
            doMultiSwap();
        } else if (contractMethod == ContractMethod.simpleSwap) {
            withdrawAmount += _simpleData.fromAmount;
            _withdrawAsset(asset, withdrawAmount, vault, buffer);

            doSimpleSwap();
        } else if (contractMethod == ContractMethod.swapOnUniswap) {
            withdrawAmount += _uniData.amountIn;
            _withdrawAsset(asset, withdrawAmount, vault, buffer);

            swapOnUniswap();
        } else if (contractMethod == ContractMethod.swapOnUniswapFork) {
            withdrawAmount += _uniData.amountIn;
            _withdrawAsset(asset, withdrawAmount, vault, buffer);

            swapOnUniswapFork();
        } else if (contractMethod == ContractMethod.swapOnUniswapV2Fork) {
            withdrawAmount += _v2Data.amountInMax;
            _withdrawAsset(asset, withdrawAmount, vault, buffer);

            swapOnUniswapV2Fork();
        } else if (contractMethod == ContractMethod.megaSwap) {
            withdrawAmount += _megaData.fromAmount;
            _withdrawAsset(asset, withdrawAmount, vault, buffer);

            doMegaSwap();
        }
    }

    ///@notice repay liability on IP
    ///@notice this contract already has some amount of USDC, use all of it to repay
    ///@notice after execution, either liability is 0, or USDi on this contract is 0
    function _repayLiability(uint96 vault) internal {
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
    }

    ///@notice This removes assets from the vault so we can sell them in order to repay the flash loan
    ///@notice This should only be reachable if decreasePosition == true
    function _withdrawAsset(
        address asset,
        uint256 amountToWithdraw,
        IVault vault,
        uint256 buffer
    ) internal {
        uint256 liability = CONTROLLER.vaultLiability(vault.id()); //~~0.021392200745857087
        uint256 totalTokenBalance = IERC20(asset).balanceOf(address(vault));

        //if liability is 0 we can withdraw everything
        if (liability == 0) {
            if (totalTokenBalance < amountToWithdraw) {
                vault.withdrawErc20(asset, totalTokenBalance);
            } else {
                vault.withdrawErc20(asset, amountToWithdraw);
            }
        } else {
            //if some liability remains, we need to leave some asset to cover it
            uint256 maxWithdrawAmount = _calculateWithdrawAmount(
                liability,
                totalTokenBalance,
                asset,
                vault.id(),
                buffer
            );

            if (amountToWithdraw > maxWithdrawAmount) {
                vault.withdrawErc20(asset, maxWithdrawAmount);
            } else {
                vault.withdrawErc20(asset, amountToWithdraw);
            }
        }
    }

    ///@param buffer is needed to prevent over-withdraw, buffer is the percentage to withdraw out of 1000, so buffer = 999 => withdraw 99.9% of max
    /// this prevents issues where withdrawing the expected amount to withdraw still results in over-withdrawal errors
    /// generally withdrawing with buffer == 999 is safe, if errors persist, increase buffer
    function _calculateWithdrawAmount(
        uint256 liability,
        uint256 totalTokenBalance,
        address asset,
        uint96 vault,
        uint256 buffer
    ) internal view returns (uint256) {
        return
            ((totalTokenBalance -
                ((CONTROLLER.vaultBorrowingPower(vault) - liability) /
                    ORACLE.getLivePrice(asset))) * buffer) / 1000;
    }

    ///@notice decode packed bools from uint8
    function getBoolean(uint8 _packedBools, whichBool _boolNumber)
        internal
        pure
        returns (bool)
    {
        uint8 flag = (_packedBools >> uint8(_boolNumber)) & uint8(1);
        return (flag == 1 ? true : false);
    }
}