// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "base64-sol/base64.sol";

contract brconchain is ERC721A, Ownable {
    uint256 public maxSupply = 5000;
    uint256 public maxFree = 1;
    uint256 public maxPerTx = 10;
    uint256 public cost = .002 ether;
    bool public sale;

    mapping(address => uint256) public mintedFreeAmount;

    error SaleNotActive();
    error MaxSupplyReached();
    error MaxPerTxReached();
    error NotEnoughETH();

    constructor() ERC721A("brconchain", "BONX") {}

    function _getRank(uint256 balance) internal pure returns (string memory) {
        if (balance >= 50) {
            return "DIAMOND";
        } else if (balance >= 25) {
            return "PLATINUM";
        } else if (balance >= 15) {
            return "GOLDEN";
        } else if (balance >= 10) {
            return "SILVER";
        } else if (balance >= 5) {
            return "BRONZE";
        } else {
            return "IRON";
        }
    }

    function _isEligible(uint256 balance)
        internal
        pure
        returns (string memory)
    {
        if (balance >= 5) {
            return "ELIGIBLE";
        } else {
            return "NOT ELIGIBLE";
        }
    }

    function _createSVG(address _owner, uint256 _tokenId)
        internal
        view
        returns (string memory)
    {
        uint256 balance = balanceOf(_owner);
        string memory isEligible = _isEligible(balance);
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid meet" viewBox="0 0 1500 1500">',
                "<style>.base { fill: white; font-family: Helvetica, Geneva, sans-serif; } .status_text { stroke: black; stroke-width: 10px; }</style>",
                '<rect width="100%" height="100%" fill="#161616" />',
                '<text x="50%" y="500" class="base" text-anchor="middle" font-size="200px" letter-spacing= "5px">$BONX</text>',
                '<text x="50%" y="700" class="base" text-anchor="middle" font-size="100px" letter-spacing= "5px">{ BRC-20 }</text>',
                '<text x="50%" y="800" class="base" text-anchor="middle" font-size="50px" letter-spacing= "5px">',
                Strings.toHexString(uint160(_owner)),
                '</text><text x="50%" y="900" class="base" text-anchor="middle" font-size="50px">TOKEN ID: ',
                Strings.toString(_tokenId),
                '</text><text x="50%" y="1000" class="base" text-anchor="middle" font-size="50px">RANK: ',
                _getRank(balance),
                '</text><text x="50%" y="1100" class="base" text-anchor="middle" font-size="50px">$BONX BALANCE: ',
                Strings.toString(balance),
                "</text>",
                '<rect x="25%" y="1130" width="50%" height="100" fill="#FF4800" rx="20" ry="20" />',
                '<text x="50%" y="1200" class="base status_text" text-anchor="middle" font-size="50px">STATUS: <tspan fill="',
                (
                    keccak256(bytes(isEligible)) == keccak256(bytes("ELIGIBLE"))
                        ? "#6aff28"
                        : "#f22626"
                ),
                '">',
                isEligible,
                "</tspan></text>",
                '<text x="50%" y="1200" class="base" text-anchor="middle" font-size="50px">STATUS: <tspan fill="',
                (
                    keccak256(bytes(isEligible)) == keccak256(bytes("ELIGIBLE"))
                        ? "#6aff28"
                        : "#f22626"
                ),
                '">',
                isEligible,
                "</tspan></text>",
                "</svg>"
            )
        );
        return svg;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        address owner = ownerOf(tokenId);
        string memory svg = _createSVG(owner, tokenId);
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Token ',
                        Strings.toString(tokenId),
                        '", "description": "$BONX Token", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 _amount) external payable {
        if (!sale) revert SaleNotActive();

        uint256 _cost = (msg.value == 0 &&
            (mintedFreeAmount[msg.sender] + _amount <= maxFree))
            ? 0
            : cost;

        if (_amount > maxPerTx) revert MaxPerTxReached();
        if (msg.value < _cost * _amount) revert NotEnoughETH();
        if (totalSupply() + _amount > maxSupply) revert MaxSupplyReached();

        if (_cost == 0) {
            mintedFreeAmount[msg.sender] += _amount;
        }

        _safeMint(msg.sender, _amount);
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

    function setSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function ownerMint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}