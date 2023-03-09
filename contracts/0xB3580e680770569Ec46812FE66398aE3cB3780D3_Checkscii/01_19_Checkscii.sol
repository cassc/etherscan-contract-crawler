// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./interfaces/IERC4906.sol";

contract Checkscii is
    ERC721,
    IERC2981,
    IERC4906,
    Ownable,
    DefaultOperatorFilterer
{   
    bool    public mintEnabled     = false;
    uint256 public maxPerWallet    = 50;
    uint256 public maxSupply       = 5000;
    uint256 public price           = 0.0025 ether;

    uint256 private _totalSupply;

    struct Check {
        uint256 seed;
        bool lightMode;
    }

    mapping(uint256 => Check) public checks;
    mapping(address => uint256) public hasMinted;
    mapping(address => uint256) public hasBurned;

    string[55] private colorPalette = [
        "#e60049",
        "#82b6b9",
        "#b3d4ff",
        "#00ffff",
        "#0bb4ff",
        "#1853ff",
        "#35d435",
        "#61ff75",
        "#00bfa0",
        "#fd7f6f",
        "#d0f400",
        "#9b19f5",
        "#f46a9b",
        "#bd7ebe",
        "#fdcce5",
        "#fce74c",
        "#eeeeee",
        "#7f766d",
        "#ff6666",
        "#ff99cc",
        "#ffa500",
        "#ffa07a",
        "#ffd700",
        "#ff1493",
        "#ff7f50",
        "#ff00ff",
        "#ffb6c1",
        "#ff69b4",
        "#ffc0cb",
        "#ffdead",
        "#ff7f24",
        "#ff00bf",
        "#ff7256",
        "#ff82ab",
        "#ffc3a0",
        "#fa8072",
        "#ff4500",
        "#ffb347",
        "#ffff00",
        "#00ff00",
        "#ff007f",
        "#00ff80",
        "#ff0099",
        "#00ffbf",
        "#ff0066",
        "#00ffcc",
        "#ff0033",
        "#00ffd9",
        "#ff0000",
        "#00ffee",
        "#ff3300",
        "#00ff99",
        "#ff6600",
        "#00ff66",
        "#ff9900"
    ];

    uint8[20] private positions = [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19
    ];

    uint16[2][20] private coordinates = [
        [600, 498],
        [816, 498],
        [1032, 498],
        [1248, 498],
        [600, 708],
        [816, 708],
        [1032, 708],
        [1248, 708],
        [600, 918],
        [816, 918],
        [1032, 918],
        [1248, 918],
        [600, 1128],
        [816, 1128],
        [1032, 1128],
        [1248, 1128],
        [600, 1338],
        [816, 1338],
        [1032, 1338],
        [1248, 1338]
    ];

    error MintNotLive();
    error AlreadyMaxMinted();
    error NotEnoughETH();
    error NoneLeft();
    error TokenDoesNotExist();
    error NotApprovedOrOwner();
    error WithdrawalFailed();

    constructor() ERC721("Checkscii", "CHECKSCII"){}

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function mint(uint256 amount) external payable {
        if (!mintEnabled) {
            revert MintNotLive();
        }
        if (hasMinted[msg.sender] + amount > maxPerWallet) {
            revert AlreadyMaxMinted();
        }
        if (msg.value < amount * price) {
            revert NotEnoughETH();
        }
        if (_totalSupply + amount > maxSupply) {
            revert NoneLeft();
        }

        uint256 next = _totalSupply;
        _totalSupply += amount;
        hasMinted[msg.sender] += amount;
        for (uint256 i = 1; i <= amount; i++) {
            uint256 tokenId = next + i;
            checks[tokenId].seed = uint256(
                    keccak256(
                        abi.encodePacked(msg.sender, block.coinbase, _totalSupply, tokenId)
                )
            );

            _mint(msg.sender, tokenId);
        }
    }

    function toggleTokenMode(uint256 tokenId) external {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotApprovedOrOwner();
        }

        checks[tokenId].lightMode = !checks[tokenId].lightMode;
        emit MetadataUpdate(tokenId);
    }

    function getFrame(uint256 tokenId) internal view returns (string memory) {
        if (checks[tokenId].lightMode) {
            return
                "<path d='M2000 0H0V2000H2000V0Z' fill='#ffffff'/><path d='M1448.89 447.852H551.107V1552.15H1448.89V447.852Z' fill='#ffffff' />";
        }

        return
            "<path d='M2000 0H0V2000H2000V0Z' fill='#111112'/><path d='M1448.89 447.852H551.107V1552.15H1448.89V447.852Z' fill='#111112' />";
    }

    function getCheck(
        uint256 tokenId,
        uint8 i,
        string[55] memory shuffledColorPalette,
        uint256 colors
    ) internal view returns (string memory) {
        uint256 colorPaletteIndex = uint256(
            uint256(checks[tokenId].seed + i) %
                colors
        );

        return
            string(
                abi.encodePacked(
                        "<text  x='60' y='40' color='#FFFFFF' font-family='Courier,monospace' font-weight='700' font-size='60' text-anchor='middle' letter-spacing='1'><tspan fill='",
                        shuffledColorPalette[colorPaletteIndex],
                        "'>\xE2\x8F\x9E</tspan><tspan  dy='22' x='60' fill='",
                        shuffledColorPalette[colorPaletteIndex],
                        "'>\x7B\xE2\x9C\x93\x7D</tspan><tspan dy='26' x='60' fill='",
                        shuffledColorPalette[colorPaletteIndex],
                        "'>\xE2\x8F\x9F</tspan></text>"
                )
            );
    }

    function shufflePositions(
        uint256 tokenId
    ) internal view returns (uint8[20] memory) {
        uint8[20] memory shuffledPositions = positions;

        for (uint i = 0; i < shuffledPositions.length; ) {
            uint j = checks[tokenId].seed % (i + 1);
            uint8 temp = shuffledPositions[i];

            shuffledPositions[i] = shuffledPositions[j];
            shuffledPositions[j] = temp;

            unchecked {
                ++i;
            }
        }

        return shuffledPositions;
    }

    function shuffleColors(
        uint256 tokenId
    ) internal view returns (string[55] memory) {
        string[55] memory shuffledColors = colorPalette;

        for (uint i = 0; i < shuffledColors.length; ) {
            uint j = checks[tokenId].seed % (i + 1);
            string memory temp = shuffledColors[i];

            shuffledColors[i] = shuffledColors[j];
            shuffledColors[j] = temp;

            unchecked {
                ++i;
            }
        }

        return shuffledColors;
    }

    function getColors( 
        uint256 tokenId 
    ) internal view returns (uint256) {
        uint256 tokenIndex = checks[tokenId].seed % 2;
        uint256 colors = 20;

        if (tokenIndex == 0) {
            colors = (checks[tokenId].seed + tokenId) % 20;
            colors = 20 - colors;
        }

        colors = colors < 21 ? colors : 20;
        return colors;
    }

    function getGrid(
        uint256 tokenId
    ) internal view returns (string memory grid) {
                string[55] memory shuffledColorPalette = shuffleColors(tokenId);
                uint256 colors = getColors(tokenId);
        for (uint8 i = 0; i < 20; ) {
            uint8[20] memory shuffledPositions = shufflePositions(tokenId);

            uint8 positionIndex = colors > 0
                ? shuffledPositions[i]
                : i;

                grid = string(
                    abi.encodePacked(
                        grid,
                        "<g transform='translate(",
                        Strings.toString(coordinates[positionIndex][0]),
                        " ",
                        Strings.toString(coordinates[positionIndex][1]),
                        ")'>",
                        getCheck(tokenId, i, shuffledColorPalette, colors),
                        "</g>"
                    )
                );

            unchecked {
                ++i;
            }
        }

        return grid;
    }

    function getTokenIdSvg(
        uint256 tokenId
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 2000 2000'>",
                    getFrame(tokenId),
                    getGrid(tokenId),
                    "</svg>"
                )
            );
    }

    function getTokenIdMetadata(
        uint256 tokenId
    ) internal view returns (string memory metadata) {
        uint256 colors = getColors(tokenId);
        metadata = string(
            abi.encodePacked(
                '{"trait_type": "Mode", "value": "',
                checks[tokenId].lightMode ? "Light" : "Dark",
                '"}'
            )
        );

        if (colors > 0) {
            metadata = string(
                abi.encodePacked(
                    metadata,
                    ',{"trait_type": "Colors", "value": "',
                    Strings.toString(colors),
                    '"}'
                )
            );
        }

        return metadata;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Checkscii #',
                                    Strings.toString(tokenId),
                                    '", "description": "ASCII art? Check. On-chain? Check. Notable? Maybe.", "image": "data:image/svg+xml;base64,',
                                    Base64.encode(
                                        bytes(getTokenIdSvg(tokenId))
                                    ),
                                    '","attributes":[',
                                    getTokenIdMetadata(tokenId),
                                    "]}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function burn(uint256 tokenId) external {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotApprovedOrOwner();
        }

        --_totalSupply;
        // Burn baby burn
        ++hasBurned[msg.sender];
        _burn(tokenId);
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance <= 0) {
            revert NotEnoughETH();
        }
        _withdraw(_msgSender(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        if (!success) {
            revert WithdrawalFailed();
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, ERC721) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == bytes4(0x49064906) ||
            super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) public view returns (address, uint256) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }

        return (owner(), (salePrice * 69) / 1000);
    }
}