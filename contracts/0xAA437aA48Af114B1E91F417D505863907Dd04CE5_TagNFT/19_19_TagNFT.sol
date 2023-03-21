//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/ITagEscrow.sol";
contract TagNFT is
    ERC721,
    ERC721Burnable,
    Ownable
{
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;

    ITagEscrow EscrowContract;

    mapping(uint256 => EscrowDetails) public nftEscrowDetails;

    string public version = "V1";

    struct EscrowDetails {
        address owner;
        address arbitrator;
        uint256 escrowId;
        bool isPartyA;
        bool isPartyB;
        string metadataUri;
    }

    // -- EVENTS
    event EscrowNFTCreated(
        address owner,
        uint256 newTokenId,
        uint256 escrowId,
        uint256 createdTime,
        bool isPartyA,
        bool isPartyB
    );

    // -- MODIFIERS
    modifier escrowContractOnly() {
        require(msg.sender == address(EscrowContract), "Caller is not the Escrow Contract");
        _;
    }

    // -- FUNCTIONS
    constructor(address _escrowAddress) ERC721("TAG NFT", "TAG") {
        require(_escrowAddress != address(0), "Escrow cannot be the 0 address");
        EscrowContract = ITagEscrow(_escrowAddress);
    }

    // TODO add events
    /**
    * @dev This method mints the NFT
    * @param owningParty the owner of the NFT
    * @param arbitrator The arbitrator of the wager
    * @param escrowId the ID of the escrow that triggers this function and the NFT will be linked with
    * @param isPartyA Denotes if this NFT belongs to party A otherwise to party B
    * @param metadataUri the URL of the metadata for this NFT
    */
    function mintEscrowNft(
        address owningParty,
        address arbitrator,
        uint256 escrowId,
        bool isPartyA,
        string memory metadataUri
    ) external escrowContractOnly returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(owningParty, newTokenId);

        nftEscrowDetails[newTokenId] = EscrowDetails({
            owner: owningParty,
            arbitrator: arbitrator,
            escrowId: escrowId,
            isPartyA: isPartyA,
            isPartyB: !isPartyA,
            metadataUri: metadataUri
        });

        return newTokenId;
    }

    /**
    * @dev Sets the address of the Escrow contract
    */
    function updateEscrowContractAddress(address _escrowAddress) external onlyOwner {
        require(_escrowAddress != address(0));
        EscrowContract = ITagEscrow(_escrowAddress);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override {
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
        if (from != address(0) && to != address(0)) {
            nftEscrowDetails[firstTokenId].owner = to;
            require(
                nftEscrowDetails[firstTokenId].arbitrator != address(to),
                "You cannot transfer your share to the arbitrator of the escrow"
            );
            EscrowContract.transferRightToCollect(nftEscrowDetails[firstTokenId].escrowId, firstTokenId, to);
        }
    }

    /**
     * @dev Burns the NFT with the provided ID. Only the owner of the NFT can burn it and
     * @param tokenId the token id
     */
    function burn(uint256 tokenId) public override {
        require(msg.sender == ownerOf(tokenId), "Cannot burn this token as you do not own it");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return nftEscrowDetails[tokenId].metadataUri;
    }

    function updateUri(uint256 tokenId, string memory metadataUri) external onlyOwner {
        require(_exists(tokenId), "Trying to update metadata url for non existing token");
        nftEscrowDetails[tokenId].metadataUri = metadataUri;
    }
}