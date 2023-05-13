// // SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.7;

import "./Config.sol";
import "./Utils.sol";

abstract contract AuctionHouseLike {
    function AUCTION_TYPE() external virtual returns (bytes32);
}

abstract contract Setter {
    function updateResult(uint256) external virtual;

    function addAuthorization(address) external virtual;

    function removeAuthorization(address) external virtual;

    function removeAuthority(address) external virtual;

    function setAuthority(address) external virtual;

    function setOwner(address) external virtual;

    function setDelay(uint256) external virtual;

    function modifyParameters(bytes32, address) external virtual;

    function modifyParameters(bytes32, bytes32, address) external virtual;

    function modifyParameters(bytes32, uint256) external virtual;

    function modifyParameters(bytes32, bytes32, uint256) external virtual;

    function setPerBlockAllowance(address, uint256) external virtual;

    function setTotalAllowance(address, uint256) external virtual;

    function initializeCollateralType(bytes32) external virtual;

    function updateCollateralPrice(bytes32) external virtual;

    function updateRate(address) external virtual;

    function transfer(address, uint256) external virtual;

    function balanceOf(address) external view virtual returns (uint256);
}

contract Setup is Config {
    Setter internal immutable coin;
    Setter internal immutable coinJoin;
    Setter internal immutable coinOracle;
    Setter internal immutable oracleRelayer;
    Setter internal immutable safeEngine;
    Setter internal immutable taxCollector;
    Setter internal immutable coinSavingsAccount;
    Setter internal immutable surplusAuctionHouse;
    Setter internal immutable debtAuctionHouse;
    Setter internal immutable accountingEngine;
    Setter internal immutable liquidationEngine;
    Setter internal immutable stabilityFeeTreasury;
    Setter internal immutable globalSettlement;
    Setter internal immutable esm;
    Setter internal immutable rateCalculator;
    Setter internal immutable rateSetter;
    Setter internal immutable rateSetterRelayer;
    Setter internal immutable pause;
    Setter internal immutable protocolTokenAuthority;
    Setter internal immutable prot;
    Setter internal immutable debtPopperRewards;
    Setter internal immutable debtRewards;
    Setter internal immutable rewardsDripper;
    Setter internal immutable liquidityRewards;
    Setter internal immutable emitter;

    constructor(address[] memory addresses) public {
        coin = Setter(addresses[0]);
        coinJoin = Setter(addresses[1]);
        coinOracle = Setter(addresses[2]);
        oracleRelayer = Setter(addresses[3]);
        safeEngine = Setter(addresses[4]);
        taxCollector = Setter(addresses[5]);
        coinSavingsAccount = Setter(addresses[6]);
        surplusAuctionHouse = Setter(addresses[7]);
        debtAuctionHouse = Setter(addresses[8]);
        accountingEngine = Setter(addresses[9]);
        liquidationEngine = Setter(addresses[10]);
        stabilityFeeTreasury = Setter(addresses[11]);
        globalSettlement = Setter(addresses[12]);
        esm = Setter(addresses[13]);
        rateCalculator = Setter(addresses[14]);
        rateSetter = Setter(addresses[15]);
        rateSetterRelayer = Setter(addresses[16]);
        pause = Setter(addresses[17]);
        protocolTokenAuthority = Setter(addresses[18]);
        prot = Setter(addresses[19]);
        debtPopperRewards = Setter(addresses[20]);
        debtRewards = Setter(addresses[21]);
        rewardsDripper = Setter(addresses[22]);
        liquidityRewards = Setter(addresses[23]);
        emitter = Setter(addresses[24]);
    }

    function setup() external {
        // prot
        prot.setAuthority(address(protocolTokenAuthority));

        protocolTokenAuthority.addAuthorization(address(debtAuctionHouse));
        protocolTokenAuthority.addAuthorization(address(surplusAuctionHouse)); // todo: confirmar 

        // coin oracle
        if (IS_TESTNET)
            coinOracle.updateResult(INITIAL_COIN_PRICE);

        // safeEngine
        safeEngine.modifyParameters("globalDebtCeiling", GLOBAL_DEBT_CEILING);

        safeEngine.modifyParameters("rewards", address(debtRewards));
        rewardsDripper.modifyParameters("requestor0", address(debtRewards));
        rewardsDripper.modifyParameters(
            "requestor1",
            address(liquidityRewards)
        );
        rewardsDripper.modifyParameters(
            "requestorZeroShare",
            INCENTIVES_DEBT_SHARE
        );
        rewardsDripper.modifyParameters(
            "lastUpdateTime",
            INCENTIVES_START_TIME - DRIPPER_UPDATE_DELAY
        );
        rewardsDripper.modifyParameters("fundsHolder", address(emitter));

        oracleRelayer.modifyParameters(
            "redemptionPrice",
            INITIAL_COIN_PRICE * 10 ** 9
        );

        // taxation
        safeEngine.addAuthorization(address(taxCollector));
        taxCollector.modifyParameters(
            "primaryTaxReceiver",
            address(stabilityFeeTreasury)
        ); // stability fee treasury will accumulate, anything over treasury capacity is sent to accounting engine (surplus buffer)
        stabilityFeeTreasury.modifyParameters(
            "treasuryCapacity",
            TREASURY_CAPACITY
        );

        // dsr
        if (DEPLOY_DSR) {
            safeEngine.addAuthorization(address(coinSavingsAccount));
        }

        // auction setup
        if (
            (SURPLUS_AUCTION_HOUSE_TYPE == "recycling" ||
                SURPLUS_AUCTION_HOUSE_TYPE == "mixed") &&
            SURPLUS_AUCTION_RECEIVER != address(0)
        ) {
            surplusAuctionHouse.modifyParameters(
                "protocolTokenBidReceiver",
                SURPLUS_AUCTION_RECEIVER
            );
        }

        safeEngine.addAuthorization(address(debtAuctionHouse));

        // accounting engine
        debtAuctionHouse.modifyParameters(
            "accountingEngine",
            address(accountingEngine)
        );
        surplusAuctionHouse.addAuthorization(address(accountingEngine));
        debtAuctionHouse.addAuthorization(address(accountingEngine));

        accountingEngine.modifyParameters(
            "protocolTokenAuthority",
            address(protocolTokenAuthority)
        );
        accountingEngine.modifyParameters(
            "surplusAuctionAmountToSell",
            SURPLUS_AUCTION_AMOUNT_TO_SELL
        );
        accountingEngine.modifyParameters("surplusBuffer", SURPLUS_BUFFER);

        // liquidation engine
        liquidationEngine.modifyParameters(
            "accountingEngine",
            address(accountingEngine)
        );
        safeEngine.addAuthorization(address(liquidationEngine));
        accountingEngine.addAuthorization(address(liquidationEngine));

        // global settlement
        globalSettlement.modifyParameters("safeEngine", address(safeEngine));
        globalSettlement.modifyParameters(
            "liquidationEngine",
            address(liquidationEngine)
        );
        globalSettlement.modifyParameters(
            "accountingEngine",
            address(accountingEngine)
        );
        globalSettlement.modifyParameters(
            "oracleRelayer",
            address(oracleRelayer)
        );
        if (address(coinSavingsAccount) != address(0)) {
            globalSettlement.modifyParameters(
                "coinSavingsAccount",
                address(coinSavingsAccount)
            );
        }
        if (address(stabilityFeeTreasury) != address(0)) {
            globalSettlement.modifyParameters(
                "stabilityFeeTreasury",
                address(stabilityFeeTreasury)
            );
        }

        safeEngine.addAuthorization(address(globalSettlement));
        liquidationEngine.addAuthorization(address(globalSettlement));
        accountingEngine.addAuthorization(address(globalSettlement));
        oracleRelayer.addAuthorization(address(globalSettlement));
        if (address(coinSavingsAccount) != address(0)) {
            coinSavingsAccount.addAuthorization(address(globalSettlement));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
            stabilityFeeTreasury.addAuthorization(address(globalSettlement));
        }

        // ESM
        globalSettlement.addAuthorization(address(esm));

        // Controller
        rateSetterRelayer.modifyParameters("setter", address(rateSetter));
        if (CONTROLLER_TYPE != "new") {
            rateCalculator.modifyParameters("allReaderToggle", 1);
        }
        rateCalculator.modifyParameters("seedProposer", address(rateSetter));
        rateSetter.updateRate(address(accountingEngine));
        oracleRelayer.addAuthorization(address(rateSetterRelayer));
        stabilityFeeTreasury.setPerBlockAllowance(
            address(rateSetterRelayer),
            CONTROLLER_SETTER_MAX_UPDATE_CALLER_REWARD
        );
        stabilityFeeTreasury.setTotalAllowance(
            address(rateSetterRelayer),
            uint256(-1)
        );
        rateSetterRelayer.modifyParameters(
            "maxRewardIncreaseDelay",
            CONTROLLER_SETTER_RELAYER_MAX_REWARD_INCREASE_DELAY
        );

        // DebtPopperRewards
        stabilityFeeTreasury.setPerBlockAllowance(
            address(debtPopperRewards),
            POPPER_REWARDS_FIXED_REWARD
        );
        stabilityFeeTreasury.setTotalAllowance(
            address(debtPopperRewards),
            uint256(-1)
        );

        // deauth deployer from all contracts
        coinJoin.removeAuthorization(ETH_FROM);
        oracleRelayer.removeAuthorization(ETH_FROM);
        safeEngine.removeAuthorization(ETH_FROM);
        taxCollector.removeAuthorization(ETH_FROM);
        if (address(coinSavingsAccount) != address(0))
            coinSavingsAccount.removeAuthorization(ETH_FROM);
        surplusAuctionHouse.removeAuthorization(ETH_FROM);
        debtAuctionHouse.removeAuthorization(ETH_FROM);
        accountingEngine.removeAuthorization(ETH_FROM);
        liquidationEngine.removeAuthorization(ETH_FROM);
        stabilityFeeTreasury.removeAuthorization(ETH_FROM);
        globalSettlement.removeAuthorization(ETH_FROM);
        esm.removeAuthorization(ETH_FROM);
        rateCalculator.removeAuthority(ETH_FROM);
        rateSetter.removeAuthorization(ETH_FROM);
        rateSetterRelayer.removeAuthorization(ETH_FROM);
        debtPopperRewards.removeAuthorization(ETH_FROM);
        rewardsDripper.removeAuthorization(ETH_FROM);
        liquidityRewards.removeAuthorization(ETH_FROM);

        // pause setup
        pause.setDelay(PAUSE_DELAY);
        pause.setOwner(GEB_MULTISIG); 

        // distribute prot
        prot.transfer(GEB_MULTISIG, PROTOCOL_TOKEN_MULTISIG_AMOUNT); // team / treasury
        prot.transfer(GEB_MULTISIG, PROTOCOL_TOKEN_COMMUNITY_TREASURY); // community fund
        prot.transfer(address(emitter), prot.balanceOf(address(this))); // emitter
    }

    function setupCollateral(
        bytes32 collateralType,
        address auctionHouse,
        address adapter,
        address collateralFSM,
        uint256 debtCeiling,
        uint256 debtFloor,
        uint256 cRatio,
        uint256 stabilityFee,
        uint256 liquidationPenalty,
        uint256 liquidationQuantity,
        bytes calldata auctionHouseParams
    ) external {

        safeEngine.addAuthorization(address(oracleRelayer)); // todo: move to main
        safeEngine.addAuthorization(adapter);

        liquidationEngine.modifyParameters(
            collateralType,
            "collateralAuctionHouse",
            auctionHouse
        );
        liquidationEngine.modifyParameters(
            collateralType,
            "liquidationPenalty",
            liquidationPenalty
        );
        liquidationEngine.modifyParameters(
            collateralType,
            "liquidationQuantity",
            liquidationQuantity
        );
        liquidationEngine.addAuthorization(auctionHouse);
        // Internal auth
        Setter(auctionHouse).addAuthorization(address(liquidationEngine));
        Setter(auctionHouse).addAuthorization(address(globalSettlement));

        oracleRelayer.modifyParameters(
            collateralType,
            "orcl",
            address(collateralFSM)
        );

        // Internal references set up
        safeEngine.initializeCollateralType(collateralType);
        taxCollector.initializeCollateralType(collateralType);
        taxCollector.modifyParameters(
            collateralType,
            "stabilityFee",
            stabilityFee
        );

        // Set bid restrictions
        Setter(auctionHouse).modifyParameters(
            "oracleRelayer",
            address(oracleRelayer)
        );
        Setter(auctionHouse).modifyParameters(
            "collateralFSM",
            address(collateralFSM)
        );

        setupCollateralAuctionHouse(auctionHouse, auctionHouseParams);

        safeEngine.modifyParameters(collateralType, "debtCeiling", debtCeiling);
        safeEngine.modifyParameters(collateralType, "debtFloor", debtFloor);
        oracleRelayer.modifyParameters(collateralType, "safetyCRatio", cRatio);
        oracleRelayer.modifyParameters(
            collateralType,
            "liquidationCRatio",
            cRatio
        );

        // remove auth
        Setter(auctionHouse).removeAuthorization(ETH_FROM);
        Setter(adapter).removeAuthorization(ETH_FROM);
        Setter(collateralFSM).removeAuthorization(ETH_FROM);

        // update collateral price
        oracleRelayer.updateCollateralPrice(collateralType);
    }

    function setupCollateralAuctionHouse(
        address auctionHouse,
        bytes memory params
    ) internal {
        (
            uint256 minBid,
            uint256 minDiscount,
            uint256 maxDiscount,
            uint256 maxDiscountUpdateRateTimeline,
            uint256 lowerCollateralMedianDeviation,
            uint256 upperCollateralMedianDeviation
        ) = abi.decode(
                params,
                (uint256, uint256, uint256, uint256, uint256, uint256)
            );
        Setter(auctionHouse).modifyParameters("minimumBid", minBid);
        Setter(auctionHouse).modifyParameters("minDiscount", minDiscount);
        Setter(auctionHouse).modifyParameters("maxDiscount", maxDiscount);
        Setter(auctionHouse).modifyParameters(
            "maxDiscountUpdateRateTimeline",
            maxDiscountUpdateRateTimeline
        );

        Setter(auctionHouse).modifyParameters(
            "lowerCollateralMedianDeviation",
            lowerCollateralMedianDeviation
        );
        Setter(auctionHouse).modifyParameters(
            "upperCollateralMedianDeviation",
            upperCollateralMedianDeviation
        );
    }
}