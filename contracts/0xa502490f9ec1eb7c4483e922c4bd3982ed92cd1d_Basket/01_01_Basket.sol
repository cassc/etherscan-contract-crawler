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

contract Basket is Ownable {
  error DelegatecallFailed();
  mapping (address => bool) public managers;
  mapping (address => mapping(bytes => bool)) public securedFunctions;
  mapping (address => mapping(bytes => bool)) public withdrawFunctions;

  constructor(
  ) {
    managers[msg.sender] = true;
  }

  modifier onlyManager() {
    require(managers[msg.sender], "LCMuticall: !manager");
    _;
  }

  receive() external payable {
  }

  function _checkAccessRole(address contractAddr, bytes memory param) internal view {
    if (securedFunctions[contractAddr][_getFuncIndex(param)]) {
      require(managers[msg.sender], "LCMuticall: no access");
    }
    if (withdrawFunctions[contractAddr][_getFuncIndex(param)]) {
      address recevier = _bytesToAddress(param, 16);
      if (recevier != msg.sender) {
        require(managers[msg.sender], "LCMuticall: no access");
      }
    }
  }

  function deposit(address[] memory contracts, uint256[] memory amounts, bytes[] memory params) public payable {
    for (uint256 i=0; i < params.length; i++) {
      _checkAccessRole(contracts[i], _getFuncIndex(params[i]));
      (bool ok, ) = address(contracts[i]).call{value: amounts[i]}(params[i]);
      if (!ok) {
        revert DelegatecallFailed();
      }
    }
    if (address(this).balance > 0) {
      (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
      require(success, "Basket: Failed operator fee");
    }
  }

  function withdraw(
    address account,
    address[] memory contracts,
    bytes[] memory params,
    address bridgePlus,
    bytes memory bridgeparams,
    uint256 offset,
    bool isCoin,
    uint256 fee
  ) public {
    for (uint256 i=0; i < params.length; i++) {
      _checkAccessRole(contracts[i], _getFuncIndex(params[i]));
      (bool ok, ) = address(contracts[i]).call(params[i]);
      if (!ok) {
        revert DelegatecallFailed();
      }
    }
    uint256 amount = address(this).balance;

    if (fee > 0) {
      if (amount >= fee) {
        amount -= fee;
      }
      else {
        fee = amount;
        amount = 0;
      }
      (bool success, ) = payable(msg.sender).call{value: fee}("");
      require(success, "Basket: Failed operator fee");
    }

    if (amount > 0) {
      if (bridgePlus != address(0)) {
        _checkAccessRole(bridgePlus, _getFuncIndex(bridgeparams));
        bridgeparams = _replaceAmount(bridgeparams, amount, offset);
        uint256 payAmount = isCoin ? amount : 0;
        (bool ok, ) = address(bridgePlus).call{value: payAmount}(bridgeparams);
        if (!ok) {
          revert DelegatecallFailed();
        }
      }
      else {
        (bool success, ) = payable(account).call{value: amount}("");
        require(success, "Basket: withdraw");
      }
    }
  }

  function setSecuredFunctions(address contractAddr, bytes calldata funcIndex, bool mode) public onlyManager {
    securedFunctions[contractAddr][funcIndex] = mode;
  }

  function setWithdrawFunctions(address contractAddr, bytes calldata funcIndex, bool mode) public onlyManager {
    withdrawFunctions[contractAddr][funcIndex] = mode;
  }

  function setManager(address account, bool access) public onlyOwner {
    managers[account] = access;
  }

  function _getFuncIndex(bytes memory data) internal pure returns(bytes memory) {
    bytes memory tempBytes;
    assembly {
      tempBytes := mload(0x40)
      let lengthmod := and(0x4, 31)
      let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
      let end := add(mc, 0x4)
      for {
        let cc := add(add(add(data, lengthmod), mul(0x20, iszero(lengthmod))), 0x0)
      } lt(mc, end) {
        mc := add(mc, 0x20)
        cc := add(cc, 0x20)
      } {
        mstore(mc, mload(cc))
      }
      mstore(tempBytes, 0x4)
      mstore(0x40, and(add(mc, 31), not(31)))
    }
    return tempBytes;
  }

  function _bytesToAddress(bytes memory b, uint256 s) public pure returns (address){
    address addr;
    assembly {
      addr := mload(add(b, add(s, 20)))
    }
    return addr;
  }

  function _replaceAmount(bytes memory data, uint256 x, uint256 offset) public pure returns (bytes memory) {
    bytes memory b;
    uint256 size = 32;
    assembly {
      b := mload(0x40)
      mstore(b, size)
      mstore(add(b, 0x20), x)
      mstore(0x40, add(b, add(size, 0x20)))
    }
    for (uint256 i = 0; i < b.length; i++) {
      data[offset + i] = b[i];
    }
    return data;
  }
}