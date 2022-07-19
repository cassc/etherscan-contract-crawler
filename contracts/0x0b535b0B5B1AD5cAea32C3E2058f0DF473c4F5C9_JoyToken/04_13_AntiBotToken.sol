// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./BlackListToken.sol";

contract AntiBotToken is BlackListToken {
    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////    

    bool public isAntiBotChecking;
    uint256 public antiBotStartedAt;
    uint256 public antiBotDeadBlocks;
    bool public isDexPoolCreating;
    
    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    event NotifySniperBot(address _user);

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function __AntiBotToken_init() internal virtual initializer {
        __BlackList_init();

        isAntiBotChecking = false;
        antiBotStartedAt = 0;
        antiBotDeadBlocks = 30;
        isDexPoolCreating = false;
    }
    
    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////

    function startAntiBot(bool _status,uint256 _deadBlocks) public onlyAuthorized {
        isAntiBotChecking = _status;
        if(isAntiBotChecking){
            antiBotStartedAt = block.number;
            antiBotDeadBlocks = _deadBlocks;
        }
    }

    function startDexPoolCreating(bool _status) public onlyAuthorized {
        isDexPoolCreating = _status;
    }    
   
    ////////////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////////////

    function checkSniperBot(address account) internal {
        if (isAntiBotChecking) {
            //antibot - first 2 blocks
            if(antiBotStartedAt > 0 && (antiBotStartedAt + antiBotDeadBlocks) > block.number) {
                addBlackList(account);
                emit NotifySniperBot(account);
            }
        }
    }

    function _transfer(address _from, address _to, uint256 _amount) internal virtual override {
        checkSniperBot(_to);
        super._transfer(_from, _to, _amount);
    }

}