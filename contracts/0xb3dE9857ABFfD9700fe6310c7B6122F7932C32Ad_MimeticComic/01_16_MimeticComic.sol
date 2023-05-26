// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { ERC721 } from "./ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IMimeticComic } from "./IMimeticComic.sol";
import { Base64 } from "./Base64.sol"; 
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IMirror } from "./IMirror.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title Mimetic Comic w/ Phantom Ownership
 * @author @nftchance and @masonthechain 
 * @dev Implementation of EIP-721 Non-Fungible Token Standard, including the 
 *      Metadata extension and combining with the usage of Mimetic Metadata, 
 *      Phantom Ownership, and EIP-2309. Many of the features included in this 
 *      contract will be limited time use / reserved for the future. 
 * @dev The use of hooks is not enabled by default which will leave some 
 *      indexers not having the most up to date ownership record. Hooks solve 
 *      this, however full benefits can only be enjoyed after migration.
 */
contract MimeticComic is
      ERC721
    , Ownable
    , IMimeticComic
{
    using Strings for uint8;
    using Strings for uint256;

    /*//////////////////////////////////////////////////////////////
                    TOKEN METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    ///@dev Comic series metadata info and redemption time period.
    struct Series {
        string description;     // Token description in displays
        string ipfsHash;        // Comic book cover
        uint256 issuanceEnd;    // When this issue can no longer be focused
    }

    ///@dev Comic series index to series data.
    mapping(uint8 => Series) public seriesToSeries;

    ///@dev Token id to comic series index.
    mapping(uint256 => uint256) internal tokenToSeries;

    ///@dev Number of comic series indexes stored in a single index.
    uint256 public constant PACKED = 64;
    
    ///@dev Number of bytes a series can take up.
    uint256 public constant PACKED_SHIFT = 4;
    
    ///@dev Number of tokens required for end-of-road redemption.
    uint256 public constant REDEMPTION_QUALIFIER = 13;

    ///@dev Nuclear Nerds token id to comic wildcard condition truth.
    mapping(uint256 => bool) internal nerdToWildcard;

    ///@dev The default description of the collection and tokens.
    string private collectionDescription;

    ///@dev Disclaimer message appended to wildcard tokens for buyer safety.
    string private wildcardDescription;

    ///@dev Disclaimer message appended to tokens that have been redeemed.
    string private redeemedDescription;

    ///@dev Management of redemption booleans bitpacked to lower storage needs.
    ///@notice `tokens` as it is a bitpacked mapping returned.
    mapping(uint256 => uint256) public tokensToRedeemed;

    /*//////////////////////////////////////////////////////////////
                      COLLECTION STATE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    ///@dev Controls whether or not wildcards can be loaded.
    bool public wildcardsLocked;

    ///@dev Controls whether or not master actions can be called.
    bool public masterLocked;

    ///@dev Controls all series progression within the collection.
    bool public locked;

    ///@dev Nuclear Nerd contracts that call transferHooks upon transfer.
    mapping(address => bool) public hooks;

    /*//////////////////////////////////////////////////////////////
                            ROYALTY LOGIC
    //////////////////////////////////////////////////////////////*/
    
    ///@dev IPFS hash to the contract URI json.
    string public contractURIHash;

    ///@dev On-chain royalty basis points.
    uint256 public royaltyBasis = 690;
    
    ///@dev The floating point percentage used for royalty calculation.
    uint256 private constant percentageTotal = 10000;

    ///@dev Team address that receives royalties from secondary sales.
    address public royaltyReceiver;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    ///@dev EIP-2309 standard for more efficient ownership indexing events.
    event ConsecutiveTransfer(
          uint256 indexed fromTokenId
        , uint256 toTokenId
        , address indexed fromAddress
        , address indexed toAddress
    );

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error CollectionStateInvalid();
    error CollectionMasterLocked();
    error CollectionWildcardsLocked();

    error HookCallerMismatch();

    error TokenMinted();
    error TokenDoesNotExist();
    error TokenOwnerMismatch();
    error TokenNotWildcard();
    error TokenBundleInvalid();
    error TokenRedeemed();

    error SeriesNotLoaded();
    error SeriesAlreadyLoaded();
    error SeriesAlreadyLocked();
    error SeriesNotLocked();
    error SeriesDirectionProhibited();
    error SeriesBundleInvalid();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
          string memory _name
        , string memory _symbol
        , string memory _seriesZeroDescription
        , string memory _seriesZeroHash
        , string memory _collectionDescription
        , string memory _wildcardDescription
        , string memory _redeemedDescription        
        , address _nerds
        , address _royaltyReceiver
        , string memory _contractURIHash
    ) ERC721(
          _name
        , _symbol
        , _nerds
    ) {
        ///@dev Initialize series 0 that everyone starts with.
        seriesToSeries[0] = Series(
              _seriesZeroDescription
            , _seriesZeroHash
            , 42069
        );

        collectionDescription = _collectionDescription;
        wildcardDescription = _wildcardDescription;
        redeemedDescription = _redeemedDescription;

        royaltyReceiver = _royaltyReceiver;
        contractURIHash = _contractURIHash;
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    ///@dev Prevents master locked actions.
    modifier onlyMasterUnlocked() {
        if(masterLocked) revert CollectionMasterLocked();
        _;
    }

    ///@dev Prevents unlocked actions.
    modifier onlyUnlocked() {
        if(locked) revert SeriesAlreadyLocked();
        _;
    }

    ///@dev Prevents locked actions.
    modifier onlyLocked() {
        if(!locked) revert SeriesNotLocked();
        _;
    }

    ///@dev Prevents actions not on a non-loaded series.
    modifier onlyLoaded(uint8 _series) {
        if(bytes(seriesToSeries[_series].ipfsHash).length == 0)
            revert SeriesNotLoaded();
        _;
    }

    ///@dev Prevents actions on tokenIds greater than max supply.
    modifier onlyInRange(uint256 _tokenId) {
        if(_tokenId > MAX_SUPPLY - 1) revert TokenDoesNotExist();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        METADATA INTILIAZATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows the Nuclear Nerds team migrate the primary Nuclear
     *         Nerds collection without having to migrate comics and 
     *         having instant updates as the comics would follow the migration.
     *         As soon as utilization has completed the enabling of
     *         master lock will prevent this function from ever being used
     *         again. Contract ownership is delegated to multi-sig for 
     *         maximum security.
     * @notice THIS WOULD NOT BE IMPLEMENTED IF IT WAS NOT NEEDED. ;) 
     *         (Short time horizon on the usage and locking.)
     * @param _mirror The address of the parent token to mirror ownership of.
     * 
     * Requires:
     * - sender must be contract owner
     * - `masterLocked` must be false (default value)
     */
    function loadMirror(
        address _mirror
    )
        public
        virtual
        onlyMasterUnlocked()
        onlyOwner()
    { 
        mirror = IMirror(_mirror);
    }

    /**
     * @notice Loads the wildcards that have direct redemption at the
     *         locking-point for physical transformation.
     * @dev This function can only be ran once so that wildcards cannot
     *      be adjusted past the time of being established.
     * @param _tokenIds The ids of the tokens that are wildcards.
     * 
     * Requires:
     * - sender must be contract owner
     * - `wildcardsLocked` hash must be false (default value).
     */
    function loadWildcards(
        uint256[] calldata _tokenIds
    )
        public
        virtual
        onlyOwner()
    {
        if(wildcardsLocked) revert CollectionWildcardsLocked();
        
        wildcardsLocked = true;

        for(
            uint8 i;
            i < _tokenIds.length;
            i++
        ) {
            nerdToWildcard[_tokenIds[i]] = true;
        }
    }

    /**
     * @notice Allows token holders to emit an event with
     *         'refreshed' ownership that using the mirrored ownership
     *         of the parent token. This way, indexers will pick up the new
     *         ownership for far cheaper still without having to write 
     *         ownership.
     * @notice Does not update the real ownership state and merely notifies the
     *         platforms of an ownership record 'change' that they need 
     *         to catalog.
     * @dev This is not needed for primary-use however, this is here for
     *      future-proofing backup for any small issues that 
     *      take place upon delivery or future roll outs of new platforms. The 
     *      primary of this use would be that the comic has not been seperated, 
     *      but has found it's in a smart contract that needs the hook to 
     *      complete processing.
     *
     * Requires:
     * - `masterLocked` must be false.
     * - token must NOT be claimed
     * - sender must be owner of the token.
     */
    function refreshToken(
        uint256 _tokenId
    )
        public
        onlyMasterUnlocked()
    {
        if(_exists(_tokenId)) revert TokenMinted();
  
        address _owner = mirror.ownerOf(_tokenId);
        
        if(_msgSender() != _owner) revert TokenOwnerMismatch();

        emit Transfer(
              address(this)
            , _owner
            , _tokenId
        );
    }

    /**
     * @notice Bundle version of token refreshing. This can only be called
     *         if all tokens are still paired and the caller is the owner
     *         of all comics being called.
     * @notice Does not update the real ownership state and merely notifies the
     *         platforms of an ownership record 'change' that they need 
     *         to catalog.
     *
     * Requires:
     * - `masterLocked` must be false.
     * - all tokens must NOT be claimed.
     * - sender must be owner of all tokens.
     */
    function refreshTokenBundle(
        uint256[] calldata _tokenIds
    )
        public
        onlyMasterUnlocked()
    {
        if(!mirror.isOwnerOf(
              _msgSender()
            , _tokenIds
        )) revert TokenOwnerMismatch();

        for(
            uint256 i;
            i < _tokenIds.length;
            i++
        ) {
            if(_exists(_tokenIds[i])) revert TokenMinted();

            emit Transfer(
                  address(this)
                , _msgSender()
                , _tokenIds[i]
            );
        }
    }

    /**
     * @notice Allows the Nuclear Nerds team to emit an event with
     *         'refreshed' ownership utilizing the mirrored ownership
     *         of the parent token.
     * @notice Does not update the real ownership state and merely notifies the
     *         platforms of an ownership record 'change' that they need 
     *         to catalog.
     * @dev This is not needed for primary-use however, this is here for
     *      future-proofing backup for any small issues that 
     *      take place upon delivery or future roll outs of new platforms. The 
     *      primary of this use would be that the comic has not been seperated, 
     *      but has found it's in a smart contract that needs the hook to 
     *      complete processing.
     *
     * Requires:
     * - `masterLocked` must be false.
     * - sender must be contract owner.
     */
    function loadCollectionOwners(
          uint256 _fromTokenId
        , uint256 _toTokenId
    )
        public
        onlyMasterUnlocked()
        onlyOwner()
    {
        for(
            uint256 tokenId = _fromTokenId;
            tokenId < _toTokenId;
            tokenId++
        ) { 
            address _owner = mirror.ownerOf(tokenId);

            emit Transfer(
                  address(0)
                , _owner
                , tokenId
            );

            require(
                _checkOnERC721Received(
                      address(0)
                    , _owner
                    , tokenId
                    , ""
                )
                , "ERC721: transfer to non ERC721Receiver implementer"
            );
        }
    }

    /**
     * @notice Allows the Nuclear Nerds team to emit Transfer events to a 
     *         a specific target. 
     * @notice Does not update the real ownership state and merely notifies the
     *         platforms of an ownership record 'change' that they need 
     *         to catalog.
     * @dev This is not needed for primary-use however,
     *      this is here for future-proofing/backup for any small issues that 
     *      take place upon delivery or future roll outs of new platforms.
     * 
     * Requires:
     * - `masterLocked` must be false.
     * - sender must be contract owner.
     * - length of `to` must be the same length as the range of token ids.
     */
    function loadCollectionCalldata(
            uint256 _fromTokenId
          , uint256 _toTokenId
          , address[] calldata _to
    )
        public
        onlyMasterUnlocked()
        onlyOwner()
    { 
        uint256 length =  _toTokenId - _fromTokenId + 1;

        if(length != _to.length) revert CollectionStateInvalid();

        uint256 index;
        for(
            uint256 tokenId = _fromTokenId;
            tokenId <= _toTokenId;
            tokenId++
        ) { 
            emit Transfer(
                  address(0)
                , _to[index++]
                , tokenId
            );
        }
    }

    /**
     * @notice Utilizes EIP-2309 to most efficiently emit the Transfer events
     *         needed to notify the platforms that this token exists.
     * @notice Does not update the real ownership state and merely notifies the
     *         platforms of an ownership record 'change' that they need 
     *         to catalog.
     *
     * Requires:
     * - `masterLocked` must be false.
     * - sender must be contract owner
     */
    function loadCollection2309(
            uint256 _fromTokenId
          , uint256 _toTokenId
    ) 
        public
        onlyMasterUnlocked()
        onlyOwner()
    { 
        emit ConsecutiveTransfer(
              _fromTokenId
            , _toTokenId
            , address(0)
            , address(this)
        );
    }

    /**
     * @notice Utilizes EIP-2309 to refresh the ownership of tokens in a 
     *         collective batch. This is to be fired after tokens have been 
     *         minted.
     * @notice Does not update the real ownership state and merely notifies the
     *         platforms of an ownership record 'change' that they need 
     *         to catalog.
     *
     * Requires:
     * - `masterLocked` must be false.
     * - sender must be contract owner
     */
    function loadCollection2309From(
            uint256 _fromTokenId
          , uint256 _toTokenId
          , address _from
    ) 
        public
        onlyMasterUnlocked()
        onlyOwner()
    { 
        emit ConsecutiveTransfer(
              _fromTokenId
            , _toTokenId
            , _from
            , address(this)
        );
    }

    /**
     * @notice Utilizes EIP-2309 to most efficiently emit the Transfer events
     *         needed to notify the platforms that this token exists of a 
     *         specific range of token ids AND receivers.
     * @notice Does not update the real ownership state and merely notifies the
     *         platforms of an ownership record 'change' that they need 
     *         to catalog.
     *
     * Requires:
     * - `masterLocked` must be false.
     * - sender must be contract owner
     */
    function loadCollection2309To(
            uint256 _fromTokenId
          , uint256 _toTokenId
          , address _to
    ) 
        public
        onlyMasterUnlocked()
        onlyOwner()
    { 
        emit ConsecutiveTransfer(
              _fromTokenId
            , _toTokenId
            , address(0)
            , _to
        );
    }

    /**
     * @notice Allows owners of contract to initialize a new series of 
     *         the comic as Chapter 12 cannot be published on the same
     *         day as Chapter 1.
     * @dev Fundamentally, a series is 'just' an IPFS hash.
     * @param _series The index of the series being initialized.
     * @param _ipfsHash The ipfs hash of the cover image of the series.
     * @param _issuanceEnd When the issue can no longer be focused.
     * 
     * Requires:
     * - `locked` must be false.
     * - sender must be contract owner
     * `_series` hash must not be set.
     */
    function loadSeries(
          uint8 _series
        , string memory _description
        , string memory _ipfsHash
        , uint256 _issuanceEnd
    )
        override
        public
        virtual
        onlyUnlocked()
        onlyOwner()
    {
        if(bytes(seriesToSeries[_series].ipfsHash).length != 0) {
            revert SeriesAlreadyLoaded();
        }

        seriesToSeries[_series] = Series(
              _description
            , _ipfsHash
            , _issuanceEnd
        );
    }

    /*//////////////////////////////////////////////////////////////
                            LOCK MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Locks the emission of Nuclear Nerd team member called 
     *         loadCollection(x). By default this will remain open,
     *         however with time and the completed release of series
     *         the community may prefer the contract reach a truly 
     *         immutable and decentralized state.
     *
     * Requires:
     * - sender must be contract owner
     */
    function masterLock()
        public
        virtual
        onlyOwner()
    {
        masterLocked = true;
    }

    /**
     * @notice Locks the series upgrading of the collection preventing any
     *         further series from being added and preventing holders
     *         from upgrading their series any further.
     * 
     * Requires:
     * - sender must be contract owner
     */
    function lock()
        override
        public
        virtual
        onlyOwner()
    {     
        locked = true;
    }

    /*//////////////////////////////////////////////////////////////
                            HOOK MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows The Nuclear Nerd team to connect Transfer hooks
     *         to the comic state of a token.
     * @dev Future feature. This can also be completely disabled and 
     *      then locked to prevent any new team additions of hook contracts.
     * @param _hook The address of the contract to accept an incoming 
     *              event from.
     * 
     * Requires:
     * - `masterLocked` must be false.
     * - sender must be contract owner.
     */
    function toggleHook(
        address _hook
    )
        public
        onlyMasterUnlocked()
        onlyOwner()
    {
        hooks[_hook] = !hooks[_hook];
    }

    /**
     * @notice Handles the processing when a parent token of this
     *         is transferred. To be procesed within the handling of 
     *         of the parent token. With this, ownership
     *         of the child token will update immediately across all
     *         indexers, marketplaces and tools.
     * @dev Only emits an event for children tokens that haven't been seperated.
     * @param _from The address transferring the parent token.
     * @param _to The address transferring the child token.
     * @param _tokenId The id of the parent:child token being transferred.
     * 
     * Requires:
     * - sender must be an enabled hook contract.
     */
    function transferHook(
          address _from
        , address _to
        , uint256 _tokenId
    )
        public
        virtual
    {
        if(!hooks[_msgSender()]) revert HookCallerMismatch();

        if(!_exists(_tokenId)) {
            delete _tokenApprovals[_tokenId][_from];
            emit Approval(
                  _from
                , address(0)
                , _tokenId
            );

            emit Transfer(
                  _from
                , _to
                , _tokenId
            );
        }
    }

    /**
     * @notice Handles the processing when a parent token of this
     *         is transferred. To be procesed within the handling of 
     *         of the parent token. With this, ownership
     *         of the child token will update immediately across all
     *         indexers, marketplaces and tools.
     * @dev Only emits an event for children tokens that haven't been seperated.
     * @param _from The address transferring the parent token.
     * @param _to The address transferring the child token.
     * @param _tokenId The id of the parent:child token being transferred.
     * 
     * Requires:
     * - sender must be an enabled hook contract.
     */
    function safeTransferHook(
          address _from
        , address _to
        , uint256 _tokenId
        , bytes memory _data
    )
        public
        virtual
    {
        if(!hooks[_msgSender()]) revert HookCallerMismatch();

        if(!_exists(_tokenId)) {
            delete _tokenApprovals[_tokenId][_from];
            emit Approval(
                  _from
                , address(0)
                , _tokenId
            );

            emit Transfer(
                  _from
                , _to
                , _tokenId
            );

            require(
                  _checkOnERC721Received(
                        _from
                      , _to
                      , _tokenId
                      , _data
                  )
                , "ERC721: transfer to non ERC721Receiver implementer"
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                            COMIC METADATA
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the ipfs image url.
     * @param _series The index of the series we are getting the image for.
     * @return ipfsString The url to ipfs where the image is represented. 
     * 
     * Requires:
     * - Series index provided must be loaded.
     * - Token of id must exist.
     */
    function seriesImage(
        uint8 _series
    )
        override
        public
        virtual
        view
        onlyLoaded(_series)
        returns (
            string memory ipfsString
        )
    {
        ipfsString = string(
            abi.encodePacked(
                  "ipfs://"
                , seriesToSeries[_series].ipfsHash
            )
        );
    }

    /**
     * @notice Returns the series JSON metadata that conforms to standards.
     * @dev The response from this function is not intended for on-chain usage.
     * @param _series The index of the series we are getting the image for.
     * @return metadataString The JSON string of the metadata that represents
     *                        the supplied series. 
     * 
     * Requires:
     * - Series index provided must be loaded.
     * - Token of id must exist.
     */
    function seriesMetadata(
          uint8 _series
        , uint256 _tokenId
        , bool redeemed
        , bool exists
        , bool wildcard
        , uint256 votes
    ) 
        override
        public
        virtual
        view
        onlyLoaded(_series)
        returns (
            string memory metadataString
        )
    {
        ///@dev Append active series 
        ///@note Nerds special prologue of #00 and all series below 10 are 0 padded
        metadataString = string(
            abi.encodePacked(
                  '{"trait_type":"Series","value":"#'
                , _series < 10 ? string(
                    abi.encodePacked(
                          "0"
                        , _series.toString()
                    )
                ) : _series.toString()
                , '"},'
            )
        );

        ///@dev Reflect the state of the series the comic is currently at
        ///@note Minting if issues is still open -- Limited if issues is closed and no more comics can evolve to this stage (series supply is functionally max supply locked)
        metadataString = string(
            abi.encodePacked(
                  metadataString
                , string(
                    abi.encodePacked(
                         '{"trait_type":"Edition","value":"'
                        , seriesToSeries[_series].issuanceEnd < block.timestamp ? "Limited" : "Minting"
                        , '"},'
                    )
                )
            )
        );
        
        ///@dev Append metadata to reflect the Pairing Status of the token
        ///@note When appended the ownership of the token is automatically updating until the pairing is broken through transferring or claiming.
        metadataString = string(
            abi.encodePacked(
                  metadataString
                , string(
                    abi.encodePacked(
                        '{"trait_type":"Nerd","value":"'
                        , !exists ? string(
                            abi.encodePacked(
                                  "#"
                                , _tokenId.toString()
                            )
                        ) : "Unpaired"
                        , '"},'
                    )
                )
            )
        );

        ///@dev Adds the Schrodinger trait if applicable and reflects the status of usage
        if(wildcard) { 
            metadataString = string(
                abi.encodePacked(
                      metadataString
                    , '{"trait_type":"Schrodinger'
                    , "'"
                    , 's Cat","value":"'
                    , redeemed ? "Dead" : "Alive"
                    , '"},'
                )
            );

        ///@dev Show whether or not the token has been used for the physical comic redemption -- does not show on Schrodingers
        } else { 
            metadataString = string(
                abi.encodePacked(
                      metadataString
                    , string(
                        abi.encodePacked(
                            '{"trait_type":"Status","value":"'
                            , redeemed ? "Redeemed" : "Unredeemed"
                            , '"},'
                        )
                    )
                )
            );
        }

        ///@dev Reflect the current number of Story Votes the owner of a Comic token earns through ownership.
        metadataString = string(
            abi.encodePacked(
                  metadataString
                , string(
                    abi.encodePacked(
                        '{"display_type":"number","trait_type":"Story Votes","value":"'
                        , votes.toString()
                        , '","max_value":"12"}'
                    )
                )
            )
        );
    }

    /**
     * @notice Allows the active series of the token to be retrieved.
     * @dev Pick the number out from where it lives. All this does is pull down
     *      the number that we've stored in the data packed index. With the 
     *      cumulative number in hand we nagivate into the proper bits and 
     *      make sure we return the properly cased number.
     * @param _tokenId The token to retrieve the comic book series for.
     * @return series The index of the series the retrieved comic represents.
     * 
     * Requires:
     * - token id must exist
     */
    function tokenSeries(
        uint256 _tokenId
    )
        override
        public
        virtual
        view
        onlyInRange(_tokenId)
        returns (
            uint8 series
        )
    {
        series = uint8(
            (
                tokenToSeries[_tokenId / PACKED] >> (
                    (_tokenId % PACKED) * PACKED_SHIFT
                )
            ) & 0xF
        );
    }

    /**
     * @notice Get the number of votes for a token.
     * @param _tokenId The comic tokenId to check votes for.
     * @return The number of votes the token actively contributes. 
     * 
     * Requires:
     * - token id must exist
     */
    function tokenVotes(
        uint256 _tokenId
    )
        public
        virtual
        view
        onlyInRange(_tokenId)
        returns (
            uint8
        ) 
    {
        if(nerdToWildcard[_tokenId]) return 12;
        
        return tokenSeries(_tokenId);
    }

    /**
     * @notice Determines if a Comic has been used for redemption.
     * @param _tokenId The comic tokenId being checked.
     * @return bool url to ipfs where the image is represented.
     * 
     * Requires:
     * - token id must exist
     */
    function tokenRedeemed(
        uint256 _tokenId
    )
        public 
        view 
        onlyInRange(_tokenId)
        returns(
            bool
        )
    {
        uint256 flag = (
            tokensToRedeemed[_tokenId / 256] >> _tokenId % 256
        ) & uint256(1);

        return (flag == 1 ? true : false);
    }

    /**
     * @notice Get the ipfs image url for a given token.
     * @param _tokenId The comic tokenId desired to be updated.
     * @return The url to ipfs where the image is represented.
     * 
     * Requires:
     * - token id must exist
     */
    function tokenImage(
        uint256 _tokenId
    )
        override
        public
        virtual
        view
        onlyInRange(_tokenId)
        returns (
            string memory
        )
    {
        return seriesImage(tokenSeries(_tokenId));
    }

    /**
     * @notice Returns the series JSON metadata that conforms to standards.
     * @dev The response from this function is not intended for on-chain usage.
     * @param _tokenId The comic tokenId desired to be updated.
     * @return The JSON string of the metadata that represents
     *         the supplied series.
     * 
     * Requires:
     * - token id must exist
     */
    function tokenMetadata(
        uint256 _tokenId
    ) 
        override
        public
        virtual
        view
        onlyInRange(_tokenId)
        returns (
            string memory
        )
    {
        return seriesMetadata(
              tokenSeries(_tokenId)
            , _tokenId
            , tokenRedeemed(_tokenId)
            , _exists(_tokenId)
            , nerdToWildcard[_tokenId]
            , tokenVotes(_tokenId)
        );
    }

    /**
     * @notice Generates the on-chain metadata for each non-fungible 1155.
     * @param _tokenId The id of the token to get the uri data for.
     * @return uri encoded json in the form of a string detailing the 
     *         retrieved token.
     * 
     * Requires:
     * - token id must exist
     */
    function tokenURI(
        uint256 _tokenId
    )
        override
        public
        virtual
        view
        onlyInRange(_tokenId)
        returns (
            string memory uri
        )        
    { 
        uint8 series = tokenSeries(_tokenId);

        uri = seriesToSeries[series].description;

        if(nerdToWildcard[_tokenId]) { 
            uri = string(
                abi.encodePacked(
                      uri
                    , wildcardDescription
                )
            );
        }

        if(tokenRedeemed(_tokenId)) { 
            uri = string(
                abi.encodePacked(
                      uri
                    , redeemedDescription
                )
            );
        }

        // Build the metadata string and return it as encoded data
        uri = string(
            abi.encodePacked(
                  "data:application/json;base64,"
                , Base64.encode(
                    bytes(  
                        abi.encodePacked(
                              '{"name":"Nuclear Nerds Comic #'
                            , _tokenId.toString()
                            , '","description":"'
                            , collectionDescription
                            , uri
                            , '","image":"'
                            , seriesImage(series)
                            , '?owner='
                            , Strings.toHexString(
                                    uint160(ownerOf(_tokenId))
                                , 20
                             )
                            , '","attributes":['
                            , tokenMetadata(_tokenId)
                            , ']}'
                        )
                    )
                )
            )
        );
    }

    /**
     * @notice Helper function to assist in determining whether a Nuclear Nerd
     *         has been used to claim a comic.
     * @dev This function will return false if even one of the tokenId 
     *      parameters has been previously used to claim.
     * @param _tokenIds The tokenIds of the Nuclear Nerds being checked 
     *                  for their claiming status.
     */
    function isClaimable(
        uint256[] calldata _tokenIds
    ) 
        public
        view
        returns (
            bool
        )
    {
        for(
            uint256 i; 
            i < _tokenIds.length;
            i++
        ) {
            if(_exists(_tokenIds[i])) 
                return false;
        }

        return true;
    }

    /**
     * @notice Helper function to used to determine if an array of 
     *         tokens can still be used to redeem a physical.
     * @dev This function will return false if even one of the tokenId
     *      parameters has been previously used to claim.
     * @param _tokenIds The tokenIds of the comcis being checked.
     */
    function isRedeemable(
        uint256[] calldata _tokenIds
    )
        public
        view 
        returns ( 
            bool
        )
    {
        for(
            uint256 i;
            i < _tokenIds.length;
            i++ 
        ) { 
            if(tokenRedeemed(_tokenIds[i]))
                return false;
        }

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                            COMIC CONTROL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows holders of a Nuclear Nerd to claim a comic.
     * @dev This mint function acts as the single token call for claiming
     *      multiple tokens at a time.
     * @param _tokenId The tokenId of the Nuclear Nerd being used 
     *                  to claim a Comic.
     * 
     * Requires:
     * - sender must be owner of mirrored token.
     * - token of id must NOT exist.
     */
    function claimComic(
        uint256 _tokenId
    )
        public
        virtual
    {
        if (
            mirror.ownerOf(_tokenId) != _msgSender()
        ) revert TokenOwnerMismatch();

        _mint(
              _msgSender()
            , _tokenId
        );
    }    

    /**
     * @notice Allows holders of Nuclear Nerds to claim a comic for each 
     *         Nerd they own.
     * @dev This function should be used with reason in mind. A holder with 100 
     *      Nerds is far more likely to have a Nerd purchased in a
     *      long-pending transaction given low gas urgency. 
     * @param _tokenIds The tokenIds of the Nuclear Nerds being used 
     *                  to claim Comics.
     * 
     * Requires:
     * - sender must be owner of all mirrored tokens.
     * - all ids of token must NOT exist.
     */
    function claimComicBundle(
          uint256[] calldata _tokenIds
    ) 
        public
        virtual 
    {
        if(!mirror.isOwnerOf(
              _msgSender()
            , _tokenIds
        )) revert TokenOwnerMismatch();

        for(
            uint256 i; 
            i < _tokenIds.length;
            i++
        ) {
            _mint(
                  _msgSender()
                , _tokenIds[i]
            );
        }
    }
    
    /**
     * @notice Focuses a specific comic on a specific series.
     * @dev Every _series has at most 8 bits so we can bitpack 32 of them 
     *      (8 * 32 = 256) into a single storage slot of a uint256. 
     *      This saves a significant amount of money because setting a 
     *      non-zero slot consumes 20,000 gas where as it only costs 5,000 
     *      gas. So it is cheaper to store 31/32 times.
     * 
     * Requires:
     * - series being upgraded to must have been loaded.
     * - message sender must be the token owner.
     * - comic cannot be downgraded.
     * - cannot upgrade to series with closed issuance.
     */
    function _focusSeries(
          uint8 _series
        , uint256 _tokenId
    )
        internal
        onlyLoaded(_series)
    {        
        if(_msgSender() != ownerOf(_tokenId)) revert TokenOwnerMismatch();
    
        uint256 seriesIndex = _tokenId / PACKED;
        uint256 bitShift = (_tokenId % PACKED) * PACKED_SHIFT;

        if(uint8(
            (tokenToSeries[seriesIndex] >> bitShift) & 0xF
        ) > _series) revert SeriesDirectionProhibited();

        if(seriesToSeries[_series].issuanceEnd < block.timestamp) {
            revert SeriesAlreadyLocked();
        }

        tokenToSeries[seriesIndex] =
              (tokenToSeries[seriesIndex] & ~(0xF << bitShift)) 
            | (uint256(_series) << bitShift);
    }

    /**
     * @notice Allows the holder of a comic to progress
     *         the comic token to a subsequent issued series.
     * @dev Once a comic has progressed to the next issued series,
     *      it cannot be reverted back to a previous series.
     * @dev A token can progress from an early series to any series
     *      in the future provided Comics have not been locked.
     * @param _series The desired series index.
     * @param _tokenId The comic tokenId desired to be updated.
     *
     * Requires:
     * - series of index must be unlocked.
     */
    function focusSeries(
          uint8 _series
        , uint256 _tokenId
    ) 
        override
        public
        virtual
        onlyUnlocked()
    {
        _focusSeries(
              _series
            , _tokenId
        );
    }
 
    /**
     * @notice Allows the holder to focus multiple comics with multiple series
     *         in the same transaction so that they can update a series of
     *         comics all at once without having to go through pain.
     * @dev Once a comic has progressed to the next issued series,
     *      it cannot be reverted back to a previous series.
     * @dev A token can progress from an early series to any series
     * @param _series The array of desired series to be focused by tokenId.
     * @param _tokenIds The array of tokenIds to be focused.
     *
     * Requires:
     * - series of index must be unlocked.
     * - series array and token id array lengths must be the same.
     */
    function focusSeriesBundle(
          uint8[] calldata _series
        , uint256[] calldata _tokenIds
    ) 
        public
        virtual
        onlyUnlocked()
    {
        if(_series.length != _tokenIds.length) revert SeriesBundleInvalid();

        for(
            uint256 i;
            i < _series.length;
            i++
        ) {
            _focusSeries(
                  _series[i]
                , _tokenIds[i]
            );
        }
    }

    /**
    * @notice Toggles the redemption stage for a token id.
     * @dev Implements the boolean bitpacking of 256 values into a single 
     *      storage slot. This means, that while we've created a gas-consuming
     *      mechanism we've minimized cost to the highest extent. A boolean is 
     *      only 1 bit of information, but is typically 8 bits in solidity.
     *      With bitpacking, we can stuff 256 values into a single storage slot
     *      making it cheaper for the following 255 comics. This cost-savings 
     *      scales through the entire collection.
     * 
     * Requires:
     * - message sender must be the token owner
     * - cannot already be redeemed
     */
    function _redeemComic(
        uint256 _tokenId
    )
        internal
    {
        if(ownerOf(_tokenId) != _msgSender()) revert TokenOwnerMismatch();

        uint256 tokenIndex = _tokenId / 256;
        uint256 tokenShift =  _tokenId % 256;

        if(((
            tokensToRedeemed[tokenIndex] >> tokenShift
        ) & uint256(1)) == 1) revert TokenRedeemed();

        tokensToRedeemed[tokenIndex] = (
            tokensToRedeemed[tokenIndex] | uint256(1) << tokenShift
        );
    }

    /**
     * @notice Allows a holder to redee an array of tokens.
     * @dev The utilization of this function is not fully gated, though the 
     *      return for 'redeeming comics' is dependent on external criteria. 
     *      Nothing is earned or entitled by the redemption of a Comic unless 
     *      in the defined times and opportunities.
     * @dev Interface calls are extremely expensive. It is worthwhile to use 
     *      the higher level processing that is available.
     * @param _tokenIds The ids of the tokens to redeem.
     *
     * Requires:
     * - collection evolution must be locked preventing any future focusing.
     * - token ids array length must be equal to redemption capacity
     */
    function redeemComics(
          uint256[] calldata _tokenIds
    ) 
        public
        virtual
        onlyLocked()
    {
        if(
            _tokenIds.length != REDEMPTION_QUALIFIER
        ) revert TokenBundleInvalid();

        for (
            uint256 i; 
            i < _tokenIds.length; 
            i++
        ) {
            _redeemComic(_tokenIds[i]);
        }
    }

    /**
     * @notice Allows a wildcard holder to redeem their token.
     * @dev The utilization of this function is not fully gated, though the
     *      return for 'redeeming comics' is dependent on external criteria. 
     *      Nothing is earned or entitled by the redemption of a Comic unless 
     *      in the defined times and opportunities.
     * @dev Interface calls are extremely expensive. It is worthwhile to use 
     *      the higher level processing that is available.
     * @param _tokenId The id of the token to redeem.
     *
     * Requires:
     * - collection evolution must be locked preventing any future focusing.
     * - token id must be a wildcard representative of a wildcard Nuclear Nerd.
     */
    function redeemWildcardComic(
        uint256 _tokenId
    ) 
        public
        virtual
        onlyLocked()
    {   
        if(!nerdToWildcard[_tokenId]) revert TokenNotWildcard();

        _redeemComic(_tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) 
        public 
        view 
        virtual 
        override
        returns (
            bool
        ) 
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IMimeticComic).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC2981 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Allows the Nuclear Nerds team to adjust contract-level metadata
     * @param _contractURIHash The ipfs hash of the contract metadata
     */
    function setContractURI(
        string memory _contractURIHash
    )
        public
        onlyOwner()
    { 
        contractURIHash = _contractURIHash;
    }

    /**
     * @notice Returns the accesible url of the contract level metadata
     */
    function contractURI() 
        public 
        view 
        returns (
            string memory
        ) 
    {
        return string(
            abi.encodePacked(
                  "ipfs://"
                , contractURIHash
            )
        );
    }

    /**
    * @notice Allows the Nuclear Nerds team to adjust where royalties
    *         are paid out if necessary.
    * @param _royaltyReceiver The address to send royalties to
    */
    function setRoyaltyReceiver(
        address _royaltyReceiver
    ) 
        public 
        onlyOwner() 
    {
        require(
              _royaltyReceiver != address(0)
            , "Royalties: new recipient is the zero address"
        );

        royaltyReceiver = _royaltyReceiver;
    }

    /**
    * @notice Allows the Nuclear Nerds team to adjust the on-chain
    *         royalty basis points.
    * @param _royaltyBasis The new basis points earned in royalties
    */
    function setRoyaltyBasis(
        uint256 _royaltyBasis
    )
        public
        onlyOwner()
    {
        royaltyBasis = _royaltyBasis;
    }

    /**
    * @notice EIP-2981 compliant view function for marketplaces
    *         to calculate the royalty percentage and what address
    *         receives them. 
    * @param _salePrice Total price of secondary sale
    * @return address of receiver and the amount of payment to send
    */
    function royaltyInfo(
          uint256
        , uint256 _salePrice
    ) 
        public 
        view 
        returns (
              address
            , uint256
        ) 
    {
        return (
              royaltyReceiver
            , (_salePrice * royaltyBasis) / percentageTotal
        );
    }
}