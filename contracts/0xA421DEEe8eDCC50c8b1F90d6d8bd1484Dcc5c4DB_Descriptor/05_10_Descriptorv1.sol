// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a-upgradeable/contracts/interfaces/IERC721AUpgradeable.sol";
import "./library/Base64.sol";
import "./library/StringUtils.sol";
import "./library/ColorLib.sol";

contract Descriptor is Ownable {
    using Strings for uint256;
    using Strings for uint160;
    using StringUtils for string;

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                                set state
    ⌐◨—————————————————————————————————————————————————————————————◨ */
    address private _owner;
    string public description =
        "OPP. Personalized Opepen editions with colors generated from the owner's wallet address. When an OPP is transferred between wallets, the colors will update to reflect the new owner's palette.";
    string public name = "OPP";
    string public contractImage =
        "ipfs://QmNza61hCd3Wah4cw9fh7SRfi5nAFvsFUtuKEfMNsfQAh6";
    string public animationUrl;
    string public sellerFeeBasisPoints;
    address public sellerFeeRecipient = _owner;

    IERC721AUpgradeable public tokenContract;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
    }

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                              URI functions
    ⌐◨—————————————————————————————————————————————————————————————◨ */

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(
            tokenContract.totalSupply() >= tokenId,
            "Ooooooopsepen. This token does't exist."
        );
        return constructTokenURI(tokenId);
    }

    function contractURI() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "',
                                    name,
                                    '", "description": "',
                                    description,
                                    '", "image": "',
                                    contractImage,
                                    '", "seller_fee_basis_points": "',
                                    sellerFeeBasisPoints,
                                    '", "seller_fee_recipient": "',
                                    _owner,
                                    '", "animation_url": "',
                                    animationUrl,
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }

    function getColors(
        address minterAddress
    ) internal pure returns (string[7] memory) {
        string memory addr = uint160(minterAddress).toHexString(20);
        string memory color;
        string[7] memory list;
        for (uint i; i < 7; ++i) {
            if (i == 0) {
                color = addr._substring(6, 2);
            } else if (i == 1) {
                color = addr._substring(6, int(i) * 8);
            } else {
                color = addr._substring(6, int(i) * 6);
            }
            list[i] = color;
        }
        return list;
    }

    function getOwnerOf(
        uint256 tokenId
    ) public view returns (address ownerAddress) {
        ownerAddress = tokenContract.ownerOf(tokenId);
        return ownerAddress;
    }

    function constructTokenURI(
        uint256 tokenId
    ) internal view returns (string memory) {
        address ownerAddress = getOwnerOf(tokenId);
        string memory image = string(
            abi.encodePacked(
                Base64.encode(bytes(getTokenIdSvg(tokenId, ownerAddress)))
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "',
                                    name,
                                    " ",
                                    abi.encodePacked(
                                        string(tokenId.toString())
                                    ),
                                    '","image": "data:image/svg+xml;base64,',
                                    abi.encodePacked(string(image)),
                                    '","description": "',
                                    description,
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }

    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                               get parts
    ⌐◨—————————————————————————————————————————————————————————————◨ */

    function getTokenIdSvg(
        uint256 tokenId,
        address ownerAddress
    ) internal pure returns (string memory svg) {
        bytes[5] memory colors = ColorLib.gradientForAddress(ownerAddress);
        bytes[12] memory colorPalette = getColorPalette(tokenId, colors);
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="2000" height="2000">',
                    '<path fill="#000" d="M100 0H0v100h100V0Z"/>',
                    '<path stroke="#232323" stroke-width=".147" d="M50 0v100M75 0v100M87.5 0v100M25 0v100M12.5 0v100m50-100v100M37.5 0v100M100 50H0m100-12.5H0M100 75H0m100 12.5H0M100 25H0m100-12.5H0m100 50H0"/>',
                    '<path fill="none" stroke="#232323" stroke-width=".147" d="M50 99.927c27.574 0 49.927-22.353 49.927-49.927C99.927 22.426 77.574.074 50 .074 22.427.074.074 22.426.074 50S22.426 99.927 50 99.927Z"/>',
                    '<g shape-rendering="geometricPrecision"><path fill="#000" d="M50 37.5c0 6.885 5.604 12.465 12.518 12.465V37.5H50Z"/><path fill="#fff" d="M50.018 37.5c0 6.914-5.604 12.518-12.518 12.518V37.5h12.518Z"/><path fill="#000" d="M25 37.5c0 6.914 5.604 12.518 12.518 12.518V37.5H25Z"/><path fill="#000" d="M75 25.93a.999.999 0 1 0 0-1.998.999.999 0 0 0 0 1.997Z"/><path fill="#fff" d="M75.018 37.5c0 6.914-5.605 12.518-12.518 12.518V37.5h12.518Z"/>',
                    '<path fill="',
                    colorPalette[0],
                    '" d="M62.518 37.515H50c0-6.884 5.604-12.465 12.518-12.465v12.465Z"/>',
                    '<path fill="',
                    colorPalette[1],
                    '" d="M62.5 37.515h12.518c0-6.884-5.605-12.465-12.518-12.465v12.465Z"/>',
                    '<path fill="',
                    colorPalette[2],
                    '" d="M37.5 37.517h12.518C50.018 30.614 44.405 25 37.501 25L37.5 37.517Z"/>',
                    '</g><g shape-rendering="crispEdges">',
                    '<path fill="',
                    colorPalette[3],
                    '" d="M37.518 37.517H25V25h12.518v12.517Z"/>',
                    '<path fill="',
                    colorPalette[4],
                    '" d="M37.5 62.5H25V50h12.5v12.5Z"/>',
                    '<path fill="',
                    colorPalette[5],
                    '" d="M37.5 75H25V62.5h12.5V75Z"/>',
                    '<path fill="',
                    colorPalette[6],
                    '" d="M50 62.5H37.5V50H50v12.5Z"/>',
                    '<path fill="',
                    colorPalette[7],
                    '" d="M50 75H37.5V62.5H50V75Z"/>',
                    '<path fill="',
                    colorPalette[8],
                    '" d="M62.5 62.5H50V50h12.5v12.5Z"/>',
                    '<path fill="',
                    colorPalette[9],
                    '" d="M62.5 75H50V62.5h12.5V75Z"/>',
                    '<path fill="',
                    colorPalette[10],
                    '" d="M75 62.5H62.5V50H75v12.5Z"/>',
                    '<path fill="',
                    colorPalette[11],
                    '" d="M75 75H62.5V62.5H75V75Z"/></g>',
                    '<path fill="#fff" fill-rule="evenodd" d="M75.494 23.737a.58.58 0 0 0-.988 0 .578.578 0 0 0-.7.699.58.58 0 0 0 0 .988.578.578 0 0 0 .7.7.577.577 0 0 0 .988 0 .576.576 0 0 0 .7-.7.58.58 0 0 0 0-.988.577.577 0 0 0-.7-.7Zm-.582 1.722.67-1.006c.084-.125-.11-.254-.193-.13l-.591.89-.202-.202c-.106-.106-.27.059-.164.165l.319.316a.115.115 0 0 0 .129 0 .116.116 0 0 0 .032-.033Z" clip-rule="evenodd"/>',
                    "</svg>"
                )
            );
    }

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                           utility functions
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */

    function getColorPalette(
        uint256 tokenId,
        bytes[5] memory colors
    ) internal pure returns (bytes[12] memory colorPalette) {
        colorPalette = [
            colors[random(tokenId, 1, colors.length)],
            colors[random(tokenId, 2, colors.length)],
            colors[random(tokenId, 3, colors.length)],
            colors[random(tokenId, 4, colors.length)],
            colors[random(tokenId, 5, colors.length)],
            colors[random(tokenId, 6, colors.length)],
            colors[random(tokenId, 7, colors.length)],
            colors[random(tokenId, 8, colors.length)],
            colors[random(tokenId, 9, colors.length)],
            colors[random(tokenId, 10, colors.length)],
            colors[random(tokenId, 11, colors.length)],
            colors[random(tokenId, 12, colors.length)]
        ];
    }

    function random(
        uint256 tokenId,
        uint256 randomNum,
        uint256 max
    ) internal pure returns (uint256) {
        return (uint256(
            keccak256(
                abi.encodePacked(
                    (tokenId * randomNum) + (tokenId * max) + tokenId
                )
            )
        ) % max);
    }

    function setTokenContract(
        IERC721AUpgradeable _tokenContract
    ) external onlyOwner {
        tokenContract = _tokenContract;
    }

    function setName(string memory _name) public onlyOwner {
        name = _name;
    }

    function setDescription(string memory _description) public onlyOwner {
        description = _description;
    }

    function setContractImage(string memory _contractImage) public onlyOwner {
        contractImage = _contractImage;
    }

    function setSellerFeeBasisPoints(
        string memory _sellerFeeBasisPoints
    ) public onlyOwner {
        sellerFeeBasisPoints = _sellerFeeBasisPoints;
    }

    function setSellerFeeRecipient(
        address _sellerFeeRecipient
    ) public onlyOwner {
        sellerFeeRecipient = _sellerFeeRecipient;
    }

    function setAnimationUrl(string memory _animationUrl) public onlyOwner {
        animationUrl = _animationUrl;
    }
}