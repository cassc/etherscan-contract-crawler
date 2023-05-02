// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ICO is ReentrancyGuard {
    using SafeMath for uint;
    IERC20 public TOKEN;
    uint256 public constant REFERRER_PERCENTS_LENGTH = 1;
    struct Sale {
        address buyer;
        uint tokenAmount;
        uint investAmount;
        bool hasWithdrawn;
        address referrals;
        uint[REFERRER_PERCENTS_LENGTH] referrer;
    }
    uint256[REFERRER_PERCENTS_LENGTH] public REFERRER_PERCENTS = [100]; // 10% referrer bonus
    uint public constant PERCENT_DIVIDER = 1000; // 1000 = 100%, 100 = 10%, 10 = 1%, 1 = 0.1%

    address private feeWallet = address(0x1e4679A5ba393970bC08333de15637487Ac5ec7F);
    address private owner = address(0x810331938e27aE4A0aD5d7D88696E347312232Fc);

    uint public constant HARDCAP = 300 ether;
    uint public constant MIN_INVEST_AMOUNT = 0.1 ether;
    uint public constant MAX_INVEST_AMOUNT = 3 ether;
    uint public bnbtoToken = 200;

    mapping(address => Sale) public sales;
    mapping(uint => address) public investors;
    uint public totalInverstorsCount;
    address public admin;
    uint public initDate;

    uint public totalInvested;
    uint public totalTokenSale;
    bool public isActive = false;
    bool public startWithdraw = false;
    mapping(address => uint) public lastBlock;

    event SaleEvent(
        address indexed _investor,
        uint indexed _investAmount,
        uint indexed _tokenAmount
    );
    event StartWithdrawEvent(bool _canWithdraw);
    event WithdrawEvent(address indexed _investor, uint _tokenAmount);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier saleIsActive() {
        require(isActive, "sale is not active");
        _;
    }

    modifier canWithdraw() {
        require(startWithdraw, "can not withdraw");
        _;
    }

    modifier tenBlocks() {
        require(block.number.sub(lastBlock[msg.sender]) > 10, "wait 10 blocks");
        _;
    }

    function setToken(address _TOKEN) external onlyAdmin {
        TOKEN = IERC20(_TOKEN);
    }

    function start() external onlyAdmin {
        require(!isActive, "ICO is already active");
        isActive = true;
    }

    function stop() external onlyAdmin {
        require(isActive, "ICO is not active");
        isActive = false;
    }

    function starTWithDraw() external onlyAdmin {
        require(!startWithdraw, "ICO is already active");
        startWithdraw = true;
    }

    function stopWithDraw() external onlyAdmin {
        require(startWithdraw, "ICO is not active");
        startWithdraw = false;
    }

    function buy(address ref) external payable saleIsActive tenBlocks nonReentrant {
        uint amount = msg.value;
        require(
            sales[msg.sender].hasWithdrawn == false,
            "you cant withdraw twice"
        );
        require(
            amount >= MIN_INVEST_AMOUNT,
            "bnb must be greater than MIN_INVEST_AMOUNT"
        );
        require(
            amount <= MAX_INVEST_AMOUNT,
            "bnb must be less than MAX_INVEST_AMOUNT"
        );
        require(
            amount <= getReserveToInvest(),
            "bnb must be less than getReserveToInvest()"
        );
        if (amount == getReserveToInvest()) {
            isActive = false;
        }

        Sale memory sale = sales[msg.sender];

        if (sale.investAmount == 0) {
            sales[msg.sender].buyer = msg.sender;
            investors[totalInverstorsCount] = msg.sender;
            totalInverstorsCount += 1;
        }

        uint tokenAmount = amount.mul(bnbtoToken);

        sales[msg.sender].tokenAmount = sale.tokenAmount.add(tokenAmount);
        sales[msg.sender].investAmount = sale.investAmount.add(amount);

        totalInvested = totalInvested.add(amount);
        totalTokenSale = totalTokenSale.add(tokenAmount);
        Sale storage user = sales[msg.sender];
        if(user.referrals == address(0) && msg.sender != feeWallet) {
            if (ref == msg.sender || sales[ref].referrals == msg.sender || msg.sender == sales[ref].referrals) {
                user.referrals = feeWallet;
            } else {
                user.referrals = ref;
            }
            if(user.referrals != msg.sender && user.referrals != address(0)) {
                address upline = user.referrals;
                address old = msg.sender;
                for(uint i = 0; i < REFERRER_PERCENTS_LENGTH; i++) {
                    if(upline != address(0) && upline != old && sales[upline].referrals != old) {
                        sales[upline].referrer[i] += 1;
                        transferHandler(upline, amount.mul(REFERRER_PERCENTS[i]).div(PERCENT_DIVIDER));
                        old = upline;
                        upline = sales[upline].referrals;
                    } else break;
                }
            }
        }
        payFees();
        emit SaleEvent(msg.sender, amount, tokenAmount);
        require(
            sales[msg.sender].investAmount <= MAX_INVEST_AMOUNT,
            "you cant invest more than MAX_INVEST_AMOUNT"
        );
        require(
            totalInvested <= HARDCAP,
            "total invested must be less than HARDCAP"
        );
        if (totalInvested == HARDCAP) {
            isActive = false;
        }
    }

    function withdrawTokens() external canWithdraw tenBlocks nonReentrant {
        require(
            sales[msg.sender].hasWithdrawn == false,
            "you cant withdraw twice"
        );
        sales[msg.sender].hasWithdrawn = true;
        emit WithdrawEvent(msg.sender, sales[msg.sender].tokenAmount);
        TOKEN.transfer(msg.sender, sales[msg.sender].tokenAmount);
    }

    function withdrawDividens() public onlyAdmin {
        payFees();
        TOKEN.transfer(admin, TOKEN.balanceOf(address(this)));
    }

    function finish() external onlyAdmin {
        isActive = false;
        withdrawDividens();
    }

    // function transferAdmin(address newAdmin) external onlyAdmin {
    //     admin = newAdmin;
    // }

    function getReserveToInvest() public view returns (uint) {
        return HARDCAP.sub(totalInvested);
    }

    function getAllInvestorsAdress() public view returns (address[] memory) {
        address[] memory _investors = new address[](totalInverstorsCount);
        for (uint i; i < totalInverstorsCount; i++) {
            _investors[i] = investors[i];
        }
        return _investors;
    }

    function getAllTokens() public view returns (uint[] memory) {
        uint[] memory _tokens = new uint[](totalInverstorsCount);
        for (uint i; i < totalInverstorsCount; i++) {
            _tokens[i] = sales[investors[i]].tokenAmount;
        }
        return _tokens;
    }

    function getAllInvestorAndTokes() public view returns (Sale[] memory) {
        Sale[] memory _investors = new Sale[](totalInverstorsCount);
        for (uint i; i < totalInverstorsCount; i++) {
            _investors[i] = sales[investors[i]];
        }
        return _investors;
    }

    function getAllInvestorAndTokesByindex(
        uint _first,
        uint last
    ) public view returns (Sale[] memory) {
        uint length = last.sub(_first).add(1);
        Sale[] memory _investors = new Sale[](length);
        for (uint i; i < length; i++) {
            _investors[i] = sales[investors[_first + i]];
        }
        return _investors;
    }

    struct SaleToken {
        address buyer;
        uint tokenAmount;
    }

    function getAllInvestors() external view returns (SaleToken[] memory) {
        SaleToken[] memory _investors = new SaleToken[](totalInverstorsCount);
        for (uint i; i < totalInverstorsCount; i++) {
            _investors[i] = SaleToken(
                investors[i],
                sales[investors[i]].tokenAmount
            );
        }
        return _investors;
    }

    function getTokensByInvestor(address investor) public view returns (uint) {
        return sales[investor].tokenAmount;
    }

    function getInvestByInvestor(address investor) public view returns (uint) {
        return sales[investor].investAmount;
    }

    function payFees() internal {
        transferHandler(owner, getBalance());
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function transferHandler(address _to, uint _value) internal {
        uint balance = getBalance();
        if (balance < _value) {
            _value = balance;
        }
        payable(_to).transfer(_value);
    }
}