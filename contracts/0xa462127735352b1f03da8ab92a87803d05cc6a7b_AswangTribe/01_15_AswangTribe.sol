// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "../Augminted/ERC721ABase.sol";
import "./IDugo.sol";

error AswangTribe_EggAlreadyHatched();
error AswangTribe_InvalidTokenId();
error AswangTribe_PrayingDisabled();
error AswangTribe_SenderNotTokenOwner();
error AswangTribe_TokenPraying();
error AswangTribe_TokenNotPraying();

/**                                                      .,,,,.
                                                        ,l;..,l;.
                                                      .co,    ,ol.
                                                     ;do'.'::'..ox;.
                                                   .cxl..:xOOk:..cxc.
                                                  .dk:. ;xxc:dk;  ;xd,
                                                 ,xx;  'xk;. 'xx,  'dx;
                                                ;xd,  .dOxc;,;oOx.  .okc.
                                              .cko.  .oOo'.   .c0o.  .lkl.
                                             .okc.  .:kx,      .dkc.   ;xd,
                                            ;xd,     ..          ..     'okc.
                                          .lOo.                          .lko.
                                         .oOl.                             :Od'
                                        .dOc.                               ;kx'
                                       ,xk;         ...'',,,,,,''...         ,xk;
                                     .:xx'   ..';:coodddddddddoddoollc:;'.    .okl.
                                    .okl.   ..''.....               ....''..    :kk,
                                  .:O0c            ..,:loxkkxxkkdl:,..           'xOc.
                                 .o0k;        .,:oxkkkkxoooooodxkO00Okxoc,..      .o0x.
                                ,k0o.     .;ldxdoc;'....',,;;;;,....,:lxOOOko:,.    :0O;
                              .cOO:.   .:odo:'.     'cdoc:,,,;:lloc'    .':oxOOxc,.  ,kKl.
                             .dX0;  .:ooc'.       'lxd;.         'lko'      .'cxOOxc' .xXk'
                            ;OKd'.'oxl'          ;dxc.    .''.     ,xk:        .'cxOkl'.lK0:
                          .oK0:.'okl.           ,xk:.   .ldlldc.    'xk;          .,okxc';OXd.
                         'kXx'.cxl.            .oOd.   .ck:  ,xl.   .lOd.            ,oxl''xXO,
                        ;0Kl..cl'              .dOo.   .oO:  ,kx.    cOx,             .'cc..lKK:
                      .cKKo;cdo.               .l0x'    .ol;,lx:.   .d0d'               .cdc':0Xo.
                     .dX0c.oKXO:.               'x0l.     .....    .lOOc.               .xK0o.'xXx.
                    ;OXk;  .:k0Oo;.              ;OKd'            'd00o.              .:xxl;'  .lKO:
                  .oKKo.     .;okOko;.            'oOOd:'......,cx0KOl.            .;oxo;.       'xKo.
                 'xXO:        ..'cxO0Odc,.          .,:lddxxkxkkkdc,.          .'cxxd:...         .c0k'
                ;0Xx'      .;c;.  .':ok00Odl;'.           ......          ..;ldkxo;.  .lko,         ,O0;
              .cKXd.     .:dl'        .';ldk00Oxoc;,...            ..,;coxkkxl;..      .;xko,        'kKl.
             .oKKl.     ,oo,      .:;      .';lxkO00Okkxdoc:;:clodxOOOkoc;..   ,;.       .;dxc.       .dKx.
            ,kKO:.     .;'       'oo.           ..',::codkkxxkxdlc:,...        ;xx;         '::.       .lKO;
          .c0Xk,                'ol.      'l,                        .:c.       'oko.                    ;OKl.
         .oKKo. ..             .:;.      'dc.     .;;       .;,       ;xl.       .;xd,                ..  'xXd.
        .xX0c. .dk:            ..       .:c.      ;xc      .,dk.       cOl.        .,:.              :Ok,  .oKk'
       'kXO:  :Okc;.                    .'.      .ld'       .l0:       .cx:                          ;cdkc.  cKO;
      ;0XO; .dXx.                                .;;         'ko.        ,:.                           .xKx'  ;0Kc.
     cKXx'.;O0dl'    .                                        ;;                                  ..   :dldkc. 'kKo.
   .oXXd..oKO:.cd:,;cdl.                                                                        .lko;;oOo''oOd' .dKd.
  .dX0l. :OOdoloxdlc;,:'                                                                        .:;,:ldxolllxOl. .lKx.
 'xXO:.  ........                                                                                        ......   .c0k'
'OWNOoccccccccccc:c::::::;;;;,,,;;;,,,,,,,,;,,,,,,,;;,,,'''''''',,,,;;;;,,,,,;;,;;;;;;;;;;;:::::;::cccccccllccllllodONO'
:XWWWNXK00OO00000000000000OOOOOOO00OOOOO00000000000000KXXXXXXXXXKK00000000OO0O000OOOOOOOOOOOO000OOOO000OOOOOOOO00KXNNWNd

 * @title Aswang Tribe
 * @author Augminted Labs, LLC
 */
