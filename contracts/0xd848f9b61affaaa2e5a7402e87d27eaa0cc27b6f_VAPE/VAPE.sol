/**
 *Submitted for verification at Etherscan.io on 2020-09-17
*/

pragma solidity ^0.5.0;

 /**
 * 
 * https://aesthetics.finance
 * 
 * 
 * 
 * ａｎｇｅｌｐｌｅａｓｅｄｏｎ'ｔｇｏ I'll miss you when you go 
 * 
 *      ```  ``   ``  ```  ``   ``  ``   ``  ```  ```  ``  ```  ``   ``   ``  ``   ``  ```  ``   ``   ``  
 *`  ``  ```  ``   ``  ```  ``  ```  ```  ``  ```  ```  ``  ```  ```  ``  ```  ``   ``   ``  ``   ``
 *  `   ``  ```  ``   ``` ```   ``  ```````````...```` `   ``` ```   ``  ```   `   `   ```  ``  ```  
 *``````    `  ```` ````  `` ```````.-::::::::::://:----..```````  `` `  `` ````` ``  `   `   ````` 
 *   ``  ```  ``   ``  ```  `--//:/:::/++//::::::::::::::::-.``   `   ``  ```  ``    `  ```  ``   ``
 *```  ``   ``  ```  ``  ```.::://///+osso+/::::::::::++///::/..`  ```  ``   ``  ```  ``   ``  ```  
 *   ``  ```  ``   ``  ````-://+//:/+o+///::::::::---::/++o+/:--::-`  ``  ```  ``   ``  ```  ``   ``
 * ```  ```  ``  ``` `-//:::://++:---::::/+/+//++++ooo+++//:///////+/-`  ``   ``  ```  ``   ``  ``   
 *   ``  ```  ``  `-++::::::+++++/:./ooooo++ooooyyyyso+//:::::+ssso/o-``  ```  ``   ``  ```  ```  ``
 *```  ``   `` ```.s+/+/:::://////:/oyysoosssssyhysoo+//::++///+oo/o.`` ``   ``   ``  ``   ``  ```  
 *``` ``   ``  ````+yy+/:::/++///+oyys+yhyyyyyyyysoo+oo++oyyso+oooo/:` ` ` `  ``````` `   ``   `  ` 
 *   ``  ```  ``` ``+ys//+++++/osyhysosyhyssyyyyo+++yyooohdhhyoso++oo/-.  ```  ``   ``  ```  ```  ``
 * ```  ```  ``  ````./++++osys/++yyyysso+/osssssyyysyyyyhhysssyy++osss+o-``  ``  ``   ``   ``   ``  
 *   ``   ``  ``  `./+osssoossooossso+/:---:/++oossssooosyysoshhso++oys/o````  ``   ``  ```  ``   ``
 *```  ```  ``  ````/syyhhhyyo/oo+/::---..`.-::/+++oo++++oosydddysyssoo:-``  ``  ``   ``   ``   `   
 *   ``  ```  ``   ```-oyhhyo+oo+:----.....--::::::///++++++shyhhhhhyy/+- ```  ``   ``  ```  ```  ``
 *``` ``` ```  ` ``  `-ooyhhyyyo/////++++++///////////////++syshhhhhhy//``    ``  `   ``  ```  ```  
 * ``  ```   ``  ```  `:++so+++/::/+oooosyyyyssoooo+oooooo+++syyhhyso/:````   ```  ``` ``` ```  `````
 *  ```   ``  ``  ````-+osso+:---:/oooossyyyyso++osyhhysssooossohs``````  ```  ``   ``  ```  ```  ``
 *```  ```  ``  ```  ``-//oo+/:----:/++oossss+/::+yhhyyssssooso/o` ```  ``   ``  ``   ``   ``  ``   
 *   ``  ```  ``   ``  `:///////::::::////:::---:/+ossooooo++o:o-``   ``  ```  ```  ``  ```  ``   ``
 *```  ``   ``  ```  ````/+so+++//:::::::::::---:////++++//+++:o`   ``  ``   ``  ```  ``   ``   ``  
 *   ``  ```  ``   ``   `.:oysoo++///////++/::-:/+++++////++o:s.  `   ``  ```  ``    `  ```  ``   ``
 *` `` `` `````````  `` ```-yo+o++++++++ooo/:--:/ooo+++++++o/o:``  ```` ``````` ```       ```  ``   
 *```  ``   `  ````  ``` ```sso+++++++++//+++////oooo+++++oys-```  ````  ``  ``  ```` `    `` ````  
 *   ``  ```  ``  ```  ```  :yso++++++//::-/sssoooo++++++oooy.`` ```  ``  ```  ``   ``  ```  ``   ``
 *```  ``   ``  ```  ``   ```+ysoo+++ooo+/::/++++++++++ooo++s/```  ```  ``   ``   ``  ``   ``  ```  
 *   ``  ``   ``   ``  ```  ``+ysooooossoooossssosssooooo+//+y.  ``   ``  ```  ``   ``  ```  ```  ``
 *```  ```  ``  ``   ``  ```  `/yysssooooooosssoosssoooo++///oo.`   ``  ``  ```  ``   ``   ``   ``  
 *  ```  ```  ``   ``  ```  ````/hyyso++++osssoooooooooo+////+oo.```  ``  ```  ```  ``  ```  ``   ``
 *  ```  ``   `` `  ` ``  ```  ``.yhhysoo++oooo+++oosooo++/////++o:`` ` ```  ```   `   ```   ``  `  `
 *```  ```  ``  ``   ``` ```  ```:hyhyyyysssssssssssooo+++/////++o/.``  ``   ``  ```  ``   ``  ``   
 *   ``   ``  ``   ``  ```  ``  ``ohyyyyyyyyyyyyyyssooo++++///////+o:```  ```  ``   ``   ``  ```  ``
 *```  ``   ``  ```  ``   ``   `` `shyyyyyyyyyyyyyssooo++++////////+++.````  ``  ```  ``   ``  ```  
 *   ``   ``  ``   ``  ```  ``  ````oyyyyysyssssssssoooo++++////////+++/-:-``  ``   ``  ```  ```  ``
 *```  ```  ``  ```  ``  ```  ```  ``/syyyssssssssssoooo++++////////++++ooo/-``  ```  ``   ``  ```  
 *  ```  ``` ```   ``  ```  ```  ``  `.syyssyssssssssoooo+++++++++////////++//.```  ``  ``` ```    `
 *   ````    `    `  ``    `   ` `` ```-ssysyyssssssssoooo++++++///////++++++++::```` `` ``     `   
 *```  ```  ``  ``   ``   ``  ```  ````:ssyyyyyssssssssoooo+o++++++++++++++++oo/+.``  ```  ``  ``   
 *   ``   ``  ``   ``  ```  ``  ````.:+oosssyyysssssssooo+++++++++++oooossoo+/:--`  ``  ```  ```  ``
 *```  ``   ``  ```  ``   ``  ````-//+++ooosyysssssssoo+///++++ooossso+/:-.` ``   ``  ``   ``  ```  
 *   ``   ``  ``   ``  ```  ```.:///////+++sssssssyso////++++oooo+/-` ``  ```  ``   ``   ``  ``   ``
 *```  ``   ``  ```  ``   ``.-/++++///::///++///+++///++++ooo+/-` ````  ``   ``  ```  ``   ``  ```  
 *  ```  ``` ```  ```  ```.://++//////://///::::://++++ooo+:.``  ``` ```  ``   ``   ``   ``  ``   ``
 *   `  ``   `` `  `  ` ``///+++:::/://::::::::/+++++oos+.````    `     `  ```  ``   ` ````       ``
 * ``  ``   ``  ```  ``   -:+++o/:///++/:-:://+++++oso/.  ```  ``   `   ``  ```  ```  ``   ``   ``  
 *`   ``  ```  ``   ``  ```  ``.-::++++o+//++++++oos+:`  ``  ```  ``   ``  ```  ``   ``  ```  ``   ``
 * ```  ``   ``  ```  ``   ``  ```  `-::/++oooooso:.  ```  ``   ``  ```  ``   ``  ```  ``   ``  ```  
 *``   ``   ``  ``   ``  ```  ``  ```  ```  ```````  ```  ``  ```  ```  ``  ``   ``   ``   ``  ```  ``
 *  ``   ``   ``  ```  ``  ```   ``  ``  ```  ```  ``   `   ```  ``   ``  ``   ``   ``  ```  ``  ```  
 *``   ``  ```  ``   ``  ``   ``  ```  ```  ``   ``  ``   ``    `  ``   ``   `   ``   ``  ```   `   ``
 * 
 * 
 * 
 * 
 * Ｖａｐｏｒｗａｖｅｉｓｄｅａｄ
 * 
 */
 
 // Copied & modified from NUTS code:
 // https://squirrel.finance/
 // this alteration has not been audited and may contain bugs - be warned.


interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}

contract VAPE is ERC20 {
    using SafeMath for uint256;
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    string public constant name  = "aesthetics.finance";
    string public constant symbol = "VAPE";
    uint8 public constant decimals = 18;

    uint256 totalVape = 4200000 * (10 ** 18);
    address public currentGovernance;
    
    constructor() public {
        balances[msg.sender] = totalVape;
        currentGovernance = msg.sender;
        emit Transfer(address(0), msg.sender, totalVape);
    }
    
    function totalSupply() public view returns (uint256) {
        return totalVape;
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

    function approveAndCall(address spender, uint256 tokens, bytes calldata data) external returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
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
    
    function updateGovernance(address newGovernance) external {
        require(msg.sender == currentGovernance);
        currentGovernance = newGovernance;
    }
    
    function mint(uint256 amount, address recipient) external {
        require(msg.sender == currentGovernance);
        balances[recipient] = balances[recipient].add(amount);
        totalVape = totalVape.add(amount);
        emit Transfer(address(0), recipient, amount);
    }
    
    function burn(uint256 amount) external {
        require(amount != 0);
        require(amount <= balances[msg.sender]);
        totalVape = totalVape.sub(amount);
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