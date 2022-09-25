// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Vault } from "./Vault.sol";
import { ShareMath } from "./ShareMath.sol";
import { IStrikeSelection } from "../interfaces/INeuron.sol";
import { GnosisAuction } from "./GnosisAuction.sol";
import { IONtokenFactory, IONtoken, IController, Actions, IMarginVault } from "../interfaces/GammaInterface.sol";
import { IERC20Detailed } from "../interfaces/IERC20Detailed.sol";
import { IGnosisAuction } from "../interfaces/IGnosisAuction.sol";

library VaultLifecycle {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event BurnedOnTokens(address indexed ontokenAddress, uint256 amountBurned);

    struct CloseParams {
        address ON_TOKEN_FACTORY;
        address USDC;
        address currentOption;
        uint256 delay;
        uint16 lastStrikeOverrideRound;
        uint256 overriddenStrikePrice;
        uint256[] collateralConstraints;
    }

    struct ClosePremiumParams {
        address oracle;
        address strikeSelection;
        address optionsPremiumPricer;
        uint256 premiumDiscount;
        address auctionBiddingToken;
    }

    //  * @notice Sets the next option the vault will be shorting, and calculates its premium for the auction
    //  * @param strikeSelection is the address of the contract with strike selection logic
    //  * @param optionsPremiumPricer is the address of the contract with the
    //    black-scholes premium calculation logic
    //  * @param premiumDiscount is the vault's discount applied to the premium
    //  * @param closeParams is the struct with details on previous option and strike selection details
    //  * @param vaultParams is the struct with vault general data
    //  * @param vaultState is the struct with vault accounting state
    //  * @return onTokenAddress is the address of the new option
    //  * @return premium is the premium of the new option
    //  * @return strikePrice is the strike price of the new option
    //  * @return delta is the delta of the new option
    //  */
    function commitAndClose(
        address _usdc,
        uint16 round,
        Vault.VaultParams storage vaultParams,
        CloseParams calldata closeParams,
        ClosePremiumParams calldata closePremiumParams
    )
        external
        returns (
            address onTokenAddress,
            uint256 premium,
            uint256 strikePrice,
            uint256 delta
        )
    {
        bool isPut = vaultParams.isPut;
        address underlying = vaultParams.underlying;
        {
            uint256 expiry = getNextExpiry(closeParams.currentOption);

            IStrikeSelection selection = IStrikeSelection(closePremiumParams.strikeSelection);

            (strikePrice, delta) = closeParams.lastStrikeOverrideRound == round
                ? (closeParams.overriddenStrikePrice, selection.delta())
                : selection.getStrikePrice(expiry, isPut);

            require(strikePrice != 0, "!strikePrice");

            // retrieve address if option already exists, or deploy it
            onTokenAddress = getOrDeployONtoken(
                closeParams,
                vaultParams,
                underlying,
                vaultParams.collateralAssets,
                strikePrice,
                expiry,
                isPut
            );
        }

        address premiumCalcToken = _usdc;
        if (premiumCalcToken != closePremiumParams.auctionBiddingToken) {
            // get the black scholes premium of the option
            premium = GnosisAuction.getONTokenPremiumInToken(
                closePremiumParams.oracle,
                onTokenAddress,
                closePremiumParams.optionsPremiumPricer,
                closePremiumParams.premiumDiscount,
                premiumCalcToken,
                closePremiumParams.auctionBiddingToken
            );
        } else {
            // get the black scholes premium of the option
            premium = GnosisAuction.getONTokenPremium(
                onTokenAddress,
                closePremiumParams.optionsPremiumPricer,
                closePremiumParams.premiumDiscount
            );
        }
        require(premium > 0, "!premium");

        return (onTokenAddress, premium, strikePrice, delta);
    }

    /**
     * @notice Verify the onToken has the correct parameters to prevent vulnerability to option protocolcontract changes
     * @param onTokenAddress is the address of the onToken
     * @param vaultParams is the struct with vault general data
     * @param collateralAssets is the address of the collateral asset
     * @param USDC is the address of usdc
     * @param delay is the delay between commitAndClose and rollToNextOption
     */
    function verifyONtoken(
        address onTokenAddress,
        Vault.VaultParams storage vaultParams,
        address[] memory collateralAssets,
        address USDC,
        uint256 delay
    ) private view {
        require(onTokenAddress != address(0), "!onTokenAddress");

        IONtoken onToken = IONtoken(onTokenAddress);
        require(onToken.isPut() == vaultParams.isPut, "Type mismatch");
        require(onToken.underlyingAsset() == vaultParams.underlying, "Wrong underlyingAsset");
        require(
            keccak256(abi.encode(onToken.getCollateralAssets())) == keccak256(abi.encode(collateralAssets)),
            "Wrong collateralAsset"
        );

        // we just assume all options use USDC as the strike
        require(onToken.strikeAsset() == USDC, "strikeAsset != USDC");

        uint256 readyAt = block.timestamp.add(delay);
        require(onToken.expiryTimestamp() >= readyAt, "Expiry before delay");
    }

    /**
     * @notice Creates the actual Option Protocol short position by depositing collateral and minting onTokens
     * @param gammaController is the address of the option protocolcontroller contract
     * @param marginPool is the address of the option protocolmargin contract which holds the collateral
     * @param onTokenAddress is the address of the onToken to mint
     * @param depositAmounts is the amounts of collaterals to deposit
     * @return the onToken mint amount
     */
    function createShort(
        address gammaController,
        address marginPool,
        address onTokenAddress,
        uint256[] memory depositAmounts
    ) external returns (uint256, uint256) {
        IController controller = IController(gammaController);
        uint256 newVaultID = (controller.accountVaultCounter(address(this))).add(1);

        // An onToken's collateralAsset is the vault's `asset`
        // So in the context of performing Option Protocol short operations we call them collateralAsset
        IONtoken onToken = IONtoken(onTokenAddress);
        address[] memory collateralAssets = onToken.getCollateralAssets();

        for (uint256 i = 0; i < collateralAssets.length; i++) {
            // double approve to fix non-compliant ERC20s
            IERC20 collateralToken = IERC20(collateralAssets[i]);
            collateralToken.safeApprove(marginPool, 0);
            collateralToken.safeApprove(marginPool, depositAmounts[i]);
        }

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](3);

        // Pass zero to mint using all deposited collaterals
        uint256[] memory mintAmount = new uint256[](1);

        actions[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.OpenVault,
            owner: address(this), // owner
            secondAddress: onTokenAddress, // optionToken
            assets: new address[](0), // not used
            vaultId: newVaultID, // vaultId
            amounts: new uint256[](0) // not used
        });

        actions[1] = Actions.ActionArgs({
            actionType: Actions.ActionType.DepositCollateral,
            owner: address(this), // owner
            secondAddress: address(this), // address to transfer from
            assets: new address[](0), // not used
            vaultId: newVaultID, // vaultId
            amounts: depositAmounts // amounts
        });

        actions[2] = Actions.ActionArgs({
            actionType: Actions.ActionType.MintShortOption,
            owner: address(this), // owner
            secondAddress: address(this), // address to transfer to
            assets: new address[](0), // not used
            vaultId: newVaultID, // vaultId
            amounts: mintAmount // amount
        });
        controller.operate(actions);

        uint256 mintedAmount = onToken.balanceOf(address(this));

        return (mintedAmount, newVaultID);
    }

    /**
     * @notice Close the existing short onToken position. Currently this implementation is simple.
     * It closes the most recent vault opened by the contract. This assumes that the contract will
     * only have a single vault open at any given time. Since calling `_closeShort` deletes vaults by
     calling SettleVault action, this assumption should hold.
     * @param gammaController is the address of the option protocolcontroller contract
     * @return amount of collateral redeemed from the vault
     */
    function settleShort(Vault.VaultParams storage vaultParams, address gammaController)
        external
        returns (uint256[] memory)
    {
        IController controller = IController(gammaController);

        // gets the currently active vault ID
        uint256 vaultID = controller.accountVaultCounter(address(this));

        (IMarginVault.Vault memory vault, ) = controller.getVaultWithDetails(address(this), vaultID);

        require(vault.shortONtoken != address(0), "No short");

        // This is equivalent to doing IERC20(vault.asset).balanceOf(address(this))
        uint256[] memory startCollateralBalances = getCollateralBalances(vaultParams);

        // If it is after expiry, we need to settle the short position using the normal way
        // Delete the vault and withdraw all remaining collateral from the vault
        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);

        actions[0] = Actions.ActionArgs(
            Actions.ActionType.SettleVault,
            address(this), // owner
            address(this), // address to transfer to
            new address[](0), // not used
            vaultID, // vaultId
            new uint256[](0) // not used
        );

        controller.operate(actions);

        uint256[] memory endCollateralBalances = getCollateralBalances(vaultParams);

        return getArrayOfDiffs(endCollateralBalances, startCollateralBalances);
    }

    /**
     * @notice Burn the remaining onTokens left over from auction. Currently this implementation is simple.
     * It burns onTokens from the most recent vault opened by the contract. This assumes that the contract will
     * only have a single vault open at any given time.
     * @param gammaController is the address of the option protocolcontroller contract
     * @param currentOption is the address of the current option
     */
    function burnONtokens(address gammaController, address currentOption) external {
        uint256 numONTokensToBurn = IERC20(currentOption).balanceOf(address(this));
        require(numONTokensToBurn > 0, "No onTokens to burn");

        IController controller = IController(gammaController);

        // gets the currently active vault ID
        uint256 vaultID = controller.accountVaultCounter(address(this));

        (IMarginVault.Vault memory gammaVault, ) = controller.getVaultWithDetails(address(this), vaultID);

        require(gammaVault.shortONtoken != address(0), "No short");

        // Burning `amount` of onTokens from the neuron vault,
        // then withdrawing the corresponding collateral amount from the vault
        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](2);

        address[] memory shortONtokenAddressActionArg = new address[](1);
        shortONtokenAddressActionArg[0] = gammaVault.shortONtoken;

        uint256[] memory burnAmountActionArg = new uint256[](1);
        burnAmountActionArg[0] = numONTokensToBurn;

        actions[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.BurnShortOption,
            owner: address(this), // vault owner
            secondAddress: address(0), // not used
            assets: shortONtokenAddressActionArg, // short to burn
            vaultId: vaultID,
            amounts: burnAmountActionArg // burn amount
        });

        actions[1] = Actions.ActionArgs({
            actionType: Actions.ActionType.WithdrawCollateral,
            owner: address(this), // vault owner
            secondAddress: address(this), // withdraw to
            assets: new address[](0), // not used
            vaultId: vaultID,
            amounts: new uint256[](1) // array with one zero element to withdraw all available
        });

        controller.operate(actions);

        emit BurnedOnTokens(currentOption, numONTokensToBurn);
    }

    function getCollateralBalances(Vault.VaultParams storage vaultParams) internal view returns (uint256[] memory) {
        address[] memory collateralAssets = vaultParams.collateralAssets;
        uint256 collateralsLength = collateralAssets.length;
        uint256[] memory collateralBalances = new uint256[](collateralsLength);
        for (uint256 i = 0; i < collateralsLength; i++) {
            collateralBalances[i] = IERC20(collateralAssets[i]).balanceOf(address(this));
        }
        return collateralBalances;
    }

    function getArrayOfDiffs(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory) {
        require(a.length == b.length, "Arrays must be of equal length");
        uint256[] memory diffs = new uint256[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            diffs[i] = a[i].sub(b[i]);
        }
        return diffs;
    }

    /**
     * @notice Either retrieves the option token if it already exists, or deploy it
     * @param closeParams is the struct with details on previous option and strike selection details
     * @param vaultParams is the struct with vault general data
     * @param underlying is the address of the underlying asset of the option
     * @param collateralAssets is the address of the collateral asset of the option
     * @param strikePrice is the strike price of the option
     * @param expiry is the expiry timestamp of the option
     * @param isPut is whether the option is a put
     * @return the address of the option
     */
    function getOrDeployONtoken(
        CloseParams calldata closeParams,
        Vault.VaultParams storage vaultParams,
        address underlying,
        address[] memory collateralAssets,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    ) internal returns (address) {
        IONtokenFactory factory = IONtokenFactory(closeParams.ON_TOKEN_FACTORY);

        {
            address onTokenFromFactory = factory.getONtoken(
                underlying,
                closeParams.USDC,
                collateralAssets,
                closeParams.collateralConstraints,
                strikePrice,
                expiry,
                isPut
            );

            if (onTokenFromFactory != address(0)) {
                return onTokenFromFactory;
            }
        }
        address onToken = factory.createONtoken(
            underlying,
            closeParams.USDC,
            collateralAssets,
            closeParams.collateralConstraints,
            strikePrice,
            expiry,
            isPut
        );

        verifyONtoken(onToken, vaultParams, collateralAssets, closeParams.USDC, closeParams.delay);

        return onToken;
    }

    /**
     * @notice Starts the gnosis auction
     * @param auctionDetails is the struct with all the custom parameters of the auction
     * @return the auction id of the newly created auction
     */
    function startAuction(GnosisAuction.AuctionDetails calldata auctionDetails) external returns (uint256) {
        return GnosisAuction.startAuction(auctionDetails);
    }

    /**
     * @notice Settles the gnosis auction
     * @param gnosisEasyAuction is the contract address of Gnosis easy auction protocol
     * @param auctionID is the auction ID of the gnosis easy auction
     */
    function settleAuction(address gnosisEasyAuction, uint256 auctionID) internal {
        IGnosisAuction(gnosisEasyAuction).settleAuction(auctionID);
    }

    /**
     * @notice Verify the constructor params satisfy requirements
     * @param owner is the owner of the vault with critical permissions
     * @param keeper is the address of the vault keeper with vault management permissions
     * @param _vaultParams is the struct with vault general data
     */
    function verifyInitializerParams(
        address owner,
        address keeper,
        Vault.VaultParams calldata _vaultParams
    ) external pure {
        require(owner != address(0), "!owner");
        require(keeper != address(0), "!keeper");

        require(_vaultParams.collateralAssets.length != 0, "!collateralAssets");

        for (uint256 i = 0; i < _vaultParams.collateralAssets.length; i++) {
            require(_vaultParams.collateralAssets[i] != address(0), "zero address collateral asset");
        }

        require(_vaultParams.underlying != address(0), "!underlying");
    }

    /**
     * @notice Gets the next option expiry timestamp
     * @param currentOption is the onToken address that the vault is currently writing
     */
    function getNextExpiry(address currentOption) internal view returns (uint256) {
        // uninitialized state
        if (currentOption == address(0)) {
            return getNextFriday(block.timestamp);
        }
        uint256 currentExpiry = IONtoken(currentOption).expiryTimestamp();

        // After options expiry if no options are written for >1 week
        // We need to give the ability continue writing options
        if (block.timestamp > currentExpiry + 7 days) {
            return getNextFriday(block.timestamp);
        }
        return getNextFriday(currentExpiry);
    }

    /**
     * @notice Gets the next options expiry timestamp
     * @param timestamp is the expiry timestamp of the current option
     * Reference: https://codereview.stackexchange.com/a/33532
     * Examples:
     * getNextFriday(week 1 thursday) -> week 1 friday
     * getNextFriday(week 1 friday) -> week 2 friday
     * getNextFriday(week 1 saturday) -> week 2 friday
     */
    function getNextFriday(uint256 timestamp) internal pure returns (uint256) {
        // dayOfWeek = 0 (sunday) - 6 (saturday)
        uint256 dayOfWeek = ((timestamp / 1 days) + 4) % 7;
        uint256 nextFriday = timestamp + ((7 + 5 - dayOfWeek) % 7) * 1 days;
        uint256 friday8am = nextFriday - (nextFriday % (24 hours)) + (8 hours);

        // If the passed timestamp is day=Friday hour>8am, we simply increment it by a week to next Friday
        if (timestamp >= friday8am) {
            friday8am += 7 days;
        }
        return friday8am;
    }
}