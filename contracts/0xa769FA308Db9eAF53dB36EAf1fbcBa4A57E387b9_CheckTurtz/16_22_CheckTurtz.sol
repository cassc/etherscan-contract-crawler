// SPDX-License-Identifier: MIT

/*

((((((((((((((((((((((((((((((((((((((((((          
((((((((((((((((((((((((((((((((((((((((((             
((((((((((((((((((((((((((((((((((((((((((             
((((((((((((((((((((((((((((((((((((((((((             
((((((((((((((((((((((((((((((((((((((((((             
((((((((((((((((((((((((((((((((((((((((((             
((((((((((((((                            ((((((((((((((
((((((((((((((                            ((((((((((((((
((((((((((((((                            ((((((((((((((
((((((((((((((                            ((((((((((((((
((((((((((((((                            ((((((((((((((
((((((((((((((                            ((((((((((((((
((((((((((((((              @@@@@@@@@@@@@@((((((((((((((
((((((((((((((              @@@@@@@@@@@@@@((((((((((((((
((((((((((((((              @@@@@@@@@@@@@@((((((((((((((
((((((((((((((              @@@@@@@@@@@@@@((((((((((((((
((((((((((((((              @@@@@@@@@@@@@@((((((((((((((
((((((((((((((              @@@@@@@@@@@@@@((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((

*/

// @title Check Turtz
// @author @tom_hirst
// @notice A fully on-chain, gamified Tiny Winged Turtlez x Checks derivative

