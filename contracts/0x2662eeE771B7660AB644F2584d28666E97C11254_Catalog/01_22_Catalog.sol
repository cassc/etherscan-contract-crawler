// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ZoraAsks} from "./ZoraV3/ZoraAsks.sol";

/**
--------------------------------------------------------------------------------------------------------------------

                                    ,,
  .g8"""bgd         mm            `7MM
.dP'     `M         MM              MM
dM'       ` ,6"Yb.mmMMmm  ,6"Yb.    MM  ,pW"Wq.   .P"Ybmmm
MM         8)   MM  MM   8)   MM    MM 6W'   `Wb :MI  I8
MM.         ,pm9MM  MM    ,pm9MM    MM 8M     M8  WmmmP"
`Mb.     ,'8M   MM  MM   8M   MM    MM YA.   ,A9 8M
  `"bmmmd' `Moo9^Yo.`Mbmo`Moo9^Yo..JMML.`Ybmd9'   YMMMMMb
                                                 6'     dP
                                                 Ybmmmd'

************************************************
LEGAL DISCLAIMER:
https://catalog.works/terms
************************************************

---------------------------------------------------------------------------------------------------------------------                                                                                                                                                                                                                                                                                                                           

@title                      :   Catalog
@author                     :   COMPUTER DATA (brett henderson) of Catalog Records Inc.
@notice                     :   The Catalog Shared Creator Contract is an upgradeable ERC721 contract, purpose built 
                                to facilitate the creation of Catalog records.
@dev                        :   Upgradeable ERC721 Contract, inherits functionality from ERC721Upgradeable. 
                                This contract conforms to the EIP-2981 NFT Royalty Standard.

---------------------------------------------------------------------------------------------------------------------    
 */
