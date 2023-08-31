//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Imports.sol";

/*
BLOBLOBLOBLOBLOBBLOBLOBLOBLOBLOBBLOBLOBLOBLOBLOBBLOBLOBL
BLOBLOBLOBLOBLOBLOBB#=*+++++*=#BLOBLOBLOBLOBLOBLOBLOBLOB
BLOBLOBLOBLOBLO@*++::::::::::-----*@BLOBLOBLOBLOBLOBLOBB
BLOBLOBLOBLOB#++++::::::::::---------=BLOBLOBLOBLOBLOBLO
BLOBLOBLOBLO=+++++:::::::::-----------:@BLOBLOBLOBLOBLOB
BLOBLOBLOBB=++++++:::::::::-------------#BLOBLOBLOBLOBLO
BLOBLOBLOB@+++++++::::::::---------------@BLOBLOBLOBLOBL
BLOBLOBLOB*+++++++::+@WWWWW*------:@WWW@-:BLOBLOBLOBLOBL
BLOBLOBLOB++++++++::#@WWW=*W+-----:@WW*@=-=BLOBLOBLOBLOB
BLOBLOBLO@++++++++:*#@WWW= #=------@WW*+W:+BLOBLOBLOBLOB
BLOBLOBLO#++++++++:*#@@WW= *#------#WW= @+-@BLOBLOBLOBLO
BLOBLOBLO#++++++++:*#@@WW= *@------=WW# ==-=BLOBLOBLOBLO
BLOBLOBLO#+++++++++*#@@WW= +W------*WW@  @-*BLOBLOBLOBLO
BLOBLOBLO#+++++++++*#@@WW= +W------*WW@  @-*BLOBLOBLOBLO
BLOBLOBLO#++++++++++#@@WW= +W:-----*WWW+ W-+BLOBLOBLOBLO
BLOBLOBLO#++++++++++#@@WW= +W:-----+@WW+ W:+BLOBLOBLOBLO
BLOBLOBLO#++++++++++#@@WW# +W+::---:@WW+ W++BLOBLOBLOBLO
BLOBLOBLO#++++++++++#@@WW# +W+::::-:@WW* W++BLOBLOBLOBLO
BLOBLOBLO#++++++++++=@@WW@ *W:::::::#WW#+W++BLOBLOBLOBLO
BLOBLOBLO#++++++++++*@@WWW*@@:::::::=WWW@W:*BLOBLOBLOBLO
BLOBLOBLO#+++++++++++#@WWWWW=:::::::+WWWW*:=BLOBLOBLOBLO
BLOBLOBLO#++++++++++++*#@@=+::::::::::**:::#BLOBLOBLOBLO
BLOBLOBLO@++++++++++++++::;::::::::::;:::::@BLOBLOBLOBLO
BLOBLOBLO@+++++++++++++++::*@GMGMGM@*::::::BLOBLOBLOBLOB
BLOBLOBLOB+++++++++++++++:::::::::::::::::*BLOBLOBLOBLOB
BLOBLOBLOB++++++++++++++++::::::::::::::::=BLOBLOBLOBLOB
BLOBLOBLOB*+++++++++++++++++::::::::::::::@BLOBLOBLOBLOB
BLOBLOBLOB*++++++++++++++++++::::::::::::+BLOBLOBLOBLOBL
BLOBLOBLOB=++++++++++++++++++++::::::::::=BLOBLOBLOBLOBL
BLOBLOBLOB#++++++++++++++++++++++::::::::@BLOBLOBLOBLOBL
999BLOBS@0xb10BFAcE5bB225B04B0fCe0Ddb2F6f1075Af13A2#2022
*/
contract Blobs is
    BlobChecker,
    IERC1155Receiver,
    WithIPFSMetaData,
    WithFreezableMetadata,
    WithMarketOffers
{
    address constant private BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    constructor (string memory cid)
        ERC721("Blob Mob", "BLOB")
        WithIPFSMetaData(cid)
        WithMarketOffers(payable(BLOB_LAB), 1000)
    {}

    /// @notice Create a new blob
    /// @param tokenIDs The list of tokenIDs to mint
    /// @param owners The list of owners that the tokenIDs should be airdropped to
    /// @param cid The new IPFS collection content identifyer
    function mint (
        uint256[] memory tokenIDs,
        address[] memory owners,
        string memory cid
    ) external onlyOwner {
        require(_freeBlobs(tokenIDs), "Blob ID not allowed");

        for (uint256 index = 0; index < tokenIDs.length; index++) {
            _mint(owners[index], tokenIDs[index]);
        }

        _setCID(cid);
    }

    /// @notice Burns the received Blob to mint a new one.
    function setCID (string memory cid) external onlyOwner unfrozen {
        _setCID(cid);
    }

    /// @notice Burns the received Blob to mint a new one.
    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256,
        bytes calldata
    ) public override returns (bytes4) {
        require(_isBlob(id), "Not a Blob");

        _migrateBlob(id, from);

        return IERC1155Receiver.onERC1155Received.selector;
    }

    /// @notice Burns received Blobs to mint new ones.
    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata,
        bytes calldata
    ) external override returns (bytes4) {
        // First check whether all given IDs are actual Blobs...
        for (uint256 index = 0; index < ids.length; index++) {
            require(_isBlob(ids[index]), "Not a Blob");
        }

        // Then migrate them one by one.
        for (uint256 index = 0; index < ids.length; index++) {
            _migrateBlob(ids[index], from);
        }

        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /// @notice Get the tokenURI for a specific token
    function tokenURI(uint256 tokenId)
        public view override(WithIPFSMetaData, ERC721)
        returns (string memory)
    {
        return WithIPFSMetaData.tokenURI(tokenId);
    }

    /// @notice We support the `HasSecondarySalesFees` interface
    function supportsInterface(bytes4 interfaceId)
        public view override(WithMarketOffers, ERC721, IERC165)
        returns (bool)
    {
        return WithMarketOffers.supportsInterface(interfaceId);
    }

    function _migrateBlob(uint256 id, address owner) private {
        uint256 tokenId = _getBlobTokenId(id);

        storefront.safeTransferFrom(address(this), BURN_ADDRESS, id, 1, "");

        _safeMint(owner, tokenId);
    }

    function _baseURI()
        internal view override(WithIPFSMetaData, ERC721)
        returns (string memory)
    {
        return WithIPFSMetaData._baseURI();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal override(WithMarketOffers, ERC721)
    {
        return WithMarketOffers._beforeTokenTransfer(from, to, tokenId);
    }
}