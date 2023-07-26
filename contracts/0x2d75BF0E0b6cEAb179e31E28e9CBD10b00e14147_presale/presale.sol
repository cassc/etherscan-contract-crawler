/**
 *Submitted for verification at Etherscan.io on 2023-07-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function SupplyPerPhase() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(address from, address to, uint256 value) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract presale {
    IERC20 public XG = IERC20(0xd05b51bF612e1B8F987557de03844bA65c8455E5);
    IERC20 public USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    AggregatorV3Interface public priceFeeD;

    address payable public owner;

    uint256 public tokenPerUsd = 1 * 1e18;
    uint256 public minmumPurchaseInNative = 0.000001 ether;
    uint256 public minmumPurchaseInUSDT = 1e6;
    uint256 public referralPercent = 0;
    uint256 public bonusToken = 0;
    uint256 public totalUsers;
    uint256 public soldToken;
    uint256 public SupplyPerPhase = 10000000 ether;
    uint256 public amountRaised;
    uint256 public amountRaisedUSDT;
    address payable public fundReceiver =
        payable(0x7bD3BDed9C801709ebF208733d0014A4f655DAeF);

    uint256 public constant divider = 100;
    address[] public UsersAddresses;

    bool public presaleStatus;
    mapping(address => bool) public oldBuyer;

    struct user {
        uint256 native_balance;
        uint256 usdt_balance;
        uint256 token_balance;
        uint256 claimed_token;
    }

    mapping(address => user) public users;
    mapping(address => uint256) public wallets;

    modifier onlyOwner() {
        require(msg.sender == owner, "PRESALE: Not an owner");
        _;
    }

    event BuyToken(address indexed _user, uint256 indexed _amount);
    event ClaimToken(address indexed _user, uint256 indexed _amount);

    constructor() {
        owner = payable(0xB5B01b45D46748f7AD347F7a4D46640157427E81);
        priceFeeD = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        presaleStatus = true;
    }

    receive() external payable {}

    // to get real time price of Eth
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeeD.latestRoundData();
        return uint256(price);
    }

    // to buy token during preSale time with Eth => for web3 use

    function buyToken(address _ref) public payable {
        require(presaleStatus == true, "Presale : Presale is finished");
        require(
            msg.value >= minmumPurchaseInNative,
            "Presale : amount must be greater than minimum purchase"
        );
        require(soldToken <= SupplyPerPhase, "All Sold");
        if (oldBuyer[msg.sender] != true) {
            totalUsers += 1;
        }
        uint256 numberOfTokens;
        numberOfTokens = NativeToToken(msg.value);
        uint256 bonus = (bonusToken * numberOfTokens) / divider;
        uint256 _refamount = (referralPercent * numberOfTokens) / divider;
        soldToken = soldToken + (numberOfTokens);
        amountRaised = amountRaised + (msg.value);
        fundReceiver.transfer(msg.value);

        users[msg.sender].native_balance =
            users[msg.sender].native_balance +
            (msg.value);
        users[msg.sender].token_balance =
            users[msg.sender].token_balance +
            (numberOfTokens + bonus);
        users[_ref].token_balance = users[_ref].token_balance + (_refamount);
        UsersAddresses.push(msg.sender);
    }

    // to buy token during preSale time with USDT => for web3 use
    function buyTokenUSDT(address _ref, uint256 amount) public {
        require(presaleStatus == true, "Presale : Presale is finished");
        require(
            amount >= minmumPurchaseInUSDT,
            "Presale : amount must be greater than minimum purchase"
        );

        require(soldToken <= SupplyPerPhase, "All Sold");
        if (oldBuyer[msg.sender] != true) {
            totalUsers += 1;
        }

        USDT.transferFrom(msg.sender, fundReceiver, amount);

        uint256 numberOfTokens;
        numberOfTokens = usdtToToken(amount);
        uint256 bonus = (bonusToken * numberOfTokens) / divider;
        uint256 _refamount = (referralPercent * numberOfTokens) / divider;

        soldToken = soldToken + (numberOfTokens);
        amountRaisedUSDT = amountRaisedUSDT + (amount);

        users[msg.sender].usdt_balance += amount;

        users[msg.sender].token_balance =
            users[msg.sender].token_balance +
            (numberOfTokens + bonus);
        users[_ref].token_balance = users[_ref].token_balance + (_refamount);
        UsersAddresses.push(msg.sender);
    }

    // Claim bought tokens
    function claimTokens() external {
        require(presaleStatus == false, "Presale : Presale is not finished");
        require(users[msg.sender].token_balance != 0, "Presale: 0 to claim");

        user storage _usr = users[msg.sender];

        XG.transfer(msg.sender, _usr.token_balance);
        _usr.claimed_token += _usr.token_balance;
        _usr.token_balance -= _usr.token_balance;

        emit ClaimToken(msg.sender, _usr.token_balance);
    }

    // to check percentage of token sold
    function getProgress() public view returns (uint256 _percent) {
        uint256 remaining = SupplyPerPhase -
            (soldToken / (10 ** (XG.decimals())));
        remaining = (remaining * (divider)) / (SupplyPerPhase);
        uint256 hundred = 100;
        return hundred - (remaining);
    }

    // to change preSale amount limits
    function setSupplyPerPhase(
        uint256 _SupplyPerPhase,
        uint256 _soldToken
    ) external onlyOwner {
        SupplyPerPhase = _SupplyPerPhase;
        soldToken = _soldToken;
    }

    function stopPresale(bool _off) external onlyOwner {
        presaleStatus = _off;
    }

    // to check number of token for given Eth
    function NativeToToken(uint256 _amount) public view returns (uint256) {
        uint256 EthToUsd = (_amount * (getLatestPrice())) / (1 ether);
        uint256 numberOfTokens = (EthToUsd * (tokenPerUsd)) / (1e8);
        return numberOfTokens;
    }

    // to check number of token for given usdt
    function usdtToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = (_amount * (tokenPerUsd)) / (1e6);
        return numberOfTokens;
    }

    // to change Price of the token
    function changePrice(uint256 _price) external onlyOwner {
        tokenPerUsd = _price;
    }

    function minPurchase(
        uint256 _minmumPurchaseInNative,
        uint256 _minmumPurchaseInUSDT
    ) public onlyOwner {
        minmumPurchaseInNative = _minmumPurchaseInNative;
        minmumPurchaseInUSDT = _minmumPurchaseInUSDT;
    }

    // to change bonus %
    function changeBonus(uint256 _bonus) external onlyOwner {
        bonusToken = _bonus;
    }

    // to change referral %
    function changeRefPercent(uint256 _ref) external onlyOwner {
        referralPercent = _ref;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    // change tokens
    function changeToken(address _token) external onlyOwner {
        XG = IERC20(_token);
    }

    //change USDT
    function changeUSDT(address _USDT) external onlyOwner {
        USDT = IERC20(_USDT);
    }

    // to draw funds for liquidity
    function transferFunds(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    // to draw out tokens
    function transferTokens(IERC20 token, uint256 _value) external onlyOwner {
        token.transfer(msg.sender, _value);
    }

    function BSCbuyers(
        address[] memory wallet,
        uint256[] memory amount
    ) public onlyOwner {
        for (uint256 i = 0; i < wallet.length; i++) {
            wallets[wallet[i]] += amount[i];
        }
    }

    function ClaimForBSC() public {
        require(wallets[msg.sender] > 0, "already claimed");
        XG.transfer(msg.sender, wallets[msg.sender] * 1e18);
        wallets[msg.sender] = 0;
    }
}