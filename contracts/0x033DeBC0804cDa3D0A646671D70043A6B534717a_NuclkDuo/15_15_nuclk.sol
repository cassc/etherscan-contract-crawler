// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./base64.sol";

contract NuclkDuo is ERC721Enumerable, Ownable {
    bytes10 internal constant _DIGITS = "0123456789";
    
    uint public MAX_SUPPLY = 600;
    uint256 public MINT_PRICE = 0.045 ether;
    
    bool public ALLOWLIST_MINT_PAUSED = true;
    bool public PUBLIC_MINT_PAUSED = true;

    mapping(address => uint) _allowlist;
    mapping(uint256 => uint) private _palette;

    constructor() ERC721(unicode"NüCLK Dúo", "NUCLK002") {}

    function pauseAllowlist() public onlyOwner {
        ALLOWLIST_MINT_PAUSED = !ALLOWLIST_MINT_PAUSED;
    }

    function pausePublic() public onlyOwner {
        PUBLIC_MINT_PAUSED = !PUBLIC_MINT_PAUSED;
    }

    function addToAllowlist (address[] calldata users, uint[] calldata spots) public onlyOwner {
        require(users.length == spots.length,     "invalid allowlist");
        
        for (uint i = 0; i < users.length; i++) {
            _allowlist[users[i]] = spots[i];
        }
    }

    function getAllowlist(address user) public view returns (uint amount) {
        return _allowlist[user];
    }

    function withdraw() public payable onlyOwner {
        require(payable(0x05D4A8286Ef7211cf2570722Def303C65b60f954).send(address(this).balance));
    }

    function allowlistMint() public {
        uint256 currentSupply = totalSupply();
        uint allowlistSpots = _allowlist[msg.sender];

        require(allowlistSpots > 0,                           "Not in Allowlist");
        require(currentSupply + allowlistSpots < MAX_SUPPLY,  "Sale has already ended");
        require(ALLOWLIST_MINT_PAUSED == false,               "Allowlist mint paused");

        for (uint256 i = 0; i < allowlistSpots; i++) {
            _palette[currentSupply] = prng(block.timestamp - block.number + currentSupply + i) % 3;
            _safeMint(msg.sender, currentSupply + i);   
        }

        _allowlist[msg.sender] = 0;
    }

    function publicMint() payable public {
        uint256 currentSupply = totalSupply();

        require(currentSupply < MAX_SUPPLY,      "Sale has already ended");
        require(PUBLIC_MINT_PAUSED == false,     "Public mint paused");
        require(msg.value >= MINT_PRICE,         "Ether sent is not correct");

        _palette[currentSupply] = prng(block.timestamp - block.number + currentSupply) % 3;
        _safeMint(msg.sender, currentSupply);
    }

    function tokenURI(uint256 index) public view override virtual returns (string memory) {
        require(_exists(index),  "URI query for nonexistent token");

        uint palette = _palette[index];

        bytes memory rgbSolid;
        bytes memory rgbShade;
        bytes memory paletteName;

        // Ruby
        if (palette == 0) {
            rgbSolid = "#E94E77";
            rgbShade = "#E94E77;#D53A63;#E94E77";
            paletteName = unicode"Rubí";
        } else if (palette == 1) {
            rgbSolid = "#1A90FF";
            rgbShade = "#1A90FF;#067CEB;#1A90FF";
            paletteName = "Zafiro";
        }else if (palette == 2) {
            rgbSolid = "#1FDBCC";
            rgbShade = "#1FDBCC;#0BC7B8;#1FDBCC";
            paletteName = "Diamante";
        }

        bytes memory r = abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 450 450"><defs><g id="c"><circle cx="35" cy="35" r="15" fill="none" stroke-miterlimit="10" stroke-width="2"/><line x1="35" y1="23" x2="35" y2="37" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.75"><animateTransform attributeName="transform" type="rotate" from="0 35 35" to="360 35 35" dur="1s" repeatCount="indefinite"/></line><line x1="35" y1="26" x2="35" y2="37" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.75"><animateTransform attributeName="transform" type="rotate" from="0 35 35" to="360 35 35" dur="60s" repeatCount="indefinite"/></line><circle cx="35" cy="35" r="1.5" fill="#111"/><animate attributeName="stroke" values="#EEE;#CCC;#EEE" dur="0.05s" repeatCount="indefinite"/></g></defs><rect x="0" y="0" width="450" height="450" fill="#111"/>');

        for (uint256 y = 0; y < 4; y++) {
            for (uint x = 0; x < 6; x++) {
                r = abi.encodePacked(r, '<circle cx="', itoa(100 + x*50), '" cy="', itoa(100 + y*50),'" r="15" id="', itoa(2 + x), '-', itoa(1 + y), '" fill="',rgbSolid, '"><animate attributeName="fill" values="', rgbShade, '" dur="0.05s" repeatCount="indefinite"/></circle>');
            }
        }

        for (uint256 y = 0; y < 4; y++) {
            for (uint x = 0; x < 6; x++) {
                r = abi.encodePacked(r, '<g transform="translate(', itoa(65 + x*50), ', ', itoa(65 + y*50), ')"><use href="#c"></use></g>');
            }
        }

        r = abi.encodePacked(r, '<g transform="translate(-6, -185) scale(3.5)" fill="#444"><path d="M64.85 141.4h0q.07 0 .11.04.04.05.04.11h0v5.27q0 .09-.05.14-.05.04-.12.04h0q-.03 0-.07-.02-.03-.01-.06-.04h0l-3.71-5.08.11-.05v5.05q0 .06-.04.1-.04.04-.11.04h0q-.07 0-.11-.04-.04-.04-.04-.1h0v-5.3q0-.09.05-.12.05-.04.09-.04h0q.04 0 .07.01.03.01.05.05h0l3.7 5.04-.06.16v-5.11q0-.06.04-.11.05-.04.11-.04zm4.63 1.61h0q.07 0 .12.05.04.04.04.11h0v2.33q0 .77-.44 1.16-.43.39-1.15.39h0q-.71 0-1.15-.39-.44-.39-.44-1.16h0v-2.33q0-.07.05-.11.05-.05.11-.05h0q.08 0 .12.05.04.04.04.11h0v2.33q0 .6.34.92.34.32.93.32h0q.59 0 .93-.32.34-.32.34-.92h0v-2.33q0-.07.04-.11.05-.05.12-.05zm-.77-.8h0q-.13 0-.2-.08-.08-.08-.08-.21h0v-.06q0-.13.08-.21.08-.08.21-.08h0q.11 0 .19.08.07.08.07.21h0v.06q0 .13-.07.21-.08.08-.2.08zm-1.3 0h0q-.13 0-.21-.08-.07-.08-.07-.21h0v-.06q0-.13.08-.21.08-.08.21-.08h0q.11 0 .18.08.08.08.08.21h0v.06q0 .13-.08.21-.07.08-.19.08z"/><path transform="translate(-169, -4)" d="M235.06 153.86h0q-.07.05-.08.11 0 .06.04.13h0q.04.05.1.06.06 0 .11-.03h0q.34-.23.73-.37.4-.14.85-.14h0q.51 0 .95.19.45.19.78.53.34.35.53.82.19.47.19 1.04h0q0 .57-.19 1.04-.19.47-.53.82-.33.34-.78.53-.44.19-.95.19h0q-.45 0-.84-.14-.39-.14-.73-.36h0q-.06-.04-.12-.03-.06.01-.1.06h0q-.04.06-.04.12.01.07.07.11h0q.19.13.48.26.29.13.62.2.33.08.66.08h0q.57 0 1.08-.22.5-.21.89-.6.38-.39.6-.91.22-.53.22-1.15h0q0-.62-.22-1.15-.22-.52-.6-.91-.39-.39-.89-.6-.51-.22-1.08-.22h0q-.49 0-.94.14-.45.15-.81.4zm-1.38-.62v5.6q0 .06.05.11.05.05.11.05h0q.07 0 .12-.05.04-.05.04-.11h0v-5.6q0-.06-.05-.11-.05-.05-.11-.05h0q-.07 0-.12.05-.04.05-.04.11h0zm-1.57 5.76h0q.07 0 .12-.05.04-.05.04-.11h0v-5.6q0-.06-.04-.11-.05-.05-.12-.05h0q-.07 0-.11.05-.05.05-.05.11h0v5.6q0 .06.05.11.04.05.11.05zm-2.77-4.04h0q-.07 0-.12.05-.04.05-.04.12h0q0 .07.05.12h0l2.78 2.31.01-.38-2.58-2.17q-.05-.05-.1-.05zm-.05 4.04h0q.06 0 .12-.06h0l1.93-2.06-.24-.21-1.92 2.05q-.05.05-.05.12h0q0 .08.06.12.07.04.1.04z"/><animate attributeName="fill" values="#555;#111;#555" dur="0.05s" repeatCount="indefinite"/></g><script type="text/javascript"><![CDATA[ setInterval(clock,1000);var d=new Date;var secs=d.getSeconds();var mins=d.getMinutes();var hrs=d.getHours();function clock(){if(secs<59){secs+=1}else{secs=0;mins+=1}if(mins==60){mins=0;hrs+=1}if(hrs==24){hrs==0}updateSegments(6,secs);updateSegments(4,mins);updateSegments(2,hrs)}function updateSegments(pos,t){let firstSegment=Number(parseInt(t%10)).toString(2).padStart(4,"0");let secondSegment=Number(parseInt(t/10)).toString(2).padStart(4,"0");for(let i=0;i<4;i+=1){document.getElementById((pos)+"-"+(i+1)).setAttribute("visibility",secondSegment[i]=="1"?"visible":"hidden");document.getElementById((pos+1)+"-"+(i+1)).setAttribute("visibility",firstSegment[i]=="1"?"visible":"hidden")}} ]]></script></svg>');

        r = abi.encodePacked(unicode'{"name":"NüCLK Dúo #', itoa(index), '","description":"Clocks for the Metaverse","image":"data:image/svg+xml;base64,', Base64.encode(r), '", "attributes":[{"trait_type":"Palette","value":"', paletteName, '"}]}');

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(r)));
    }


    function itoa(uint value) internal pure returns (bytes memory) {
        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = _DIGITS[value % 10];
            value /= 10;
        }
        return buffer;
    }

    // LuckySeven - @matiasbn_eth
    function prng(uint256 mu) internal pure returns (uint O) {
        assembly {
            let L := exp(10, 250) // 10^p
            let U := mul(L, 1) // 10^p * b
            let C := exp(10, 10) // 10^n
            let K := sub(C, mu) // 10^n - mu
            let Y := div(U, K) // (10^p * b)/(10^n - mu)
            let S := exp(10, add(2, 3)) // 10^(i+j)
            let E := exp(10, 2) // 10^i
            let V := mod(Y, S) // Y % 10^(i+j)
            let N := mod(Y, E) // Y % 10^i
            let I := sub(V, N) // (Y % 10^(i+j)) / (Y % 10^i)
            O := div(I, E)
        }
    }
}