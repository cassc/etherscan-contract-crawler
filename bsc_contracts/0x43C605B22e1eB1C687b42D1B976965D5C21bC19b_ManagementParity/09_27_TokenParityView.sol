// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/ParityLogic.sol";
import "./TokenParityStorage.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract TokenParityView.
*/

contract TokenParityView is  Ownable { 
    TokenParityStorage public tokenParityStorage;
    function setTokenParityStorage(address _tokenParityStorage) public onlyOwner {
        require(_tokenParityStorage != address(0),
            "Formation.Fi: zero address");
        tokenParityStorage = TokenParityStorage(_tokenParityStorage);
    }


    function getTotalTokenValue(uint256 _tokenId, uint256[3] memory _price) public view
        returns(uint256 _totalValue){
        ParityData.Amount memory _tokenBalancePerToken;
        ParityData.Amount memory _depositBalancePerToken;
        ParityData.Amount memory _depositRebalancingBalancePerToken;
        ParityData.Amount memory _withdrawalBalancePerToken;
        (_tokenBalancePerToken.alpha, _tokenBalancePerToken.beta, _tokenBalancePerToken.gamma)  = tokenParityStorage.tokenBalancePerToken(_tokenId);
        (_depositBalancePerToken.alpha, _depositBalancePerToken.beta, _depositBalancePerToken.gamma)= tokenParityStorage.depositBalancePerToken(_tokenId);
        (_depositRebalancingBalancePerToken.alpha, _depositRebalancingBalancePerToken.beta, _depositRebalancingBalancePerToken.gamma) = tokenParityStorage.depositRebalancingBalancePerToken(_tokenId);
        (_withdrawalBalancePerToken.alpha, _withdrawalBalancePerToken.beta, _withdrawalBalancePerToken.gamma) = tokenParityStorage.withdrawalBalancePerToken(_tokenId);
        _totalValue = ParityLogic.getTotalTokenValue( _tokenBalancePerToken,  _depositBalancePerToken,
        _depositRebalancingBalancePerToken, _withdrawalBalancePerToken, _price); 
    } 


    function getTotalNetTokenValue(uint256 _tokenId, uint256[3] memory _price) public view
        returns(uint256 _totalValue){
        ParityData.Amount memory _tokenBalancePerToken;
        ParityData.Amount memory _depositBalancePerToken;
        ParityData.Amount memory _depositRebalancingBalancePerToken;
        (_tokenBalancePerToken.alpha, _tokenBalancePerToken.beta, _tokenBalancePerToken.gamma)  = tokenParityStorage.tokenBalancePerToken(_tokenId);
        (_depositBalancePerToken.alpha, _depositBalancePerToken.beta, _depositBalancePerToken.gamma)= tokenParityStorage.depositBalancePerToken(_tokenId);
        (_depositRebalancingBalancePerToken.alpha, _depositRebalancingBalancePerToken.beta, _depositRebalancingBalancePerToken.gamma) = tokenParityStorage.depositRebalancingBalancePerToken(_tokenId);
        _totalValue = ParityLogic.getNetTotalTokenValue(_tokenBalancePerToken, _depositBalancePerToken,
        _depositRebalancingBalancePerToken, _price);  
    } 


    function getAvailableTokenValue(uint256 _tokenId, uint256 _indexEvent, uint256[3] memory _price) 
        public view returns(uint256 _totalValue) { 
        ParityData.Event[] memory _depositBalancePerTokenPerEvent = tokenParityStorage.getDepositBalancePerTokenPerEvent(_tokenId);
        ParityData.Event[] memory _depositRebalancingBalancePerTokenPerEvent = tokenParityStorage.getDepositRebalancingBalancePerTokenPerEvent(_tokenId);
        ParityData.Amount memory _tokenBalancePerToken;
        (_tokenBalancePerToken.alpha, _tokenBalancePerToken.beta, _tokenBalancePerToken.gamma) = tokenParityStorage.tokenBalancePerToken(_tokenId);
        _totalValue =  ParityLogic.getAvailableTokenValue(_depositBalancePerTokenPerEvent, 
        _depositRebalancingBalancePerTokenPerEvent, _tokenBalancePerToken, _indexEvent, _price) ;
    }


    function getTokenValueToRebalance( uint256 _tokenId, uint256 _indexEvent,
        uint256[3] memory _price) public view returns(uint256, uint256, uint256, uint256){
        ParityData.Event[] memory _depositBalancePerTokenPerEvent = tokenParityStorage.getDepositBalancePerTokenPerEvent(_tokenId);
        ParityData.Event[] memory _depositRebalancingBalancePerTokenPerEvent = tokenParityStorage.getDepositRebalancingBalancePerTokenPerEvent(_tokenId);
        ParityData.Amount memory _tokenBalancePerToken;
        ParityData.Amount memory _amount;
        uint256 _totalValue;
        (_tokenBalancePerToken.alpha, _tokenBalancePerToken.beta, _tokenBalancePerToken.gamma) = tokenParityStorage.tokenBalancePerToken(_tokenId);
        (_amount.alpha, _amount.beta, _amount.gamma, _totalValue) = ParityLogic.getTokenValueToRebalance(_depositBalancePerTokenPerEvent, 
        _depositRebalancingBalancePerTokenPerEvent,
        _tokenBalancePerToken,
        _indexEvent,
        _price);
        return (_amount.alpha, _amount.beta, _amount.gamma, _totalValue);
    }


    function getRebalancingFee(uint256 _tokenId,uint256 _indexEvent,
        uint256[3] memory _price ) public view returns(uint256 _fee){
        ( , , , uint256 _totalValue) =  getTokenValueToRebalance(_tokenId,  _indexEvent,  _price);
        _fee = tokenParityStorage.managementParityParams().getRebalancingFee(_totalValue);
    }


    function getWithdrawalFee(uint256 _tokenId, uint256 _rate, uint256 _indexEvent,
        uint256[3] memory _price ) public view returns(uint256 _totalFee){
        ParityData.Amount memory _depositRebalancingAmount;
        (_depositRebalancingAmount.alpha, _depositRebalancingAmount.beta, _depositRebalancingAmount.gamma) = tokenParityStorage.depositRebalancingBalancePerToken(_tokenId);
        ParityData.Amount memory _withdrawalRebalancingAmount;
        (_withdrawalRebalancingAmount.alpha, _withdrawalRebalancingAmount.beta, _withdrawalRebalancingAmount.gamma) = tokenParityStorage.withdrawalRebalancingBalancePerToken(_tokenId);
        ParityData.Amount memory _tokenBalancePerToken;
        (_tokenBalancePerToken.alpha, _tokenBalancePerToken.beta, _tokenBalancePerToken.gamma) = tokenParityStorage.tokenBalancePerToken(_tokenId);
        uint256 _totalValue = getAvailableTokenValue(_tokenId, _indexEvent,  _price);
        (ParityData.Amount memory _amountToWithdrawFromDeposit, ParityData.Amount memory  _amountToWithdrawFromTokens) = _calculateWithdrawalData( _tokenId, _indexEvent, _rate, _totalValue, _tokenBalancePerToken, 
        _depositRebalancingAmount, _withdrawalRebalancingAmount, _price);
        _totalFee = _calculateWithdrawalFee(  _tokenId, _amountToWithdrawFromDeposit,  _amountToWithdrawFromTokens,  _price);    
    }


    function _calculateWithdrawalData(uint256 _tokenId, uint256 _indexEvent, uint256 _rate,
        uint256 _totalValue, ParityData.Amount memory _tokenBalancePerToken, 
        ParityData.Amount memory _depositRebalancingAmount, ParityData.Amount memory _withdrawalRebalancingAmount,
        uint256[3] memory _price) 
        internal view returns(ParityData.Amount memory _amountToWithdrawFromDeposit, ParityData.Amount memory  _amountToWithdrawFromTokens){
        uint256 _depositValueTotal;
        ParityData.Amount memory _depositValue;
        (_depositValueTotal, _depositValue) = _calculateDepositValue( _indexEvent, _tokenId, _depositRebalancingAmount, _withdrawalRebalancingAmount, _price);
        ( _amountToWithdrawFromDeposit,   _amountToWithdrawFromTokens) = 
        ParityLogic.calculateWithdrawalData( _rate, _totalValue, _depositValueTotal, 
        _depositValue, _tokenBalancePerToken, _price);
    }


    function _calculateWithdrawalFee(uint256 _tokenId,ParityData.Amount memory _amountToWithdrawFromDeposit, ParityData.Amount memory _amountToWithdrawFromTokens,
        uint256[3] memory _price) 
        internal view returns(uint256 _totalFee){
        uint256 _stableAmountToSend = _amountToWithdrawFromDeposit.alpha + _amountToWithdrawFromDeposit.beta +
        _amountToWithdrawFromDeposit.gamma;
        uint256 _stableFee = Math.mulDiv( _stableAmountToSend , tokenParityStorage.managementParityParams().fixedWithdrawalFee(), ParityData.COEFF_SCALE_DECIMALS);
        ParityData.Amount memory _fee; 
        ParityData.Amount memory _flowTimePerToken;
        (_flowTimePerToken.alpha, _flowTimePerToken.beta, _flowTimePerToken.gamma)  = tokenParityStorage.flowTimePerToken(_tokenId);
        ParityData.Fee[] memory _withdrawalVariableFeeData = tokenParityStorage.managementParityParams().getWithdrawalVariableFeeData();
        _fee.alpha = ParityLogic.calculateWithdrawalFees(_flowTimePerToken.alpha, _withdrawalVariableFeeData);
        _fee.beta = ParityLogic.calculateWithdrawalFees(_flowTimePerToken.beta, _withdrawalVariableFeeData);
        _fee.gamma = ParityLogic.calculateWithdrawalFees(_flowTimePerToken.gamma, _withdrawalVariableFeeData);
        _fee = ParityLogic.getWithdrawalTokenFees( _fee, _amountToWithdrawFromTokens, _price);
        _fee = ParityMath.mulMultiCoefDiv2(_fee, _price, ParityData.FACTOR_PRICE_DECIMALS);
        _totalFee =   _stableFee + _fee.alpha + _fee.beta + _fee.gamma;
    }


    function _calculateDepositValue( uint256 _indexEvent, uint256 _tokenId, ParityData.Amount memory _depositRebalancingAmount,
        ParityData.Amount memory _withdrawalRebalancingAmount, uint256[3] memory _price) 
        internal view returns(uint256 _depositValueTotal, ParityData.Amount memory _depositValue){
        ParityData.Event[] memory _depositBalancePerTokenPerEvent = tokenParityStorage.getDepositBalancePerTokenPerEvent(_tokenId);
        uint256 _indexDeposit = ParityLogic.searchIndexEvent(_depositBalancePerTokenPerEvent, _indexEvent);
        if (_indexDeposit < ParityLogic.MAX_INDEX_EVENT){
           _depositValueTotal = _depositBalancePerTokenPerEvent[_indexDeposit].amount.alpha +
           _depositBalancePerTokenPerEvent[_indexDeposit].amount.beta +
           _depositBalancePerTokenPerEvent[_indexDeposit].amount.gamma;
           _depositValue = _depositBalancePerTokenPerEvent[_indexDeposit].amount;
        }
        uint256 _totalDepositRebalancingAmount = _depositRebalancingAmount.alpha + _depositRebalancingAmount.beta +
        _depositRebalancingAmount.gamma;
        uint256 _totalWithdrawalRebalancingAmount = ( _withdrawalRebalancingAmount.alpha * _price[0] + 
        _withdrawalRebalancingAmount.beta * _price[1] + _withdrawalRebalancingAmount.gamma * _price[2])/ ParityData.FACTOR_PRICE_DECIMALS;
        if (_totalDepositRebalancingAmount > _totalWithdrawalRebalancingAmount){
            uint256 _deltaAmount =  _totalDepositRebalancingAmount - _totalWithdrawalRebalancingAmount;
            _depositValueTotal += _deltaAmount;
            _depositValue.alpha += _deltaAmount;
        }
    }


    function isCancelWithdrawalRequest(uint256 _tokenId, uint256 _indexEvent) public view
        returns (bool _isCancel, uint256 _index){
        ParityData.Event[] memory _withdrawalBalancePerTokenPerEvent = tokenParityStorage.getWithdrawalBalancePerTokenPerEvent(_tokenId);
        (_isCancel, _index) = ParityLogic.isCancelWithdrawalRequest(_withdrawalBalancePerTokenPerEvent, _indexEvent);
    }


    function getTotalDepositUntilLastEvent(uint256 _tokenId, uint256 _indexEvent, uint256 _id) public view returns 
        (uint256 _totalValue){
        ParityData.Event[] memory _depositBalancePerTokenPerEvent = tokenParityStorage.getDepositBalancePerTokenPerEvent(_tokenId);
        _totalValue = ParityLogic.getTotalValueUntilLastEventPerProduct(_depositBalancePerTokenPerEvent, 
        _indexEvent, _id);     
    }


    function getTotalWithdrawalUntilLastEvent(uint256 _tokenId, uint256 _indexEvent, uint256 _id) public view returns 
        (uint256 _totalValue){
        ParityData.Event[] memory _withdrawalBalancePerTokenPerEvent = tokenParityStorage.getWithdrawalBalancePerTokenPerEvent(_tokenId);
        _totalValue = ParityLogic.getTotalValueUntilLastEventPerProduct(_withdrawalBalancePerTokenPerEvent, 
        _indexEvent, _id);     
    }


    function getTotalDepositRebalancingUntilLastEvent(uint256 _tokenId, uint256 _indexEvent) public view returns 
        (ParityData.Amount memory _totalValue){
        ParityData.Event[] memory _depositRebalancingBalancePerTokenPerEvent = tokenParityStorage.getDepositRebalancingBalancePerTokenPerEvent(_tokenId);
        _totalValue = ParityLogic.getTotalValueUntilLastEvent(_depositRebalancingBalancePerTokenPerEvent, 
        _indexEvent);     
    }


    function getTotalWithdrawalRebalancingUntilLastEvent(uint256 _tokenId, uint256 _indexEvent,  uint256 _id) public view returns 
        (uint256 _totalValue){
         ParityData.Event[] memory _withdrawalRebalancingBalancePerTokenPerEvent = tokenParityStorage.getWithdrawalRebalancingBalancePerTokenPerEvent(_tokenId);
        _totalValue = ParityLogic.getTotalValueUntilLastEventPerProduct(_withdrawalRebalancingBalancePerTokenPerEvent, 
        _indexEvent, _id);     
    }


    function verifyBurnCondition(uint256 _tokenId) public view returns (bool _result) {
        ParityData.Amount memory _depositBalancePerToken;
        (_depositBalancePerToken.alpha, _depositBalancePerToken.beta, _depositBalancePerToken.gamma) = tokenParityStorage.depositBalancePerToken(_tokenId);
        ParityData.Amount memory _withdrawalBalancePerToken;
        (_withdrawalBalancePerToken.alpha, _withdrawalBalancePerToken.beta, _withdrawalBalancePerToken.gamma) = tokenParityStorage.withdrawalBalancePerToken(_tokenId);
        ParityData.Amount memory _tokenBalancePerToken;
        (_tokenBalancePerToken.alpha, _tokenBalancePerToken.beta, _tokenBalancePerToken.gamma) = tokenParityStorage.tokenBalancePerToken(_tokenId);
        ParityData.Amount memory _depositRebalancingBalancePerToken;
        (_depositRebalancingBalancePerToken.alpha, _depositRebalancingBalancePerToken.beta, _depositRebalancingBalancePerToken.gamma) = tokenParityStorage.depositRebalancingBalancePerToken(_tokenId);
        _result = ParityLogic.verifyBurnCondition( _depositBalancePerToken, _withdrawalBalancePerToken, _tokenBalancePerToken, 
        _depositRebalancingBalancePerToken);
    }
    

    function getwithdrawalFeeRate(uint256 _tokenId) public view returns (ParityData.Amount memory _fee) {
        ParityData.Fee[] memory _withdrawalVariableFeeData = tokenParityStorage.managementParityParams().getWithdrawalVariableFeeData();
        ParityData.Amount memory _flowTimePerToken;
        (_flowTimePerToken.alpha, _flowTimePerToken.beta, _flowTimePerToken.gamma)  = tokenParityStorage.flowTimePerToken(_tokenId);
        _fee.alpha = ParityLogic.calculateWithdrawalFees(_flowTimePerToken.alpha, _withdrawalVariableFeeData);
        _fee.beta = ParityLogic.calculateWithdrawalFees(_flowTimePerToken.beta, _withdrawalVariableFeeData);
        _fee.gamma = ParityLogic.calculateWithdrawalFees(_flowTimePerToken.gamma, _withdrawalVariableFeeData);
    }

}