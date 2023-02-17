// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/*                                                                    
            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        
          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        
         @@@@@@                                                    @@@@@        
         @@@@@                                                     @@@@@        
         @@@@@                                                     @@@@@        
         @@@@@                      @@                             @@@@@        
         @@@@@                      @@@@@@                         @@@@         
         @@@@@                        @@@@@@@                                   
         @@@@@            @@@         @@@@@@@@@@@                               
         @@@@@             @@@@@@    @@@@@@@@@@@@@@@                            
         @@@@@              @@@@@@@@@@@@@@@@@@@@   @@@@                         
         @@@@@               @@@@@@@@@@@@@@@    @@  @@@@@@                       
         @@@@@                @@@@@@@@@@  @@@     @@@@@@@                       
         @@@@@                 @@@@@   @@  @@@@@@@@@@@@                         
         @@@@@                  @@@@       @@@@@@@@@@@                          
         @@@@@                   @@@@@@@@@@@@@@@@@@@@@                          
         @@@@@                   @@@@@@@@@@@@@@@@@@@@@@@                        
         @@@@@                      @@@@@       @@@@@@@@@                       
         @@@@@                                  @@@@@@@@@@                      
          @@@@@                                @@@@@@@@@@@@                     
           @@@@@                              @@@@@@@@@@@@@                     
            @@@@@@                          @@@@@@@@@@@@@@@                     
              @@@@@@                       @@@@@@@@@@@@@@@@                     
                @@@@@@@                  @@@@@@@@@@@@@@@@@@                     
                   @@@@@@@@@          @@@@@@@@@@@@@@@@@@@@                      
                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC20Extended {
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

contract psmstart is Multicall, AccessControl {

    using SafeERC20 for IERC20;

    bytes32 public constant CONVERTER_ROLE = keccak256("CONVERTER");

    IERC20 public synth; 
    IERC20 public tradeable; // yield token
    address public feeToken;
    address public treasury;

    constructor(IERC20 _synth, IERC20 _tradeable) {
        _setupRole(CONVERTER_ROLE, msg.sender);
        _setRoleAdmin(CONVERTER_ROLE, CONVERTER_ROLE); 
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        synth = _synth;
        tradeable = _tradeable;
    }

    function trade(uint256 amount ) public onlyRole(CONVERTER_ROLE) {
        uint256 maxRedeemable = tradeable.balanceOf(address(this));
        if (amount > maxRedeemable){
            amount = maxRedeemable;
        }
        IERC20Extended(address(synth)).burnFrom(msg.sender, amount);
        tradeable.safeTransfer(msg.sender, amount);
    }

    function synthToFeeToken(uint256 amount) public onlyRole(CONVERTER_ROLE) {
        synth.approve(feeToken, amount);
        IFeeToken(feeToken).deposit(amount, treasury);
    }

    function setTreasury(address _treasury) public onlyRole(DEFAULT_ADMIN_ROLE) {
        treasury = _treasury;
    }

    function setFeeToken(address _feeToken) public onlyRole(DEFAULT_ADMIN_ROLE) {
        feeToken = _feeToken;
    }
}

interface IFeeToken {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
}