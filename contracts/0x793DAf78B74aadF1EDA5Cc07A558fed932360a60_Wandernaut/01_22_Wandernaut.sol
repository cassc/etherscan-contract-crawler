// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721MultiMetadata.sol";

contract Wandernaut is
    ERC721,
    ERC721Enumerable,
    ERC721Royalty,
    Ownable,
    ERC721MultiMetadata,
    Pausable,
    ReentrancyGuard
{
    /// A "block" of tokens that can be individually controlled.
    /// Note: You will explode if Groups have overlapping ranges!
    struct Group {
        /// Price for pre-sale (in ether)
        uint256 presalePrice;
        /// Price for public (in ether)
        uint256 publicPrice;
        /// Beginning token ID. The first token minted in this group will have this ID.
        uint256 counter;
        /// End token ID. The last token minted in this group will have this ID.
        uint256 end;
        /// Merkle root for sub-tickets.
        bytes32 root;
        /// State of the group
        GroupState groupState;
    }

    /// State of the group.
    /// Closed: only available for admins to mint.
    /// MerklePresale: allows addresses in merkle tree to purchase.
    /// Public: anyone can purchase.
    enum GroupState {
        Closed,
        MerklePresale,
        Public
    }

    /// Mapping of 32-byte identifiers to groups.
    mapping(bytes32 => Group) public groups;

    /// A ticket for a pre-sale mint. Each ticket is good for ONE mint only.
    struct Ticket {
        /// A unique number to identify the ticket.
        uint256 ticketId;
        /// Merkle proof the ticket exists.
        bytes32[] proof;
    }

    /// Event when a ticket has been consumed
    /// @param consumer the address which used the ticket
    /// @param ticketId the ID of the ticket
    event ConsumeTicket(address consumer, uint256 ticketId);

    /// Mapping of ticket IDs to whether they have been used.
    mapping(uint256 => bool) public ticketUsed;

    /// Address to send payment to
    address payable public payoutAddress;

    constructor(
        string memory zeroURI,
        address payable _payoutAddress,
        uint96 feeNumerator
    ) ERC721("Wandernaut", "WANDERNAUT") ERC721MultiMetadata(zeroURI) {
        payoutAddress = _payoutAddress;
        _setDefaultRoyalty(msg.sender, feeNumerator);
        _pause();
    }

    /// Unpause the contract.
    function pause() public onlyOwner {
        _pause();
    }

    /// Pause the contract.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// Set the payout address.
    /// @param _payoutAddress the new payout address
    function setPayoutAddress(address payable _payoutAddress)
        external
        onlyOwner
    {
        payoutAddress = _payoutAddress;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// Claim the balance of the contract.
    function claimBalance() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payoutAddress.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    /// Set up a group.
    /// @param groupIdentifier unique 32-byte identifier for the group
    /// @param group data for the group
    function setGroup(bytes32 groupIdentifier, Group calldata group)
        external
        onlyOwner
    {
        groups[groupIdentifier] = group;
    }

    /// Set the group state.
    /// @param groupIdentifier unique 32-byte identifier for the group
    /// @param groupState new group state
    function setGroupState(bytes32 groupIdentifier, GroupState groupState)
        external
        onlyOwner
    {
        groups[groupIdentifier].groupState = groupState;
    }

    /// Admin mint a token.
    /// @param to the address to send the token to
    /// @param tokenId the token ID to mint.
    function adminMint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    /// Pre-sale mint a token.
    /// @param to address to send tokens to
    /// @param groupIdentifier 32-byte identifier for which group to mint in
    /// @param tickets array of tickets to use
    function presaleMint(
        address to,
        bytes32 groupIdentifier,
        Ticket[] calldata tickets
    ) external payable whenNotPaused nonReentrant {
        Group storage group = groups[groupIdentifier];
        // Ensure the group is in pre-sale
        require(
            group.groupState == GroupState.MerklePresale,
            "Incorrect group state"
        );

        // Ensure enough funds were sent
        require(
            msg.value >= tickets.length * group.presalePrice,
            "Insufficient funds sent"
        );

        // Ensure tokens will not overflow
        require(
            group.counter + tickets.length <= group.end + 1,
            "Exceeds no. in group"
        );

        // Ensure all tickets are not used
        for (uint256 i = 0; i < tickets.length; i++) {
            require(!ticketUsed[tickets[i].ticketId], "Ticket already used");
        }

        // Set all tickets to be used
        for (uint256 i = 0; i < tickets.length; i++) {
            _markTicket(tickets[i]);
            emit ConsumeTicket(to, tickets[i].ticketId);
        }

        // Increment the counter ONCE, instead of doing it in _mintTicket()
        uint256 id = group.counter;
        bytes32 root = group.root;

        group.counter += tickets.length;

        // Mint using each ticket
        for (uint256 i = 0; i < tickets.length; i++) {
            _mintTicket(to, root, id, tickets[i]);
            id++;
        }
        assert(group.counter == id);
    }

    /// Mark a ticket as used
    /// @param ticket the ticket to mark
    function _markTicket(Ticket calldata ticket) internal {
        ticketUsed[ticket.ticketId] = true;
    }

    /// Mint a token using a ticket.
    /// @param to address to send tokens to
    /// @param root 32-byte root to check against
    /// @param id the token id to mint
    /// @param ticket the ticket to use
    function _mintTicket(
        address to,
        bytes32 root,
        uint256 id,
        Ticket calldata ticket
    ) internal {
        bytes32 leaf = _leaf(ticket.ticketId, to);
        require(_verify(root, leaf, ticket.proof), "Invalid merkle proof");
        _safeMint(to, id);
    }

    /// Reconstruct leaf hash of a mint.
    function _leaf(uint256 ticketId, address account)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(ticketId, account));
    }

    /// Verify a merkle proof.
    function _verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] calldata proof
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    /// Public mint a token.
    /// @param to address to send tokens to
    /// @param groupIdentifier 32-byte identifier for which group to mint in
    /// @param amount number of tokens to mint
    function publicMint(
        address to,
        bytes32 groupIdentifier,
        uint256 amount
    ) external payable whenNotPaused nonReentrant {
        Group storage group = groups[groupIdentifier];

        // Ensure the group is in public
        require(group.groupState == GroupState.Public, "Incorrect group state");

        // Ensure enough funds were sent
        uint256 totalCost = amount * group.publicPrice;
        require(msg.value >= totalCost, "Insufficient funds sent");

        // Ensure tokens will not overflow
        require(
            group.counter + amount <= group.end + 1,
            "Exceeds no. in group"
        );

        uint256 id = group.counter;
        group.counter += amount;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, id);
            id++;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721MultiMetadata)
        returns (string memory)
    {
        return ERC721MultiMetadata.tokenURI(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721Royalty)
    {
        super._burn(tokenId);
    }
}