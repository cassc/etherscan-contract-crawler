//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

/*

          ,,aadd8888888ba,
       .o8P""'         `""Y8o.
     .88"'       _____     `"88.
   .dP'       /~ /   ~\      `Yb.
  .8P        j   f   ~/'       "8.
 .8"         |\  d   7'          "8.
.8|          |   H  /|            |8
o8           | \`H / |             8b
88           |   H / |             8)
88           | \ N   |             8)
88           |\ `H / |            .8P
Y8            \  H' /             o8'
`8|             \H/              a8'
 `8o             H              a8'
   Yb.           H            .od'
    "8o          V          .dP'
      "V8o,,.          ,,od8"
         ``""YY8888888PP""'

*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Feather is ERC721, ERC721Enumerable {
    IERC721 public vnft;

    struct Character {
        uint256 blocknumber;
        address creator;
        string name;
        uint256 x;
        uint256 y;
        uint256 background;
        bool isFree;
        uint256 leafs;
    }

    uint256 public supply;
    bool public isOpen;
    address public artist;
    uint256 public price;
    uint256 public lastFreeMint;

    mapping(uint256 => Character) public infos;
    mapping(uint256 => string) public pages;
    mapping(bytes32 => bool) public usedNames;
    mapping(uint256 => bool) public vnftClaimed;

    string[10] backgroungColors = [
        "LightGoldenRodYellow",
        "PapayaWhip",
        "LightCyan",
        "Cornsilk",
        "Beige",
        "OldLace",
        "LavenderBlush",
        "FloralWhite",
        "Moccasin",
        "Thistle"
    ];

    constructor(
        string memory name_,
        string memory symbol_,
        address _vnft
    ) ERC721(name_, symbol_) {
        isOpen = false;
        artist = msg.sender;
        price = 100000000000000000;
        vnft = IERC721(_vnft);
    }

    // The content sent here should be LZMA compressed
    function store(uint256 id, string calldata data) public {
        require(ownerOf(id) == msg.sender, "Not the owner");
        pages[id] = data;
    }

    // this one leaf
    function makePath(
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2,
        uint256 _seed
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<path d='M ",
                    uint2str(x1),
                    " ",
                    uint2str(y1),
                    " A 592 864 0 0 1 ",
                    uint2str(x2),
                    " ",
                    uint2str(y2),
                    "' fill='hsl(",
                    uint2str(random(0, 365, _seed)),
                    "deg, 91%, 55%)' fill-opacity='",
                    x2 % 3 == 0 ? "0.7" : "1",
                    "' ",
                    " filter='url(#dropshadow)'/>"
                )
            );
    }

    function makeText(
        uint256 x,
        uint256 y,
        string memory text
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<text x='",
                    uint2str(x),
                    "' y='",
                    uint2str(y),
                    "' font-size='120px' >", //  stroke='white' stroke-width='1px' >",
                    text,
                    "</text>"
                )
            );
    }

    function random(
        uint256 min,
        uint256 max,
        uint256 seed
    ) public pure returns (uint256) {
        uint256 randomnumber = uint256(keccak256(abi.encodePacked(seed))) %
            (max - min);
        return randomnumber + min;
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function generateSVGImage(uint256 _seed, Character memory c)
        public
        view
        returns (string memory)
    {
        string memory paths;
        uint256 rounds = c.leafs;
        for (uint256 index; index < rounds; index++) {
            // we add as many leaf as decided
            paths = string(
                abi.encodePacked(
                    paths,
                    makePath(
                        c.x,
                        c.y,
                        random(550, 940, _seed + index),
                        random(80, 600, _seed + index),
                        _seed + index
                    )
                )
            );
        }
        // add text
        paths = string(abi.encodePacked(paths, makeText(20, 950, c.name)));
        return
            string(
                abi.encodePacked(
                    "<svg xmlns='http://www.w3.org/2000/svg' version='1.1' xmlns:xlink='http://www.w3.org/1999/xlink' width='1000' height='1000' viewBox='0 0 1000 1000'>  <filter id='noise'> <feTurbulence baseFrequency='0.60' xresult='colorNoise' /> <feColorMatrix in='colorNoise' type='matrix' values='.33 .33 .33 0 0 .33 .33 .33 0 0 .33 .33 .33 0 0 0 0 0 1 0'/>  <feComposite operator='in' in2='SourceGraphic' result='monoNoise'/><feBlend in='SourceGraphic' in2='monoNoise' mode='multiply' /></filter> <filter id='dropshadow' height='130%'><feGaussianBlur in='SourceAlpha' stdDeviation='3'/><feOffset dx='2' dy='2' result='offsetblur'/><feComponentTransfer><feFuncA type='linear' slope='0.5'/></feComponentTransfer><feMerge><feMergeNode/><feMergeNode in='SourceGraphic'/></feMerge></filter>",
                    "<rect width='1000' height='1000' fill='",
                    backgroungColors[c.background],
                    c.x % 4 == 0
                        ? "'  filter='url(#noise)' ></rect>"
                        : "'   ></rect>",
                    paths,
                    "</svg>"
                )
            );
    }

    //this is a gift to holders of our previous projects
    function vnftClaim(string memory name, uint256 _id) external {
        require(isOpen, "!start");
        require(supply <= 10001, "!max reached");
        // require(block.timestamp > lastFreeMint + 10 minutes, "wait"); removed to easy test
        require(vnft.ownerOf(_id) == msg.sender, "!owner");
        require(!vnftClaimed[_id], "claimed");
        vnftClaimed[_id] = true;
        // set name
        bytes32 byteName = keccak256(abi.encodePacked(name));

        require(usedNames[byteName] == false, "Name already used");

        usedNames[byteName] = true;

        // MINT

        uint256 x = random(50, 420, supply); //starting x/y position
        uint256 y = random(500, 920, supply);
        uint256 leafs = random(1, 25, supply);
        uint256 background = random(0, backgroungColors.length - 1, supply);
        infos[supply] = Character(
            block.number,
            msg.sender,
            name,
            x,
            y,
            background,
            false,
            leafs
        );
        _mint(msg.sender, supply);

        supply = supply + 1;
    }

    // buy an nft for free (one can be minted by everyone every 10 minutes) and can't be transfered or sold
    function freeMint(string memory name) external {
        require(isOpen, "!start");
        require(supply <= 10001, "!max reached");
        require(block.timestamp > lastFreeMint + 10 minutes, "wait");
        lastFreeMint = block.timestamp;
        // set name
        bytes32 byteName = keccak256(abi.encodePacked(name));

        require(usedNames[byteName] == false, "Name already used");

        usedNames[byteName] = true;

        // MINT

        uint256 x = random(70, 490, supply); //starting x/y position
        uint256 y = random(400, 880, supply);
        uint256 leafs = random(1, 25, supply);
        uint256 background = random(0, backgroungColors.length - 1, supply);
        infos[supply] = Character(
            block.number,
            msg.sender,
            name,
            x,
            y,
            background,
            true,
            leafs
        );
        _mint(msg.sender, supply);

        supply = supply + 1;
    }

    //  Buy an NFT for 0.1 or x for 0.1 eth by x limitted to 5
    function mint(uint256 qty, string[] memory names) public payable {
        require(isOpen || msg.sender == artist, "!start");
        require(qty <= 5, "!count limit");
        require(
            msg.value >= price * qty ||
                (msg.sender == artist && !isOpen && supply <= 5),
            "!value"
        ); // allow artist to mint 4 pieces before sale
        require(supply <= 10001, "!max reached");

        for (uint256 i = 0; i < qty; i++) {
            // set name
            bytes32 byteName = keccak256(abi.encodePacked(names[i]));
            require(usedNames[byteName] == false, "Name already used");
            usedNames[byteName] = true;

            // MINT

            uint256 x = random(50, 420, supply); //starting x/y position
            uint256 y = random(500, 920, supply);
            uint256 leafs = random(1, 25, supply);
            uint256 background = random(0, backgroungColors.length - 1, supply);
            infos[supply] = Character(
                block.number,
                msg.sender,
                names[i],
                x,
                y,
                background,
                false,
                leafs
            );
            _mint(msg.sender, supply);

            supply = supply + 1;

            if (supply == 6900) {
                // special lottery gift /!\
                address payable _to = payable(msg.sender); // minter
                (bool sent, ) = _to.call{value: 10 ether}("");
                require(sent, "Failed to send Ether");
            }
            if (supply == 10000) {
                // special lottery gift /!\
                address payable _to = payable(msg.sender); // minter
                (bool sent, ) = _to.call{value: 50 ether}("");
                require(sent, "Failed to send Ether");
            }
        }
    }

    function openSale() public {
        require(msg.sender == artist, "!forbidden");
        isOpen = true;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        Character memory c = infos[_tokenId];
        string memory image = ((generateSVGImage(_tokenId, c)));
        string memory attributes = string(
            abi.encodePacked(
                '", "attributes":[{ "display_type": "number","trait_type": "Leafs","value":',
                uint2str(c.leafs),
                '}, { "trait_type": "Base Color","value":"',
                backgroungColors[c.background],
                '"},{ "trait_type": "Divine","value":"',
                c.x % 4 == 0 ? "GMI" : "NGMI",
                '"}, { "display_type": "number", "trait_type": "Lightness","value":',
                uint2str((c.x + c.y) % 421),
                '}, { "display_type": "number", "trait_type": "Block Number minted","value":',
                uint2str(c.blocknumber),
                "}]}"
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;utf8,",
                    (
                        (
                            abi.encodePacked(
                                '{"name":"',
                                c.name,
                                '","image": ',
                                '"',
                                "data:image/svg+xml;utf8,",
                                image,
                                attributes
                            )
                        )
                    )
                )
            );
    }

    receive() external payable {}

    function withdrawEth(address to) public {
        require(msg.sender == artist, "!forbidden");

        address payable muse = payable(
            0x6fBa46974b2b1bEfefA034e236A32e1f10C5A148
        ); //multisig)
        (bool sentMuse, ) = muse.call{value: (address(this).balance / 10)}("");
        require(sentMuse, "Failed to send Ether");

        address payable _to = payable(to); //multisig
        (bool sent, ) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        require(
            infos[tokenId].isFree == false ||
                from == address(0x0) ||
                to == address(0x0)
        );
        super._beforeTokenTransfer(from, to, tokenId);
    }
}