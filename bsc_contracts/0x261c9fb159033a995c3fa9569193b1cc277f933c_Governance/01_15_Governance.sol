// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IterableMapping.sol";
import "./Interface/ILoan.sol";
import "./Interface/ILoanDeployer.sol";
import "hardhat/console.sol";


struct LoanAccept {
    address loan;
    uint256 acceptId;
}

struct CreatedLoanStruct {
    address token;
    uint256 tokenAmount;
    uint8 duration;
    uint8 paymentPeriod;
    uint8 aPRInerestRate;
    address owner;
    uint8 status; // "activated - 2, canceled - 0, pending - 1"
    address loan;
    uint256 availableAmount;
}

struct AcceptedLoanStruct {
    address token;
    uint256 acceptId;
    uint256 tokenAmount;
    uint8 duration;
    uint8 paymentPeriod;
    uint8 aPRInerestRate;
    address owner;
    uint8 status; // "activated - 2, canceled - 0, pending - 1"
    address loan;
    uint256 availableAmount;
}

contract Governance is UUPSUpgradeable, OwnableUpgradeable {

    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private lenderWhiteList;
    IterableMapping.Map private borrowerWhiteList;
    IterableMapping.Map private blackList;

    mapping(address=>address[]) public loanList;
    mapping(address=>LoanAccept[]) public borrowedLoanList;

    mapping(address=>uint256) public creditAmount;

    mapping(address=>uint256) public borrowedAmount;

    address public teamWallet;

    address[] public loanArray;

    address public loanDeployer;

    event CreatedLoan(address indexed account, address indexed loan);
    event AcceptedLoan(address indexed account, address indexed loan, uint256 acceptId, uint256 borrowAmount, uint256 timeStamp);
    

    function initialize (address _teamWallet) public initializer
    {
        __Ownable_init();
        teamWallet = _teamWallet;
    }

    function _authorizeUpgrade(address newImplementaion) internal override onlyOwner {}

    modifier onlyWhiteListedLender() {
        require(lenderWhiteList.get(msg.sender) > 0, "Caller is not whitlisted lender");
        _;
    }

    modifier onlyWhiteListedBorrower() {
        require(borrowerWhiteList.get(msg.sender) > 0, "Caller is not whitlisted borrower");
        _;
    }

    modifier notBlackListed() {
        require(blackList.get(msg.sender) == 0, "Caller is in blacklist");
        _;
    }

    function whitelistLender(address _account) public onlyOwner {
        lenderWhiteList.set(_account, 1);
    }

    function whitelistBorrower(address _account, uint256 _limit) public onlyOwner {
        borrowerWhiteList.set(_account, 1);
        creditAmount[_account] = _limit;
    }

    function blackListUser(address _account) public onlyOwner {
        blackList.set(_account, 1);
    }

    function isWhitelistedLender(address _account) public view returns (bool) {
        return lenderWhiteList.get(_account) == 1;
    }

    function isWhitelistedBorrower(address _account) public view returns (bool) {
        return borrowerWhiteList.get(_account) == 1;
    }

    function isBlacklistedUser(address _account) public view returns (bool) {
        return blackList.get(_account) == 1;
    }

    function createLoan(
        address _tokenAddress,
        uint256 _tokenAmount,
        uint64 _duration,
        uint64 _paymentPeriod,
        uint8 _interestRate
    ) public onlyWhiteListedLender notBlackListed {

        uint256 tokenAllowance = IERC20(_tokenAddress).allowance(msg.sender, address(this));
        require(tokenAllowance >= _tokenAmount, "Token allownce is not enough!");

        address loan = ILoanDeployer(loanDeployer).createLoan(
            msg.sender, 
            _tokenAddress, 
            _tokenAmount, 
            _duration, 
            _paymentPeriod, 
            _interestRate, 
            teamWallet);
            
        IERC20(_tokenAddress).transferFrom(msg.sender, loan, _tokenAmount);

        loanList[msg.sender].push(loan);
        loanArray.push(loan);

        emit CreatedLoan(msg.sender, loan);

    }

    function getOwnedLoanListOfUser(address _account) public view returns (CreatedLoanStruct[] memory){

        uint256 i = 0;
        CreatedLoanStruct[] memory loans = new CreatedLoanStruct[](loanList[_account].length);
        uint256 aI = 0;
        while(i < loanList[_account].length){
            ILoan loan = ILoan(loanList[_account][i]);
            loans[aI].loan = address(loan);
            loans[aI].token = loan.token();
            loans[aI].availableAmount = IERC20(loan.token()).balanceOf(address(loan));
            loans[aI].tokenAmount = loan.tokenAmount();
            loans[aI].duration = loan.duration();
            loans[aI].paymentPeriod = loan.paymentPeriod();
            loans[aI].aPRInerestRate = loan.aPRInerestRate();
            loans[aI].owner = loan.owner();
            loans[aI].status = loan.status();
            i++;
            aI++;
        }
        return loans;
    }

    function getBorrowedLoanListOfUser(address _account) public view returns (AcceptedLoanStruct[] memory){

        uint256 i = 0;
        AcceptedLoanStruct[] memory loans = new AcceptedLoanStruct[](borrowedLoanList[_account].length);
        uint256 aI = 0;
        while(i < borrowedLoanList[_account].length){
            ILoan loan = ILoan(borrowedLoanList[_account][i].loan);
            loans[aI].acceptId = borrowedLoanList[_account][i].acceptId;
            loans[aI].loan = address(loan);
            loans[aI].token = loan.token();
            loans[aI].availableAmount = IERC20(loan.token()).balanceOf(address(loan));
            loans[aI].tokenAmount = loan.tokenAmount();
            loans[aI].duration = loan.duration();
            loans[aI].paymentPeriod = loan.paymentPeriod();
            loans[aI].aPRInerestRate = loan.aPRInerestRate();
            loans[aI].owner = loan.owner();
            loans[aI].status = loan.status();
            i++;
            aI++;
        }
        return loans;
    }

    function updateCreditAmountOfUser(address _account, uint256 _creditAmount) public onlyOwner {
        creditAmount[_account] = _creditAmount;
    }

    function accept(address _loan, uint256 _borrowAmount) public onlyWhiteListedBorrower notBlackListed {

        address token = ILoan(_loan).token();
        uint256 creditTokenAmount = creditAmount[msg.sender];
        // require(borrowerWhiteList.get(msg.sender) >= _borrowAmount, "Caller exceed limit amount");
        require(borrowedLoanList[msg.sender].length <= 10, "Caller exceed his available loans");
        require(creditTokenAmount >= _borrowAmount, "Caller does not have enough credit amount!");
        require(IERC20(token).balanceOf(_loan) >= _borrowAmount, "Loan does not have enough tokens left!");

        creditAmount[msg.sender] = creditAmount[msg.sender] - _borrowAmount;

        uint256 acceptIndex = ILoan(_loan).getAcceptLoanMapLengthOf(msg.sender);
        ILoan(_loan).accept(msg.sender, _borrowAmount);
        borrowedAmount[msg.sender] = borrowedAmount[msg.sender] + _borrowAmount;

        borrowedLoanList[msg.sender].push(LoanAccept({acceptId: acceptIndex, loan:_loan }));

        emit AcceptedLoan(msg.sender, _loan, acceptIndex, _borrowAmount, block.timestamp);
        
    }

    function upateTeamWallet(address _teamWallet) public onlyOwner {
        require(teamWallet != _teamWallet, "Same value already!");
        teamWallet = _teamWallet;
    }

    function getLimitAmountOf(address _acount) public view returns (uint256){
        return borrowerWhiteList.get(_acount);
    }

    function getLoanList(uint256 fromIndex, uint256 limit) public view returns ( CreatedLoanStruct[] memory ) {

        require(limit > 0, "no limit is set");
        
        uint256 i = fromIndex;
        uint256 toIndex = fromIndex + limit;
        if(toIndex > loanArray.length) toIndex = loanArray.length;
        CreatedLoanStruct[] memory loans = new CreatedLoanStruct[](toIndex - fromIndex);
        uint256 aI = 0;
        while(i < toIndex){
            ILoan loan = ILoan(loanArray[i]);
            loans[aI].loan = address(loan);
            loans[aI].token = loan.token();
            loans[aI].availableAmount = IERC20(loan.token()).balanceOf(address(loan));
            loans[aI].tokenAmount = loan.tokenAmount();
            loans[aI].duration = loan.duration();
            loans[aI].paymentPeriod = loan.paymentPeriod();
            loans[aI].aPRInerestRate = loan.aPRInerestRate();
            loans[aI].owner = loan.owner();
            loans[aI].status = loan.status();
            i++;
            aI++;
        }
        return loans;
    }

    function isWhiteListedLender() public view returns (bool) {
        return lenderWhiteList.get(msg.sender) > 0;
    }

    function isWhiteListedBorrower() public view returns (uint256) {
        return borrowerWhiteList.get(msg.sender);
    }

    function isBlackListed() public view returns (bool) {
        return blackList.get(msg.sender) != 0;
    }

    function setLoanDeployer(address _loanDeployer) public onlyOwner {
        require(loanDeployer != _loanDeployer, "same value");
        loanDeployer = _loanDeployer;
    }
}