// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {ERC1155} from "solmate/tokens/ERC1155.sol";

enum Sock {
    Left,
    Right
}

/// When the duration of the mint has finished.
error MintFinished();

/// @title Solidity 🧦 from Devcon Bogota.
contract Socks is ERC1155 {
    /// The name of the contract
    string public constant name = unicode"🧦.sol";

    /// Timestamp when the mint ends
    uint256 public immutable endTime = block.timestamp + 4 weeks;

    function uri(uint256 id) public pure override returns (string memory) {
        return Sock(id) == Sock.Left
            ? "ipfs://QmbxXn6GQcP2KbKbu3Sd5UFqS1uzXkEXdhXC5myc5MY2wu"
            : "ipfs://QmSnSkRmaQmAC5Dtc8qmEuvZNiznHKLrkX8kM8iCQhYYHV";
    }

    /// Mints a psuedo-random 🧦.sol
    function mint() external {
        if (block.timestamp > endTime) revert MintFinished();

        Sock sock = Sock(block.difficulty % 2);
        _mint({to: msg.sender, id: uint256(sock), amount: 1, data: ""});
    }
}