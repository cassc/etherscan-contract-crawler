// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract JumpStartTicket is ERC721AQueryable {
    uint256 public mintLimit;
    address public jumpStartNFT;
    string private baseUri;
    mapping(uint256 => bool) public ticketRedeemed;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _mintLimit,
        address _jumpStartNFT
    ) ERC721A(_name, _symbol) {
        baseUri = _uri;
        mintLimit = _mintLimit;
        jumpStartNFT = _jumpStartNFT;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function mintTicket(address ticketMinter, uint256 quantity) public {
        require(
            msg.sender == jumpStartNFT,
            "Only JumpStart NFT can mint tickets"
        );
        _safeMint(ticketMinter, quantity);
    }

    function redeemTicket(uint256 ticketId) public {
        require(
            msg.sender == ownerOf(ticketId),
            "Only ticket owner can redeem ticket"
        );
        require(
            ticketRedeemed[ticketId] == false,
            "Ticket has already been redeemed"
        );
        ticketRedeemed[ticketId] = true;
    }

    function checkRedemption(uint256 _ticketId) public view returns (bool) {
        return ticketRedeemed[_ticketId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI)) : "";
    }
}