// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/math/Math.sol"; 
import "../utils/Pausable.sol";
import "./libraries/SafeBEP20.sol";
import "./Management.sol";
import "./DepositConfirmation.sol";
import "./WithdrawalConfirmation.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract Investement.
*/

interface IManagementParityInterface {
    function setDepositData(uint256 _amountMinted, uint256 _amountValidated, 
         uint256 _id) external;
    function setWithdrawalData(uint256 _amountMinted, uint256 _amountValidated, 
         uint256 _id) external;
}

interface IEventDataParityInterface {
    function setDepositData(uint256 _amountMinted, uint256 _amountValidated, 
        uint256 _id) external;
}

contract Investment is Pausable {
    using SafeBEP20 for IBEP20;
    using Math for uint256;

    uint256 public constant FACTOR_FEES_DECIMAL = 1e4;
    uint256 public constant FACTOR_PRICE_DECIMALS = 1e18;
    uint256 public product;
    uint256 public maxDeposit;
    uint256 public maxWithdrawal;
    uint256 public tokenPrice;
    uint256 public tokenPriceMean;
    uint256 public netDepositInd;
    uint256 public netAmountEvent;
    uint256 public withdrawalAmountTotal = 1;
    uint256 public withdrawalAmountTotalOld;
    uint256 public depositAmountTotal;
    uint256 public tokenTotalSupply;
    uint256 public tokenIdDeposit = 21;
    uint256 public tokenIdWithdraw = 16;

    mapping(address => uint256) private acceptedWithdrawalPerAddress;
    Management public management;
    DepositConfirmation public deposit;
    WithdrawalConfirmation public withdrawal;
    IManagementParityInterface public managementParity;
    IEventDataParityInterface public eventDataParity;
    event DepositRequest(address indexed _account, uint256 _amount);
    event CancelDepositRequest(address indexed _account, uint256 _amount);
    event WithdrawalRequest(address indexed _account, uint256 _amount);
    event CancelWithdrawalRequest(address indexed _account, uint256 _amount);
    event ValidateDeposit(address indexed _account, uint256 _validatedAmount, uint256 _mintedAmount);
    event ValidateWithdrawal(address indexed _account, uint256 _validatedAmount, uint256 _SentAmount);
   
    constructor(uint256 _product, address _management,  
        address _depositConfirmationAddress, 
        address _withdrawalConfirmationAddress) {
        require(_product >= 0 && _product <=2, 
        "Formation.Fi: not in range"); 
        require(
            _management != address(0),
            "Formation.Fi: zero address"
        );
        require(
           _depositConfirmationAddress != address(0),
            "Formation.Fi:  zero address"
        );
        require(
            _withdrawalConfirmationAddress != address(0),
            "Formation.Fi:  zero address"
        );
        product = _product;
        management = Management(_management);
        deposit = DepositConfirmation(_depositConfirmationAddress);
        withdrawal = WithdrawalConfirmation(_withdrawalConfirmationAddress);
    }
  
    modifier onlyManager() {
        require( management.isManager(msg.sender) == true, 
         "Formation.Fi: no manager");
        _;
    }

    modifier cancel() {
        bool _isCancel = management.isCancel();
        require( _isCancel == true, "Formation.Fi: no cancel");
        _;
    }

    /**
     * @dev getter functions.
    */

    function getTokenPrice() public view returns(uint256){
        return  management.tokenPrice();
    }

    function getDepositFee(uint256 _amount) public view returns (uint256){
        return management.getDepositFee(_amount);
    }

    /**
     * @dev Setter functions.
    */
    function setManagement(address _management) external onlyOwner {
        require(
            _management != address(0),
            "Formation.Fi: zero address"
        );
        management = Management(_management);
    }

    function setDepositConfirmation(address _depositConfirmationAddress) external onlyOwner {
        require(
            _depositConfirmationAddress != address(0),
            "Formation.Fi: zero address"
        );
        deposit = DepositConfirmation(_depositConfirmationAddress);
    }

    function setWithdrawalConfirmation(address _withdrawalConfirmationAddress) external onlyOwner {
        require(
            _withdrawalConfirmationAddress != address(0),
            "Formation.Fi: zero address"
        );
        withdrawal = WithdrawalConfirmation(_withdrawalConfirmationAddress);
    }
    
    function setManagementParity(address _address) external onlyOwner{
        require(
            _address != address(0),
            "Formation.Fi: zero address"
        );
        managementParity = IManagementParityInterface(_address);      
    }

     function setEventDataParity(address _address) external onlyOwner{
        require(
            _address != address(0),
            "Formation.Fi: zero address"
        );
        eventDataParity = IEventDataParityInterface(_address);      
    }
    
    /**
     * @dev Calculate the event parameters by the manager. 
    */
    function calculateEventParameters() external onlyManager {
        calculateNetAmountEvent();
        calculateMaxDepositAmount();
        calculateMaxWithdrawAmount();
    }

    /**
     * @dev Validate the deposit requests of users by the manager.
     * @param _accounts the addresses of users.
    */
    function validateDeposits(address[] memory _accounts) external 
        whenNotPaused onlyManager {
        uint256 _amountStable;
        uint256 _amountStableTotal;
        uint256 _amountToken;
        uint256 _amountTokenTotal;
        uint256 _tokenIdDeposit;
        Token _token = management.token();
        require (_accounts.length > 0, "Formation.Fi: no user");
        for (uint256 i = 0; i < _accounts.length; i++) {
            address _account =_accounts[i];
            if (deposit.balanceOf(_account) == 0) {
                continue;
            }
            if (maxDeposit <= _amountStableTotal) {
                break;
            }
            _tokenIdDeposit = deposit.getTokenId(_account);
            (  , _amountStable, ) = deposit.pendingDepositPerAddress(_account);
            _amountStable = Math.min(maxDeposit  - _amountStableTotal ,  _amountStable);
            _amountToken = Math.mulDiv(_amountStable, FACTOR_PRICE_DECIMALS, tokenPrice);
            if ((_account == address(managementParity)) && (_amountStable >0)) {
                managementParity.setDepositData(_amountToken, _amountStable, 
                product);

            }
            if ((_account == address(eventDataParity)) && (_amountStable >0)) {
                eventDataParity.setDepositData(_amountToken, _amountStable, 
                product);

            }
            _amountTokenTotal += _amountToken;
            _amountStableTotal += _amountStable;
            if (_amountToken > 0){
                if (_account == address(eventDataParity)){
                    _token.mint(address(managementParity), _amountToken);
                }
                else {
                    _token.mint(_account, _amountToken);
                }
                _token.addDeposit(_account, _amountToken, block.timestamp);
            }
            deposit.updateDepositData(_account, _tokenIdDeposit, _amountStable, false);
            emit ValidateDeposit(_account, _amountStable, _amountToken);
        }
        maxDeposit -= _amountStableTotal;
        depositAmountTotal -= _amountStableTotal;
        if (_amountTokenTotal > 0){
            tokenPriceMean  = ((tokenTotalSupply * tokenPriceMean) + 
            (_amountTokenTotal * tokenPrice)) /
            ( tokenTotalSupply + _amountTokenTotal);
            management.updateTokenPriceMean(tokenPriceMean);
        }
        
        if (management.managementFeeTime() == 0){
            management.updateManagementFeeTime(block.timestamp);   
        }
    }

    /**
     * @dev  Validate the withdrawal requests of users by the manager.
     * @param _accounts the addresses of users.
    */
    function validateWithdrawals(address[] memory _accounts) external
        whenNotPaused onlyManager {
        uint256 _tokensToBurn;
        uint256 _amountToken;
        uint256 _amountTokenTotal;
        uint256 _amountStable;
        uint256 _tokenIdWithdraw;
        uint256 _amountScaleDecimals = management.amountScaleDecimals();
        IBEP20 _stableToken = management.stableToken();
        Token _token = management.token();
        calculateAcceptedWithdrawalAmount(_accounts);
        for (uint256 i = 0; i < _accounts.length; i++) {
            address _account =_accounts[i];
            if (withdrawal.balanceOf(_account) == 0) {
                continue;
            }
            _amountToken = acceptedWithdrawalPerAddress[_account];
            delete acceptedWithdrawalPerAddress[_account]; 
            _amountTokenTotal += _amountToken;
            _amountStable = Math.mulDiv(_amountToken,  tokenPrice, 
            (FACTOR_PRICE_DECIMALS * _amountScaleDecimals));
            if ((_account == address(managementParity)) && (_amountToken > 0))  {
               managementParity.setWithdrawalData(_amountStable, _amountToken, 
               product);
            }
            _tokenIdWithdraw = withdrawal.getTokenId(_account);
            withdrawal.updateWithdrawalData(_account,  _tokenIdWithdraw, _amountToken, false);
            if (_amountStable > 0){
                _stableToken.safeTransfer(_account, _amountStable);
            }
            if (_amountToken > 0){
                _tokensToBurn += _amountToken;
                _token.updateTokenData(_account, _amountToken);
            }
            emit ValidateWithdrawal(_account,  _amountToken, _amountStable);
        }
        withdrawalAmountTotal -= _amountTokenTotal;
        
        if ((_tokensToBurn) > 0){
           _token.burn(address(this), _tokensToBurn);
        }
    }

    /**
     * @dev  Make a deposit request.
     * @param _account the addresses of the user.
     * @param _amount the deposit amount in Stablecoin.
     */
    function depositRequest(address _account, uint256 _amount) external whenNotPaused {
        uint256 _fee;
        if ((_account != address(managementParity)) && (_account!= address(eventDataParity))){
            require(_amount >= management.minAmount(), 
                "Formation.Fi: min Amount");
            _fee = getDepositFee(_amount);
            _amount-= _fee;
        }
        if (deposit.balanceOf(_account) == 0){
            tokenIdDeposit += 1;
            deposit.mint(_account, tokenIdDeposit, _amount);
        }
        else {
            uint256 _tokenIdDeposit = deposit.getTokenId(_account);
            deposit.updateDepositData(_account, _tokenIdDeposit, _amount, true);
        }
        depositAmountTotal += _amount; 
        IBEP20 _stableToken = management.stableToken();
        uint256 _amountScaleDecimals = management.amountScaleDecimals();
        if (_amount > 0){
            _stableToken.safeTransferFrom(msg.sender, address(this), _amount/_amountScaleDecimals);
        }
        if (_fee > 0){
            _stableToken.safeTransferFrom(msg.sender, management.treasury(), _fee /_amountScaleDecimals);
        }
        emit DepositRequest(_account, _amount);
    }

    /**
     * @dev  Cancel the deposit request.
     * @param _amount the deposit amount to cancel in Stablecoin.
     */
    function cancelDepositRequest(uint256 _amount) external whenNotPaused cancel {
        require(deposit.balanceOf(msg.sender) > 0, 
            "Formation.Fi: no deposit request"); 
        require(_amount > 0, 
            "Formation.Fi: zero amount"); 
        uint256 _tokenIdDeposit = deposit.getTokenId(msg.sender);
        deposit.updateDepositData(msg.sender,  _tokenIdDeposit, _amount, false);
        depositAmountTotal -= _amount; 
        IBEP20 _stableToken = management.stableToken();
        uint256 _amountScaleDecimals = management.amountScaleDecimals();
        _stableToken.safeTransfer(msg.sender, _amount/_amountScaleDecimals);
        emit CancelDepositRequest(msg.sender, _amount);      
    }
    
    /**
     * @dev  Make a withdrawal request.
     * @param _amount the withdrawal amount in Token.
    */
    function withdrawRequest(uint256 _amount) external whenNotPaused {
        require ( _amount > 0, 
            "Formation Fi: zero amount");
        require(withdrawal.balanceOf(msg.sender) == 0, 
            "Formation.Fi: request on pending");
        Token _token = management.token();
        if (msg.sender != address(managementParity)) {
            require(_token.checklWithdrawalRequest(msg.sender, _amount, management.lockupPeriodUser()),
                "Formation.Fi: locked position");
        }
        tokenIdWithdraw += 1;
        withdrawal.mint(msg.sender, tokenIdWithdraw, _amount);
        withdrawalAmountTotal += _amount;
        _token.transferFrom(msg.sender, address(this), _amount);
        emit WithdrawalRequest(msg.sender, _amount);   
    }

    /**
     * @dev Cancel the withdrawal request.
     * @param _amount the withdrawal amount in Token.
    */
    function cancelWithdrawalRequest( uint256 _amount) external whenNotPaused {
        require(_amount > 0, 
            "Formation Fi: zero amount");
        require(withdrawal.balanceOf(msg.sender) > 0, 
                "Formation.Fi: no withdrawal request"); 
        uint256 _tokenIdWithdraw = withdrawal.getTokenId(msg.sender);
        withdrawal.updateWithdrawalData(msg.sender, _tokenIdWithdraw, _amount, false);
        withdrawalAmountTotal -= _amount;
        Token _token = management.token();
        _token.transfer(msg.sender, _amount);
        emit CancelWithdrawalRequest(msg.sender, _amount);
    }
    
    /**
     * @dev Send Stablecoins to the SafeHouse by the manager.
     * @param _amount the amount to send.
    */
    function sendToSafeHouse(uint256 _amount) external 
        whenNotPaused onlyManager {
        require( _amount> 0,  
            "Formation.Fi: zero amount");
        uint256 _amountScaleDecimals = management.amountScaleDecimals();
        IBEP20 _stableToken = management.stableToken();
        uint256 _scaledAmount = _amount/ _amountScaleDecimals;
        address _safeHouse = management.safeHouse();
        require(
            _safeHouse != address(0),
            "Formation.Fi: zero address"
        );
        require(
            _stableToken.balanceOf(address(this)) >= _scaledAmount,
            "Formation.Fi: exceeds balance"
        );
        _stableToken.safeTransfer(_safeHouse, _scaledAmount);
    }


    /**
     * @dev Calculate net deposit indicator
    */
    function calculateNetAmountEvent( ) internal {
        getTokenData();
        management.calculateNetAmountEvent(depositAmountTotal, withdrawalAmountTotal,
        management.maxDepositAmount(), management.maxWithdrawalAmount());
        netDepositInd = management.netDepositInd();
        netAmountEvent = management.netAmountEvent();
    }

    /**
     * @dev Calculate the maximum deposit amount to be validated 
     * by the manager for users.
    */
    function calculateMaxDepositAmount( ) internal  {
             maxDeposit = Math.min(depositAmountTotal, management.maxDepositAmount());
        }
    
    /**
     * @dev Calculate the maximum withdrawal amount to be validated 
     * by the manager for users.
    */
    function calculateMaxWithdrawAmount( ) internal  {
        withdrawalAmountTotalOld = withdrawalAmountTotal;
        maxWithdrawal = Math.min(withdrawalAmountTotal , Math.mulDiv(management.maxWithdrawalAmount(), FACTOR_PRICE_DECIMALS,  tokenPrice));
    }

    
     /**
     * @dev update data from management contract.
     */
    function getTokenData() internal { 
        Token _token = management.token();
        tokenPrice = management.tokenPrice();
        tokenPriceMean = management.tokenPriceMean();
        tokenTotalSupply = _token.totalSupply();
    }
    
    /**
     * @dev Calculate the accepted withdrawal amounts for users.
     * @param _accounts the addresses of users.
     */
    function calculateAcceptedWithdrawalAmount(address[] memory _accounts) 
        internal {
        require(_accounts.length > 0, 
            "Formation.Fi: no user");
        uint256 _amountToken;
        address _account;
        for (uint256 i = 0; i < _accounts.length; ++i) {
            _account = _accounts[i];
            require(_account!= address(0), 
                "Formation.Fi: zero address");
            if (withdrawal.balanceOf(_account) == 0) {
                continue;
            }
            ( , _amountToken, ) = withdrawal.pendingWithdrawPerAddress(_account);
            _amountToken = Math.min(Math.mulDiv(maxWithdrawal, _amountToken,
            withdrawalAmountTotalOld), _amountToken);
            acceptedWithdrawalPerAddress[_account] = _amountToken;
        }   
    }
   
}