// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ICO is ReentrancyGuard {
    using SafeMath for uint;

    IERC20 public TOKEN;
    struct Sale {
        address buyer;
        uint tokenAmount;
        uint investAmount;
        bool hasWithdrawn;
    }

    uint constant public OWNER_FEE = 50;//5%
    uint constant public JWALLET_FEE = 25; // 2.5%
    uint constant public DEV_FEE = 25; // 2.5%
    uint constant public PERCENT_DIVIDER = 1000; // 1000 = 100%, 100 = 10%, 10 = 1%, 1 = 0.1%

    address private devAddress;
    address private jWallet;
    address constant public owner = 0x5031Aea78078399fF4c0b30c1AC41B1247BcD0AB;
    address constant public receiverWAllet = 0xAE49aB6c4C131C3c871b1f57832c3f51608B99A6;

    uint constant public HARDCAP = 750 ether;
    uint public constant MIN_INVEST_AMOUNT = 0.005 ether;
    uint public constant MAX_INVEST_AMOUNT = 10 ether;


    mapping(address => Sale) public sales;
    mapping(uint => address) public investors;
    uint public totalInverstorsCount;
    address public admin;
    uint public initDate;
    uint public bnbtoToken = 200;

    uint public totalInvested;
    uint public totalTokenSale;
    bool public isActive = false;
    bool public startWithdraw = false;
	mapping (address => uint) public lastBlock;

    event SaleEvent (address indexed _investor, uint indexed _investAmount, uint indexed _tokenAmount);
    event StartWithdrawEvent(bool _canWithdraw);
    event WithdrawEvent(address indexed _investor, uint _tokenAmount);

    constructor(address _dev, address _marketingAddress) {
        admin = msg.sender;
        devAddress = _dev;
        jWallet = _marketingAddress;
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
        require(
            block.number.sub(lastBlock[msg.sender]) > 10,
            "wait 10 blocks"
        );
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

    function buy() external payable saleIsActive tenBlocks nonReentrant {
        uint amount = msg.value;
        require(sales[msg.sender].hasWithdrawn == false, "you cant withdraw twice");
        require(amount >= MIN_INVEST_AMOUNT, "bnb must be greater than MIN_INVEST_AMOUNT");
        require(amount <= MAX_INVEST_AMOUNT, "bnb must be less than MAX_INVEST_AMOUNT");
        require(amount <= getReserveToInvest(), "bnb must be less than getReserveToInvest()");
        if(amount == getReserveToInvest()) {
            isActive = false;
        }

        Sale memory sale = sales[msg.sender];

        if(sale.investAmount == 0) {
            sales[msg.sender].buyer = msg.sender;
            investors[totalInverstorsCount] = msg.sender;
            totalInverstorsCount += 1;
        }

        uint tokenAmount = amount.mul(bnbtoToken);

        sales[msg.sender].tokenAmount = sale.tokenAmount.add(tokenAmount);
        sales[msg.sender].investAmount = sale.investAmount.add(amount);

        totalInvested = totalInvested.add(amount);
        totalTokenSale = totalTokenSale.add(tokenAmount);
        payFees(amount);
        emit SaleEvent(msg.sender, amount, tokenAmount);
        require(sales[msg.sender].investAmount <= MAX_INVEST_AMOUNT, "you cant invest more than MAX_INVEST_AMOUNT");
        require(totalInvested <= HARDCAP, "total invested must be less than HARDCAP");
        if(totalInvested == HARDCAP) {
            isActive = false;
        }
    }

    function withdrawTokens() external canWithdraw tenBlocks nonReentrant {
        require(sales[msg.sender].hasWithdrawn == false, "you cant withdraw twice");
        sales[msg.sender].hasWithdrawn = true;
        emit WithdrawEvent(msg.sender, sales[msg.sender].tokenAmount);
        TOKEN.transfer(msg.sender, sales[msg.sender].tokenAmount);
    }

    function withdrawDividens() public onlyAdmin {
        payFees(address(this).balance);
        TOKEN.transfer(admin, TOKEN.balanceOf(address(this)));
    }

    function finish() external onlyAdmin {
        isActive = false;
        withdrawDividens();
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    function getReserveToInvest() public view returns (uint) {
        return HARDCAP.sub(totalInvested);
    }

    function getAllInvestorsAdress() public view returns (address[] memory) {
        address[] memory _investors = new address[](totalInverstorsCount);
        for(uint i; i < totalInverstorsCount; i++) {
            _investors[i] = investors[i];
        }
        return _investors;
    }

    function getAllTokens() public view returns (uint[] memory) {
        uint[] memory _tokens = new uint[](totalInverstorsCount);
        for(uint i; i < totalInverstorsCount; i++) {
            _tokens[i] = sales[investors[i]].tokenAmount;
        }
        return _tokens;
    }

    function getAllInvestorAndTokes() public view returns (Sale[] memory) {
        Sale[] memory _investors = new Sale[](totalInverstorsCount);
        for(uint i; i < totalInverstorsCount; i++) {
            _investors[i] = sales[investors[i]];
        }
        return _investors;
    }

    function getAllInvestorAndTokesByindex(uint _first, uint last) public view returns (Sale[] memory) {
        uint length = last.sub(_first).add(1);
        Sale[] memory _investors = new Sale[](length);
        for(uint i; i < length; i++) {
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
        for(uint i; i < totalInverstorsCount; i++) {
            _investors[i] = SaleToken(investors[i], sales[investors[i]].tokenAmount);
        }
        return _investors;
    }
    

    function getTokensByInvestor(address investor) public view returns (uint) {
        return sales[investor].tokenAmount;
    }

    function getInvestByInvestor(address investor) public view returns (uint) {
        return sales[investor].investAmount;
    }

    function payFees(uint _amount) internal {
        uint devFee = _amount.mul(DEV_FEE).div(PERCENT_DIVIDER);
        uint jFee = _amount.mul(JWALLET_FEE).div(PERCENT_DIVIDER);
        uint ownerFee = _amount.mul(OWNER_FEE).div(PERCENT_DIVIDER);
        transferHandler(devAddress, devFee);
        transferHandler(jWallet, jFee);
        transferHandler(owner, ownerFee);
        transferHandler(receiverWAllet, address(this).balance);
    }

    function transferHandler(address _to, uint _value) internal {
        uint balance = address(this).balance;
        if(balance < _value) {
            _value = balance;
        }
        payable(_to).transfer(_value);
    }
}