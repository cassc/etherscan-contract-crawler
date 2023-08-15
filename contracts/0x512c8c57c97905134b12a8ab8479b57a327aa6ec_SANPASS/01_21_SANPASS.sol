//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**                       ███████╗ █████╗ ███╗   ██╗
 *                        ██╔════╝██╔══██╗████╗  ██║
 *                        ███████╗███████║██╔██╗ ██║
 *                        ╚════██║██╔══██║██║╚██╗██║
 *                        ███████║██║  ██║██║ ╚████║
 *                        ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝
 *
 *                              █████████████╗
 *                              ╚════════════╝
 *                               ███████████╗
 *                               ╚══════════╝
 *                            █████████████████╗
 *                            ╚════════════════╝
 *
 *                     ██████╗  █████╗ ███████╗███████╗
 *                     ██╔══██╗██╔══██╗██╔════╝██╔════╝
 *                     ██████╔╝███████║███████╗███████╗
 *                     ██╔═══╝ ██╔══██║╚════██║╚════██║
 *                     ██║     ██║  ██║███████║███████║
 *                     ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝
 */

import "./token/ERC2981ContractWideRoyalties.sol";
import "./token/TokenRescuer.sol";
import "./ISAN.sol";
import "./ISANPASS.sol";
import "./SAN1155Burnable.sol";
import "./SANMetadata.sol";
import "./SANSoulbindable.sol";

/**
 * @title SAN Concert Pass
 * @author Aaron Hanson <[email protected]> @CoffeeConverter
 * @notice https://sansound.io
 */
