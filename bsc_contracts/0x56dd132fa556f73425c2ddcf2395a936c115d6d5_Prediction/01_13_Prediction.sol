// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IEvent.sol";
import "./IHelper.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

// import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";
struct OptionStat {
    uint256 value;
    uint256[] options;
}

contract Prediction is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(uint256 => mapping(address => mapping(address => EDataTypes.Prediction[]))) public predictions;
    mapping(uint256 => mapping(address => OptionStat)) public predictStats;

    uint256 private oneHundredPrecent;
    address payable public feeCollector;

    IEvent public eventData;
    address public eventDataAddress;
    mapping(address => mapping(address => uint256)) public liquidityPool;
    mapping(uint256 => mapping(address => uint256)) public liquidityPoolEvent;
    mapping(uint256 => mapping(address => bool)) public claimedLiquidityPool;
    address payable public efunToken;
    uint256 public creationFee;

    function initialize(
        uint256 _participateRate,
        uint256 _oneHundredPrecent,
        uint256 _creationFee
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        oneHundredPrecent = _oneHundredPrecent;
        setFeeCollector(0x9AFfAA4c1c3Eb3fDdAfEd379C25E50a68A323044);
        setEventData(0xdb48A5e4b09B5241e812c26763E94C1780B04635);
        setEfunToken(0x6746E37A756DA9E34f0BBF1C0495784Ba33b79B4);
        creationFee = _creationFee;
    }

    function hostFee(
        address _helperAddress,
        address _eventDataAddress,
        uint256 _eventId
    ) public view returns (uint256) {
        IHelper _helper = IHelper(_helperAddress);
        return _helper.hostFee(eventDataAddress, _eventId);
    }

    function platformFee(address _helperAddress) public view returns (uint256) {
        IHelper _helper = IHelper(_helperAddress);
        return _helper.platformFee();
    }

    function platFormfeeBefore(address _helperAddress) public view returns (uint256) {
        IHelper _helper = IHelper(_helperAddress);
        return _helper.platFormfeeBefore();
    }

    function createSingleEvent(
        uint256[3] memory _times,
        address _helperAddress,
        uint256[] calldata _odds,
        string memory _datas,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        uint256 _pro,
        bool _affiliate,
        uint256 _hostFee
    ) external payable returns (uint256 _idx) {
        uint256 len = _odds.length;

        _idx = _createEvent(_times, _helperAddress, msg.sender, _odds, _datas, _pro, _affiliate, _hostFee);
        predictStats[_idx][address(0)].options = new uint256[](_odds.length);
        predictStats[_idx][efunToken].options = new uint256[](_odds.length);
        EDataTypes.Event memory _event = eventData.info(_idx);
        _deposit(msg.value, _idx, _tokens, _amounts, len);
    }

    function setFeeCollector(address _feeCollector) public onlyOwner {
        feeCollector = payable(_feeCollector);
    }

    function setEventData(address _eventData) public onlyOwner {
        eventData = IEvent(_eventData);
        eventDataAddress = _eventData;
    }

    function setEfunToken(address _efunToken) public onlyOwner {
        efunToken = payable(_efunToken);
    }

    function setCreationFee(uint256 _creationFee) public onlyOwner {
        creationFee = _creationFee;
    }

    /**
     * @dev Get remaining lp
     */
    function getRemainingLP(uint256 _eventId, address[] calldata _tokens) public view returns (uint256[] memory) {
        uint256[] memory _results = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; ++i) {
            address _token = _tokens[i];
            (
                EDataTypes.Event memory _event,
                IHelper _helper,
                uint256 _liquidityPool,
                uint256[] memory _predictOptionStat,
                uint256 _predictStat
            ) = _getPRInfo(_eventId, _token);

            if (
                _event.endTime != 0 &&
                _event.endTime + 172800 < block.timestamp &&
                _event.status != EDataTypes.EventStatus.FINISH
            ) {
                _results[i] = _liquidityPool;
            } else if (_event.isBlock) {
                _results[i] = _liquidityPool;
            } else {
                _results[i] = _helper.calculateRemainLP(
                    eventDataAddress,
                    _eventId,
                    _predictStat,
                    _predictOptionStat,
                    _event.odds,
                    oneHundredPrecent,
                    _liquidityPool
                );
            }
        }
        return _results;
    }

    function getMaxPayout(
        uint256 _eventId,
        address _token,
        uint256 _index
    ) public view returns (uint256) {
        (
            EDataTypes.Event memory _event,
            IHelper _helper,
            uint256 _liquidityPool,
            uint256[] memory _predictOptionStat,
            uint256 _predictStat
        ) = _getPRInfo(_eventId, _token);
        return
            _helper.maxPayout(
                eventDataAddress,
                _eventId,
                _predictStat,
                _predictOptionStat,
                _event.odds[_index],
                _liquidityPool,
                oneHundredPrecent,
                _index
            );
    }

    function getMaxPayoutBatch(
        uint256[] calldata _eventIds,
        address[] calldata _tokens,
        uint256[] calldata _indexs
    ) public view returns (uint256[] memory) {
        uint256[] memory _results = new uint256[](_eventIds.length);

        for (uint256 i = 0; i < _eventIds.length; ++i) {
            uint256 _index = _indexs[i];
            uint256 _eventId = _eventIds[i];
            (
                EDataTypes.Event memory _event,
                IHelper _helper,
                uint256 _liquidityPool,
                uint256[] memory _predictOptionStat,
                uint256 _predictStat
            ) = _getPRInfo(_eventId, _tokens[i]);
            _results[i] = _helper.maxPayout(
                eventDataAddress,
                _eventId,
                _predictStat,
                _predictOptionStat,
                _event.odds[_index],
                _liquidityPool,
                oneHundredPrecent,
                _index
            );
        }
        return _results;
    }

    function getPotentialReward(
        uint256 _eventId,
        address _token,
        uint256 _index,
        uint256 _amount
    ) public view returns (uint256) {
        (
            EDataTypes.Event memory _event,
            IHelper _helper,
            uint256 _liquidityPool,
            uint256[] memory _predictOptionStat, // uint256 _predictStat

        ) = _getPRInfo(_eventId, _token);

        return
            _helper.calculatePotentialReward(
                eventDataAddress,
                _eventId,
                predictStats[_eventId][_token].value,
                _predictOptionStat,
                _amount,
                _event.odds[_index],
                oneHundredPrecent,
                _index,
                _liquidityPool
            );
    }

    function calculateSponsor(
        uint256 _eventId,
        address _token,
        uint256 _index,
        uint256 _amount
    ) public view returns (uint256) {
        (
            EDataTypes.Event memory _event,
            IHelper _helper,
            uint256 _liquidityPool,
            uint256[] memory _predictOptionStat, // uint256 _predictStat

        ) = _getPRInfo(_eventId, _token);

        return
            _helper.calculateSponsor(
                eventDataAddress,
                _eventId,
                predictStats[_eventId][_token].value,
                _predictOptionStat,
                _amount,
                _event.odds[_index],
                oneHundredPrecent,
                _index,
                _liquidityPool
            );
    }

    function depositLP(
        uint256 _eventId,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) public payable {
        EDataTypes.Event memory _event = eventData.info(_eventId);
        uint256 _totalAmount = msg.value;
        _deposit(_totalAmount, _eventId, _tokens, _amounts, _event.odds.length);
    }

    /**
     * @dev Predictions
     */
    function predict(
        uint256 _eventId,
        uint256[] calldata _optionIndexs,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) public payable {
        uint256 _totalAmount = msg.value;
        uint256 eventId = _eventId;
        EDataTypes.Event memory _event = eventData.info(_eventId);
        IHelper _helper = IHelper(_event.helperAddress);

        require(_tokens.length == _amounts.length && _tokens.length == _optionIndexs.length, "not-match-length");
        require(block.timestamp <= _event.deadlineTime, "invalid-predict-time");
        require(_event.status == EDataTypes.EventStatus.AVAILABLE, "event-not-available");

        for (uint256 i = 0; i < _tokens.length; ++i) {
            address _token = _tokens[i];
            uint256 _liquidityPool = liquidityPoolEvent[_eventId][_token];
            if (_event.affiliate) {
                _liquidityPool = liquidityPoolEvent[0][_token];
            }
            uint256 _amount = _amounts[i];
            uint256 _platformAmount = (_amount * _helper.platFormfeeBefore()) / oneHundredPrecent;
            _amount -= _platformAmount;
            uint256 _index = _optionIndexs[i];
            if (_token == address(0)) {
                require(_totalAmount >= _amount, "total-amount-not-same");
                _totalAmount -= _amount;
            }
            if (predictStats[eventId][_token].options.length == 0) {
                predictStats[eventId][_token].options = new uint256[](_event.odds.length);
            }

            require(_index < _event.odds.length, "cannot-find-index");
            require(_amount > 0, "predict-value = 0");
            require(
                _helper.validatePrediction(
                    predictStats[eventId][_token].value,
                    predictStats[eventId][_token].options,
                    _amount,
                    _event.odds[_index],
                    _liquidityPool,
                    oneHundredPrecent,
                    _index
                ),
                "not-enough-liquidity"
            );

            if (_token != address(0)) {
                IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);
                if (_platformAmount > 0) {
                    IERC20Upgradeable(_token).safeTransfer(feeCollector, _platformAmount);
                }
            } else {
                if (_platformAmount > 0) {
                    payable(feeCollector).transfer(_platformAmount);
                }
            }

            uint256 _userNumPredict = predictions[eventId][msg.sender][_token].length;
            predictStats[eventId][_token].value += _amount;
            predictStats[eventId][_token].options[_index] += _amount;
            EDataTypes.Prediction memory prediction;
            prediction.predictOptions = _index;
            prediction.predictionAmount = _amount;
            predictions[eventId][msg.sender][_token].push(prediction);

            emit PredictionCreated(eventId, _userNumPredict, msg.sender, _index, _token, _amount);
        }
    }

    /**
     * @dev Gets predict information
     */
    function getPredictInfo(
        uint256 eventId,
        address account,
        address token,
        uint256 index
    ) public view returns (EDataTypes.Prediction memory) {
        return predictions[eventId][account][token][index];
    }

    /**
     * @dev Gets event information
     */
    function getEventInfo(uint256 eventId, address token) public view returns (uint256) {
        return predictStats[eventId][token].value;
    }

    /**
     * @dev Gets balance token
     */
    function getTokenAmount(address token) public view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        }
        return IERC20Upgradeable(token).balanceOf(address(this));
    }

    /**
     * @dev Claims reward
     */
    function claimReward(
        uint256 _eventId,
        address _token,
        uint256 _predictNum
    ) external {
        EDataTypes.Event memory _event = eventData.info(_eventId);

        require(_event.status == EDataTypes.EventStatus.FINISH, "event-not-finish");
        require(predictions[_eventId][msg.sender][_token][_predictNum].claimed == false, "claimed");
        require(_event.claimTime < block.timestamp, "claim_time < timestamp");
        require(!_event.isBlock, "event blocked");

        uint256 _reward;
        _reward = estimateReward(_eventId, msg.sender, _token, _predictNum, true);

        if (_reward > 0) {
            IHelper _helper = IHelper(_event.helperAddress);
            uint256 hostFee = _helper.hostFee(eventDataAddress, _eventId);
            uint256 platformFee = _helper.platformFee();
            uint256 _amountHasFee = getAmountHasFee(
                _eventId,
                predictions[_eventId][msg.sender][_token][_predictNum].predictionAmount,
                _reward
            );
            transferMoney(_token, msg.sender, _amountHasFee, _reward, hostFee, platformFee, _event.creator);
            predictions[_eventId][msg.sender][_token][_predictNum].claimed = true;
        }

        emit RewardClaimed(_eventId, _predictNum, msg.sender, _token, _reward);
    }

    /**
     * @dev Estimate reward Sponsor
     */
    function estimateReward(
        uint256 _eventId,
        address _user,
        address _token,
        uint256 _predictNum,
        bool _validate
    ) public view returns (uint256) {
        (
            EDataTypes.Event memory _event,
            IHelper _helper,
            uint256 _predictStat,
            uint256[] memory _predictOptionStat,
            EDataTypes.Prediction memory _prediction,
            uint256 _liquidityPool
        ) = _getStat(_eventId, _user, _token, _predictNum);
        bool validate = _validate;

        return
            _helper.calculateReward(
                eventDataAddress,
                _eventId,
                _predictStat,
                _predictOptionStat,
                _prediction,
                oneHundredPrecent,
                _liquidityPool,
                validate
            );
    }

    /**
     * @dev Estimate reward Sponsor
     */
    function getAmountHasFee(
        uint256 _eventId,
        uint256 _amount,
        uint256 _reward
    ) public view returns (uint256 amountHasFee) {
        EDataTypes.Event memory _event = eventData.info(_eventId);
        IHelper _helper = IHelper(_event.helperAddress);
        amountHasFee = _helper.getAmountHasFee(_amount, _reward);
        if (_event.affiliate) {
            amountHasFee = 0;
        }
    }

    /**
     * @dev Estimate reward Sponsor
     */
    function estimateRewardSponsor(
        uint256 _eventId,
        address _user,
        address _token,
        uint256 _predictNum
    ) public view returns (uint256) {
        (
            EDataTypes.Event memory _event,
            IHelper _helper,
            uint256 _predictStat,
            uint256[] memory _predictOptionStat,
            EDataTypes.Prediction memory _prediction,
            uint256 _liquidityPool
        ) = _getStat(_eventId, _user, _token, _predictNum);

        return
            _helper.calculateRewardSponsor(
                eventDataAddress,
                _eventId,
                _predictStat,
                _predictOptionStat,
                _prediction,
                oneHundredPrecent,
                _liquidityPool
            );
    }

    /**
     * @dev Claims remaining lp
     */
    function claimRemainingLP(uint256 _eventId, address[] calldata _tokens) public {
        EDataTypes.Event memory _event = eventData.info(_eventId);
        require(
            (_event.status == EDataTypes.EventStatus.FINISH && _event.claimTime < block.timestamp) ||
                (_event.status != EDataTypes.EventStatus.FINISH &&
                    _event.endTime != 0 &&
                    _event.endTime + 172800 < block.timestamp),
            "event-not-finish"
        );
        require(_event.creator == msg.sender, "unauthorized");
        uint256[] memory _amounts = getRemainingLP(_eventId, _tokens);

        for (uint256 i = 0; i < _tokens.length; ++i) {
            address _token = _tokens[i];
            require(claimedLiquidityPool[_eventId][_token] == false, "claimed");
            claimedLiquidityPool[_eventId][_token] = true;

            uint256 _amount = _amounts[i];
            if (_token == address(0)) {
                payable(msg.sender).transfer(_amount);
            } else {
                IERC20Upgradeable(payable(_token)).safeTransfer(msg.sender, _amount);
            }
            emit LPClaimed(_eventId, _token, _amount);
        }
    }

    /**
     * @dev Claims host fee
     */
    function claimHostFee(uint256[] calldata _eventIds, address _token) public {
        for (uint256 i = 0; i < _eventIds.length; ++i) {
            uint256 _eventId = _eventIds[i];
            EDataTypes.Event memory _event = eventData.info(_eventId);
            require(msg.sender == _event.creator, "unauthorized");
            IHelper _helper = IHelper(_event.helperAddress);
            uint256 hostFee = _helper.hostFee(eventDataAddress, _eventId);
            uint256 prediction = predictStats[_eventId][_token].options[_event.resultIndex];
            uint256 _amountHasFee = predictStats[_eventId][_token].value - prediction;
            uint256 _hostAmount = (_amountHasFee * hostFee) / oneHundredPrecent;
            if (_token == address(0)) {
                if (_hostAmount > 0) {
                    payable(_event.creator).transfer(_hostAmount);
                }
            } else {
                if (_hostAmount > 0) {
                    IERC20Upgradeable(_token).safeTransfer(_event.creator, _hostAmount);
                }
            }
        }
    }

    /**
     * @dev Claims reward
     */
    function claimCashBack(
        uint256 _eventId,
        address _token,
        uint256 _predictNum
    ) external {
        EDataTypes.Event memory _event = eventData.info(_eventId);

        require(
            (_event.status == EDataTypes.EventStatus.FINISH && _event.claimTime < block.timestamp && _event.isBlock) ||
                (_event.status != EDataTypes.EventStatus.FINISH &&
                    _event.endTime != 0 &&
                    _event.endTime + 172800 < block.timestamp),
            "event-not-finish"
        );
        require(predictions[_eventId][msg.sender][_token][_predictNum].claimed == false, "claimed");

        transferMoneyNoFee(_token, msg.sender, predictions[_eventId][msg.sender][_token][_predictNum].predictionAmount);
        predictions[_eventId][msg.sender][_token][_predictNum].claimed = true;

        emit CashBackClaimed(_eventId, _predictNum, msg.sender, _token);
    }

    function emergencyWithdraw(address _token, uint256 amount) public onlyOwner {
        if (_token == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20Upgradeable(payable(_token)).safeTransfer(msg.sender, amount);
        }
    }

    /* =============== INTERNAL FUNCTION ==================== */

    function _createEvent(
        uint256[3] memory _times,
        address _helperAddress,
        address _creator,
        uint256[] calldata _odds,
        string memory _datas,
        uint256 _pro,
        bool _affiliate,
        uint256 _hostFee
    ) internal returns (uint256 _idx) {
        if (!_affiliate) {
            IERC20Upgradeable(efunToken).safeTransferFrom(msg.sender, feeCollector, creationFee);
        }
        _idx = eventData.createSingleEvent(_times, _helperAddress, _odds, _datas, _creator, _pro, _affiliate, _hostFee);

        emit EventCreated(
            _idx,
            _times[0],
            _times[1],
            _times[2],
            _helperAddress,
            _creator,
            _odds,
            _datas,
            _pro,
            _affiliate,
            _hostFee,
            creationFee
        );
    }

    function _deposit(
        uint256 _totalAmount,
        uint256 _idx,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        uint256 _len
    ) internal {
        for (uint256 i = 0; i < _tokens.length; ++i) {
            address _token = _tokens[i];
            uint256 _amount = _amounts[i];

            liquidityPoolEvent[_idx][_token] += _amount;
            if (_token != address(0)) {
                IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);
            } else {
                require(_totalAmount >= _amount, "total-amount-not-same");
                _totalAmount -= _amount;
            }
            if (predictStats[_idx][_token].options.length == 0) {
                predictStats[_idx][_token].options = new uint256[](_len);
            }

            emit LPDeposited(_idx, _token, liquidityPoolEvent[_idx][_token]);
        }
    }

    function _getPRInfo(uint256 _eventId, address _token)
        internal
        view
        returns (
            EDataTypes.Event memory _event,
            IHelper _helper,
            uint256 _liquidityPool,
            uint256[] memory _predictOptionStat,
            uint256 _predictStat
        )
    {
        _predictStat = predictStats[_eventId][_token].value;
        _event = eventData.info(_eventId);
        _helper = IHelper(_event.helperAddress);
        _liquidityPool = liquidityPoolEvent[_eventId][_token];
        if (_event.affiliate) {
            _liquidityPool = liquidityPoolEvent[0][_token];
        }
        _predictOptionStat = predictStats[_eventId][_token].options;
        if (_predictOptionStat.length == 0) {
            _predictOptionStat = new uint256[](_event.odds.length);
        }
    }

    function _getStat(
        uint256 _eventId,
        address _user,
        address _token,
        uint256 _predictNum
    )
        internal
        view
        returns (
            EDataTypes.Event memory _event,
            IHelper _helper,
            uint256 _predictStat,
            uint256[] memory _predictOptionStat,
            EDataTypes.Prediction memory _prediction,
            uint256 _liquidityPool
        )
    {
        uint256 eventId = _eventId;
        address token = _token;
        address user = _user;
        uint256 predictNum = _predictNum;

        _event = eventData.info(eventId);
        _helper = IHelper(_event.helperAddress);
        _predictStat = predictStats[eventId][token].value;
        _predictOptionStat = predictStats[eventId][token].options;
        _prediction = predictions[eventId][user][token][predictNum];
        _liquidityPool = liquidityPoolEvent[_eventId][_token];
        if (_event.affiliate) {
            _liquidityPool = liquidityPoolEvent[0][_token];
        }
    }

    function transferMoney(
        address _token,
        address _toAddress,
        uint256 _amountHasFee,
        uint256 _reward,
        uint256 _hostFee,
        uint256 _platformFee,
        address _creator
    ) internal {
        uint256 _platformAmount = (_amountHasFee * _platformFee) / oneHundredPrecent;
        uint256 _hostAmount = (_amountHasFee * _hostFee) / oneHundredPrecent;

        // need to check balance of contract, if balance < amount, send balance
        if (_token == address(0)) {
            if (_platformAmount > 0) {
                payable(feeCollector).transfer(_platformAmount);
            }
            payable(_toAddress).transfer(_reward - _platformAmount - _hostAmount);
        } else {
            if (_platformAmount > 0) {
                IERC20Upgradeable(_token).safeTransfer(feeCollector, _platformAmount);
            }
            IERC20Upgradeable(_token).safeTransfer(_toAddress, _reward - _platformAmount - _hostAmount);
        }
    }

    function transferMoneyNoFee(
        address _token,
        address _toAddress,
        uint256 _amount
    ) internal {
        if (_token == address(0)) {
            payable(_toAddress).transfer(_amount);
        } else {
            IERC20Upgradeable(_token).safeTransfer(_toAddress, _amount);
        }
    }

    /* =============== EVENT ==================== */

    event EventCreated(
        uint256 idx,
        uint256 startTime,
        uint256 deadlineTime,
        uint256 endTime,
        address helperAddress,
        address creator,
        uint256[] odds,
        string datas,
        uint256 pro,
        bool affiliate,
        uint256 _hostFee,
        uint256 creationFee
    );
    event LPDeposited(uint256 eventId, address token, uint256 amount);
    event LPClaimed(uint256 eventId, address token, uint256 amount);
    event PredictionCreated(
        uint256 eventId,
        uint256 predictNum,
        address user,
        uint256 optionIndex,
        address token,
        uint256 amount
    );
    event RewardClaimed(uint256 eventId, uint256 predictNum, address user, address token, uint256 reward);
    event CashBackClaimed(uint256 eventId, uint256 predictNum, address user, address token);
}