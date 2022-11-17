// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {NotionalFinanceValueProvider} from "../oracle_implementations/discount_rate/NotionalFinance/NotionalFinanceValueProvider.sol";
import {Relayer} from "../relayer/Relayer.sol";
import {IRelayer} from "../relayer/IRelayer.sol";

contract NotionalFinanceFactory {
    event NotionalFinanceDeployed(
        address relayerAddress,
        address oracleAddress
    );

    /// @param collybus_ Address of the collybus
    /// @param tokenId_ Token Id that will be used to push values to Collybus
    /// @param minimumPercentageDeltaValue_ Minimum delta value used to determine when to
    /// push data to Collybus
    /// @param timeUpdateWindow_ Minimum time between updates of the value
    /// @param notional_ The address of the deployed notional contract
    /// @param currencyId_ Currency ID(eth = 1, dai = 2, usdc = 3, wbtc = 4)
    /// @param oracleRateDecimals_ Precision of the Notional oracle rate
    /// @param maturity_ Maturity date.
    /// @return The address of the Relayer
    function create(
        // Relayer parameters
        address collybus_,
        uint256 tokenId_,
        uint256 minimumPercentageDeltaValue_,
        // Oracle parameters
        uint256 timeUpdateWindow_,
        // Notional specific parameters, see NotionalFinanceValueProvider for more info
        address notional_,
        uint256 currencyId_,
        uint256 oracleRateDecimals_,
        uint256 maturity_
    ) external returns (address) {
        // Create the oracle that will fetch data from the NotionalFinance contract
        NotionalFinanceValueProvider notionalFinanceValueProvider = new NotionalFinanceValueProvider(
                timeUpdateWindow_,
                notional_,
                currencyId_,
                oracleRateDecimals_,
                maturity_
            );

        // Create the relayer that manages the oracle and pushes data to Collybus
        Relayer relayer = new Relayer(
            collybus_,
            IRelayer.RelayerType.DiscountRate,
            address(notionalFinanceValueProvider),
            bytes32(tokenId_),
            minimumPercentageDeltaValue_
        );

        // Whitelist the Relayer in the Oracle so it can trigger updates
        notionalFinanceValueProvider.allowCaller(
            notionalFinanceValueProvider.ANY_SIG(),
            address(relayer)
        );
        // Whitelist the deployer
        notionalFinanceValueProvider.allowCaller(
            notionalFinanceValueProvider.ANY_SIG(),
            msg.sender
        );
        // Whitelist the deployer
        relayer.allowCaller(relayer.ANY_SIG(), msg.sender);

        // Renounce permissions
        relayer.blockCaller(relayer.ANY_SIG(), address(this));
        notionalFinanceValueProvider.blockCaller(
            notionalFinanceValueProvider.ANY_SIG(),
            address(this)
        );

        emit NotionalFinanceDeployed(
            address(relayer),
            address(notionalFinanceValueProvider)
        );

        // Return the address of the relayer
        return address(relayer);
    }
}