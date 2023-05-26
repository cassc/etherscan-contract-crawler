/**
 *Submitted for verification at Etherscan.io on 2019-09-08
*/

pragma solidity ^0.5.0;

//license of Barter Smart Co.,Ltd. Thailand (Applied from MIT) Final Version

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}



// ERC 20 Token Standard #20 Interface

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}


//Owned
contract Owned {
    address payable public owner;
    address payable public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



contract BigPoint is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "BIGP";
        name = "Big Point";
        decimals = 18;
        _totalSupply = 21000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


   
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


   
    

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    
    
     mapping(address => uint) ShareStatus;
    address payable[] ShareAddress;
    uint8 public i = 0;//for adding share iteration
    uint public fee;
    uint public ordertoPay= 0;
    uint256 public minBalance;
    uint public warnRepeated;
    
    
    
    function AddShare(address payable _Share)public onlyOwner returns(bool){
        require(balances[_Share]>0);
         
         
         for(uint e =0; e<i; e++){
        if(_Share ==ShareAddress[e]){
          warnRepeated =1;}
         }
         
         if(warnRepeated!=1){
         
         
        ShareAddress.push(_Share);
        ShareStatus[_Share]=1;
        i++;
        //ShareStatus = 1 => approved
        
         }
        warnRepeated = 0; 
    }
    
    
    function AddShareManual(address payable _Share)public onlyOwner returns(bool){
        require(balances[_Share]>0);
        ShareStatus[_Share]=1;
        ShareAddress.push(_Share);
        i++;
        
        
    }
    
    function viewSharePermission(address payable _Share)public view returns(bool){
        if(ShareStatus[_Share]==1){return true;}
        if(ShareStatus[_Share]!=1){return false;}
    }
    
    
    
    
    function BanThisAddress(address payable _Share)public onlyOwner returns(uint){
        require(ShareStatus[_Share]==1);
         ShareStatus[_Share]=0;
         //ShareStatus = 0 => banned
    }
    
    function CancelBanThisAddress(address payable _Share)public onlyOwner returns(uint){
        require(ShareStatus[_Share]==0);
         ShareStatus[_Share]=1;
         //ShareStatus = 1 => unbanned
    }
    
    
    
    function SetFeeinWei(uint _fee)public onlyOwner returns(uint){
        fee = _fee;
    }
    
    function viewFee()public onlyOwner view returns(uint){
       return fee;
    }
    
    
    function CalWeiToPay(uint _ordertoPay, uint _ShareWei)public onlyOwner view returns(address payable, uint, uint){
        
        require(ShareStatus[ShareAddress[_ordertoPay]]==1 && balances[ShareAddress[_ordertoPay]]>=minBalance);
        uint Amount_to_pay = balances[ShareAddress[_ordertoPay]].mul(_ShareWei).div(_totalSupply);
        Amount_to_pay = Amount_to_pay.sub(fee);
        
        return (ShareAddress[_ordertoPay], Amount_to_pay, balances[ShareAddress[_ordertoPay]]);
    }
    
    
    
    function CalWeiToPayByAddress(address payable _thisAddress, uint _ShareWei)public onlyOwner view returns(address payable, uint, uint){
        
        require(ShareStatus[_thisAddress]==1 && balances[_thisAddress]>=minBalance);
        uint Amount_to_pay = balances[_thisAddress].mul(_ShareWei).div(_totalSupply);
        Amount_to_pay = Amount_to_pay.sub(fee);
        
        return (_thisAddress , Amount_to_pay, balances[_thisAddress]);
    }
    
    
    
    
    function ResetOrdertoPay(uint reset)public onlyOwner returns(uint){
        ordertoPay = reset;
        
    }
    
    function SetMinBalance(uint256 _k)public onlyOwner returns(uint){
        minBalance = _k;
        return minBalance;
    }
    
    
    function viewMinBalanceRequireToPayShare()public view returns(uint){
        return minBalance;
        
    }
    
    function viewNumShare()public view returns(uint){
        return i;
    }
    
   
        
  
    
    
    
    
}