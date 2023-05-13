// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.7;
pragma experimental ABIEncoderV2;

// settings for core deployments
abstract contract Config {
    // external addresses
    address internal constant ETH_FROM = 0xe75B8A5Ba47ca7458Cbc4dB1dD52df5E2ebC42Cf;
    address internal constant GEB_MULTISIG = 0x4fC49D0979fa0Ea7cE33C5cb98af01BbA5C48C6F;
    address internal constant MULTICALL = address(0x51812e07497586ce025D798Bb44b6d11bBEe3a01);
    address internal constant PROXY_ACTIONS = address(0);
    address internal constant PROXY_ACTIONS_INCENTIVES = address(0);
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant UNIV3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address internal constant BUNNI_FACTORY = 0xb5087F95643A9a4069471A28d32C569D9bd57fE4;
    address internal constant PROXY_REGISTRY = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;
    address internal constant COIN_ORACLE = 0x7F9E3bC7c858Bf830906a0BD81F184708cc42260;

    // testnet - will deploy tokens for collaterals if true. Owner of tokens will remain the EOA used to create them (will not be transferred to pause.proxy())
    bool internal constant IS_TESTNET = false;

    // pause
    uint256 internal constant PAUSE_DELAY = 0;

    // protocol token
    string internal constant PROTOCOL_TOKEN_NAME = "RATE governance token";
    string internal constant PROTOCOL_TOKEN_SYMBOL = "RATE";
    uint internal constant PROTOCOL_TOKEN_SUPPLY = 1000000 ether;
    uint internal constant PROTOCOL_TOKEN_MULTISIG_AMOUNT = 170000 ether; // 17%
    uint internal constant PROTOCOL_TOKEN_COMMUNITY_TREASURY = 50000 ether; // 5%

    // coin
    string internal constant SYSTEM_COIN_NAME = "TAI reflex index";
    string internal constant SYSTEM_COIN_SYMBOL = "TAI";
    uint internal constant INITIAL_COIN_PRICE = 1 ether;

    // DSR
    bool internal constant DEPLOY_DSR = false;

    // Safe engine
    uint internal constant GLOBAL_DEBT_CEILING = uint(-1);

    // Accounting Engine
    uint internal constant SURPLUS_AUCTION_AMOUNT_TO_SELL = 23539750823574720783752937941325000000000000000000;
    uint internal constant SURPLUS_BUFFER = 500000000000000000000000000000000000000000000000000;

    // SF treasury
    uint internal constant TREASURY_CAPACITY = 10000 *10**45;

    // Auction houses
    bytes32 internal constant SURPLUS_AUCTION_HOUSE_TYPE = "mixed";
    address internal constant SURPLUS_AUCTION_RECEIVER = address(0x1); // receives proceeds from surplus auctions on recycling and mixedStrat

    // ESM
    uint internal constant ESM_THRESHOLD = 20000 ether;
    uint internal constant ESM_MIN_AMOUNT_TO_BURN = 10000 ether;
    uint internal constant ESM_SUPPLY_PERCENTAGE_TO_BURN = 100; // 10%

    // Controller
    bytes32 internal constant CONTROLLER_TYPE = "new"; // raw, scaled, or new. PI always used
    int256 internal constant CONTROLLER_KP = 0;
    int256 internal constant CONTROLLER_KI = 0;
    int256 internal constant CONTROLLER_BIAS = 0;
    uint256 internal constant CONTROLLER_PSCL = 1000000000000000000000000000;
    uint256 internal constant CONTROLLER_IPS = 3600;
    uint256 internal constant CONTROLLER_NB = 1000000000000000000;
    uint256 internal constant CONTROLLER_FOUB = 1000000000000000000000000000000000000000000000;
    int256 internal constant CONTROLLER_FOLB = -999999999999999999999999999;
    int256[] internal CONTROLLER_IMPORTED_STATE = new int256[](5); // clean state

    // Controller setter
    uint256 internal constant CONTROLLER_SETTER_UPDATE_DELAY = 3600;
    uint256 internal constant CONTROLLER_SETTER_BASE_UPDATE_CALLER_REWARD = 100;
    uint256 internal constant CONTROLLER_SETTER_MAX_UPDATE_CALLER_REWARD = 200;
    uint256 internal constant CONTROLLER_SETTER_PER_SECOND_REWARD_INCREASE = 1000000000000000000000000000; // no increase
    uint256 internal constant CONTROLLER_SETTER_RELAY_DELAY = 3600;
    uint256 internal constant CONTROLLER_SETTER_RELAYER_MAX_REWARD_INCREASE_DELAY = 6 hours;

    // Collateral  oracle reward params
    uint256 internal constant ORACLE_BASE_CALLER_REWARD = 100;
    uint256 internal constant ORACLE_MAX_CALLER_REWARD = 200;
    uint256 internal constant ORACLE_PERIOD_SIZE = 2600;
    uint256 internal constant ORACLE_REWARD_INCREASE = 1000000000000000000000000000;
    uint256 internal constant ORACLE_REWARD_INCREASE_TIMELINE = 3600;
    uint256 internal constant ORACLE_MAX_REWARD_INCREASE_DELAY = 6 hours;

    // Debt Popper Rewards
    uint256 internal immutable POPPER_REWARDS_REWARD_PERIOD_START;
    uint256 internal constant POPPER_REWARDS_INTER_PERIOD_DELAY = 1209600;
    uint256 internal constant POPPER_REWARDS_REWARD_TIMELINE = 4838400;
    uint256 internal constant POPPER_REWARDS_FIXED_REWARD = 8068940976438182549;
    uint256 internal constant POPPER_REWARDS_MAX_PER_PERIOD_POPS = 50;
    uint256 internal constant POPPER_REWARDS_REWARD_START_TIME = 1620766800;

    // Liqiudity Incentives
    uint24  internal constant UNI_V3_FEE = 3000;
    int24   internal constant BUNNI_POSITION_TICK_LOWER = int24(-887220);
    int24   internal constant BUNNI_POSITION_TICK_UPPER = int24(887220);

    // Rewards
    uint256 internal constant INCENTIVES_START_TIME = 1680924973;
    uint256 internal constant INCENTIVES_DEBT_SHARE = 10**18 / 2; // 50%
    address internal constant DRIPPER_RATE_SETTER = GEB_MULTISIG; 
    uint256 internal constant DRIPPER_REWARD_PERIOD = 30 days; 
    uint256 internal constant DRIPPER_UPDATE_DELAY = 1 days;

    // Emitter
    uint256 internal constant EMITTER_INIT_TIMESTAMP = 1680924973;
    uint256 internal constant EMITTER_START_AMOUNT = PROTOCOL_TOKEN_SUPPLY - PROTOCOL_TOKEN_MULTISIG_AMOUNT - PROTOCOL_TOKEN_COMMUNITY_TREASURY;
    uint256 internal constant EMITTER_C = 20 ether;
    uint256 internal constant EMITTER_LAM = uint(1 ether) / 120;

    constructor() public {
        // setting deploy time vars here
        POPPER_REWARDS_REWARD_PERIOD_START = block.timestamp + 10 days;
    }
}