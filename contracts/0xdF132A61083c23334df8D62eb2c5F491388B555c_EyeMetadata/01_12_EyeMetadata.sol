/* --------------------------------- ******* ----------------------------------- 
                                       THE

                            ███████╗██╗   ██╗███████╗
                            ██╔════╝╚██╗ ██╔╝██╔════╝
                            █████╗   ╚████╔╝ █████╗  
                            ██╔══╝    ╚██╔╝  ██╔══╝  
                            ███████╗   ██║   ███████╗
                            ╚══════╝   ╚═╝   ╚══════╝
                                 FOR ADVENTURERS
                                                                                   
                             .-=++=-.........-=++=-                  
                        .:..:++++++=---------=++++++:.:::            
                     .=++++----=++-------------===----++++=.         
                    .+++++=---------------------------=+++++.
                 .:-----==------------------------------------:.     
                =+++=---------------------------------------=+++=    
               +++++=---------------------------------------=++++=   
               ====-------------=================-------------===-   
              -=-------------=======================-------------=-. 
            :+++=----------============ A ============----------=+++:
            ++++++--------======= MAGICAL DEVICE =======---------++++=
            -++=----------============ THAT ============----------=++:
             ------------=========== CONTAINS ==========------------ 
            :++=---------============== AN =============----------=++-
            ++++++--------========== ON-CHAIN =========--------++++++
            :+++=----------========== WORLD ==========----------=+++:
              .==-------------=======================-------------=-  
                -=====----------===================----------======   
               =+++++---------------------------------------++++++   
                =+++-----------------------------------------+++=    
                  .-=----===---------------------------===-----:.     
                      .+++++=---------------------------=+++++.        
                       .=++++----=++-------------++=----++++=:         
                         :::.:++++++=----------++++++:.:::            
                                -=+++-.........-=++=-.                 

                            HTTPS://EYEFORADVENTURERS.COM
   ----------------------------------- ******* ---------------------------------- */

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import {Base64} from "./lib/Base64.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IEye} from "./interfaces/IEye.sol";
import {IEyeMetadata} from "./interfaces/IEyeMetadata.sol";
import {IEyeDescriptions} from "./interfaces/IEyeDescriptions.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract EyeMetadata is IEyeMetadata, Ownable {
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    IEye private _eye;
    string public svgURIBase;
    string public animationURIBase;
    address public powerupAddress;
    address public eyeDescriptionsAddress;

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    constructor(
        address eyeAddress_,
        address eyeDescriptionAddress_,
        address powerupAddress_
    ) {
        _eye = IEye(eyeAddress_);
        eyeDescriptionsAddress = eyeDescriptionAddress_;
        powerupAddress = powerupAddress_;
    }

    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                    ADMIN                                   */
    /* -------------------------------------------------------------------------- */
    /// @notice Sets the base URI for the token JSON
    /// @param svgBaseURI_ The SVG base URI to set.
    function setSvgBaseURI(string calldata svgBaseURI_) external onlyOwner {
        svgURIBase = svgBaseURI_;
    }

    /// @notice Sets the base URI for the token JSON
    /// @param animationBaseURI_ The animation base URI to set.
    function setAnimationBaseURI(string calldata animationBaseURI_)
        external
        onlyOwner
    {
        animationURIBase = animationBaseURI_;
    }

    /// @notice Sets the descriptions' address
    /// @param newAddress The new descriptions' contract address
    function setDescriptionsAddress(address newAddress) external onlyOwner {
        eyeDescriptionsAddress = newAddress;
    }

    /// @notice Sets the contract address to trigger the powerup
    /// @param newAddress The powerup contract address
    function setPowerupAddress(address newAddress) external onlyOwner {
        powerupAddress = newAddress;
    }

    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                   PUBLIC                                   */
    /* -------------------------------------------------------------------------- */
    /* solhint-disable quotes */
    /// @notice Gets the TokenURI for a specified Eye given params
    /// @param tokenId The tokenId of the Eye
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    _getMetadataJSON(tokenId)
                )
            );
    }

    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                  INTERNAL                                  */
    /* -------------------------------------------------------------------------- */

    function _getMetadataJSON(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            Base64.encode(
                abi.encodePacked(
                    _getMetadataHeader(tokenId),
                    _getSvgURL(tokenId),
                    '", "attributes": ',
                    _getAttributes(tokenId),
                    ', "animation_url": "',
                    _getAnimationURL(tokenId),
                    '"}'
                )
            );
    }

    /// @notice Gets the animation URL for a specific tokenID
    function _getAnimationURL(uint256 tokenId)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                animationURIBase,
                "/",
                _getFilename(tokenId),
                ".html?",
                _getTraitsParams(tokenId),
                _getCustomCollectionParams(tokenId)
            );
    }

    /// @notice Gets the SVG URL for a specific tokenID
    function _getSvgURL(uint256 tokenId) internal view returns (bytes memory) {
        return abi.encodePacked(svgURIBase, "/", _getFilename(tokenId), ".svg");
    }

    /// @notice Get the NFTs description
    function _getDescription(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            IEyeDescriptions(eyeDescriptionsAddress).getDescription(
                _eye.getGreatness(tokenId),
                _eye.getOrder(tokenId),
                _eye.getAttunement(tokenId),
                _eye.getNamePrefix(tokenId),
                _eye.getNameSuffix(tokenId),
                string(_getAnimationURL(tokenId))
            );
    }

    function _getAttributes(uint256 tokenId)
        internal
        view
        returns (bytes memory)
    {
        bytes memory attributes = abi.encodePacked(
            '[{"trait_type":"Attunement", "value": "',
            _eye.getAttunement(tokenId),
            '"}, {"trait_type":"Order", "value": "',
            _eye.getOrder(tokenId),
            '"}, {"trait_type":"Greatness", "value": ',
            Strings.toString(_eye.getGreatness(tokenId)),
            '}, {"trait_type":"My Collection", "value": ',
            Strings.toString(_eye.getIndividualCuration(tokenId).length),
            '}, {"trait_type":"Curated Collection", "value": ',
            Strings.toString(_eye.getCollectionCuration().length),
            '}, {"trait_type":"Enchantment Prefix", "value": "',
            _eye.getNamePrefix(tokenId),
            '"}'
        );
        attributes = abi.encodePacked(
            attributes,
            ', {"trait_type":"Enchantment Suffix", "value": "',
            _eye.getNameSuffix(tokenId),
            '"}, {"trait_type":"Artifact", "value": "',
            _eye.getArtifactName(),
            '"}, {"trait_type":"Vision", "value": "',
            _eye.getVision(tokenId),
            '"}',
            _confirmERC721Balance(_eye.ownerOf(tokenId), powerupAddress)
                ? ',{"trait_type": "Lootbound", "value": "True"}'
                : "",
            "]"
        );
        return attributes;
    }

    function _getTraitsParams(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "g=",
                    Strings.toString(_eye.getGreatness(tokenId)),
                    "&p=",
                    _eye.getNamePrefix(tokenId),
                    "%20",
                    _eye.getNameSuffix(tokenId),
                    "&s=",
                    _eye.getOrder(tokenId)
                )
            );
    }

    function _getCustomCollectionParams(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory collection = "";
        bytes32[] memory stories = _eye.getIndividualCuration(tokenId);
        for (uint256 i = 0; i < stories.length; ) {
            collection = string(
                abi.encodePacked(
                    collection,
                    "&e=",
                    Strings.toHexString(uint256(stories[i]))
                )
            );
            unchecked {
                i++;
            }
        }
        return collection;
    }

    /// @notice Returns file name based on tokenId traits: '[powered on]_[light vs dark]_[order]'
    function _getFilename(uint256 tokenId)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _confirmERC721Balance(_eye.ownerOf(tokenId), powerupAddress)
                    ? "1"
                    : "0",
                "_",
                Strings.toString(_eye.getAttunementIndex(tokenId)),
                "_",
                Strings.toString(_eye.getOrderIndex(tokenId)),
                "_",
                Strings.toString(_eye.getConditionIndex(tokenId)),
                "_",
                Strings.toString(_eye.getVisionIndex(tokenId))
            );
    }

    /// @notice confirms the msg.sender is the owner of an ERC721 from another contract
    /// @param owner The owner of the tokenId
    /// @param contractAddress The address of the contract
    function _confirmERC721Balance(address owner, address contractAddress)
        internal
        view
        returns (bool)
    {
        IERC721 token = IERC721(contractAddress);
        return token.balanceOf(owner) > 0;
    }

    /// @notice confirms the msg.sender is the owner of an ERC20 from another contract
    /// @param owner The owner of the tokenId
    /// @param contractAddress The address of the contract
    function _confirmERC20Balance(address owner, address contractAddress)
        internal
        view
        returns (bool)
    {
        IERC20 token = IERC20(contractAddress);
        return token.balanceOf(owner) > 0;
    }

    /* solhint-disable quotes */
    function _getMetadataHeader(uint256 tokenId)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                '{"name": "',
                _eye.getName(tokenId),
                '", "description": "',
                _getDescription(tokenId),
                '", "image": "'
            );
    }
    /* solhint-enable */
}