contract Catalog is
    ERC721Upgradeable,
    IERC2981Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ZoraAsks
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event CreatorUpdated(uint256 indexed tokenId, address indexed creator);
    event ContentUpdated(
        uint256 indexed tokenId,
        bytes32 indexed contentHash,
        string contentURI
    );
    event MetadataUpdated(uint256 indexed tokenId, string metadataURI);
    event RoyaltyUpdated(
        uint256 indexed tokenId,
        address indexed payoutAddress
    );

    /*//////////////////////////////////////////////////////////////
                         STATE/STORAGE/CALLDATA
    //////////////////////////////////////////////////////////////*/

    /// @notice Storage for readable properties of a Catalog NFT
    /// @param metadataURI URI of the metadata (ipfs://)
    /// @param creator Address of the creator
    /// @param royaltyPayout payout address for royalties (EIP2981)
    /// @param royaltyBPS royalty percentage (in basis points)
    /// @dev this struct is used to store the readable properties of a Catalog NFT
    struct TokenData {
        string metadataURI;
        address creator;
        address royaltyPayout;
        uint16 royaltyBPS;
    }

    /// @notice Calldata struct for input ContentData
    /// @param contentURI URI of the content (ipfs://)
    /// @param contentHash SHA256 hash of the content
    /// @dev this struct is not stored in storage, only used to emit events via input calldata
    struct ContentData {
        string contentURI;
        bytes32 contentHash;
    }

    /// Mapping and Storage
    mapping(uint256 => TokenData) private tokenData;
    /// Tracking tokenIds
    CountersUpgradeable.Counter private _tokenIdCounter;

    /*//////////////////////////////////////////////////////////////
                             INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /**
        @notice Initializes contract with default values
        @param _name name of the contract
        @param _symbol symbol of the contract
        @dev contains constructor logic, initializes proxied contract. must be called upon deployment.
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        address _zoraAsksV1_1,
        address _zoraTransferHelper,
        address _zoraModuleManager
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ZoraAsksV1_1_init(
            _zoraAsksV1_1,
            _zoraTransferHelper,
            _zoraModuleManager
        );
        /// Start tokenId @ 1
        _tokenIdCounter.increment();
    }

    /*//////////////////////////////////////////////////////////////
                                  BURN
    //////////////////////////////////////////////////////////////*/

    /**
        @notice Burns a token, given input tokenId
        @param _tokenId identifier of token to burn
        @dev burns given tokenId, restricted to creator (when owned)
     */
    function burn(uint256 _tokenId) external {
        require(
            (msg.sender == tokenData[_tokenId].creator &&
                msg.sender == ownerOf(_tokenId)),
            "Only creator"
        );
        _burn(_tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                                  MINT
    //////////////////////////////////////////////////////////////*/

    /**
        @notice mints a new token
        @param _data input TokenData struct, containing metadataURI, creator, royaltyPayout, royaltyBPS
        @param _content input ContentData struct, containing contentURI, contentHash.
        @return tokenId of the minted token 
        @dev mints a new token to msg.sender with a valid input creator address proof. Emits a ContentUpdated event to track contentURI/contentHash updates.
     */
    function mint(
        TokenData memory _data,
        ContentData memory _content,
        address _to
    ) public onlyOwner returns (uint256) {
        require(_data.royaltyBPS < 10000, "royalty !< 10000");

        uint256 tokenId = _tokenIdCounter.current();

        _mint(_to, tokenId);
        tokenData[tokenId] = _data;

        // Emit event to track ContentURI
        emit ContentUpdated(tokenId, _content.contentHash, _content.contentURI);

        _tokenIdCounter.increment();
        return tokenId;
    }

    /// @param _ipfs URI of the music metadata (ipfs://bafkreidfgdtzedh27qpqh2phb2r72ccffxnyoyx4fibls5t4jbcd4iwp6q)
    function simpleMint(
        address _to,
        string memory _ipfs,
        uint256 _askPrice,
        address _sellerFundsRecipient,
        uint16 _findersFeeBps
    ) public {
        uint256 tokenId = mint(
            TokenData(_ipfs, _to, _to, 300),
            ContentData(_ipfs, ""),
            _to
        );
        zoraTokenApprovals(_to);
        _createAsk(tokenId, _askPrice, _sellerFundsRecipient, _findersFeeBps);
    }

    /*//////////////////////////////////////////////////////////////
                                  WRITE
    //////////////////////////////////////////////////////////////*/

    /**
        @notice Emits an event to be used to track content updates on a token
        @param _tokenId token id corresponding to the token to update
        @param _content struct containing new/updated contentURI and hash.
        @dev access controlled function, restricted to owner/admin. 
     */
    function updateContentURI(uint256 _tokenId, ContentData calldata _content)
        external
        onlyOwner
    {
        emit ContentUpdated(
            _tokenId,
            _content.contentHash,
            _content.contentURI
        );
    }

    /**
        @notice updates the creator of a token, emits an event
        @param _tokenId token id corresponding to the token to update
        @param _creator address new creator of the token
        @dev access controlled function, restricted to owner/admin. used in case of compromised artist wallet.
     */
    function updateCreator(uint256 _tokenId, address _creator)
        external
        onlyOwner
    {
        emit CreatorUpdated(_tokenId, _creator);
        tokenData[_tokenId].creator = _creator;
    }

    /**
        @notice updates the metadata URI of a token, emits an event
        @param _tokenId token id corresponding to the token to update
        @param _metadataURI string containing new/updated metadata (e.g IPFS URI pointing to metadata.json)
        @dev access controlled, restricted to creator of token
     */
    function updateMetadataURI(uint256 _tokenId, string memory _metadataURI)
        external
    {
        require(msg.sender == tokenData[_tokenId].creator, "!creator");
        emit MetadataUpdated(_tokenId, _metadataURI);
        tokenData[_tokenId].metadataURI = _metadataURI;
    }

    /**
        @notice updates the royalty payout address and royalty BPS of a token, emits an event
        @param _tokenId token id corresponding to the token of which to update royalty payout
        @param _royaltyPayoutAddress address of new royalty payout address
        @dev access controlled to owner only. this function allows for emergency royalty control (i.e compromised wallet)
     */
    function updateRoyaltyInfo(uint256 _tokenId, address _royaltyPayoutAddress)
        external
        onlyOwner
    {
        emit RoyaltyUpdated(_tokenId, _royaltyPayoutAddress);
        tokenData[_tokenId].royaltyPayout = _royaltyPayoutAddress;
    }

    /*//////////////////////////////////////////////////////////////
                                  READ
    //////////////////////////////////////////////////////////////*/

    /**
        @notice gets the creator address of a given tokenId
        @param _tokenId identifier of token to get creator for
        @return creator address of given tokenId
        @dev basic public getter method for creator
     */
    function creator(uint256 _tokenId) public view returns (address) {
        address c = tokenData[_tokenId].creator;
        return c;
    }

    /**
        @notice gets the address for the royalty payout of a token/record
        @param _tokenId identifier of token to get royalty payout address for
        @return royalty payout address of given tokenId
        @dev basic public getter method for royalty payout address 
     */
    function royaltyPayoutAddress(uint256 _tokenId)
        public
        view
        returns (address)
    {
        address r = tokenData[_tokenId].royaltyPayout;
        return r;
    }

    /*//////////////////////////////////////////////////////////////
                                ZORA V3
    //////////////////////////////////////////////////////////////*/

    function zoraTokenApprovals(address _owner) internal onlyOwner {
        _approveOperatorForAll(_owner, address(this));
        _approveOperatorForAll(_owner, zoraTransferHelper);
    }

    function _approveOperatorForAll(address _owner, address _operator)
        internal
    {
        if (!isApprovedForAll(_operator, msg.sender)) {
            _setApprovalForAll(_owner, _operator, true);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
        @notice override function gets royalty information for a token (EIP-2981)
        @param _tokenId token id corresponding to the token of which to get royalty information
        @param _salePrice final sale price of token used to calculate royalty payout
        @dev conforms to EIP-2981
        @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (
            tokenData[_tokenId].royaltyPayout,
            (_salePrice * tokenData[_tokenId].royaltyBPS) / 10000
        );
    }

    /**
        @notice override function to check if contract supports given interface
        @param interfaceId id of interface to check
        @inheritdoc IERC165Upgradeable
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            type(IERC2981Upgradeable).interfaceId == interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId);
    }

    /**
        @notice override function to get the URI of a token. 
        @param _tokenId token id corresponding to the token of which to get metadata from
        @return string containing metadata URI (example: 'ipfs:///...')
        @dev override function, returns metadataURI of token stored in tokenData
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return tokenData[_tokenId].metadataURI;
    }

    /**
        @notice override of UUPSUpgradeable authorizeUpgrade function. 
        @param newImplementation address of the new implementation contract
        @dev access controlled to owner only, upgrades deployed proxy to input implementation. Can be modified to support different authorization schemes.
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}