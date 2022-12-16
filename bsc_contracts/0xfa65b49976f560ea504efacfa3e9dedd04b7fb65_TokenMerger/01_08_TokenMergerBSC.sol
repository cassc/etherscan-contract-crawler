// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/SafeERC20.sol";

contract TokenMerger is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 divisor = 10**15;

    address public constant oldAPPLE = 0xF65Ae63D580EDe49589992b6E772b48E61EaDed2;
    address public constant oldPEACH = 0xdB3aBa37F0F0C0e8233FFB862FbaD2F725cdE989;

    uint256 public appleRate = 17547;
    uint256 public peachRate = 30543291;

    address public newPYE = 0xb4B486496469B3269c8907543706C377daAA4dD9;

    address deadWallet = 0x000000000000000000000000000000000000dEaD;

    event NewTokenTransfered(address indexed operator, IERC20 newToken, uint256 sendAmount);

    // update migrate info    
    function setConversionRates(uint256 _appleRate, uint256 _peachRate) external onlyOwner{    
        appleRate = _appleRate;
        peachRate = _peachRate;
    }

    function setNewTokens(address _newPYE) external onlyOwner{
        newPYE = _newPYE;
    }

    function handlePYE(address account) internal {
        uint256 newPYEAmount = 0;

        uint256 oldAPPLEAmount = IERC20(oldAPPLE).balanceOf(account);
        uint256 oldPEACHAmount = IERC20(oldPEACH).balanceOf(account);

        if(oldAPPLEAmount > 0) {
            newPYEAmount += oldAPPLEAmount * appleRate / divisor;
            IERC20(oldAPPLE).safeTransferFrom(account, deadWallet, oldAPPLEAmount);
        }
        if(oldPEACHAmount > 0) {
            newPYEAmount += oldPEACHAmount * peachRate / divisor;
            IERC20(oldPEACH).safeTransferFrom(account, deadWallet, oldPEACHAmount);
        }

        if(newPYEAmount > 0) {
            IERC20(newPYE).safeTransfer(account, newPYEAmount);
            emit NewTokenTransfered(account, IERC20(newPYE), newPYEAmount); 
        }
    }

    // Merging
    function mergeTokens() external nonReentrant {
        require(msg.sender != deadWallet, "Not allowed to dead wallet");
        handlePYE(msg.sender);
    }

    // Withdraw rest or wrong tokens that are sent here by mistake
    function drainERC20Token(IERC20 token, uint256 amount, address to) external onlyOwner {
        if( token.balanceOf(address(this)) < amount ) {
            amount = token.balanceOf(address(this));
        }
        token.safeTransfer(to, amount);
    }

    function getAmounts(address account) external view returns(
        uint256 appleBalance, 
        uint256 peachBalance, 
        uint256 pyeFromApple, 
        uint256 pyeFromPeach, 
        uint256 pyeOwed
    ) {
        appleBalance = IERC20(oldAPPLE).balanceOf(account);
        peachBalance = IERC20(oldPEACH).balanceOf(account);
        pyeFromApple = appleBalance * appleRate / divisor;
        pyeFromPeach = peachBalance * peachRate / divisor;
        pyeOwed = pyeFromApple + pyeFromPeach;
    }
}