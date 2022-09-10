pragma solidity >=0.8.10 >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//01010100 01110010 01110101 01110011 01110100 00100000 01101110 01101111 00100000 01101111 01101110 01100101 00100000 01101111 01101110 01101100 01111001 00100000 01110100 01110010 01110101 01110011 01110100 00100000 01100011 01101111 01100100 01100101 00100000 01100010 01100101 00100000 01101111 01101110 00100000 01110100 01101000 01100101 00100000 01101100 01101111 01101111 01101011 00100000 01101111 01110101 01110100 00100000 01100110 01101111 01110010 00100000 01110100 01101000 01100101 00100000 01101110 01100101 01111000 01110100 00100000 01100011 01101100 01110101 01100101 00101100 00100000 01110011 01110100 01100001 01111001 00100000 01101111 01101110 00100000 01111001 01101111 01110101 01110010 00100000 01110100 01101111 01100101 01110011 00100000 01100011 01101100 01110101 01100101 01110011 00100000 01100001 01110010 01100101 00100000 01100101 01110110 01100101 01110010 01111001 01110111 01101000 01100101 01110010 01100101

contract HexChedda is ERC20 {
 address DevWallet = 0x7DcA34823C35F199514a7b25E2b165A549a7FA6e;
    // Constructor
    constructor() ERC20('Hex Chedda', 'HCHEDDA')  {
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