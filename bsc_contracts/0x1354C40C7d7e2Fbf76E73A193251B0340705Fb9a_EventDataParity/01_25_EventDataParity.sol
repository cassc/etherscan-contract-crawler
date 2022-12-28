// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/ParityMath.sol";
import "./TokenParityView.sol";
import "./TokenParity.sol";

interface IInvestment{
    function getTokenPrice() external view returns(uint256); 
    function depositRequest(address _user, uint256 _amount) external;
    function withdrawRequest(uint256 _amount) external;
}

/** 
* @author Formation.Fi.
* @notice Implementation of the contract EventDataParity.
*/
contract EventDataParity is Ownable, IERC721Receiver {
    using Math for uint256;
    struct Event{
        uint256 netDepositInd;  
        uint256 netAmountEvent;
        uint256 totalStableAmount;
        uint256 totalTokenAmount; 
        uint256 netRebalancingDepositInd;
        uint256 netAmountRebalancingEvent;
        uint256 totalRebalancingStableAmount;
        uint256 totalRebalancingTokenAmount;
        uint256 totalRebalancingValidatedDepositAmount;
        uint256 validatedRebalancingWithdrawalBalance;
    }
    
    uint256 public totalRebalancingStableAmount;
    ParityData.Amount public  totalTokenAmount;
    ParityData.Amount public  totalStableAmount;
    ParityData.Amount public  validatedDepositBalance;
    ParityData.Amount public  validatedWithdrawalBalance;
    ParityData.Amount public  validatedRebalancingWithdrawalBalance;
    ParityData.Amount public  netDepositInd;
    ParityData.Amount public  netAmountEvent; 
    ParityData.Amount public  totalDepositAmountOld;
    ParityData.Amount public  totalRebalancingDepositAmount;
    ParityData.Amount public  totalRebalancingWithdrawalAmountOld;
    ParityData.Amount public  distributedRebalancingValidatedDepositAmount;
    ParityData.Amount public  totalRebalancingDepositAmountOld;
    ParityData.Amount public  totalRebalancingWithdrawalAmount;
    ParityData.Amount public  netRebalancingDepositInd;
    ParityData.Amount public  netAmountRebalancingEvent;
    ParityData.Amount public  totalWithdrawalAmountOld;
    ParityData.Amount public  totalRebalancingTokenAmount;
    ParityData.Amount public  totalRebalancingValidatedDepositAmount;
    ParityData.Amount public  distributedRebalancingTokenAmount;
    IInvestment public alpha; 
    IInvestment public beta;
    IInvestment public gamma;
    TokenParityStorage public tokenParityStorage;
    TokenParity public tokenParity;
    TokenParityView public tokenParityView;
    IManagementParity public managementParity;
    constructor(address _tokenParity, address _tokenParityStorage, 
        address _tokenParityView, address _alpha, address _beta, 
        address _gamma) {
        
        require(_tokenParity != address(0),
            "Formation.Fi:  zero address");
        require(_tokenParityStorage != address(0),
            "Formation.Fi:  zero address");

         require(_tokenParityView != address(0),
            "Formation.Fi:  zero address");
        require(_alpha != address(0),
            "Formation.Fi: zero address");
        require(_beta != address(0),
            "Formation.Fi: zero address");
        require(_gamma != address(0),
            "Formation.Fi: zero address");
        
        alpha = IInvestment(_alpha);
        beta = IInvestment(_beta);
        gamma = IInvestment(_gamma);
        tokenParity = TokenParity(_tokenParity);
        tokenParityStorage = TokenParityStorage(_tokenParityStorage);
        tokenParityView = TokenParityView(_tokenParityView);
    }

    modifier onlyManagementParity() {
        require(address(managementParity) != address(0),
            "Formation.Fi:  zero address");
        require(msg.sender == address(managementParity),
             "Formation.Fi:  not investement");
        _;
    }

    function setManagementParity(address _managementParity) external onlyOwner {
        require(_managementParity!= address(0),
            "Formation.Fi: zero address");
       managementParity = IManagementParity(_managementParity);
    }

    function setTokenParityStorage(address _tokenParity, address _tokenParityStorage, 
        address _tokenParityView) external onlyOwner {
        require(_tokenParity!= address(0),
            "Formation.Fi: zero address");
        require(_tokenParityStorage!= address(0),
            "Formation.Fi: zero address");
        require(_tokenParityView!= address(0),
            "Formation.Fi: zero address");
        tokenParity = TokenParity(_tokenParity);
        tokenParityStorage = TokenParityStorage(_tokenParityStorage);
        tokenParityView = TokenParityView(_tokenParityView); 
    }

    function setInvestment(address _alpha, address _beta,
        address _gamma) external onlyOwner {
        require(_alpha!= address(0),
            "Formation.Fi: zero address");
        require(_beta!= address(0),
            "Formation.Fi: zero address");
        require(_gamma!= address(0),
            "Formation.Fi: zero address");
        alpha = IInvestment(_alpha);
        beta = IInvestment(_beta);
        gamma = IInvestment(_gamma);
    }
   
    function updateOldData(ParityData.Amount memory _depositAmount, 
        ParityData.Amount memory _withdrawalAmount,  ParityData.Amount memory _rebalancingWithdrawalAmount) 
        external onlyManagementParity{
        totalDepositAmountOld.alpha -= Math.min(totalDepositAmountOld.alpha, _depositAmount.alpha);
        totalDepositAmountOld.beta -= Math.min(totalDepositAmountOld.beta, _depositAmount.beta);
        totalDepositAmountOld.gamma -= Math.min(totalDepositAmountOld.gamma, _depositAmount.gamma);
        totalWithdrawalAmountOld.alpha -= Math.min(totalWithdrawalAmountOld.alpha, _withdrawalAmount.alpha);
        totalWithdrawalAmountOld.beta -= Math.min(totalWithdrawalAmountOld.beta, _withdrawalAmount.beta);
        totalWithdrawalAmountOld.gamma -= Math.min(totalWithdrawalAmountOld.gamma, _withdrawalAmount.gamma);
        totalRebalancingWithdrawalAmountOld.alpha -= Math.min(totalRebalancingWithdrawalAmountOld.alpha, _rebalancingWithdrawalAmount.alpha);
        totalRebalancingWithdrawalAmountOld.beta -= Math.min(totalRebalancingWithdrawalAmountOld.beta, _rebalancingWithdrawalAmount.beta);
        totalRebalancingWithdrawalAmountOld.gamma -= Math.min(totalRebalancingWithdrawalAmountOld.gamma, _rebalancingWithdrawalAmount.gamma);
    }

    function updateTotalRebalancingStableAmount() external onlyManagementParity {
        totalRebalancingStableAmount = 0;
    }

    function calculateNetAmountEvent() external onlyManagementParity {
        ParityData.Amount memory _rebalancingDepositAmount;
        ParityData.Amount memory _rebalancingWithdrawalAmount;
        ParityData.Amount memory _totalDepositAmount;
        ParityData.Amount memory _totalWithdrawalAmount;
        Event memory _event;

        (_rebalancingDepositAmount.alpha, _rebalancingDepositAmount.beta,
        _rebalancingDepositAmount.gamma) = tokenParityStorage.depositRebalancingBalance();
        (_rebalancingWithdrawalAmount.alpha, _rebalancingWithdrawalAmount.beta,
         _rebalancingWithdrawalAmount.gamma) = tokenParityStorage.withdrawalRebalancingBalance();
        (_totalDepositAmount.alpha, _totalDepositAmount.beta,
         _totalDepositAmount.gamma) = tokenParityStorage.depositBalance();
        (_totalWithdrawalAmount.alpha, _totalWithdrawalAmount.beta,
        _totalWithdrawalAmount.gamma) = tokenParityStorage.withdrawalBalance();
        ParityMath.add(totalRebalancingDepositAmountOld, _rebalancingDepositAmount);
        ParityMath.sub(totalRebalancingDepositAmountOld, distributedRebalancingValidatedDepositAmount);
        ParityMath.sub(totalRebalancingValidatedDepositAmount, distributedRebalancingValidatedDepositAmount);
        ParityMath.add(totalRebalancingWithdrawalAmountOld, _rebalancingWithdrawalAmount);
        ParityMath.add(totalDepositAmountOld, _totalDepositAmount);
        ParityMath.add(totalWithdrawalAmountOld, _totalWithdrawalAmount);

        uint256 _price; 
        _price = alpha.getTokenPrice();
        _event = _calculateNetAmountEvent(_rebalancingDepositAmount.alpha, _rebalancingWithdrawalAmount.alpha, 
        _totalDepositAmount.alpha, _totalWithdrawalAmount.alpha, _price);
        netDepositInd.alpha = _event.netDepositInd;
        netAmountEvent.alpha = _event.netAmountEvent;
        netRebalancingDepositInd.alpha = _event.netRebalancingDepositInd;
        netAmountRebalancingEvent.alpha = _event.netAmountRebalancingEvent;
        totalStableAmount.alpha = _event.totalStableAmount;
        totalTokenAmount.alpha = _event.totalTokenAmount;
        validatedDepositBalance.alpha = Math.mulDiv(_event.totalTokenAmount, _price, ParityData.FACTOR_PRICE_DECIMALS);
        validatedWithdrawalBalance.alpha = Math.mulDiv(_event.totalStableAmount, ParityData.FACTOR_PRICE_DECIMALS, _price);
        totalRebalancingTokenAmount.alpha -= Math.min(totalRebalancingTokenAmount.alpha, distributedRebalancingTokenAmount.alpha);
        totalRebalancingTokenAmount.alpha += _event.totalRebalancingTokenAmount;
        totalRebalancingValidatedDepositAmount.alpha += _event.totalRebalancingValidatedDepositAmount;
        validatedRebalancingWithdrawalBalance.alpha = _event.validatedRebalancingWithdrawalBalance;
        validatedRebalancingWithdrawalBalance.alpha += _event.totalRebalancingTokenAmount;
        totalRebalancingStableAmount += _event.totalRebalancingStableAmount;
        
        _price = beta.getTokenPrice();
        _event = _calculateNetAmountEvent( _rebalancingDepositAmount.beta, _rebalancingWithdrawalAmount.beta, 
        _totalDepositAmount.beta, _totalWithdrawalAmount.beta, _price);
        netDepositInd.beta = _event.netDepositInd;
        netAmountEvent.beta = _event.netAmountEvent;
        netRebalancingDepositInd.beta = _event.netRebalancingDepositInd;
        netAmountRebalancingEvent.beta = _event.netAmountRebalancingEvent;
        totalStableAmount.beta = _event.totalStableAmount;
        totalTokenAmount.beta = _event.totalTokenAmount;
        validatedDepositBalance.beta = Math.mulDiv(_event.totalTokenAmount, _price, ParityData.FACTOR_PRICE_DECIMALS);
        validatedWithdrawalBalance.beta = Math.mulDiv(_event.totalStableAmount, ParityData.FACTOR_PRICE_DECIMALS, _price);
        totalRebalancingTokenAmount.beta -= Math.min(totalRebalancingTokenAmount.beta, distributedRebalancingTokenAmount.beta);
        totalRebalancingTokenAmount.beta += _event.totalRebalancingTokenAmount;
        totalRebalancingValidatedDepositAmount.beta += _event.totalRebalancingValidatedDepositAmount;
        validatedRebalancingWithdrawalBalance.beta = _event.validatedRebalancingWithdrawalBalance;
        validatedRebalancingWithdrawalBalance.beta += _event.totalRebalancingTokenAmount;
        totalRebalancingStableAmount += _event.totalRebalancingStableAmount;
        
        _price = gamma.getTokenPrice();
        _event = _calculateNetAmountEvent( _rebalancingDepositAmount.gamma, _rebalancingWithdrawalAmount.gamma, 
        _totalDepositAmount.gamma, _totalWithdrawalAmount.gamma, _price);
        netDepositInd.gamma = _event.netDepositInd;
        netAmountEvent.gamma = _event.netAmountEvent;
        netRebalancingDepositInd.gamma = _event.netRebalancingDepositInd;
        netAmountRebalancingEvent.gamma = _event.netAmountRebalancingEvent;
        totalStableAmount.gamma = _event.totalStableAmount;
        totalTokenAmount.gamma = _event.totalTokenAmount;
        validatedDepositBalance.gamma = Math.mulDiv(_event.totalTokenAmount, _price , ParityData.FACTOR_PRICE_DECIMALS);
        validatedWithdrawalBalance.gamma = Math.mulDiv(_event.totalStableAmount, ParityData.FACTOR_PRICE_DECIMALS, _price);
        totalRebalancingTokenAmount.gamma -= Math.min(totalRebalancingTokenAmount.gamma, distributedRebalancingTokenAmount.gamma);
        totalRebalancingTokenAmount.gamma += _event.totalRebalancingTokenAmount;
        totalRebalancingValidatedDepositAmount.gamma += _event.totalRebalancingValidatedDepositAmount;
        validatedRebalancingWithdrawalBalance.gamma = _event.validatedRebalancingWithdrawalBalance;
        validatedRebalancingWithdrawalBalance.gamma += _event.totalRebalancingTokenAmount;
        totalRebalancingStableAmount += _event.totalRebalancingStableAmount;
        totalRebalancingStableAmount += managementParity.getStableBalance() - (
        _totalDepositAmount.alpha + _totalDepositAmount.beta + _totalDepositAmount.gamma);
        tokenParityStorage.updateTotalBalances(_totalDepositAmount, _totalWithdrawalAmount, 
        _rebalancingDepositAmount, _rebalancingWithdrawalAmount);
        distributedRebalancingTokenAmount = ParityData.Amount(0,0,0);
        distributedRebalancingValidatedDepositAmount = ParityData.Amount(0,0,0);
    }
    
    function _calculateNetAmountEvent(uint256 _rebalancingDepositAmount, 
        uint256 _rebalancingWithdrawalAmount, uint256 _totalDepositAmount, 
        uint256 _totalWithdrawalAmount, uint256 _price) internal pure
        returns (Event memory _event) {
        uint256 _rebalancingWithdrawalStableAmount = Math.mulDiv(_rebalancingWithdrawalAmount, _price, ParityData.FACTOR_PRICE_DECIMALS);
        (_event.netRebalancingDepositInd, _event.netAmountRebalancingEvent, ,_event.totalRebalancingTokenAmount) =
        _calculateNetDepositInd(_rebalancingDepositAmount, _rebalancingWithdrawalStableAmount, 
        _rebalancingWithdrawalAmount,  _price);
        uint256 _totalWithdrawalStableAmount = Math.mulDiv(_totalWithdrawalAmount,  _price, ParityData.FACTOR_PRICE_DECIMALS);
        (_event.netDepositInd, _event.netAmountEvent, _event.totalStableAmount, _event.totalTokenAmount) =
        _calculateNetDepositInd(_totalDepositAmount, _totalWithdrawalStableAmount, 
        _totalWithdrawalAmount, _price);
        if (( _event.netDepositInd == 1 ) && ( _event.netRebalancingDepositInd == 0 )) {
            uint256 _minAmount = Math.min( _event.netAmountEvent, _event.netAmountRebalancingEvent * _price / ParityData.FACTOR_PRICE_DECIMALS);
            _event.netAmountEvent -= _minAmount;
            _event.totalTokenAmount += Math.mulDiv(_minAmount, ParityData.FACTOR_PRICE_DECIMALS, _price);
            _event.netAmountRebalancingEvent -= Math.mulDiv(_minAmount, ParityData.FACTOR_PRICE_DECIMALS, _price);
            _event.totalRebalancingStableAmount += _minAmount;
            _event.validatedRebalancingWithdrawalBalance += Math.mulDiv(_minAmount, ParityData.FACTOR_PRICE_DECIMALS, _price);
        }
        uint256 _rebalancingStableAmount = Math.mulDiv( _event.totalRebalancingTokenAmount, _price, ParityData.FACTOR_PRICE_DECIMALS);
        _event.totalRebalancingValidatedDepositAmount = _rebalancingStableAmount;
    }

    function _calculateNetDepositInd(uint256 _totalDepositAmount, 
        uint256 _totalWithdrawalStableAmount, uint256 _totalWithdrawalAmount, 
        uint256 _price) internal pure
        returns (uint256 _netDepositInd, uint256 _netAmountEvent, 
        uint256 _totalStableAmount, uint256 _totalTokenAmount){
        if ( _totalDepositAmount > _totalWithdrawalStableAmount) {
            _netDepositInd = 1;
            _netAmountEvent = _totalDepositAmount - _totalWithdrawalStableAmount;
            _totalStableAmount = _totalWithdrawalStableAmount;
            _totalTokenAmount = _totalWithdrawalAmount; 
        }
        else {
            _netDepositInd = 0;
            _netAmountEvent = Math.mulDiv((_totalWithdrawalStableAmount - _totalDepositAmount), ParityData.FACTOR_PRICE_DECIMALS,
            _price);
            _totalStableAmount =  _totalDepositAmount;
            _totalTokenAmount = Math.mulDiv( _totalDepositAmount, ParityData.FACTOR_PRICE_DECIMALS,
            _price);
        }  
    }

    function setDepositData(uint256 _amountMinted, uint256 _amountValidated, 
        uint256 _id) external {
        require(_id >= 0 && _id <=2, "Formation.Fi: not in range");    
        require((_amountMinted > 0) && (_amountValidated> 0), 
        "Formation.Fi: zero amount");
        if (_id == 0){  
            require(msg.sender == address(alpha), 
                "Formation.Fi: no caller");
            totalRebalancingTokenAmount.alpha += _amountMinted;
            totalRebalancingValidatedDepositAmount.alpha += _amountValidated; 
        }
        else if (_id == 1){
            require(msg.sender == address(beta), 
                "Formation.Fi: no caller");    
            totalRebalancingTokenAmount.beta += _amountMinted;
            totalRebalancingValidatedDepositAmount.beta += _amountValidated;            
        }
        else {
            require(msg.sender == address(gamma), 
                "Formation.Fi: no caller");
            totalRebalancingTokenAmount.gamma += _amountMinted; 
            totalRebalancingValidatedDepositAmount.gamma += _amountValidated; 
        }               
    }

    function distributeRebalancingToken(uint256[] memory _tokenIds, uint256 _indexEvent) 
        external onlyManagementParity {
        require (_indexEvent >0, 
            "Formation.Fi : no event");
        ParityData.Amount memory _totalRebalancingTokenAmount =
        totalRebalancingTokenAmount;
        ParityData.Amount memory _totalRebalancingValidatedDepositAmount = 
        totalRebalancingValidatedDepositAmount;
        ParityData.Amount memory _token;
        ParityData.Amount memory _deposit; 
        ParityData.Amount memory _validatedStable;
        ParityData.Amount memory _price = ParityData.Amount(alpha.getTokenPrice(), beta.getTokenPrice(), gamma.getTokenPrice());
        for (uint256 i = 0; i < _tokenIds.length ; ++i) {
            require(tokenParity.ownerOf(_tokenIds[i])!= address(0), 
                "Formation.Fi: zero address");
            _deposit = tokenParityView.getTotalDepositRebalancingUntilLastEvent(_tokenIds[i],  _indexEvent);
            if ((_deposit.alpha> 0) && (totalRebalancingDepositAmountOld.alpha> 0)){
                _validatedStable.alpha = Math.min(_deposit.alpha, Math.mulDiv(_deposit.alpha, _totalRebalancingValidatedDepositAmount.alpha,
                totalRebalancingDepositAmountOld.alpha));
                _token.alpha = Math.min(Math.mulDiv(_deposit.alpha, _totalRebalancingTokenAmount.alpha, 
                totalRebalancingDepositAmountOld.alpha), Math.mulDiv(_validatedStable.alpha, ParityData.FACTOR_PRICE_DECIMALS, _price.alpha));
                distributedRebalancingTokenAmount.alpha += _token.alpha;
                distributedRebalancingValidatedDepositAmount.alpha += _validatedStable.alpha;
                tokenParityStorage.updateRebalancingDepositBalancePerToken(_tokenIds[i], _validatedStable.alpha,
                 _indexEvent, 0);
                tokenParityStorage.updateTokenBalancePerToken(_tokenIds[i], _token.alpha, 0);
            }
            if ((_deposit.beta> 0) && (totalRebalancingDepositAmountOld.beta > 0)){
                _validatedStable.beta = Math.min(_deposit.beta, Math.mulDiv(_deposit.beta, _totalRebalancingValidatedDepositAmount.beta,
                totalRebalancingDepositAmountOld.beta));
                _token.beta = Math.min(Math.mulDiv(_deposit.beta, _totalRebalancingTokenAmount.beta,
                totalRebalancingDepositAmountOld.beta), Math.mulDiv(_validatedStable.beta, ParityData.FACTOR_PRICE_DECIMALS, _price.beta));
                distributedRebalancingTokenAmount.beta += _token.beta;
                distributedRebalancingValidatedDepositAmount.beta += _validatedStable.beta;
                tokenParityStorage.updateRebalancingDepositBalancePerToken(_tokenIds[i],  _validatedStable.beta, 
                _indexEvent, 1);
                tokenParityStorage.updateTokenBalancePerToken(_tokenIds[i], _token.beta, 1);
            }
            if ((_deposit.gamma> 0) && ( totalRebalancingDepositAmountOld.gamma> 0)){
                _validatedStable.gamma = Math.min(_deposit.gamma, Math.mulDiv(_deposit.gamma, _totalRebalancingValidatedDepositAmount.gamma,
                totalRebalancingDepositAmountOld.gamma));
                _token.gamma = Math.min(Math.mulDiv(_deposit.gamma, _totalRebalancingTokenAmount.gamma, 
                totalRebalancingDepositAmountOld.gamma), Math.mulDiv(_validatedStable.gamma, ParityData.FACTOR_PRICE_DECIMALS, _price.gamma));
                distributedRebalancingTokenAmount.gamma += _token.gamma;
                distributedRebalancingValidatedDepositAmount.gamma += _validatedStable.gamma;
                tokenParityStorage.updateRebalancingDepositBalancePerToken(_tokenIds[i],  _validatedStable.gamma,
                _indexEvent, 2);
                tokenParityStorage.updateTokenBalancePerToken(_tokenIds[i], _token.gamma, 2);
            }
        }
    }
    
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory) 
        public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

}