// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

/**   ______   __         __  __     __  __        ______   ______     __  __     ______     __   __    
  *  /\  ___\ /\ \       /\ \/\ \   /\_\_\_\      /\__  _\ /\  __ \   /\ \/ /    /\  ___\   /\ "-.\ \   
  *  \ \  __\ \ \ \____  \ \ \_\ \  \/_/\_\/_     \/_/\ \/ \ \ \/\ \  \ \  _"-.  \ \  __\   \ \ \-.  \  
  *   \ \_\    \ \_____\  \ \_____\   /\_\/\_\       \ \_\  \ \_____\  \ \_\ \_\  \ \_____\  \ \_\\"\_\ 
  *    \/_/     \/_____/   \/_____/   \/_/\/_/        \/_/   \/_____/   \/_/\/_/   \/_____/   \/_/ \/_/
 **/

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract FLX is ERC20PresetMinterPauser {
                                               
     uint256 public constant MAX_SUPPLY    = 1000000000e18; // 1 billion
    uint256 public constant INITIAL_SUPPLY =  560413928e18; // 579.413928 million
    
    constructor(address _dao, address _treasury) ERC20PresetMinterPauser("Flux Token", "FLX") {
       // Mint initial balance
       _mint(_treasury, INITIAL_SUPPLY);
       
       // Grant minter rights to DAO
       grantRole(MINTER_ROLE, _dao);
       
       // Revoke sender minting rights
       revokeRole(MINTER_ROLE, _msgSender());

       // Revoke sender pauser rights
       revokeRole(PAUSER_ROLE, _msgSender());
       
       // Revoke sender admin rights
       revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
   }

    // Override mint() to prevent exceeding MAX_SUPPLY
    function mint(
        address to,
        uint256 amount
    ) public virtual override {
        require(amount + totalSupply() <= MAX_SUPPLY, "Mint exceeds max supply");
        super.mint(to, amount); // checks for MINTER_ROLE
    }
}