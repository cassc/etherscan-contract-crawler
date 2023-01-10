// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./PrivateSaleUpgradeable.sol";
import "hardhat/console.sol";

contract StakingSimple8FUpgradeable is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    address public tokenAddress;
    uint256 public fullTime;
    uint256 public resultRate; // годовой процент (сразу с 10 ** 18)

    function initialize(
        address _tokenAddress,
        uint256 _fulltime
    ) initializer public {
        __ERC20_init("8.Finance Staking", "8FS");
        __Ownable_init();
        tokenAddress = _tokenAddress;
        fullTime = _fulltime;
    }

    struct Payment {
        address account;
        uint256 amount;
        uint timestamp;
        uint256 withdrawed;
        bool stakeFilling;
        bool bodyWithdraw;
        uint256 nftTokenId;
    }

    Payment[] payments;
    address public PSAddress;
    address public NFTAddress;

    mapping(uint256 => uint256) public nftTime;
    uint256 public cliffClaimBody;
    uint256 public resultRateNft;

    function getPayment(address account) public view returns (Payment[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < payments.length; i++) {
            Payment memory payment = payments[i];
            if (payment.account == account) {
                count++;
            }
        }

        Payment[] memory _tokensOfOwner = new Payment[](count);
        uint256 addedPayments = 0;
        for (uint256 i = 0; i < payments.length; i++) {
            Payment memory payment = payments[i];
            if (payment.account == account) {
                _tokensOfOwner[addedPayments] = payment;
                addedPayments++;
            }
        }

        return _tokensOfOwner;

    }

    function stake(uint256 amount) public {
        (bool s,) = tokenAddress.call(abi.encodeWithSelector(bytes4(keccak256(bytes('transferFrom(address,address,uint256)'))), tx.origin, address(this), amount));
        require(s, "transfer error");

        Payment memory newPayment = Payment(
            tx.origin,
            amount,
            block.timestamp,
            0,
            false,
            false,
            0
        );
        payments.push(newPayment);
    }

    function stakingBalance() public view returns (uint256 allowStake) {
        allowStake = ERC20Upgradeable.balanceOf(address(this));
    }

    function bankBalance() public view onlyOwner returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < payments.length; i++) {
            if (payments[i].stakeFilling) {
                result += payments[i].amount;
            }
            if (payments[i].withdrawed > 0 && !payments[i].bodyWithdraw) {
                result += payments[i].amount;
            }
        }
        return result;
    }

    function getFullAmount(address account) public view returns (uint256 fullAmount, uint256 timestamp) {
        timestamp = block.timestamp;
        uint256 prevAmount = 0;
        uint256 neededAccountAmount = 0;
        uint256 prevTxTimestamp = payments[0].timestamp;
        uint256 rewardRatePerSecond = resultRate / fullTime;
        uint256 decimalsDelimiter = 10 ** decimals();
        uint256 stakenAmount = 0;
        console.log("In the begin info: %s %s %s", rewardRatePerSecond, resultRate, fullTime);
        for (uint256 i = 0; i < payments.length; i++) {
            Payment memory payment = payments[i];
            uint256 secondsPassed = payment.timestamp - prevTxTimestamp;
            uint256 increaseValue = secondsPassed * rewardRatePerSecond * neededAccountAmount;
            fullAmount += increaseValue / decimalsDelimiter;

            if (payment.account == account && payment.nftTokenId == 0) {
                console.log("filling needed account amount +: %s -: %s", payment.amount, payment.withdrawed);
                neededAccountAmount += payment.amount;
                prevAmount += payment.amount - payment.withdrawed;
                prevTxTimestamp = payment.timestamp;
            }

            console.log("Payment iterate: %s %s %s", i, payment.account, payment.amount);
            console.log("Current percent of amount: %s %s %s", payment.account, neededAccountAmount, prevAmount);
            console.log("1 %s %s %s",fullTime,payment.account, stakenAmount);
            console.log("2 %s %s %s",secondsPassed,prevTxTimestamp,prevAmount);
            console.log("Before increase checks: %s %s", stakenAmount);
        }
        if (prevAmount != 0) {
            console.log("In the end info: %s %s %s", timestamp, prevTxTimestamp, prevAmount);
            uint256 addAmount = (timestamp - prevTxTimestamp) * rewardRatePerSecond * prevAmount / decimalsDelimiter;
            console.log("In the end info 2: %s %s %s", addAmount, fullAmount, prevTxTimestamp);
            fullAmount+= addAmount;
        }
    }

    function changeFullTime(uint256 time) public onlyOwner {
        fullTime = time;
    }

    function claimMyStake () public {
        (uint256 fullAmount,) = getFullAmount(tx.origin);
        require(fullAmount != 0, "Nothing to claim");
        (bool status, ) = tokenAddress.call(abi.encodeWithSelector(bytes4(keccak256(bytes('transfer(address,uint256)'))), tx.origin, fullAmount));
        require (status, 'transfer error');
        Payment memory newPayment = Payment(
            tx.origin,
            0,
            block.timestamp,
            fullAmount,
            false,
            false,
            0
        );
        payments.push(newPayment);
    }

    function setTokenContract (address _tokenAddress) public {
        tokenAddress = _tokenAddress;
    }

    function claimMyBody (uint256 amount) public {
        uint256 fullAmount = 0;
        for (uint256 i = 0; i < payments.length; i++) {
            Payment memory payment = payments[i];
            if (payment.account == tx.origin && block.timestamp - payment.timestamp > cliffClaimBody) {
                fullAmount += payment.amount;
            }
        }
        require(fullAmount != 0, "Nothing to claim");
        require(fullAmount > amount, "Can't withdraw more than available to claim body");
        (bool status, ) = tokenAddress.call(abi.encodeWithSelector(bytes4(keccak256(bytes('transfer(address,uint256)'))), tx.origin, amount));
        require (status, 'transfer error');
        Payment memory newPayment = Payment(
            tx.origin,
            0,
            block.timestamp,
            amount,
            false,
            true,
            0
        );
        payments.push(newPayment);
    }

    function setResultRate(uint256 _resultRate) public onlyOwner {
        resultRate = _resultRate;
    }

    function stakeNft(uint256 tokenId, uint256 time) public {
        address ownerOfNft = PrivateSaleNft8FContractV1(NFTAddress).fullOwnerOf(tokenId);
        require(ownerOfNft == address(tx.origin));
        PrivateSale8FUpgradeableV2.Payment memory payment = PrivateSale8FUpgradeableV2(PSAddress).getPayment(tokenId);
        require (!PrivateSale8FUpgradeableV2(PSAddress).isOpened(tokenId), "Your token is not transferable now! It is opened");
        require(payment.withdrawed == 0);
        require(payment.tokensAmount > 0);
        uint256 amount = payment.tokensAmount;
        PrivateSale8FUpgradeableV2(PSAddress).stakeNft(tokenId);
        Payment memory newPayment = Payment(
            tx.origin,
            amount,
            block.timestamp,
            0,
            false,
            false,
            tokenId
        );
        nftTime[tokenId] = time;
        payments.push(newPayment);
    }

    function getPaymentForNft(uint256 tokenId) public view returns (Payment memory pay) {
        for (uint256 i = 0; i < payments.length; i++) {
            Payment memory payment = payments[i];
            if (payment.nftTokenId == tokenId) {
                pay = payment;
            }
        }
    }

    function setPSAddress(address _PSAddress) public onlyOwner {
        PSAddress = _PSAddress;
    }

    function setNFTAddress(address _NFTAddress) public onlyOwner {
        NFTAddress = _NFTAddress;
    }

    function getFullAmountForNft(uint256 tokenId) public view returns (uint256 fullAmount, uint256 timestamp) {
        timestamp = block.timestamp;
        uint256 prevAmount = 0;
        uint256 neededAccountAmount = 0;
        uint256 prevTxTimestamp = payments[0].timestamp;
        uint256 rewardRatePerSecond = resultRateNft / nftTime[tokenId];
        uint256 decimalsDelimiter = 10 ** decimals();
        uint256 stakenAmount = 0;
        console.log("In the begin info: %s %s %s", rewardRatePerSecond, resultRateNft, nftTime[tokenId]);
        for (uint256 i = 0; i < payments.length; i++) {
            Payment memory payment = payments[i];
            uint256 secondsPassed = payment.timestamp - prevTxTimestamp;
            uint256 increaseValue = secondsPassed * rewardRatePerSecond * neededAccountAmount;
            fullAmount += increaseValue / decimalsDelimiter;

            if (payment.nftTokenId == tokenId) {
                console.log("filling needed account amount +: %s -: %s", payment.amount, payment.withdrawed);
                neededAccountAmount += payment.amount;
                prevAmount += payment.amount - payment.withdrawed;
                prevTxTimestamp = payment.timestamp;
            }

            console.log("Payment iterate: %s %s %s", i, payment.account, payment.amount);
            console.log("Current percent of amount: %s %s %s", payment.account, neededAccountAmount, prevAmount);
            console.log("1 %s %s %s",fullTime,payment.account, stakenAmount);
            console.log("2 %s %s %s",secondsPassed,prevTxTimestamp,prevAmount);
            console.log("Before increase checks: %s %s", stakenAmount);
        }
        if (prevAmount != 0) {
            console.log("In the end info: %s %s %s", timestamp, prevTxTimestamp, prevAmount);
            uint256 addAmount = (timestamp - prevTxTimestamp) * rewardRatePerSecond * prevAmount / decimalsDelimiter;
            console.log("In the end info 2: %s %s %s", addAmount, fullAmount, prevTxTimestamp);
            fullAmount+= addAmount;
        }
    }

    function claimMyStakeNft (uint256 tokenId) public {
        (uint256 fullAmount,) = getFullAmountForNft(tokenId);
        require(fullAmount != 0, "Nothing to claim");
        (bool status, ) = tokenAddress.call(abi.encodeWithSelector(bytes4(keccak256(bytes('transfer(address,uint256)'))), tx.origin, fullAmount));
        require (status, 'transfer error');
        Payment memory newPayment = Payment(
            tx.origin,
            0,
            block.timestamp,
            fullAmount,
            false,
            false,
            tokenId
        );
        payments.push(newPayment);
    }

    function setResultRateNft(uint256 _resultRateNft) public onlyOwner {
        resultRateNft = _resultRateNft;
    }

    function claimMyBodyNft (uint256 tokenId) public {
        uint256 fullAmount = 0;
        for (uint256 i = 0; i < payments.length; i++) {
            Payment memory payment = payments[i];
            if (payment.nftTokenId == tokenId && payment.account == tx.origin && block.timestamp - payment.timestamp > cliffClaimBody) {
                fullAmount += payment.amount;
            }
        }
        require(fullAmount != 0, "Nothing to claim from this NFT");
        (bool status, ) = tokenAddress.call(abi.encodeWithSelector(bytes4(keccak256(bytes('transfer(address,uint256)'))), tx.origin, fullAmount));
        require (status, 'transfer error');
        Payment memory newPayment = Payment(
            tx.origin,
            0,
            block.timestamp,
            fullAmount,
            false,
            true,
            tokenId
        );
        payments.push(newPayment);
    }

    function getMyBody() public view returns(uint256 result) {
        for (uint256 i = 0; i < payments.length; i++) {
            Payment memory payment = payments[i];
            if (payment.account == tx.origin && !payment.bodyWithdraw) {
                result += payment.amount;
            }
            if (payment.account == tx.origin && payment.bodyWithdraw) {
                result -= payment.withdrawed;
            }
        }
    }
}