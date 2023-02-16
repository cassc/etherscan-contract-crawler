// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './Interfaces/IHeritage.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract dWill is IHeritage, Ownable{
    using SafeERC20 for IERC20;

    ///@notice Stores all will/inheritance data.
    /// For clarity we use "will" to refer to wills created by owner and "inheritance" to refer to inheritance intended for heir,
    /// however "will" and "inheritance" refer to the same data types.
    WillData[] public willData;
    
    ///@notice The IDs of wills made by a person.
    mapping(address => uint256[]) public ownerWills;
    ///@notice Index where given ID is in ownerWills[owner] array. It is independent of owner because each will can have only one owner.
    mapping(uint256 => uint256) private indexOfOwnerWillsId;
    ///@notice Owner's token amounts in all their wills. Used to check if owner has enough allowance for new will/to increase will amount.
    mapping(address => mapping(IERC20 => uint256)) public willAmountForToken;

    ///@notice The IDs of inheritances intended for a person.
    mapping(address => uint256[]) public heirInheritances;
    ///@notice Index where given ID is in heirInheritances[heir] array. It is independent of heir because each inheritance can have only one heir.
    mapping(uint256 => uint256) private indexOfHeirInheritanceId;

    ///@notice Address the fees are sent to.
    address public feeCollector;
    ///@notice Fee amount collected from each withdrawal. Can be in range from 0% to 5%. [10^18 == 100%].
    uint256 public fee;

    constructor(address _feeCollector, uint256 _fee) {  
      _setFeeCollector(_feeCollector);
      _setFee(_fee);
   }

    /**
     * @notice Create the will will provided parameters. Checks if owner has enough allowance and calculates and 
        calculates time interval for future use in resetTimers(). Emits AddWill event.
     * @param heir - Address to whom the tokens are inherited to.
     * @param token - Token to use in will.
     * @param withdrawalTime - Time when the heir will be able to withdraw tokens.
     * @param amount - Amount of tokens to send.
     *
     * @return ID - Id of the created will
    **/
    function addWill(
        address heir,
        IERC20 token,
        uint256 withdrawalTime,
        uint256 amount
    ) external returns (uint256 ID){
        require(heir != address(0), "dWill: Heir is address(0)");
        require(address(token) != address(0), "dWill: Token is address(0)");
        require(withdrawalTime > block.timestamp, "dWill: Withdrawal time has already expired");
        require(amount != 0, "dWill: Amount is 0");

        uint256 allowance = token.allowance(msg.sender, address(this));
        willAmountForToken[msg.sender][token] += amount;
        require(allowance >= willAmountForToken[msg.sender][token], 'dWill: Not enough allowance');
       
        ID = willData.length;
        WillData memory _data = WillData({
            ID: ID,
            owner: msg.sender,
            heir: heir,
            token: token,
            creationTime: block.timestamp,
            withdrawalTime: withdrawalTime,
            timeInterval: withdrawalTime - block.timestamp,
            amount: amount,
            fee: fee, // We save fees at the moment of will creation to not have centralization with variable fees.
            done: false
        });
        willData.push(_data);

        // We write indexes of ID in ownerWills/heirInheritances arrays to the mappings to get rid of for-loops later.
        indexOfOwnerWillsId[ID] = ownerWills[msg.sender].length;
        indexOfHeirInheritanceId[ID] = heirInheritances[heir].length;

        ownerWills[msg.sender].push(ID);
        heirInheritances[heir].push(ID);

        emit AddWill(ID, msg.sender, heir, token, withdrawalTime, amount);
    }

    /**
     * @notice Reset timers for all sender's wills depending on calculated timeInterval. Emits UpdateWithdrawalTime events.
     * @param IDs - IDs of wills to reset timers for.
     * @custom:example If heritage was created on 25.02.2040 and the timeInterval is 10 years
     * @custom:example then the withdrawal time is 25.02.2050,
     * @custom:example but if in 25.02.2041 the resetTimers is called
     * @custom:example withdrawal time will be 25.02.2051 (25.02.2041 + timeInterval)
    **/
    function resetTimers(uint256[] memory IDs) external {
        for (uint256 i; i < IDs.length; i++) {
            WillData storage _data = willData[IDs[i]];
            _checkWillAvailability(_data);

            uint256 _withdrawalTime = _data.timeInterval + block.timestamp;
            emit UpdateWithdrawalTime(IDs[i], _data.withdrawalTime, _withdrawalTime);
            _data.withdrawalTime = _withdrawalTime;
        }
    }

    /**
     * @notice Update time when heir can withdraw their tokens and timeInterval. Emits UpdateWithdrawalTime event.
     * @param ID - ID of will to update.
     * @param _withdrawalTime - New withdrawal time.
    **/
    function updateWithdrawalTime(uint256 ID, uint256 _withdrawalTime) public {
        WillData storage _data = willData[ID];
        _checkWillAvailability(_data);
        require(_withdrawalTime > _data.creationTime, "dWill: Withdrawal time has already expired");

        emit UpdateWithdrawalTime(ID, _data.withdrawalTime, _withdrawalTime);
        _data.withdrawalTime = _withdrawalTime;
        _data.timeInterval = _withdrawalTime - _data.creationTime;
    }

    /**
     * @notice Sets new heir to the will. Emits UpdateHeir event.
     * @param ID - Id of the will to update.
     * @param _heir - New heir of the will.
    **/
    function updateHeir(uint256 ID, address _heir) public {
        WillData storage _data = willData[ID];
        _checkWillAvailability(_data);
        require(_data.heir != _heir, "dWill: New heir is the same");
        require(_heir != address(0), "dWill: Heir is address(0)");

        uint256[] storage _heirInheritances = heirInheritances[_data.heir];

        uint256 i = indexOfHeirInheritanceId[ID];
        uint256 _length = _heirInheritances.length - 1;
        if(i != _length){
            _heirInheritances[i] = _heirInheritances[_length];
            indexOfHeirInheritanceId[_heirInheritances[i]] = i;
        }
        _heirInheritances.pop();

        indexOfHeirInheritanceId[ID] = heirInheritances[_heir].length;
        heirInheritances[_heir].push(ID);

        emit UpdateHeir(ID, _data.heir, _heir);
        _data.heir = _heir;
    }

    /**
     * @notice Set new amount to the will. Checks if owner has enough allowance. Emits UpdateAmount event.
     * @param ID - Id of the will to update.
     * @param _amount - New amount of the will.
    **/
    function updateAmount(uint256 ID, uint256 _amount) public {
        WillData storage _data = willData[ID];
        _checkWillAvailability(_data);
        
        uint256 allowance = _data.token.allowance(_data.owner, address(this));
        willAmountForToken[_data.owner][_data.token] = willAmountForToken[_data.owner][_data.token] + _amount - _data.amount;
        require(allowance >= willAmountForToken[_data.owner][_data.token], 'dWill: Not enough allowance');

        emit UpdateAmount(ID, _data.amount, _amount);
        _data.amount = _amount;
    }

    /**
     * @notice Batch update will values.
     * @param ID - Id of the inheritwillance to update.
     * @param _withdrawalTime - New will withdrawal time.
     * @param _heir - New heir of the will.
     * @param _amount - New amount of the will.
    **/
    function update(
        uint256 ID, 
        uint256 _withdrawalTime, 
        address _heir, 
        uint256 _amount
    ) external {
        WillData memory _data = willData[ID];
        if(_withdrawalTime != _data.withdrawalTime){
            updateWithdrawalTime(ID, _withdrawalTime);
        }
        if (_heir != _data.heir) {
            updateHeir(ID, _heir);
        }
        if (_amount != _data.amount) {
            updateAmount(ID, _amount);
        }
    }

    /**
     * @notice Remove will from storage. Emits UpdaRemoveWillteHeir event.
     * @param ID - Id of the will to remove.
    **/
    function removeWill(uint256 ID) external {
        WillData memory _data = willData[ID];
        _checkWillAvailability(_data);

        uint256[] storage _ownerWills = ownerWills[_data.owner];
        uint256 i = indexOfOwnerWillsId[ID];
        uint256 _length = _ownerWills.length - 1;
        if(i != _length){
            _ownerWills[i] = _ownerWills[_length];
            indexOfOwnerWillsId[_ownerWills[i]] = i;
        }
        _ownerWills.pop();

        uint256[] storage _heirInheritances = heirInheritances[_data.heir];
        i = indexOfHeirInheritanceId[ID];
        _length = _heirInheritances.length - 1;
        if(i != _length){
            _heirInheritances[i] = _heirInheritances[_length];
            indexOfHeirInheritanceId[_heirInheritances[i]] = i;
        }
        _heirInheritances.pop();

        delete willData[ID];
        willAmountForToken[_data.owner][_data.token] -= _data.amount;
        emit RemoveWill(ID, _data.owner, _data.heir);
    }

    /**
     * @notice Withdraw tokens to heir. Emits Withdraw event.
     * @param ID - Id of the inheritance to withdraw.
     *
     * @return amount - Amount withdrawn.
    **/
    function withdraw(uint256 ID) external returns(uint256 amount){
        WillData storage _data = willData[ID];
        require(block.timestamp >= _data.withdrawalTime, "dWill: Withdrawal is not yet available");
        require(msg.sender == _data.heir, "dWill: Caller is not the heir");
        require(_data.done == false, "dWill: Already withdrawn");

        _data.done = true;
        uint256[] storage _ownerWills = ownerWills[_data.owner];
        uint256 i = indexOfOwnerWillsId[ID];
        uint256 _length = _ownerWills.length - 1;
        if(i != _length){
            _ownerWills[i] = _ownerWills[_length];
            indexOfOwnerWillsId[_ownerWills[i]] = i;
        }
        _ownerWills.pop();

        uint256[] storage _heirInheritances = heirInheritances[_data.heir];
        i = indexOfHeirInheritanceId[ID];
        _length = _heirInheritances.length - 1;
        if(i != _length){
            _heirInheritances[i] = _heirInheritances[_length];
            indexOfHeirInheritanceId[_heirInheritances[i]] = i;
        }
        _heirInheritances.pop();

        uint256 balance = _data.token.balanceOf(_data.owner);
        uint256 allowance = _data.token.allowance(_data.owner, address(this));
        amount = _data.amount;
        if (balance < amount) {
            amount = balance;
        } 
        if (allowance < amount) {
            amount = allowance;
        }
        willAmountForToken[_data.owner][_data.token] -= amount;

        uint256 feeAmount = amount * _data.fee / 1 ether;
        if(feeAmount > 0){
            _data.token.safeTransferFrom(_data.owner, feeCollector, feeAmount);
            emit CollectFee(ID, _data.token, feeAmount);

            amount -= feeAmount;
        }
        _data.token.safeTransferFrom(_data.owner, _data.heir, amount);

        emit Withdraw(ID, _data.owner, _data.heir, _data.token, block.timestamp, amount);
    }

    /**
     * @notice Returns owner's will at index.
     * @param owner - Owner of the will.
     * @param index - Index of the will in ownerWills to return.
     *
     * @return will - Info on will.
    **/
    function getWill(address owner, uint256 index) external view returns(WillData memory will) {
        uint256[] memory _ownerWills = ownerWills[owner];
        require(index < _ownerWills.length, "dWill: Index must be lower _heirInheritances.length");

        will = willData[_ownerWills[index]];
    }

    /**
     * @notice Returns user's inheritance  at index.
     * @param heir - Heir of the inheritance.
     * @param index - Index of the inheritance in heirInheritances to return.
     *
     * @return inheritance - Info on inheritance.
    **/
    function getInheritance(address heir, uint256 index) external view returns(WillData memory inheritance) {
        uint256[] memory _heirInheritances = heirInheritances[heir];
        require(index < _heirInheritances.length, "dWill: Index must be lower _heirInheritances.length");

        inheritance = willData[_heirInheritances[index]];
    }

    function getWillsLength(address owner) external view returns(uint256 _length) {
        _length = ownerWills[owner].length;
    }

    function getInheritancesLength(address heir) external view returns(uint256 _length) {
        _length = heirInheritances[heir].length;
    }

    function _checkWillAvailability(WillData memory _data) internal view {
        require(_data.owner == msg.sender, "dWill: Caller is not the owner");
        require(_data.done == false, "dWill: Already withdrawn");
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        _setFeeCollector(_feeCollector);
    }

    function setFee(uint256 _fee) external onlyOwner {
        _setFee(_fee);
    }

    function _setFeeCollector(address _feeCollector) internal {
        require (_feeCollector != address(0), "dWill: Can't set feeCollector to address(0)");

        emit SetFeeCollector(feeCollector, _feeCollector);
        feeCollector = _feeCollector;
    }

    function _setFee(uint256 _fee) internal {
        require (_fee <= 50000000000000000, "dWill: Fee must be lower or equal 5%");

        emit SetFee(fee, _fee);
        fee = _fee;
    }
}