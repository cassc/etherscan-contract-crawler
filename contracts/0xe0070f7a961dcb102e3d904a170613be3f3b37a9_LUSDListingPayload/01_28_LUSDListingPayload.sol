// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { AaveV2Ethereum } from 'aave-address-book/AaveAddressBook.sol';

interface Initializable {
    function initialize(
        uint8 underlyingAssetDecimals,
        string calldata tokenName,
        string calldata tokenSymbol
    ) external;
}

interface IProposalGenericExecutor {
    function execute() external;
}

contract LUSDListingPayload is IProposalGenericExecutor {
    address public constant LUSD = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    uint8 public constant LUSD_DECIMALS = 18;

    address public constant FEED_LUSD_USD_TO_LUSD_ETH =
        0x60c0b047133f696334a2b7f68af0b49d2F3D4F72;

    address public constant ATOKEN_IMPL =
        0x893E606358205AD994e610ad48e8aEF98aEadDbe;
    address public constant VARIABLE_DEBT_IMPL =
        0xEB1cfEF24F5B9d287F702AC6EbD301E606936B54;
    address public constant STABLE_DEBT_IMPL =
        0x595c33538215DC4B092F35Afc85d904631263f4F;
    address public constant INTEREST_RATE_STRATEGY =
        0x545Ae1908B6F12e91E03B1DEC4F2e06D0570fE1b;

    uint256 public constant RESERVE_FACTOR = 1000;
    uint256 public constant LTV = 0;
    uint256 public constant LIQUIDATION_THRESHOLD = 0;
    uint256 public constant LIQUIDATION_BONUS = 0;

    function execute() external override {
        address[] memory assets = new address[](1);
        assets[0] = LUSD;
        address[] memory sources = new address[](1);
        sources[0] = FEED_LUSD_USD_TO_LUSD_ETH;

        AaveV2Ethereum.ORACLE.setAssetSources(assets, sources);

        AaveV2Ethereum.POOL_CONFIGURATOR.initReserve(
            ATOKEN_IMPL,
            STABLE_DEBT_IMPL,
            VARIABLE_DEBT_IMPL,
            LUSD_DECIMALS,
            INTEREST_RATE_STRATEGY
        );

        AaveV2Ethereum.POOL_CONFIGURATOR.enableBorrowingOnReserve(LUSD, true);
        AaveV2Ethereum.POOL_CONFIGURATOR.setReserveFactor(LUSD, RESERVE_FACTOR);
        /*
        AaveV2Ethereum.POOL_CONFIGURATOR.configureReserveAsCollateral(
            LUSD,
            LTV,
            LIQUIDATION_THRESHOLD,
            LIQUIDATION_BONUS
        );
        */

        // We initialize the different implementations, for security reasons
        Initializable(ATOKEN_IMPL).initialize(
            uint8(18),
            "Aave interest bearing LUSD",
            "aLUSD"
        );
        Initializable(VARIABLE_DEBT_IMPL).initialize(
            uint8(18),
            "Aave variable debt bearing LUSD",
            "variableDebtLUSD"
        );
        Initializable(STABLE_DEBT_IMPL).initialize(
            uint8(18),
            "Aave stable debt bearing LUSD",
            "stableDebtLUSD"
        );
    }
}