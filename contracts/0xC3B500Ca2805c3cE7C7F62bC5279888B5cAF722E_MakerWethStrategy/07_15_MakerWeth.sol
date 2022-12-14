// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import {BaseStrategy} from "./BaseStrategy.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IDssCdpManager} from "../../interfaces/maker/IDssCdpManager.sol";
import {IGemJoin} from "../../interfaces/maker/IGemJoin.sol";
import {IDaiJoin} from "../../interfaces/maker/IDaiJoin.sol";
import {IJug} from "../../interfaces/maker/IJug.sol";
import {IVat} from "../../interfaces/maker/IVat.sol";
import {ISpot} from "../../interfaces/maker/ISpot.sol";
import {VaultAPI} from "../../interfaces/vault/VaultAPI.sol";
import {IUniswapV2Router01} from "../../interfaces/uniswap/IUniswapV2Router01.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MakerWethStrategy is BaseStrategy {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant _WAD = 1e18;
    uint256 internal constant _RAY = 1e27;
    // 100%, or _WAD basis points
    uint256 internal constant _MAX_BPS = _WAD;
    string internal _strategyName;
    uint256 public cdpId;
    bytes32 public ilk;
    uint256 public dust;
    uint256 public idealCollRatio;
    uint256 public liquidationRatio;
    uint256 public deltaRatioPercentage = 1e25; // 1% in basis points in ray (100% = 1e27 = 1 RAY)
    address public urnHandler;
    ISpot public spot;
    // Wrapped Ether - Used for swaps routing
    address internal constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IGemJoin public gemJoin;

    // Maximum acceptable loss on DAI vault withdrawal. Default to 0.01%.
    uint256 public maxLoss;

    VaultAPI public daiVault;

    IDssCdpManager internal constant _DSS_CDP_MANAGER = IDssCdpManager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);
    IDaiJoin internal constant _DAI_JOIN = IDaiJoin(0x9759A6Ac90977b93B58547b4A71c78317f391A28);
    IJug internal constant _JUG = IJug(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    IVat internal constant _VAT = IVat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    IERC20 internal constant _DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    uint256 internal constant _MAX_LOSS_BPS = 10000;
    IUniswapV2Router01 internal constant _UNISWAPROUTER =
        IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    event Cloned(address indexed clone);
    event CdpUpdated(uint256 virtualNextCollRatio, uint256 updatedCollRatio);

    /**
     * @notice
     *  All precise quantities e.g. ratios have a _RAY denomination
     *  All basic quantities e.g. balances have a _WAD denomination
     */
    constructor(
        address _vault,
        string memory strategyName,
        bytes32 _ilk,
        address _spot,
        address _gemJoin,
        address _daiVault
    ) BaseStrategy(_vault) {
        _initializeStrat(strategyName, _ilk, _spot, _gemJoin, _daiVault);
    }

    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        string memory _name,
        bytes32 _ilk,
        address _spot,
        address _gemJoin,
        address _daiVault
    ) external {
        _initialize(_vault, _strategist, _rewards, _keeper);
        _initializeStrat(_name, _ilk, _spot, _gemJoin, _daiVault);
    }

    function _initializeStrat(
        string memory strategyName,
        bytes32 _ilk,
        address _spot,
        address _gemJoin,
        address _daiVault
    ) internal {
        require(idealCollRatio == 0, "Already Initialized");
        _strategyName = strategyName;
        ilk = _ilk;
        cdpId = _DSS_CDP_MANAGER.open(ilk, address(this));
        require(cdpId > 0, "Bad cdp id");
        urnHandler = _DSS_CDP_MANAGER.urns(cdpId);
        spot = ISpot(_spot);
        gemJoin = IGemJoin(_gemJoin);
        (, liquidationRatio) = spot.ilks(ilk);
        (, , , , dust) = _VAT.ilks(ilk);

        daiVault = VaultAPI(_daiVault);
        // Approve gemJoin to spend want tokens
        IERC20(vault.token()).safeApprove(address(gemJoin), type(uint256).max);

        idealCollRatio = 2100000000000000000000000000; // ray

        // Define maximum acceptable loss on withdrawal to be 0.01%.
        maxLoss = 1;

        // Allow DAI vault and DAIJOIN to spend DAI tokens
        _DAI.safeApprove(address(daiVault), type(uint256).max);
        _DAI.safeApprove(address(_DAI_JOIN), type(uint256).max);

        // Allow the _DAI_JOIN contract to modify the VAT DAI balance of the strategy
        _VAT.hope(address(_DAI_JOIN));
    }

    function cloneMakerWethStrategy(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        string memory _name,
        bytes32 _ilk,
        address _spot,
        address _gemJoin,
        address _daiVault
    ) external returns (address payable newStrategy) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));
        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newStrategy := create(0, clone_code, 0x37)
        }

        MakerWethStrategy(newStrategy).initialize(
            _vault,
            _strategist,
            _rewards,
            _keeper,
            _name,
            _ilk,
            _spot,
            _gemJoin,
            _daiVault
        );

        emit Cloned(newStrategy);
    }

    function name() external view override returns (string memory) {
        return _strategyName;
    }

    function updateCollateralizationRatio(uint256 _collateralizationRatio) public onlyAuthorized {
        require(_collateralizationRatio > liquidationRatio, "Can't go below liquidation ratio");
        idealCollRatio = _collateralizationRatio;
    }

    function updateDeltaCollRatio(uint256 _deltaRatioPercentage) public onlyAuthorized {
        deltaRatioPercentage = _deltaRatioPercentage;
    }

    function updateMaxLoss(uint256 _maxLoss) external onlyAuthorized {
        require(_maxLoss <= _MAX_LOSS_BPS, "Can't set maxLoss higher than 100%");
        maxLoss = _maxLoss;
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        uint256 allDaiInWant = daiToWant(daiTokensInStrategy().add(daiTokensInEbVault()));
        uint256 allAssets = want.balanceOf(address(this)).add(collateralInCdp()).add(allDaiInWant);
        uint256 allDebtInWant = daiToWant(debtInCdp());
        return allAssets.sub(allDebtInWant);
    }

    function _prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        _debtPayment = _debtOutstanding;
        uint256 debtToVault = vault.strategies(address(this)).totalDebt;
        _takeDaiVaultProfit();
        uint256 currentValue = estimatedTotalAssets();

        _profit = currentValue > debtToVault ? currentValue.sub(debtToVault) : 0;
        _loss = debtToVault > currentValue ? debtToVault.sub(currentValue) : 0;

        uint256 toFree = _debtPayment.add(_profit);
        uint256 _withdrawalLoss;

        if (toFree > 0) {
            (, _withdrawalLoss) = _liquidatePosition(toFree);

            if (_withdrawalLoss < _profit) {
                _profit = _profit.sub(_withdrawalLoss);
            } else {
                _loss = _loss.add(_withdrawalLoss.sub(_profit));
                _profit = 0;
            }

            uint256 wantBalance = want.balanceOf(address(this));

            if (wantBalance > _profit && wantBalance < _debtPayment.add(_profit)) {
                _debtPayment = wantBalance.sub(_profit);
            }
        }
    }

    function _liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        // If we can pay with available want balance, we do
        uint256 wantBalanceBefore = want.balanceOf(address(this));

        if (wantBalanceBefore >= _amountNeeded) {
            return (_amountNeeded, 0);
        }
        uint256 amountToLiquidate = _amountNeeded.sub(wantBalanceBefore); // wad
        uint256 amountAvailable = collateralInCdp(); // wad
        // If we don't have enough collateral available, we have to report a loss and liquidate what is available
        amountToLiquidate = Math.min(amountToLiquidate, amountAvailable);
        // By liquidating we adjust the collateralization ratio of our cdp and have to account for this
        uint256 _debtInCdp = debtInCdp(); // wad
        uint256 wantPrice = wantPriceUsd(); // wad
        uint256 amountAvailableUsd = amountAvailable.mul(wantPrice).div(_WAD); // wad
        uint256 amountToLiquidateUsd = amountToLiquidate.mul(wantPrice).div(_WAD); // wad

        if (_debtInCdp > 0) {
            uint256 newCollateralizationRatio = amountAvailableUsd.sub(amountToLiquidateUsd).mul(_RAY).div(_debtInCdp); // ray

            // Assess how much DAI we need to repay in order to keep a healthy collateralization ratio after withdrawing collateral
            _payOffDebt(newCollateralizationRatio);
        }

        // Unlock collateral from the urn and move it back to the strategy
        amountToLiquidate = Math.min(amountToLiquidate, _maxCollLiquidation());
        _freeAndMoveCollateral(amountToLiquidate);

        // Our want balance should now cover the amount we need. If not, we have to report a loss
        uint256 diff = want.balanceOf(address(this)).sub(wantBalanceBefore);

        return diff > amountToLiquidate ? (amountToLiquidate, 0) : (diff, amountToLiquidate.sub(diff));
    }

    function _payOffDebt(uint256 newCollRatio) internal {
        uint256 delta = idealCollRatio.mul(deltaRatioPercentage).div(_MAX_BPS.mul(1e9));
        if (newCollRatio.add(delta) > idealCollRatio) {
            return;
        }
        uint256 debt = debtInCdp(); // wad
        uint256 healthyDebt = newCollRatio.mul(debt).div(idealCollRatio); // wad
        uint256 daiToPayOff;
        uint256 daiBalance = daiTokensInStrategy();
        // Withdraw dai from DaiVault
        if (healthyDebt <= dust.div(_RAY)) {
            // Pay off whole debt if we can, pay off just above the debtfloor (1 wad) otherwise
            uint256 totalAvailableDai = daiBalance.add(daiTokensInEbVault());
            daiToPayOff = totalAvailableDai >= debt ? debt : debt.sub(dust.div(_RAY)).sub(_WAD);
        } else {
            daiToPayOff = debt.sub(healthyDebt);
        }
        if (daiToPayOff > daiBalance) {
            uint256 vaultSharesToWithdraw = Math.min(
                daiToPayOff.sub(daiBalance).mul(_WAD).div(daiVault.pricePerShare()),
                daiVault.balanceOf(address(this))
            );
            if (vaultSharesToWithdraw > 0) {
                daiVault.withdraw(vaultSharesToWithdraw, address(this), maxLoss);
            }
        }

        _wipe(daiToPayOff);
    }

    function _wipe(uint256 amount) private {
        uint256 daiBalance = _DAI.balanceOf(address(this));

        // We cannot payoff more debt then we have
        amount = Math.min(amount, daiBalance);

        uint256 debt = debtInCdp();
        // We cannot payoff more debt then we owe
        amount = Math.min(amount, debt);

        if (amount > 0) {
            // When repaying the full debt it is very common to experience Vat/dust
            // reverts due to the debt being non-zero and less than (or equal to) the debt floor.
            // This can happen due to rounding
            // To circumvent this issue we will add 1 Wei to the amount to be paid
            // if there is enough investment token balance (DAI) to do it.
            if (debt.sub(amount) == 0 && daiBalance.sub(amount) >= 1) {
                amount = amount.add(1);
            }

            // Joins DAI amount into the vat and burns the amount from the callers address
            _DAI_JOIN.join(urnHandler, amount);
            // Paybacks debt to the CDP with the provided DAI in the vat
            _DSS_CDP_MANAGER.frob(cdpId, 0, _getWipeDart(urnHandler, _VAT.dai(urnHandler)));
        }
    }

    function _getWipeDart(address urn, uint256 dai) internal view returns (int256 dart) {
        // Gets actual rate from the vat
        (, uint256 rate, , , ) = _VAT.ilks(ilk);
        // Gets actual art value of the urn
        (, uint256 art) = _VAT.urns(ilk, urn);

        // Uses the whole dai balance in the vat to reduce the debt
        dart = int256(dai.div(rate));

        // Checks the calculated dart is not higher than urn.art (total debt), otherwise uses its value
        dart = uint256(dart) <= art ? -dart : -int256(art);
    }

    function _maxCollLiquidation() internal view returns (uint256) {
        uint256 amountAvailable = collateralInCdp(); // wad
        uint256 _debtInCdp = debtInCdp(); // wad
        if (_debtInCdp == 0) {
            return amountAvailable;
        }

        uint256 collateralPrice = wantPriceUsd(); // wad
        // Allow the liquidation of collateral te be 10% above the liquidation ratio
        uint256 deltaLiqRatioPercentage = (10 * _RAY).div(100);

        uint256 minCollAmount = liquidationRatio.add(deltaLiqRatioPercentage).mul(_debtInCdp).div(collateralPrice).div(
            1e9
        ); // wad

        // If we are under collateralized then it is not safe for us to withdraw anything
        return minCollAmount > amountAvailable ? 0 : amountAvailable.sub(minCollAmount);
    }

    function _liquidateAllPositions() internal override returns (uint256 _amountFreed) {
        (_amountFreed, ) = _liquidatePosition(1e36);
        // we can request a lot. dont use max because of overflow
    }

    function ethToWant(uint256 _amtInWei) public view override returns (uint256) {
        return _amtInWei;
    }

    function daiToWant(uint256 _daiAmount) public view returns (uint256) {
        return _daiAmount.mul(_WAD).div(wantPriceUsd());
    }

    // solhint-disable-next-line no-unused-vars
    function _adjustPosition(uint256 _debtOutstanding) internal override {
        uint256 _wantToInvest = want.balanceOf(address(this));
        if (_wantToInvest == 0) {
            return;
        }

        // Calculate the amount of DAI we want to mint
        uint256 _dart = _calculateDaiAmount(_wantToInvest);
        if (_dart.add(debtInCdp()) <= dust.div(_RAY)) {
            return;
        }

        // Deposit collateral in the VAT
        _depositCollateral(_wantToInvest);
        // Mint DAI against collateral amount
        _mintAndMoveDai(_wantToInvest, _dart);
        daiVault.deposit();
    }

    function _prepareMigration(address _newStrategy) internal override {
        IERC20(daiVault).safeTransfer(_newStrategy, daiVault.balanceOf(address(this)));
        _DAI.safeTransfer(_newStrategy, daiTokensInStrategy());

        // Move ownership to the new strategy. This does NOT move any funds
        _DSS_CDP_MANAGER.give(cdpId, _newStrategy);
    }

    /**
     * @notice
     *  Move collateral and debt to another CDP(urn)
     * @dev
     *  The strategy calling this function, needs to have ownership over both the old and new cdp ids
     *  This function should only be called after migration is done since ownership is moved there
     * @param oldCdpId The CDP ID of the old strategy's urn
     */
    function shiftToCdp(uint256 oldCdpId) external onlyGovernance {
        _DSS_CDP_MANAGER.shift(oldCdpId, cdpId);
    }

    function _protectedTokens() internal view override returns (address[] memory) {
        address[] memory protected = new address[](2);
        protected[0] = address(daiVault);
        protected[1] = address(_DAI);
        return protected;
    }

    // Deposits want into the vat contract
    function _depositCollateral(uint256 _collateralAmount) internal {
        gemJoin.join(urnHandler, _collateralAmount);
    }

    /**
     * @notice
     *  Step 1: Locks collateral into the urn and generates debt against it
     *  Step 2: move DAI to the strategy and mint ERC20 DAI tokens
        The strategies DAI balance should have been increased after minting DAI
     * @param _dink collateral to lock
     * @param _dart DAI in wad to generate as debt and to mint as ERC20
     */
    function _mintAndMoveDai(uint256 _dink, uint256 _dart) internal {
        // Lock collateral & generate DAI
        int256 daiToMintMinusRate = _getDrawDart(urnHandler, _dart);
        _DSS_CDP_MANAGER.frob(cdpId, int256(_dink), daiToMintMinusRate);

        // Move assets from the urn to the strategy
        _DSS_CDP_MANAGER.move(cdpId, address(this), _dart.mul(_RAY));

        // Mint DAI ERC20 tokens for the strategy by decreasing its DAI balance in the VAT contract
        _DAI_JOIN.exit(address(this), _dart);
    }

    function _getDrawDart(address urn, uint256 wad) internal returns (int256 dart) {
        // Updates stability fee rate
        uint256 rate = _JUG.drip(ilk); // ray

        // Gets DAI balance of the urn in the vat
        uint256 dai = _VAT.dai(urn); // rad

        // If there was already enough DAI in the vat balance, just exits it without adding more debt
        if (dai < wad.mul(_RAY)) {
            // Calculates the needed dart so together with the existing dai in the vat is enough to exit wad amount of DAI tokens
            dart = int256(wad.mul(_RAY).sub(dai).div(rate)); // wad
            // This is needed due lack of precision. It might need to sum an extra dart wei (for the given DAI wad amount)
            dart = uint256(dart).mul(rate) < wad.mul(_RAY) ? dart + 1 : dart; // wad
        }
    }

    // Adjusted from 'freeGem' in dssProxyActions.sol. Unlocks collateral and moves it to the strategy.
    function _freeAndMoveCollateral(uint256 _dink) internal {
        // Unlocks token amount from the CDP
        _DSS_CDP_MANAGER.frob(cdpId, -int256(_dink), 0);
        // Moves the amount from the CDP urn to proxy's address
        _DSS_CDP_MANAGER.flux(cdpId, address(this), _dink);
        // Exits token amount to the strategy as a token
        gemJoin.exit(address(this), _dink);
    }

    function wantPriceUsd() public view returns (uint256) {
        (, , uint256 spotPrice, , ) = _VAT.ilks(ilk); // ray
        return spotPrice.mul(liquidationRatio).div(_RAY * 1e9); // wad
    }

    function collateralInCdp() public view returns (uint256) {
        (uint256 collateral, ) = _VAT.urns(ilk, urnHandler);
        return collateral; // wad
    }

    function debtInCdp() public view returns (uint256) {
        (, uint256 debt) = _VAT.urns(ilk, urnHandler); // wad
        (, uint256 rate, , , ) = _VAT.ilks(ilk); // ray
        return debt.mul(rate).div(_RAY); // wad
    }

    /**
     * @notice
     *  Calculates the amount of DAI we can mint for a given collateral amount
     * @param _collateralAmount The amount of collateral tokens to mint dai debt against
     * @return
     *  the amount of DAI to mint in wad
     */
    function _calculateDaiAmount(uint256 _collateralAmount) internal view returns (uint256) {
        uint256 collateralPrice = wantPriceUsd(); // wad

        // dai to mint in wad = wad * wad * wad / (ray * 1e9)
        return _collateralAmount.mul(collateralPrice).mul(_MAX_BPS).div(idealCollRatio * 1e9); // wad
    }

    /**
     * @notice
     *  Calculates the amount of DAI we can mint for a new coll ratio within our current position
     * @param collRatio The collateralization ratio used to determine the amount of DAI to mint
     * @return
     *  the amount of DAI to mint in wad
     */
    function _calculateDaiToMint(uint256 collRatio) internal view returns (uint256) {
        // We need to use Math.max here to prevent underflow errors
        uint256 newCollRatio = Math.max(collRatio, idealCollRatio);
        return newCollRatio.mul(debtInCdp()).div(idealCollRatio).sub(debtInCdp()); // wad
    }

    function daiTokensInEbVault() public view returns (uint256) {
        uint256 balance = daiVault.balanceOf(address(this));
        if (daiVault.totalSupply() == 0) {
            // Needed because of revert on priceperfullshare if 0
            return 0;
        }
        uint256 pricePerShare = daiVault.pricePerShare();
        // dai tokens are 1e18 decimals
        return balance.mul(pricePerShare).div(1e18);
    }

    function daiTokensInStrategy() public view returns (uint256) {
        return _DAI.balanceOf(address(this));
    }

    function _daiToDaiVaultShares(uint256 amount) internal view returns (uint256) {
        return amount.mul(10**daiVault.decimals()).div(daiVault.pricePerShare());
    }

    function currentCollateralRatio() public view returns (uint256) {
        uint256 collateralPrice = wantPriceUsd();
        return calculateCollRatio(collateralInCdp(), debtInCdp(), collateralPrice); // rad
    }

    function calculateCollRatio(
        uint256 collateralAmount,
        uint256 debt,
        uint256 wantPrice
    ) public pure returns (uint256) {
        uint256 collateralInUsd = collateralAmount.mul(wantPrice).div(_WAD);
        return collateralInUsd.mul(_RAY).div(debt); // ray
    }

    /**
     * @notice
     *  Updates the collateralization ratio to ensure a healthy position for the next price snapshot
     * @dev
     *  MakerDAO updates the usd price of collateral every hour
     *  we need to prepare the strategy to prevent liquidation by minting extra DAI
     *  or by repaying debt based on the new collateralization ratio
     * @param newWantPrice The price of the collateral(want) token in the next snapshot in WAD
     */
    function updateCdpRatio(uint256 newWantPrice) external onlyKeepers {
        uint256 newCollRatio = calculateCollRatio(collateralInCdp(), debtInCdp(), newWantPrice); // ray
        if (newCollRatio < liquidationRatio) {
            _payOffDebt(newCollRatio);
        } else {
            uint256 delta = idealCollRatio.mul(deltaRatioPercentage).div(_RAY);
            require(newCollRatio > idealCollRatio.add(delta), "The new collateralization ratio is too low");
            uint256 daiToMint = _calculateDaiToMint(newCollRatio);
            uint256 expectedCollRatioAfterDaiMint = calculateCollRatio(
                collateralInCdp(),
                debtInCdp().add(daiToMint),
                wantPriceUsd()
            );
            require(expectedCollRatioAfterDaiMint > liquidationRatio, "Can't go below liquidation ratio");
            _mintAndMoveDai(0, daiToMint);
            daiVault.deposit();
        }
        emit CdpUpdated(newCollRatio, currentCollateralRatio());
    }

    function _takeDaiVaultProfit() internal {
        uint256 _debt = debtInCdp();
        uint256 _valueInVault = daiTokensInEbVault();
        if (_debt >= _valueInVault) {
            return;
        }

        uint256 profit = _valueInVault.sub(_debt);
        uint256 daiVaultSharesToWithdraw = _daiToDaiVaultShares(profit);
        if (daiVaultSharesToWithdraw > 0) {
            daiVault.withdraw(daiVaultSharesToWithdraw);
            _sellAForB(daiTokensInStrategy(), address(_DAI), address(want));
        }
    }

    function _sellAForB(
        uint256 _amount,
        address tokenA,
        address tokenB
    ) internal {
        if (_amount == 0 || tokenA == tokenB) {
            return;
        }

        _checkAllowance(address(_UNISWAPROUTER), tokenA, _amount);
        _UNISWAPROUTER.swapExactTokensForTokens(
            _amount,
            0,
            _getTokenOutPath(tokenA, tokenB),
            address(this),
            block.timestamp
        );
    }

    function _getTokenOutPath(address _tokenIn, address _tokenOut) internal pure returns (address[] memory _path) {
        bool isWeth = _tokenIn == address(_WETH) || _tokenOut == address(_WETH);
        _path = new address[](isWeth ? 2 : 3);
        _path[0] = _tokenIn;

        if (isWeth) {
            _path[1] = _tokenOut;
        } else {
            _path[1] = address(_WETH);
            _path[2] = _tokenOut;
        }
    }

    function _checkAllowance(
        address _contract,
        address _token,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _contract) < _amount) {
            IERC20(_token).safeApprove(_contract, 0);
            IERC20(_token).safeApprove(_contract, type(uint256).max);
        }
    }
}