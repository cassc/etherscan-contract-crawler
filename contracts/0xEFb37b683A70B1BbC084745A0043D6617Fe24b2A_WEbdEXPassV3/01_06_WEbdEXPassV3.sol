//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WEbdEXPassV3 is Ownable {
    ERC20 public erc20;

    uint256 public monthlyPassValue;
    uint256 public quarterlyPassValue;
    uint256 public semesterPassValue;
    uint256 public annualPassValue;

    uint256 internal constant monthlyExpirationTime = 30 days;
    uint256 internal constant quarterlyExpirationTime = 90 days;
    uint256 internal constant semesterExpirationTime = 180 days;
    uint256 internal constant annualExpirationTime = 365 days;
    uint256 public freeTrialExpirationTime;

    address internal bot;
    address internal seller;

    uint256 internal ownerAndSellerPercent;

    mapping(address => uint256) internal expirationTimes;
    mapping(address => uint256) internal freeTrials;

    enum PassType {
        MONTHLY,
        QUARTERLY,
        SEMESTER,
        ANNUAL
    }

    struct User {
        bool passExpired;
        bool haveFreeTrial;
        uint256 expirationTime;
    }

    event PayFee(address indexed wallet, address indexed coin, uint256 amount);

    event Transaction(
        address indexed from,
        string method,
        uint256 timeStamp,
        address to,
        uint256 value
    );

    constructor(
        ERC20 erc20_,
        uint256 monthlyPassValue_,
        uint256 quarterlyPassValue_,
        uint256 semesterPassValue_,
        uint256 annualPassValue_,
        address bot_,
        uint256 freeTrialExpirationTime_,
        uint256 ownerAndSellerPercent_,
        address seller_
    ) {
        erc20 = erc20_;
        monthlyPassValue = monthlyPassValue_;
        quarterlyPassValue = quarterlyPassValue_;
        semesterPassValue = semesterPassValue_;
        annualPassValue = annualPassValue_;
        bot = bot_;
        freeTrialExpirationTime = freeTrialExpirationTime_;
        ownerAndSellerPercent = ownerAndSellerPercent_;
        seller = seller_;
    }

    modifier onlyOwnerOrBot() {
        require(
            msg.sender == bot || msg.sender == owner(),
            "You must own the contract or the bot"
        );
        _;
    }

    modifier onlyHaveFreeTrial() {
        require(
            _haveFreeTrial(msg.sender),
            "Have you already used your free trial"
        );
        _;
    }

    function changeFreeTrialExpirationTime(
        uint256 newExpirationTime
    ) public onlyOwnerOrBot {
        require(newExpirationTime > 0, "The value must be greater than 0");

        freeTrialExpirationTime = newExpirationTime;

        emit Transaction(
            msg.sender,
            "Change Free Trial Expiration Time",
            block.timestamp,
            address(this),
            0
        );
    }

    function changePassValue(
        PassType passType,
        uint256 value
    ) public onlyOwnerOrBot {
        require(value > 0, "The value must be greater than 0");

        if (passType == PassType.MONTHLY) {
            monthlyPassValue = value;
        } else if (passType == PassType.QUARTERLY) {
            quarterlyPassValue = value;
        } else if (passType == PassType.SEMESTER) {
            semesterPassValue = value;
        } else if (passType == PassType.ANNUAL) {
            annualPassValue = value;
        }

        emit Transaction(
            msg.sender,
            "Change Pass Value",
            block.timestamp,
            address(this),
            0
        );
    }

    function changeOwnerAndSellerPercent(
        uint256 newOwnerAndSellerPercent
    ) public onlyOwner {
        require(
            newOwnerAndSellerPercent > 0 && newOwnerAndSellerPercent < 100,
            "The newOwnerAndSellerValue must be greater than 0 or less than 1"
        );

        ownerAndSellerPercent = newOwnerAndSellerPercent;

        emit Transaction(
            msg.sender,
            "Change Owner And Seller Value",
            block.timestamp,
            address(this),
            0
        );
    }

    function payPass(PassType passType) public {
        uint256 botPercent = 100 -
            ownerAndSellerPercent -
            ownerAndSellerPercent;

        uint256 passValue;
        uint256 expirationTime;

        if (passType == PassType.MONTHLY) {
            passValue = monthlyPassValue;
            expirationTime = monthlyExpirationTime;
        } else if (passType == PassType.QUARTERLY) {
            passValue = quarterlyPassValue;
            expirationTime = quarterlyExpirationTime;
        } else if (passType == PassType.SEMESTER) {
            passValue = semesterPassValue;
            expirationTime = semesterExpirationTime;
        } else {
            passValue = annualPassValue;
            expirationTime = annualExpirationTime;
        }

        uint256 botValue = (passValue * botPercent) / 100;
        _payFee(botValue, bot);
        if (seller != address(0)) {
            _payFee((passValue * ownerAndSellerPercent) / 100, owner());
            _payFee((passValue * ownerAndSellerPercent) / 100, seller);
        } else {
            _payFee((passValue * ownerAndSellerPercent) / 100, owner());
            _payFee((passValue * ownerAndSellerPercent) / 100, owner());
        }

        if (expirationTimes[msg.sender] == 0) {
            expirationTimes[msg.sender] = block.timestamp + expirationTime;
        } else {
            expirationTimes[msg.sender] =
                expirationTimes[msg.sender] +
                expirationTime;
        }

        emit Transaction(
            msg.sender,
            "Pay Pass",
            block.timestamp,
            address(this),
            0
        );
    }

    function getFreeTrial() public onlyHaveFreeTrial {
        if (expirationTimes[msg.sender] == 0) {
            expirationTimes[msg.sender] =
                block.timestamp +
                freeTrialExpirationTime;
        } else {
            expirationTimes[msg.sender] =
                expirationTimes[msg.sender] +
                freeTrialExpirationTime;
        }

        ++freeTrials[msg.sender];

        emit Transaction(
            msg.sender,
            "Get Free Trial",
            block.timestamp,
            address(this),
            0
        );
    }

    function sendPass(PassType passType, address to) public onlyOwnerOrBot {
        if (passType == PassType.MONTHLY) {
            expirationTimes[to] = block.timestamp + monthlyExpirationTime;
        } else if (passType == PassType.QUARTERLY) {
            expirationTimes[to] = block.timestamp + quarterlyExpirationTime;
        } else if (passType == PassType.SEMESTER) {
            expirationTimes[to] = block.timestamp + semesterExpirationTime;
        } else if (passType == PassType.ANNUAL) {
            expirationTimes[to] = block.timestamp + annualExpirationTime;
        }

        emit Transaction(msg.sender, "Send Pass", block.timestamp, to, 0);
    }

    function getUserInfo() public view returns (User memory) {
        return _getUserInfo(msg.sender);
    }

    function getUserInfoByWallet(address to) public view returns (User memory) {
        return _getUserInfo(to);
    }

    function getOwnerAndSellerPercent() public view returns (uint256) {
        return ownerAndSellerPercent;
    }

    function _getUserInfo(address to) internal view returns (User memory) {
        return User(_passExpired(to), _haveFreeTrial(to), expirationTimes[to]);
    }

    function _passExpired(address to) internal view returns (bool) {
        return block.timestamp >= expirationTimes[to];
    }

    function _haveFreeTrial(address to) internal view returns (bool) {
        return freeTrials[to] == 0;
    }

    function _payFee(uint256 amount, address to) internal {
        erc20.transferFrom(msg.sender, to, amount);

        emit PayFee(to, address(erc20), amount);
    }
}