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

contract feeSplitStaking is Multicall, AccessControl {

    using SafeERC20 for IERC20;

    bytes32 public constant CONVERTER_ROLE = keccak256("CONVERTER");

    IERC20 public rewardsToken; // synth token
    IERC20 public collateral; // fee token
    IERC20 public tradeable; // yield token

    mapping(address => uint256) public deposited;
    mapping(address => uint256) public lastPoints;

    uint256 public totaldeposits;

    // allocation logic for depositors
    uint256 public pointMultiplier = 10e18;
    uint256 public totalPoints;
    uint256 public unclaimed;

    function Owing(address _depositor) public view returns(uint256) {
        uint256 newPoints = totalPoints - lastPoints[_depositor];
        return (deposited[_depositor] * newPoints) / pointMultiplier;
    }

    modifier fetch(address _depositor) {
        uint256 owing = Owing(_depositor);
        if (owing > 0) {      
            unclaimed = unclaimed - owing;
            rewardsToken.transfer(_depositor, owing);
        }
        lastPoints[_depositor] = totalPoints;
        _;
    }

    modifier sync() {
        uint256 excess = rewardsToken.balanceOf(address(this)) - unclaimed;
        if (excess > 100) {
            totalPoints = totalPoints + (excess * pointMultiplier / totaldeposits);
            unclaimed += excess;
        }
        _;
    }

    constructor(IERC20 _rewardsToken, IERC20 _collateral, IERC20 _tradeable) {
        _setupRole(CONVERTER_ROLE, _msgSender());
        _setRoleAdmin(CONVERTER_ROLE, CONVERTER_ROLE);
        rewardsToken = _rewardsToken;
        collateral = _collateral;
        tradeable = _tradeable; 
    }

    function deposit(uint256 amount) external sync() fetch(msg.sender) {
        collateral.safeTransferFrom(msg.sender, address(this), amount);
        deposited[msg.sender] += amount;
        totaldeposits += amount;
    }

    function withdraw(uint256 amount) external sync() fetch(msg.sender) {
        deposited[msg.sender] -= amount; 
        totaldeposits -= amount;
        collateral.safeTransfer(msg.sender, amount);
    }

    function poke(address _depositor) external sync() fetch(_depositor) {
        // the purpose of this function is to trigger the modifiers
    }

    function trade(uint256 amount) public onlyRole(CONVERTER_ROLE) {
        uint256 maxRedeemable = tradeable.balanceOf(address(this));
        if (amount > maxRedeemable) {
            amount = maxRedeemable;
        }
        rewardsToken.safeTransferFrom(msg.sender, address(this), amount);
        tradeable.safeTransfer(msg.sender, amount);
    }
}