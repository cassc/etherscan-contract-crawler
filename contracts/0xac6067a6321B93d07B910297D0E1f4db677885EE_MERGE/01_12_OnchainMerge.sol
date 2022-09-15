// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MERGE is ERC721, Ownable {
    using Counters for Counters.Counter;

    uint256 private constant nftsNumber = 1509;
    bool private isSaleActive = true;
    uint256 private tokenPrice = 30000000000000000;// 0.03 ETH
    mapping(address => uint) public claimed;
    mapping(address => uint) public free_claimed;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("OnChain Merge Spirit", "OMS") {
        _tokenIdCounter.increment();
    }
    
function toStringSgn(int256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        int256 temp = value >= 0 ? value : -value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        if (value < 0) {
            digits++;
        }
        bytes memory buffer = new bytes(digits);
        if (value < 0) {
            //digits -= 1;
            value = -value;
            buffer[0] = bytes1(uint8(45));
        }
        
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }

    function getPoints(uint256 num, uint256 dir) internal pure returns (string memory ) {
        uint256[48]memory xtypes =[
            1601793089378634651916229389068460762052459802311704556339969,
            3455055549283932254542345883136998673944601941313622309095914512785721091758,
            14116839556210659620904562421719427577964239589633727123738674641387513539,
            2988103702795037444765425695026115639176893544827684,
            1689413862520023004513186866647917739775118161997665643328146109274930584789,
            3925146823175282154253240364329507190142806709484384736787962417656406813452,
            2282221626075212578099688283917530289384524886424860676155716275850945899296,
            632776959209791478350506430697,
            1956211109081345379296317235471186689123882870422957818135667908589262283499,
            35135175856856,
            632963162756625563438824634075,
            2415004921342884549858999,
            2415060549803900343001799,
            1884820520426204814200635895108599143783359014481165101811969904161799090804,
            9210748839305214620,
            1899065509100683129538046889086076598002788739905944672655742855558671691930,
            134017178,
            2238245253822760989449454494598949661896814069356689282098159649183932161671,
            165919785338073259500278367429143734,
            2053550962340045469097767931779772635592265490277305899371489986499233001586,
            134033522,
            2252021679777264024114407787861438570698762615550072927827525832302280908941,
            43495044332305604522823034452308363682976,
            1460197207315237484052602404227733794869126349782802835030368174066862478489,
            9211349515447909014,
            2025808261424475400744239902434344404796679062148083545412604657182400384662,
            2414377134891908205982323,
            2195619258217122146117541857811325401681032150578322393392322140618339720365,
            9210365726888896175,
            2153077058442902441640234527000124099984425968897108171968716016073999723699,
            632950884354071818322012616367,
            2025366551026516234010073780811458649243826219495156129363023607500967849647,
            2336664267203264771368274405849153688865883224257550080559807064906773635252,
            632955762779866246291720586414,
            1785460876923739195814668465435157725766640943217861860813963494726632812709,
            2280511115933763359002140373249427033429258453790091936187961172790483420328,
            2336857406049843438472922391933354787553972984473931242187281448477941123220,
            2414580698440041919236259,
            2195923154211866918767224498147307201349438532652922952892029785940808775376,
            14115549053228728825140767344416260809344070845953524314606490623837813909,
            53847753986875303369585923480488032166504095413073305675798995874419,
            205409767362377582773895558105893183497759164731608213512327314,
            2054023140008318469145529063474852455675364250211142286835752803375033430697,
            511,
            2845110905292298374965439145401793593335266483652293488749058146504419575335,
            43471583580407309215221827239602099745306,
            2180843908416196875607435898040014948726916018761136964696342662180990692905,
            134032937
        ];
        uint256 i;
        uint256 first_index;
        uint256 cur_num;
        uint256 k;
        int256 dir_y;
        uint256 pos;
        string memory res;
        uint256 result;
        
        first_index = (xtypes[0] / (256 ** (num-1)))%256;
        
        if (dir==1)
            dir_y = 0;
        else
            dir_y = 10;
        res = '';
    
        for(i = first_index; i<=48; i++) {
            if (xtypes[i] == 0)
                break;
    
            cur_num= xtypes[i];    
            k=0;
            for(pos=0;pos<=27;pos++) {
                result = (cur_num /  (512 ** pos)) % 512;
                if (result == 511)
                    break;
    
                if (k%2 == 0) {
                    if (dir==1)
                        res = string(abi.encodePacked(res, toStringSgn(int256((result*3))), ','));
                    else
                        res = string(abi.encodePacked(res, toStringSgn(970-int256((result*3))), ','));

                }
                else {
                    res = string(abi.encodePacked(res, toStringSgn(int256((result*3))-dir_y), ' '));

                }
                k++;
             }   
            if (result == 511)
                break;
        }

        return res;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function toHashCode(uint256 value) internal pure returns (string memory) {
        uint256 i;

        bytes memory buffer = "000000";
        for(i=6;i>0;i--) {
            if (value % 16 < 10)
                buffer[i-1] = bytes1(uint8(48 + uint256(value % 16)));
            else
                buffer[i-1] = bytes1(uint8(55 + uint256(value % 16)));

            value /= 16;
        }
        return string(buffer);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function tokenURI(uint256 tokenId) pure public override(ERC721)  returns (string memory) {
        uint256[15] memory xtypes;
        string[6] memory colors;
        string[40] memory parts;
        uint256[5] memory params;

        uint pos;

        uint256 rand = random(string(abi.encodePacked('OnChain Merge Spirit',toString(tokenId))));

        params[0] = 1 + (rand % 500); // pallette
        if (params[0]>30)
            params[0] = 1 + params[0] % 26;

        params[1] = 1 + (rand/100 % 5); // magic
        params[2] = 7 + (rand/1000 % 4); // magictime
        params[3] = (rand/10000 % 20); // meteors
        if (params[3] > 3)
            params[3] = 0; 
        
        params[4] = (rand/1000000 % 20) + 70; // stars


        xtypes[0] = 690488383033354219641375186562699158318364169482568241810305903975464959;
        xtypes[1] = 79036776625307791701348164042712353328490851890414448361188773414830079;
        xtypes[2] = 491308800584041007122779860319866296923294545556384175841541783675730841;
        xtypes[3] = 2573208762472449532788387464938866217196379346898807141640371926202009;
        xtypes[4] = 1001895129279643530301253581038908432229690155186935303840568147550664345;
        xtypes[5] = 1085183579070973857993025048453769120379302585432886755530964929369336811;
        xtypes[6] = 1230646929421187996973367959876278571697415818334807340365482914425587635;
        xtypes[7] = 575250914740202838402708593136469066367474242066319361020178334727797158;
        xtypes[8] = 498985760184077789483251484849649586520377052764307162785887987544613821;
        xtypes[9] = 920174386713173784891452649584414985023478375601209326778104302203304358;
        xtypes[10] = 1624863353245390385960345314777044164407498875695019585826566502460386;
        xtypes[11] = 865692017586216292698204939618548210433660086459366197809005998977931812;
        xtypes[12] = 739434155922810763069377056076501677869440564142647695036200883353878493;
        xtypes[13] = 519851593459797981897156763519359744426095485819042920194463717702762495;
        xtypes[14] = 1515379393161744958771473244738377076434447951906173897577477064966212;

        for(uint i = 0;i<5;i++) {
            pos = (params[0]-1) * 5 + i;
            colors[i] = toHashCode(xtypes[pos/10] / (16777216 ** (pos%10)) % 16777216);
        }


        parts[0] = string(abi.encodePacked('<?xml version="1.0" encoding="utf-8"?><svg xmlns="http://www.w3.org/2000/svg" width="1000px" height="1000px" viewBox="0 0 1000 1000"><defs><filter id="y"><feGaussianBlur stdDeviation="25"/></filter><filter id="x"><feGaussianBlur stdDeviation="5"/></filter></defs><linearGradient id="a" gradientUnits="userSpaceOnUse" x1="500" y1="1000" x2="500" y2="0"><stop  offset="0" style="stop-color:#',colors[3],'"/><stop  offset="0.5" style="stop-color:#',colors[4],'"/><stop  offset="1" style="stop-color:#',colors[3],'"/></linearGradient><rect fill="url(#a)" width="1000" height="1000"/><g opacity="0.4">'));
        for (uint i = 0; i < params[4]; i++) {
            parts[0] = string(abi.encodePacked(parts[0], '<circle fill="#',colors[0],'" cx="',toString((rand>>i)%1000),'" cy="',toString((rand>>(i+70))%1000),'" r="',toString((rand>>(i+140))%5),'"/>'));
        }

        parts[0] = string(abi.encodePacked(parts[0], '</g><linearGradient id="b" gradientUnits="userSpaceOnUse" x1="1000" y1="0" x2="100" y2="0"><stop  offset="0" style="stop-color:#',colors[2],'"/><stop  offset="0.5" style="stop-color:#',colors[1],'"/><stop  offset="1" style="stop-color:#',colors[2],'"/></linearGradient>'));
        if (params[3] > 0) {
            parts[0] = string(abi.encodePacked(parts[0], '<g>'));
            for (uint i = 1; i <= params[3]; i++) 
                parts[0] = string(abi.encodePacked(parts[0], '<circle opacity="0.4" fill="#',colors[0],'" cx="',toString(i==1?500:(i==2?820:983)),'" cy="-',toString(i==1?69:(i==2?240:164)),'" r="3"/>'));

            parts[0] = string(abi.encodePacked(parts[0], '<animateMotion path="M 0 0 l -10000 10000 20 Z" dur="20s" repeatCount="indefinite" /></g>'));
        }
        for (uint i = 1; i <= 2; i++) {
                parts[0] = string(abi.encodePacked(parts[0], '<polygon opacity="0.8" fill="url(#b)" points="',getPoints(1,i),'"/>'));
                parts[0] = string(abi.encodePacked(parts[0], '<polygon opacity="0.8" fill="#',colors[1],'" points="',getPoints(2,i),'"/>'));
                parts[0] = string(abi.encodePacked(parts[0], '<polygon opacity="0.4" fill="#',colors[1],'" points="',getPoints(3,i),'"/>'));
                parts[0] = string(abi.encodePacked(parts[0], '<polygon fill="#',colors[2],'" points="',getPoints(4,i),'"/>'));
                parts[0] = string(abi.encodePacked(parts[0], '<polygon fill="#',colors[0],'" points="',getPoints(5,i),'"/>'));
                parts[0] = string(abi.encodePacked(parts[0], '<polygon fill="#',colors[2],'" points="',getPoints(6,i),'"/>'));
                parts[0] = string(abi.encodePacked(parts[0], '<polygon fill="#',colors[0],'" points="',getPoints(7,i),'"/>'));
        } 
        for (uint i = 1; i <= 2; i++) 
            parts[0] = string(abi.encodePacked(parts[0], '<polygon opacity="0.1" fill="#',colors[0],'" points="',getPoints(22+i,1),'" filter="url(#y)"><animateTransform attributeName="transform" type="rotate" from="',toString(i==1?0:360),' 500 430" to="',toString(i==1?360:0),' 500 430" dur="',toString(50),'s" repeatCount="indefinite" /></polygon>'));

        parts[0] = string(abi.encodePacked(parts[0], '<g filter="url(#x)">'));
        for (uint i = 1; i <= 3; i++) 
            parts[0] = string(abi.encodePacked(parts[0], '<polygon fill="#',colors[0],'" points="',getPoints(4+i+params[1] *3,1),'"><animate attributeName="opacity" values="',(i==1?'1;0;0;0;1':(i==2?'0;1;0;0;0':'0;0;1;0;0')),';" dur="',toString(params[2]),'s" repeatCount="indefinite" begin="0s"/></polygon>'));





        parts[1] = string(abi.encodePacked('</g></svg> '));

        string memory output = string(abi.encodePacked(parts[0],parts[1]));
        

        
        parts[0] = '[{ "trait_type": "Palette", "value": "';
        parts[1] = toString(params[0]);
        parts[2] = '" }, { "trait_type": "Magic", "value": "';
        parts[3] = toString(params[1]);
        parts[4] = '" }, { "trait_type": "Magic time", "value": "';
        parts[5] = toString(params[2]);
    
        parts[6] = '" }, { "trait_type": "Stars", "value": "';
        parts[7] = toString(params[4]);

        if (params[3] > 0) {
            parts[7] = string(abi.encodePacked(parts[7], 
             '" }, { "trait_type": "Meteors", "value": "',toString(params[3])));
        }
        parts[8] = '" }]';
        
        string memory strparams = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5],parts[6], parts[7],parts[8]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "OnChain Merge Spirit", "description": "Beautiful spirits, completely generated OnChain","attributes":', strparams, ', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function flipSale() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setPrice(uint256 _price) external onlyOwner {
        require(_price >= 0, "Wrong price");
        
        tokenPrice = _price;
    }   
    
    function claim(uint num) public {
        require(isSaleActive, "Later");
        require(num <= 100, "Free claim finished");

        require(_tokenIdCounter.current() == num, "Wrong number");
        require(free_claimed[msg.sender]  == 0, "Tokens done");

        free_claimed[msg.sender] = 1;
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function buy(uint amount) public payable {
        require(amount < 3, "Wrong amount (need 1 or 2)");

        require(isSaleActive, "Later");
        require(_tokenIdCounter.current() + amount <= nftsNumber, "Sale finished");
        require(tokenPrice * amount <= msg.value, "Need more ETH");
        require(claimed[msg.sender] + amount <= 2, "Tokens done");

        for (uint i = 0; i < amount; i++) {
            require(_tokenIdCounter.current()<= nftsNumber + 1, "Sale finished");
            claimed[msg.sender] += 1;
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function directMint(address _address, uint256 amount) public onlyOwner {
        require(_tokenIdCounter.current() + amount <= nftsNumber, "Sale finished");

        for (uint i = 0; i < amount; i++) {
            _safeMint(_address, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}