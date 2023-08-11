// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.21;

/// @title Gnars HD
/// @notice High definition Gnars counterparts
/// @author Volky
/// @dev This contract describes Gnars HD as 1:1 counterparts for each GnarV2. They are not mintable, since the ownership of the respective GnarV2 is mirrored on the GnarHD.
///
////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀       ▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀   ▄▄░░░░▄   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀▀       ▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀  ▄▒░░░░░░░░░▌  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀  ▄▐▒░░░░   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀  ▀░▐░░░░░░░░▌▐  ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▄▒░░░░░░░▐   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   ▌░ ░░░░░░░░░░▓  ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▄░░░░░░░░░▌▌  ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▌  ▄▒ ▒░░░░░░░░░░▌  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▐░ ░░░░░░▐▐▌▌  ▐▓▓▓▓▓▓▓▓▓▓▓▓▓   ░ ▐░░░░░░░░░░▓   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▌ ▐░░░░░░░░░▓   ▓▓▓▓▓▓▓▓▓▓▓▓   ▓▒ ░░░░░░░░░░▐   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▌  ▒ ░░░░░░░░░░▐   ▓▓▓▓▓▓▓▓▓▓▓▓   ▌░▒░░░░░░░░░░▌  ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▌  ▒ ░░░░░░░░░░▐   ▓▓▀▀▀         ▐░ ░░░░░░░░░░▐   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▌  ▒ ▐░░░░░░░░░░        ▄▄▄▄▄▄▄▄▄▐░░░░░░░░░░░░▌  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▌  ▌░▐░░░░░░░░░░▌   ▐░ ░░░░░░░░░░▌░░░░░░░░░░░▐  ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▐░ ▒░░░░░░░░░░▄▄░░░░░░░░░░░░░░▌░░░░░░░░░░▌▌  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌  ▌▒░░░░░░░░░░░▓░░░░░░░░░░░░░░░▌░░░░░░░░░░▒▌  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   ▒░░░░░░░░░░░▌░░░░░▄▄▀▀▀▀▀▀▀▀▀▒░░░░░░░░░▀▄   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌  ▐░░░░░░░░░░░▌░░░░▀░░░░░░░░░░░░░░░░░░░░░░░░▌  ▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌  ▐░░░░░░░░░░▒░░░▌▒▒░░░░░░░░░░░░░░░░░░░░░░░░▀  ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▐░░░░░░░░░▒░░░▌▄▐░░░░░░░░░░░░░░░░░░░░░░░░▒▌  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   ▒░░░░░░░░▓░░░░▓░▄░▀▒░░░░░░░░░░░░░░░░░░░▒▐▐  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   ░░░░░░░░░░▌░░░░░▀▀▒▄▄▄▄▄▄▄▓▀▀▒░░░░░░░░░░░▐  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▐░░░░░░░░░░░▒▀▄▄░▄▄░▀░░░░░░░░░░░░░░░░░░░░░▌  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▐░░░░░░░░░░░░░░░░▓░░░░░░░░░░░░░░░░░░░░░░░▌  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   ▒░░░░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░░░▀  ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▐░░░░░░░░░░░░░░░▒░░░░░░░░░░░░░░░░░░░░▄▀  ▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌   ▒░░░░░░░░░░░░░▀▒░░░░░░░░░░░░░░░░░▒▀  ▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   █▀▀▄▄▄░░░░░░░░░▀▄░░░░░░░░░░░▄▄█   ▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▌  ▐░░░░░░░░░░░░░░░░░▒▀▀▀▀▀▀▒░░░░▐   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   ▀░░░░░░░░░░░░░░░░░░░░░░░░░▄▀  ▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄   ▀▀▒▄░░░░░░░░░░░░░░░▒▀▀   ▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄                     ▄▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▄▄▄▄▄▄▄▄▄▄▄▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//                                                                                        //
//              ░██████╗░███╗░░██╗░█████╗░██████╗░░██████╗  ██╗░░██╗██████╗░              //
//              ██╔════╝░████╗░██║██╔══██╗██╔══██╗██╔════╝  ██║░░██║██╔══██╗              //
//              ██║░░██╗░██╔██╗██║███████║██████╔╝╚█████╗░  ███████║██║░░██║              //
//              ██║░░╚██╗██║╚████║██╔══██║██╔══██╗░╚═══██╗  ██╔══██║██║░░██║              //
//              ╚██████╔╝██║░╚███║██║░░██║██║░░██║██████╔╝  ██║░░██║██████╔╝              //
//              ░╚═════╝░╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░  ╚═╝░░╚═╝╚═════╝░              //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {Base64} from "base64/base64.sol";

