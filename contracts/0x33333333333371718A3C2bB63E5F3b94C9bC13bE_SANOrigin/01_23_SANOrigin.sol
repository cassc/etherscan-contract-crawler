// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./SAN721.sol";
import "./SANSoulbindable.sol";

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
 *                 ██████╗ ██████╗ ██╗ ██████╗ ██╗███╗   ██╗
 *                ██╔═══██╗██╔══██╗██║██╔════╝ ██║████╗  ██║
 *                ██║   ██║██████╔╝██║██║  ███╗██║██╔██╗ ██║
 *                ██║   ██║██╔══██╗██║██║   ██║██║██║╚██╗██║
 *                ╚██████╔╝██║  ██║██║╚██████╔╝██║██║ ╚████║
 *                 ╚═════╝ ╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝
 *                                                     
 * @title SAN Origin | 三 | Soulbindable NFT
 * @author Aaron Hanson <[email protected]> @CoffeeConverter
 * @notice https://sansound.io/
 */
contract SANOrigin is SAN721, SANSoulbindable {

    bytes32 public constant     ___SUNCORE___    =  "Suncore Light Industries";
    bytes32 public constant      ___SANJI___     =  "The Perfect Creation";
    bytes32 public constant       ___SAN___      =  "The Sound of Web3";
    bytes32 public constant        __XIN__       =  keccak256(abi.encodePacked(
    /*                              \???/
                                     \?/
                                      '
    */
                                ___SUNCORE___,
                                 ___SANJI___,
                                  ___SAN___
    ));/*                          __XIN__
                                    \333/
                                     \3/
                                      '
    */
    uint256 public constant       _S_O_R_A_      =  ((((((((0x000e77154)
                                                    << 33 | 0x0de317498)
                                                    << 33 | 0x1d07b6070)
                                                    << 33 | 0x1f061e54f)
                                                    << 33 | 0x14bf0daef)
                                                    << 33 | 0x16635c817)
                                                    << 33 | 0x0ad6c9a0b)
                                                    << 33 | 0x199a0adf2);
    uint256 public constant MAX_LEVEL_FOUR_SOULBINDS =
        uint256(__XIN__) ^ _S_O_R_A_;
    uint256 public levelFourSoulbindsLeft = MAX_LEVEL_FOUR_SOULBINDS;
    bool public soulbindingEnabled;
    mapping(uint256 => SoulboundLevel) public tokenLevel;
    mapping(SoulboundLevel => uint256) public levelPrice;
    mapping(address => uint256) public userSoulbindCredits;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _startingTokenID,
        address _couponSigner,
        string memory _contractURI,
        string memory _baseURI,
        uint256[] memory _levelPrices
    )
        SAN721(
            _name,
            _symbol,
            _startingTokenID,
            _couponSigner,
            _contractURI,
            _baseURI
        )
    {
        levelPrice[SoulboundLevel.One]   = _levelPrices[0];
        levelPrice[SoulboundLevel.Two]   = _levelPrices[1];
        levelPrice[SoulboundLevel.Three] = _levelPrices[2];
        levelPrice[SoulboundLevel.Four]  = _levelPrices[3];
    }

    function soulbind(
        uint256 _tokenID,
        SoulboundLevel _newLevel
    )
        external
        payable
    {
        SoulboundLevel curLevel = tokenLevel[_tokenID];

        if (ownerOf(_tokenID) != _msgSender()) revert TokenNotOwned();
        if (!soulbindingEnabled) revert SoulbindingDisabled();
        if (curLevel >= _newLevel) revert LevelAlreadyReached();

        unchecked {
            uint256 price = levelPrice[_newLevel] - levelPrice[curLevel];
            uint256 credits = userSoulbindCredits[_msgSender()];
            if (credits == 0) {
                if (msg.value != price) revert IncorrectPaymentAmount();
            }
            else if (price <= credits) {
                if (msg.value > 0) revert IncorrectPaymentAmount();
                userSoulbindCredits[_msgSender()] -= price;
            }
            else {
                if (msg.value != price - credits)
                    revert IncorrectPaymentAmount();
                userSoulbindCredits[_msgSender()] = 0;
            }
        }

        if (_newLevel == SoulboundLevel.Four) {
            if (levelFourSoulbindsLeft == 0) revert LevelFourFull();
            unchecked {
                levelFourSoulbindsLeft--;
            }
        }

        tokenLevel[_tokenID] = _newLevel;
        _approve(address(0), _tokenID);

        emit SoulBound(
            _msgSender(),
            _tokenID,
            _newLevel,
            curLevel
        );
    }

    function _The_static_percolates_our_unlit_sky___()
        external pure returns (bytes32 n) {n = hex"734a4e6b3179";}

    function __Still_tension_is_exhausted_by_our_pain___()
        external pure returns (bytes32 m) {m = hex"7068617634696e";}

    function setSoulbindingEnabled(
        bool _isEnabled
    )
        external
        onlyOwner
    {
        soulbindingEnabled = _isEnabled;
        emit SoulbindingEnabled(_isEnabled);
    }

    function ___As_a_warm_purr_prepares_to_amplify___()
        external pure returns (bytes32 l) {l = hex"614a6d31706c6956664479";}

    function ____Our_apprehensions_cross_a_sonic_plane___()
        external pure returns (bytes32 k) {k = hex"706e6c61666e7265";}

    function addUserSoulbindCredits(
        address[] calldata _accounts,
        uint256[] calldata _credits
    )
        external
        onlyOwner
    {
        unchecked {
            uint256 maxCredit = levelPrice[SoulboundLevel.Three];
            for (uint i; i < _accounts.length; i++) {
                if (_credits[i] > maxCredit) revert InvalidSoulbindCredit();
                userSoulbindCredits[_accounts[i]] += _credits[i];
            }
        }
    }

    function _____Initiating_first_transmissions_now___()
        external pure returns (bytes32 j) {j = hex"6e46466f5777";}

    function ______At_last_our_pitch_black_planet_twinkles_to___()
        external pure returns (bytes32 i) {i = hex"744a4c6f6f";}

    function setLevelPrices(
        uint256[] calldata _newPrices
    )
        external
        onlyOwner
    {
        if (_newPrices.length != 4) revert InvalidNumberOfLevelPrices();

        unchecked {
            uint256 previousPrice;
            for (uint i; i < 4; i++) {
                if (_newPrices[i] <= previousPrice)
                    revert LevelPricesNotIncreasing();
                levelPrice[SoulboundLevel(i + 1)] = _newPrices[i];
                previousPrice = _newPrices[i];
            }
        }
    }

    function _______We_waited_for_permission_to_avow___()
        external pure returns (bytes32 h) {h = hex"6132766f4c3577";}

    function ________That_seizing_silence_take_an_altered_hue___()
        external pure returns (bytes32 g) {g = hex"686145756e65";}

    function userMaxSoulboundLevel(
        address _owner
    )
        external
        view
        returns (SoulboundLevel)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return SoulboundLevel.Unbound;

        SoulboundLevel userMaxLevel;
        unchecked {
            for (uint i; i < tokenCount; i++) {
                SoulboundLevel level =
                    tokenLevel[tokenOfOwnerByIndex(_owner, i)];
                if (level > userMaxLevel) userMaxLevel = level;
            }
        }
        return userMaxLevel;
    }

    function _________Baptized_to_the_tune_of_our_refound_rite___()
        external pure returns (bytes32 f) {f = hex"72694a74345665";}

    function __________Though_mute_shade_has_reborn_our_infancy___()
        external pure returns (bytes32 e) {e = hex"696e516678616e63546779";}

    function tokenURI(
        uint256 _tokenID
    )
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenID)) revert TokenDoesNotExist();
        if (!isRevealed) return baseURI;
        return string(
            abi.encodePacked(
                baseURI,
                Strings.toString(uint256(tokenLevel[_tokenID])),
                "/",
                Strings.toString(_tokenID),
                ".json"
            )
        );
    }

    function ___________We_rise_from_ruins_of_eternal_night___()
        external pure returns (bytes32 d) {d = hex"6e4869674c683174";}

    function ____________Saved_solely_by_Suncore_Light_Industry___()
        external pure returns (bytes32 c) {c = hex"496e4d7364754c7374727779";}

    function approve(
        address to,
        uint256 tokenId
    )
        public
        override(IERC721, ERC721)
    {
        if (tokenLevel[tokenId] > SoulboundLevel.Unbound)
            revert CannotApproveSoulboundToken();
        super.approve(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override
    {
        if (tokenLevel[tokenId] > SoulboundLevel.Unbound)
            revert CannotTransferSoulboundToken();
        super._beforeTokenTransfer(from, to, tokenId);
    }

/*33333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333KAKUBERRY33333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333CROMAGNUS33333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333333333
333333333333333333333333333333333333IMCMPLX333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333xc,''''''''''''''''''''';d3333333333333333333333333
33333333333333333333333333xc.                      .:x3333333333333333333333333
333333333333333333333333x:.                      .:x333333333333333333333333333
3333333333333333333333xc.                      .:x33333333333333333333333333333
333333333333333333333l.                      .:x3333333333333333333333333333333
333333333333333333333;                     .:x33xccx333333333333333333333333333
333333333333333333333;                   .:x33d;.  .:x3333333333333333333333333
333333333333333333333;                .':x33d;.      .:x33333333333333333333333
333333333333333333333:              .:x333d;.          .:x333333333333333333333
333333333333333333333x;.          .:x333x;.              c333333333333333333333
33333333333333333333333d;.      .:x33d;'.                :333333333333333333333
3333333333333333333333333d;.  .:x33x;.                   :333333333333333333333
333333333333333333333333333dccx33x;.                     :333333333333333333333
3333333333333333333333333333333x;.                      .3333333333333333333333
33333333333333333333333333333d;.                      .ck3333333333333333333333
333333333333333333333333333x:.                      .ck333333333333333333333333
3333333333333333333333333x:.                      .cx33333333333333333333333333
3333333333333333333333333l,,,,,,,,,,,,,,,,,,,,,,,cx3333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333THE33333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333SOUND3333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333OF333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333WEB33333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333THREE3333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333*/

    function _____________FOR_YEARS_OUR_SENSES_WERE_UNDER_ATTACK___()
        external pure returns (bytes32 DIC) {DIC = hex"4150545054704143514b";}

    function ______________UNTIL_NEW_SENSORS_WERE_TRANSPORTED_BACK___()
        external pure returns (bytes32 sfpi) {sfpi = hex"4250416d43514b";}

}//                             三