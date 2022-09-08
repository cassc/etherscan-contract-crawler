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

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../../Libs/Base64.sol";

contract AutographDynamicNFT721 is
    AccessControlEnumerableUpgradeable,
    ERC721Upgradeable,
    ERC721BurnableUpgradeable,
    ERC721PausableUpgradeable,
    ERC721EnumerableUpgradeable,
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

    string baseContractURI;

    mapping(uint256 => Metadata) public metadata;

    /**
     * @dev Initializable
     */
    function initialize(
        string memory name,
        string memory symbol,
        string memory initialContractURI,
        string[] memory meta,
        string[] memory traits,
        string[] memory values
    ) external initializer {
        __ERC721_init(name, symbol);
        __ERC721Burnable_init();
        __ERC721Pausable_init();
        __AccessControlEnumerable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(UPGRADER_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());

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

        baseContractURI = initialContractURI;
    }

    /**
     * @dev mints quantity of tokens and transfers
     * them to each recipient in the array passed
     */
    function mint(address[] memory recipients) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "AutographDynamic: must have minter role to mint"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(recipients[i], newItemId);
        }
    }

    /**
     * @dev Retrieves the contract-level metadata.
     */

    function contractURI() public view virtual returns (string memory) {
        return baseContractURI;
    }

    /**
     * @dev Sets the contract-level metadata.
     */

    function updateContractURI(string memory newContractURI)
        public
        returns (string memory)
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Must have admin role to update contract level URI"
        );
        baseContractURI = newContractURI;
        return baseContractURI;
    }

    /**
     * @dev Set metadata for all
     */
    function setMetadataForAll(
        string[] memory meta,
        string[] memory traits,
        string[] memory values
    ) external nonReentrant returns (bool success) {
        require(
            hasRole(UPGRADER_ROLE, _msgSender()),
            "AutographDynamic: must have upgrader role"
        );

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
    function concatenate(string memory s1, string memory s2)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(s1, s2));
    }

    /**
     * @dev gets the metadata for this token in base64 encoded
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "AutographDynamic: URI query for nonexistent token"
        );

        string memory tokenIdString = tokenId.toString();
        string memory name = string(
            abi.encodePacked(metadata[0].title, " #", tokenIdString)
        );
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
                        '", ',
                        '"description":"',
                        description,
                        '", ',
                        '"edition_number":"',
                        tokenIdString,
                        '", ',
                        '"image":"',
                        image_url,
                        '", ',
                        '"animation_url":"',
                        animation_url,
                        '", ',
                        '"external_url":"',
                        external_url,
                        '", ',
                        '"attributes":',
                        metaData,
                        "}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
     * @dev A function that generates the metadata for a given tokenId
     */
    function generateMetadata(uint256 _tokenId)
        internal
        view
        returns (string memory)
    {
        string memory _traits = "[";
        for (uint256 t = 0; t < metadata[0].traits.length; t++) {
            string memory trait = string(
                abi.encodePacked(
                    '{"trait_type":"',
                    metadata[0].traits[t],
                    '","value":"',
                    metadata[0].values[t],
                    '"}'
                )
            );
            if (t != metadata[0].traits.length - 1) {
                trait = string(abi.encodePacked(trait, ","));
            }
            _traits = concatenate(_traits, trait);
        }
        _traits = concatenate(_traits, "]");

        return _traits;
    }

    /**
     * @dev Needed for OpenSea editing/royalty setting
     */
    function owner() external view returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    /**
     * @dev Supports the following interfaceIds.
     * - IERC165: 0x01ffc9a7
     * - IERC721: 0x80ac58cd
     * - IERC721Metadata: 0x5b5e139f
     * - IERC2981: 0x2a55205a
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC721PausableUpgradeable
        )
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Pauses all transfers.
     */
    function pause() external virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "AutographDynamic: must have pauser role to pause"
        );

        _pause();
    }

    /**
     * @dev Unpauses all transfers.
     */
    function unpause() external virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "AutographDynamic: must have pauser role to unpause"
        );

        _unpause();
    }
}