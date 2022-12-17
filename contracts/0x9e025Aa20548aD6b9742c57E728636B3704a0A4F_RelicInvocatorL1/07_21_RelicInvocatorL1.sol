pragma solidity ^0.8.13;

import "../src/bridge/Inbox.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RelicInvocatorL2 {
    mapping (address => bool) public allowlist;

    function allow(address _toAllow) public virtual {
        allowlist[_toAllow]=true;
    }
}

contract RelicInvocatorL1 is Ownable {
    address public l2Target;
    IInbox public inbox;

    event RetryableTicketCreated(uint256 indexed ticketId);

     function beginJourney(
        string memory _traveller,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid
    ) public payable returns (uint256) {
        bytes memory data = abi.encodeWithSelector(RelicInvocatorL2.allow.selector, _traveller);
        uint256 ticketID = inbox.createRetryableTicket{ value: msg.value }(
            l2Target,
            0,
            maxSubmissionCost,
            msg.sender,
            msg.sender,
            maxGas,
            gasPriceBid,
            data
        );

        emit RetryableTicketCreated(ticketID);
        return ticketID;
    }

    function setAddresses(address _l2target, address _inbox) external onlyOwner{
        l2Target=_l2target;
        inbox = IInbox(_inbox);
    }
}