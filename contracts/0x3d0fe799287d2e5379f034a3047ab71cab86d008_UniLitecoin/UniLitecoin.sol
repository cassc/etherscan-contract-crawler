/**
 *Submitted for verification at Etherscan.io on 2020-06-12
*/

pragma solidity ^0.4.25;

// ----------------------------------------------------------------------------

// www.unibitcoin.network/unilitecoin

//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNmmddddddddddmmmNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMNmdhyyyyyyyyyyyyyyyyyyyyyyhdmNMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMmdhyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhdmMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMNmhyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhmNMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMmhyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyydMMMMMMMMMMMMM
//MMMMMMMMMMMmyyyyyyyyyyyyyyyyyyyyyyyyyy::::::::::+yyyyyyyyyyyyyyyyyyydMMMMMMMMMMM
//MMMMMMMMMmhyyyyyyyyhdhyyyyyyhddhhyyyy-          :yyyyyyyyyyyyyyyyyyyyymMMMMMMMMM
//MMMMMMMNhyyyyyyyyyyymMMNdhyyhMs+yNNddhhhs+-    `yyyyyyyyyyyyyyyyyyyyyyyhNMMMMMMM
//MMMMMMNyyyyyyyyyyyyyyhmNhdmmdNd  `Nho/--/oyms` +yyyyyyyyyyyyyyyyyyyyyyyyyNMMMMMM
//MMMMMmyyyyyyyyyyyyyyyyyhNmsohMm.  `-/sdho--:sNoyyyyyyyyyyyyyyyyyyyyyyyyyyymMMMMM
//MMMMmyyyyyyyyyyyyyyyyyyyydNmm/         .ym/--/MmhyyyyyyyyyyyyyyyyyyyyyyyyyymMMMM
//MMMmyyyyyyyyyyyyyyyyyyyyyhNo `           /N/--yMdNdyyyyyyyyyyyyyyyyyyyyyyyyymMMM
//MMNyyyyyyyyyyyyyyyyyyyyydN/   sMd   `     my--+MoomNyyyyyyyyyyyyyyyyyyyyyyyyyNMM
//MMhyyyyyyyyyyyyyyyyyyyydN-    `-`   do    my--/MsoomNyyyyyyyyyyyyyyyyyyyyyyyyhMM
//MNyyyyyyyyyyyyyyyyyyyymd.          /N-   :M/--/hooosMhyyyyyso+yyyyyyyyyyyyyyyyNM
//MdyyyyyyyyyyyyyyyyyyyNy`        .+hh.    dh----+oooyMd+:-.   +yyyyyyyyyyyyyyyyhM
//MyyyyyyyyyyyyyyyyyyydM`    -shdhs/::     Ns---:oooomdmh`    -yyyyyyyyyyyyyyyyyyM
//NyyyyyyyyyyyyyyyyyyyymmssshNhys   .hd`   yd---:ooomm+/hm+osyyyyyyyyyyyyyyyyyyyyN
//Nyyyyyyyyyyyyyyyyyyyyyyhhhyyyy-     yd   `mh:-:oomd+///dNyyyyyyyyyyyyyyyyyyyyyyN
//Nyyyyyyyyyyyyyyyyyyyyyyyyys+/-      .M-   `o:--+dN/////sMhyyyyyyyyyyyyyyyyyyyyyN
//Nyyyyyyyyyyyyyyyyyyso/:-`           -M.     .--:dd/////+MhyyyyyyyyyyyyyyyyyyyyyN
//Myyyyyyyyyyyyyyyyy:       .-`       dy        ``/Mo/////syyyyyyyyyyyyyyyyyyyyyyM
//Mdyyyyyyyyyyyyyyyo `-:/osyyo      `hh            /Ns////+yyyyyyyyyyyyyyyyyyyyydM
//MNyyyyyyyyyyyyyyysyyyyyyyyy.      :+              `/+///+yyyyyyyyyyyyyyyyyyyyyNM
//MMhyyyyyyyyyyyyyyyyyyyyyyy+          .+//::::::/+syyyysooyyyyyyyyyyyyyyyyyyyyhMM
//MMNyyyyyyyyyyyyyyyyyyyyyyy`          oyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyNMM
//MMMmyyyyyyyyyyyyyyyyyyyyy:          `//////////////////////syyyyyyyyyyyyyyyymMMM
//MMMMmyyyyyyyyyyyyyyyyyyys                                  /yyyyyyyyyyyyyyymMMMM
//MMMMMmyyyyyyyyyyyyyyyyyy-                                 `yyyyyyyyyyyyyyymMMMMM
//MMMMMMNyyyyyyyyyyyyyyyy+                                  +yyyyyyyyyyyyyyNMMMMMM
//MMMMMMMMhyyyyyyyyyyyyyy`                                 -yyyyyyyyyyyyyhMMMMMMMM
//MMMMMMMMMmhyyyyyyyyyyyysssssssssssssssssssssssssssssssssyyyyyyyyyyyyyhmMMMMMMMMM
//MMMMMMMMMMMmyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyymMMMMMMMMMMM
//MMMMMMMMMMMMMmhyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhmMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMmhyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhmMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMmhyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhmMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMmdhyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyhdmMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMNmdhyyyyyyyyyyyyyyyyyyyyyyhdmNMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNmmddddddddddmmNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM


// Symbol      : UNILITECOIN

// Name        : UniLitecoin

// Total supply: 8,400,000.00000000

// Decimals    : 8

// Inspired by UniPower Token / MrBlobby / GOO, & UniBitcoin / Crow

// ----------------------------------------------------------------------------

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) external;
}


contract UniLitecoin is ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private balances;
  mapping (address => mapping (address => uint256)) private allowed;
  string public constant name  = "UniLitecoin";
  string public constant symbol = "UNILITECOIN";
  uint8 public constant decimals = 8;
  
  address owner = msg.sender;

  uint256 _totalSupply = 8400000 * (10 ** 8); // 8.4 million supply

  constructor() public {
    balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address player) public view returns (uint256) {
    return balances[player];
  }

  function allowance(address player, address spender) public view returns (uint256) {
    return allowed[player][spender];
  }


  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= balances[msg.sender]);
    require(to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(value);

    emit Transfer(msg.sender, to, value);
    return true;
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function approveAndCall(address spender, uint256 tokens, bytes data) external returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= balances[from]);
    require(value <= allowed[from][msg.sender]);
    require(to != address(0));
    
    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);
    
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
    
    emit Transfer(from, to, value);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(subtractedValue);
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  function burn(uint256 amount) external {
    require(amount != 0);
    require(amount <= balances[msg.sender]);
    _totalSupply = _totalSupply.sub(amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    emit Transfer(msg.sender, address(0), amount);
  }

}




library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}