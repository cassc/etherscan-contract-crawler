// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface BeastContract {
    function safeMint(address to) external returns (uint256);
}

contract TicketsRedeemL2 is Ownable {
    address public l1Target;
    BeastContract public originBeasts;
    BeastContract public beasts;


    enum BeastCollection {
        OriginBeast,
        StarterBeast
    }

    event BeastRedeemed(uint indexed tokenId, BeastCollection indexed collection, bool fromGoldenTicket);
    event TicketsRedeemed(address indexed from, uint[] ids, uint[] amounts);

    constructor(address _l1Target, address _originBeasts, address _beasts) {
        l1Target = _l1Target;
        originBeasts = BeastContract(_originBeasts);
        beasts = BeastContract(_beasts);
    }

    function updateL1Target(address _l1Target) external onlyOwner {
        l1Target = _l1Target;
    }

    function _random() internal view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        msg.sender,
                        gasleft()
                    )
                )
            ) % 100;
    }

    function redeemTickets(
        address from,
        uint[] calldata ids,
        uint[] calldata amounts
    ) public {
        require(
            msg.sender == AddressAliasHelper.applyL1ToL2Alias(l1Target),
            "Can only be called by L1 contract"
        );

        for (uint i = 0; i < ids.length; i++) {
            uint256 tokenId = ids[i];
            uint256 amount = amounts[i];
            if (tokenId == 1) {
                uint originId = originBeasts.safeMint(from);
                uint starterId = beasts.safeMint(from);
                emit BeastRedeemed(originId, BeastCollection.OriginBeast, true);
                emit BeastRedeemed(starterId, BeastCollection.StarterBeast, true);
            } else if (tokenId == 2) {
                uint originId = originBeasts.safeMint(from);
                emit BeastRedeemed(originId, BeastCollection.OriginBeast, false);


                if (_random() < 10) {
                    uint starterId = beasts.safeMint(from);
                    emit BeastRedeemed(starterId, BeastCollection.StarterBeast, false);
                }
            }
        }

        emit TicketsRedeemed(from, ids, amounts);
    }
}