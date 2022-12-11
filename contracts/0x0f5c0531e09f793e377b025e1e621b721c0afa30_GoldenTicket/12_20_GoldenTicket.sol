// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./GoldenTicketRedeemed.sol";
import "./FlickDropNFT.sol";

contract GoldenTicket is FlickDropNFT, AccessControl {
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    GoldenTicketRedeemed public goldenTicketRedeemer;

    event Redeemed(address indexed to, uint256 indexed tokenId, bytes data);
    event Redeemed2(address indexed to, uint256 indexed tokenId, bytes data);

    constructor(
        address feeReceiver,
        uint96 feeBasisPoints,
        string memory baseURI
    )
        FlickDropNFT(
            "Golden Hunny Ticket",
            "GOLDENTICKET",
            feeReceiver,
            feeBasisPoints
        )
    {
        setBaseURI(baseURI);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MINT_ROLE, msg.sender);
    }

    function setGoldenTicketRedeemerAddress(
        address payable _goldenTicketRedeemerAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        goldenTicketRedeemer = GoldenTicketRedeemed(
            _goldenTicketRedeemerAddress
        );
    }

    function mint(address to) external onlyRole(MINT_ROLE) {
        _mint(to, 1);
    }

    /**
     * @dev Redeems a Golden Ticket for a Redeemed Golden Ticket
     * @param tokenId The tokenId of the Golden Ticket to redeem
     * @param data Any data to pass to the redeemed Golden Ticket
     * I thought long and hard and can see no reason why this needs any reentrancy protection
     */
    function redeem(uint256 tokenId, bytes memory data) external {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _burn(tokenId);
        goldenTicketRedeemer.mint(owner);
        emit Redeemed(owner, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view override(AccessControl, FlickDropNFT) returns (bool) {
        return super.supportsInterface(interfaceID);
    }
}