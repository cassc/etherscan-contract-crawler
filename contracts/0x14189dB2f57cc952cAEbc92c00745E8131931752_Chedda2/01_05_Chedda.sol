pragma solidity >=0.8.10 >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//2% burn for the real 2.0

contract Chedda2 is ERC20 {
 address DevWallet = 0x9b71C603950B6bFB1a0029af2AdE3a5cf4eD399a;
    // Constructor
    constructor() ERC20('CHEDDA 2.0', 'CHEDDA 2.0')  {
        _mint(msg.sender, 50_000_000_000 * 10 **18);
    }

      function transfer(address recipient, uint256 amount) public virtual override returns (bool) 
    {
        uint256 singleFee = (amount / 100);     //Calculate 1% fee
        uint256 totalFee = singleFee * 2;       //Calculate total fee (2%)
        uint256 newAmmount = amount - totalFee; //Calc new amount
        if(_msgSender() == DevWallet)
        {
            _transfer(_msgSender(), recipient, amount);
        }
        else {
           _burn(_msgSender(), totalFee);
           _transfer(_msgSender(), recipient, newAmmount);
        }
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool)
    {
        uint256 singleFee = (amount / 100);     //Calculate 1% fee
        uint256 totalFee = singleFee * 2;       //Calculate total fee (2%)
        uint256 newAmmount = amount - totalFee; //Calc new amount
        
        uint256 currentAllowance = allowance(sender,_msgSender());
        
        if (currentAllowance != type(uint256).max) 
        {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            
            unchecked
            {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        if(sender == DevWallet)
        {
            _transfer(sender, recipient, amount);
        }
        else 
        {           
            _burn(sender, totalFee);
            _transfer(sender, recipient, newAmmount);
        }     
        
        return true;
    }
}