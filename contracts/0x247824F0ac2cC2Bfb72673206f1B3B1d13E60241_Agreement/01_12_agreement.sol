// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "Strings.sol";
import "ERC721A.sol";
import "Base64.sol";

contract Agreement is ERC721A {
    using Strings for uint160;
    using Strings for uint256;

    string internal constant p =
        '<p align="left" style= "white-space:pre-wrap; line-height: 35px; font-family:Courier;">';
    string internal constant p$ = "</text></foreignObject>";

    struct AgreementNFT {
        string name;
        string terms;
        address partyA;
        address partyB;
        address asset;
        uint256 assetId;
        uint256 signDate;
        uint256 dueDate;
        bool signed;
    }

    AgreementNFT[] private nft;

    modifier tokenExist(uint256 tokenId) {
        require(_exists(tokenId), "Nonexistent token");
        _;
    }

    constructor() ERC721A("Agreement Manager", "AGRM") {}

    function create(
        string calldata _name,
        string calldata _terms,
        address _party,
        address _asset,
        uint256 _id,
        uint256 _due
    ) external {
        require(
            _party == IERC721(_asset).ownerOf(_id),
            "party-B is not asset owner"
        );
        nft.push(
            AgreementNFT(
                _name,
                _terms,
                msg.sender,
                _party,
                _asset,
                _id,
                block.timestamp,
                _due,
                false
            )
        );

        _mint(msg.sender, 1);
    }

    function sign(uint256 tokenId) public tokenExist(tokenId) {
        _verify(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        tokenExist(tokenId)
        returns (string memory)
    {
        bool signed = nft[tokenId].signed;
        string memory status = nft[tokenId].signed ? "Signed" : "Pending";
        if (block.timestamp >= nft[tokenId].dueDate) {
            status = "Expired";
            signed = false;
        }
        if (
            nft[tokenId].partyB !=
            IERC721(nft[tokenId].asset).ownerOf(nft[tokenId].assetId)
        ) {
            status = "Asset Lost";
            signed = false;
        }

        bytes memory meta = abi.encodePacked(
            '{"name": "',
            nft[tokenId].name,
            '", "description": "The Agreement between [',
            uint160(nft[tokenId].partyA).toHexString(),
            "] and [",
            uint160(nft[tokenId].partyB).toHexString(),
            "] with Asset {",
            uint160(nft[tokenId].asset).toHexString(),
            "#",
            nft[tokenId].assetId.toString(),
            '}",'
        );
        meta = abi.encodePacked(
            meta,
            '"image_data": "data:image/svg+xml;base64,',
            Base64.encode(abi.encodePacked(_nft_image(signed, tokenId))),
            '", "designer": "drzu.xyz",',
            '"attributes": [{"trait_type": "SIGN-DATE", "value": "',
            nft[tokenId].signDate.toString(),
            '"},{"trait_type": "DUE-DATE", "value": "',
            nft[tokenId].dueDate.toString(),
            '"},',
            '{"trait_type": "STATUS", "value": "',
            status,
            '"}]}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(meta)
                )
            );
    }

    function terms(uint256 tokenId)
        public
        view
        tokenExist(tokenId)
        returns (string memory)
    {
        require(
            msg.sender == nft[tokenId].partyA ||
                msg.sender == nft[tokenId].partyB,
            "Only contract party can view contract terms"
        );

        return string(nft[tokenId].terms);
    }

    function _nft_image(bool signed, uint256 tokenId)
        internal
        view
        returns (bytes memory)
    {
        bytes memory ret = abi.encodePacked(
            '<svg width="500" height="500" viewBox="0 0 500 500" ',
            signed
                ? 'style="background-color:darkgreen"'
                : 'style="background-color:darkred"',
            ' xml:space="preserve" xmlns="http://www.w3.org/2000/svg"><text x="250" y="80" style="text-anchor:middle;fill:white;font-size:40px">CONTRACT</text><text x="250" y="120" style="text-anchor:middle;fill:white;font-size:12px">BETWEEN</text><text x="250" y="160" style="text-anchor:middle;fill:white;font-size:24px">PARTY A:</text><text x="250" y="200" style="text-anchor:middle;fill:white;font-size:16px">[',
            uint160(nft[tokenId].partyA).toHexString(),
            ']</text><text x="250" y="240" style="text-anchor:middle;fill:white;font-size:12px">AND</text><text x="250" y="280" style="text-anchor:middle;fill:white;font-size:24px">PARTY B:</text><text x="250" y="320" style="text-anchor:middle;fill:white;font-size:16px">[',
            uint160(nft[tokenId].partyB).toHexString(),
            ']</text><text x="250" y="360" style="text-anchor:middle;fill:white;font-size:24px">WITH ASSET:</text><text x="250" y="400" style="text-anchor:middle;fill:white;font-size:16px">{',
            uint160(nft[tokenId].asset).toHexString(),
            "#",
            nft[tokenId].assetId.toString()
        );
        return
            abi.encodePacked(
                ret,
                '}</text><text x="250" y="460" style="text-anchor:middle;fill:white;font-size:40px">',
                signed ? "VALID" : "INVALID",
                "</text></svg>"
            );
    }

    function _verify(address _party, uint256 tokenId) internal {
        require(_party == nft[tokenId].partyB, "signer is not partyB");
        require(
            _party == IERC721(nft[tokenId].asset).ownerOf(nft[tokenId].assetId),
            "party-B is not asset owner"
        );
        nft[tokenId].signed = true;
    }
}