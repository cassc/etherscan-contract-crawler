// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";

contract LucisTrade is Ownable {
    /*//////////////////////////////////////////////////////////////////////////
                                  Events
    //////////////////////////////////////////////////////////////////////////*/

    event SkullClaimed(uint256 indexed _ticketId, uint256 indexed _skullId, address indexed _claimer);

    event WinnersSet(
        uint256[] _winningTicketIds,
        string[] _ticketIdComments,
        uint256[] _skullIdsForWinners
    );

    /*//////////////////////////////////////////////////////////////////////////
                                  Structs
    //////////////////////////////////////////////////////////////////////////*/
    struct Ticket {
        string comment;
        uint256 skullId;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  State Variables
    //////////////////////////////////////////////////////////////////////////*/

    uint256 private _semaphore;

    address public skullHolder;
    IERC721 public skullNFTAddress;
    IERC721 public ticketAddress;

    mapping(uint256 => Ticket) public winners;

    bool public winnersSelected;

    /*//////////////////////////////////////////////////////////////////////////
                                  Modifiers
    //////////////////////////////////////////////////////////////////////////*/

    modifier addressesSet() {
        require(skullHolder != address(0), "a0");
        require(address(skullNFTAddress) != address(0), "a1");
        require(address(ticketAddress) != address(0), "a2");
        _;
    }

    modifier guarded() {
        require(_semaphore == 0);
        _semaphore = 1;
        _;
        _semaphore = 0;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  Constructor
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        address _skullHolder, 
        address _skullNFTAddress, 
        address _ticketAddress
    ) {
        skullHolder = _skullHolder;
        skullNFTAddress = IERC721(_skullNFTAddress);
        ticketAddress = IERC721(_ticketAddress);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  Admin Functions
    //////////////////////////////////////////////////////////////////////////*/

    function setSkullHolder(address _skullHolder) external onlyOwner {
        skullHolder = _skullHolder;
    }

    function setSkullNFTAddress(address _skullNFTAddress) external onlyOwner {
        skullNFTAddress = IERC721(_skullNFTAddress);
    }

    function setTicketAddress(address _ticketAddress) external onlyOwner {
        ticketAddress = IERC721(_ticketAddress);
    }

    function setTicketWinnersAndSkulls(
        uint256[] calldata _winningTicketIds,
        string[] calldata _ticketIdComments,
        uint256[] calldata _skullIdsForWinners
    ) external onlyOwner {
        require(_winningTicketIds.length == 3);
        require(_ticketIdComments.length == 3);
        require(_skullIdsForWinners.length == 3);

        for (uint8 i = 0; i < 3; i++) {
            winners[_winningTicketIds[i]] = Ticket(
                _ticketIdComments[i],
                _skullIdsForWinners[i]
            );
        }
        winnersSelected = true;

        emit WinnersSet(
            _winningTicketIds,
            _ticketIdComments,
            _skullIdsForWinners
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                External Functions
    //////////////////////////////////////////////////////////////////////////*/

    function claimSkull(uint256[] calldata _ticketIds) external addressesSet guarded {
        require(winnersSelected, "c5");
        require(skullNFTAddress.isApprovedForAll(skullHolder, address(this)), "c0");
        require(ticketAddress.isApprovedForAll(msg.sender, address(this)), "c1");
        require(_ticketIds.length <= 3, "c2");

        for (uint8 i = 0; i < _ticketIds.length; i++) {
            Ticket memory ticket = winners[_ticketIds[i]];
            delete winners[_ticketIds[i]];
            require(ticketAddress.ownerOf(_ticketIds[i]) == msg.sender, "c3");
            require(bytes(ticket.comment).length != 0, "c4");
            skullNFTAddress.safeTransferFrom(skullHolder, msg.sender, ticket.skullId, bytes(ticket.comment));
            ticketAddress.safeTransferFrom(msg.sender, skullHolder, _ticketIds[i]);

            emit SkullClaimed(_ticketIds[i], ticket.skullId, msg.sender);
        }
    }
}