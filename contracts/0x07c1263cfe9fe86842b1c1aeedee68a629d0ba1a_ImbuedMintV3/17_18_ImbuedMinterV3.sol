// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";
import "./deployed/IImbuedNFT.sol";
import "./ImbuedData.sol";

contract ImbuedMintV3 is Ownable {
    IImbuedNFT constant public NFT = IImbuedNFT(0x000001E1b2b5f9825f4d50bD4906aff2F298af4e);
    IERC721 immutable public metaverseMiamiTicket;

    mapping (uint256 => bool) public miamiTicketId2claimed; // token ids that are claimed.

    enum Edition { LIFE, LONGING, FRIENDSHIP, FRIENDSHIP_MIAMI }
    // Order relevant variables per edition so that they are packed together,
    // reduced sload and sstore gas costs.
    struct MintInfo {
        uint16 nextId;
        uint16 maxId;
        bool openMint;
        uint216 price;
    }

    MintInfo[4] public mintInfos;

    constructor(address metaverseMiamiAddress) {
        metaverseMiamiTicket = IERC721(metaverseMiamiAddress);
        mintInfos[uint(Edition.LIFE      )] = MintInfo(201, 299, true, 0.25 ether);
        mintInfos[uint(Edition.LONGING   )] = MintInfo(301, 399, true, 0.25 ether);
        mintInfos[uint(Edition.FRIENDSHIP_MIAMI)] = MintInfo(401, 460, false, 0 ether);
        // Friendship edition is 461-499, first 60 reserved for Miami ticket holders.
        mintInfos[uint(Edition.FRIENDSHIP)] = MintInfo(461, 499, true, 0.25 ether);
    }

    // Mint tokens of a specific edition.
    function mint(Edition edition, uint8 amount) external payable {
        // Check payment.
        MintInfo memory info = mintInfos[uint(edition)];
        require(info.price * amount == msg.value, "Incorrect payment amount");
        require(info.openMint, "This edition cannot be minted this way");
        _mint(msg.sender, edition, amount);
    }

    // Free mint for holders of the Metaverse Miami ticket, when they simultaneously mint one for a friend and imbue.
    function mintFriendshipMiami(uint256 tokenId, address friend, string calldata imbuement) external payable {
        MintInfo memory info = mintInfos[uint(Edition.FRIENDSHIP_MIAMI)];
        require(info.price == msg.value, "Incorrect payment amount");
        require(metaverseMiamiTicket.ownerOf(tokenId) == msg.sender, "You do not own this ticket");
        require(msg.sender != friend, "You cannot mint with yourself as the friend");
        require(miamiTicketId2claimed[tokenId] == false, "You already claimed with this ticket");
        miamiTicketId2claimed[tokenId] = true;
        require(bytes(imbuement).length > 0, "Imbuement cannot be empty");
        require(bytes(imbuement).length <= 32, "Imbuement too long");
        uint256 nextId = info.nextId;
        ImbuedData data = ImbuedData(NFT.dataContract());
        bytes32 imb = bytes32(bytes(imbuement));
        data.imbueAdmin(nextId, imb, msg.sender, uint96(block.timestamp));
        _mint(friend, Edition.FRIENDSHIP_MIAMI, 1);
    }

    // only owner

    /// (Admin only) Admin can mint without paying fee, because they are allowed to withdraw anyway.
    /// @param recipient what address should be sent the new token, must be an
    ///        EOA or contract able to receive ERC721s.
    /// @param amount the number of tokens to mint, starting with id `nextId()`.
    function adminMintAmount(address recipient, Edition edition, uint8 amount) external onlyOwner() {
        _mint(recipient, edition, amount);
    }

    /// (Admin only) Can mint *any* token ID. Intended foremost for minting
    /// major versions for the artworks.
    /// @param recipient what address should be sent the new token, must be an
    ///        EOA or contract able to receive ERC721s.
    /// @param tokenId which id to mint, may not be a previously minted one.
    function adminMintSpecific(address recipient, uint256 tokenId) external onlyOwner() {
        NFT.mint(recipient, tokenId);
    }

    /// (Admin only) Withdraw the entire contract balance to the recipient address.
    /// @param recipient where to send the ether balance.
    function withdrawAll(address payable recipient) external payable onlyOwner() {
        recipient.call{value: address(this).balance}("");
    }

    /// (Admin only) Set parameters of an edition.
    /// @param edition which edition to set parameters for. 
    /// @param nextId the next id to mint.
    /// @param maxId the maximum id to mint.
    /// @param price the price to mint one token.
    /// @dev nextId must be <= maxId.
    function setEdition(Edition edition, uint16 nextId, uint16 maxId, bool openMint, uint216 price) external onlyOwner() {
        require(nextId % 100 <= maxId % 100, "nextId must be <= maxId");
        require(nextId / 100 == maxId / 100, "nextId and maxId must be in the same batch");
        require(NFT.provenance(nextId, 0, 0).length == 0, "nextId must not be minted yet");
        mintInfos[uint(edition)] = MintInfo(nextId, maxId, openMint, price);
    }

    /// (Admin only) self-destruct the minting contract.
    /// @param recipient where to send the ether balance.
    function kill(address payable recipient) external payable onlyOwner() {
        selfdestruct(recipient);
    }

    // internal

    // Rethink: reentrancy danger. Here we have several nextId.
    function _mint(address recipient, Edition edition, uint8 amount) internal {
        MintInfo memory infoCache = mintInfos[uint(edition)];
        unchecked {
            uint256 newNext = infoCache.nextId + amount;
            require(newNext - 1 <= infoCache.maxId, "Minting would exceed maxId");
            for (uint256 i = 0; i < amount; i++) {
                NFT.mint(recipient, infoCache.nextId + i); // reentrancy danger. Handled by fact that same ID can't be minted twice.
            }
            mintInfos[uint(edition)].nextId = uint16(newNext);
        }
    }
}