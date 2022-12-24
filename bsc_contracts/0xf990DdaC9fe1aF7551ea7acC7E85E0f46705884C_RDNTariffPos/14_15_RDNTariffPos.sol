pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import {IRDNRegistry} from "./interfaces/IRDNRegistry.sol";
import {IRDNDistributor} from "./interfaces/IRDNDistributor.sol";
import {WithdrawAnyERC20Token} from "../Utils/WithdrawAnyERC20Token.sol";

contract RDNTariffPos is
    Context,
    AccessControlEnumerable,
    WithdrawAnyERC20Token
{

    event Turnover(
        uint indexed userId,
        address indexed token,
        uint turnoverAmount,
        uint normalizedTurnover
    );

    event RDNSubscriptionBonus(
        uint indexed userId,
        address indexed userAddress,
        uint bonusAmount
    );

    IERC20 public immutable token1;
    IERC20 public immutable token2;
    IRDNRegistry public immutable registry;

    mapping(uint => uint[2]) public tariffPrices;
    mapping(uint => mapping(uint => uint)) public subscriptionPackagePrices;
    uint public defaultSubscriptionPeriod = 30 * 24 * 60 * 60;
    uint public reward = 4800;
    mapping(uint => uint[2]) public usersPaid;

    mapping(uint => uint) public bonusCounter;
    mapping (uint => uint) public bonusAmountPerTariff;
    mapping (uint => bool) public bonusCandidatesExcluded;
    uint public bonusCandidatesCounter;
    uint public bonusCandidatesLimit;
    uint public bonusCandidatesLimitRDN;
    uint public bonusRequirement;

    bool public token2Points;

    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

    constructor(
        address _token1,
        address _token2,
        address _registry,
        address _admin
    ) WithdrawAnyERC20Token(_admin, false) {
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
        registry = IRDNRegistry(_registry);

        token2Points = false;

        tariffPrices[1] = [150 ether, 0];
        tariffPrices[2] = [300 ether, 3 ether];
        tariffPrices[3] = [600 ether, 6 ether];
        tariffPrices[4] = [900 ether, 12 ether];
        tariffPrices[5] = [1200 ether, 15 ether];
        tariffPrices[6] = [1500 ether, 21 ether];
        tariffPrices[7] = [1800 ether, 24 ether];

        subscriptionPackagePrices[1][30] = 24 ether;
        subscriptionPackagePrices[1][90] = 72 ether;
        subscriptionPackagePrices[1][180] = 144 ether;
        subscriptionPackagePrices[1][360] = 288 ether;

        subscriptionPackagePrices[2][30] = 42 ether;
        subscriptionPackagePrices[2][90] = 126 ether;
        subscriptionPackagePrices[2][180] = 252 ether;
        subscriptionPackagePrices[2][360] = 504 ether;

        subscriptionPackagePrices[3][30] = 42 ether;
        subscriptionPackagePrices[3][90] = 126 ether;
        subscriptionPackagePrices[3][180] = 252 ether;
        subscriptionPackagePrices[3][360] = 504 ether;

        subscriptionPackagePrices[4][30] = 42 ether;
        subscriptionPackagePrices[4][90] = 126 ether;
        subscriptionPackagePrices[4][180] = 252 ether;
        subscriptionPackagePrices[4][360] = 504 ether;

        subscriptionPackagePrices[5][30] = 42 ether;
        subscriptionPackagePrices[5][90] = 126 ether;
        subscriptionPackagePrices[5][180] = 252 ether;
        subscriptionPackagePrices[5][360] = 504 ether;

        subscriptionPackagePrices[6][30] = 42 ether;
        subscriptionPackagePrices[6][90] = 126 ether;
        subscriptionPackagePrices[6][180] = 252 ether;
        subscriptionPackagePrices[6][360] = 504 ether;

        subscriptionPackagePrices[7][30] = 42 ether;
        subscriptionPackagePrices[7][90] = 126 ether;
        subscriptionPackagePrices[7][180] = 252 ether;
        subscriptionPackagePrices[7][360] = 504 ether;

        bonusAmountPerTariff[1] = 12 ether;
        bonusAmountPerTariff[2] = 30 ether;
        bonusAmountPerTariff[3] = 30 ether;
        bonusAmountPerTariff[4] = 30 ether;
        bonusAmountPerTariff[5] = 30 ether;
        bonusAmountPerTariff[6] = 30 ether;
        bonusAmountPerTariff[7] = 30 ether;

        bonusCandidatesLimit = 10000;
        bonusCandidatesLimitRDN = 3000;
        bonusRequirement = 360;

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(CONFIG_ROLE, _admin);
    }

    // todo Добавлять в каунтер если новый тариф и лимит не исчерпан и больше RDNLimit

    function activateTariff(uint _tariff) public {
        uint userId = registry.getUserIdByAddress(_msgSender());
        require(userId > 0, "Not registered in RDN");
        IRDNRegistry.User memory user = registry.getUser(userId);
        require(
            tariffPrices[_tariff][0] > 0 || tariffPrices[_tariff][1] > 0,
            "Invalid tariff"
        );
        require(_tariff > user.tariff, "New tariff is lower than current");

        // bonus counters
        if ((user.tariff == 0) && (userId > bonusCandidatesLimitRDN) && (bonusCandidatesCounter < bonusCandidatesLimit)) {
            bonusCandidatesCounter += 1;
            bonusCounter[userId] = 30;
        }

        uint[2] memory amountReq = calcActivationPrice(
            userId,
            user.tariff,
            _tariff
        );

        if (amountReq[0] > 0) {
            token1.transferFrom(_msgSender(), address(this), amountReq[0]);
            usersPaid[userId][0] += amountReq[0];
            IRDNDistributor distributor1 = IRDNDistributor(
                registry.getDistributor(address(token1))
            );
            uint rewardsAmount1 = (amountReq[0] * reward) / 10000;
            token1.approve(address(distributor1), rewardsAmount1);
            distributor1.distribute(_msgSender(), rewardsAmount1);
            emit Turnover(
                userId,
                address(token1),
                amountReq[0],
                amountReq[0] / 10
            );
        }
        if (amountReq[1] > 0) {
            token2.transferFrom(_msgSender(), address(this), amountReq[1]);
            usersPaid[userId][1] += amountReq[1];
            IRDNDistributor distributor2 = IRDNDistributor(
                registry.getDistributor(address(token2))
            );
            uint rewardsAmount2 = (amountReq[1] * reward) / 10000;
            token2.approve(address(distributor2), rewardsAmount2);
            distributor2.distribute(_msgSender(), rewardsAmount2);
            if (token2Points) {
                emit Turnover(
                    userId,
                    address(token2),
                    amountReq[1],
                    amountReq[1] / 10
                );
            }
        }
        if (user.tariff == 0) {
            registry.setActiveUntill(
                userId,
                block.timestamp + defaultSubscriptionPeriod
            );
        }
        registry.setTariff(userId, _tariff);
    }

    function prolongSubscription(uint _package) public {
        uint userId = registry.getUserIdByAddress(_msgSender());
        require(userId > 0, "Not registered in RDN");
        IRDNRegistry.User memory user = registry.getUser(userId);
        uint amount = _calcProlongPrice(user, _package); // gas savings
        require(amount > 0, "Package is not available");
        require(user.tariff > 0, "User tariff is 0");

        // bonus excluding
        if (
            ((userId <= bonusCandidatesLimitRDN) || (bonusCounter[userId] > 0)) &&
            user.activeUntill < block.timestamp
        ) {
            bonusCandidatesExcluded[userId] = true;
        }

        if (user.activeUntill == 0) {
            registry.setActiveUntill(
                userId,
                block.timestamp + _package * 60 * 60 * 24
            );
        } else {
            registry.setActiveUntill(
                userId,
                user.activeUntill + _package * 60 * 60 * 24
            );
        }

        token1.transferFrom(_msgSender(), address(this), amount);

        uint rewardsAmount = (amount * reward) / 10000;
        IRDNDistributor distributor1 = IRDNDistributor(
            registry.getDistributor(address(token1))
        );
        token1.approve(address(distributor1), rewardsAmount);
        distributor1.distribute(_msgSender(), rewardsAmount);

        emit Turnover(userId, address(token1), amount, amount / 10);

        // bonus counter / execution
        (uint reqBefore, uint bonusAmount) = estimateBonus(userId);
        if ((reqBefore > 0) && (reqBefore < bonusRequirement)) {
            bonusCounter[userId] += _package;
            if (bonusCounter[userId] >= bonusRequirement) {
                token2.transfer(user.userAddress, bonusAmount);
                emit RDNSubscriptionBonus(userId, user.userAddress, bonusAmount);
            }
        }
    }

    function calcActivationPrice(
        uint _userId,
        uint _tariffFrom,
        uint _tariffTo
    ) public view returns (uint[2] memory) {
        uint[2] memory price;
        // gas savings
        uint[2] memory _usersPaid = usersPaid[_userId];
        uint[2] memory _tariffPrices = tariffPrices[_tariffTo];

        if (_usersPaid[0] > 0 || _usersPaid[1] > 0) {
            if (_tariffPrices[0] > _usersPaid[0]) {
                price[0] = _tariffPrices[0] - _usersPaid[0];
            } else {
                price[0] = 0;
            }
            if (_tariffPrices[1] > _usersPaid[1]) {
                price[1] = _tariffPrices[1] - _usersPaid[1];
            } else {
                price[1] = 0;
            }
        } else {
            price[0] = _tariffPrices[0] - tariffPrices[_tariffFrom][0];
            price[1] = _tariffPrices[1] - tariffPrices[_tariffFrom][1];
        }

        if (
            _tariffFrom > 0 &&
            (subscriptionPackagePrices[_tariffTo][30] >
                subscriptionPackagePrices[_tariffFrom][30]) &&
            registry.isActive(_userId)
        ) {
            uint remaindSeconds = registry.getActiveUntill(_userId) - block.timestamp;
            uint diffSecondPrice = 
                (
                    subscriptionPackagePrices[_tariffTo][30] - 
                    subscriptionPackagePrices[_tariffFrom][30]
                ) /
                (30 * 24 * 60 * 60);
            price[0] += remaindSeconds * diffSecondPrice;
        }

        return price;
    }

    function calcProlongPrice(uint _userId, uint _package)
        public
        view
        returns (uint)
    {
        IRDNRegistry.User memory user = registry.getUser(_userId);
        return _calcProlongPrice(user, _package);
    }

    function _calcProlongPrice(IRDNRegistry.User memory _user, uint _package)
        private
        view
        returns (uint)
    {
        uint remaindSeconds = (block.timestamp < _user.activeUntill)
            ? (_user.activeUntill - block.timestamp)
            : 0;
        // should remain not more than 13 months after prolongation
        if ((_package * 24 * 60 * 60 + remaindSeconds) > (390 * 24 * 60 * 60)) {
            return 0;
        }
        return subscriptionPackagePrices[_user.tariff][_package];
    }

    function estimateBonus(uint _userId) public view returns(uint requirement, uint bonusAmount) {
        uint counter = bonusCounter[_userId];
        uint req = bonusRequirement;

        if (_userId <= bonusCandidatesLimitRDN) {
            counter += 30;
        }

        if (
            !registry.isActive(_userId) ||
            bonusCandidatesExcluded[_userId] || 
            (counter == 0) ||
            (counter >= req)
        ) {
            return (0, 0);
        }

        uint tariff = registry.getTariff(_userId);

        return ((req - counter), bonusAmountPerTariff[tariff]);
    }

    function getTariffPrice(uint _tariff)
        public
        view
        returns (uint[2] memory)
    {
        return tariffPrices[_tariff];
    }

    function getSubscriptionPackagePrice(uint _tariff, uint _package)
        public
        view
        returns (uint) 
    {
        return subscriptionPackagePrices[_tariff][_package];
    }

    function setReward(uint _reward) public onlyRole(CONFIG_ROLE) {
        reward = _reward;
    }

    function setTariffPrice(
        uint _tariff,
        uint _price1,
        uint _price2
    ) public onlyRole(CONFIG_ROLE) {
        tariffPrices[_tariff] = [_price1, _price2];
    }

    function setDefaultSupscriptionPeriod(uint _value)
        public
        onlyRole(CONFIG_ROLE)
    {
        defaultSubscriptionPeriod = _value;
    }

    function setBonusAmount(uint _tariff, uint _bonus) 
        public 
        onlyRole(CONFIG_ROLE) 
    {
        bonusAmountPerTariff[_tariff] = _bonus;
    }

    function setBonusCandidatesLimit(uint _limit) 
        public 
        onlyRole(CONFIG_ROLE)
    {
        bonusCandidatesLimit = _limit;
    }

    function setBonusCandidatesLimitRDN(uint _limit) 
        public 
        onlyRole(CONFIG_ROLE) 
    {
        bonusCandidatesLimitRDN = _limit;
    }

    function setBonusRequirement(uint _req) 
        public 
        onlyRole(CONFIG_ROLE) 
    {
        require(_req > bonusRequirement, "Must be greater");
        bonusRequirement = _req;
    }

    function setToken2Pioints(bool _points) 
        public 
        onlyRole(CONFIG_ROLE) 
    {
        token2Points = _points;
    }
}