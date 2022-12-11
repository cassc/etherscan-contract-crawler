// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./FlickDropNFT.sol";

contract GoldenTicketRedeemed is FlickDropNFT {
    address public goldenTicketAddress;

    constructor(
        string memory baseURI
    )
        FlickDropNFT(
            "Golden Hunny Ticket (Redeemed)",
            "GOLDENTICKET-REDEEMED",
            address(0xdead),
            0
        )
    {
        setBaseURI(baseURI);
    }

    function setGoldenTicketAddress(
        address _goldenTicketAddress
    ) external onlyOwner {
        goldenTicketAddress = _goldenTicketAddress;
    }

    modifier onlyGoldenTicket() {
        require(
            msg.sender == goldenTicketAddress,
            "GoldenTicket: Only GoldenTicket can call this function."
        );
        _;
    }

    function mint(address to) external onlyGoldenTicket {
        _mint(to, 1);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 /* tokenId */,
        uint256 /* quantity */
    ) internal pure override {
        require(
            from == address(0) || to == address(0),
            "GoldenTicket: Soul-bound"
        );
    }
}