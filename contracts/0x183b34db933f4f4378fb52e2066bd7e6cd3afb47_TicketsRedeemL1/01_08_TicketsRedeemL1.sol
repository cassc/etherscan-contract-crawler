// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "arb-bridge-eth/contracts/bridge/interfaces/IInbox.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TicketsRedeemL2.sol";

interface IERC1155Burnable {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}

contract TicketsRedeemL1 is Ownable {
    IERC1155Burnable public ferryTickets;
    IERC1155Burnable public goldenBadges;
    IInbox public inbox;
    address public l2Target;

    event TicketsRedeemInitiated(
        uint indexed ticket,
        address indexed wallet,
        uint[] ids,
        uint[] amounts
    );

    constructor(address _ferryTickets, address _goldenBadges, address _inbox) {
        ferryTickets = IERC1155Burnable(_ferryTickets);
        goldenBadges = IERC1155Burnable(_goldenBadges);
        inbox = IInbox(_inbox);
    }

    function updateL2Target(address _l2Target) external onlyOwner {
        l2Target = _l2Target;
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
        uint[] calldata ids,
        uint[] calldata amounts,
        uint maxSubmissionCost,
        uint maxGas,
        uint gasPriceBid
    ) public payable returns (uint) {
        ferryTickets.burnBatch(msg.sender, ids, amounts);

        // Sending tickets to L2
        bytes memory data = abi.encodeWithSelector(
            TicketsRedeemL2.redeemTickets.selector,
            msg.sender,
            ids,
            amounts
        );
        uint ticket = inbox.createRetryableTicket{value: msg.value}(
            l2Target,
            0,
            maxSubmissionCost,
            msg.sender,
            msg.sender,
            maxGas,
            gasPriceBid,
            data
        );

        // Minting Golden badges
        uint badges = 0;
        for (uint i = 0; i < ids.length; i++) {
            if (ids[i] == 1) {
                badges += amounts[i];
            } else if (ids[i] == 2) {
                for (uint j = 0; j < amounts[i]; j++) {
                    if (_random() < 10) {
                        badges += 1;
                    }
                }
            }
        }

        if (badges > 0) {
            goldenBadges.mint(msg.sender, 1, badges, "");
        }

        emit TicketsRedeemInitiated(ticket, msg.sender, ids, amounts);
        return ticket;
    }
}