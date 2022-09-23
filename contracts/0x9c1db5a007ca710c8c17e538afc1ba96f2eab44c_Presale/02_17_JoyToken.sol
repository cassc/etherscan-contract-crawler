// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./extensions/SecureToken.sol";

error DISABLED();
error ALLOWED_WHITELISTED_FROM();
error ALLOWED_WHITELISTED_TO(); 
error SWAP_IS_COOLING_DOWN();

contract JoyToken is SecureToken {

    enum TransferMode {
        DISABLED,
        ALLOWED_ALL,
        ALLOWED_WHITELISTED_FROM,
        ALLOWED_WHITELISTED_TO,
        ALLOWED_WHITELISTED_FROM_TO
    }

    TransferMode public transferMode;
    
    mapping (address => uint256) private swapBlock;

    bool public swapGuarded;

    /**
      * Joy Token constructor
      * @param _whitelist - Initial list of whitelisted receivers
      * @param _blacklist - Initial list of blacklisted addresses
      * @param _admins - Initial list of all administrators of the token
      */
    constructor(
        address[] memory _whitelist, 
        address[] memory _blacklist, 
        address[] memory _admins
    )
        SecureToken(_whitelist, _blacklist, _admins, "Joystick", "JOY") 
    {
            transferMode = TransferMode.ALLOWED_ALL;
    }

    /**
      * Setting new transfer mode for the token
      * @param _mode - New transfer mode to be set
      */
    function setTransferMode(TransferMode _mode) public onlyAdmin {
        transferMode = _mode;
    }

    /**
      * Checking transfer status
      * @param from - Transfer sender
      * @param to - Transfer recipient
      */
    function _checkTransferStatus(address from, address to) private view {
        if(transferMode == TransferMode.DISABLED) revert DISABLED();
        
        if(transferMode == TransferMode.ALLOWED_WHITELISTED_FROM_TO) {
            if(blacklisted[from] || !whitelisted[from]) revert ALLOWED_WHITELISTED_FROM(); 
            if(blacklisted[to] || !whitelisted[to]) revert ALLOWED_WHITELISTED_TO();
            return;
        }

        if(transferMode == TransferMode.ALLOWED_WHITELISTED_FROM) {
            if(blacklisted[from] || !whitelisted[from]) revert ALLOWED_WHITELISTED_FROM(); 
            return;
        }

        if (transferMode == TransferMode.ALLOWED_WHITELISTED_TO) {
            if(blacklisted[to] || !whitelisted[to]) revert ALLOWED_WHITELISTED_TO();
            return;
        }
    }

    /**
      * Prevent MEV Bots from doing Sandwich Attacks and Arbitrage
      * Enforces a single JOY Transfer per transaction
      * @param _swapGuardStatus - True or false
      */
    function setProtectedSwaps(bool _swapGuardStatus) external onlyOwner {
        swapGuarded = _swapGuardStatus;
    }

    /**
      * Enforces atleast 1 block gap for swaps and transfers
      * This prevents MEV Bots (Maximal Extractable Value)
      * @param from - Address of sender
      * @param to - Address of recipient
      */
    function _checkSwapCooldown(address from, address to) private {
        if(swapGuarded) {
            if(swapBlock[from] == block.number) revert SWAP_IS_COOLING_DOWN();
            swapBlock[to] = block.number;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256) override internal virtual {
        _checkTransferStatus(from, to);
        _checkSwapCooldown(from, to);
    }
}