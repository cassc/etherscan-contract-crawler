/**
 *Submitted for verification at Etherscan.io on 2023-04-13
*/

//SPDX-License-Identifier: MIT Licensed
pragma solidity ^0.8.10;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function tokensForSale() external view returns (uint256);

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

contract GoldenPresale {
    IERC20 public GoldenToken;

    address payable public owner;

    uint256 public tokenPerEth = 200000000000000 * 1e9;
    uint256 public totalUsers;
    uint256 public soldToken;
    uint256 public maxPurchase = 1 ether;
    uint256 public tokensForSale = 10000000000000000 * 1e9;

    uint256 public amountRaisedInEth;
    address payable public fundReceiver =
        payable(0xE62146C0d544F3B3fe9C75676350d39f54A9D17b);

    uint256 public constant divider = 100;
    bool public enableClaim;
    struct user {
        uint256 Eth_balance;
        uint256 token_balance;
        uint256 claimed_token;
    }

    mapping(address => user) public users;

    modifier onlyOwner() {
        require(msg.sender == owner, "PRESALE: Not an owner");
        _;
    }

    event BuyToken(address indexed _user, uint256 indexed _amount);
    event ClaimToken(address indexed _user, uint256 indexed _amount);

    constructor(IERC20 _token) {
        owner = payable(0xE62146C0d544F3B3fe9C75676350d39f54A9D17b);
        GoldenToken = _token;
    }

    receive() external payable {}

    // to buy token during preSale time with Eth => for web3 use

    function buyToken() public payable {
        require(enableClaim == false, "Presale : Paused");
        require(
            users[msg.sender].Eth_balance + msg.value <= maxPurchase,
            "Presale : amount must be less than max purchase"
        );
        require(soldToken <= tokensForSale, "All Sold");

        uint256 numberOfTokens;
        numberOfTokens = EthToToken(msg.value);
        soldToken = soldToken + (numberOfTokens);
        amountRaisedInEth = amountRaisedInEth + (msg.value);
        fundReceiver.transfer(msg.value);

        users[msg.sender].Eth_balance =
            users[msg.sender].Eth_balance +
            (msg.value);
        users[msg.sender].token_balance =
            users[msg.sender].token_balance +
            (numberOfTokens);
    }

    // to change preSale amount limits
    function setSupply(
        uint256 tokenPerPhase,
        uint256 _soldToken
    ) external onlyOwner {
        tokensForSale = tokenPerPhase;
        soldToken = _soldToken;
    }

    // Claim bought tokens
    function claimTokens() external {
        require(enableClaim == true, "Presale : Presale is not finished yet");
        require(users[msg.sender].token_balance != 0, "Presale: 0 to claim");

        user storage _usr = users[msg.sender];

        GoldenToken.transfer(msg.sender, _usr.token_balance);
        _usr.claimed_token += _usr.token_balance;
        _usr.token_balance -= _usr.token_balance;

        emit ClaimToken(msg.sender, _usr.token_balance);
    }

    // to check number of token for given eth
    function EthToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = (_amount * (tokenPerEth)) / (1e18);
        return numberOfTokens;
    }

    // to change Price of the token
    function changePrice(uint256 _price) external onlyOwner {
        tokenPerEth = _price;
    }

    function EnableClaim(bool _claim) public onlyOwner {
        enableClaim = _claim;
    }

    function changePurchaseLimits(uint256 _maxPurchase) public onlyOwner {
        maxPurchase = _maxPurchase;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    // change tokens
    function changeToken(address _token) external onlyOwner {
        GoldenToken = IERC20(_token);
    }

    // to draw funds for liquidity
    function transferFundsEth(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    // to draw out tokens
    function transferTokens(IERC20 token, uint256 _value) external onlyOwner {
        token.transfer(msg.sender, _value);
    }
}