contract SANPASS is
    ISANPASS,
    SAN1155Burnable,
    ERC2981ContractWideRoyalties,
    TokenRescuer,
    SANMetadata,
    SANSoulbindable
{
    uint256 public constant MAX_ROYALTIES_PCT = 333; // 3.33%

    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    uint256 private constant MaskChi   = 1<<0;
    uint256 private constant MaskUmi   = 1<<1;
    uint256 private constant MaskSora  = 1<<2;
    uint256 private constant MaskMecha = 1<<3;

    ISAN public immutable SAN;

    string public contractURI;

    SaleState public saleState;

    mapping(address => factionCredits) public userFactionCredits;

    constructor(
        string memory _contractURI,
        string memory _baseURI,
        address _royaltiesReceiver,
        uint256 _royaltiesPercent,
        address _sanContract
    )
        SAN1155(_baseURI)
    {
        contractURI = _contractURI;
        setRoyalties(
            _royaltiesReceiver,
            _royaltiesPercent
        );
        SAN = ISAN(_sanContract);
    }

    /**
     * @notice Mints SANPASS tokens by burning SAN Origin tokens.
     * @param _tokenIds The list of SAN Origin tokens to burn.
     */
    function mintPasses(
        uint256[] calldata _tokenIds
    )
        external
    {
        if (saleState != SaleState.Open) revert SaleStateNotActive();

        factionCredits memory credits = userFactionCredits[_msgSender()];

        unchecked {
            for (uint i; i < _tokenIds.length; ++i) {
                uint256 factions = sanTokenFactions(_tokenIds[i]);
                if (factions == 0) ++credits.none;
                else if (0 < factions & MaskMecha) ++credits.mecha;
                else {
                    if (0 < factions & MaskChi) ++credits.chi;
                    if (0 < factions & MaskUmi) ++credits.umi;
                    if (0 < factions & MaskSora) ++credits.sora;
                }
            }
        }

        unchecked {
            uint256 mintChi = credits.chi / 3;
            uint256 mintUmi = credits.umi / 3;
            uint256 mintSora = credits.sora / 3;
            uint256 mintMecha = credits.mecha / 3;
            uint256 mintNone = credits.none / 3;
            uint256 idCount = (mintChi == 0 ? 0 : 1) + (mintUmi == 0 ? 0 : 1) +
                (mintSora == 0 ? 0 : 1) + (mintMecha == 0 ? 0 : 1) +
                (mintNone == 0 ? 0 : 1);
            if (1 == idCount) {
                if (mintChi != 0) {
                    _mintSimple(_msgSender(), uint256(Id.Chi), mintChi);
                    credits.chi = credits.chi % 3;
                }
                else if (mintUmi != 0) {
                    _mintSimple(_msgSender(), uint256(Id.Umi), mintUmi);
                    credits.umi = credits.umi % 3;
                }
                else if (mintSora != 0) {
                    _mintSimple(_msgSender(), uint256(Id.Sora), mintSora);
                    credits.sora = credits.sora % 3;
                }
                else if (mintMecha != 0) {
                    _mintSimple(_msgSender(), uint256(Id.Mecha), mintMecha);
                    credits.mecha = credits.mecha % 3;
                }
                else {
                    _mintSimple(_msgSender(), uint256(Id.None), mintNone);
                    credits.none = credits.none % 3;
                }
            }
            else if (1 < idCount) {
                uint256[] memory ids = new uint256[](idCount);
                uint256[] memory amounts = new uint256[](idCount);
                uint256 curIndex;
                if (mintChi != 0) {
                    ids[curIndex] = uint256(Id.Chi);
                    amounts[curIndex++] = mintChi;
                    credits.chi = credits.chi % 3;
                }
                if (mintUmi != 0) {
                    ids[curIndex] = uint256(Id.Umi);
                    amounts[curIndex++] = mintUmi;
                    credits.umi = credits.umi % 3;
                }
                if (mintSora != 0) {
                    ids[curIndex] = uint256(Id.Sora);
                    amounts[curIndex++] = mintSora;
                    credits.sora = credits.sora % 3;
                }
                if (mintMecha != 0) {
                    ids[curIndex] = uint256(Id.Mecha);
                    amounts[curIndex++] = mintMecha;
                    credits.mecha = credits.mecha % 3;
                }
                if (mintNone != 0) {
                    ids[curIndex] = uint256(Id.None);
                    amounts[curIndex] = mintNone;
                    credits.none = credits.none % 3;
                }
                _mintBatchSimple(_msgSender(), ids, amounts);
            }
        }

        userFactionCredits[_msgSender()] = credits;
        SAN.batchTransferFrom(_msgSender(), BURN_ADDRESS, _tokenIds);
        emit Sacrifice(_msgSender());
    }

    /**
     * @notice (only owner) Mints VIP tokens to a list of recipients.
     * @param _recipients The list of token recipients.
     * @param _amounts The list of token amounts.
     */
    function airdropVIP(
        address[] calldata _recipients,
        uint256[] calldata _amounts
    )
        external
        onlyOwner
    {
        if (_recipients.length != _amounts.length) revert ArrayLengthMismatch();
        unchecked {
            for (uint i; i < _recipients.length; ++i) {
                _mintSimple(
                    _recipients[i],
                    uint256(Id.VIP),
                    _amounts[i]
                );
            }
        }
    }

    /**
     * @notice (only owner) Mints Redvoxx tokens to a list of recipients.
     * @param _recipients The list of token recipients.
     * @param _amounts The list of token amounts.
     */
    function airdropRedvoxx(
        address[] calldata _recipients,
        uint256[] calldata _amounts
    )
        external
        onlyOwner
    {
        if (_recipients.length != _amounts.length) revert ArrayLengthMismatch();
        unchecked {
            for (uint i; i < _recipients.length; ++i) {
                _mintSimple(
                    _recipients[i],
                    uint256(Id.Redvoxx),
                    _amounts[i]
                );
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
     * @notice Looks up all factions for a SAN token ID.
     * @param _sanTokenId The SAN token ID to check.
     * @return factions_ Bitfield of five bits indication the factions.
     */
    function sanTokenFactions(
        uint256 _sanTokenId
    )
        public
        view
        returns (uint256 factions_)
    {
        uint256 bucket = _sanTokenId >> 6;
        factions_ = sanFactions[bucket] >> ((_sanTokenId & 63) * 4) & 0xf;
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

    string[119] public _takeThisEngineerMayItServeYouWell = [
        "201110", "010110", "000110", "012010", "210100", "220110", "120110",
        "001110", "100110", "210100", "220110", "020110", "121010", "210100",
        "102010", "200110", "121010", "210100", "002010", "022010", "120110",
        "001110", "100110", "210100", "202010", "001110", "020110", "220110",
        "101000", "010110", "112010", "210100", "120110", "100110", "212010",
        "220110", "111110", "212010", "020110", "210100", "202010", "020110",
        "202010", "212010", "201110", "210100", "102010", "202010", "002010",
        "022010", "012010", "022010", "020110", "002010", "121010", "120110",
        "101000", "100110", "020110", "121010", "201110", "120110", "210100",
        "002010", "022010", "220110", "110110", "111110", "020110", "002010",
        "210100", "121010", "210100", "202010", "200110", "022010", "201110",
        "220110", "200110", "202010", "210100", "120110", "202010", "220110",
        "010110", "200110", "101000", "100110", "020110", "010110", "012010",
        "120110", "200110", "121010", "020110", "220110", "210100", "120110",
        "200110", "010110", "022010", "220110", "002010", "121010", "012010",
        "210100", "000110", "000110", "121010", "210100", "012010", "010110",
        "210100", "120110", "220110", "120110", "121010", "202010", "221010"
    ];
}