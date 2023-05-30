// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import { IGlove } from "./interfaces/IGlove.sol";


contract Glove is IGlove, AccessControlEnumerable
{
  bytes32 public constant CREDITOR_ROLE = keccak256("CREDITOR_ROLE");

  bytes32 private constant _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 private constant _DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

  bytes32 private constant _NAME_HASH = keccak256("Glove");
  bytes32 private constant _VERSION_HASH = keccak256("1");

  bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
  uint256 private immutable _CACHED_CHAIN_ID;
  address private immutable _CACHED_THIS;


  uint256 private _totalSupply;

  mapping(address => uint256) private _nonce;

  mapping(address => uint256) private _credit;

  mapping(address => uint256) private _balance;
  mapping(address => mapping(address => uint256)) private _allowance;


  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);


  constructor ()
  {
    _CACHED_THIS = address(this);
    _CACHED_CHAIN_ID = block.chainid;
    _CACHED_DOMAIN_SEPARATOR = _separator();


    _setupRole(CREDITOR_ROLE, msg.sender);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setRoleAdmin(CREDITOR_ROLE, DEFAULT_ADMIN_ROLE);
  }


  function name () public pure returns (string memory)
  {
    return "Glove";
  }

  function symbol () public pure returns (string memory)
  {
    return "GLO";
  }

  function decimals () public pure returns (uint8)
  {
    return 18;
  }

  function totalSupply () public view returns (uint256)
  {
    return _totalSupply;
  }

  function balanceOf (address account) public view returns (uint256)
  {
    return _balance[account];
  }


  function creditOf (address account) public view returns (uint256)
  {
    return _credit[account];
  }

  function creditlessOf (address account) public view returns (uint256)
  {
    return _balance[account] - _credit[account];
  }


  function _separator () private view returns (bytes32)
  {
    return keccak256(abi.encode(_DOMAIN_TYPEHASH, _NAME_HASH, _VERSION_HASH, block.chainid, address(this)));
  }

  function DOMAIN_SEPARATOR () public view returns (bytes32)
  {
    return (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) ? _CACHED_DOMAIN_SEPARATOR : _separator();
  }

  function nonces (address owner) public view returns (uint256)
  {
    return _nonce[owner];
  }

  function allowance (address owner, address spender) public view returns (uint256)
  {
    return _allowance[owner][spender];
  }


  function _approve (address owner, address spender, uint256 amount) internal
  {
    _allowance[owner][spender] = amount;


    emit Approval(owner, spender, amount);
  }

  function approve (address spender, uint256 amount) public returns (bool)
  {
    _approve(msg.sender, spender, amount);


    return true;
  }

  function increaseAllowance (address spender, uint256 amount) public returns (bool)
  {
    _approve(msg.sender, spender, _allowance[msg.sender][spender] + amount);


    return true;
  }

  function decreaseAllowance (address spender, uint256 amount) public returns (bool)
  {
    uint256 currentAllowance = _allowance[msg.sender][spender];

    require(currentAllowance >= amount, "GLO: decreasing < 0");


    unchecked
    {
      _approve(msg.sender, spender, currentAllowance - amount);
    }


    return true;
  }

  function permit (address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public
  {
    require(block.timestamp <= deadline, "GLO: expired deadline");


    bytes32 hash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _nonce[owner]++, deadline));
    address signer = ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), hash)), v, r, s);

    require(signer != address(0) && signer == owner, "GLO: !valid sig");


    _approve(owner, spender, value);
  }


  function _isCreditor () internal view
  {
    require(hasRole(CREDITOR_ROLE, msg.sender), "GLO: !creditor");
  }

  function _transfer (address from, address to, uint256 amount) internal
  {
    require(to != address(0), "GLO: transfer to 0 addr");


    uint256 balance = _balance[from];

    require(balance >= amount, "GLO: amount > balance");


    unchecked
    {
      _balance[from] = balance - amount;
      _balance[to] += amount;
    }


    emit Transfer(from, to, amount);
  }

  function _transferCredits (address from, address to, uint256 amount) internal
  {
    uint256 credit = _credit[from];

    bool senderIsCreditor = hasRole(CREDITOR_ROLE, from);
    bool recipientIsCreditor = hasRole(CREDITOR_ROLE, to);


    if (!senderIsCreditor && !recipientIsCreditor)
    {
      require(credit >= amount, "GLO: amount > credit");
    }


    _credit[from] = credit > amount ? credit - amount : 0;


    if (senderIsCreditor || recipientIsCreditor)
    {
      _credit[to] += amount;
    }
    else if (from == tx.origin)
    {
      _credit[to] += (_balance[to] > amount ? amount : ((amount * 99_00) / 100_00));
    }
  }

  function transfer (address to, uint256 amount) public returns (bool)
  {
    _transfer(msg.sender, to, amount);
    _transferCredits(msg.sender, to, amount);


    return true;
  }

  function transferCreditless (address to, uint256 amount) public returns (bool)
  {
    _isCreditor();


    _transfer(msg.sender, to, amount);

    _credit[msg.sender] = _credit[msg.sender] > amount ? (_credit[msg.sender] - amount) : 0;


    return true;
  }

  function transferFrom (address from, address to, uint256 amount) public returns (bool)
  {
    uint256 currentAllowance = _allowance[from][msg.sender];


    if (currentAllowance != type(uint256).max)
    {
      require(currentAllowance >= amount, "GLO: !enough allowance");


      unchecked
      {
        _approve(from, msg.sender, currentAllowance - amount);
      }
    }


    _transfer(from, to, amount);
    _transferCredits(from, to, amount);


    return true;
  }


  function _creditize (address account, uint256 amount) internal
  {
    _isCreditor();


    uint256 balance = _balance[account];
    uint256 addition = _credit[account] + amount;


    _credit[account] = addition > balance ? balance : addition;
  }

  function _mint (address account, uint256 amount) internal
  {
    require(account != address(0), "GLO: mint to 0 addr");


    _totalSupply += amount;


    unchecked
    {
      _balance[account] += amount;
    }


    emit Transfer(address(0), account, amount);
  }

  function mint (address account, uint256 amount) external
  {
    _mint(account, amount);
    _creditize(account, amount);
  }

  function mintCreditless (address account, uint256 amount) external
  {
    _isCreditor();


    _mint(account, amount);
  }

  function creditize (address account, uint256 amount) external returns (bool)
  {
    _creditize(account, amount);


    return true;
  }


  function _decreditize (address account, uint256 amount) internal
  {
    _isCreditor();


    uint256 credit = _credit[account];


    _credit[account] = credit > amount ? (credit - amount) : 0;
  }

  function _burn (address account, uint256 amount) internal
  {
    uint256 balance = _balance[account];

    require(balance >= amount, "GLO: burn > balance");


    unchecked
    {
      _balance[account] = balance - amount;
      _totalSupply -= amount;
    }


    emit Transfer(account, address(0), amount);
  }

  function burn (address account, uint256 amount) external
  {
    _isCreditor();


    uint256 creditless = _balance[account] - _credit[account];


    _burn(account, amount);


    if (amount > creditless)
    {
      _decreditize(account, amount);
    }
  }

  function decreditize (address account, uint256 amount) external returns (bool)
  {
    _decreditize(account, amount);


    return true;
  }
}