contract GnarsHD is Owned {
    /* ⌐◨—————————————————————————————————————————————————————————————◨
                         STRUCTS / EVENTS / ERRORS
       ⌐◨—————————————————————————————————————————————————————————————◨ */
    struct Artwork {
        string ipfsFolder;
        uint48 amountBackgrounds;
        uint48 amountBodies;
        uint48 amountAccessories;
        uint48 amountHeads;
        uint48 amountNoggles;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    error Untransferable();
    error TokenDoesNotExist(uint256 tokenId);

    /* ⌐◨—————————————————————————————————————————————————————————————◨
                         STORAGE
       ⌐◨—————————————————————————————————————————————————————————————◨ */

    string public name = "Gnars HD";

    string public symbol = "GNARSHD";

    string public rendererBaseUri;

    string public contractURI;

    Artwork public artwork;

    ISkateContractV2 public gnarsV2;

    /* ⌐◨—————————————————————————————————————————————————————————————◨
                        CONSTRUCTOR
       ⌐◨—————————————————————————————————————————————————————————————◨ */

    constructor(
        address _gnarsV2Address,
        string memory _rendererBaseUri,
        Artwork memory _artwork,
        string memory _contractURI,
        address _owner
    ) Owned(_owner) {
        gnarsV2 = ISkateContractV2(_gnarsV2Address);
        rendererBaseUri = _rendererBaseUri;
        artwork = _artwork;
        contractURI = _contractURI;
    }

    /* ⌐◨—————————————————————————————————————————————————————————————◨
                         MAIN LOGIC
       ⌐◨—————————————————————————————————————————————————————————————◨ */

    function setArtwork(Artwork memory _artwork) public onlyOwner {
        artwork = _artwork;
    }

    function setContractUri(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setRendererBaseUri(string memory _rendererBaseUri) public onlyOwner {
        rendererBaseUri = _rendererBaseUri;
    }

    /// @notice The properties and query string for a generated token
    /// @param _tokenId The ERC-721 token id
    function getAttributes(uint256 _tokenId)
        public
        view
        returns (string memory resultAttributes, string memory queryString)
    {
        (uint48 background, uint48 body, uint48 accessory, uint48 head, uint48 glasses) = gnarsV2.seeds(_tokenId);
        IGnarDescriptorV2 descriptor = IGnarDescriptorV2(gnarsV2.descriptor());
        IGnarDecorator decorator = IGnarDecorator(descriptor.decorator());

        queryString = string.concat(
            "?contractAddress=",
            Strings.toHexString(address(this)),
            "&tokenId=",
            Strings.toString(_tokenId),
            getBackgroundQueryParam(background),
            getPartQueryParam("BODY", body, artwork.amountBodies),
            getPartQueryParam("ACCESSORY", accessory, artwork.amountAccessories),
            getPartQueryParam("HEADS", head, artwork.amountHeads),
            getPartQueryParam("NOGGLES", glasses, artwork.amountNoggles)
        );

        resultAttributes = string.concat(
            getPartTrait("Background", background, decorator.backgrounds),
            ",",
            getPartTrait("Body", body, decorator.bodies),
            ",",
            getPartTrait("Accessory", accessory, decorator.accessories),
            ",",
            getPartTrait("Head", head, decorator.heads),
            ",",
            getPartTrait("Glasses", glasses, decorator.glasses)
        );
    }

    function getPartQueryParam(string memory folder, uint48 partIndex, uint48 amountOfPart)
        public
        view
        returns (string memory)
    {
        if (partIndex >= amountOfPart) {
            return string.concat("&images=", artwork.ipfsFolder, "/", folder, "/FALLBACK.PNG");
        }

        return string.concat("&images=", artwork.ipfsFolder, "/", folder, "/", Strings.toString(partIndex), ".PNG");
    }

    function getBackgroundQueryParam(uint48 backgroundIndex) public view returns (string memory) {
        if (backgroundIndex >= artwork.amountBackgrounds) {
            return string.concat("&images=", artwork.ipfsFolder, "/BACKGROUND/FALLBACK.PNG");
        }

        return string.concat("&images=", artwork.ipfsFolder, "/BACKGROUND/", Strings.toString(backgroundIndex), ".PNG");
    }

    function getPartTrait(
        string memory traitType,
        uint48 partIndex,
        function (uint256) external view returns (string memory) getPartDescription
    ) public view returns (string memory) {
        try getPartDescription(partIndex) returns (string memory partDescription) {
            return string.concat('{"trait_type":"', traitType, '","value":"', partDescription, '"}');
        } catch {
            return string.concat('{"trait_type":"', traitType, '","value":"Unknown"}');
        }
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        if (gnarsV2.ownerOf(_tokenId) == address(0)) {
            revert TokenDoesNotExist(_tokenId);
        }

        (string memory attributes, string memory queryString) = getAttributes(_tokenId);
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"Gnar HD #',
                            Strings.toString(_tokenId),
                            '", "description":"High definition Gnar #',
                            Strings.toString(_tokenId),
                            " counterpart",
                            '", "attributes": [',
                            attributes,
                            '], "image": "',
                            string.concat(rendererBaseUri, queryString),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    /* ⌐◨—————————————————————————————————————————————————————————————◨
                              PASSTHROUGH METHODS
       ⌐◨—————————————————————————————————————————————————————————————◨ */

    /// @notice Returns the total amount of Gnars HD in existence
    /// @dev Delegates to the Gnars V2 contract
    function totalSupply() external view returns (uint256) {
        return gnarsV2.totalSupply();
    }

    /// @notice Returns the tokenId of the Gnar HD by index
    /// @dev Delegates to the Gnars V2 contract
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        return gnarsV2.tokenByIndex(_index);
    }

    /// @notice Returns the Gnar HD owner's address by token index
    /// @dev Delegates to the Gnars V2 contract
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        return gnarsV2.tokenOfOwnerByIndex(_owner, _index);
    }

    /// @notice Returns the Gnar HD owner's address by token id
    /// @dev Delegates to the Gnars V2 contract
    function ownerOf(uint256 id) public view returns (address owner) {
        return gnarsV2.ownerOf(id);
    }

    /// @notice Returns the amount of Gnars HD owned by the specified address
    /// @dev Delegates to the Gnars V2 contract
    function balanceOf(address owner) public view returns (uint256) {
        return gnarsV2.balanceOf(owner);
    }

    /// @notice Refresh ownership of specified tokens on marketplaces/datasets that are showing out of date information
    /// @dev Since this token is not mintable, there's no Transfer event. This method emits the Transfer event so that consumers that can detect the creation/new ownership of the token.
    /// @param tokenIds The ids of tokens to refresh
    function assertOwnership(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            emit Transfer(address(0), gnarsV2.ownerOf(tokenId), tokenId);
        }
    }

    /* ⌐◨—————————————————————————————————————————————————————————————◨
                              ERC721 LOGIC
       ⌐◨—————————————————————————————————————————————————————————————◨ */

    /// @notice Gnars HD are not transferable
    /// @dev Will always revert
    function approve(address, uint256) public pure {
        revert Untransferable();
    }

    /// @notice Gnars HD are not transferable
    /// @dev Will always revert
    function setApprovalForAll(address, bool) public pure {
        revert Untransferable();
    }

    /// @notice Gnars HD are not transferable
    /// @dev Will always revert
    function transferFrom(address, address, uint256) public pure {
        revert Untransferable();
    }

    /// @notice Gnars HD are not transferable
    /// @dev Will always revert
    function safeTransferFrom(address, address, uint256) public pure {
        revert Untransferable();
    }

    /// @notice Gnars HD are not transferable
    /// @dev Will always revert
    function safeTransferFrom(address, address, uint256, bytes calldata) public pure {
        revert Untransferable();
    }

    /* ⌐◨—————————————————————————————————————————————————————————————◨
                              ERC6454 LOGIC
       ⌐◨—————————————————————————————————————————————————————————————◨ */

    /// @notice Gnars HD are not transferable
    /// @dev Will always return false
    function isTransferable(uint256, address, address) external pure returns (bool) {
        return false;
    }

    /* ⌐◨—————————————————————————————————————————————————————————————◨
                              ERC165 LOGIC
       ⌐◨—————————————————————————————————————————————————————————————◨ */

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0x80ac58cd // ERC165 Interface ID for ERC721
            || interfaceId == 0x5b5e139f // ERC165 Interface ID for ERC721Metadata
            || interfaceId == 0x780e9d63 // ERC165 Interface ID for ERC721Enumerable
            || interfaceId == 0x7f5828d0 // ERC165 Interface ID for ERC173
            || interfaceId == 0x91a6262f; // ERC165 Interface ID for ERC6454
    }
}

interface IGnarDecorator {
    function accessories(uint256) external view returns (string memory);
    function backgrounds(uint256) external view returns (string memory);
    function bodies(uint256) external view returns (string memory);
    function glasses(uint256) external view returns (string memory);
    function heads(uint256) external view returns (string memory);
}

interface IGnarDescriptorV2 {
    function decorator() external view returns (address);
}

interface ISkateContractV2 {
    function balanceOf(address owner) external view returns (uint256);
    function descriptor() external view returns (address);
    function ownerOf(uint256 tokenId) external view returns (address);
    function seeds(uint256)
        external
        view
        returns (uint48 background, uint48 body, uint48 accessory, uint48 head, uint48 glasses);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}