/*

How it works:

- Anyone can mint a Check Turtz NFT for free + gas
- There is a mint limit of 1 Check Turtz NFT per wallet
- Minting will last for 72 hours as an open edition with no max supply
- Holding Tiny Winged Turtlez and/or Checks NFTs in the wallet you mint from unlocks differentiated art
- Your minted Check Turtz NFT will receive a Colors trait based on the number of Tiny Winged Turtlez and/or Checks NFTs you hold
- Example 1: If you hold 5 Tiny Winged Turtlez in your wallet when you mint, your Check Turtz NFT will have a Colors trait of 5
- Example 2: If you hold 10 Checks NFTs in your wallet when you mint, your Check Turtz NFT will have a Colors trait of 10
- Example 3: If you hold 5 Tiny Winged Turtlez and 10 Checks NFTs in your wallet when you mint, your Check Turtz NFT will have a Colors trait of 15
- The maximum Colors trait value is 80. This is the number of elements in the original Checks piece by @jackbutcher
- Check Turtz NFTs with a Colors trait feature pseudo-random elements in their art
- For example, if your Check Turtz NFT has a Colors trait value of 5, its artwork will have 5 pseudo-randomly coloured and positioned elements
- Colours and positions used are distinct per Check Turtz NFT with differentiated art
- The colour palette is inspired by the original Checks piece designed by @jackbutcher
- Color traits are assigned at mint time and won't change thereafter
- For example, your Check Turtz NFT will still have a Colors trait of 5, even if you no longer hold the 5 Tiny Winged Turtlez and/or Checks NFTs used to unlock it
- Tiny Winged Turtlez and Checks NFTs are NOT burned
- Check Turtz NFTs are burnable

*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./lib/CheckTurtzDelegateBalance.sol";
import "./interfaces/IERC4906.sol";

contract CheckTurtz is
    ERC721,
    IERC2981,
    IERC4906,
    Ownable,
    DefaultOperatorFilterer,
    CheckTurtzDelegateBalance
{
    address public immutable TINY_WINGED_TURTLEZ_ADDRESS;
    address public immutable CHECKS_ADDRESS;

    uint256 public mintEnds;

    // @dev Just in case
    address public checksV2Address;

    uint256 private _totalSupply;
    uint256 private nextTokenId;

    struct CheckTurt {
        uint16 colors;
        uint256 psuedoRandomNumber;
        bool darkMode;
    }

    mapping(uint256 => CheckTurt) public checkTurtz;

    mapping(address => bool) public hasMinted;

    string[80] private colorPalette = [
        "#DB395E",
        "#602263",
        "#5C83CB",
        "#B1EFC9",
        "#25438C",
        "#7A2520",
        "#85C33C",
        "#C23532",
        "#2E668B",
        "#F6CBA6",
        "#DA3321",
        "#2D5352",
        "#5FCD8C",
        "#4291A8",
        "#EF8C37",
        "#535687",
        "#F2A43A",
        "#5ABAD3",
        "#D6F4E1",
        "#D1DF4F",
        "#A4C8EE",
        "#EF8933",
        "#A7DDF9",
        "#9DEFBF",
        "#525EAA",
        "#EC7368",
        "#FBEA5B",
        "#93CF98",
        "#EB5A2A",
        "#B82C36",
        "#EA3A2D",
        "#F6CB45",
        "#33758D",
        "#F09837",
        "#9AD9FB",
        "#F7DD9B",
        "#FAE663",
        "#F4BDBE",
        "#F7CA57",
        "#EE837D",
        "#ED7C30",
        "#3E8BA3",
        "#F0A0CA",
        "#4D3658",
        "#81D1EC",
        "#3B2F39",
        "#F2A93B",
        "#60B1F4",
        "#977A31",
        "#D5332F",
        "#E73E53",
        "#2F2243",
        "#DB4D58",
        "#F2A93C",
        "#5A9F3E",
        "#6D2F22",
        "#4068C1",
        "#F9DA4D",
        "#77D3DE",
        "#6A552A",
        "#8A2235",
        "#FAE272",
        "#EB4429",
        "#E0C963",
        "#F9DA4A",
        "#C7EDF2",
        "#F2B341",
        "#EA5B33",
        "#D97D2E",
        "#ABDD45",
        "#F2A840",
        "#EE828F",
        "#322F92",
        "#E8424E",
        "#2E4985",
        "#5FC9BF",
        "#F9DB49",
        "#4AA392",
        "#DE3237",
        "#7A5AB4"
    ];

    uint8[80] private positions = [
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
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        35,
        36,
        37,
        38,
        39,
        40,
        41,
        42,
        43,
        44,
        45,
        46,
        47,
        48,
        49,
        50,
        51,
        52,
        53,
        54,
        55,
        56,
        57,
        58,
        59,
        60,
        61,
        62,
        63,
        64,
        65,
        66,
        67,
        68,
        69,
        70,
        71,
        72,
        73,
        74,
        75,
        76,
        77,
        78,
        79
    ];

    uint16[2][80] private coordinates = [
        [600, 498],
        [708, 498],
        [816, 498],
        [924, 498],
        [1032, 498],
        [1140, 498],
        [1248, 498],
        [1356, 498],
        [600, 603],
        [708, 603],
        [816, 603],
        [924, 603],
        [1032, 603],
        [1140, 603],
        [1248, 603],
        [1356, 603],
        [600, 708],
        [708, 708],
        [816, 708],
        [924, 708],
        [1032, 708],
        [1140, 708],
        [1248, 708],
        [1356, 708],
        [600, 813],
        [708, 813],
        [816, 813],
        [924, 813],
        [1032, 813],
        [1140, 813],
        [1248, 813],
        [1356, 813],
        [600, 918],
        [708, 918],
        [816, 918],
        [924, 918],
        [1032, 918],
        [1140, 918],
        [1248, 918],
        [1356, 918],
        [600, 1023],
        [708, 1023],
        [816, 1023],
        [924, 1023],
        [1032, 1023],
        [1140, 1023],
        [1248, 1023],
        [1356, 1023],
        [600, 1128],
        [708, 1128],
        [816, 1128],
        [924, 1128],
        [1032, 1128],
        [1140, 1128],
        [1248, 1128],
        [1356, 1128],
        [600, 1233],
        [708, 1233],
        [816, 1233],
        [924, 1233],
        [1032, 1233],
        [1140, 1233],
        [1248, 1233],
        [1356, 1233],
        [600, 1338],
        [708, 1338],
        [816, 1338],
        [924, 1338],
        [1032, 1338],
        [1140, 1338],
        [1248, 1338],
        [1356, 1338],
        [600, 1443],
        [708, 1443],
        [816, 1443],
        [924, 1443],
        [1032, 1443],
        [1140, 1443],
        [1248, 1443],
        [1356, 1443]
    ];

    error MintEndsInPast();
    error EmptyTWTContract();
    error EmptyChecksContract();
    error ChecksV2AlreadySet();
    error EmptyChecksV2Contract();
    error MintingEnded();
    error AlreadyMinted();
    error TokenDoesNotExist();
    error NotApprovedOrOwner();

    constructor(
        uint256 _mintEnds,
        address _twtAddress,
        address _checksAddress,
        address _warmWalletAddress
    )
        ERC721("Check Turtz", "CHECKTURTZ")
        CheckTurtzDelegateBalance(_warmWalletAddress)
    {
        if (block.timestamp > _mintEnds) {
            revert MintEndsInPast();
        }

        if (_twtAddress == address(0)) {
            revert EmptyTWTContract();
        }

        if (_checksAddress == address(0)) {
            revert EmptyChecksContract();
        }

        mintEnds = _mintEnds;
        TINY_WINGED_TURTLEZ_ADDRESS = _twtAddress;
        CHECKS_ADDRESS = _checksAddress;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function addChecksV2Contract(address _checksV2Address) external onlyOwner {
        if (checksV2Address != address(0)) {
            revert ChecksV2AlreadySet();
        }

        if (_checksV2Address == address(0)) {
            revert EmptyChecksV2Contract();
        }

        checksV2Address = _checksV2Address;
    }

    function mint() external {
        if (block.timestamp > mintEnds) {
            revert MintingEnded();
        }

        if (hasMinted[msg.sender]) {
            revert AlreadyMinted();
        }

        uint256 tokenId = ++nextTokenId;
        // @dev Max supply 5,000 + 16,030 = 24,030
        uint16 colors = 0;

        colors = uint16(
            delegateBalance(TINY_WINGED_TURTLEZ_ADDRESS) +
                delegateBalance(CHECKS_ADDRESS)
        );

        if (checksV2Address != address(0)) {
            colors += uint16(delegateBalance(checksV2Address));
        }

        if (colors > 0) {
            checkTurtz[tokenId].colors = colors < 81 ? colors : 80;

            checkTurtz[tokenId].psuedoRandomNumber = uint256(
                keccak256(
                    abi.encodePacked(msg.sender, block.coinbase, _totalSupply)
                )
            );
        }

        hasMinted[msg.sender] = true;
        ++_totalSupply;
        _mint(msg.sender, tokenId);
    }

    function toggleTokenMode(uint256 tokenId) external {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotApprovedOrOwner();
        }

        checkTurtz[tokenId].darkMode = !checkTurtz[tokenId].darkMode;
        emit MetadataUpdate(tokenId);
    }

    function getFrame(uint256 tokenId) internal view returns (string memory) {
        if (checkTurtz[tokenId].darkMode) {
            return
                "<path d='M2000 0H0V2000H2000V0Z' fill='#000000'/><path d='M1448.89 447.852H551.107V1552.15H1448.89V447.852Z' fill='#111111' />";
        }

        return
            "<path d='M2000 0H0V2000H2000V0Z' fill='#efefef'/><path d='M1448.89 447.852H551.107V1552.15H1448.89V447.852Z' fill='#ffffff' />";
    }

    function getDefaultTurt() internal pure returns (string memory) {
        return
            "<path d='M0.893005 0.897949H35.093L35.093 12.298H46.493V46.498H35.093L35.093 57.8979H0.893005V0.897949Z' fill='#65bc48' /><path d='M35.093 12.298H12.293V35.098H35.093V12.298Z' fill='#ffffff' /><path d='M35.1 23.698H23.7V35.098H35.1V23.698Z' fill='#000000' />";
    }

    function getCheckTurt(
        uint256 tokenId,
        uint8 i
    ) internal view returns (string memory) {
        uint8 colorPaletteIndex = uint8(
            uint8(checkTurtz[tokenId].psuedoRandomNumber >> i) %
                colorPalette.length
        );

        return
            string(
                abi.encodePacked(
                    "<path d='M0.893005 0.897949H35.093L35.093 12.298H46.493V46.498H35.093L35.093 57.8979H0.893005V0.897949Z' fill='",
                    colorPalette[colorPaletteIndex],
                    "' /><path d='M35.093 12.298H12.293V35.098H35.093V12.298Z' fill='#ffffff' /><path d='M35.1 23.698H23.7V35.098H35.1V23.698Z' fill='#000000' />"
                )
            );
    }

    function shufflePositions(
        uint256 tokenId
    ) internal view returns (uint8[80] memory) {
        uint8[80] memory shuffledPositions = positions;

        for (uint i = 0; i < shuffledPositions.length; ) {
            uint j = checkTurtz[tokenId].psuedoRandomNumber % (i + 1);
            uint8 temp = shuffledPositions[i];

            shuffledPositions[i] = shuffledPositions[j];
            shuffledPositions[j] = temp;

            unchecked {
                ++i;
            }
        }

        return shuffledPositions;
    }

    function getTurtGrid(
        uint256 tokenId
    ) internal view returns (string memory grid) {
        for (uint8 i = 0; i < 80; ) {
            uint8[80] memory shuffledPositions = shufflePositions(tokenId);

            uint8 positionIndex = checkTurtz[tokenId].colors > 0
                ? shuffledPositions[i]
                : i;

            if (i < checkTurtz[tokenId].colors) {
                grid = string(
                    abi.encodePacked(
                        grid,
                        "<g transform='translate(",
                        Strings.toString(coordinates[positionIndex][0]),
                        " ",
                        Strings.toString(coordinates[positionIndex][1]),
                        ")'>",
                        getCheckTurt(tokenId, i),
                        "</g>"
                    )
                );
            } else {
                grid = string(
                    abi.encodePacked(
                        grid,
                        "<g transform='translate(",
                        Strings.toString(coordinates[positionIndex][0]),
                        " ",
                        Strings.toString(coordinates[positionIndex][1]),
                        ")'>",
                        getDefaultTurt(),
                        "</g>"
                    )
                );
            }

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
                    getTurtGrid(tokenId),
                    "</svg>"
                )
            );
    }

    function getTokenIdMetadata(
        uint256 tokenId
    ) internal view returns (string memory metadata) {
        metadata = string(
            abi.encodePacked(
                '{"trait_type": "Mode", "value": "',
                checkTurtz[tokenId].darkMode ? "Dark" : "Light",
                '"}'
            )
        );

        if (checkTurtz[tokenId].colors > 0) {
            metadata = string(
                abi.encodePacked(
                    metadata,
                    ',{"trait_type": "Colors", "value": "',
                    Strings.toString(checkTurtz[tokenId].colors),
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
                                    '{"name": "Check Turtz #',
                                    Strings.toString(tokenId),
                                    '", "description": "Check Turtz is a fully on-chain, gamified Tiny Winged Turtlez x Checks derivative.", "image": "data:image/svg+xml;base64,',
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
        _burn(tokenId);
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

        return (owner(), (salePrice * 25) / 1000);
    }
}