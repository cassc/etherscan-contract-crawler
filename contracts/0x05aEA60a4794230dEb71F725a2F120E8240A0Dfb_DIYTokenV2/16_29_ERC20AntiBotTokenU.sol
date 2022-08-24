// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC20BlacklistTokenU.sol";

contract ERC20AntiBotTokenU is ERC20BlacklistTokenU {
    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////

    bool public isAntiBotChecking;
    uint256 public antiBotStartedAt;
    uint256 public antiBotDeadBlocks;

    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    event NotifySniperBot(address _user);

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function __AntiBotToken_init() internal virtual initializer {
        __Blacklist_init();

        isAntiBotChecking = false;
        antiBotStartedAt = 0;
        antiBotDeadBlocks = 2;
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