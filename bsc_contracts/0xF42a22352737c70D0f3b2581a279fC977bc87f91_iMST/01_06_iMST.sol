// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract iMST is ERC20, Ownable {

    uint8 _decimals;
    constructor(string memory _name, string memory _symbol, uint8 dec, uint256 amount, address _mintTo) ERC20(_name, _symbol) {
            _decimals = dec;
            _mint(_mintTo, amount * 10 ** dec);
        }
            
    receive() external payable {}

    /**
      * function to transfer specific erc20 token to specific address
    */
   function claimToken(ERC20 _token, address _to) public onlyOwner{
         _token.transfer(_to, _token.balanceOf(address(this)));
   }

    function transferEther(
        address payable _recipient, 
        uint _amount
    ) 
    external 
    onlyOwner 
    returns (bool) 
    {
        require(address(this).balance >= _amount, 'Not enough Ether in contract!');
        _recipient.transfer(_amount);

        return true;
    }
    
    function decimals() public view override returns(uint8){
        return _decimals;
    }
}