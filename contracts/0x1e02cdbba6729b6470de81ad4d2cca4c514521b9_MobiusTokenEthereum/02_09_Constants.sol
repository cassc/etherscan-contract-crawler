// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

contract Constants {
    bytes32 internal constant MOT = 'MOT';
    bytes32 internal constant USD = 'moUSD';

    bytes32 internal constant CONTRACT_RESOLVER = 'Resolver';
    bytes32 internal constant CONTRACT_ASSET_PRICE = 'AssetPrice';
    bytes32 internal constant CONTRACT_SETTING = 'Setting';

    bytes32 internal constant CONTRACT_MOBIUS = 'Mobius';
    bytes32 internal constant CONTRACT_ESCROW = 'Escrow';
    bytes32 internal constant CONTRACT_ISSUER = 'Issuer';

    bytes32 internal constant CONTRACT_STAKER = 'Staker';
    bytes32 internal constant CONTRACT_TRADER = 'Trader';
    bytes32 internal constant CONTRACT_TEAM = 'Team';

    bytes32 internal constant CONTRACT_MOBIUS_TOKEN = 'MobiusToken';

    bytes32 internal constant CONTRACT_LIQUIDATOR = 'Liquidator';

    bytes32 internal constant CONTRACT_REWARD_COLLATERAL = 'RewardCollateral';
    bytes32 internal constant CONTRACT_REWARD_STAKING = 'RewardStaking';
    bytes32 internal constant CONTRACT_REWARD_TRADING = 'RewardTradings';

    bytes32 internal constant TRADING_FEE_ADDRESS = 'TradingFeeAddress';
    bytes32 internal constant LIQUIDATION_FEE_ADDRESS = 'LiquidationFeeAddress';

    bytes32 internal constant CONTRACT_DYNCMIC_TRADING_FEE = 'DynamicTradingFee';
}