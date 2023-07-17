// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/AggregatorV3Interface.sol";
import "./utils/ECDSA.sol";
import './access/Ownable.sol';
import './utils/SafeERC20.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';
import "./TokenManager.sol";

contract LaborXContract is Ownable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    enum State {NULL, CREATED, BLOCKED, PAYED_TO_FREELANCER, RETURNED_FUNDS_TO_CUSTOMER, DISTRIBUTED_FUNDS_BY_ARBITER}

    event ContractCreated(bytes32 indexed contractId, address token, uint256 amount, address disputer, uint256 deadline);
    event ContractBlocked(bytes32 indexed contractId);
    event PayedToFreelancer(bytes32 indexed contractId, uint256 freelancerFee, uint256 freelancerAmount);
    event RefundedToCustomer(bytes32 indexed contractId, uint256 customerPayAmount);
    event DistributedForPartials(bytes32 indexed contractId, uint256 freelancerFee, uint256 customerPayAmount, uint256 freelancerPayAmount);
    event ServiceFeesChanged(uint256 customerFee, uint256 freelancerFee);

    uint256 public constant FEE_PRECISION = 1000;

    bool private initialized;
    uint256 public customerFee = 0;
    uint256 public freelancerFee = 100;
    uint256 public extraDuration = 172800;
    uint256 public precision = 10000000000;
    uint256 public priceOutdateDelay = 14400;
    uint256 public priceOutdateDelayStable = 172800;
    bool public convertAvailable = true;

    address public weth;
    address public tokenManager;
    address public serviceFeesRecipient;
    address public disputer;

    struct Contract {
        bytes32 contractId;
        address customer;
        address freelancer;
        address disputer;
        address token;
        uint256 amount;
        uint256 customerFee;
        uint256 deadline;
        uint256 percentToBaseConvert;
        State state;
    }

    struct ServiceFeeAccum {
        address token;
        uint256 amount;
    }

    mapping(bytes32 => Contract) public contracts;
    mapping(address => uint256) public serviceFeesAccum;

    function init(address _weth, address _tokenManager, address _disputer, address _serviceFeesRecipient) external onlyOwner {
        require(!initialized, "Initialized");
        weth = _weth;
        tokenManager = _tokenManager;
        disputer = _disputer;
        serviceFeesRecipient = _serviceFeesRecipient;
        initialized = true;
    }

    function createContract(
        bytes32 _contractId,
        address _freelancer,
        address _disputer,
        address _token,
        uint256 _amount,
        uint64 _duration,
        uint256 _percentToBaseConvert
    ) external payable {
        require(contracts[_contractId].state == State.NULL, "Contract already exist");
        (bool found,) = TokenManager(tokenManager).indexOfToken(_token);
        require(found, "Only allowed currency");
        require((_percentToBaseConvert >= 0 && _percentToBaseConvert <= 1000), "Percent to base convert goes beyond the limits from 0 to 1000");
        require(_duration > 0, "Duration must be greater than zero");
        uint256 _deadline = _duration + block.timestamp;
        uint256 feeAmount = customerFee * _amount / FEE_PRECISION;
        uint256 amountWithFee = _amount + feeAmount;
        if (_token == weth) {
            require(msg.value == amountWithFee, 'Incorrect passed msg.value');
            IWETH(weth).deposit{value : amountWithFee}();
        } else {
            IERC20(_token).safeTransferFrom(_msgSender(), address(this), amountWithFee);
        }
        Contract storage jobContract = contracts[_contractId];
        jobContract.state = State.CREATED;
        jobContract.customer = _msgSender();
        jobContract.freelancer = _freelancer;
        if (_disputer != address(0)) jobContract.disputer = _disputer;
        jobContract.token = _token;
        jobContract.amount = _amount;
        if (customerFee != 0) jobContract.customerFee = customerFee;
        jobContract.deadline = _deadline;
        if (_percentToBaseConvert != 0) jobContract.percentToBaseConvert = _percentToBaseConvert;
        emit ContractCreated(_contractId, _token, _amount, _disputer, _deadline);
    }

    function blockContract(bytes32 _contractId) external onlyCreatedState(_contractId) {
        require(
            ((contracts[_contractId].disputer == address(0) && _msgSender() == disputer) || _msgSender() == contracts[_contractId].disputer) ||
            _msgSender() == contracts[_contractId].freelancer,
            "Only disputer or freelancer can block contract"
        );
        contracts[_contractId].state = State.BLOCKED;
        emit ContractBlocked(_contractId);
    }

    function payToFreelancer(
        bytes32 _contractId
    ) external onlyCustomer(_contractId) onlyCreatedState(_contractId) {
        uint256 freelancerFeeAmount = freelancerFee * contracts[_contractId].amount / FEE_PRECISION;
        uint256 customerFeeAmount = contracts[_contractId].customerFee * contracts[_contractId].amount / FEE_PRECISION;
        uint256 freelancerAmount = contracts[_contractId].amount - freelancerFeeAmount;
        contracts[_contractId].state = State.PAYED_TO_FREELANCER;
        if (contracts[_contractId].token == weth) {
            IWETH(weth).withdraw(freelancerAmount);
            payable(contracts[_contractId].freelancer).transfer(freelancerAmount);
        } else {
            if (contracts[_contractId].percentToBaseConvert > 0) {
                uint256 freelancerAmountToBase = freelancerAmount * contracts[_contractId].percentToBaseConvert / FEE_PRECISION;
                bool success = _payInBase(contracts[_contractId].freelancer, contracts[_contractId].token, freelancerAmountToBase);
                if (success) {
                    IERC20(contracts[_contractId].token).safeTransfer(contracts[_contractId].freelancer, freelancerAmount - freelancerAmountToBase);
                } else {
                    IERC20(contracts[_contractId].token).safeTransfer(contracts[_contractId].freelancer, freelancerAmount);
                }
            } else {
                IERC20(contracts[_contractId].token).safeTransfer(contracts[_contractId].freelancer, freelancerAmount);
            }
        }
        serviceFeesAccum[contracts[_contractId].token] += freelancerFeeAmount + customerFeeAmount;
        emit PayedToFreelancer(_contractId, freelancerFee, freelancerAmount);
    }

    function refundToCustomerByFreelancer(
        bytes32 _contractId
    ) external onlyFreelancer(_contractId) onlyCreatedState(_contractId) {
        uint256 customerFeeAmount = contracts[_contractId].customerFee * contracts[_contractId].amount / FEE_PRECISION;
        uint256 customerAmount = contracts[_contractId].amount + customerFeeAmount;
        contracts[_contractId].state = State.RETURNED_FUNDS_TO_CUSTOMER;
        if (contracts[_contractId].token == weth) {
            IWETH(weth).withdraw(customerAmount);
            payable(contracts[_contractId].customer).transfer(customerAmount);
        } else {
            IERC20(contracts[_contractId].token).safeTransfer(
                contracts[_contractId].customer,
                customerAmount
            );
        }
        emit RefundedToCustomer(_contractId, customerAmount);
    }

    function refundToCustomerByCustomer(
        bytes32 _contractId
    ) external onlyCustomer(_contractId) onlyCreatedState(_contractId) {
        require(contracts[_contractId].deadline + extraDuration < block.timestamp, "You cannot refund the funds, deadline plus extra hours");
        uint256 customerFeeAmount = contracts[_contractId].customerFee * contracts[_contractId].amount / FEE_PRECISION;
        uint256 customerAmount = contracts[_contractId].amount + customerFeeAmount;
        contracts[_contractId].state = State.RETURNED_FUNDS_TO_CUSTOMER;
        if (contracts[_contractId].token == weth) {
            IWETH(weth).withdraw(customerAmount);
            payable(contracts[_contractId].customer).transfer(customerAmount);
        } else {
            IERC20(contracts[_contractId].token).safeTransfer(
                contracts[_contractId].customer,
                customerAmount
            );
        }
        emit RefundedToCustomer(_contractId, customerAmount);
    }

    function refundToCustomerWithFreelancerSignature(
        bytes32 _contractId,
        bytes memory signature
    ) public onlyCustomer(_contractId) onlyCreatedState(_contractId) {
        address signerAddress = _contractId.toEthSignedMessageHash().recover(signature);
        require(signerAddress == contracts[_contractId].freelancer, "Freelancer signature is incorrect");
        uint256 customerFeeAmount = contracts[_contractId].customerFee * contracts[_contractId].amount / FEE_PRECISION;
        uint256 customerAmount = contracts[_contractId].amount + customerFeeAmount;
        contracts[_contractId].state = State.RETURNED_FUNDS_TO_CUSTOMER;
        if (contracts[_contractId].token == weth) {
            IWETH(weth).withdraw(customerAmount);
            payable(contracts[_contractId].customer).transfer(customerAmount);
        } else {
            IERC20(contracts[_contractId].token).safeTransfer(
                contracts[_contractId].customer,
                customerAmount
            );
        }
        emit RefundedToCustomer(_contractId, customerAmount);
    }

    function distributionForPartials(
        bytes32 _contractId,
        uint256 _customerAmount
    ) external onlyDisputer(_contractId) onlyBlockedState(_contractId) {
        require(contracts[_contractId].amount >= _customerAmount, "High value of the customer amount");
        uint256 customerBeginFee = contracts[_contractId].amount * contracts[_contractId].customerFee / FEE_PRECISION;
        uint256 freelancerAmount = contracts[_contractId].amount - _customerAmount;
        uint256 freelancerFeeAmount = freelancerAmount * freelancerFee / FEE_PRECISION;
        uint256 freelancerPayAmount = freelancerAmount - freelancerFeeAmount;
        uint256 customerFeeAmount = freelancerAmount * precision * customerBeginFee / contracts[_contractId].amount / precision;
        uint256 customerPayAmount = _customerAmount + (customerBeginFee - customerFeeAmount);
        contracts[_contractId].state = State.DISTRIBUTED_FUNDS_BY_ARBITER;
        if (contracts[_contractId].token == weth) {
            IWETH(weth).withdraw(customerPayAmount + freelancerPayAmount);
            if (customerPayAmount != 0) {
                payable(contracts[_contractId].customer).transfer(customerPayAmount);
            }
            if (freelancerPayAmount != 0) {
                payable(contracts[_contractId].freelancer).transfer(freelancerPayAmount);
            }
        } else {
            if (customerPayAmount != 0) {
                IERC20(contracts[_contractId].token).safeTransfer(contracts[_contractId].customer, customerPayAmount);
            }
            if (freelancerPayAmount != 0) {
                IERC20(contracts[_contractId].token).safeTransfer(contracts[_contractId].freelancer, freelancerPayAmount);
            }
        }
        serviceFeesAccum[contracts[_contractId].token] += customerFeeAmount + freelancerFeeAmount;
        emit DistributedForPartials(_contractId, freelancerFee, customerPayAmount, freelancerPayAmount);
    }

    function withdrawServiceFee(address token) external onlyServiceFeesRecipient {
        require(serviceFeesRecipient != address(0), "Not specified service fee address");
        require(serviceFeesAccum[token] > 0, "You have no accumulated commissions");
        uint256 amount = serviceFeesAccum[token];
        serviceFeesAccum[token] = 0;
        if (token == weth) {
            IWETH(weth).withdraw(amount);
            payable(serviceFeesRecipient).transfer(amount);
        } else {
            IERC20(token).safeTransfer(serviceFeesRecipient, amount);
        }
    }

    function withdrawServiceFees() external onlyServiceFeesRecipient {
        address[] memory addresses = TokenManager(tokenManager).getListTokenAddresses();
        for (uint256 i = 0; i < addresses.length; i++) {
            if (serviceFeesAccum[addresses[i]] > 0) {
                uint256 amount = serviceFeesAccum[addresses[i]];
                serviceFeesAccum[addresses[i]] = 0;
                if (addresses[i] == weth) {
                    IWETH(weth).withdraw(amount);
                    payable(serviceFeesRecipient).transfer(amount);
                } else {
                    IERC20(addresses[i]).safeTransfer(serviceFeesRecipient, amount);
                }
            }
        }
    }

    function checkAbilityConvertToBase(address fromToken, uint256 amount) public view returns (bool success, uint256 amountInBase) {
        if (!convertAvailable) return (false, 0);
        if (address(0) == weth) return (false, 1);
        if (fromToken == weth) return (false, 2);
        (bool found,) = TokenManager(tokenManager).indexOfToken(weth);
        if (!found) return (false, 3);
        (,,,,address priceContractToUSD, bool isStable) = TokenManager(tokenManager).tokens(fromToken);
        if (priceContractToUSD == address(0)) return (false, 4);
        (,int256 answerToUSD,,uint256 updatedAtToUSD,) = AggregatorV3Interface(priceContractToUSD).latestRoundData();
        if ((updatedAtToUSD + (isStable ? priceOutdateDelayStable : priceOutdateDelay )) < block.timestamp) return (false, 5);
        if (answerToUSD <= 0) return (false, 6);
        (,,,,address priceContractToBase,) = TokenManager(tokenManager).tokens(weth);
        (,int256 answerToBase,,uint256 updatedAtToBase,) = AggregatorV3Interface(priceContractToBase).latestRoundData();
        if ((updatedAtToBase + priceOutdateDelay) < block.timestamp) return (false, 7);
        if (answerToBase <= 0) return (false, 8);
        uint256 amountInUSD = amount * uint(answerToUSD) / (10 ** AggregatorV3Interface(priceContractToUSD).decimals());
        amountInBase = amountInUSD * (10 ** 18) / uint(answerToBase);
        if (amountInBase > serviceFeesAccum[weth]) return (false, 9);
        return (true, amountInBase);
    }

    function addToServiceFeeAccumBase() external payable onlyServiceFeesRecipient {
        IWETH(weth).deposit{value : msg.value}();
        serviceFeesAccum[weth] += msg.value;
    }

    function setPrecision(uint256 _precision) external onlyOwner {
        precision = _precision;
    }

    function setServiceFeesRecipient(address _address) external onlyOwner {
        serviceFeesRecipient = _address;
    }

    function setDisputer(address _address) external onlyOwner {
        disputer = _address;
    }

    function setTokenManager(address _address) external onlyOwner {
        tokenManager = _address;
    }

    function setServiceFees(uint256 _customerFee, uint256 _freelancerFee) external onlyOwner {
        customerFee = _customerFee;
        freelancerFee = _freelancerFee;
        emit ServiceFeesChanged(customerFee, freelancerFee);
    }

    function setExtraDuration(uint256 _extraDuration) external onlyOwner {
        extraDuration = _extraDuration;
    }

    function setPriceOutdateDelay(uint256 _priceOutdateDelay, uint256 _priceOutdateDelayStable) external onlyOwner {
        priceOutdateDelay = _priceOutdateDelay;
        priceOutdateDelayStable = _priceOutdateDelayStable;
    }

    function setConvertAvailable(bool _convertAvailable) external onlyOwner {
        convertAvailable = _convertAvailable;
    }

    function _payInBase(address to, address fromToken, uint256 amount) internal returns (bool) {
        (bool success, uint256 amountInBase) = checkAbilityConvertToBase(fromToken, amount);
        if (!success) return false;
        IWETH(weth).withdraw(amountInBase);
        payable(to).transfer(amountInBase);
        serviceFeesAccum[weth] -= amountInBase;
        serviceFeesAccum[fromToken] += amount;
        return true;
    }

    receive() external payable {
        assert(msg.sender == weth);
    }

    // -------- Getters ----------
    function getAccumulatedFees() public view returns (ServiceFeeAccum[] memory _fees) {
        uint256 length = TokenManager(tokenManager).getLengthTokenAddresses();
        ServiceFeeAccum[] memory fees = new ServiceFeeAccum[](length);
        for (uint256 i = 0; i < length; i++) {
            address token = TokenManager(tokenManager).tokenAddresses(i);
            fees[i].token = token;
            fees[i].amount = serviceFeesAccum[token];
        }
        return fees;
    }

    function getServiceFees() public view returns (uint256 _customerFee, uint256 _freelancerFee) {
        _customerFee = customerFee;
        _freelancerFee = freelancerFee;
    }

    // -------- Modifiers ----------
    modifier onlyCreatedState (bytes32 _contractId) {
        require(contracts[_contractId].state == State.CREATED, "Contract allowed only created state");
        _;
    }

    modifier onlyBlockedState (bytes32 _contractId) {
        require(contracts[_contractId].state == State.BLOCKED, "Contract allowed only blocked state");
        _;
    }

    modifier onlyServiceFeesRecipient () {
        require(_msgSender() == serviceFeesRecipient, "Only service fees recipient can call this function");
        _;
    }

    modifier onlyFreelancer (bytes32 _contractId) {
        require(_msgSender() == contracts[_contractId].freelancer, "Only freelancer can call this function");
        _;
    }

    modifier onlyCustomer (bytes32 _contractId) {
        require(_msgSender() == contracts[_contractId].customer, "Only customer can call this function");
        _;
    }

    modifier onlyTxSender (bytes32 _contractId) {
        require(msg.sender == tx.origin, "Only tx sender can call this function");
        _;
    }

    modifier onlyDisputer (bytes32 _contractId) {
        require((contracts[_contractId].disputer == address(0) && _msgSender() == disputer) || _msgSender() == contracts[_contractId].disputer, "Only disputer can call this function");
        _;
    }
}