// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Timelockwallet is ERC20, Ownable {
  using SafeERC20 for IERC20;

  struct ManagerObj {
    uint256 index;
    bool exist;
  }

  struct WithdrawObj {
    uint256 amount;
    uint256 createdAt;
  }

  mapping (address => ManagerObj) private _manageAccess;
  address[] private _manager;

  address[] public availableTokenLists;

  uint256 public withdrawDuration;
  uint256 public withdrawLimitation;
  mapping(address => mapping(uint256 => WithdrawObj)) public withdrawLists;
  mapping(address => uint256) public withdrawListIndex;

  event Deposit(address _token, address _account, uint256 _amount);
  event Withdraw(address _token, address _account, uint256 _amount);
  event RemoveLiquidity(address _operator, address _token, address _account, uint256 _amount);

  modifier onlyManager() {
    require(_manageAccess[msg.sender].exist, "!manager");
    _;
  }

  constructor (string memory _name, string memory  _symbol) 
    ERC20(_name, _symbol)
  {
    withdrawDuration = 24 * 3600;
    withdrawLimitation = 100e18;

    availableTokenLists.push(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // BUSD
    availableTokenLists.push(0x55d398326f99059fF775485246999027B3197955); // USDT
    availableTokenLists.push(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d); // USDC
    availableTokenLists.push(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3); // DAI
  }

  function getAllManager() public view returns(address[] memory) {
    return _manager;
  }

  function setManager(address usraddress, bool access) public onlyOwner {
    if (access == true) {
      if ( ! _manageAccess[usraddress].exist) {
        uint256 newId = _manager.length;
        _manageAccess[usraddress] = ManagerObj(newId, true);
        _manager.push(usraddress);
      }
    }
    else {
      if (_manageAccess[usraddress].exist) {
        address lastObj = _manager[_manager.length - 1];
        _manager[_manageAccess[usraddress].index] = _manager[_manageAccess[lastObj].index];
        _manager.pop();
        delete _manageAccess[usraddress];
      }
    }
  }

  function setWithdrawDuration(uint256 _withdrawDuration) public onlyOwner {
    withdrawDuration = _withdrawDuration;
  }

  function setWithdrawLimitation(uint256 _withdrawLimitation) public onlyOwner {
    withdrawLimitation = _withdrawLimitation;
  }

  function removeLiquidity(address _token, address _account) public onlyOwner {
    require(_availableToken(_token), "TIMELOCKWALLET: Not registered token");
    uint256 _balance = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransfer(_account, _balance);
    emit RemoveLiquidity(msg.sender, _token, _account, _balance);
  }

  function deposit(address _token, uint256 _amount) public {
    require(_availableToken(_token), "TIMELOCKWALLET: Not registered token");
    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    _mint(msg.sender, _amount);
    emit Deposit(_token, msg.sender, _amount);
  }

  function withdraw(address _token, uint256 _amount) public onlyManager {
    require(_availableToken(_token), "TIMELOCKWALLET: Not registered token");
    uint256 _prevSum = 0;
    uint256 _now = block.timestamp;
    uint256 _len = withdrawListIndex[msg.sender];
    for (uint256 i=_len; i>0; i--) {
      if (withdrawLists[msg.sender][i].createdAt + withdrawDuration > _now) {
        _prevSum += withdrawLists[msg.sender][i].amount;
      }
    }
    require(_prevSum < withdrawLimitation && _prevSum+_amount <= withdrawLimitation, "TIMELOCKWALLET: Withdraw limitation exceeds");
    _burn(msg.sender, _amount);
    IERC20(_token).safeTransfer(msg.sender, _amount);
    withdrawLists[msg.sender][_len+1] = WithdrawObj(_amount, _now);
    withdrawListIndex[msg.sender] = withdrawListIndex[msg.sender] + 1;
    emit Withdraw(_token, msg.sender, _amount);
  }

  function getRecentWithdrawLength(address _account) public view returns(uint256) {
    uint256 _now = block.timestamp;
    uint256 j = 0;
    uint256 _len = withdrawListIndex[_account];
    for (uint256 i=_len; i>0; i--) {
      if (withdrawLists[_account][i].createdAt + withdrawDuration > _now) {
        j ++;
      }
    }
    return j;
  }

  function getWithdrawLength(address _account) public view returns(uint256) {
    return withdrawListIndex[_account];
  }

  function getWithdrawInfo(address _account, uint256 _index) public view returns(WithdrawObj memory) {
    return withdrawLists[_account][_index];
  }

  function _availableToken(address _token) internal view returns(bool) {
    uint256 _len = availableTokenLists.length;
    for (uint256 i=0; i<_len; i++) {
      if (availableTokenLists[i] == _token) {
        return true;
      }
    }
    return false;
  }
}