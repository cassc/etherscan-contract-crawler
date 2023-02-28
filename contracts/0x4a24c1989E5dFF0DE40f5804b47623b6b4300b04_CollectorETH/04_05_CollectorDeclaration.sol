// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.18;

interface UniswapV2 {

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        returns (uint256[] memory amounts);
}

interface TokenERC20 {

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool success);

    function approve(
        address _spender,
        uint256 _value
    )
        external
        returns (bool success);
}

interface WiserToken {
    function mintSupply(
        address _to,
        uint256 _value
    )
        external
        returns (bool success);
}

contract CollectorDeclaration {

    UniswapV2 public constant UNISWAP_ROUTER = UniswapV2(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 constant INVESTMENT_DAYS = 50;
    uint256 constant REFERRAL_BONUS = 10;
    uint256 constant SECONDS_IN_DAY = 86400;
    uint256 constant PRECISION_POINT = 100E18;
    uint256 constant INCEPTION_TIME = 1677628800;
    uint256 constant LIMIT_REFERRALS = 90000000E18;
    uint256 constant WISER_FUNDRAISE = 10000000E18;
    uint128 constant MINIMUM_REFERRAL = 10 ether;
    uint128 constant MIN_INVEST = 50000000000000000;
    uint128 constant DAILY_SUPPLY = 18000000E18;

    struct Globals {
        uint64 generatedDays;
        uint64 preparedReferrals;
        uint256 totalTransferTokens;
        uint256 totalWeiContributed;
        uint256 totalReferralTokens;
    }

    Globals public g;

    mapping(uint256 => uint256) public dailyTotalSupply;
    mapping(uint256 => uint256) public dailyTotalInvestment;

    mapping(uint256 => uint256) public investorAccountCount;
    mapping(uint256 => mapping(uint256 => address)) public investorAccounts;
    mapping(address => mapping(uint256 => uint256)) public investorBalances;

    mapping(address => uint256) public referralAmount;
    mapping(address => uint256) public referralTokens;
    mapping(address => uint256) public investorTotalBalance;
    mapping(address => uint256) public originalInvestment;

    uint256 public referralAccountCount;
    uint256 public uniqueInvestorCount;

    mapping (uint256 => address) public uniqueInvestors;
    mapping (uint256 => address) public referralAccounts;

    event GeneratedStaticSupply(
        uint256 indexed investmentDay,
        uint256 staticSupply
    );

    event ReferralAdded(
        address indexed referral,
        address indexed referee,
        uint256 amount
    );

    event WiseReservation(
        address indexed sender,
        uint256 indexed investmentDay,
        uint256 amount
    );
}