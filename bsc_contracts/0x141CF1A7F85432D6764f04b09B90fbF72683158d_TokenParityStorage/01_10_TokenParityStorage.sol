// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IManagementParity.sol";
import "./IManagementParityParams.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract TokenParityStorage.
*/

contract TokenParityStorage is Ownable {
    ParityData.Amount public depositBalance;
    ParityData.Amount public withdrawalBalance;
    ParityData.Amount public withdrawalRebalancingBalance;
    ParityData.Amount public depositRebalancingBalance;
    address public eventDataParity;
    address public tokenParity;
    address public investmentParity;
    mapping(uint256 => uint256) public optionPerToken;
    mapping(uint256 => uint256) public riskPerToken;
    mapping(uint256 => uint256) public returnPerToken;
    mapping(uint256 => ParityData.Amount) public weightsPerToken;
    mapping(uint256 => ParityData.Amount) public flowTimePerToken;
    mapping(uint256 => ParityData.Amount) public depositBalancePerToken;
    mapping(uint256 => ParityData.Amount) public withdrawalBalancePerToken;
    mapping(uint256 => ParityData.Amount) public depositRebalancingBalancePerToken;
    mapping(uint256 => ParityData.Amount) public withdrawalRebalancingBalancePerToken;
    mapping(uint256 => ParityData.Amount) public tokenBalancePerToken;
    mapping(uint256 => ParityData.Event []) public depositBalancePerTokenPerEvent;
    mapping(uint256 => ParityData.Event []) public withdrawalBalancePerTokenPerEvent;
    mapping(uint256 => ParityData.Event []) public depositRebalancingBalancePerTokenPerEvent;
    mapping(uint256 => ParityData.Event []) public withdrawalRebalancingBalancePerTokenPerEvent;
    mapping(uint256 => ParityData.Event []) public tokenWithdrawalFee;
    IManagementParity public managementParity;
    IManagementParityParams public managementParityParams;
    address public delegateContract;

    constructor (address _delegateContract){
        require(_delegateContract!= address(0),
            "Formation.Fi: zero address");
        uint256 _size;
        assembly{_size := extcodesize(_delegateContract)}
        require (_size > 0, "Formation.Fi: no contract");
        delegateContract = _delegateContract;
    }
  

    modifier onlyManagementParity() {
        require(address(managementParity) != address(0),
            "Formation.Fi: zero address");
        require(msg.sender == address(managementParity), 
            "Formation.Fi: no ManagementParity");
        _;
    }

    modifier onlyEventDataParity() {
        require(eventDataParity != address(0),
            "Formation.Fi: zero address");
        require(msg.sender == eventDataParity, 
            "Formation.Fi: no EventDataParity");
        _;
    }

    function setTokenParity(address _tokenParity) public onlyOwner {
        require(_tokenParity != address(0),
            "Formation.Fi: zero address");
        tokenParity = _tokenParity;
    }

    function setInvestmentParity(address _investmentParity) public onlyOwner {
        require(_investmentParity != address(0),
            "Formation.Fi: zero address");
        investmentParity =  _investmentParity;
    }


    function setmanagementParity(address _managementParity, address _managementParityParams, 
    address _eventDataParity) 
    public onlyOwner {
        require(_managementParity != address(0),
            "Formation.Fi: zero address");
        require(_eventDataParity != address(0),
            "Formation.Fi: zero address");
        require(_managementParityParams != address(0),
            "Formation.Fi: zero address");
        managementParity = IManagementParity(_managementParity);
        managementParityParams = IManagementParityParams(_managementParityParams);
        eventDataParity = _eventDataParity;
    }
    function setDelegateContract(address _delegateContract) external onlyOwner {
        require(_delegateContract != address(0),
            "Formation.Fi: zero address");
        uint256 _size;
        assembly{_size := extcodesize(_delegateContract)}
        require (_size > 0, "Formation.Fi: no contract");
        delegateContract =  _delegateContract;
    }

    function updateTokenBalancePerToken(uint256 _tokenId, uint256 _amount, uint256 _id) 
        external {
        (bool success, ) = delegateContract.delegatecall(abi.encodeWithSignature("updateTokenBalancePerToken(uint256,uint256,uint256)",
        _tokenId,  _amount,  _id));
        require (success == true, "Formation.Fi: delegatecall fails");    
    } 

    function updateDepositBalancePerToken(uint256 _tokenId, uint256 _amount, 
        uint256 _indexEvent, uint256 _id) external {
        (bool success, ) = delegateContract.delegatecall(abi.encodeWithSignature("updateDepositBalancePerToken(uint256,uint256,uint256,uint256)",
        _tokenId,  _amount, _indexEvent,_id));
        require (success == true, "Formation.Fi: delegatecall fails");   
    }   

    function updateRebalancingDepositBalancePerToken(uint256 _tokenId, uint256 _amount, 
        uint256 _indexEvent,uint256 _id) external {
        (bool success, ) = delegateContract.delegatecall(abi.encodeWithSignature("updateRebalancingDepositBalancePerToken(uint256,uint256,uint256,uint256)",
        _tokenId,  _amount, _indexEvent,_id));
        require (success == true, "Formation.Fi: delegatecall fails");    
    }   

    function updateRebalancingWithdrawalBalancePerToken(uint256 _tokenId, uint256 _amount, 
        uint256 _indexEvent,uint256 _id) external {
        (bool success, ) = delegateContract.delegatecall(abi.encodeWithSignature("updateRebalancingWithdrawalBalancePerToken(uint256,uint256,uint256,uint256)",
        _tokenId,  _amount, _indexEvent,_id));
        require (success == true, "Formation.Fi: delegatecall fails");
    }   

    function updateWithdrawalBalancePerToken(uint256 _tokenId, uint256 _amount, 
        uint256 _indexEvent, uint256 _id) external {
        (bool success, ) = delegateContract.delegatecall(abi.encodeWithSignature("updateWithdrawalBalancePerToken(uint256,uint256,uint256,uint256)",
        _tokenId,  _amount, _indexEvent,_id));
        require (success == true, "Formation.Fi: delegatecall fails");
        
    }   

    function updateTotalBalances(ParityData.Amount memory _depositAmount, 
        ParityData.Amount memory _withdrawalAmount, 
        ParityData.Amount memory _depositRebalancingAmount, 
        ParityData.Amount memory _withdrawalRebalancingAmount) 
        external {
        (bool success, ) = delegateContract.delegatecall(abi.encodeWithSignature("updateTotalBalances((uint256,uint256,uint256),(uint256,uint256,uint256),(uint256,uint256,uint256),(uint256,uint256,uint256))",
        _depositAmount, _withdrawalAmount, _depositRebalancingAmount, _withdrawalRebalancingAmount)); 
        require (success == true, "Formation.Fi: delegatecall fails");
    }  

    function rebalanceParityPosition( ParityData.Position memory _position,
        uint256 _indexEvent, uint256[3] memory _price, bool _isFree) 
        external {
        (bool success, ) = delegateContract.delegatecall(abi.encodeWithSignature("rebalanceParityPosition((uint256,uint256,uint256,uint256,uint256,(uint256,uint256,uint256)),uint256,uint256[3],bool)",
        _position, _indexEvent,  _price,  _isFree)); 
        require (success == true, "Formation.Fi: delegatecall fails");  
    }
    
    function cancelWithdrawalRequest (uint256 _tokenId, uint256 _indexEvent, 
        uint256[3] memory _price) external {
        (bool success, ) = delegateContract.delegatecall(abi.encodeWithSignature("cancelWithdrawalRequest(uint256,uint256,uint256[3])",
        _tokenId, _indexEvent,  _price)); 
        require (success == true, "Formation.Fi: delegatecall fails"); 
    }

    function withdrawalRequest (uint256 _tokenId, uint256 _indexEvent, 
        uint256 _rate, uint256[3] memory _price, address _owner) external {
        (bool success, ) = delegateContract.delegatecall(abi.encodeWithSignature("withdrawalRequest(uint256,uint256,uint256,uint256[3],address)",
        _tokenId, _indexEvent, _rate,  _price, _owner)); 
        require (success == true, "Formation.Fi: delegatecall fails"); 
    }

    function updateUserPreference(ParityData.Position memory _position, 
        uint256 _indexEvent, uint256[3] memory _price,  bool _isFirst) 
        external {
        (bool success, ) = delegateContract.delegatecall(abi.encodeWithSignature("updateUserPreference((uint256,uint256,uint256,uint256,uint256,(uint256,uint256,uint256)),uint256,uint256[3],bool)", _position, _indexEvent, _price, _isFirst)); 
        require (success == true, "Formation.Fi: delegatecall fails");
    }

    function getDepositBalancePerTokenPerEvent(uint256 _tokenId) public view 
        returns(ParityData.Event[] memory){
        uint256 _size = depositBalancePerTokenPerEvent[_tokenId].length;
        ParityData.Event[] memory _data = new ParityData.Event[](_size);
        for (uint256 i = 0; i < _size ; ++i) {  
            _data[i] = depositBalancePerTokenPerEvent[_tokenId][i];
        }
        return _data;
    }
    
    function getDepositRebalancingBalancePerTokenPerEvent(uint256 _tokenId) public view 
        returns(ParityData.Event[] memory){
        uint256 _size = depositRebalancingBalancePerTokenPerEvent[_tokenId].length;
        ParityData.Event[] memory _data = new ParityData.Event[](_size);
        for (uint256 i = 0; i < _size ; ++i) {  
            _data[i] = depositRebalancingBalancePerTokenPerEvent[_tokenId][i];
        }
        return _data;
    }
    function getWithdrawalBalancePerTokenPerEvent(uint256 _tokenId) public view 
        returns(ParityData.Event[] memory){
        uint256 _size = withdrawalBalancePerTokenPerEvent[_tokenId].length;
        ParityData.Event[] memory _data = new ParityData.Event[](_size);
        for (uint256 i = 0; i < _size ; ++i) {  
            _data[i] = withdrawalBalancePerTokenPerEvent[_tokenId][i];
        }
        return _data;
    }

    function getWithdrawalRebalancingBalancePerTokenPerEvent(uint256 _tokenId) public view 
        returns(ParityData.Event[] memory){
        uint256 _size = withdrawalRebalancingBalancePerTokenPerEvent[_tokenId].length;
        ParityData.Event[] memory _data = new ParityData.Event[](_size);
        for (uint256 i = 0; i < _size ; ++i) {  
            _data[i] = withdrawalRebalancingBalancePerTokenPerEvent[_tokenId][i];
        }
        return _data;
    }
   
}