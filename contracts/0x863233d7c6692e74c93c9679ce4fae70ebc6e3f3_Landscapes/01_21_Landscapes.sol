// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

contract Landscapes is
    RevokableDefaultOperatorFilterer,
    ERC721Royalty,
    Ownable
{
    using Strings for uint256;

    string constant TITLE = "Landscape";
    string constant DESCRIPTION =
        unicode'\\"81 Landscapes\\" is a collection of 81 fully on-chain artworks 🌹 '
        unicode"project by Rafaël Rozendaal 2023 🌹 "
        unicode"smart contract by Alberto Granzotto 🌹 "
        unicode"License: CC BY-NC-ND 4.0";

    string constant JSON_PROTOCOL_URI = "data:application/json;base64,";
    string constant SVG_PROTOCOL_URI = "data:image/svg+xml;base64,";

    string constant SVG_HEADER =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 800">'
        "<defs>"
        '<linearGradient id="g" x1="600" y1="800" x2="600" y2="0" gradientUnits="userSpaceOnUse">';

    string constant SVG_FOOTER =
        "</linearGradient>"
        "</defs>"
        '<rect fill="url(#g)" width="1200" height="800"/>'
        "</svg>";

    // Each artwork is described by a sequence of 4 bytes:
    // - The first byte is the gradient offset
    // - The other three bytes represet the color
    bytes constant PALETTE =
        hex"0000a99d0308aba0071eb3a80d43bfb71376d1ca1ab7e6e321ffffff29ecf7fc"
        hex"39bce4f65070c7eb6429abe20022b57321ffffff29ecf7fc39bce4f65070c7eb"
        hex"6429abe200006c390800743b15008a42190092451d07966222109c842818a0a1"
        hex"2f1ea4b93623a7cb3f26a9d84b28aadf6429abe200000000040025220900544e"
        hex"0e007870130093881700a3971a00a99d1b04a9a41e14a9bf211faad22426aade"
        hex"2729abe2642e31920022b5730423b28d0d26aebb1328abd71729abe22043b1e6"
        hex"3883bff04cb1c9f85bcdcffd64d8d2ff0000a99d0308aaa0071eada80d43b2b7"
        hex"1376b9cb1ab7c3e421fccdff29e9cafc3ab9c2f5516db6eb6429abe200000000"
        hex"040025220900544e0e007870130093881700a3971a00a99d1b06a99f1e34b0b1"
        hex"215fb6c12484bbd028a5c0dd2dc0c4e732d6c7f037e7caf73ef3cbfb48faccfe"
        hex"64fccdff0029abe20331ace30747afe60c6cb5eb129fbef219e0c8fb1bfccdff"
        hex"1cf3d2fd20dae4f823cbeff526c6f3f53fd8e6f864fccdff00b8ffde0ab9ffe3"
        hex"16bcfff31dbfffff64fccdff00c6f3f507c8f3f00fd0f5e416def8cf1ef0fbb1"
        hex"23ffff9b2efefaa441fdecbf59fcd7e964fccdff00ffff9b05fcff9f0af4ffab"
        hex"0fe6ffc014d3ffde19bfffff1fccf3ff2ce1e2ff3af0d6ff4bf9cfff64fccdff"
        hex"00bfffff06c3ffff0ccfffff13e4ffff19ffffff2ffef5ff54fcdaff64fccdff"
        hex"00ffff9b06ffffa30effffb919ffffde21ffffff3dfdecff64fccdff00ffd59b"
        hex"08ffd99b10ffe59b18fffa9b19ffff9b26fefaa43cfdecbf58fcd7e964fccdff"
        hex"0029d3eb032ed4e8073fd7e20c5bddd81182e5c916b4efb61cf0fba01dffff9b"
        hex"29fbfba23bf3f1b851e5e2db64d8d2ff00662d910f29abe2136fc6ca18bce4b1"
        hex"1becf7a11dffff9b26fffb9532fff08440ffde694fffc5435effa51464ff9800"
        hex"0000d0ff0436cfff0971ceff0ea3ceff13c9cdff17e5cdff1bf6cdff1efccdff"
        hex"3afdb79964ff980000ff980003ffa71708ffc6460effdf6a13fff08518fffb95"
        hex"1bffff9b3129abe264662d9100ff980003ff9d0809ffae2110ffc84918ffec7f"
        hex"1cffff9b21e3f4a42ab2e0b43388d0c23c65c2cd464bb8d65038b0dc592cace0"
        hex"6429abe200ff98001cfccdff23f6cdff2ce5cdff36cacdff41a4ceff4d74ceff"
        hex"5939cfff6400d0ff00ff980003f99e1509ecae4511e1bc7118d7c89621ced2b6"
        hex"2ac7dad033c2e1e43ebee5f24cbce8fa64bce9fd00ffff9b03ffffaa0cffffce"
        hex"14ffffe91bfffff921ffffff21fcffff23e1ffff25ceffff28c2ffff2abfffff"
        hex"6429abe200ffd59b1bffff9b1bfcff9e1fe6ffc122d5ffdc26c8ffef29c1fffb"
        hex"2dbfffff6429abe200bfffff05cfffff10e9ffff1af9ffff21ffffff21fcffff"
        hex"23e1ffff25ceffff28c2ffff2abfffff64d8d2ff00bfffff05cfffff10e9ffff"
        hex"1af9ffff21ffffff23feefff25fcdcff27fcd0ff2afccdff6429abe200fccdff"
        hex"0bd8e6f812c6f3f516cbeff51adae4f81ff4d2fd20fccdff27ddc8fa379ebdf2"
        hex"466bb5eb5347afe65d31ace36429abe20000a99d23fccdff64bce9fd00b8ffde"
        hex"07c0ffe112d6ffec20fbfffd21ffffff38ecffff64bfffff00fccdff07fdddff"
        hex"12fef6ff19ffffff2be4ffff3fcfffff52c3ffff64bfffff00b8ffde07cfffe8"
        hex"11e9fff41af9fffc21ffffff23feefff25fcdcff27fcd0ff2afccdff6400ffff"
        hex"0000ffff062bf6ff1296e1ff1efccdff24e2cdff446aceff5a1dcfff6400d0ff"
        hex"0000a99d0625bcb90d4bcfd61467ddeb1a78e6f81e7ee9fd28bce9fd39c8e8f6"
        hex"64e6e6e60000d0ff1dbce9fd3cc2deea64cccccc00b3b3b307bbbbbb11d1d1d1"
        hex"1ef6f6f621ffffff35ececec5cbdbdbd64b3b3b300b3b3b305afafb10aa4a4ae"
        hex"0f9191a9137777a1185555971c2d2d8c2000007f271e037e38670d7c47a0147a"
        hex"54ca19795ee31c7964ed1e7900ed1e7903e41c7908cb19790fa3147a166c0d7c"
        hex"1f27047e2300007f302e2e8c4266669c519090a85da9a9b064b3b3b30029abe2"
        hex"023bb5e5076acfee0c8ee4f511a9f2fa15b9fbfd19bfffff21d0abcd29df5f9f"
        hex"2fe9308332ed1e7937d2207c439826844d6a2a8a57492e8e5f353091642e3192"
        hex"0000a99d0600a3a20e0092b2170077cd1a006ed72a2e57c03c5942ab4d79339b"
        hex"5a8c2a926493278f0000afe7190000001b36061b1d660c341f8f124921b1165a"
        hex"24cb196826de1c7128e91d772bed1e79476f499c5b1f65b3640071bc00000000"
        hex"032f061807680d350b97134d0fbc176013d71b6d16e71d7619ed1e791aee1b6d"
        hex"22fa071e25ff000064662d9100662d910ad00d2c0fff000013fe000215fd020a"
        hex"17fb061918f80b2d1af411471bef19671ced1e7923e71d762dd61b6d37bb175f"
        hex"4395124c4f650c335c2a0515640000000000d0ff030bcdf30929c6d5105bbba3"
        hex"199fac5f23f59a0924ff980064ff000000ff000023ff980025f59a09379fad5f"
        hex"475abca45429c6d55e0bcdf36400d0ff0029abe2002ea6de0d7176bb18a6509e"
        hex"21cc358a28e4247d2ded1e7934f0356243f65f3751fb7e195cfe910664ff9800"
        hex"0000a99d0308a397071e948a0d437c7313765a531ab72f2b21ff000028ff1200"
        hex"36ff42004aff8f0063fff90064ffff00000068371643c1b622fccdff64ed1e79"
        hex"00ff980008ff95000dff8b0011ff7c0016ff66001aff4a001dff270021ff0000"
        hex"64662d9100662d9107692b8d0d752882148822701aa21b5720c5113626ee040f"
        hex"28ff000030ff1f003bff4a0047ff6c0052ff84005cff920064ff9800002e3192"
        hex"041a4ba3080b60b10c026cb9100071bc120472bb131177b9152680b717448bb3"
        hex"196a9aae1b99ada81dcfc2a11effd59b26fecf9931fcbf963dfaa4924af6808b"
        hex"57f2518264ed1e7900ed1e7906f251820bf6808b11faa49216fcbf961bfecf99"
        hex"1effd59b1ff7d29b22bebba3258ba7a9286096af2c3d89b42f227eb7320f77ba"
        hex"350372bb390071bc642e31920000007f2000004c3e0000225600000964000000"
        hex"00000000020000050f00002a1e0000492d0000603d0000714e00007b6400007f"
        hex"00000000060000030c00000e110000211700003b1c00005c2000007f3600004c"
        hex"4a0000225a0000096400000000000000060000030c00000e110000211700003b"
        hex"1c00005c2000007f31240c8c484d1a9b596623a4647027a8006666660c636366"
        hex"125c5c67164f4f6a1a3d3d6d1d252572200909782100007a2b00006d3f00004d"
        hex"580000196400000000000000060000191200004d1b00006d2000007a29151575"
        hex"3a38386f4a51516a586060676466666600000000090000081700002029000047"
        hex"3c00007a4c2f2f705c5656686466666600ff5d0005dc50151186314d220202a2"
        hex"26010199640000000000000008030000100e0000172100001e3b000020460000"
        hex"3c220000550900006400000000003d000900390012002e001a001b0022000100"
        hex"230000002600001f2900003f2e00005a33000070380000813f00008d49000094"
        hex"64000096000068370700582e1700381d29001f103b000d074e00030164000000"
        hex"00000000030010070a002c1311003d1a1500431d2015452a2f2e48393e3f4b44"
        hex"50494c4a644d4d4d004d4d4d06484c4a0d3a4a41142347331c04431f1c00431d"
        hex"2c003d1a40002c13570011076400000000ababab049797970e6f6f6f194c4c4c"
        hex"24303030311b1b1b3e0b0b0b4d0202026400000000000000132c2c2c2f656565"
        hex"468f8f8f59a9a9a964b3b3b300004e00080043121c002b3c3100185e44000b76"
        hex"550002846400008a000092450b009b711800a59d1e00a9af2700949964000000"
        hex"000068370200734808008a6c0e009b871300a5971700a99d1706aa9e1b2fb1a7"
        hex"1f54b7b02375bdb82890c1be2da6c5c333b7c8c73bc3caca46cacbcb64cccccc"
        hex"19cee4eb1ac2e2ec1da4dfef2072dbf3242fd4fa2600d0ff3c5390cf64ed1e79"
        hex"00ffffff07fbffff0df2ffff12e1ffff16c9ffff1babffff1f86ffff245affff"
        hex"2828ffff2b00ffff4300d6f25800b9ea6400afe700bfffff05cfffff10e9ffff"
        hex"1af9ffff21ffffff21fcffff23e1ffff25ceffff28c2ffff2abfffff6429abe2"
        hex"0029abe20241b4e5077acbed0ca9ddf311ceecf815e9f6fc19f9fcfe1cffffff"
        hex"28ffffff6429abe20029abe20241b4e5087acbed0da9ddf312ceecf817e9f6fc"
        hex"1bf9fcfe1fffffff3229abe2641b1464001b14641729abe221ffffff28f9fcfe"
        hex"32e9f6fc3cceecf847a9ddf3537acbed5f41b4e56429abe200000000180071bc"
        hex"191277c01b4289cd1e8fa5e222f8cbfe22fccdff6429abe20000afe7062bb4eb"
        hex"1296c0f51dfccdff2191ceff2500d0ff42006bd159011faf640202a200999999"
        hex"0099999914a5b5bc28afccd83cb6dced50bae5f964bce9fd00bce9fd21cccccc"
        hex"256dbed82900afe72c00a6e3530130b4640202a200cccccc04b6c8ce0c7fc1d6"
        hex"1728b4e11c00afe7210095db2d0068c8380042b7430025ab4e0010a25900049c"
        hex"6400009b00cccccc19ffffff1ae1f9ff2069e3ff241dd5ff2600d0ff2a00c6f8"
        hex"3b00a1de4b0086cb590076c0640071bc000202a2060123af120079d11a00afe7"
        hex"22cccccc64bce9fd";

    // Each offset is a uint16
    bytes constant OFFSETS =
        hex"0000002c0044007400a800d000fc01440178018c01b401e00200021c02400270"
        hex"02a002c802ec03240348037403a403c803f4041c0450045c0478049804c004e0"
        hex"050405140534056c059c05e00608063c066c06b006d006f00720075007600784"
        hex"07bc0808084c0860088008ac08d80908093009500968098c09c409e00a080a30"
        hex"0a540a6c0a880aa00ae00b000b340b600b880bb00bd80bf80c1c0c380c540c84"
        hex"0cb0";

    uint8 constant MAX_SUPPLY = 81;

    address internal _holder;

    constructor(address holder) ERC721("81 Landscapes", "81L") {
        _holder = holder;
        _setDefaultRoyalty(msg.sender, 1000);
        for (uint256 i = 1; i <= MAX_SUPPLY; ) {
            emit Transfer(address(0), _holder, i);
            unchecked {
                i++;
            }
        }
        __unsafe_increaseBalance(_holder, MAX_SUPPLY);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            tokenId > 0 && tokenId <= MAX_SUPPLY,
            "Landscapes: invalid token id"
        );

        bytes memory json = abi.encodePacked(
            '{"name":"',
            TITLE,
            " ",
            tokenId.toString(),
            '",',
            '"description":"',
            DESCRIPTION,
            '",',
            '"image":"',
            abi.encodePacked(SVG_PROTOCOL_URI, Base64.encode(_getSVG(tokenId))),
            '"}'
        );

        return string(abi.encodePacked(JSON_PROTOCOL_URI, Base64.encode(json)));
    }

    function owner()
        public
        view
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function _ownerOf(
        uint256 tokenId
    ) internal view override returns (address addr) {
        if (!(tokenId > 0 && tokenId <= MAX_SUPPLY)) {
            return address(0);
        }
        addr = super._ownerOf(tokenId);
        if (addr == address(0)) {
            addr = _holder;
        }
    }

    function _getOffset(uint256 tokenId) internal pure returns (uint256) {
        return
            (uint256(uint8(OFFSETS[tokenId * 2])) << 8) +
            uint256(uint8(OFFSETS[tokenId * 2 + 1]));
    }

    function _getSVG(uint256 tokenId) internal pure returns (bytes memory) {
        bytes memory svg = abi.encodePacked(SVG_HEADER);

        uint256 startOffset = _getOffset(tokenId - 1);
        uint256 endOffset = tokenId < MAX_SUPPLY
            ? _getOffset(tokenId)
            : PALETTE.length;

        for (; startOffset < endOffset; startOffset += 4) {
            uint256 gradientOffset = uint8(PALETTE[startOffset]);
            svg = abi.encodePacked(
                svg,
                '<stop offset="',
                gradientOffset.toString(),
                '%" stop-color="rgb(',
                uint256(uint8(PALETTE[startOffset + 1])).toString(),
                ",",
                uint256(uint8(PALETTE[startOffset + 2])).toString(),
                ",",
                uint256(uint8(PALETTE[startOffset + 3])).toString(),
                ')"/>'
            );
        }
        return abi.encodePacked(svg, SVG_FOOTER);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}