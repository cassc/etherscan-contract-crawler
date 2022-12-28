// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./libraries/ParityData.sol";
import "../main/libraries/SafeBEP20.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract ManagementParityParams.
*/
contract ManagementParityParams is Ownable {
    using Math for uint256;
    
    uint256 public depositMinAmount;
    uint256 public depositFee;
    uint256 public maxDepositFee;
    uint256 public minDepositFee;
    uint256 public fixedWithdrawalFee;
    uint256 public rebalancingFee;
    uint256 public minRebalancingFee;
    uint256 public maxRebalancingFee;
    ParityData.Fee[] public variableWithdrawalFee;
    address public manager;
    address public treasury;
    mapping(address => bool) public managers;

    constructor(address _manager){
        require(_manager!= address(0), 
            "Formation.Fi: no manager");
        manager = _manager;
        managers[_manager] = true;
    }

    modifier onlyManager() {
        require(msg.sender == manager, 
            "Formation.Fi: no manager");
        _;
    }

    function setManager(address _manager) 
        external onlyOwner {
        require(_manager != address(0),
            "Formation.Fi: zero address");
        manager = _manager;
        managers[_manager] = true;
    }

    function updateManagers(address _manager, bool _state) external onlyOwner {
        require(_manager != address(0),
            "Formation.Fi: zero address");
        require(managers[_manager] != _state,
            "Formation.Fi: no change");
        managers[_manager] = _state;
    }   

    function setTreasury(address _treasury) 
        external onlyOwner {
        require(_treasury != address(0),
            "Formation.Fi: zero address");
        treasury = _treasury;
    }

    function setDepositMinAmount(uint256 _depositMinAmount) 
        external onlyManager {
        depositMinAmount = _depositMinAmount;
    }

    function setDepositFee(uint256 _depositFee) 
        external onlyManager {
        depositFee = _depositFee;
    }

    function setRebalancingFee(uint256 _rebalancingFee) 
        external onlyManager {
        rebalancingFee = _rebalancingFee;
    }

    function setMaxRebalancingFee(uint256 _maxRebalancingFee) 
        external onlyManager {
        maxRebalancingFee = _maxRebalancingFee;
    }

    function setMinRebalancingFee(uint256 _minRebalancingFee) 
        external onlyManager {
        minRebalancingFee = _minRebalancingFee;
    }

    function setMaxDepositFee(uint256 _maxDepositFee) 
        external onlyManager {
        maxDepositFee = _maxDepositFee;
    }

    function setMinDepositFee(uint256 _minDepositFee) 
        external onlyManager {
        minDepositFee = _minDepositFee;
    }

    function setFixedWithdrawalFee(uint256 _value) 
        external onlyManager{
        fixedWithdrawalFee = _value;
    }

    function addVariableWithdrawalFee( uint256 _value, uint256 _time) 
            external onlyManager {
            uint256 _size = variableWithdrawalFee.length;
            if (_size >=1 ){
                require (variableWithdrawalFee[_size - 1].time < _time,
                "Formation.Fi: time does not match");
                require (variableWithdrawalFee[_size - 1].value >= _value,
                "Formation.Fi: value does not match");
            }
            ParityData.Fee memory _fee = ParityData.Fee(_value, _time);
            variableWithdrawalFee.push(_fee);
    }

    function updateVariableWithdrawalFee( uint256 _index,  uint256 _value,
        uint256 _time) external onlyManager  {
            uint256 _size = variableWithdrawalFee.length;
            require ( _index<= _size -1,
                "Formation.Fi: out of range");
            if (_index > 0){
                require ( variableWithdrawalFee[_index -1].time < _time,
                "Formation.Fi: time does not match");
                require ( variableWithdrawalFee[_index -1].value >= _value,
                "Formation.Fi: value does not match");
            }
            if (_index < _size - 1){
                require ( variableWithdrawalFee[_index + 1].time > _time,
                "Formation.Fi: time does not match");
                require ( variableWithdrawalFee[_index + 1].value <= _value,
                "Formation.Fi: value does not match");
            }
            ParityData.Fee memory _fee = ParityData.Fee(_value, _time);
            variableWithdrawalFee[_index]= _fee;
    }

    function isManager(address _account) public view 
        returns(bool) {
        return managers[_account];
    }

    function getDepositFee(uint256 _value) public view    
        returns (uint256 _fee) {
        _fee = Math.max((depositFee * _value) /ParityData.COEFF_SCALE_DECIMALS, minDepositFee);
        _fee = Math.min(_fee, maxDepositFee);
    }

    function getRebalancingFee(uint256 _value) public view 
        returns (uint256 _fee) {
        _fee = Math.max((rebalancingFee * _value) /ParityData.COEFF_SCALE_DECIMALS, minRebalancingFee);
        _fee = Math.min(_fee, maxRebalancingFee);
    }

    function getSizeVariableWithdrawalFee() public view 
        returns (uint256) {
        return variableWithdrawalFee.length; 
    }

    function getVariableWithdrawalFee(uint256 _index) public view  
        returns (uint256, uint256) {
        require (_index <= variableWithdrawalFee.length - 1, 
            "Formation.Fi: out of range");
        return (variableWithdrawalFee[_index].value, variableWithdrawalFee[_index].time); 
    }

    function getWithdrawalVariableFeeData() public view 
        returns (ParityData.Fee[] memory) {
        uint256 _size = variableWithdrawalFee.length;
        ParityData.Fee[] memory _data = new ParityData.Fee[](_size);
        for (uint256 i = 0; i < _size ; ++i) {  
            _data[i] = variableWithdrawalFee[i];
        }
        return _data;
    }
    
}