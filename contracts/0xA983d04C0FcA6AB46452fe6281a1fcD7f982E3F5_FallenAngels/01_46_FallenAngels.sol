import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./LiquidCollections.sol";

contract FallenAngels is LiquidCollections {
    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    )
        LiquidCollections(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
    {}

    /*///////////////////////////////////////////////////////////////
                    Overriden ERC 721 logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Returns the metadata URI for an NFT.
     *  @dev            See `BatchMintMetadata` for handling of metadata in this contract.
     *
     *  @param _tokenId The tokenId of an NFT.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string
            memory cid = "bafybeiaxucaszbmk6zmjtmxixzrifwdol4khjvq2m3oew64ukliy7ivug4";
        string memory fancyId = Strings.toString(_tokenId + 1);
        string memory redeemed = " [REDEEMED]";
        string memory nameFancyIdAndRedeemedMaybe;
        string memory redeemable;
        bytes memory animationurl;

        if (isRedeemable(_tokenId)) {
            redeemable = "true";
            nameFancyIdAndRedeemedMaybe = fancyId;
            animationurl = abi.encodePacked(
                "https://",
                cid,
                ".ipfs.nftstorage.link/pre/",
                fancyId,
                ".jpg"
            );
        } else {
            redeemable = "false";
            nameFancyIdAndRedeemedMaybe = string(
                bytes.concat(bytes(fancyId), bytes(redeemed))
            );
            animationurl = abi.encodePacked(
                "https://",
                cid,
                ".ipfs.nftstorage.link/post/redeemed_",
                fancyId,
                ".jpg"
            );
        }

        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Fallen Angel Tequila #',
            nameFancyIdAndRedeemedMaybe,
            '",',
            '"description": "The inaugural drop of Fallen Angel Tequila, a super-premium reposado made from 100% Blue Weber Agave. A collaboration between Meta Angels and Liquid Collections, this Liquid-backed token features the beautiful artwork from Aslan Ruby and is redeemable for our limited edition Fallen Angel Tequila.  Return to this page at Liquid Collections for additional tequila details and redemption information in February 2023: https://liquidcollections.com/collections/fallen-angel-tequila",',
            '"image": "',
            animationurl,
            '",',
            '"animation_url": "',
            animationurl,
            '",',
            '"attributes": [ { "trait_type": "Spirit", "value": "Tequila" }, { "trait_type": "Provenance", "value": "Jalisco, MX" }, { "trait_type": "Proof", "value": "80" }, { "trait_type": "Size", "value": "750ml" }, { "trait_type": "Agave", "value": "100% Blue Weber" }, { "trait_type": "Batch", "value": "One" }, { "trait_type": "Distilled", "value": "2022" }, { "trait_type": "Tequila Type", "value": "Reposado" }, { "trait_type": "Partner", "value": "Meta Angels" }, { "trait_type": "Brand", "value": "Fallen Angel" }, { "trait_type": "Artist", "value": "Aslan Ruby" } ],',
            '"redeemable": ',
            redeemable,
            "",
            "}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    // /*///////////////////////////////////////////////////////////////
    //                 Overriden ERC 721 logic
    // //////////////////////////////////////////////////////////////*/

    // /**
    //  *  @notice         Returns the metadata URI for an NFT.
    //  *  @dev            See `BatchMintMetadata` for handling of metadata in this contract.
    //  *
    //  *  @param _tokenId The tokenId of an NFT.
    //  */
    // function tokenURI(uint256 _tokenId)
    //     public
    //     view
    //     virtual
    //     override
    //     returns (string memory)
    // {
    //     string memory uid = Strings.toString(_tokenId);
    //     bytes memory dataURI = abi.encodePacked(
    //         "{",
    //         '"name": "My721Token #',
    //         uid,
    //         '"image": "image #',
    //         uid,
    //         '"',
    //         '"foo": "bar"',
    //         // Replace with extra ERC721 Metadata properties
    //         "}"
    //     );

    //     return
    //         string(
    //             abi.encodePacked(
    //                 "data:application/json;base64,",
    //                 Base64.encode(dataURI)
    //             )
    //         );
    // }
}