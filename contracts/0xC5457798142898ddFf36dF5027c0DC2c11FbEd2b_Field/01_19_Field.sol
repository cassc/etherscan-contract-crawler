//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './Utils.sol';
import './FieldResponsive.sol';
import './FieldThumb.sol';
import './Base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';

contract Field is ERC721, Ownable, ERC2981 {
    string private constant JSON_PROTOCOL_URI = 'data:application/json;base64,';
    string private constant SVG_PROTOCOL_URI = 'data:image/svg+xml;base64,';

    constructor() ERC721('Field', unicode'✲') {
      _setDefaultRoyalty(0x9011Eb570D1bE09eA4d10f38c119DCDF29725c41, 1000); // 10%
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getImageSVG(uint256 tokenId) private pure returns (string memory) {
        return
            Base64.encode(
                abi.encodePacked(renderThumb(tokenId, appearance(tokenId)))
            );
    }

    function getAnimationSVG(uint256 tokenId)
        private
        pure
        returns (string memory)
    {
        return
            Base64.encode(
                abi.encodePacked(
                    renderResponsiveAnimation(tokenId, appearance(tokenId))
                )
            );
    }

    // function example() external view returns (string memory) {
    //     return tokenURI(5);
    //     // uint256 tokenId = 5;
    //     // return renderThumb(tokenId, appearance(tokenId));
    // }

    function appearance(uint256 tokenId) internal pure returns (uint8) {
        return uint8(tokenId - 1) / 2;
    }

    function traitsString(uint256 tokenId) private pure returns (bytes memory) {
        uint8 a = appearance(tokenId);
        string memory appearanceString = a == 0 ? 'auto' : a == 1
            ? 'classic'
            : 'dark';
        return
            abi.encodePacked(
                '"attributes":[{"trait_type":"appearance","value":"',
                appearanceString,
                '"},{"trait_type":"kind","value":"',
                tokenId % 2 == 1 ? 'similar' : 'diverse',
                '"}]'
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        bytes memory image = abi.encodePacked(
            SVG_PROTOCOL_URI,
            getImageSVG(tokenId)
        );
        bytes memory animation = abi.encodePacked(
            SVG_PROTOCOL_URI,
            getAnimationSVG(tokenId)
        );

        bytes memory json = abi.encodePacked(
            '{"name":"Field ',
            utils.uint2str(tokenId),
            '",',
            '"description":"Harm van den Dorpel, 2008-2023",',
            '"image":"',
            image,
            '",',
            '"animation_url":"',
            animation,
            '",',
            traitsString(tokenId),
            '}'
        );
        return string(abi.encodePacked(JSON_PROTOCOL_URI, Base64.encode(json)));
    }

    function adminMint(address recipient, uint256 tokenId) external onlyOwner {
        require(tokenId <= 6, 'all minted');
        _safeMint(recipient, tokenId);
    }

    function totalSupply() public pure returns (uint256) {
        return 6;
    }
}