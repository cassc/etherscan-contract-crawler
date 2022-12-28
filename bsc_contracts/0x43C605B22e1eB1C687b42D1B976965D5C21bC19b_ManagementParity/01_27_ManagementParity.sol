// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../main/IBEP20.sol";
import "../main/libraries/SafeBEP20.sol";
import "./libraries/ParityMath.sol";
import "./EventDataParity.sol";
import "./ManagementParityParams.sol";
import "./TokenParityView.sol";
import "./TokenParity.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract ManagementParity.

*/

contract ManagementParity is  IERC721Receiver, Ownable {
    using SafeBEP20  for IBEP20 ;
    using Math for uint256;
    uint256 public constant APPROVED_AMOUNT = 1e50;
    struct Input {
        uint256 totalDepositOld;
        uint256 totalWithdrawalOld;  
        uint256 totalRebalancingWithdrawalOld;
        uint256 tokenBalance;
        uint256 validatedDepositBalance;
        uint256 stableBalance;
        uint256 validatedWithdrawalBalance;
        uint256 validatedRebalancingWithdrawalBalance;
        uint256 price;
    }
    struct Output{
       uint256 distributedTokenBalance;
       uint256 distributedValidatedDepositBalance;
       uint256 distributedStableBalance;
       uint256 distributedValidatedWithdrawalBalance;
       uint256 distributedValidatedRebalancingWithdrawalBalance;
    }
    
    uint256 public amountScaleDecimals; 
    uint256 public rebalancingStableBalance;
    uint256 public indexEvent = 8;
    ParityData.Amount public tokenBalance;
    ParityData.Amount public stableBalance;
    ParityData.Amount public validatedDepositBalance;
    ParityData.Amount public validatedWithdrawalBalance;
    ParityData.Amount public validatedRebalancingWithdrawalBalance;
    ParityData.Amount public distributedValidatedDepositBalance;
    ParityData.Amount public distributedValidatedWithdrawalBalance;
    ParityData.Amount public distributedValidatedRebalancingWithdrawalBalance;
    ParityData.Amount public distributedStableBalance;
    ParityData.Amount public distributedTokenBalance;
    ParityData.Amount public netWithdrawalAmountEvent;
    ParityData.Amount public netRebalancingWithdrawalAmountEvent;
    ParityData.Amount public netDepositAmountEvent;
    ParityData.Amount public netRebalancingDepositAmountEvent;
    ParityData.Amount public InvestedWithdrawalAmount;
    ParityData.Amount public InvestedRebalancingWithdrawalAmount;
    IBEP20 public tokenAlpha;
    IBEP20 public tokenBeta;    
    IBEP20 public tokenGamma; 
    IBEP20 public stableToken; 
    EventDataParity public eventDataParity; 
    ManagementParityParams public managementParityParams;
    
    constructor( address _eventDataParity, address _managementParityParams,
        address _tokenAlpha, address _tokenBeta, address _tokenGamma,
        address  _stableToken) {

        require(_eventDataParity != address(0),
            "Formation.Fi: zero address");
        require(_managementParityParams!= address(0),
            "Formation.Fi: zero address");
        require(_tokenAlpha != address(0),
            "Formation.Fi: zero address");
        require(_tokenBeta != address(0),
            "Formation.Fi: zero address");
        require(_tokenGamma != address(0),
            "Formation.Fi: zero address");
        require(_stableToken != address(0),
            "Formation.Fi: zero address");
        eventDataParity = EventDataParity(_eventDataParity);
        managementParityParams = ManagementParityParams(_managementParityParams);
        tokenAlpha = IBEP20(_tokenAlpha);
        tokenBeta = IBEP20(_tokenBeta);
        tokenGamma = IBEP20(_tokenGamma);
        stableToken= IBEP20(_stableToken);
        uint8 _stableTokenDecimals = uint8(18) - stableToken.decimals();
        amountScaleDecimals= 10 ** _stableTokenDecimals;
    }

    modifier onlyManager() {
        require(managementParityParams.isManager(msg.sender) == true, 
            "Formation.Fi: no manager");
        _;
    }


    function getStableBalance() public view returns (uint256) {
        return stableToken.balanceOf(address(this));
    }

    function getStableToken() public view returns(IBEP20){
        return stableToken;
    }

    function getPrice() public view returns(uint256[3] memory _price){
        _price[0] = eventDataParity.alpha().getTokenPrice();
        _price[1] = eventDataParity.beta().getTokenPrice();
        _price[2] = eventDataParity.gamma().getTokenPrice();
    }

    function getToken() public view returns(IBEP20 , IBEP20, IBEP20){
        return (tokenAlpha, tokenBeta, tokenGamma);
    }

    function seteventDataParity(address _eventDataParity) public onlyOwner {
         require(_eventDataParity != address(0),
            "Formation.Fi: zero address"
        );
        eventDataParity = EventDataParity(_eventDataParity);     
    }

    function setManagementParityParams(address _managementParityParams) public onlyOwner{
         require(_managementParityParams!= address(0),
            "Formation.Fi: zero address"
        );
        managementParityParams = ManagementParityParams(_managementParityParams);   
    }

    function setToken(address _tokenAlpha, address _tokenBeta,
        address _tokenGamma) external onlyOwner {
        require(_tokenAlpha!= address(0),
            "Formation.Fi: zero address");
        require(_tokenBeta!= address(0),
            "Formation.Fi: zero address");
         require(_tokenGamma!= address(0),
            "Formation.Fi: zero address");
        tokenAlpha = IBEP20(_tokenAlpha);
        tokenBeta = IBEP20(_tokenBeta);
        tokenGamma = IBEP20(_tokenGamma);
    }

    function setStableToken(address _stableToken) external onlyOwner {
        require(_stableToken != address(0),
            "Formation.Fi: zero address");
        stableToken = IBEP20(_stableToken);
        uint8 _stableTokenDecimals = uint8(18) - stableToken.decimals();
        amountScaleDecimals = 10 ** _stableTokenDecimals;
    }

    function calculateNetAmountEvent() external onlyManager {
        _calculateNetAmountEvent();
        indexEvent += 1;
    }

    function depositManagerRequest() external onlyManager {
        _deposit(address(this), netDepositAmountEvent);
        netDepositAmountEvent = ParityData.Amount(0,0,0);
    }


    function withdrawManagerRequest() external onlyManager {
        ParityData.Amount memory _withdrawalAmount;
        _withdrawalAmount = ParityMath.add2( netWithdrawalAmountEvent, netRebalancingWithdrawalAmountEvent);
        ParityMath.add(InvestedWithdrawalAmount, netWithdrawalAmountEvent);
        ParityMath.add(InvestedRebalancingWithdrawalAmount, netRebalancingWithdrawalAmountEvent);
        netWithdrawalAmountEvent = ParityData.Amount(0,0,0);
        netRebalancingWithdrawalAmountEvent = ParityData.Amount(0,0,0);
        _withdraw(_withdrawalAmount);
    }

    function rebalancingDepositManagerRequest() external onlyManager {
        ParityData.Amount memory _amount;
        uint256 _amountDepositRebalancing;
        _amountDepositRebalancing = netRebalancingDepositAmountEvent.alpha +  netRebalancingDepositAmountEvent.beta + netRebalancingDepositAmountEvent.gamma;
        if (_amountDepositRebalancing >0 ){
            _amount.alpha = Math.min( netRebalancingDepositAmountEvent.alpha, Math.mulDiv(netRebalancingDepositAmountEvent.alpha, rebalancingStableBalance,
            _amountDepositRebalancing)) ;
            _amount.beta = Math.min( netRebalancingDepositAmountEvent.beta, Math.mulDiv(netRebalancingDepositAmountEvent.beta, rebalancingStableBalance,
            _amountDepositRebalancing)) ;
            _amount.gamma = Math.min(netRebalancingDepositAmountEvent.gamma, Math.mulDiv(netRebalancingDepositAmountEvent.gamma, rebalancingStableBalance, 
            _amountDepositRebalancing));
            ParityMath.sub(netRebalancingDepositAmountEvent, _amount);
            rebalancingStableBalance = 0;
            _deposit(address(eventDataParity),  _amount);
        }
    }

    function setDepositData(uint256 _amountMinted, uint256 _amountValidated, 
        uint256 _id) external {
        require(_id >= 0 && _id <=2, 
            "Formation.Fi: not in range");    
        require((_amountMinted > 0) && (_amountValidated > 0), 
            "Formation.Fi: zero amount");
        if (_id == 0){  
            IInvestment _alpha = eventDataParity.alpha();
            require(msg.sender == address(_alpha), 
                "Formation.Fi: no caller");
            tokenBalance.alpha += _amountMinted; 
            validatedDepositBalance.alpha += _amountValidated;   
        }
        else if (_id == 1){
            IInvestment _beta = eventDataParity.beta();
            require(msg.sender == address(_beta), 
                "Formation.Fi: no caller");    
            tokenBalance.beta += _amountMinted; 
            validatedDepositBalance.beta += _amountValidated;          
        }
        else {
            IInvestment _gamma = eventDataParity.gamma();
            require(msg.sender == address(_gamma), 
                "Formation.Fi: no caller");
            tokenBalance.gamma += _amountMinted; 
            validatedDepositBalance.gamma += _amountValidated; 
        }        
    }

    function setWithdrawalData(uint256 _amountMinted, uint256 _amountValidated,
        uint256 _id) external { 
        uint256 _netAmountEventTotal;
        require(_id >= 0 && _id <=2, 
            "Formation.Fi: not in range");    
        require((_amountMinted > 0) && (_amountValidated> 0), 
            "Formation.Fi: zero amount");
        uint256 _amount;
        uint256 _validatedWithdrawalBalance;
        uint256 _validatedRebalancingWithdrawalBalance;
        if (_id == 0){  
            IInvestment _alpha = eventDataParity.alpha();
            require(msg.sender == address(_alpha), 
                "Formation.Fi: no caller"); 
            _netAmountEventTotal = InvestedWithdrawalAmount.alpha + InvestedRebalancingWithdrawalAmount.alpha;
            _amount = Math.mulDiv(_amountMinted, InvestedWithdrawalAmount.alpha, _netAmountEventTotal);
            stableBalance.alpha += _amount; 
            _validatedWithdrawalBalance = Math.mulDiv(_amountValidated, InvestedWithdrawalAmount.alpha, _netAmountEventTotal); 
            _validatedRebalancingWithdrawalBalance = Math.mulDiv(_amountValidated, InvestedRebalancingWithdrawalAmount.alpha, _netAmountEventTotal); 
            validatedWithdrawalBalance.alpha += _validatedWithdrawalBalance;
            validatedRebalancingWithdrawalBalance.alpha += _validatedRebalancingWithdrawalBalance;
            rebalancingStableBalance += _amountMinted - _amount;
            InvestedWithdrawalAmount.alpha -= _validatedWithdrawalBalance;
            InvestedRebalancingWithdrawalAmount.alpha -= _validatedRebalancingWithdrawalBalance;

        }  
        else if (_id == 1){
            IInvestment _beta = eventDataParity.beta();
            require(msg.sender == address(_beta), 
                "Formation.Fi: no caller");  
            _netAmountEventTotal = InvestedWithdrawalAmount.beta + InvestedRebalancingWithdrawalAmount.beta;
            _amount = Math.mulDiv(_amountMinted, InvestedWithdrawalAmount.beta, _netAmountEventTotal);
            stableBalance.beta += _amount; 
            _validatedWithdrawalBalance = Math.mulDiv(_amountValidated, InvestedWithdrawalAmount.beta, _netAmountEventTotal); 
            _validatedRebalancingWithdrawalBalance = Math.mulDiv(_amountValidated, InvestedRebalancingWithdrawalAmount.beta, _netAmountEventTotal); 
            validatedWithdrawalBalance.beta += _validatedWithdrawalBalance;
            validatedRebalancingWithdrawalBalance.beta += _validatedRebalancingWithdrawalBalance;
            rebalancingStableBalance += _amountMinted - _amount;
            InvestedWithdrawalAmount.beta -= _validatedWithdrawalBalance;
            InvestedRebalancingWithdrawalAmount.beta -= _validatedRebalancingWithdrawalBalance; 
        }
        else {
            IInvestment _gamma = eventDataParity.gamma();
            require(msg.sender == address(_gamma), 
                "Formation.Fi: no caller");
            _netAmountEventTotal = InvestedWithdrawalAmount.gamma + InvestedRebalancingWithdrawalAmount.gamma;
            _amount = Math.mulDiv(_amountMinted, InvestedWithdrawalAmount.gamma, _netAmountEventTotal);
            stableBalance.gamma += _amount; 
            _validatedWithdrawalBalance = Math.mulDiv(_amountValidated, InvestedWithdrawalAmount.gamma, _netAmountEventTotal); 
            _validatedRebalancingWithdrawalBalance = Math.mulDiv(_amountValidated, InvestedRebalancingWithdrawalAmount.gamma, _netAmountEventTotal); 
            validatedWithdrawalBalance.gamma += _validatedWithdrawalBalance;
            validatedRebalancingWithdrawalBalance.gamma += _validatedRebalancingWithdrawalBalance;
            rebalancingStableBalance += _amountMinted - _amount;
            InvestedWithdrawalAmount.gamma -= _validatedWithdrawalBalance;
            InvestedRebalancingWithdrawalAmount.gamma -= _validatedRebalancingWithdrawalBalance;             
        }          
    }

    function distributeAlphaToken(uint256[] memory _tokenIds) external onlyManager(){
        (uint256 _totalDepositOld, , )  = eventDataParity.totalDepositAmountOld();
        (uint256 _totalWithdrawalOld, , ) = eventDataParity.totalWithdrawalAmountOld();
        (uint256 _totalRebalancingWithdrawalOld, , ) = eventDataParity.totalRebalancingWithdrawalAmountOld();
        Output memory _output;
        TokenParityStorage _tokenParityStorage = eventDataParity.tokenParityStorage();
        TokenParity _tokenParity = eventDataParity.tokenParity();
        TokenParityView _tokenParityView = eventDataParity.tokenParityView();
        uint256 _price = eventDataParity.alpha().getTokenPrice();
        _output = _distributeTokens (Input(_totalDepositOld, _totalWithdrawalOld, _totalRebalancingWithdrawalOld, 
        tokenBalance.alpha, validatedDepositBalance.alpha, stableBalance.alpha,
        validatedWithdrawalBalance.alpha, validatedRebalancingWithdrawalBalance.alpha, _price), _tokenIds, 0, 
        _tokenParityStorage, _tokenParity, _tokenParityView);
        distributedTokenBalance.alpha += _output.distributedTokenBalance;
        distributedValidatedDepositBalance.alpha += _output.distributedValidatedDepositBalance;
        distributedStableBalance.alpha += _output.distributedStableBalance;
        distributedValidatedWithdrawalBalance.alpha += _output.distributedValidatedWithdrawalBalance;  
        distributedValidatedRebalancingWithdrawalBalance.alpha += _output.distributedValidatedRebalancingWithdrawalBalance;
    }

    function distributeBetaToken(uint256[] memory _tokenIds) external onlyManager(){
        ( ,uint256 _totalDepositOld, )  = eventDataParity.totalDepositAmountOld();
        ( ,uint256 _totalWithdrawalOld, ) = eventDataParity.totalWithdrawalAmountOld();
        ( ,uint256 _totalRebalancingWithdrawalOld, ) = eventDataParity.totalRebalancingWithdrawalAmountOld();
        Output memory _output;
        TokenParityStorage _tokenParityStorage = eventDataParity.tokenParityStorage();
        TokenParity _tokenParity = eventDataParity.tokenParity();
        TokenParityView _tokenParityView = eventDataParity.tokenParityView();
        uint256 _price = eventDataParity.beta().getTokenPrice();
        _output = _distributeTokens (Input(_totalDepositOld, _totalWithdrawalOld, _totalRebalancingWithdrawalOld, 
        tokenBalance.beta,  validatedDepositBalance.beta, stableBalance.beta,
        validatedWithdrawalBalance.beta, validatedRebalancingWithdrawalBalance.beta, _price), _tokenIds, 1,  
        _tokenParityStorage, _tokenParity, _tokenParityView);
        distributedTokenBalance.beta += _output.distributedTokenBalance;
        distributedValidatedDepositBalance.beta += _output.distributedValidatedDepositBalance;
        distributedStableBalance.beta += _output.distributedStableBalance;
        distributedValidatedWithdrawalBalance.beta += _output.distributedValidatedWithdrawalBalance;
        distributedValidatedRebalancingWithdrawalBalance.beta += _output.distributedValidatedRebalancingWithdrawalBalance;  
    }

    function distributeGammaToken(uint256[] memory _tokenIds) external onlyManager(){
        ( , ,uint256 _totalDepositOld)  = eventDataParity.totalDepositAmountOld();
        ( , ,uint256 _totalWithdrawalOld) = eventDataParity.totalWithdrawalAmountOld();
        ( , ,uint256 _totalRebalancingWithdrawalOld) = eventDataParity.totalRebalancingWithdrawalAmountOld();
        Output memory _output;
        TokenParityStorage _tokenParityStorage = eventDataParity.tokenParityStorage();
        TokenParity _tokenParity = eventDataParity.tokenParity();
        TokenParityView _tokenParityView = eventDataParity.tokenParityView();
        uint256 _price = eventDataParity.gamma().getTokenPrice();
        _output = _distributeTokens (Input(_totalDepositOld, _totalWithdrawalOld, _totalRebalancingWithdrawalOld, 
        tokenBalance.gamma,  validatedDepositBalance.gamma, stableBalance.gamma,
        validatedWithdrawalBalance.gamma, validatedRebalancingWithdrawalBalance.gamma, _price), _tokenIds, 2,
        _tokenParityStorage, _tokenParity, _tokenParityView);
        distributedTokenBalance.gamma += _output.distributedTokenBalance;
        distributedValidatedDepositBalance.gamma += _output.distributedValidatedDepositBalance;
        distributedStableBalance.gamma += _output.distributedStableBalance;
        distributedValidatedWithdrawalBalance.gamma += _output.distributedValidatedWithdrawalBalance;
        distributedValidatedRebalancingWithdrawalBalance.gamma += _output.distributedValidatedRebalancingWithdrawalBalance;  
    }

    function distributeRebalancingToken(uint256[] memory _tokenIds) 
        external onlyManager {
        eventDataParity.distributeRebalancingToken(_tokenIds, indexEvent); 
    }

    function sendTokenFee(ParityData.Amount memory _fee) external {
        TokenParityStorage _tokenParityStorage = eventDataParity.tokenParityStorage();
        require(msg.sender == address(_tokenParityStorage), 
           "Formation.Fi: no required caller");
        address _treasury = managementParityParams.treasury();
        if (_fee.alpha >0){
            tokenAlpha.safeTransfer(_treasury, _fee.alpha);
        }
        if (_fee.beta >0){
            tokenBeta.safeTransfer(_treasury, _fee.beta);
        }
        if (_fee.gamma >0){
            tokenGamma.safeTransfer(_treasury, _fee.gamma);
        }
    }

    function sendBackWithdrawalFee(ParityData.Amount memory _amount) external {
        TokenParityStorage _tokenParityStorage = eventDataParity.tokenParityStorage();
        require(msg.sender == address(_tokenParityStorage), 
           "Formation.Fi: no required caller");
        address _treasury = managementParityParams.treasury();
        if (_amount.alpha >0){
            tokenAlpha.safeTransferFrom(_treasury, address(this), _amount.alpha);
        }
        if (_amount.beta >0){
            tokenAlpha.safeTransferFrom(_treasury, address(this), _amount.beta);
        }
        if (_amount.gamma >0){
             tokenAlpha.safeTransferFrom(_treasury, address(this), _amount.gamma);
        }
    }

    function sendStableFee(address _account, uint256 _amount, uint256  _fee) external {
        TokenParityStorage _tokenParityStorage = eventDataParity.tokenParityStorage();
        require(msg.sender == address(_tokenParityStorage), 
            "Formation.Fi: no required caller");
        address _treasury = managementParityParams.treasury();
        if (_amount > 0 ){
            stableToken.safeTransfer(_account, _amount/ amountScaleDecimals);
        }
        if (_fee > 0){
            stableToken.safeTransfer(_treasury, _fee/ amountScaleDecimals);
        }
    }

    function withdrawStable(uint256 _amount) external {
        address _manager = managementParityParams.manager();
        require(msg.sender == _manager, 
            "Formation.Fi: no manager");
        stableToken.safeTransfer(_manager, _amount);
    }

    function withdrawToken(IBEP20 _token, uint256 _amount) external {
        address _manager = managementParityParams.manager();
        require(msg.sender == _manager, 
            "Formation.Fi: no manager");
        _token.safeTransfer(_manager, _amount);
    }

    function _calculateNetAmountEvent() internal {
        ParityMath.sub(tokenBalance, distributedTokenBalance);
        ParityMath.sub(stableBalance, distributedStableBalance);
        distributedTokenBalance = ParityData.Amount(0,0,0);
        distributedStableBalance = ParityData.Amount(0,0,0);
        _updateValidatedData();
        eventDataParity.updateOldData(distributedValidatedDepositBalance, 
        distributedValidatedWithdrawalBalance, distributedValidatedRebalancingWithdrawalBalance);
        distributedValidatedDepositBalance = ParityData.Amount(0, 0,0);
        distributedValidatedWithdrawalBalance = ParityData.Amount(0, 0,0);
        distributedValidatedRebalancingWithdrawalBalance = ParityData.Amount(0, 0,0);
        eventDataParity.updateTotalRebalancingStableAmount();
        eventDataParity.calculateNetAmountEvent();
        _updateEventData(); 
    }

    function _deposit(address _to, ParityData.Amount memory _amount) internal {
        if (_amount.alpha > 0) {
            IInvestment _alpha = eventDataParity.alpha();
            _investmentDeposit(_alpha, _amount.alpha, _to);
        }

        if (_amount.beta > 0){
            IInvestment _beta = eventDataParity.beta();
            _investmentDeposit (_beta, _amount.beta, _to);
        }

        if (_amount.gamma > 0){
             IInvestment _gamma = eventDataParity.gamma();
            _investmentDeposit (_gamma, _amount.gamma, _to);
        } 
    }

    function _withdraw(ParityData.Amount memory _amount ) internal {
        if (_amount.alpha > 0){
            IInvestment _alpha = eventDataParity.alpha();
            _investmentWithdraw(_alpha, tokenAlpha, _amount.alpha ); 
        } 

        if (_amount.beta > 0){
            IInvestment _beta = eventDataParity.beta();
            _investmentWithdraw(_beta, tokenBeta, _amount.beta);
        } 

        if (_amount.gamma > 0){
            IInvestment _gamma = eventDataParity.gamma();
            _investmentWithdraw(_gamma, tokenGamma, _amount.gamma);
        } 
    }
  
    function _distributeTokens (Input memory _input, uint256[] memory _tokenIds, uint256 _id,
        TokenParityStorage _tokenParityStorage, TokenParity _tokenParity, TokenParityView _tokenParityView) 
        internal  returns (Output memory _output){
        require (indexEvent >0, "Formation.Fi : no event");
        _output = _distributeDepositToken( _input,  _tokenIds, _id, _tokenParity, 
        _tokenParityStorage, _tokenParityView);
        _output =  _distributeWithdrawalToken( _input,  _output,  _tokenIds, _id, _tokenParity,
        _tokenParityStorage,  _tokenParityView);            
    }

    function _distributeDepositToken(Input memory _input, uint256[] memory _tokenIds, 
        uint256 _id, TokenParity _tokenParity,
        TokenParityStorage _tokenParityStorage, TokenParityView _tokenParityView)
        internal returns (Output memory  _output){
        uint256 _token;
        uint256 _depositAmount; 
        for (uint256 i = 0; i < _tokenIds.length ; ++i) {
            require(_tokenParity.ownerOf(_tokenIds[i])!= address(0), 
             "Formation.Fi: zero address");
            _depositAmount = _tokenParityView.getTotalDepositUntilLastEvent(_tokenIds[i], 
                indexEvent, _id);
            if ((_input.totalDepositOld > 0) && (_depositAmount > 0)){
                _token = Math.mulDiv(_depositAmount, _input.tokenBalance, _input.totalDepositOld);
                _depositAmount = Math.min(_depositAmount, Math.mulDiv(_depositAmount, _input.validatedDepositBalance, 
                _input.totalDepositOld));
                _token = Math.min(_token, Math.mulDiv(_depositAmount, ParityData.FACTOR_PRICE_DECIMALS, _input.price)); 
                _output.distributedTokenBalance += _token;
                _output.distributedValidatedDepositBalance += _depositAmount;
                _tokenParityStorage.updateDepositBalancePerToken(_tokenIds[i], _depositAmount, indexEvent, _id);
                _tokenParityStorage.updateTokenBalancePerToken(_tokenIds[i], _token, _id);
            }
        }
    }

    function _distributeWithdrawalToken(Input memory _input, Output memory _output1, 
        uint256[] memory _tokenIds, uint256 _id, TokenParity _tokenParity,
        TokenParityStorage _tokenParityStorage, TokenParityView _tokenParityView)
        internal returns (Output memory _output2){
        uint256 _withdrawalAmount;
        uint256 _stable;
        _output2 =  _output1;
        for (uint256 i = 0; i < _tokenIds.length ; ++i) {
            require(_tokenParity.ownerOf(_tokenIds[i])!= address(0), 
                "Formation.Fi: zero address");
            _withdrawalAmount = _tokenParityView.getTotalWithdrawalUntilLastEvent(_tokenIds[i],
            indexEvent, _id);
            if ((_input.totalWithdrawalOld >0) && (_withdrawalAmount > 0)){
                _stable = Math.mulDiv(_withdrawalAmount, _input.stableBalance, _input.totalWithdrawalOld);
                _withdrawalAmount = Math.min(_withdrawalAmount, Math.mulDiv(_withdrawalAmount, _input.validatedWithdrawalBalance
                , _input.totalWithdrawalOld));
                _stable = Math.min(_stable, Math.mulDiv(_withdrawalAmount, _input.price, ParityData.FACTOR_PRICE_DECIMALS));
                _output2.distributedStableBalance += _stable;
                _output2.distributedValidatedWithdrawalBalance += _withdrawalAmount;
                _tokenParityStorage.updateWithdrawalBalancePerToken(_tokenIds[i], _withdrawalAmount, indexEvent, _id);
                stableToken.safeTransfer(_tokenParity.ownerOf(_tokenIds[i]), _stable / amountScaleDecimals);     
            }
            _withdrawalAmount = _tokenParityView.getTotalWithdrawalRebalancingUntilLastEvent(_tokenIds[i],
            indexEvent, _id);
            if ((_input.totalRebalancingWithdrawalOld >0) && (_withdrawalAmount > 0)){
                _withdrawalAmount = Math.min(_withdrawalAmount, Math.mulDiv(_withdrawalAmount, _input.validatedRebalancingWithdrawalBalance,
                _input.totalRebalancingWithdrawalOld));
                _output2.distributedValidatedRebalancingWithdrawalBalance += _withdrawalAmount;
                _tokenParityStorage.updateRebalancingWithdrawalBalancePerToken(_tokenIds[i], _withdrawalAmount, indexEvent, _id);
            }
        }
    }

    function _updateEventData() internal {
        ParityData.Amount memory _tokenBalance;
        ParityData.Amount memory _stableBalance;
        ParityData.Amount memory _validatedDepositBalance;
        ParityData.Amount memory _validatedWithdrawalBalance;
        ParityData.Amount memory _validatedRebalancingWithdrawalBalance;
        ParityData.Amount memory _netAmountEvent;
        ParityData.Amount memory _netAmountRebalancingEvent;
        ParityData.Amount memory _netDepositInd;
        ParityData.Amount memory _netRebalancingDepositInd;
        (_tokenBalance.alpha, _tokenBalance.beta, _tokenBalance.gamma) =  
        eventDataParity.totalTokenAmount();
        (_stableBalance.alpha, _stableBalance.beta, _stableBalance.gamma) =  
        eventDataParity.totalStableAmount();
        (_validatedDepositBalance.alpha, _validatedDepositBalance.beta, _validatedDepositBalance.gamma) =  
        eventDataParity.validatedDepositBalance();
        (_validatedWithdrawalBalance.alpha, _validatedWithdrawalBalance.beta, _validatedWithdrawalBalance.gamma) =  
        eventDataParity.validatedWithdrawalBalance();
        (_validatedRebalancingWithdrawalBalance.alpha, _validatedRebalancingWithdrawalBalance.beta, _validatedRebalancingWithdrawalBalance.gamma) =  
        eventDataParity.validatedRebalancingWithdrawalBalance();
        ParityMath.add(tokenBalance, _tokenBalance);
        ParityMath.add(validatedDepositBalance, _validatedDepositBalance);
        ParityMath.add(stableBalance, _stableBalance);
        ParityMath.add(validatedWithdrawalBalance, _validatedWithdrawalBalance);
        ParityMath.add(validatedRebalancingWithdrawalBalance, _validatedRebalancingWithdrawalBalance);
        rebalancingStableBalance += eventDataParity.totalRebalancingStableAmount();
        (_netDepositInd.alpha, _netDepositInd.beta, _netDepositInd.gamma) = 
        eventDataParity.netDepositInd();
        (_netRebalancingDepositInd.alpha, _netRebalancingDepositInd.beta, 
        _netRebalancingDepositInd.gamma) = eventDataParity.netRebalancingDepositInd();
        (_netAmountEvent.alpha, _netAmountEvent.beta, _netAmountEvent.gamma) =
        eventDataParity.netAmountEvent();
        (_netAmountRebalancingEvent.alpha, _netAmountRebalancingEvent.beta, 
        _netAmountRebalancingEvent.gamma) = eventDataParity.netAmountRebalancingEvent();
        netWithdrawalAmountEvent.alpha += (1 - _netDepositInd.alpha) * _netAmountEvent.alpha;
        netWithdrawalAmountEvent.beta += (1 - _netDepositInd.beta) * _netAmountEvent.beta;
        netWithdrawalAmountEvent.gamma += (1 - _netDepositInd.gamma) * _netAmountEvent.gamma;
        netDepositAmountEvent.alpha += _netDepositInd.alpha * _netAmountEvent.alpha;
        netDepositAmountEvent.beta += _netDepositInd.beta * _netAmountEvent.beta;
        netDepositAmountEvent.gamma +=  _netDepositInd.gamma * _netAmountEvent.gamma;
        netRebalancingWithdrawalAmountEvent.alpha += (1 - _netRebalancingDepositInd.alpha) * _netAmountRebalancingEvent.alpha;
        netRebalancingWithdrawalAmountEvent.beta += (1 - _netRebalancingDepositInd.beta) * _netAmountRebalancingEvent.beta;
        netRebalancingWithdrawalAmountEvent.gamma += (1 - _netRebalancingDepositInd.gamma) * _netAmountRebalancingEvent.gamma;
        netRebalancingDepositAmountEvent.alpha +=  _netRebalancingDepositInd.alpha * _netAmountRebalancingEvent.alpha;
        netRebalancingDepositAmountEvent.beta +=  _netRebalancingDepositInd.beta * _netAmountRebalancingEvent.beta;
        netRebalancingDepositAmountEvent.gamma +=  _netRebalancingDepositInd.gamma * _netAmountRebalancingEvent.gamma;

    }

    function _investmentDeposit (IInvestment _product, uint256 _amount, address _to) internal {
        if ( stableToken.allowance(address(this), address(_product))<
            _amount){
            stableToken.approve(address(_product), APPROVED_AMOUNT);
        }
        _product.depositRequest(_to, _amount);
    }

    function _investmentWithdraw(IInvestment _product, IBEP20 _token,  uint256 _amount) internal {
        if (_token.allowance(address(this), address(_product)) < 
            _amount){
            _token.approve(address(_product), APPROVED_AMOUNT);
        }
            _product.withdrawRequest(_amount);
    }

    function _updateValidatedData() internal {
        validatedDepositBalance.alpha -= Math.min(validatedDepositBalance.alpha, distributedValidatedDepositBalance.alpha);
        validatedDepositBalance.beta -= Math.min(validatedDepositBalance.beta, distributedValidatedDepositBalance.beta);
        validatedDepositBalance.gamma -= Math.min(validatedDepositBalance.gamma, distributedValidatedDepositBalance.gamma);
        validatedWithdrawalBalance.alpha -= Math.min(validatedWithdrawalBalance.alpha, distributedValidatedWithdrawalBalance.alpha);
        validatedWithdrawalBalance.beta -= Math.min(validatedWithdrawalBalance.beta, distributedValidatedWithdrawalBalance.beta);
        validatedWithdrawalBalance.gamma -= Math.min(validatedWithdrawalBalance.gamma, distributedValidatedWithdrawalBalance.gamma);
        validatedRebalancingWithdrawalBalance.alpha -= Math.min(validatedRebalancingWithdrawalBalance.alpha, distributedValidatedRebalancingWithdrawalBalance.alpha);
        validatedRebalancingWithdrawalBalance.beta -= Math.min(validatedRebalancingWithdrawalBalance.beta, distributedValidatedRebalancingWithdrawalBalance.beta);
        validatedRebalancingWithdrawalBalance.gamma -= Math.min(validatedRebalancingWithdrawalBalance.gamma, distributedValidatedRebalancingWithdrawalBalance.gamma);
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