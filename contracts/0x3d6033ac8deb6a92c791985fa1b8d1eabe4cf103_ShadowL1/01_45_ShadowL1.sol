// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "arb-bridge-eth/contracts/bridge/Inbox.sol";
import "arb-bridge-eth/contracts/bridge/Outbox.sol";
import "./ERC721S.sol";
import "./IToken.sol";

contract ShadowL1 is ERC721S, Ownable{
    address public l2Target;
    IInbox public inbox;

    // ERC-721 NFT Contract deployed to root network (i.e. mainnet L1)
    IToken public rootContract;

    event RetryableTicketCreated(uint256 indexed ticketId);

    constructor(
        string memory _name, 
        string memory _symbol,
        // address _l2Target,
        address _inbox
    ) public ERC721S(_name, _symbol) {
        // l2Target = _l2Target;
        inbox = IInbox(_inbox);
    }

    function updateL2Target(address _l2Target) public onlyOwner {
        l2Target = _l2Target;
    }

    function updateInbox(IInbox _inbox) public onlyOwner {
        inbox = _inbox;
    }

    function setShadowInL2(
        address shadowOwner, 
        uint256 tokenId,
        uint256 maxSubmissionCost,
        uint256 maxGas,
        uint256 gasPriceBid
    ) public payable returns (uint256) {

        address rootOwner = rootContract.ownerOf(tokenId);

        require(
            msg.sender == rootOwner,
            "Only current token owner can set Shadow."
        );

        bytes memory data = abi.encodeWithSelector(ERC721S.setShadow.selector, rootOwner, shadowOwner, tokenId);
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

    function setRootContract(IToken _rootContract) public onlyOwner
    {
        rootContract = _rootContract;
    }


    /// @notice set Shadow using setShadowInL2.
    function setShadow(address _rootOwner, address _shadowOwner, uint256 _tokenId) public override {
        require(
            false,
            "Set shadow using setShadowInL2"
        );
    }
}