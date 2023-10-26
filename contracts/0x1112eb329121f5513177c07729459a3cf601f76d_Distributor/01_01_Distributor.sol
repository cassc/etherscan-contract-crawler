// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}

interface IWETH is IERC20 {
  function deposit() external payable;
  function withdraw(uint amount) external;
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }
  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _transferOwnership(_msgSender());
  }

  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  function _checkOwner() internal view virtual {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

interface IERC20Permit {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
  function nonces(address owner) external view returns (uint256);
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library Address {
  function isContract(address account) internal view returns (bool) {
    return account.code.length > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCallWithValue(target, data, 0, "Address: low-level call failed");
  }

  function functionCall(
      address target,
      bytes memory data,
      string memory errorMessage
  ) internal returns (bytes memory) {
      return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
      address target,
      bytes memory data,
      uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function verifyCallResultFromTarget(
    address target,
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    if (success) {
      if (returndata.length == 0) {
        require(isContract(target), "Address: call to non-contract");
      }
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function _revert(bytes memory returndata, string memory errorMessage) private pure {
    if (returndata.length > 0) {
      assembly {
        let returndata_size := mload(returndata)
        revert(add(32, returndata), returndata_size)
      }
    } else {
      revert(errorMessage);
    }
  }
}

library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    unchecked {
      uint256 oldAllowance = token.allowance(address(this), spender);
      require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
      uint256 newAllowance = oldAllowance - value;
      _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
  }

  function safePermit(
    IERC20Permit token,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    uint256 nonceBefore = token.nonces(owner);
    token.permit(owner, spender, value, deadline, v, r, s);
    uint256 nonceAfter = token.nonces(owner);
    require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

contract Distributor is Ownable {
  using SafeERC20 for IERC20;

  struct FeeRecObj {
    uint256 index;
    string title;
    address account;
    uint256 feePercent;
    bool exist;
  }

  struct ManagerObj {
    uint256 index;
    bool exist;
  }

  uint256 public MAX_FEE = 1000000;
  uint256 public MAX_INDEX = 1;

  mapping (uint256 => FeeRecObj) private _feeTier;
  uint256[] private _tierIndex;

  mapping (address => ManagerObj) private _manageAccess;
  address[] private _feeManager;

  event ClaimReward(address account, address token, uint256 rewardAmount);

  modifier onlyManager() {
    require(msg.sender == owner() || _manageAccess[msg.sender].exist, "!manager");
    _;
  }

  constructor () {
  }

  function claim(address token) public {
    uint256 amount = 0;
    if (token == address(0)) {
      amount = address(this).balance;
    }
    else {
      amount = IERC20(token).balanceOf(address(this));
    }

    if (amount > 0) {
      uint256 x = 0;
      uint256 len = _tierIndex.length;
      for (x = 0; x < len; x ++) {
        (address account, , uint256 percent) = getTier(_tierIndex[x]);
        uint256 rewardAmount = amount * percent / MAX_FEE;
        if (rewardAmount > 0) {
          if (token == address(0)) {
            if (address(this).balance > rewardAmount) {
              (bool success, ) = payable(account).call{value: rewardAmount}("");
              require(success, "Distributor: Failed claim");
              emit ClaimReward(account, token, rewardAmount);
            }
          }
          else {
            if (IERC20(token).balanceOf(address(this)) >= rewardAmount) {
              IERC20(token).safeTransfer(account, rewardAmount);
              emit ClaimReward(account, token, rewardAmount);
            }
          }
        }
      }
    }
  }

  function getAllManager() public view returns(address[] memory) {
    return _feeManager;
  }

  function setManager(address usraddress, bool access) public onlyOwner {
    if (access == true) {
      if ( ! _manageAccess[usraddress].exist) {
        uint256 newId = _feeManager.length;
        _manageAccess[usraddress] = ManagerObj(newId, true);
        _feeManager.push(usraddress);
      }
    }
    else {
      if (_manageAccess[usraddress].exist) {
        address lastObj = _feeManager[_feeManager.length - 1];
        _feeManager[_manageAccess[usraddress].index] = _feeManager[_manageAccess[lastObj].index];
        _feeManager.pop();
        delete _manageAccess[usraddress];
      }
    }
  }

  function getAllTier() public view returns(uint256[] memory) {
    return _tierIndex;
  }

  function insertTier(string memory title, address account, uint256 fee) public onlyManager {
    require(fee <= MAX_FEE, "Fee tier value is overflowed");
    _tierIndex.push(MAX_INDEX);
    _feeTier[MAX_INDEX] = FeeRecObj(_tierIndex.length - 1, title, account, fee, true);
    MAX_INDEX = MAX_INDEX + 1;
  }

  function getTier(uint256 index) public view returns(address, string memory, uint256) {
    require(_feeTier[index].exist, "Only existing tier can be loaded");
    FeeRecObj memory tierItem = _feeTier[index];
    return (tierItem.account, tierItem.title, tierItem.feePercent);
  }

  function updateTier(uint256 index, string memory title, address account, uint256 fee) public onlyManager {
    require(_feeTier[index].exist, "Only existing tier can be loaded");
    require(fee <= MAX_FEE, "Fee tier value is overflowed");
    _feeTier[index].title = title;
    _feeTier[index].account = account;
    _feeTier[index].feePercent = fee;
  }

  function removeTier(uint256 index) public onlyManager {
    require(_feeTier[index].exist, "Only existing tier can be removed");
    uint256 arr_index = _feeTier[index].index;
    uint256 last_index = _tierIndex[_tierIndex.length-1];
    
    FeeRecObj memory changedObj = _feeTier[last_index];
    _feeTier[last_index] = FeeRecObj(arr_index, changedObj.title, changedObj.account, changedObj.feePercent, true);
    _tierIndex[arr_index] = last_index;
    _tierIndex.pop();
    delete _feeTier[index];
  }
}