contract AswangTribe is ERC721ABase {
    event StartPraying(uint256 indexed tokenId);
    event StopPraying(uint256 indexed tokenId);
    event Summon(uint256 indexed tokenId);
    event Hatch(uint256 indexed tokenId);

    struct TokenInfo {
        uint64 prayingStartedAt;
        uint64 totalTimePraying;
        bool hatched;
    }

    uint256 public constant MAX_SUPPLY = 6666;
    uint256 public constant SUMMONING_COST = 900 ether;
    uint256[7] public RANK_DURATIONS;

    IDugo public Dugo;
    bool public prayingEnabled;
    string public genesisURI;
    string public manananggalURI;
    mapping(uint256 => TokenInfo) public tokenInfo;

    constructor(
        address signer,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subId
    )
        ERC721ABase(
            "AswangTribe",
            "ASWANG",
            3333,
            vrfCoordinator
        )
    {
        setMintConfig(MintConfig({
            price: 0.1 ether,
            maxPerAddress: 0,
            signer: signer
        }));

        setVrfRequestConfig(VrfRequestConfig({
            keyHash: keyHash,
            subId: subId,
            callbackGasLimit: 200000,
            requestConfirmations: 3
        }));

        RANK_DURATIONS = [30 days, 90 days, 180 days, 365 days, 1095 days, 12045 days, 121545 days];
        prayingEnabled = true;
    }

    /**
     * @notice Metadata URI for specified token
     * @param tokenId Token to return metadata URI of
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (revealed) {
            return string(abi.encodePacked(
                tokenId < MAX_MINTABLE ? genesisURI : manananggalURI,
                _toString(rank(tokenId)),
                "/",
                _toString(tokenId))
            );
        } else {
            return metadata.placeholderURI;
        }
    }

    /**
     * @notice Current rank of token, based on how long it's been !praying
     * @param tokenId Token to return rank of
     */
    function rank(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (tokenInfo[tokenId].prayingStartedAt == 0) return 0;

        uint256 durationPraying = block.timestamp - tokenInfo[tokenId].prayingStartedAt;
        for (uint256 i; i < RANK_DURATIONS.length; ++i) {
            if (RANK_DURATIONS[i] > durationPraying) return i;
        }

        return RANK_DURATIONS.length;
    }

    /**
     * @notice Time the token started !praying
     * @param tokenId Token to return info for
     */
    function prayingStartedAt(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return tokenInfo[tokenId].prayingStartedAt;
    }

    /**
     * @notice Total time the token has spent !praying
     * @param tokenId Token to return info for
     */
    function totalTimePraying(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return tokenInfo[tokenId].totalTimePraying;
    }

    /**
     * @notice If the token has been hatched (only applies to Manananggal tokens)
     * @param tokenId Token to return info for
     */
    function hatched(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return tokenInfo[tokenId].hatched;
    }

    /**
     * @notice Set a new $DUGO contract
     * @param dugo New $DUGO contract
     */
    function setDugo(IDugo dugo) external lockable onlyOwner {
        Dugo = dugo;
    }

    /**
     * @notice Update base token URI for genesis tokens
     * @param uri New base token URI
     */
    function setGenesisURI(string calldata uri) external lockable onlyOwner {
        genesisURI = uri;
    }

    /**
     * @notice Update base token URI for Manananggal tokens
     * @param uri New base token URI
     */
    function setManananggalURI(string calldata uri) external lockable onlyOwner {
        manananggalURI = uri;
    }

    /**
     * @notice Flip between praying being enabled or disabled
     */
    function flipPrayingEnabled() external lockable onlyOwner {
        prayingEnabled = !prayingEnabled;
    }

    /**
     * @notice Mint a specified amount of tokens to specified receivers
     * @param receivers Receivers of the airdrop
     * @param amounts Amounts of tokens to airdrop for corresponding receivers
     */
    function airdrop(address[] calldata receivers, uint256[] calldata amounts) external lockable onlyOwner {
        for (uint256 i; i < receivers.length;) {
            _mint(receivers[i], amounts[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Mint a specified amount of tokens using a signature
     * @param amount Amount of tokens to mint
     * @param signature Ethereum signed message, created by `signer`
     */
    function mint(uint256 amount, uint256 max, bytes memory signature) public payable {
        if (msg.value != mintConfig.price * amount) revert ERC721ABase_InvalidValue();
        if (_numberMinted(_msgSender()) + amount > max) revert ERC721ABase_ExceedsMaxPerAddress();
        if (mintConfig.signer != ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_msgSender(), max))),
            signature
        )) revert ERC721ABase_InvalidSignature();

        _mint(amount);
    }

    /**
     * @dev Override to force use of the above mint function
     */
    function mint(uint256 amount, bytes memory signature) public override payable {
        mint(amount, amount, signature);
    }

    /**
     * @notice Start !praying
     * @param tokenIds Tokens to start !praying
     */
    function startPraying(uint256[] calldata tokenIds) external {
        if (!prayingEnabled) revert AswangTribe_PrayingDisabled();

        for (uint256 i; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];

            if (ownerOf(tokenId) != _msgSender()) revert AswangTribe_SenderNotTokenOwner();
            if (tokenInfo[tokenId].prayingStartedAt != 0) revert AswangTribe_TokenPraying();

            tokenInfo[tokenId].prayingStartedAt = uint64(block.timestamp);

            emit StartPraying(tokenId);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Stop !praying
     * @param tokenIds Tokens to stop !praying
     */
    function stopPraying(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];

            if (ownerOf(tokenId) != _msgSender()) revert AswangTribe_SenderNotTokenOwner();
            if (tokenInfo[tokenId].prayingStartedAt == 0) revert AswangTribe_TokenNotPraying();

            if (address(Dugo) != address(0)) Dugo.claim(_msgSender(), tokenId);

            tokenInfo[tokenId].totalTimePraying += uint64(block.timestamp - tokenInfo[tokenId].prayingStartedAt);
            tokenInfo[tokenId].prayingStartedAt = 0;

            emit StopPraying(tokenId);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Summon a Manananggal egg
     * @param tokenId Genesis token currently !praying
     * @param amount Amount of Manananggal eggs to summon
     */
    function summon(uint256 tokenId, uint256 amount) external {
        if (tokenId >= MAX_MINTABLE) revert AswangTribe_InvalidTokenId();
        if (ownerOf(tokenId) != _msgSender()) revert AswangTribe_SenderNotTokenOwner();
        if (tokenInfo[tokenId].prayingStartedAt == 0) revert AswangTribe_TokenNotPraying();
        if (_totalMinted() + amount > MAX_SUPPLY) revert ERC721ABase_InsufficientSupply();

        Dugo.burn(_msgSender(), SUMMONING_COST * amount);

        for (uint256 i; i < amount;) {
            emit Summon(_nextTokenId() + i);
            unchecked { ++i; }
        }

        _mint(_msgSender(), amount);
    }

    /**
     * @notice Hatch a Manananggal eggs, revealing traits
     * @param tokenIds Manananggal eggs to hatch
     */
    function hatch(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];

            if (tokenId < MAX_MINTABLE) revert AswangTribe_InvalidTokenId();
            if (ownerOf(tokenId) != _msgSender()) revert AswangTribe_SenderNotTokenOwner();
            if (tokenInfo[tokenId].hatched) revert AswangTribe_EggAlreadyHatched();

            tokenInfo[tokenId].hatched = true;

            emit Hatch(tokenId);
            unchecked { ++i; }
        }
    }

    /**
     * @inheritdoc ERC721A
     * @dev Cannot transfer while token is !praying
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(IERC721A, ERC721A)
    {
        if (tokenInfo[tokenId].prayingStartedAt != 0) revert AswangTribe_TokenPraying();

        ERC721A.transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc ERC721A
     * @dev Cannot transfer while token is !praying
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(IERC721A, ERC721A)
    {
        if (tokenInfo[tokenId].prayingStartedAt != 0) revert AswangTribe_TokenPraying();

        ERC721A.safeTransferFrom(from, to, tokenId, data);
    }
}