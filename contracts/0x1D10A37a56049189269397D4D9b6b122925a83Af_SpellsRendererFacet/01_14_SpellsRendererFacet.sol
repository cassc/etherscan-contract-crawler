// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

import "./shared/access/CallProtection.sol";
import "../libraries/LibDiamond.sol";
import "../../coin/ISpellsCoin.sol";
import "../../helpers/Base64.sol";
import '../../helpers/SVG.sol';
import '../../helpers/Utils.sol';

import "./SpellsCastStorage.sol";
import "./SpellsStorage.sol";

library SpellsRendererStorage {
    bytes32 constant SPELLS_RENDER_STORAGE_POSITION =
        keccak256("spells.render.location");

    struct Storage {
        string[] kind;
        string[] element;
        string[] spell;
        string[] prefixes;
        string[] suffixes;
        string[][] gods;
        string[] demigods;
        string[] sigils;
        string[] gateSigils;
        string[][] legendarySigils;
        string[] words;
        string[] spellsCoins;
    }

    function getStorage() internal pure returns (Storage storage es) {
        bytes32 position = SPELLS_RENDER_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

contract SpellsRendererFacet is CallProtection {

    function initializeSpellsRendererFacet(
        string[] memory kinds,
        string[] memory elements,
        string[] memory spells,
        string[] memory prefixes,
        string[] memory suffixes
    ) external protectedCall {
        SpellsRendererStorage.Storage storage es = SpellsRendererStorage
            .getStorage();
        es.kind = kinds;
        es.element = elements;
        es.spell = spells;
        es.prefixes = prefixes;
        es.suffixes = suffixes;
        es.gods = [
            [
                "Anu the Builder",
                "Iluvatar",
                "Manwe",
                "Tathamet",
                "Ytar",
                "Tyre",
                "Dalaran"
            ],
            [
                "Morvian the Bold",
                "Alatar",
                "Si'mar",
                "Vehari",
                "Masiara",
                "Lorien",
                "Vana"
            ],
            [
                "Sarlon the Lost",
                "Iluvatar",
                "Golrag",
                "Ishnak",
                "Rrazul",
                "Melkor",
                "Skoll"
            ],
            [
                "Graardor the Broken",
                "Torva",
                "Ilmare",
                "Jaharra",
                "Tamfana",
                "Kree'arra",
                "Vyr"
            ],
            [
                "Zathmet the Destroyer",
                "K'ril Tsutsaroth",
                "General Zilyana",
                unicode"Æschere",
                "Hunferth",
                "Tulkas",
                "Araw"
            ]
        ];

        // 7
        es.demigods = [
            "Fazurah the Child",
            "Shanar of Vyr",
            "Frydehr",
            "Othmec",
            "Hashir",
            "Nemoc",
            "Jin"
        ];

        es.sigils = [
            unicode"✿",
            unicode"߷",
            unicode"✜",
            unicode"⏾",
            unicode"☍",
            unicode"⬨",
            unicode"♖"
        ];

        es.gateSigils = [
            unicode"⍝",
            unicode"𝇉",
            unicode"Ж",
            unicode"ບ",
            unicode"➶"
        ];

        es.legendarySigils = [
            [unicode"✹", unicode"❋"],
            [unicode"ҹ", unicode"⌻"],
            [unicode"𝄐", unicode"✝"],
            [unicode"Њ", unicode"🗠"],
            [unicode"⋎", unicode"⋏"],
            [unicode"⋔", unicode"⎛"]
        ];

        es.words = [
            unicode"ada",
            unicode"aeilin",
            unicode"avari",
            unicode"barad",
            unicode"brith",
            unicode"dolоros",
            unicode"calmїt",
            unicode"cú",
            unicode"dоl",
            unicode"duin",
            unicode"ú",
            unicode"elenya",
            unicode"er",
            unicode"ethuїl",
            unicode"ẛorn",
            unicode"goḷin",
            unicode"giḷ",
            unicode"ḿiṅas",
            unicode"naḷ",
            unicode"ṅumen",
            unicode"noc",
            unicode"orodruїn",
            unicode"par",
            unicode"sїlan",
            unicode"quendi",
            unicode"tiṅ",
            unicode"thalias",
            unicode"vоs",
            unicode"sin",
            unicode"cоs"
        ];
        
        es.spellsCoins = [
            unicode"․",
            unicode"․",
            unicode"․",
            unicode"․",
            unicode"∴",
            unicode"∴",
            unicode"∴",
            unicode"`",
            unicode"`",
            unicode"ҹ",
            unicode"⁕",
            unicode"º"
        ];
    }
    
    function _seed(uint256 tokenId) internal view returns(uint256) {
        return SpellsStorage.tokenSeed(tokenId);
    }
    
    function _faction(uint256 tokenId) internal view returns(uint256) {
        return SpellsCastStorage.getStorage().factions[tokenId];
    }
    
    function _spellsCoin(uint256 tokenId) internal view returns(uint256) {
        return SpellsCastStorage.getStorage().spellsCoin.balanceOf(
            address(this),
            tokenId
        ) / (1e9 gwei);
    }
    
    uint256 constant xunit = 368 / 16; // 23
    uint256 constant yunit = 320 / 16; // 20
    
     function _getSpellsCoinCanvas(uint256 tokenId, uint256 n)
        internal
        view
        returns (string memory)
    {
        string memory output;
        uint256 rand = random(utils.uint2str(tokenId));
        if (n > 33) {
            n = 33;
        }
        uint256 i;
        uint256 j;
        SpellsRendererStorage.Storage storage es = SpellsRendererStorage
            .getStorage();
        uint256[256] memory _chars;
        for (i = 0; i < n; i++) {
            if (_chars[rand % 256] <= 0) {
                _chars[rand % 256] = (rand % es.spellsCoins.length) + 1;
            } else {
                i--;
            }
            rand = rand / (i + 3);
        }
        uint256 charidx;
        for (i = 0; i < 16; i++) {
            for (j = 0; j < 16; j++) {
                charidx = _chars[i * 16 + j];
                if (charidx > 0) {
                    output = string.concat(
                        output,
                        svg.text(
                            string.concat(
                                svg.prop('x', utils.uint2str(i * xunit + 11 + (rand % xunit))),
                                svg.prop('y', utils.uint2str(j * yunit + 18 + (rand * 3 % yunit))),
                                svg.prop('class', 'base chant spellsCoin'),
                                svg.prop('opacity', string.concat('0.', utils.uint2str(rand % 5 + 4)))
                            ),
                            es.spellsCoins[charidx - 1]
                        )
                    );
                    rand += (i * j + j + 1);
                }
            }
        }
        return output;
    }
    
    
    function _getSpell(uint256 tokenId)
        internal
        view
        returns (
            string memory title,
            string memory sigil,
            string[3] memory chant
        )
    {
        SpellsRendererStorage.Storage storage es = SpellsRendererStorage
            .getStorage();
        uint256 rand = _seed(tokenId);
        uint256 _kind = rand % 3;
        uint256 greatness = rand % 21;
        uint256 faction = _faction(tokenId);
        if (_kind < 1) {
            title = string.concat(
                    es.element[rand % es.element.length],
                    " ",
                    es.spell[rand % es.spell.length]
            );
        } else {
            title = string.concat(
                    es.kind[rand % es.kind.length],
                    " ",
                    es.spell[rand % es.spell.length]
            );
        }

        if (greatness > 14 && greatness % 3 != 0) {
            title = string.concat(
                    es.prefixes[rand % es.prefixes.length],
                    " ",
                    title
                );
        }
        if (greatness >= 16 && greatness % 2 == 0) {
            title = string.concat(
                    title,
                    " ",
                    es.suffixes[rand % es.suffixes.length]
            );
        }
        sigil = es.sigils[rand % es.sigils.length];
        if (faction > 0) {
            sigil = es.gateSigils[faction - 1];
            rand = rand / 3;
            title = string(
                abi.encodePacked(
                    es.gods[faction - 1][
                        rand % es.gods[faction - 1].length
                    ],
                    "'s ",
                    title
                )
            );
        }
        if (greatness >= 18 && rand % 2 == 0) {
            if (faction == 0) {
                rand = rand / 3;
                title = string(
                    abi.encodePacked(
                        es.demigods[rand % es.demigods.length],
                        "'s ",
                        title
                    )
                );
            }
            if (greatness == 20) {
                sigil = es.legendarySigils[faction][1];
            } else {
                sigil = es.legendarySigils[faction][0];
            }
        }

        rand = random(title);
        uint256 n = 0;
        if (greatness > 16) {
            n = 5;
        }
        n = (rand % 7) + 4 + n;
        uint256 i = 0;
        uint256 offset = 0;
        for (i = 0; i < n; i++) {
            rand = rand / (i + 1);
            offset = i / 5;
            if (bytes(chant[offset]).length == 0) {
                chant[offset] = es.words[rand % es.words.length];
            } else {
                chant[offset] = string.concat(
                        chant[offset],
                        " ",
                        es.words[rand % es.words.length]
                );
            }
        }
        return (title, sigil, chant);
    }
    
    string constant private insetX = '14';
    
    function render(uint256 tokenId) public view returns (string memory) {
        string memory name;
        string memory sigil;
        string[3] memory incantation;
        (name, sigil, incantation) = _getSpell(tokenId);

        uint256 spellsCoinAmount = _spellsCoin(tokenId);
        string memory spellsCoinRows = _getSpellsCoinCanvas(
            tokenId,
            spellsCoinAmount / 10
        );
        string memory headerRows = '';
        uint256 y = 50;
        uint256 i;
        for (i = 0; i < incantation.length; i++) {
            headerRows = string.concat(
                headerRows,
                svg.text(
                    string.concat(
                        svg.prop('x', insetX),
                        svg.prop('y', utils.uint2str(y + 20 * i)),
                        svg.prop('opacity', '0.85'),
                        svg.prop('class', 'base chant')
                    ),
                    string.concat(
                       incantation[i]
                    )
                )
            );
        } 
        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 350">',
            '<style>.base { fill: lightyellow; font-family: serif } .title{ font-size: 14px;} .balance {font-size:13px} .chant { font-style: italic; font-size:14px} .spellsCoin {font-size: 6px;}.sm{font-size: 10px;} .sigil{font-size:16px}</style>',
            svg.rect(
                    string.concat(
                        svg.prop('fill', '#171717'),
                        svg.prop('x', '0'),
                        svg.prop('y', '0'),
                        svg.prop('width', '100%'),
                        svg.prop('height', '100%')
                    ),
                    utils.NULL
            ),
            string.concat(
                spellsCoinRows,
                svg.text(
                    string.concat(
                        svg.prop('x', insetX),
                        svg.prop('y', '24'),
                        svg.prop('class', 'base title')
                    ),
                    string.concat(
                        svg.cdata(name)
                    )
                ),
                headerRows,
                svg.text(
                    string.concat(
                        svg.prop('x', '374'),
                        svg.prop('y', '336'),
                        svg.prop('class', 'base sigil')
                    ),
                    string.concat(
                        svg.cdata(sigil)
                    )
                ),
                svg.text(
                    string.concat(
                        svg.prop('x', insetX),
                        svg.prop('y', '335'),
                        svg.prop('class', 'base balance'),
                        svg.prop('opacity', '0.5')
                    ),
                    string.concat(
                        unicode"∴"
                    )
                ),
                svg.text(
                    string.concat(
                        svg.prop('x', '28'),
                        svg.prop('y', '336'),
                        svg.prop('class', 'base balance'),
                        svg.prop('opacity', '0.9')
                    ),
                    string.concat(
                        utils.uint2str(spellsCoinAmount)
                    )
                )
            ),
            '</svg>'
        );
    }

    function getSpell(uint256 tokenId)
        external
        view
        returns (
            string memory name,
            string memory sigil,
            string memory incantation
        )
    {
        string[3] memory _incantation;
        (name, sigil, _incantation) = _getSpell(tokenId);
        incantation = string(
            abi.encodePacked(
                _incantation[0],
                " ",
                _incantation[1],
                " ",
                _incantation[2]
            )
        );
    }

    function _getAttributes(uint256 tokenId, string memory sigil, uint256 spellsCoin)
        internal
        view
        returns (string memory)
    {
        string memory kind;
        uint256 rand = _seed(tokenId);
        if(rand % 3 < 1){
            kind = "Elemental";
        } else {
            SpellsRendererStorage.Storage storage store = SpellsRendererStorage
            .getStorage();
            kind = store.kind[rand % store.kind.length];
        }
        return
            string.concat(
                '[{"trait_type":"sigil", "value": "',
                sigil,
                '"},{"trait_type":"mined", "value":"',
                string.concat(
                    utils.uint2str(SpellsCastStorage.getStorage().tokenSpellsCoinMined[tokenId]),
                    " / ",
                    utils.uint2str(SpellsStorage.mineOpCap(tokenId))
                ),
                '"},{"trait_type":"kind", "value":"',
                kind,
                '"},{"trait_type":"spellsCoin", "value":',
                utils.uint2str(spellsCoin),
                "}]"
            );
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        string memory name;
        string memory sigil;
        string[3] memory incantation;
        (name, sigil, incantation) = _getSpell(tokenId);
        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name": "',
                    name,
                    '", "description": "Spells are on-chain magic. Cast them across the blockchain on other NFTs and wallets. Build with them in any way you imagine.", "image": "data:image/svg+xml;base64,',
                    Base64.encode(bytes(render(tokenId))),
                    '", "attributes":',
                    _getAttributes(tokenId, sigil, _spellsCoin(tokenId)),
                    "}"
                )
            )
        );
        return string.concat(
            "data:application/json;base64,", json
        );
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
}