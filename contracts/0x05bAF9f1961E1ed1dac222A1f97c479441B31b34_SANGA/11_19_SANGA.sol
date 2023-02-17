//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/***
 *    ███████╗ █████╗ ███╗   ██╗ ██████╗  █████╗
 *    ██╔════╝██╔══██╗████╗  ██║██╔════╝ ██╔══██╗
 *    ███████╗███████║██╔██╗ ██║██║  ███╗███████║
 *    ╚════██║██╔══██║██║╚██╗██║██║   ██║██╔══██║
 *    ███████║██║  ██║██║ ╚████║╚██████╔╝██║  ██║
 *    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝
 *
 * cromagnus the name
 * mystery in his brush strokes
 * art must always flow
 */

import "./SAN1155.sol";
import "./token/ERC2981ContractWideRoyalties.sol";
import "./token/TokenRescuer.sol";
import "./ISAN.sol";
import "./SANSoulbindable.sol";
import "./ISANGA.sol";

/**
 * @title SANGA by Cromagnus
 * @author Aaron Hanson <[email protected]> @CoffeeConverter
 */
contract SANGA is
    ISANGA,
    SAN1155,
    ERC2981ContractWideRoyalties,
    TokenRescuer,
    SANSoulbindable
{
    /// The maximum ERC-2981 royalties percentage (two decimals).
    uint256 public constant MAX_ROYALTIES_PCT = 333; // 3.33%

    /// The SAN contract.
    ISAN public immutable SAN;

    /// The start time of the first minting epoch.
    uint256 immutable public FLOW_ORIGINATION_TIME;

    /// The length of a minting epoch.
    uint256 immutable public FLOW_RATE;

    /// The token name.
    string public name;

    /// The token symbol.
    string public symbol;

    /// The contract URI for contract-level metadata.
    string public contractURI;

    /// The token sale state (0=Paused, 1=Open).
    SaleState public saleState = SaleState.Open;

    /// Tracks which minting epochs have been skipped.
    mapping(uint256 => bool) private epochSkipped;

    /// Tracks which SAN tokens have been used to mint in this epoch.
    /// epoch => bitfield array
    mapping(uint256 => uint256[40]) private epochSanUsed;

    uint256[40] private sanGoldTokenBitfield = [
        36893488147419103232,
        11150373928493307355683732040131241033334784,
        2305843009213693952,
        1606938044258990275541962092341162602522202993782792835301376,
        55213970774324510299478046898216203619608871796705905555134260602470400,
        21267647932558658688827395834130726912,
        205688069665150755269371147819668813122841983204197482918576128,
        1725438232202198268064731120538439917384279064465366950225789614817280,
        0,
        441711766194596180475538996311607334714920236071836368927967390581391360,
        28269553036454155550626057352616065595456100367924597067487529538800320512,
        452312848583266388373324160190187140051835877600177796092245021597705961472,
        784637716923424298460267800393524444885885024004028235776,
        11692013098647223345629478661730264157247460343808,
        187437584987688299259622580400326207078187935989760,
        514220174162876888173427869550470107021738738992833002368795136,
        1461501648222607500259002564945408316080753213440,
        102844034834071955311312418498074979830122465414226416383295488,
        10889077279844899109449015681787216527362,
        27606985387162267410077494795375679823640796408330383623876468071727104,
        79228162514264337593543950336,
        57896044618658097711785492504343953926634992332820282019728792003956564819968,
        6277101735386680763835789423207666416102355444466181996545,
        40728227292489011044181186969600,
        2147549184,
        13164036483089576991093975194192356474276505269525381895124156416,
        12855504354071922204335696738729300820187068683228081972838912,
        21778071482940216404160885548167527923712,
        2722258935525964032735525534641233608740,
        862718704724959803824391304722084463551968387438819483148461178617856,
        3369993333394596315640628243330772752694576644254665679320626757633,
        36028938752884736,
        0,
        2993155353253689176481146537402947624255349864792064,
        411376139330488582748320651213029957181100864178446488307761664,
        14474011154717180573780651719434947495500583299404132133890181186165372092416,
        365380984519025362206706592108638917004359630848,
        10385861367669883486462489361645568,
        383123885216472214589749016064406509268076358556188672,
        0
    ];

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        string memory _baseURI,
        address _royaltiesReceiver,
        uint256 _royaltiesPercent,
        uint256 _flowOriginationTime,
        uint256 _flowRate,
        address _sanContract
    )
        SAN1155(_baseURI)
    {
        name = _name;
        symbol = _symbol;
        contractURI = _contractURI;
        setRoyalties(
            _royaltiesReceiver,
            _royaltiesPercent
        );
        FLOW_ORIGINATION_TIME = _flowOriginationTime;
        FLOW_RATE = _flowRate;
        SAN = ISAN(_sanContract);
    }

    /**
     * @notice Mints SANGA tokens.
     * @param _sanIdsForGold SAN token IDs to be used to mint gold SANGA.
     * @param _sanIdsForColor SAN token IDs to be used to mint color SANGA.
     * @param _sanIdsForMono SAN token IDs to be used to mint monochrome SANGA.
     */
    function mint(
        uint256[] calldata _sanIdsForGold,
        uint256[] calldata _sanIdsForColor,
        uint256[] calldata _sanIdsForMono
    )
        external
    {
        if (saleState == SaleState.Paused) revert SalePhaseNotActive();

        uint256 epoch = _currentEpoch();
        if (epochIsMintable(epoch) == false) revert EpochIsNotMintable(epoch);

        unchecked {
            for (uint i = 0; i < _sanIdsForGold.length; ++i) {
                uint256 tokenId = _sanIdsForGold[i];

                if (!sanTokenIsGold(tokenId))
                    revert TokenIsNotGold(tokenId);

                if (tokenWasUsedInEpoch(epoch, tokenId))
                    revert TokenAlreadyUsedThisEpoch(tokenId);

                if (SAN.ownerOf(tokenId) != _msgSender())
                    revert TokenIsNotOwned(tokenId);

                _setTokenUsedThisEpoch(tokenId);
            }

            for (uint i = 0; i < _sanIdsForColor.length; ++i) {
                uint256 tokenId = _sanIdsForColor[i];

                if (tokenWasUsedInEpoch(epoch, tokenId))
                    revert TokenAlreadyUsedThisEpoch(tokenId);

                if (SAN.ownerOf(tokenId) != _msgSender())
                    revert TokenIsNotOwned(tokenId);

                if (SAN.tokenLevel(tokenId) == SoulboundLevel.Unbound)
                    revert TokenIsNotSoulbound(tokenId);

                _setTokenUsedThisEpoch(tokenId);
            }

            for (uint i = 0; i < _sanIdsForMono.length; ++i) {
                uint256 tokenId = _sanIdsForMono[i];

                if (tokenWasUsedInEpoch(epoch, tokenId))
                    revert TokenAlreadyUsedThisEpoch(tokenId);

                if (SAN.ownerOf(tokenId) != _msgSender())
                    revert TokenIsNotOwned(tokenId);

                _setTokenUsedThisEpoch(tokenId);
            }

            uint256 idCount;
            if (_sanIdsForMono.length > 0) ++idCount;
            if (_sanIdsForColor.length > 0) ++idCount;
            if (_sanIdsForGold.length > 0) ++idCount;

            if (idCount == 1) {
                if (_sanIdsForMono.length > 0) {
                    _mintSimple(currentMonoTokenId(), _sanIdsForMono.length);
                }
                else if (_sanIdsForColor.length > 0) {
                    _mintSimple(currentColorTokenId(), _sanIdsForColor.length);
                }
                else {
                    _mintSimple(currentGoldTokenId(), _sanIdsForGold.length);
                }
            }
            else {
                uint256[] memory ids = new uint256[](idCount);
                uint256[] memory amounts = new uint256[](idCount);
                uint256 curIndex;

                if (_sanIdsForMono.length > 0) {
                    ids[curIndex] = currentMonoTokenId();
                    amounts[curIndex] = _sanIdsForMono.length;
                    ++curIndex;
                }
                if (_sanIdsForColor.length > 0) {
                    ids[curIndex] = currentColorTokenId();
                    amounts[curIndex] = _sanIdsForColor.length;
                    ++curIndex;
                }
                if (_sanIdsForGold.length > 0) {
                    ids[curIndex] = currentGoldTokenId();
                    amounts[curIndex] = _sanIdsForGold.length;
                }

                _mintBatchSimple(ids, amounts);
            }
        }
    }

    /**
     * @notice (only owner) Sets the contract URI for contract metadata.
     * @param _newContractURI The new contract URI.
     */
    function setContractURI(
        string calldata _newContractURI
    )
        external
        onlyOwner
    {
        contractURI = _newContractURI;
    }

    /**
     * @notice (only owner) Sets if an epoch should be skipped (non-mintable).
     * @param _epoch The epoch.
     * @param _isSkipped Whether or not the epoch should be skipped.
     */
    function setEpochSkipped(
        uint256 _epoch,
        bool _isSkipped
    )
        external
        onlyOwner
    {
        epochSkipped[_epoch] = _isSkipped;
    }


    /**
     * @notice (only owner) Sets the saleState to `_newSaleState`.
     * @param _newSaleState The new sale state
     * (0=Paused, 1=Open).
     */
    function setSaleState(
        SaleState _newSaleState
    )
        external
        onlyOwner
    {
        saleState = _newSaleState;
        emit SaleStateChanged(_newSaleState);
    }

    /**
     * @notice (only owner) Sets the token URI for token metadata.
     * @param _newURI The new URI.
     */
    function setURI(
        string calldata _newURI
    )
        external
        onlyOwner
    {
        _setURI(_newURI);
    }

    /**
     * @notice Returns the current minting epoch number.
     * @return epoch_ The current minting epoch number.
     */
    function currentEpoch()
        external
        view
        returns (uint256 epoch_)
    {
        epoch_ = _currentEpoch();
    }

    /**
     * @notice Zeroes out token IDs user already minted with this epoch.
     * @param _sanTokenIds The list of SAN token IDs to check.
     * @return unusedTokenIds_ The token ID list with used ones zeroed out.
     */
    function tokensUnusedThisEpoch(
        uint256[] calldata _sanTokenIds
    )
        external
        view
        returns (uint256[] memory unusedTokenIds_)
    {
        uint256 epoch = _currentEpoch();
        unusedTokenIds_ = new uint256[](_sanTokenIds.length);
        unchecked {
            for(uint i = 0; i < _sanTokenIds.length; ++i) {
                uint256 tokenId = _sanTokenIds[i];
                if (tokenWasUsedInEpoch(epoch, tokenId) == false) {
                    unusedTokenIds_[i] = tokenId;
                }
            }
        }
    }

    /**
     * @notice (only owner) Sets ERC-2981 royalties recipient and percentage.
     * @param _recipient The address to which to send royalties.
     * @param _value The royalties percentage (two decimals, e.g. 1000 = 10%).
     */
    function setRoyalties(
        address _recipient,
        uint256 _value
    )
        public
        onlyOwner
    {
        if (_value > MAX_ROYALTIES_PCT) revert ExceedsMaxRoyaltiesPercentage();

        _setRoyalties(
            _recipient,
            _value
        );
    }

    /**
     * @notice Gets the current Gold SANGA token ID.
     * @return _tokenId The current Gold SANGA token ID.
     */
    function currentGoldTokenId()
        public
        view
        returns (uint256 _tokenId)
    {
        unchecked {
            return 3 + _currentEpoch() * 10;
        }
    }

    /**
     * @notice Gets the current Color SANGA token ID.
     * @return _tokenId The current Color SANGA token ID.
     */
    function currentColorTokenId()
        public
        view
        returns (uint256 _tokenId)
    {
        unchecked {
            return 2 + _currentEpoch() * 10;
        }
    }

    /**
     * @notice Gets the current Mono SANGA token ID.
     * @return _tokenId The current Mono SANGA token ID.
     */
    function currentMonoTokenId()
        public
        view
        returns (uint256 _tokenId)
    {
        unchecked {
            return 1 + _currentEpoch() * 10;
        }
    }

    /**
     * @notice Checks if the current epoch is mintable.
     * @return isMintable_ True if the current epoch is mintable.
     */
    function currentEpochIsMintable()
        public
        view
        returns (bool isMintable_)
    {
        uint256 epoch = _currentEpoch();
        isMintable_ = epochIsMintable(epoch);
    }

    /**
     * @notice Checks if an epoch is mintable.
     * @param _epoch The epoch number to check.
     * @return isMintable_ True if the epoch is mintable.
     */
    function epochIsMintable(
        uint256 _epoch
    )
        public
        view
        returns (bool isMintable_)
    {
        isMintable_ = _epoch > 0 && epochSkipped[_epoch] == false;
    }

    /**
     * @notice Checks if a SAN token ID is a gold character.
     * @param _sanTokenId The SAN token ID to check.
     * @return isGold_ True if the SAN token ID is a gold character.
     */
    function sanTokenIsGold(
        uint256 _sanTokenId
    )
        public
        view
        returns (bool isGold_)
    {
        uint256 bucket = _sanTokenId >> 8;
        uint256 mask = 1 << (_sanTokenId & 0xff);
        isGold_ = sanGoldTokenBitfield[bucket] & mask > 0;
    }

    /**
     * @notice Checks if a SAN token ID has been used to mint in some epoch.
     * @param _epoch The epoch number.
     * @param _sanTokenId The SAN token ID.
     * @return hasBeenUsed_ True if this SAN token ID has minted in the epoch.
     */
    function tokenWasUsedInEpoch(
        uint256 _epoch,
        uint256 _sanTokenId
    )
        public
        view
        returns (bool hasBeenUsed_)
    {
        uint256 bucket = _sanTokenId >> 8;
        uint256 mask = 1 << (_sanTokenId & 0xff);
        hasBeenUsed_ = epochSanUsed[_epoch][bucket] & mask > 0;
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override (SAN1155, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function _setTokenUsedThisEpoch(
        uint256 _sanTokenId
    )
        private
    {
        uint256 bucket = _sanTokenId >> 8;
        uint256 mask = 1 << (_sanTokenId & 0xff);
        epochSanUsed[_currentEpoch()][bucket] |= mask;
    }

    function _currentEpoch()
        private
        view
        returns (uint256 epoch_)
    {
        if (block.timestamp < FLOW_ORIGINATION_TIME) {
            epoch_ = 0;
        }
        else {
            unchecked {
                epoch_ = 1 + (block.timestamp - FLOW_ORIGINATION_TIME) / FLOW_RATE;
            }
        }
    }

    function ___ART_MUST_FLOW___()
        external
        pure
        returns (string memory haiku_)
    {
        haiku_ =
            "cromagnus the name ||| "
            "mystery in his brush strokes ||| "
            "art must always flow";
    }

}