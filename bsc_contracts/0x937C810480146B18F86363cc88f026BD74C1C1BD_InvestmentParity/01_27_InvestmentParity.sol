// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../main/libraries/SafeBEP20.sol";
import "../utils/Pausable.sol";
import "./TokenParity.sol";
import "./TokenParityView.sol";
import "./ParityLine.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract InvestmentParity.
*/

contract InvestmentParity is Pausable {
    using SafeBEP20  for IBEP20 ;
    using Math for uint256;

    struct Risk {
        uint256 low;
        uint256 medium;
        uint256 high;
    }
    uint256 public tokenId = 4;
    Risk public risk;
    IManagementParityParams public managementParityParams;
    IManagementParity public managementParity;
    TokenParity public tokenParity;
    TokenParityStorage public tokenParityStorage;
    TokenParityView public tokenParityView;
    ParityLine public parityLine;

    event DepositRequest(ParityData.Position _position);
    event WithdrawalRequest(uint256 _tokenId, uint256 _rate);
    event CancelWithdrawalRequest(uint256 _tokenId);
    event RebalanceRequest(ParityData.Position _position);
    event SetDefaultRisk(uint256 _low, uint256 _medium, uint256 _high);

    constructor(address _managementParity, address _managementParityParams,
        address _tokenParity, address _tokenParityStorage, address _tokenParityView,
        address _parityLine) {

        require(_managementParity != address(0),
            "Formation.Fi: zero address");
        
        require(_managementParityParams != address(0),
            "Formation.Fi: zero address");

        require(_tokenParity != address(0),
            "Formation.Fi: zero address");

        require(_tokenParityStorage != address(0),
            "Formation.Fi: zero address");

        require(_tokenParityView != address(0),
            "Formation.Fi: zero address");

        require(_parityLine != address(0),
            "Formation.Fi: zero address");

        managementParity = IManagementParity(_managementParity);
        managementParityParams = IManagementParityParams(_managementParityParams);
        tokenParity = TokenParity(_tokenParity);
        tokenParityStorage = TokenParityStorage(_tokenParityStorage);
        tokenParityView = TokenParityView(_tokenParityView);
        parityLine = ParityLine(_parityLine);
    }

    modifier onlyManager() {
        require (msg.sender == managementParityParams.manager(), 
        "Formation.Fi: no manager");
        _;
    }

    function setTokenParity(address _tokenParity) external onlyOwner {
        require(_tokenParity != address(0),
            "Formation.Fi: zero address");
        tokenParity = TokenParity(_tokenParity);
    }

    function setTokenStorage(address _tokenParityStorage) external onlyOwner {
        require(_tokenParityStorage != address(0),
            "Formation.Fi: zero address");
        tokenParityStorage = TokenParityStorage(_tokenParityStorage);
    }

    function setTokenParityView(address _tokenParityView) external onlyOwner {
        require(_tokenParityView != address(0),
            "Formation.Fi: zero address");
        tokenParityView = TokenParityView(_tokenParityView);
    }

    function setManagementParity(address _managementParity) external onlyOwner {
        require(_managementParity != address(0),
            "Formation.Fi: zero address");
        managementParity = IManagementParity(_managementParity);
    }

    function setManagementParityParams(address _managementParityParams) external onlyOwner {
        require(_managementParityParams != address(0),
            "Formation.Fi: zero address");
        managementParityParams = IManagementParityParams(_managementParityParams);
    }

    function setParityLine(address _parityLine) external onlyOwner {
        require(_parityLine != address(0),
            "Formation.Fi: zero address");
        parityLine = ParityLine(_parityLine);
    }

    function setDefaultRisk(uint256 _low, uint256 _medium, 
        uint256 _high) external onlyManager {
        risk = Risk(_low, _medium, _high);
        emit SetDefaultRisk(_low, _medium, _high);
    }
   
    function depositRequestWithLowRisk(address _account, uint256 _amount, 
        uint256 _tokenId) external whenNotPaused {
        ParityData.Position memory _position = ParityData.Position(_tokenId, _amount, 1, risk.low, 0 , ParityData.Amount(0, 0, 0));
        depositRequest(_account, _position);
    }

    function depositRequestWithMediumRisk(address _account, uint256 _amount,
        uint256 _tokenId) external whenNotPaused {
        ParityData.Position memory _position = ParityData.Position(_tokenId, _amount, 1, risk.medium, 0 , ParityData.Amount(0, 0, 0));
        depositRequest(_account, _position);
    }
    function depositRequestWithHighRisk(address _account, uint256 _amount, 
        uint256 _tokenId) external whenNotPaused {
        ParityData.Position memory _position = ParityData.Position(_tokenId, _amount, 1, risk.high, 0 , ParityData.Amount(0, 0, 0));
        depositRequest(_account, _position);
    }
        
    function depositRequest(address _account, ParityData.Position memory _position) 
        public whenNotPaused{
        require( (_position.userOption >= 1) && (_position.userOption <= 3), 
            "Formation.Fi: option is out of range");
        require(_position.amount >= getMinAmountDeposit(), 
            "Formation.Fi: min amount");
        if (_position.userOption == 1){
            (_position.userReturn, _position.userWeights.alpha, _position.userWeights.beta, 
            _position.userWeights.gamma) = parityLine.ConvertRisk( _position.userRisk);
        }
        else if ( _position.userOption == 2){
            (_position.userRisk, _position.userWeights.alpha, _position.userWeights.beta, 
            _position.userWeights.gamma) = parityLine.ConvertReturn(_position.userReturn);
        }
        else{
            require((_position.userWeights.alpha + _position.userWeights.beta + 
            _position.userWeights.gamma) == ParityData.COEFF_SCALE_DECIMALS , 
                "Formation.Fi: sum weights");
            (_position.userRisk, _position.userReturn) = parityLine.ConvertWeights(_position.userWeights.alpha, 
            _position.userWeights.beta, _position.userWeights.gamma); 
        }
        uint256[3] memory _price = managementParity.getPrice();
        uint256 _indexEvent = managementParity.indexEvent();
        _position.amount = _sendFees(_position.amount, msg.sender);
        bool _isFirst;
        if (_position.tokenId == 0){
            tokenId = tokenId + 1;
            _position.tokenId = tokenId;
            _isFirst = true;
        }
        tokenParity.mint(_account, _position, _indexEvent, _price, _isFirst);
        IBEP20 _stableToken = managementParity.getStableToken();
        uint256 _amountScaleDecimals = managementParity.amountScaleDecimals();
        if (_position.amount >0){
            _stableToken.safeTransferFrom(msg.sender, address(managementParity), 
            _position.amount /_amountScaleDecimals);
        }
        emit DepositRequest(_position);  
    }

    function withdrawRequest(uint256 _tokenId, uint256 _rate) 
        external whenNotPaused {
        require (msg.sender == tokenParity.ownerOf(_tokenId), 
            "Formation Fi: no owner");
        require (( _rate > 0) && ( _rate <= ParityData.COEFF_SCALE_DECIMALS), 
            "Formation Fi: not in range");
        uint256 _indexEvent = managementParity.indexEvent();
        uint256[3] memory _price = managementParity.getPrice();
        tokenParityStorage.withdrawalRequest(_tokenId, _indexEvent, _rate, _price, msg.sender);
        emit WithdrawalRequest(_tokenId, _rate);
    }  

    function cancelWithdrawRequest(uint256 _tokenId) 
        external whenNotPaused {
        require (msg.sender == tokenParity.ownerOf(_tokenId), 
            "Formation Fi: no owner");
        uint256 _indexEvent = managementParity.indexEvent();
        uint256[3] memory _price = managementParity.getPrice();
        tokenParityStorage.cancelWithdrawalRequest(_tokenId, _indexEvent, _price);
        emit CancelWithdrawalRequest(_tokenId);
    }  

    function rebalanceRequest(ParityData.Position memory _position) 
        external whenNotPaused {
        require (msg.sender == tokenParity.ownerOf(_position.tokenId), 
            "Formation Fi: no owner");
        _position.amount = _sendFees(_position.amount, msg.sender);
        IBEP20 _stableToken = managementParity.getStableToken();
        uint256 _amountScaleDecimals = managementParity.amountScaleDecimals();
        if (_position.amount >0){
            _stableToken.safeTransferFrom(msg.sender, address(managementParity), 
            _position.amount / _amountScaleDecimals);
        }
        _rebalanceRequest(_position, false);
    }  

    function rebalanceManagerRequest(uint256[] memory _tokenIds) 
    external {
        require(managementParityParams.isManager(msg.sender) == true, 
            "Formation.Fi: no manager");
        ParityData.Amount memory _weights;
        ParityData.Position memory _position;
        for (uint256 i = 0; i < _tokenIds.length ; ++i) {    
            if (tokenParity.ownerOf(_tokenIds[i]) == address(0)){
                break;
            }
            _position.tokenId = _tokenIds[i];
            _position.amount = 0;
            (_weights.alpha, _weights.beta, _weights.gamma) = 
            tokenParityStorage.weightsPerToken(_tokenIds[i]);
            _position.userWeights = _weights;
            _position.userOption = tokenParityStorage.optionPerToken(_tokenIds[i]);
            _position.userRisk = tokenParityStorage.riskPerToken(_tokenIds[i]);
            _position.userReturn = tokenParityStorage.returnPerToken(_tokenIds[i]);
            _rebalanceRequest(_position, true);
        }
    } 

    function CloseParityPosition(uint256 _tokenId) external {
        address _owner = tokenParity.ownerOf(_tokenId); 
        require((msg.sender == _owner) || (managementParityParams.isManager(msg.sender) == true), 
            "Formation.Fi: neither owner nor manager");
        tokenParity.burn(_tokenId);
    }
     
    function getTotalTokenValue(uint256 _tokenId) public view 
        returns (uint256 _value){
        uint256[3] memory _price = managementParity.getPrice();
        _value = tokenParityView.getTotalTokenValue(_tokenId, _price);
    }

    function getTotalNetTokenValue(uint256 _tokenId) public view 
        returns (uint256 _value){
        uint256[3] memory _price = managementParity.getPrice();
        _value = tokenParityView.getTotalNetTokenValue(_tokenId, _price);
    }

    function getAvailableTokenValue(uint256 _tokenId) public view 
        returns (uint256 _value){
        uint256 _indexEvent = managementParity.indexEvent();
        uint256[3] memory _price = managementParity.getPrice();
        _value = tokenParityView.getAvailableTokenValue(_tokenId, _indexEvent, _price); 
    }
    
    function getRebalancingFee(uint256 _tokenId) public view
        returns(uint256 _fee){
        uint256 _indexEvent = managementParity.indexEvent();
        uint256[3] memory _price = managementParity.getPrice();
        _fee = tokenParityView.getRebalancingFee(_tokenId, _indexEvent, _price );
    }

    function getWithdrawalFee(uint256 _tokenId, uint256 _rate) public view
        returns(uint256 _fee){
        uint256 _indexEvent = managementParity.indexEvent();
        uint256[3] memory _price = managementParity.getPrice();
        _fee = tokenParityView.getWithdrawalFee(_tokenId, _rate,  _indexEvent,
        _price );
    }
    
    function getParityTVL() public view returns (uint256 _tvl) {
        (IBEP20 _tokenAlpha, IBEP20 _tokenBeta, IBEP20 _tokenGamma) = managementParity.getToken();
        uint256[3] memory _price = managementParity.getPrice();
        _tvl = (_tokenAlpha.balanceOf(address(managementParity)) * _price[0] + 
        _tokenBeta.balanceOf(address(managementParity)) * _price[1] + 
        _tokenGamma.balanceOf(address(managementParity)) * _price[2])/ ParityData.FACTOR_PRICE_DECIMALS;
    }

    function isCancelWithdrawalRequest(uint256 _tokenId) public view returns (bool _isCancel) {
        uint256 _indexEvent = managementParity.indexEvent();
        (_isCancel, ) = tokenParityView.isCancelWithdrawalRequest(_tokenId, _indexEvent);
    }

    function getDepositFee(uint256 _amount) public view returns (uint256 _fee){
        _fee = managementParityParams.getDepositFee(_amount);
    }

    function getMinAmountDeposit() public view returns (uint256){
        return managementParityParams.depositMinAmount();
    }

    function _rebalanceRequest(ParityData.Position memory _position, bool _isFree) internal {
        require( (_position.userOption >= 1) && (_position.userOption <= 3), 
            "Formation.Fi:  choice not in range");
        require (tokenParity.ownerOf(_position.tokenId)!= address(0), 
            "Formation.Fi: no token");
        if (_position.userOption == 1 ){
            (_position.userReturn, _position.userWeights.alpha, _position.userWeights.beta, 
            _position.userWeights.gamma) = parityLine.ConvertRisk(_position.userRisk);
         }
        else if (_position.userOption == 2){
            (_position.userRisk, _position.userWeights.alpha, _position.userWeights.beta, 
            _position.userWeights.gamma) = parityLine.ConvertReturn(_position.userReturn);
        }
        else {
            require((_position.userWeights.alpha + _position.userWeights.beta + 
            _position.userWeights.gamma) == ParityData.COEFF_SCALE_DECIMALS , 
                "Formation.Fi: sum weights");
            (_position.userRisk, _position.userReturn) = parityLine.ConvertWeights(_position.userWeights.alpha, _position.userWeights.beta,
            _position.userWeights.gamma); 
        }
        uint256[3] memory _price = managementParity.getPrice();
        uint256 _indexEvent = managementParity.indexEvent();
        tokenParityStorage.rebalanceParityPosition(_position , _indexEvent, _price, _isFree);
        emit RebalanceRequest(_position);

    }

    function _sendFees(uint256 _amount, address _caller) internal returns (uint256 _newAmount){
        if (_amount > 0){
            uint256 _fee = getDepositFee( _amount);
            _newAmount = _amount - _fee;
            if (_fee > 0){
                IBEP20 _stableToken = managementParity.getStableToken();
                uint256 _amountScaleDecimals = managementParity.amountScaleDecimals();
                _stableToken.safeTransferFrom(_caller, 
                managementParityParams.treasury(), _fee / _amountScaleDecimals);
            }
        }
    }

}