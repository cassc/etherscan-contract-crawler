// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "base64-sol/base64.sol";

contract whoiswhale is ERC721A, Ownable {
    uint256 public maxSupply = 5555;
    uint256 public maxFree = 1;
    uint256 public maxPerTx = 10;
    uint256 public cost = .003 ether;
    bool public sale;

    mapping(address => uint256) private _mintedFreeAmount;

    error SaleNotActive();
    error MaxSupplyReached();
    error MaxPerTxReached();
    error NotEnoughETH();
    error AlreadyMintedMore();

    constructor() ERC721A("whoiswhale_", "wiw") {}

    function _randomRGB() private view returns (string memory) {
        uint256 r = (uint256(keccak256(abi.encodePacked(block.timestamp))) %
            128) + 128;
        uint256 g = (uint256(keccak256(abi.encodePacked(block.timestamp, r))) %
            64) + 128;
        uint256 b = (uint256(keccak256(abi.encodePacked(block.timestamp, g))) %
            128) + 128;
        return
            string(
                abi.encodePacked(
                    "rgb(",
                    Strings.toString(r),
                    ",",
                    Strings.toString(g),
                    ",",
                    Strings.toString(b),
                    ")"
                )
            );
    }

    function _getRank(uint256 balance) private pure returns (string memory) {
        if (balance >= 10 ether) {
            return "Extraordinary";
        } else if (balance >= 5 ether) {
            return "Mythical";
        } else if (balance >= 3 ether) {
            return "Elite";
        } else if (balance >= 1 ether) {
            return "Superior";
        } else if (balance >= 0.5 ether) {
            return "Advanced";
        } else {
            return "Novice";
        }
    }

    function _createSVG(
        address owner,
        uint256 balance,
        uint256 tokenId
    ) private view returns (string memory) {
        string memory color = _randomRGB();
        string memory rank = _getRank(balance);
        uint256 ethBalanceScaled = (balance * 100) / (10**18);
        uint256 ethBalanceWhole = ethBalanceScaled / 100;
        uint256 ethBalanceFraction = ethBalanceScaled % 100;

        string memory shapes = _createRandomShapes();

        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" width="1000" height="1000">',
                    "<defs>",
                    '<linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="0%">',
                    '<stop offset="0%" style="stop-color:rgb(0,0,0);stop-opacity:1" />',
                    '<stop offset="100%" style="stop-color:rgb(30,30,30);stop-opacity:1" />',
                    "</linearGradient>",
                    '<filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">',
                    '<feGaussianBlur in="SourceAlpha" stdDeviation="8" result="blur" />',
                    '<feOffset in="blur" dx="6" dy="6" result="offsetBlur" />',
                    "<feMerge>",
                    '<feMergeNode in="offsetBlur" />',
                    '<feMergeNode in="SourceGraphic" />',
                    "</feMerge>",
                    "</filter>",
                    "</defs>",
                    '<rect width="100%" height="100%" fill="url(#grad1)" />',
                    shapes,
                    '<rect x="125" y="500" width="750" height="100" fill="#092B02" stroke="#33E80A" stroke-width="1" />',
                    '<text x="50%" y="250" font-family="Courier,monospace" font-size="40" fill="',
                    color,
                    '" text-anchor="middle" dominant-baseline="central" filter="url(#shadow)">',
                    Strings.toHexString(uint160(owner)),
                    "</text>",
                    '<text x="50%" y="400" font-family="Courier,monospace" font-size="60" fill="',
                    color,
                    '" text-anchor="middle" dominant-baseline="central" filter="url(#shadow)">Token: ',
                    Strings.toString(tokenId),
                    "</text>",
                    '<text x="50%" y="550" font-family="Courier,monospace" font-size="50" fill="#33E80A" text-anchor="middle" dominant-baseline="central" filter="url(#shadow)">ACCESS GRANTED</text>',
                    '<text x="50%" y="700" font-family="Courier,monospace" font-size="50" fill="',
                    color,
                    '" text-anchor="middle" dominant-baseline="central" filter="url(#shadow)">Rank: ',
                    rank,
                    "</text>",
                    '<text x="50%" y="850" font-family="Courier,monospace" font-size="50" fill="',
                    color,
                    '" text-anchor="middle" dominant-baseline="central" filter="url(#shadow)">Balance: ',
                    Strings.toString(ethBalanceWhole),
                    ".",
                    ethBalanceFraction < 10 ? "0" : "",
                    Strings.toString(ethBalanceFraction),
                    " ETH</text>",
                    "</svg>"
                )
            );
    }

    function _createRandomShapes() private view returns (string memory) {
        uint256 shapeCount = 3 +
            (uint256(keccak256(abi.encodePacked(block.timestamp))) % 3);
        string memory shapes = "";

        for (uint256 i = 0; i < shapeCount; i++) {
            string memory shape = _randomShape();
            shapes = string(abi.encodePacked(shapes, shape));
        }

        return shapes;
    }

    function _randomShape() private view returns (string memory) {
        uint256 shapeType = uint256(
            keccak256(abi.encodePacked(block.timestamp))
        ) % 3;
        string memory shape;

        if (shapeType == 0) {
            shape = _createRandomCircle();
        } else if (shapeType == 1) {
            shape = _createRandomRectangle();
        } else {
            shape = _createRandomTriangle();
        }

        return shape;
    }

    function _createRandomCircle() private view returns (string memory) {
        uint256 cx = uint256(keccak256(abi.encodePacked(block.timestamp))) %
            1000;
        uint256 cy = uint256(keccak256(abi.encodePacked(block.timestamp, cx))) %
            1000;
        uint256 r = 10 +
            (uint256(keccak256(abi.encodePacked(block.timestamp, cy))) % 90);
        string memory fillColor = _randomRGB();

        return
            string(
                abi.encodePacked(
                    '<circle cx="',
                    Strings.toString(cx),
                    '" cy="',
                    Strings.toString(cy),
                    '" r="',
                    Strings.toString(r),
                    '" fill="',
                    fillColor,
                    '" />'
                )
            );
    }

    function _createRandomRectangle() private view returns (string memory) {
        uint256 x = uint256(keccak256(abi.encodePacked(block.timestamp))) %
            1000;
        uint256 y = uint256(keccak256(abi.encodePacked(block.timestamp, x))) %
            1000;
        uint256 width = 10 +
            (uint256(keccak256(abi.encodePacked(block.timestamp, y))) % 90);
        uint256 height = 10 +
            (uint256(keccak256(abi.encodePacked(block.timestamp, width))) % 90);
        string memory fillColor = _randomRGB();

        return
            string(
                abi.encodePacked(
                    '<rect x="',
                    Strings.toString(x),
                    '" y="',
                    Strings.toString(y),
                    '" width="',
                    Strings.toString(width),
                    '" height="',
                    Strings.toString(height),
                    '" fill="',
                    fillColor,
                    '" />'
                )
            );
    }

    function _createRandomTriangle() private view returns (string memory) {
        uint256 x1 = uint256(keccak256(abi.encodePacked(block.timestamp))) %
            1000;
        uint256 y1 = uint256(keccak256(abi.encodePacked(block.timestamp, x1))) %
            1000;
        uint256 x2 = uint256(keccak256(abi.encodePacked(block.timestamp, y1))) %
            1000;
        uint256 y2 = uint256(keccak256(abi.encodePacked(block.timestamp, x2))) %
            1000;
        uint256 x3 = uint256(keccak256(abi.encodePacked(block.timestamp, y2))) %
            1000;
        uint256 y3 = uint256(keccak256(abi.encodePacked(block.timestamp, x3))) %
            1000;
        string memory fillColor = _randomRGB();

        return
            string(
                abi.encodePacked(
                    '<polygon points="',
                    Strings.toString(x1),
                    ",",
                    Strings.toString(y1),
                    " ",
                    Strings.toString(x2),
                    ",",
                    Strings.toString(y2),
                    " ",
                    Strings.toString(x3),
                    ",",
                    Strings.toString(y3),
                    '" fill="',
                    fillColor,
                    '" />'
                )
            );
    }

    function mint(uint256 _amount) external payable {
        if (!sale) revert SaleNotActive();

        uint256 _cost = (msg.value == 0 &&
            (_mintedFreeAmount[msg.sender] + _amount <= maxFree))
            ? 0
            : cost;

        if (_amount > maxPerTx) revert MaxPerTxReached();
        if (msg.value < _cost * _amount) revert NotEnoughETH();
        if (totalSupply() + _amount > maxSupply) revert MaxSupplyReached();

        if (_cost == 0) {
            _mintedFreeAmount[msg.sender] += _amount;
        }

        _safeMint(msg.sender, _amount);
    }

    function _getEthBalance(address owner) private view returns (uint256) {
        return address(owner).balance;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        address owner = ownerOf(tokenId);
        uint256 balance = _getEthBalance(owner);
        string memory rank = _getRank(balance);
        string memory svg = _createSVG(owner, balance, tokenId);

        string memory encodedSvg = Base64.encode(bytes(svg));

        string memory json = string(
            abi.encodePacked(
                "{",
                '"name": "whoiswhale #',
                Strings.toString(tokenId),
                '",',
                '"description": "Meet whoiswhale_, a unique and innovative on-chain asset that adapts to its holders Eth balance. With its ever-changing rank and ability to serve as a versatile gateway pass for future drops, youll feel the true essence of fluidity and exclusivity in the world of digital collectibles.",',
                '"image": "data:image/svg+xml;base64,',
                encodedSvg,
                '",',
                '"attributes": [',
                "{",
                '"trait_type": "Rank",',
                '"value": "',
                rank,
                '"',
                "}",
                "]",
                "}"
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(json))
                )
            );
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function startSale() external onlyOwner {
        sale = !sale;
    }

    function setPrice(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setMaxFreeMint(uint256 _maxFree) external onlyOwner {
        maxFree = _maxFree;
    }

    function cutSupply(uint256 _maxSupply) external onlyOwner {
        if (_maxSupply >= maxSupply) revert MaxSupplyReached();
        if (_totalMinted() > _maxSupply) revert AlreadyMintedMore();
        maxSupply = _maxSupply;
    }

    function ownerMint(address _to, uint256 _amount) external onlyOwner {
        if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
        _mint(_to, _amount);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}