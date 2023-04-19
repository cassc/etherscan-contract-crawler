// SPDX-License-Identifier: MIT
/** 
                                                                                                                          
                                                            %@@                                                         
                                                         @       @                                                      
                                                       @           @                                                    
                                                      @             @                                                   
                                                     @                #                                                 
                                                    &                  @                                                
                                                   &                    @                                               
                                                  #                      @                                              
                                                 @                        &                                             
                                                @                          (                                            
                                               @                            ,                                           
                                              @                             ,                                           
                                             @                               #                                          
                                            @                                 @                                         
                                           @                                   @                                        
                                          @                                     @                                       
                                         @                                       @                                      
                                        @                                         @                                      
                                       @                                            #                                   
                                     ,@                                              @                                  
                                    @                                                 @                                 
                                   &                                                   @                               
                                 @                                                       @                              
                              [email protected]                                                            @                           
                           [email protected]                                                                 &@                        
                      @@                                                                            @@   
                @@                                                                                        @@   
*/
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LOWIQ is ERC20, Ownable {
    error IQTooHigh();

    uint256 public immutable maxHoldingAmount;
    uint256 public restrictionEnd;

    constructor() ERC20("LowIQ", "LOWIQ") {
        maxHoldingAmount = (69 * 10 ** 30); // 1% max
        _mint(msg.sender, 69 * 10 ** 32);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function start() external onlyOwner {
        restrictionEnd = block.timestamp + 48 hours;
        renounceOwnership();
    }

    function _beforeTokenTransfer(address, address to, uint256 value) internal virtual override {
        if (block.timestamp < restrictionEnd && balanceOf(to) + value > maxHoldingAmount) revert IQTooHigh();
    }
}