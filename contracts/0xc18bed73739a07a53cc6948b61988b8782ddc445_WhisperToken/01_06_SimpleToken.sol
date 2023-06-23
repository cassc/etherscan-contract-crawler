// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Stealth Launch on 22nd June, 7pm UTC
// Whisper introduces an innovative Ethereum zero-knowledge privacy protocol: a smart contract enabling seamless transaction acceptance in Ether and ERC-20 tokens while ensuring complete withdrawal anonymity, erasing any traceability to the initial transaction.
// Whisper contracts are governed by $WISP, a decentralized stealth-launched DAO.

// Github: https://github.com/whispertome/whisper-protocol
// Website: https://www.whisperdao.com/

contract WhisperToken is ERC20, Ownable {
    constructor() ERC20("Whisper DAO", "WISPDAO") {
        _mint(msg.sender, 111_111_111 * 1e18);
    }
}