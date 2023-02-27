/* @author
*    __         ______     __  __     __   __     ______     __  __     __     ______   __    
*  /\ \       /\  __ \   /\ \/\ \   /\ "-.\ \   /\  ___\   /\ \_\ \   /\ \   /\  ___\ /\ \   
* \ \ \____  \ \  __ \  \ \ \_\ \  \ \ \-.  \  \ \ \____  \ \  __ \  \ \ \  \ \  __\ \ \ \  
*   \ \_____\  \ \_\ \_\  \ \_____\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \_\  \ \_\    \ \_\ 
*    \/_____/   \/_/\/_/   \/_____/   \/_/ \/_/   \/_____/   \/_/\/_/   \/_/   \/_/     \/_/ 
*
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.8.13 <0.9.0;

 import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";   


        import "@openzeppelin/contracts/access/Ownable.sol";

        contract Qincoin is ERC20Capped  , Ownable {
   
        constructor(uint256 cap) ERC20("qin coin", "Q") ERC20Capped(cap){

         
         }     

    
    /// @notice Mint function
    /// @dev only the owner can mint
    /// @param to  user Address to mint tokens
    /// @param amount the amount of tokens to mint
    function mint(address to, uint256 amount) public onlyOwner{
        _mint(to, amount);
    }

        function _mint(address account, uint256 amount) internal virtual override (ERC20Capped) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
        } 



    
   
   

   
}