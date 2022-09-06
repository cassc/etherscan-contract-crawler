// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/SafeERC20.sol";

contract MultiMigration is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 accuracyFactor = 10**18;
    uint256 divisor = 10**18;

    address public constant oldPYE = 0x5B232991854c790b29d3F7a145a7EFD660c9896c;
    address public constant oldFORCE = 0x82ce8A98Bf1c5daBe24620220dd4bc5da0ba291d;
    address public constant oldAPPLE = 0x6f43a672D8024ba624651a5c2e63D129783dAd1F;
    address public constant oldCHERRY = 0xD2858A1f93316242E81CF69B762361F59Fb9b18E;

    uint256 public pyeRate = 125;
    uint256 public forceRate = 200;

    address public newPYE = 0x59f4cdBF88cBd8e3D34B00828d0b43d406F79B4e;
    address public newAPPLE = 0x717f8316e497456662ebAeE099Ac6bdAA1E62482;
    address public newCHERRY = 0x621d1C61843c43cA8D84E6480338df1DB3e068A7;

    address deadWallet = 0x000000000000000000000000000000000000dEaD;

    event NewTokenTransfered(address indexed operator, IERC20 newToken, uint256 sendAmount);

    // update migrate info    
    function setConversionRates(uint256 _pyeRate, uint256 _forceRate) external onlyOwner{    
        pyeRate = _pyeRate;
        forceRate = _forceRate;
    }

    function setNewTokens(address _newPYE, address _newAPPLE, address _newCHERRY) external onlyOwner{
        newPYE = _newPYE;
        newAPPLE = _newAPPLE;
        newCHERRY = _newCHERRY;
    }

    function handlePYE(address account) internal {
        uint256 newPYEAmount = 0;

        uint256 oldPYEAmount = IERC20(oldPYE).balanceOf(account);
        uint256 oldFORCEAmount = IERC20(oldFORCE).balanceOf(account);

        if(oldPYEAmount > 0) {
            newPYEAmount += oldPYEAmount.mul(accuracyFactor).div(pyeRate).div(divisor);
            IERC20(oldPYE).safeTransferFrom(account, deadWallet, oldPYEAmount);
        }
        if(oldFORCEAmount > 0) {
            newPYEAmount += oldFORCEAmount.mul(accuracyFactor).div(forceRate).div(divisor);
            IERC20(oldFORCE).safeTransferFrom(account, deadWallet, oldFORCEAmount);
        }

        if(newPYEAmount > 0) {
            IERC20(newPYE).safeTransfer(account, newPYEAmount);
            emit NewTokenTransfered(account, IERC20(newPYE), newPYEAmount); 
        }
    }

    function handleAPPLE(address account) internal {
        uint256 oldAPPLEAmount = IERC20(oldAPPLE).balanceOf(account);

        if(oldAPPLEAmount > 0) {
            IERC20(oldAPPLE).safeTransferFrom(account, deadWallet, oldAPPLEAmount);
            IERC20(newAPPLE).mint(account, oldAPPLEAmount);
            emit NewTokenTransfered(account, IERC20(newAPPLE), oldAPPLEAmount);  
        }
    }

    function handleCHERRY(address account) internal {
        uint256 oldCHERRYAmount = IERC20(oldCHERRY).balanceOf(account);

        if(oldCHERRYAmount > 0) {
            IERC20(oldCHERRY).safeTransferFrom(account, deadWallet, oldCHERRYAmount);
            IERC20(newCHERRY).mint(account, oldCHERRYAmount);
            emit NewTokenTransfered(account, IERC20(newCHERRY), oldCHERRYAmount); 
        }
    }

    // Migration
    function migration() external nonReentrant {
        require(msg.sender != deadWallet, "Not allowed to dead wallet");
        handlePYE(msg.sender);
        handleAPPLE(msg.sender);
        handleCHERRY(msg.sender);
    }

    // Withdraw rest or wrong tokens that are sent here by mistake
    function drainBEP20Token(IERC20 token, uint256 amount, address to) external onlyOwner {
        if( token.balanceOf(address(this)) < amount ) {
            amount = token.balanceOf(address(this));
        }
        token.safeTransfer(to, amount);
    }
}