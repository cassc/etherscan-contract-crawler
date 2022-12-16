// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IERC20.sol";

contract TokenMerger is Ownable, ReentrancyGuard {

    uint256 divisor = 10**15;

    address public constant oldAPPLE = 0x717f8316e497456662ebAeE099Ac6bdAA1E62482;

    uint256 public appleRate = 104632;

    address public newPYE = 0x59f4cdBF88cBd8e3D34B00828d0b43d406F79B4e;

    address deadWallet = 0x000000000000000000000000000000000000dEaD;

    event NewTokenTransfered(address indexed operator, IERC20 newToken, uint256 sendAmount);

    // update migrate info    
    function setConversionRates(uint256 _appleRate) external onlyOwner{    
        appleRate = _appleRate;
    }

    function setNewTokens(address _newPYE) external onlyOwner{
        newPYE = _newPYE;
    }

    function handlePYE(address account) internal {
        uint256 newPYEAmount = 0;

        uint256 oldAPPLEAmount = IERC20(oldAPPLE).balanceOf(account);

        if(oldAPPLEAmount > 0) {
            newPYEAmount += oldAPPLEAmount * appleRate / divisor;
            IERC20(oldAPPLE).burnFrom(account, oldAPPLEAmount);
        }

        if(newPYEAmount > 0) {
            IERC20(newPYE).transfer(account, newPYEAmount);
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
        token.transfer(to, amount);
    }

    function getAmounts(address account) external view returns(
        uint256 appleBalance, 
        uint256 pyeFromApple, 
        uint256 pyeOwed
    ) {
        appleBalance = IERC20(oldAPPLE).balanceOf(account);
        pyeFromApple = appleBalance * appleRate / divisor;
        pyeOwed = pyeFromApple;
    }
}