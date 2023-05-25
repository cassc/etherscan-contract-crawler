// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ContextMess.sol"; 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract MESS is ContextMess, ERC20 ,Pausable{

    struct TransferParam {
        address to;
        uint256 amount;
    }

    constructor(address config_) ERC20("MESS", "MESS") {
        _checkConfig(IConfig(config_));
    } 

    // =============================================================
    // about mint burn and transfer
    // relate with "@openzeppelin/contracts/security/Pausable.sol";
    // =============================================================

    // mint token to treasury wallet，only minter can do this.
    function mint(uint256 amount) public isMinter {
        address to = _TreasuryWalletContract();
        super._mint(to, amount);
    }

    //burn token , only burner can do this.
    function burn(uint256 amount) public isBurner {
        _burn(_msgSender(), amount);
    }

    //batch transfer token to other address
    function batchTransfer(TransferParam[] memory transfers) public isTransferer {
        for (uint256 i = 0; i < transfers.length; i++) {
            super._transfer(_TreasuryWalletContract(), transfers[i].to, transfers[i].amount);
        }
    }

    //deny transfer when paused or address in the blacklist
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused isNotInTheBlacklist(from) isNotInTheBlacklist(to) {
        super._beforeTokenTransfer(from, to, amount);
    }

    // =============================================================
    // about pause and unpause
    // relate with "@openzeppelin/contracts/security/Pausable.sol";
    // =============================================================

    //pause transfer function，only pauser can do this.
    function pause() public isPauser {
        _pause();
    }

    //unpause transfer function
    function unpause() public isPauser {
        _unpause();
    }
}