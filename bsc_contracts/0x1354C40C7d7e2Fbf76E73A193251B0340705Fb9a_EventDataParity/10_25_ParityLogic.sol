// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ParityMath.sol";
library ParityLogic {
    uint256 public constant MAX_INDEX_EVENT = 1e18;

    function searchIndexEvent(ParityData.Event[] memory _data, uint256 _indexEvent) 
        internal pure returns (uint256 _index) {
        _index = MAX_INDEX_EVENT;
        if ( _data.length > 0){
            for (uint256 i = 0; i< _data.length; i++){
                if (_data[i].index == _indexEvent){
                    return i;
                }
            }   
        }          
    }
    
    function getTotalValueUntilLastEventPerProduct(ParityData.Event[] memory
        _data, uint256 _indexEvent, uint256 _id) internal pure returns 
        ( uint256 _totalValue) {
        ParityData.Amount memory _amount;
        if (_data.length > 0){
            for (uint256 i = 0; i < _data.length ; ++i){
                if (_data[i].index < _indexEvent){
                    _amount = ParityMath.add2(_amount, _data[i].amount);
                }
            }
        }
        if (_id == 0){
            return _amount.alpha;
        }
        else if (_id == 1){
            return _amount.beta;
        }
        else {
            return _amount.gamma;
        }
    }

    function getTotalValueUntilLastEvent(ParityData.Event[] memory
        _data, uint256 _indexEvent) internal pure returns 
        ( ParityData.Amount memory _totalValue){ 
        if (_data.length > 0){
            for (uint256 i = 0; i < _data.length ; ++i){
                if (_data[i].index < _indexEvent){
                    _totalValue = ParityMath.add2(_totalValue, _data[i].amount);
                }
            }
        }
    }

    function getTotalTokenValue(ParityData.Amount memory _tokenBalancePerToken, ParityData.Amount memory _depositBalancePerToken,
        ParityData.Amount memory _depositRebalancingBalancePerToken, 
        ParityData.Amount memory _withdrawalBalancePerToken, 
        uint256[3] memory _price) 
        internal pure returns ( uint256 _totalValue){
        _totalValue = getNetTotalTokenValue( _tokenBalancePerToken,  _depositBalancePerToken,
         _depositRebalancingBalancePerToken,  _price);
        _totalValue += (_withdrawalBalancePerToken.alpha * _price[0] +  
        _withdrawalBalancePerToken.beta * _price[1] +  
        _withdrawalBalancePerToken.gamma * _price[2])/ParityData.FACTOR_PRICE_DECIMALS;
    }

    function getNetTotalTokenValue(ParityData.Amount memory _tokenBalancePerToken, ParityData.Amount memory _depositBalancePerToken,
        ParityData.Amount memory _depositRebalancingBalancePerToken,  
        uint256[3] memory _price) 
        internal pure returns (uint256){
        ParityData.Amount  memory _value; 
        _value.alpha = (_tokenBalancePerToken.alpha * _price[0]) / ParityData.FACTOR_PRICE_DECIMALS + 
        _depositBalancePerToken.alpha + _depositRebalancingBalancePerToken.alpha;
        _value.beta = (_tokenBalancePerToken.beta * _price[1]) / ParityData.FACTOR_PRICE_DECIMALS + 
        _depositBalancePerToken.beta + _depositRebalancingBalancePerToken.beta;
        _value.gamma = (_tokenBalancePerToken.gamma * _price[2]) / ParityData.FACTOR_PRICE_DECIMALS + 
        _depositBalancePerToken.gamma + _depositRebalancingBalancePerToken.gamma;
        return _value.alpha + _value.beta + _value.gamma;
    }

    function getAvailableTokenValue(ParityData.Event[] memory depositBalancePerTokenPerEvent, 
        ParityData.Event[] memory depositRebalancingBalancePerTokenPerEvent, 
        ParityData.Amount memory tokenBalancePerToken,
        uint256 _indexEvent, 
        uint256[3] memory _price) 
        internal pure returns (uint256){
        ParityData.Amount  memory _value; 
        uint256 _indexDeposit; 
        uint256 _indexRebalancingDeposit;
        _indexDeposit = searchIndexEvent(depositBalancePerTokenPerEvent, _indexEvent);
        _indexRebalancingDeposit = searchIndexEvent(depositRebalancingBalancePerTokenPerEvent, _indexEvent);
        _value = ParityMath.mulMultiCoefDiv2(tokenBalancePerToken, _price, ParityData.FACTOR_PRICE_DECIMALS);
        if (_indexDeposit < MAX_INDEX_EVENT){
            _value = ParityMath.add2( _value, depositBalancePerTokenPerEvent[_indexDeposit].amount);
        }
        if (_indexRebalancingDeposit < MAX_INDEX_EVENT) {
            _value = ParityMath.add2( _value, depositRebalancingBalancePerTokenPerEvent[_indexRebalancingDeposit].amount);
        }
        return _value.alpha + _value.beta + _value.gamma;
    }

    function getTokenValueToRebalance(ParityData.Event[] memory depositBalancePerTokenPerEvent, 
        ParityData.Event[] memory depositRebalancingBalancePerTokenPerEvent,
        ParityData.Amount memory tokenBalancePerToken,
        uint256 _indexEvent,
        uint256[3] memory _price) 
        internal pure returns(uint256, uint256, uint256, uint256){
        uint256 _valueTotal;
        ParityData.Amount  memory _value; 
        uint256 _indexDeposit; 
        uint256 _indexRebalancingDeposit;
        _indexDeposit = searchIndexEvent(depositBalancePerTokenPerEvent, _indexEvent);
        _indexRebalancingDeposit = searchIndexEvent(depositRebalancingBalancePerTokenPerEvent, _indexEvent);
        _value = ParityMath.mulMultiCoefDiv2(tokenBalancePerToken, _price, ParityData.FACTOR_PRICE_DECIMALS);
        if (_indexDeposit < MAX_INDEX_EVENT){
            _value = ParityMath.add2(_value, depositBalancePerTokenPerEvent[_indexDeposit].amount);
        }
        if (_indexRebalancingDeposit < MAX_INDEX_EVENT){
            _value = ParityMath.add2(_value, depositRebalancingBalancePerTokenPerEvent[_indexRebalancingDeposit].amount);
        }
        _valueTotal = _value.alpha + _value.beta + _value.gamma;
        return (_value.alpha,  _value.beta,  _value.gamma, _valueTotal);
    }

    function calculateWithdrawalData(uint256 _rate,  uint256 _totalValue,
        uint256 _depositValueTotal, ParityData.Amount memory _depositValue, 
        ParityData.Amount memory _tokenBalancePerToken, uint256[3] memory _price) 
        internal pure returns ( ParityData.Amount memory _amountToWithdrawFromDeposit,
        ParityData.Amount memory _amountToWithdrawFromTokens){
        ParityData.Amount memory _weights = getWeightsFromToken(_tokenBalancePerToken, _price);
        uint256 _totalAmountToWithdraw;
        uint256 _totalAmountToWithdrawFromDeposit;
        uint256 _totalAmountToWithdrawFromTokens;
        _totalAmountToWithdraw = (_totalValue * _rate);
        _totalAmountToWithdrawFromDeposit = Math.min(_totalAmountToWithdraw, ParityData.COEFF_SCALE_DECIMALS * _depositValueTotal);
        if (_totalAmountToWithdrawFromDeposit > 0){
            _amountToWithdrawFromDeposit.alpha = Math.mulDiv(_totalAmountToWithdrawFromDeposit, _depositValue.alpha, _depositValueTotal);
            _amountToWithdrawFromDeposit.beta = Math.mulDiv(_totalAmountToWithdrawFromDeposit, _depositValue.beta, _depositValueTotal);
            _amountToWithdrawFromDeposit.gamma = Math.min(_totalAmountToWithdrawFromDeposit - (_amountToWithdrawFromDeposit.alpha + _amountToWithdrawFromDeposit.beta), 
            _depositValue.gamma * ParityData.COEFF_SCALE_DECIMALS);
            _amountToWithdrawFromDeposit = ParityMath.div2( _amountToWithdrawFromDeposit, ParityData.COEFF_SCALE_DECIMALS);
        }
        _totalAmountToWithdrawFromTokens = _totalAmountToWithdraw - _totalAmountToWithdrawFromDeposit;
        if (_totalAmountToWithdrawFromTokens >0){
            _amountToWithdrawFromTokens.alpha = (_totalAmountToWithdrawFromTokens * _weights.alpha) ;
            _amountToWithdrawFromTokens.beta = (_totalAmountToWithdrawFromTokens * _weights.beta);
            _amountToWithdrawFromTokens.gamma = Math.min( _totalAmountToWithdrawFromTokens * ParityData.COEFF_SCALE_DECIMALS - (_amountToWithdrawFromTokens.alpha + _amountToWithdrawFromTokens.beta), 
            _totalAmountToWithdrawFromTokens * _weights.gamma);   
        }
    }

    function calculateRebalancingData(uint256 _newDeposit,
        uint256 _valueTotal,
        ParityData.Amount memory _oldValue,
        ParityData.Amount memory _depositBalance, 
        ParityData.Amount memory _weights,
        uint256[3] memory _price) 
        internal pure returns(ParityData.Amount memory _depositToAdd,
        ParityData.Amount memory _depositToRemove,  
        ParityData.Amount memory _depositRebalancing, 
        ParityData.Amount memory _withdrawalRebalancing) { 
        uint256 _newValue;
        _valueTotal += _newDeposit;
        _newValue = Math.mulDiv(_valueTotal, _weights.alpha, ParityData.COEFF_SCALE_DECIMALS);
        (_depositToRemove.alpha, _depositToAdd.alpha,
        _depositRebalancing.alpha, _withdrawalRebalancing.alpha )
        = _calculateRebalancingData (_newValue, _oldValue.alpha, _price[0],
        _newDeposit,  _depositBalance.alpha); 
        _newDeposit -= _depositToAdd.alpha;
        _newValue = Math.mulDiv(_valueTotal, _weights.beta, ParityData.COEFF_SCALE_DECIMALS);
        (_depositToRemove.beta, _depositToAdd.beta,
        _depositRebalancing.beta, _withdrawalRebalancing.beta )
        = _calculateRebalancingData(_newValue, _oldValue.beta, _price[1],
        _newDeposit,  _depositBalance.beta); 
        _newDeposit -= _depositToAdd.beta;
        _newValue = Math.mulDiv(_valueTotal, _weights.gamma, ParityData.COEFF_SCALE_DECIMALS);
        (_depositToRemove.gamma, _depositToAdd.gamma,
        _depositRebalancing.gamma, _withdrawalRebalancing.gamma )
        = _calculateRebalancingData(_newValue, _oldValue.gamma, _price[2],
        _newDeposit,  _depositBalance.gamma); 
        _newDeposit -= _depositToAdd.gamma;    
    }
    
    function _calculateRebalancingData (uint256 _newValue, uint256 _oldValue, 
        uint256 _price,uint256 _newDeposit, uint256 _depositBalance) 
        internal pure  returns (uint256 _depositToRemove,
        uint256 _depositToAdd, uint256 _depositRebalancing,
        uint256 _withdrawalRebalancing) { 
        uint256 _deltaValue;
        if (_newValue < _oldValue){
            _deltaValue = (_oldValue - _newValue);
            _depositToRemove = Math.min(_deltaValue, _depositBalance);
            _deltaValue -= _depositToRemove;
            _withdrawalRebalancing = Math.mulDiv(_deltaValue, ParityData.FACTOR_PRICE_DECIMALS, _price); 
        }
        else{  
            _deltaValue = (_newValue - _oldValue);
            _depositToAdd = Math.min(_newDeposit, _deltaValue);
            _deltaValue -= _depositToAdd;
            _depositRebalancing += _deltaValue;

        }
    }

    function verifyBurnCondition(ParityData.Amount memory _depositBalancePerToken, 
        ParityData.Amount memory _withdrawalBalancePerToken, ParityData.Amount memory _tokenBalancePerToken, 
        ParityData.Amount memory _depositRebalancingBalancePerToken)
        internal pure returns (bool){
        require(_depositBalancePerToken.alpha == 0 
        && _depositBalancePerToken.beta == 0 
        && _depositBalancePerToken.gamma == 0, 
            "Formation.Fi: deposit on pending");
        require(_withdrawalBalancePerToken.alpha == 0
         && _withdrawalBalancePerToken.beta == 0 
        && _withdrawalBalancePerToken.gamma == 0, 
            "Formation.Fi: withdrawal on pending");
        require(_tokenBalancePerToken.alpha == 0 
        && _tokenBalancePerToken.beta == 0 
        && _tokenBalancePerToken.gamma == 0, 
            "Formation.Fi: tokens on pending");
        require(_depositRebalancingBalancePerToken.alpha == 0 
        && _depositRebalancingBalancePerToken.beta == 0 
        && _depositRebalancingBalancePerToken.gamma == 0, 
            "Formation.Fi: deposit rebalancing on pending");
        return true ;
    }

    function isCancelWithdrawalRequest(ParityData.Event[] memory _withdrawalBalancePerTokenPerEvent, uint256 _indexEvent) internal pure
        returns (bool _isCancel, uint256 _index){
          _index = searchIndexEvent(_withdrawalBalancePerTokenPerEvent, _indexEvent);
        if (_index < MAX_INDEX_EVENT){
            if ((_withdrawalBalancePerTokenPerEvent[_index].amount.alpha + 
                _withdrawalBalancePerTokenPerEvent[_index].amount.beta +
                _withdrawalBalancePerTokenPerEvent[_index].amount.gamma) > 0) {
                _isCancel = true;
            }
        }
    }

    function getWeightsFromToken(ParityData.Amount memory _tokenBalancePerToken,  uint256[3] memory _price) 
        internal pure returns (ParityData.Amount memory _weights) {
        uint256 _totalTokenValue = _tokenBalancePerToken.alpha * _price[0] +
        _tokenBalancePerToken.beta * _price[1] + 
        _tokenBalancePerToken.gamma * _price[2];
        if (_totalTokenValue > 0){
            uint256[3] memory _scaledPrice;
            _scaledPrice[0] = _price[0] * ParityData.COEFF_SCALE_DECIMALS;
            _scaledPrice[1] = _price[1] * ParityData.COEFF_SCALE_DECIMALS;
            _scaledPrice[2] = _price[2] * ParityData.COEFF_SCALE_DECIMALS;
            _weights =  ParityMath.mulMultiCoefDiv2(_tokenBalancePerToken, _scaledPrice, _totalTokenValue);
        }
    }

    function getWithdrawalTokenFees(ParityData.Amount memory _fee, ParityData.Amount memory _amountToWithdrawFromTokens ,
        uint256[3] memory _price) internal pure
        returns(ParityData.Amount memory _withdrawalFees){
        _withdrawalFees.alpha = _amountToWithdrawFromTokens.alpha * _fee.alpha;
        _withdrawalFees.beta = _amountToWithdrawFromTokens.beta * _fee.beta;
        _withdrawalFees.gamma = _amountToWithdrawFromTokens.gamma * _fee.gamma;
        uint256[3] memory _scaledPrice;
        uint256 _scale = ParityData.COEFF_SCALE_DECIMALS * ParityData.COEFF_SCALE_DECIMALS * ParityData.COEFF_SCALE_DECIMALS;
        _scaledPrice[0] = _price[0] * _scale;
        _scaledPrice[1] = _price[1] * _scale;
        _scaledPrice[2] = _price[2] * _scale;
        _withdrawalFees = ParityMath.mulDivMultiCoef2(_withdrawalFees, ParityData.FACTOR_PRICE_DECIMALS, _scaledPrice);
    }


    function calculateWithdrawalFees(uint256 _tokenTime, ParityData.Fee[] memory _fee) 
        internal view returns (uint256 _feeRate){
        uint256 _time1;
        uint256 _time2;
        uint256 _value1;
        uint256 _size = _fee.length;
        uint256 _deltaTime = block.timestamp - _tokenTime;
        if ( _size > 0){
            for (uint256 i = 0; i < _size  ; ++i) {
                _value1 = _fee[i].value;
                _time1 = _fee[i].time;
                if (i == _size - 1){
                    _feeRate = 0;
                    break;
                }  
                else {
                    _time2 = _fee[i+1].time;
                    if ((_deltaTime >= _time1) && (_deltaTime < _time2)){
                        _feeRate = _value1;
                        break;
                    }
                }
            }
        }   
    }

    function updateTokenFlowTime( uint256  _oldTokenTime,  
        uint256 _oldTokens, uint256 _newTokens)  
        internal view returns (uint256 _newTokenTime){
        _newTokenTime= (_oldTokens * _oldTokenTime + 
        block.timestamp * _newTokens) / ( _oldTokens + _newTokens);
    }
 
}