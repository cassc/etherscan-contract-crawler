// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "erc721a/ERC721A.sol";
import "solady/tokens/ERC2981.sol";
import "solady/auth/Ownable.sol";
import "solady/utils/Base64.sol";
import "solady/utils/SSTORE2.sol";
import "solady/utils/LibString.sol";
import "solady/utils/DynamicBufferLib.sol";
import "closedsea/OperatorFilterer.sol";

contract FadingMemories is ERC721A, Ownable, OperatorFilterer, ERC2981 {
    using LibString for *;
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;

    //--------------------------------------//
    //              ERRORS                  //
    //--------------------------------------//
    error MintOver();

    //--------------------------------------//
    //              STORAGE                 //
    //--------------------------------------//
    mapping(uint256 => uint256) private _seeds;

    //--------------------------------------//
    //    STORAGE - CONSTANTS/IMMUTABLES    //
    //--------------------------------------//
    address public immutable chunk0;
    address public immutable chunk1;
    address public immutable chunk2;
    address public immutable chunk3;
    address public immutable chunk4;
    address public immutable chunk5;
    uint256 public constant FAREWELL = 1687824000; // 27/06/2023
    uint256 public constant MINT_END = FAREWELL + 7 days;

    //--------------------------------------//
    //            CONSTRUCTOR               //
    //--------------------------------------//
    constructor(
        address chunk0_,
        address chunk1_,
        address chunk2_,
        address chunk3_,
        address chunk4_,
        address chunk5_
    ) ERC721A("Fading Memories", "GRETA") {
        chunk0 = chunk0_;
        chunk1 = chunk1_;
        chunk2 = chunk2_;
        chunk3 = chunk3_;
        chunk4 = chunk4_;
        chunk5 = chunk5_;

        _initializeOwner(msg.sender);
        _registerForOperatorFiltering();
        _setDefaultRoyalty(address(this), 1_000);
    }

    //--------------------------------------//
    //               MINT                   //
    //--------------------------------------//
    function mint(address to, uint256 amount) external {
        if (block.timestamp > MINT_END) {
            revert MintOver();
        }

        uint256 tokenId = totalSupply();
        uint256 lastTokenId = tokenId + amount;

        unchecked {
            do {
                _seeds[tokenId] = uint256(keccak256(abi.encode(to, tokenId, block.timestamp)));
            } while (++tokenId < lastTokenId);
        }

        _mint(to, amount);
    }

    //--------------------------------------//
    //              RENDERERING             //
    //--------------------------------------//
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert OwnerQueryForNonexistentToken();
        }

        uint256 seed = _seeds[tokenId];
        uint256 fadeIntensity = (block.timestamp - FAREWELL) / 60 / 60 / 24 / 30;

        DynamicBufferLib.DynamicBuffer memory buffer;
        buffer.append('{"name":"', bytes(name()), '","description":"In memory of Greta, 29/03/2009-27/06/2023",');
        buffer.append('"attributes":', _attributes(seed, fadeIntensity), ',');
        buffer.append('"image":"data:image/svg+xml;base64,', _image(seed, fadeIntensity), '"}');

        return string(abi.encodePacked("data:application/json;base64,", bytes(Base64.encode(buffer.data))));
    }

    function _attributes(uint256 seed, uint256 fadeIntensity) internal pure returns (bytes memory) {
        (uint256 gR, uint256 gG, uint256 gB, uint256 bR, uint256 bG, uint256 bB) = _colors(seed);

        DynamicBufferLib.DynamicBuffer memory buffer;
        buffer.append('[{"trait_type":"Background","value":"rgb(', bytes(bR.toString()), ",", bytes(bG.toString()), ",", bytes(bB.toString()), ')"}');
        buffer.append(',{"trait_type":"Color","value":"rgb(', bytes(gR.toString()), ",", bytes(gG.toString()), ",", bytes(gB.toString()), ')"}');
        buffer.append(',{"trait_type":"Fade","value":"', bytes(fadeIntensity.toString()), '"}]');
        return bytes(buffer.data);
    }

    function _image(uint256 seed, uint256 fadeIntensity) internal view returns (bytes memory) {       
        (uint256 gR, uint256 gG, uint256 gB, uint256 bR, uint256 bG, uint256 bB) = _colors(seed); 
        uint256 fadeInteger = fadeIntensity / 10;
        uint256 fadeDecimal = fadeIntensity - fadeInteger * 10;

        // forgefmt: disable-start
        DynamicBufferLib.DynamicBuffer memory buffer;
        buffer.append('<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg"><path fill="#fff" d="M0 0h1024v1024H0z"/><path class="background" d="M12 12h1000v1000H12z"/>');
        buffer.append(SSTORE2.read(chunk0), SSTORE2.read(chunk1), SSTORE2.read(chunk2), SSTORE2.read(chunk3), SSTORE2.read(chunk4), SSTORE2.read(chunk5));
        buffer.append("<style>.background{fill:rgb(", bytes(bR.toString()), ",", bytes(bG.toString()), ",", bytes(bB.toString()), ")}");
        buffer.append(".greta{fill:rgb(", bytes(gR.toString()), ",", bytes(gG.toString()), ",", bytes(gB.toString()), ")");
        buffer.append(";filter:blur(", bytes(fadeInteger.toString()), ".", bytes(fadeDecimal.toString()), "px)}</style></svg>");
        // forgefmt: disable-end

        return bytes(Base64.encode(buffer.data));
    }

    function _colors(uint256 seed)
        internal
        pure
        returns (uint256 gR, uint256 gG, uint256 gB, uint256 bR, uint256 bG, uint256 bB)
    {
        gR = seed & 0xFF;
        gG = seed >> 8 & 0xFF;
        gB = seed >> 16 & 0xFF;
        bR = seed >> 24 & 0xFF;
        bG = seed >> 32 & 0xFF;
        bB = seed >> 40 & 0xFF;
    }
    
    //--------------------------------------//
    //        ROYALTIES ENFORCEMENT         //
    //--------------------------------------//
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    //--------------------------------------//
    //              WITHDRAW                //
    //--------------------------------------//
    function withdraw() external onlyOwner {
        (bool success,) = payable(owner()).call{value:address(this).balance}("");
        assert(success);
    }

    //--------------------------------------//
    //              RECEIVE                 //
    //--------------------------------------//
    receive() external payable {}
}