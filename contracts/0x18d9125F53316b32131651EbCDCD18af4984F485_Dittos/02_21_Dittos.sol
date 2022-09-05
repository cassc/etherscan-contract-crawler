// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";
import "./strings.sol";

contract Dittos is ERC721A, Ownable {
    mapping(uint256 => string) private _transformations;

    mapping(address => uint256) private _minters;

    bytes4 private ERC721InterfaceId = 0x80ac58cd;
    bytes4 private ERC1155MetadataInterfaceId = 0x0e89341c;

    uint256 public costTransform = 0.01 ether;

    uint16 public MAX_MINT = 1;
    uint256 public MAX_SUPPLY = 10000;
    uint256 public OWNER_SUPPLY = 500;

    constructor() ERC721A("Dittos", "DITTO") {}

    function mint() public {
        require(
            _minters[msg.sender] < MAX_MINT,
            "You are not allowed to mint more Dittos"
        );
        require(
            totalSupply() + OWNER_SUPPLY < MAX_SUPPLY,
            "Max limit of Dittos reached"
        );
        _mint(msg.sender, 1);
        _minters[msg.sender] += 1;
    }

    function ownerMint() public onlyOwner {
        _mint(msg.sender, OWNER_SUPPLY);
    }

    function transform(
        uint256 dittoId,
        address usingContractNFT,
        uint256 usingTokenId
    ) public payable {
        require(
            _exists(dittoId),
            "ERC721Metadata: dittoId for nonexistent token"
        );

        require(
            ownerOf(dittoId) == msg.sender,
            "You are not the owner of this Ditto"
        );

        require(
            msg.value >= costTransform,
            "Transfer amount too low to use Transform"
        );

        if (
            ERC165Checker.supportsInterface(usingContractNFT, ERC721InterfaceId)
        ) {
            (bool success, bytes memory bytesUri) = usingContractNFT.call(
                abi.encodeWithSignature("tokenURI(uint256)", usingTokenId)
            );

            require(success, "Error getting tokenURI data");
            string memory uri = abi.decode(bytesUri, (string));

            _transformations[dittoId] = uri;
        } else if (
            ERC165Checker.supportsInterface(
                usingContractNFT,
                ERC1155MetadataInterfaceId
            )
        ) {
            (bool success, bytes memory bytesUri) = usingContractNFT.call(
                abi.encodeWithSignature("uri(uint256)", usingTokenId)
            );

            require(success, "Error getting URI data");
            string memory uri = abi.decode(bytesUri, (string));

            _transformations[dittoId] = uri;
        } else if (
            usingContractNFT == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB
        ) {
            string memory uri = tokenURIforPunk(uint16(usingTokenId));
            _transformations[dittoId] = uri;
        } else {
            revert("Provided address is not compatible with ERC721 or ERC1155");
        }
    }

    function untransform(uint256 dittoId) public {
        require(
            _exists(dittoId),
            "ERC721Metadata: dittoId for nonexistent token"
        );

        require(
            ownerOf(dittoId) == msg.sender,
            "You are not the owner of this Ditto"
        );

        _transformations[dittoId] = "";
    }

    function tokenURIforDitto(uint256 tokenId)
        private
        pure
        returns (string memory)
    {
        string
            memory svg = '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill="#D5FCFF" d="M0 0h24v24H0z"/><path fill="#FFA4C7" d="M6 17h4v1H6zm6-10h3v1h-3zM8 7h2v1H8zm5-1h2v1h-2zm-1 11h4v1h-4zm-7-7h14v7H5z"/><path fill="#FFA4C7" d="M6 8h13v3H6z"/><path fill="#000" d="M4 13h1v4H4zm2-5h1v2H6zm10-1h3v1h-3zm-1-1h1v2h-1zM6 18h4v1H6zm4-1h2v1h-2zm4-7h2v1h-2zm-7 4h2v1H7zm9 3h2v1h-2zm2-1h1v1h-1zM5 17h1v1H5zm4-4h1v1H9zm1-4h1v1h-1zm4-1h1v1h-1zm-2 10h4v1h-4zm-2-7h4v1h-4zm8 0h1v2h-1zm1 2h1v3h-1zm0-5h1v4h-1zM7 7h1v1H7zm6-2h2v1h-2zm-1 1h1v1h-1zm-2 1h2v1h-2zM8 6h2v1H8zm-3 4h1v3H5z"/></svg>';
        string memory json = string(
            abi.encodePacked(
                '{"name": "Ditto #',
                Strings.toString(tokenId),
                '", "description": "Ditto can use Transform to mimic a different ERC721 or ERC1155 token.", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '"}'
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(json))
                )
            );
    }

    function tokenURIforPunk(uint16 tokenId) private returns (string memory) {
        (
            bool success,
            bytes memory bytesImage
        ) = 0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2.call(
                abi.encodeWithSignature("punkImageSvg(uint16)", tokenId)
            );

        require(success, "Error getting Punk data");
        string memory imageSVG = abi.decode(bytesImage, (string));

        // Formatting SVG output to display
        string memory substringSvg = strings.substring(
            imageSVG,
            162,
            strings.utfStringLength(imageSVG)
        );

        // Adding svg header and background color
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24"><rect x="0" y="0" width="24" height="24" shape-rendering="crispEdges" fill="#638596"/>',
                substringSvg
            )
        );

        string memory json = string(
            abi.encodePacked(
                '{"name": "CryptoPunk #',
                Strings.toString(tokenId),
                '", "description": "Ditto used Transform! It\'s super effective!", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '"}'
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(json))
                )
            );
    }

    function setTransformCost(uint256 priceInWeis) public onlyOwner {
        costTransform = priceInWeis;
    }

    function withdrawFromContract() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (bytes(_transformations[tokenId]).length != 0) {
            return _transformations[tokenId];
        }

        return tokenURIforDitto(tokenId);
    }
}