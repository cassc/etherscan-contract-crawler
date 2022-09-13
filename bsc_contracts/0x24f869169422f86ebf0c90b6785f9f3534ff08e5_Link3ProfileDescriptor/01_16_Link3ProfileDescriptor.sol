// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { Base64 } from "openzeppelin-contracts/contracts/utils/Base64.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Owned } from "../dependencies/solmate/Owned.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { IProfileNFTDescriptor } from "../interfaces/IProfileNFTDescriptor.sol";

import { QRSVG } from "../libraries/QRSVG.sol";
import { LibString } from "../libraries/LibString.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

import { Link3ProfileDescriptorStorage } from "../storages/Link3ProfileDescriptorStorage.sol";

/**
 * @title Profile NFT Descriptor
 * @author Link3
 * @notice This contract is used to create profile NFT token uri.
 */
contract Link3ProfileDescriptor is
    Initializable,
    Owned,
    UUPSUpgradeable,
    Link3ProfileDescriptorStorage,
    IUpgradeable,
    IProfileNFTDescriptor
{
    event SetAnimationTemplate(string preTemplate, string template);

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the Profile NFT Descriptor.
     *
     * @param _animationTemplate Template animation url to set for the Profile NFT.
     */
    function initialize(string calldata _animationTemplate, address _owner)
        external
        initializer
    {
        animationTemplate = _animationTemplate;
        Owned.__Owned_Init(_owner);
    }

    /// @inheritdoc IProfileNFTDescriptor
    function setAnimationTemplate(string calldata template)
        external
        override
        onlyOwner
    {
        string memory preTemplate = animationTemplate;
        animationTemplate = template;
        emit SetAnimationTemplate(preTemplate, template);
    }

    /// @inheritdoc IUpgradeable
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    /// @inheritdoc IProfileNFTDescriptor
    function tokenURI(DataTypes.ConstructTokenURIParams calldata params)
        external
        view
        override
        returns (string memory)
    {
        string memory formattedName = string(
            abi.encodePacked("@", params.handle)
        );

        string memory animationURL = string(
            abi.encodePacked(animationTemplate, "?handle=", params.handle)
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            formattedName,
                            '","description":"Link3 profile for ',
                            formattedName,
                            '","image":"',
                            _drawStaticImage(params.handle),
                            '","animation_url":"',
                            animationURL,
                            '","attributes":',
                            _genAttributes(
                                LibString.toString(params.tokenId),
                                LibString.toString(bytes(params.handle).length),
                                LibString.toString(params.subscribers),
                                formattedName
                            ),
                            "}"
                        )
                    )
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _genAttributes(
        string memory tokenId,
        string memory length,
        string memory subscribers,
        string memory name
    ) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                '[{"trait_type":"id","value":"',
                tokenId,
                '"},{"trait_type":"length","value":"',
                length,
                '"},{"trait_type":"subscribers","value":"',
                subscribers,
                '"},{"trait_type":"handle","value":"',
                name,
                '"}]'
            );
    }

    function _drawStaticImage(string memory handle)
        internal
        pure
        returns (string memory)
    {
        uint16 handleBackgroundWidth = 0;
        string memory handleSVGElement = "";
        string memory handleInLink = handle;
        string memory qrCode = QRSVG.generateQRCode(
            string(abi.encodePacked(_BASE_URL, handle))
        );

        if (bytes(handle).length > 13) {
            string memory headString = _substring(handle, 0, 13);

            handleSVGElement = string(
                abi.encodePacked(
                    _getHandleSVGtext(headString, 0),
                    _getHandleSVGtext(
                        _substring(handle, 13, bytes(handle).length),
                        90
                    )
                )
            );
            handleInLink = string(abi.encodePacked(headString, ".."));
            handleBackgroundWidth = 188;
        } else {
            handleSVGElement = _getHandleSVGtext(handle, 0);
            handleBackgroundWidth = uint16(bytes(handle).length - 1) * 12 + 30;
        }

        string memory fontStyleSVGElement = _getFontStyleSVGElement();
        string memory backgroundPath = _getBackgroundPath();
        string memory qrCodeSVGElement = _getQRCodeSVGElement(qrCode);
        string memory linkSVGElement = _getLinkSVGElement(
            handleBackgroundWidth,
            handleInLink
        );

        string memory svg = _compose(
            fontStyleSVGElement,
            handleSVGElement,
            backgroundPath,
            qrCodeSVGElement,
            linkSVGElement
        );

        string memory uri = string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(abi.encodePacked(svg))
            )
        );

        return uri;
    }

    function _substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function _getFontStyleSVGElement() internal pure returns (string memory) {
        return
            "<style>@font-face {font-family='\"Outfit\", sans-serif;'}</style>";
    }

    function _getBackgroundPath() internal pure returns (string memory) {
        return
            "<path d='M59 104.826C59 92.0806 62.0452 79.5197 67.882 68.1894L84.3299 36.2613C89.4741 26.2754 99.766 20 110.999 20H177.569H421.276C432.322 20 441.276 28.9543 441.276 40V428.566C441.276 437.981 436.856 446.85 429.339 452.519L406.262 469.921C397.588 476.462 387.02 480 376.157 480H182.724H79C67.9543 480 59 471.046 59 460V104.826Z' fill='black'/>";
    }

    function _getQRCodeSVGElement(string memory base64String)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<image x='20.69%' y='42.72%' href='",
                    base64String,
                    "' width='32.305%' height='32.305%' opacity='0.3'/>"
                )
            );
    }

    function _getLinkSVGElement(uint16 backgroundWidth, string memory handle)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<g style='transform:translate(19.626%, 83.8%)'>",
                    "<text dominant-baseline='hanging' x='0' y='0' fill='#fff' font-size='22px' font-weight='400' font-family='\"Outfit\", sans-serif'>link3.to/</text>",
                    "<rect width='",
                    LibString.toString(backgroundWidth),
                    "px' height='24px' rx='4px' ry='4px' fill='#fff' transform='skewX(-25)' x='90' y='-3'/>",
                    "<text dominant-baseline='hanging' text-anchor='start' x='94' y='0' font-weight='400' font-family='\"Outfit\", sans-serif' font-size='22px' fill='#000'>",
                    handle,
                    "</text></g>"
                )
            );
    }

    function _compose(
        string memory fontStyleSVGElement,
        string memory handleSVGElement,
        string memory backgroundPath,
        string memory qrCodeSVGElement,
        string memory linkSVGElement
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<svg width='500' height='500' viewBox='0 0 500 500' fill='none' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>",
                    fontStyleSVGElement,
                    backgroundPath,
                    handleSVGElement,
                    qrCodeSVGElement,
                    linkSVGElement,
                    "</svg>"
                )
            );
    }

    function _getHandleSVGtext(string memory handle, uint16 yValue)
        internal
        pure
        returns (string memory)
    {
        uint16 y = yValue > 0 ? yValue : 50;

        return
            string(
                abi.encodePacked(
                    "<text text-anchor='end' dominant-baseline='hanging' x='412' y='",
                    LibString.toString(y),
                    "' fill='#fff' font-weight='700' font-family='\"Outfit\", sans-serif' font-size='32'>",
                    handle,
                    "</text>"
                )
            );
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}