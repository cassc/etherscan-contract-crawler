//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "../incentives/StakingIncentivesV41.sol";
import "../token/LiquidityToken.sol";
import "../upgrade/FsBase.sol";
import "../upgrade/FsProxy.sol";
import "../exchange41/ExchangeLedger.sol";
import "../exchange41/SpotMarketAmm.sol";
import "../exchange41/TradeRouter.sol";
import "../exchange41/TokenVault.sol";

struct ExchangeDeployment {
    address tradeRouter;
    address amm;
    address exchangeLedger;
    address tokenVault;
    address priceOracle;
    address ammAdapter;
    address assetToken;
    address stableToken;
    address liquidityToken;
    address liquidityIncentives;
}

library DeployerLibrary {
    function deployTradeRouter(ExchangeDeployment memory data, address wethToken)
        external
        returns (address)
    {
        address tradeRouter =
            address(
                new TradeRouter(
                    data.exchangeLedger,
                    wethToken,
                    data.tokenVault,
                    data.priceOracle,
                    data.assetToken,
                    data.stableToken
                )
            );
        // Approve trade router so it can withdraw funds from the vault to pay to various parties.
        TokenVault(data.tokenVault).setAddressApproval(tradeRouter, true);
        return tradeRouter;
    }
}

/// @title ExchangeDeployer deploys exchanges.
/// @notice This contract is upgradable via the transparent proxy pattern.
contract ExchangeDeployer is FsBase {
    /// @notice Address of the proxy admin that will be authorized to upgrade the contracts this deployer creates.
    /// Proxy admin should be owned by the voting executor so only governance ultimately has the ability to upgrade
    /// contracts.
    address public immutable proxyAdmin;
    address public immutable treasury;
    address public immutable wethToken;
    address public immutable rewardsToken;

    /// @dev Logic contracts that will be used to deploy upgradable exchange contracts. This way, all exchanges will
    /// share the same logic contracts and we wouldn't have to deploy 1 logic contract per new upgradable contract,
    /// which is expensive.
    address public exchangeLedgerLogic;
    address public spotMarketAmmLogic;
    address public stakingIncentivesLogic;

    /// @notice The admin of token vault that is responsible for freezing/unfreezing the token vault in case of
    /// emergencies.
    address public tokenVaultAdmin;

    /// @dev Reserves storage for future upgrades. Each contract will use exactly storage slot 1000 until 2000.
    /// When adding new fields to this contract, one must decrement this counter proportional to the number of uint256
    /// slots used.
    //slither-disable-next-line unused-state
    uint256[996] private _____contractGap;

    /// @notice Only for testing our contract gap mechanism, never use in prod.
    //slither-disable-next-line constable-states,unused-state
    uint256 private ___storageMarker;

    /// @notice Emitted when the logic contracts are updated
    /// @param exchangeLedgerLogic address of the new exchange logic contract
    /// @param stakingIncentivesLogic address of the new stakingIncentives logic contract
    /// @param spotMarketAmmLogic address of the new SpotMarketAmm logic contract
    event LogicContractsUpdated(
        address exchangeLedgerLogic,
        address stakingIncentivesLogic,
        address spotMarketAmmLogic
    );

    /// @notice Emitted when an exchange contract is deployed.
    /// @param data The addresses of the contracts for the deployed exchange.
    event ExchangeAdded(address indexed exchange, address creator, ExchangeDeployment data);

    event TokenVaultAdminUpdated(address oldTokenVault, address newTokenVault);

    /// @dev We use immutables as these parameters will not change. Immutables are not stored in storage, but directly
    /// embedded in the deployed code and thus save storage reads. If, somehow, these need to be updated this can still
    /// be done through a implementation update of the ExchangeDeployer proxy.
    constructor(
        address _proxyAdmin,
        address _treasury,
        address _wethToken,
        address _rewardsToken
    ) {
        // nonNull() does zero checks already.
        //slither-disable-next-line missing-zero-check
        proxyAdmin = nonNull(_proxyAdmin);
        //slither-disable-next-line missing-zero-check
        treasury = nonNull(_treasury);
        //slither-disable-next-line missing-zero-check
        wethToken = nonNull(_wethToken);
        //slither-disable-next-line missing-zero-check
        rewardsToken = nonNull(_rewardsToken);
    }

    /// @notice initialize the owner and the logic contracts
    /// @param _exchangeLedgerLogic The address of the new exchange logic contract.
    /// @param _stakingIncentivesLogic The address of the new staking incentives logic contract.
    /// @param _spotMarketAmmLogic The address of the new spot market amm logic contract.
    function initialize(
        address _exchangeLedgerLogic,
        address _stakingIncentivesLogic,
        address _spotMarketAmmLogic,
        address _tokenVaultAdmin
    ) external initializer {
        initializeFsOwnable();
        setLogicContracts(_exchangeLedgerLogic, _stakingIncentivesLogic, _spotMarketAmmLogic);
        setTokenVaultAdmin(_tokenVaultAdmin);
    }

    /// @notice Deploys a new exchange with a spot market AMM. Can only be done by the owner.
    /// @param assetToken The address of the token that will be used as the asset in the exchange.
    /// @param stableToken The address of the token that will be used as the stable in the exchange.
    /// @param liquidityTokenName Name of the liquidity token associated with the exchange.
    /// @param liquidityTokenSymbol Symbol of the liquidity token associated with the exchange.
    /// @param priceOracle The oracle used by the exchange to get stable or asset prices.
    /// @param ammAdapter The AMM adapter used by the exchange's spot market amm.
    /// @param exchangeConfig The first part of the exchange's config.
    /// @param ammConfig The AMM's config.
    /// @param incentivesHook The incentives hook to connect to the deployed exchange. Can be zero address if not
    /// available.
    /// @param liquidityRewardsLockupTime rewards lockup time for liquidity provider incentives.
    /// @return Addresses for deployed contracts.
    function createExchangeWithSpotMarketAmm(
        address assetToken,
        address stableToken,
        string calldata liquidityTokenName,
        string calldata liquidityTokenSymbol,
        address priceOracle,
        address ammAdapter,
        ExchangeLedger.ExchangeConfig calldata exchangeConfig,
        SpotMarketAmm.AmmConfig calldata ammConfig,
        address incentivesHook,
        uint256 liquidityRewardsLockupTime
    ) external onlyOwner returns (ExchangeDeployment memory) {
        // slither-disable-next-line uninitialized-local
        ExchangeDeployment memory data;
        data.assetToken = assetToken;
        data.stableToken = stableToken;
        data.priceOracle = priceOracle;
        data.ammAdapter = ammAdapter;
        data.tokenVault = address(new TokenVault(tokenVaultAdmin));
        data.liquidityToken = address(new LiquidityToken(liquidityTokenName, liquidityTokenSymbol));

        deployExchangeLedger(data, exchangeConfig, incentivesHook);
        data.tradeRouter = DeployerLibrary.deployTradeRouter(data, wethToken);
        deploySpotMarketAmm(data, ammConfig, liquidityRewardsLockupTime);

        // We need to set the tradeRouter and AMM references in Exchange here instead of during initialization because
        // there's a circular dependency between them.
        ExchangeLedger(data.exchangeLedger).setTradeRouter(data.tradeRouter);
        ExchangeLedger(data.exchangeLedger).setAmm(data.amm);

        updateOwnership(data);
        // We rely on our contracts not to start another deployment inside of their initialization
        // functions, causing events to be emitted in an incorrect order.  This is the issue Slither
        // is flagging here.
        // slither-disable-next-line reentrancy-events
        emit ExchangeAdded(data.exchangeLedger, msg.sender, data);

        // Return the deployed addresses. This can be useful for off-chain staticcalls to get the addresses in advance.
        return data;
    }

    /// @notice Set the logic contracts to a new version so newly deployed contracts use the new logic.
    /// @param _exchangeLedgerLogic The address of the new exchange logic contract.
    /// @param _stakingIncentivesLogic The address of the new staking incentive contract.
    /// @param _spotMarketAmmLogic The address of the new spot market amm logic contract.
    function setLogicContracts(
        address _exchangeLedgerLogic,
        address _stakingIncentivesLogic,
        address _spotMarketAmmLogic
    ) public onlyOwner {
        //slither-disable-next-line missing-zero-check
        exchangeLedgerLogic = nonNull(_exchangeLedgerLogic);
        //slither-disable-next-line missing-zero-check
        stakingIncentivesLogic = nonNull(_stakingIncentivesLogic);
        //slither-disable-next-line missing-zero-check
        spotMarketAmmLogic = nonNull(_spotMarketAmmLogic);
        emit LogicContractsUpdated(exchangeLedgerLogic, stakingIncentivesLogic, spotMarketAmmLogic);
    }

    function setTokenVaultAdmin(address _tokenVaultAdmin) public onlyOwner {
        if (tokenVaultAdmin == _tokenVaultAdmin) {
            return;
        }

        emit TokenVaultAdminUpdated(tokenVaultAdmin, _tokenVaultAdmin);
        //slither-disable-next-line missing-zero-check
        tokenVaultAdmin = nonNull(_tokenVaultAdmin);
    }

    function deployExchangeLedger(
        ExchangeDeployment memory data,
        ExchangeLedger.ExchangeConfig calldata exchangeConfig,
        address incentivesHook
    ) private {
        // Slither infers type for `initialize.selector` to be `uint256`, while the first argument
        // of `encodeWithSelector` is `bytes4`.  It seems wrong that the `selector` type is inferred
        // to be `uint256`.  We know this call works.
        // slither-disable-next-line safe-cast
        bytes memory initializeContractData =
            abi.encodeWithSelector(
                ExchangeLedger(exchangeLedgerLogic).initialize.selector,
                treasury
            );
        address exchangeLedger = deployProxy(exchangeLedgerLogic, initializeContractData);
        ExchangeLedger(exchangeLedger).setExchangeConfig(exchangeConfig);
        if (incentivesHook != address(0)) {
            ExchangeLedger(exchangeLedger).setHook(incentivesHook);
        }

        data.exchangeLedger = exchangeLedger;
    }

    function deploySpotMarketAmm(
        ExchangeDeployment memory data,
        SpotMarketAmm.AmmConfig memory ammConfig,
        uint256 liquidityRewardsLockupTime
    ) private {
        // We always have LP incentives staking as a way to avoid flashloan attacks against liquidity pools.
        data.liquidityIncentives = deployLiquidityIncentives(data.liquidityToken);
        StakingIncentivesV41(data.liquidityIncentives).setMaxLockupTime(liquidityRewardsLockupTime);

        // Slither infers type for `initialize.selector` to be `uint256`, while the first argument
        // of `encodeWithSelector` is `bytes4`.  It seems wrong that the `selector` type is inferred
        // to be `uint256`.  We know this call works.
        // slither-disable-next-line safe-cast
        bytes memory initializeAmmData =
            abi.encodeWithSelector(
                // Need payable as SpotMarketAmm has a receive() function.
                SpotMarketAmm(payable(spotMarketAmmLogic)).initialize.selector,
                data.exchangeLedger,
                data.tokenVault,
                data.assetToken,
                data.stableToken,
                data.liquidityToken,
                data.liquidityIncentives,
                data.ammAdapter,
                data.priceOracle,
                ammConfig
            );
        data.amm = deployProxy(spotMarketAmmLogic, initializeAmmData);

        // Approve the amm to use funds from the vault to pay for swaps with spot markets such as Uniswap.
        TokenVault(data.tokenVault).setAddressApproval(data.amm, true);
    }

    function deployLiquidityIncentives(address _liquidityToken) private returns (address) {
        // Slither infers type for `initialize.selector` to be `uint256`, while the first argument
        // of `encodeWithSelector` is `bytes4`.  It seems wrong that the `selector` type is inferred
        // to be `uint256`.  We know this call works.
        // slither-disable-next-line safe-cast
        bytes memory initializeContractData =
            abi.encodeWithSelector(
                StakingIncentivesV41(stakingIncentivesLogic).initialize.selector,
                _liquidityToken,
                treasury,
                rewardsToken
            );
        return deployProxy(stakingIncentivesLogic, initializeContractData);
    }

    function updateOwnership(ExchangeDeployment memory data) private {
        // Transfer ownership of exchange to voting executor so it can adjust parameters.
        address ownerAddress = owner();
        ExchangeLedger(data.exchangeLedger).transferOwnership(ownerAddress);

        // Transfer ownerships of trade router to voting executor.
        TradeRouter(payable(data.tradeRouter)).transferOwnership(ownerAddress);

        // Transfer ownerships of vaults to voting executor so only it can approve addresses for moving funds in the
        // future.
        TokenVault(data.tokenVault).transferOwnership(ownerAddress);

        // Transfer ownership of liquidity incentives contract to voting executor so it can add and adjust rewards.
        StakingIncentivesV41(data.liquidityIncentives).transferOwnership(ownerAddress);

        // Transfer ownership of amm to voting executor so it can adjust parameters.
        SpotMarketAmm(payable(data.amm)).transferOwnership(ownerAddress);

        // Liquidity token should be owned by the amm as it's the one handling adding/removing liquidity and thus needs
        // to be able to mint/burn liquidity token.
        LiquidityToken(data.liquidityToken).transferOwnership(data.amm);
    }

    /// @notice Deploys a proxy contract instance, connected to the specified `logic` contract.
    ///         `callData` are the encoded arguments passed for the `initialize()` call.
    function deployProxy(address logic, bytes memory callData) private returns (address) {
        return address(new FsProxy(logic, proxyAdmin, callData));
    }
}