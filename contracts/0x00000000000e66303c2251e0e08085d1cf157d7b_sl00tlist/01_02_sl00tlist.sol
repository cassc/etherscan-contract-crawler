// SPDX-License-Identifier: UNLICENSED


//╱╱╱╭╮╭━━━┳━━━┳╮╱╱╱╱╭╮╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╭╮╭━┳╮
//╱╱╱┃┃┃╭━╮┃╭━╮┃┃╱╱╱╭╯╰╮╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱┃┃┃╭┫┃
//╭━━┫┃┃┃┃┃┃┃┃┃┃┃╭┳━┻╮╭╯╭╮╱╭┳━━┳╮╭┳━┳━━┳━━┫┣╯╰┫┃
//┃━━┫┃┃┃┃┃┃┃┃┃┃┃┣┫━━┫┃╱┃┃╱┃┃╭╮┃┃┃┃╭┫━━┫┃━┫┣╮╭┻╯
//┣━━┃╰┫╰━╯┃╰━╯┃╰┫┣━━┃╰╮┃╰━╯┃╰╯┃╰╯┃┃┣━━┃┃━┫╰┫┃╭╮
//╰━━┻━┻━━━┻━━━┻━┻┻━━┻━╯╰━╮╭┻━━┻━━┻╯╰━━┻━━┻━┻╯╰╯
//╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╭━╯┃
//╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╱╰━━╯

pragma solidity ^0.8.15;

import "solmate/auth/Owned.sol";

contract sl00tlist is Owned {
    constructor()Owned(msg.sender){}

    mapping(address => bool) public sl00tlistStatus;
    bool public sl00tlistingEnabled = true;
    uint public balanceThreshold = 5e16;

    receive() external payable {
        sl00tlistYourself();
    }

    function sl00tlistYourself() public {
        require(msg.sender == tx.origin, "No contracts allowed");
        require(sl00tlistingEnabled, "Sl00tlisting is disabled");
        require(msg.sender.balance >= balanceThreshold, "Insufficient balance");
        sl00tlistStatus[msg.sender] = true;
    }

    function flipSl00tlisting() external onlyOwner {
        sl00tlistingEnabled = !sl00tlistingEnabled;
    }

    function updateThreshold(uint newThreshold) external onlyOwner {
        balanceThreshold = newThreshold;
    }

    function withdraw() external onlyOwner {
        assembly {
            let result := call(0, caller(), selfbalance(), 0, 0, 0, 0)
            switch result
            case 0 { revert(0, 0) }
            default { return(0, 0) }
        }
    }

}