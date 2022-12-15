// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IToken} from "./interfaces/IToken.sol";
import {IUser} from "./interfaces/IUser.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract PrivateSale is Ownable, Pausable {
    using SafeMath for uint256;

    IERC20 public token = IERC20(0x40Da12c9fc564fc3c3692EE03802bCD82d85c1B6);
    IERC20 public paymentToken =
        IERC20(0x55d398326f99059fF775485246999027B3197955);

    address public receiver;
    address public otherInvestmentContract;
    address public userContract = 0x76726f3130b71dAdA2fF0617fcdf138b9c5B7E0E;

    uint256 public constant ROUND = 1;
    uint256 public totalSupply = 20000000000000000000000000;
    uint256 public totalSell = 0;
    uint256 public tokenPriceRate = 15000000000000000; // 0.015
    uint256 public minBuy = 10000000000000000000; // $10
    uint256 public openSale = 1675987200; // 2023-02-10 00:00:00
    uint256 public endSale = 1676678399; // 2022-02-17 23:59:59
    uint256 public timeTGE = 9999999999;
    uint256 public startUnlock = 9999999999;
    uint256 public timePeriod = 2592000; // 30 days
    uint256 public tgeUnlock = 15; // 15%
    uint256 public receivePercentage = 425; // 4.25%
    uint256 public divPercentage = 1e4;
    uint256[] public refReward = [5, 3, 2];

    mapping(address => uint256) public userLockDetail;
    mapping(address => uint256) public userTotalPayment;

    constructor() {
        receiver = msg.sender;
    }

    function buy(uint256 _paymentAmount) public whenNotPaused {
        require(
            totalBuy(msg.sender) + _paymentAmount >= minBuy,
            "limit min buy token"
        );
        require(
            block.timestamp >= openSale && block.timestamp <= endSale,
            "can not buy at this time"
        );

        // check balance payment token before buy token
        require(
            paymentToken.balanceOf(msg.sender) >= _paymentAmount,
            "your balance not enough"
        );

        uint256 totalToken = _paymentAmount.mul(1e18).div(tokenPriceRate);
        require(
            token.balanceOf(address(this)) >= totalToken,
            "contract not enough balance"
        );

        address _ref = IUser(userContract).getRef(msg.sender);
        uint256 remains = _paymentAmount;
        if (_ref != address(0)) {
            paymentToken.transferFrom(
                msg.sender,
                _ref,
                _paymentAmount.mul(refReward[0]).div(100)
            );
            remains = remains.sub(_paymentAmount.mul(refReward[0]).div(100));
            address ref = IUser(userContract).getRef(_ref);
            for (uint256 i = 1; i < refReward.length; i++) {
                if (ref != address(0)) {
                    // transfer reward to Fn
                    paymentToken.transferFrom(
                        msg.sender,
                        ref,
                        _paymentAmount.mul(refReward[i]).div(100)
                    );
                    remains = remains.sub(
                        _paymentAmount.mul(refReward[i]).div(100)
                    );
                    ref = IUser(userContract).getRef(ref);
                }
            }
        }

        // update lock detail
        userLockDetail[msg.sender] = userLockDetail[msg.sender].add(totalToken);
        // transfer token to buyer
        token.transfer(msg.sender, totalToken);
        // transfer payment token to receiver
        paymentToken.transferFrom(msg.sender, receiver, remains);
        // update total user buy
        userTotalPayment[msg.sender] = userTotalPayment[msg.sender].add(
            _paymentAmount
        );
        totalSell = totalSell.add(totalToken);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function totalBuy(address _wallet) public view returns (uint256) {
        return userTotalPayment[_wallet];
    }

    function getITransferInvestment(
        address _wallet
    ) external view returns (uint256) {
        uint256 totalLock = 0;
        if (otherInvestmentContract != address(0)) {
            totalLock = totalLock.add(
                IToken(otherInvestmentContract).getITransferInvestment(_wallet)
            );
        }
        totalLock = totalLock.add(userLockDetail[_wallet]);

        // unlock at TGE
        if (block.timestamp >= timeTGE) {
            totalLock = totalLock.sub(
                userLockDetail[_wallet].div(100).mul(tgeUnlock)
            );
        }
        if (block.timestamp >= startUnlock) {
            uint256 unlockAmount = userLockDetail[_wallet]
                .mul(receivePercentage)
                .div(divPercentage)
                .mul(block.timestamp.sub(startUnlock).div(timePeriod));
            if (unlockAmount > 0) {
                totalLock = unlockAmount >= totalLock
                    ? 0
                    : totalLock.sub(unlockAmount);
            }
        }
        return totalLock;
    }

    function setOtherInvestmentContract(
        address _otherInvestmentContract
    ) public onlyOwner {
        otherInvestmentContract = _otherInvestmentContract;
    }

    function setUserContract(address _userContract) public onlyOwner {
        userContract = _userContract;
    }

    function setReceiver(address _receiver) public onlyOwner {
        receiver = _receiver;
    }

    function setTokenPriceRate(uint256 _rate) public onlyOwner {
        tokenPriceRate = _rate;
    }

    function setDivPercentage(uint256 _divPercentage) public onlyOwner {
        divPercentage = _divPercentage;
    }

    function setTimeTGE(uint256 _time) public onlyOwner {
        timeTGE = _time;
    }

    function setStartUnlock(uint256 _time) public onlyOwner {
        startUnlock = _time;
    }

    function setTimePeriod(uint256 _time) public onlyOwner {
        timePeriod = _time;
    }

    function setOpenEndSale(uint256 _open, uint256 _end) public onlyOwner {
        openSale = _open;
        endSale = _end;
    }

    function setMinBuy(uint256 _min) public onlyOwner {
        minBuy = _min;
    }

    function setTotalSupply(uint256 _number) public onlyOwner {
        totalSupply = _number;
    }

    function setPaymentToken(address _paymentToken) public onlyOwner {
        paymentToken = IERC20(_paymentToken);
    }

    function setToken(address _token) public onlyOwner {
        token = IERC20(_token);
    }

    /**
	Clear unknow token
	*/
    function clearUnknownToken(address _tokenAddress) public onlyOwner {
        uint256 contractBalance = IERC20(_tokenAddress).balanceOf(
            address(this)
        );
        IERC20(_tokenAddress).transfer(address(msg.sender), contractBalance);
    }

    /**
	Withdraw bnb
	*/
    function withdraw(address _to) public onlyOwner {
        require(_to != address(0), "Presale: wrong address withdraw");
        uint256 amount = address(this).balance;
        payable(_to).transfer(amount);
    }
}