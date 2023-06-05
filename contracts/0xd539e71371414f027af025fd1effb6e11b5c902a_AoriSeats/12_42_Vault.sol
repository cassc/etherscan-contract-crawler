// SPDX-License-Identifier: UNLICENSED
/**                           
        /@#(@@@@@              
       @@      @@@             
        @@                      
        [email protected]@@#                  
        ##@@@@@@,              
      @@@      /@@@&            
    [email protected]@@  @   @  @@@@           
    @@@@  @@@@@  @@@@           
    @@@@  @   @  @@@/           
     @@@@       @@@             
       (@@@@#@@@      
    THE AORI PROTOCOL                           
 */
pragma solidity 0.8.19;

import "../OpenZeppelin/Ownable.sol";
import "../OpenZeppelin/ERC20.sol";
import "../Chainlink/AggregatorV3Interface.sol";
import "./MarginManager.sol";
import "../AoriCall.sol";
import "../AoriPut.sol";
import "../OpenZeppelin/Ownable.sol";
import "../OpenZeppelin/ReentrancyGuard.sol";
import "../OpenZeppelin/ERC4626.sol";
import "./Structs.sol";

contract Vault is Ownable, ReentrancyGuard, ERC4626 {

    ERC20 token;
    MarginManager manager;
    mapping(address => bool) public isSettled;
    uint256 USDCScale = 10**6;

    // struct settleVars {
    //     uint256 tokenBalBefore;
    //     uint256 tokenDiff;
    //     uint256 optionsSold;
    // }
    
    constructor(ERC20 asset, string memory name, string memory symbol, MarginManager manager_
    )  ERC4626(asset, name, symbol) {
        manager = manager_;
        token = ERC20(asset);
    }

    function depositAssets(uint256 assets, address receiver) public nonReentrant {
        deposit(assets, receiver);
    }

    function withdrawAssets(uint256 assets, address receiver) public nonReentrant {
        withdraw(assets, receiver, receiver);
    }

    // mintOptions(amountOfUnderlying, option, seatId, _account, true);
    function mintOptions(uint256 amountOfUnderlying, address option, uint256 seatId, address account, bool isCall) public nonReentrant returns (uint256) {
        require(msg.sender == address(manager));
        totalBorrows += amountOfUnderlying;
        uint256 optionsMinted;
        if(isCall) {
            AoriCall(option).UNDERLYING().approve(option, amountOfUnderlying);
            optionsMinted = AoriCall(option).mintCall(amountOfUnderlying, account, seatId);
            return optionsMinted;
        } else {
            AoriPut(option).USDC().approve(option, amountOfUnderlying);
            optionsMinted = AoriPut(option).mintPut(amountOfUnderlying, account, seatId);
            return optionsMinted;
        }
    }

    function settleITMOption(address option, bool isCall) public nonReentrant returns (uint256) {
        Structs.settleVars memory vars;
        if(isSettled[option]) {
            return 0;
        } else {
            require(AoriCall(option).endingTime() <= block.timestamp || AoriPut(option).endingTime() <= block.timestamp, "Option has not expired");
            vars.tokenBalBefore = token.balanceOf(address(this));
            if(isCall) {
                vars.optionsSold = AoriCall(option).getOptionsSold(address(this));
                AoriCall(option).sellerSettlementITM();
                isSettled[option] = true;
            } else {                
                vars.optionsSold = AoriPut(option).getOptionsSold(address(this));
                AoriPut(option).sellerSettlementITM();
                isSettled[option] = true;
            }
            vars.tokenDiff = token.balanceOf(address(this)) - vars.tokenBalBefore;
            totalBorrows -= vars.tokenDiff;
            return vars.tokenDiff;
        }
    }

    function settleOTMOption(address option, bool isCall) public nonReentrant returns (uint256) {
        Structs.settleVars memory vars;
        if(isSettled[option]) {
            return 0;
        } else {
            if(isCall) {
                vars.tokenBalBefore = token.balanceOf(address(this));            
                AoriCall(option).sellerSettlementOTM();
                isSettled[option] = true;
            } else {
                vars.tokenBalBefore = token.balanceOf(address(this));
                AoriPut(option).sellerSettlementOTM();
                isSettled[option] = true;
            }
            vars.tokenDiff = token.balanceOf(address(this)) - vars.tokenBalBefore;
            totalBorrows -= vars.tokenDiff;
            return vars.tokenDiff;
        }
    }

    function closeHedgedPosition(address option, bool isCall, uint256 optionsToSettle) public {
        require(msg.sender == address(manager));
        if(isCall) {
            AoriCall(option).liquidationSettlement(optionsToSettle);
        } else {
            AoriPut(option).liquidationSettlement(optionsToSettle);
        }
    }

    function repaid(uint256 assets) public returns (uint256) {
        require(msg.sender == address(manager));
        totalBorrows -= assets;
        return assets;    
    }
}