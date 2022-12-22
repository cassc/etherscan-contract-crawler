// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// ^^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~^~~^~!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^
// ^^^^^^^^^^^^^^^^^^^^^^^^^^~^^~^^^~!7?7777?JJ?777?7~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// ^^^^^^^^^^^^^^^^^^^^^^^^^~~~!^!YY5PPGG5555Y55?7??J?~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// ^^^^^^^^^^^^^^^^^^^^^^^^~~~!??YPYYYYY5GGGGGGGYJJY57^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// ^^^^^^^^^^^^^^^^^^^^^^^^^!!?YYY5J7!!JYP5YYP#BGPPP?~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// ^^^^^^^^^^^^^^^^^^^^^^~~!7?JYJYP!^~!?5PG5YPB#BJ?!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// :::::::^^^^^^^^^^^^^^^^^!7?YJYYPY7!J5YGBBBB#P?!::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::::::::
// :::::::::::::::::::^^^^^!?JYJYY5B5~^~!J5BBBPYJY?^::::^:::^^:::::^^^:^:::::::::::::::::::::::::::::::
// ::::::::::::::::::::^^^~!?JJJYYYGGJ7~!Y5P5YY555PY!::::::::::::::::::::::::::::::::::::::::::::::::::
// :::::::::::::::::::^^^~~!JJJYYYYPG5~^~?5YY5PYYYPP~^~!!~:::::::::::::::::::::::::::::::::::::::::::::
// ::::::::::::::::::::^^^:~!!?JJYYY?7::YPPP5YYJJJ?YPPPPPPYY7::^^::::::::::::::::::::::::::::::::::::::
// :::::::::::::::::::::::::~77J?J??~^^JG#PYJJYYYJ~7JPP55GGG5Y7!~::::::::::::::::::::::::::::::::::::::
// :::::::::::::::::::::::^^^!~!!^!~^:~PJ!!7JJJ5Y?~~!JGPPGGPPB5~:::::::::::::::::::::::::::::::::::::::
// ::::::::::::::::::::::^^::^^:^^^:::777!!JJYYPY?7!~?5BGPPPGBB?^::::::::::::::::::::::::::::::::::::::
// ::::::::::::::::::::::::::::::::::~?7??JJYYY55Y?~JYY5BGPGGGGGP7:::::::::::::::::::::::::::::::::::::
// ::::::::::::::::::::::::::::::::::?J?JYYYYYYPPYJJYY5Y5BGPPPBGPP^::::::::::::::::::::::::::::::::::::
// ...:::::::::::::::::::::::::::::.~Y5YY5555YY5555YY5555BBBGGBBBY!:::::::::::::::::::::::::::::.......
// ..........::::::::::::::::::::..~Y5P5YY5555555G5555555PP#BBBBG~!::::::::::::::::....................
// .................:::::::::::::!YPP5555YYYYY55PGPPPP55555B&#BP!^^:::::::::...........................
// ..........................::::~P&&&###BBGGP555PBBP55555PG5?!^?^.....................................
// ..............................:P##BBBBB#BBBB#G5PBBGGGGBY^....:......................................
// .............................^5GPP55YY5P5555PPBGBB#&#55J:...........................................
// .............................!PY55Y555P5P55YYY5PG&PJYG5PP^..........................................
// .............................JPYY5PBBGP5YJJYYPPY5B&5^?BGBG7.........................................
// ...........................:7GYJYY5G#BYJJYYYJYPYY5B&#PBGPPGY7:......................................
// .........................:~JG5P555Y5BBB##BGGPY5PPYP#&#GGGPPPPY^.....................................
// .......................:!JYG&&&&GYJ?5BB##5?7J55PG###&&#PPPPPPPP^....................................
// .....................:!JYYP&&@@@G!!!7YY5B#J5G5J?YYB&&##GGG5GGGBY....................................
// ...................^7JYYYJ#&&&&&&[email protected]&BY7Y5PPGG##&#5J?~GBG7....................................
// .................:!JYYYY55&&&&&###?!!~!J5&&#BBGGBGGGGB##B~:.!J^.....................................
// ................^YYYYPGG5G########BY7!!?5B#####BBBGGBBP55Y::........................................
// ................?5YY5PYYJB#########P55PBB########BG#BJ!~!7!~~^:.....................................
// ...............^JP5YYYYYJ7BBBBBB###GGBB#############B7!!77~!7?!^:...................................
// .................Y#B#5PY?.!PBBBBBBBBBBBBBBB#BBBBBBBGPY??7?7!!7JJ?7~^:..........^^...................
// ................^YGBY7!~...:JPGGBBBBBBPPY?!5BBBBBBBP7.:^!JJ7?G5JJYYJJ7:.......^YY:..................
// ................!YPP.........^~JGBG5G5J7!~~!PBGBGY!:......:!5PYP5J??JYYY77J?:::?Y^.:^~^.............
// ................!YYP~.........:.~?!:~:^!!!JJJY^!~:..........:~YPJPJJYGGBBPP5J????J?JJJJ7. ..........
// ................:JYYJ:........:........^!77??^ ................:!PPPB&BGG55GYY5YJ?JYPGB#P!:.........
// .................JPY!...............::..7J?7Y?^...............^::7GB#BG5555BBGGGGPG#&&####^.........
// .................:Y~ ..............:7~!7Y5Y5PGP~ ...........:^7?5PG##PPGP5PGBPPG#########7..........
// ................. ~Y................^!?PBPPPGBPJ^...........!?!7!?PP#P5GPPBG55B########P~...........
// ...................J^ ............ .:~?B#B##BGG5:..............~7J:!#5Y55PP5PG########J.............
// ...................:?:...........^!7YGGGGPPPP5YY^..............::..?GYJ5GPPGBBBBB##G7!:.............
// ....................^7:......7??7Y5PPGGGBBBG5YYY?.................!55YPPPG#B#BBB#B!.  ..............
// ............................^5JJYPPPPGGGBB#BPYJJY: ...............???JJYPB#BBBB#G?........~^........
// .............::::::::::~^::^~7JYPBP5YYY5YYPGPP55Y~^^^^^~^^^^^?~^^^?P5YYG######B?^.....::::^^::::::..
// ..........:::::::::::::::::^^^^^^^^^^^^^^^!!~^~^^^~!!!!!!!!!~~~~~!!77??JJJJJJJ7~~~~~~~~~~~~~~~~~^^::

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Makimono is ERC721AQueryable, Ownable, DefaultOperatorFilterer {
    enum ContinuumState {
        PENDING_JUDGEMENT,
        OG,
        SCROLLS_LIST,
        COMMONS
    }

    // ************************************************************************
    // * Constants
    // ************************************************************************

    uint256 public constant MAX_SUPPLY = 999;
    uint256 public constant MAX_MINT_PER_WALLET = 2;

    // ************************************************************************
    // * Storage
    // ************************************************************************

    uint256 public passengerFare = 0.009 ether;
    string public baseTokenURI;
    ContinuumState public state;

    // ************************************************************************
    // * Function Modifiers
    // ************************************************************************

    modifier mintCompliance(uint256 amount) {
        require(msg.sender == tx.origin, "No smart contract");
        require(totalSupply() + amount <= MAX_SUPPLY, "The Portal Has Closed");
        require(_numberMinted(msg.sender) + amount <= MAX_MINT_PER_WALLET, "You've got enough, traveler");
        _;
    }

    modifier priceCompliance(uint256 amount) {
        require(msg.value >= amount * passengerFare, "You Lack The Mana Required");
        _;
    }

    constructor() ERC721A("Makimono", "MAKIMONO") {}

    // ************************************************************************
    // * Mint Functions
    // ************************************************************************

    function summonOGTravelers(uint256 amount) external payable mintCompliance(amount) priceCompliance(amount - 1) {
        require(state == ContinuumState.OG, "OG summon inactive");
        require(_getAux(msg.sender) == uint64(ContinuumState.OG), "I don't know you, Traveler");
        _mint(msg.sender, MAX_MINT_PER_WALLET);
    }

    function summonScrollsListTravelers(
        uint256 amount
    ) external payable mintCompliance(amount) priceCompliance(amount) {
        require(state == ContinuumState.SCROLLS_LIST, "Scrolls List summon inactive");
        require(_getAux(msg.sender) == uint64(ContinuumState.SCROLLS_LIST), "You're Not On My Scroll, Traveler");
        _mint(msg.sender, amount);
    }

    function summonCommonTravelers(uint256 amount) external payable mintCompliance(amount) priceCompliance(amount) {
        require(state == ContinuumState.COMMONS, "Commons summon is inactive");
        _safeMint(msg.sender, amount);
    }

    // ************************************************************************
    // * Admin Functions
    // ************************************************************************
    function updateTravelers(address[] calldata travelerAddresses, ContinuumState status) external onlyOwner {
        for (uint256 i; i < travelerAddresses.length; ) {
            _setAux(travelerAddresses[i], uint64(status));
            unchecked {
                i++;
            }
        }
    }

    function ownerMint(uint256 amount, address to) external onlyOwner {
        require(amount + totalSupply() <= MAX_SUPPLY, "No more Rebels");
        _safeMint(to, amount);
    }

    function ownerBurn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function openPortal(ContinuumState newState) external onlyOwner {
        state = newState;
    }

    function setPassengerFare(uint256 newPrice) external onlyOwner {
        passengerFare = newPrice;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{ value: address(this).balance }("");
        require(success, "Failed to withdraw Ether");
    }

    // ************************************************************************
    // * Operator Filterer Overrides
    // ************************************************************************
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ************************************************************************
    // * Internal Overrides
    // ************************************************************************

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}