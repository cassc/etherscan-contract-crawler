// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/*
               __                               __      _     
  ____ ___  __/ /_____  ____ __________ _____  / /_    (_)___ 
 / __ `/ / / / __/ __ \/ __ `/ ___/ __ `/ __ \/ __ \  / / __ \
/ /_/ / /_/ / /_/ /_/ / /_/ / /  / /_/ / /_/ / / / / / / /_/ /
\__,_/\__,_/\__/\____/\__, /_/   \__,_/ .___/_/ /_(_)_/\____/ 
                     /____/          /_/                      
*/

import "../../Tokens/ERC721A/ERC721AUpgradeable.sol";
import "../../Tokens/ERC721A/IERC721AUpgradeable.sol";
import "../../Tokens/ERC721A/extensions/ERC721ABurnableUpgradeable.sol";
import "../../Tokens/ERC721A/interfaces/IERC721ABurnableUpgradeable.sol";
import "../../Tokens/ERC721A/extensions/ERC721AQueryableUpgradeable.sol";
import "../../Tokens/ERC721A/interfaces/IERC721AQueryableUpgradeable.sol";
import "../../Tokens/ERC721A/extensions/ERC721APausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../../Libs/Base64.sol";

contract AutographDynamicNFT is
    AccessControlEnumerableUpgradeable,
    ERC721AUpgradeable,
    ERC721ABurnableUpgradeable,
    ERC721APausableUpgradeable,
    ERC721AQueryableUpgradeable,
    ReentrancyGuardUpgradeable

{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    CountersUpgradeable.Counter public _tokenIds;

    mapping(uint256 => string) private _tokenURIs;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Metadata {
        string title;
        string description;
        string image_url;
        string animation_url;
        string external_url;
        string[] traits;
        string[] values;
    }

    mapping(uint256 => Metadata) public metadata;

     /**
     * @dev Initializable
     */
    function initialize
    (
        string memory name,
        string memory symbol,
        string[] memory meta,
        string[] memory traits,
        string[] memory values
    )
        external
        initializerERC721A {

        __ERC721A_init(name, symbol);
        __ERC721ABurnable_init();
        __ERC721AQueryable_init();
        __ERC721APausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSenderERC721A());
        _grantRole(MINTER_ROLE, _msgSenderERC721A());
        _grantRole(PAUSER_ROLE, _msgSenderERC721A());
        _grantRole(UPGRADER_ROLE, _msgSenderERC721A());
        _grantRole(ADMIN_ROLE, _msgSenderERC721A());

        /**
        * @dev sets default NFT metadata
        **/
        metadata[0].title = meta[0];
        metadata[0].description = meta[1];
        metadata[0].image_url = meta[2];
        metadata[0].animation_url = meta[3];
        metadata[0].external_url = meta[4];
        metadata[0].traits = traits;
        metadata[0].values = values;
    }

    /**
    * @dev mints quantity of tokens and transfers
    * them to each recipient in the array passed
    * mint ERC2309 gas savings
    */
    function mint
    (
        address[] memory recipients
    )
        external
    {

        require(hasRole(MINTER_ROLE, _msgSenderERC721A()), "AutographDynamic: must have minter role to mint");

        _mintERC2309(address(this), recipients.length);
        uint256[] memory _tokensOfOwner = this.tokensOfOwner(address(this));
        for (uint256 j = 0; j < _tokensOfOwner.length; j++) {
            this.transferFrom(address(this), recipients[j], _tokensOfOwner[j]);
        }

    }

    /**
    * @dev Set metadata for all
    */
    function setMetadataForAll
    (
        string[]  memory meta,
        string[]  memory traits,
        string[]  memory values
    )
        external
        nonReentrant()
        returns(bool success)
    {
        require(hasRole(UPGRADER_ROLE, _msgSender()), "AutographDynamic: must have upgrader role");

        metadata[0].title = meta[0];
        metadata[0].description = meta[1];
        metadata[0].image_url = meta[2];
        metadata[0].animation_url = meta[3];
        metadata[0].external_url = meta[4];
        metadata[0].traits = traits;
        metadata[0].values = values;

        return true;
    }

    /**
    * @dev concats 2 string params helper function
    */
    function concatenate
    (
        string memory s1,
        string memory s2
    )
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(s1, s2));
    }

    /**
    * @dev gets the metadata for this token in base64 encoded
    */
    function tokenURI
    (
        uint256 tokenId
    )
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "AutographDynamic: URI query for nonexistent token");

        string memory tokenIdString = tokenId.toString();
        string memory name = string(abi.encodePacked(metadata[0].title, " #", tokenIdString));
        string memory description = metadata[0].description;

        string memory image_url = metadata[0].image_url;
        string memory metaData = generateMetadata(0);

        string memory animation_url = metadata[0].animation_url;
        string memory external_url = metadata[0].external_url;

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"',
                        name,
                        '", ', '"description":"',
                        description,
                        '", ', '"edition_number":"',
                        tokenIdString,
                        '", ', '"image":"',
                        image_url,
                        '", ', '"animation_url":"',
                        animation_url,
                        '", ', '"external_url":"',
                        external_url,
                        '", ', '"attributes":',
                        metaData,
                        '}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

     /**
     * @dev A function that generates the metadata for a given tokenId
    */
    function generateMetadata
    (
        uint256 _tokenId
    )
        internal
        view
        returns(string memory)
    {
        string memory _traits = "[";
        for (uint t = 0; t < metadata[0].traits.length; t++) {
            string memory trait = string(abi.encodePacked('{"trait_type":"', metadata[0].traits[t], '","value":"', metadata[0].values[t], '"}'));
            if(t != metadata[0].traits.length - 1) {
                trait = string(abi.encodePacked(trait, ','));
            }
            _traits = concatenate(_traits,  trait);
        }
        _traits = concatenate(_traits, "]");

        return _traits;
    }

    /**
    * @dev get token ids for nft by owner by address
    */
    function tokenIdsOfOwner
    (
        address _owner
    )
        external
        view
        returns (uint256[] memory)
    {
        return this.tokensOfOwner(_owner);
    }

    /**
    * @dev Needed for OpenSea editing/royalty setting
    */
    function owner()
        external
        view
        returns (address)
    {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    /**
     * @dev Supports the following interfaceIds.
     * - IERC165: 0x01ffc9a7
     * - IERC721: 0x80ac58cd
     * - IERC721Metadata: 0x5b5e139f
     * - IERC2981: 0x2a55205a
     */
    function supportsInterface
    (
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, AccessControlEnumerableUpgradeable) returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev Pauses all transfers.
     */
    function pause()
        external
        virtual
    {
        require(
            hasRole(PAUSER_ROLE, _msgSenderERC721A()),
            "AutographDynamic: must have pauser role to pause"
        );

        _pause();
    }

    /**
     * @dev Unpauses all transfers.
     */
    function unpause()
        external
        virtual
    {
        require
            (hasRole(PAUSER_ROLE, _msgSenderERC721A()),
            "AutographDynamic: must have pauser role to unpause"
        );

        _unpause();
    }

}