// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "base64-sol/base64.sol";
import "erc721a/contracts/ERC721A.sol";

import "./sstore2/SSTORE2.sol";
import "./utils/DynamicBuffer.sol";

import "hardhat/console.sol";

interface PFPInterface {
    function getMintedPFPsOnDiptych(uint dypIdx) external view returns (bool[] memory result);
    function getMintedPFPsCountOnDiptych(uint dypIdx) external view returns (uint count);
}

contract OCMarilynDiptychs is Ownable, ERC721A {
    using Address for address;
    using DynamicBuffer for bytes;
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;
    
    uint public constant costPerToken = 0.01 ether;
    
    uint public constant maxSupply = 500;
    
    uint public constant maxPerTx = 20;
    
    bool public isMintActive;
    
    bytes public constant externalLink = "https://capsule21.com/collections/oc-marilyn-diptychs";
    
    bool public contractSealed;
    
    uint8 public sideLength = 5;
    
    mapping(uint => uint) private tokenIdToSeed;
    
    bytes constant tokenDescription = "One of 500 Andy Warhol-inspired Marilyn Monroe Diptychs, each randomly generated at mint using only colors from the CryptoPunks collection.\\n\\nEach Diptych is stored 100% on-chain. Individual Marilyns can also be minted as PFPs.";
    
    PFPInterface public PFPContract;
    
    function setPFPContract(address contractAddress) external onlyOwner unsealed {
        PFPContract = PFPInterface(contractAddress);
    }
    
    struct Color {
        uint16 h;
        uint8 s;
        uint8 v;
        uint8 classIdx;
    }
    
    Color[] public brightPunkColors;
    Color[] public darkPunkColors;
    
    function setPunkColors(
        uint16[] memory hues,
        uint8[] memory sats,
        uint8[] memory values,
        uint8[] memory brightOrDark
    ) external onlyOwner unsealed {
        for (uint8 i; i < hues.length; ++i) {
            Color memory color = Color({
               h: hues[i],
               s: sats[i],
               v: values[i],
               classIdx: (i + 1) 
            });
            
            if (brightOrDark[i] > 0) {
                brightPunkColors.push(color);
            } else {
                darkPunkColors.push(color);
            }
        }
    }
    
    address private tokenTitles;
    
    function setTokenTitles(string calldata _tokenTitles) external onlyOwner unsealed {
        tokenTitles = SSTORE2.write(bytes(_tokenTitles));
    }
    
    uint constant maxTitleLength = 46;
    
    function getTokenTitleAtIndex(uint index) public view returns (string memory) {
        require(_exists(index));
        
        bytes memory allTitles = SSTORE2.read(tokenTitles);
        bytes memory outputBytes = DynamicBuffer.allocate(50);
        bytes32 enderHash = keccak256(abi.encodePacked(bytes("|")));
        
        for (uint i = (maxTitleLength * index); i < (maxTitleLength * (index + 1)); ++i) {
            bytes32 currentCharHash = keccak256(abi.encodePacked(allTitles[i]));
            
            if (currentCharHash == enderHash) {
                break;
            }
            
            outputBytes.appendSafe(abi.encodePacked(allTitles[i]));
        }
        
        return string(outputBytes);
    }
    
    modifier unsealed() {
        require(!contractSealed, "Contract sealed.");
        _;
    }
    
    function sealContract() external onlyOwner unsealed {
        contractSealed = true;
    }
    
    function flipMintState() external onlyOwner {
        isMintActive = !isMintActive;
    }
    
    constructor() ERC721A("OC Marilyn Diptychs", "MARILYNS") {
    }
    
    function mintMarilyn(address toAddress, uint numTokens) public payable {
        require(numTokens + totalSupply() <= maxSupply, "Marilyn supply limit reached.");
        require(isMintActive, "Mint is not active");
        require(numTokens > 0, "Mint at least one");
        require(msg.value == totalMintCost(numTokens, msg.sender), "Need exact payment");
        require(msg.sender == tx.origin, "Contracts cannot mint");
        require(numTokens <= maxPerTx, "Too many tokens");
        
        uint oldNextIndex = _currentIndex;
        
        uint entropy = getEntropy(_currentIndex);
        
        _safeMint(toAddress, numTokens);
        
        uint newNextIndex = _currentIndex;
        
        for (uint i = oldNextIndex; i < newNextIndex; i++) {
            tokenIdToSeed[i] = entropy;
        }
    }
    
    function exists(uint tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
    
    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Token does not exist");

        return constructTokenURI(id);
    }
    
    function constructTokenURI(uint tokenId) private view returns (string memory) {
        (
            bytes memory svg,
            uint[2] memory squareCounts,
        ) = tokenImageWithMetadata(tokenId, false, 0, 0);
        
        uint mintedPfpCount = PFPContract.getMintedPFPsCountOnDiptych(tokenId);
        
        uint _sl = sideLength;
        
        uint totalSquares = (_sl * (2 * _sl));
        uint brightSquareCount = totalSquares - squareCounts[0];
        
        string memory title = getTokenTitleAtIndex(tokenId);
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":', title, ','
                                '"description":"', tokenDescription, '",'
                                '"image_data":"data:image/svg+xml;base64,', Base64.encode(svg), '",'
                                '"external_url":"', externalLink, '",'
                                    '"attributes": [',
                                        '{',
                                            '"trait_type": "Title Length",',
                                            '"value": "', (bytes(title).length).toString(), '"',
                                        '},'
                                        '{',
                                            '"trait_type": "OC Marilyn PFPs Minted",',
                                            '"value": "', mintedPfpCount.toString(), '"',
                                        '},'
                                        '{',
                                            '"trait_type": "Bright Squares",',
                                            '"value": "', brightSquareCount.toString(), '"',
                                        '},'
                                        '{',
                                            '"trait_type": "Dark Squares",',
                                            '"value": "', squareCounts[0].toString(), '"',
                                        '},'
                                        '{',
                                            '"trait_type": "Crossover Squares",',
                                            '"value": "', squareCounts[1].toString(), '"',
                                        '}'
                                    ']'
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    function getEntropy(uint seed) private view returns (uint) {
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    seed,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this)
                )
            )
        );
        
        return randomNum;
    }
    
    function deterministicRandomNumber(bytes memory seed, uint upToNumber) private pure returns (uint) {
        uint256 randomNum = uint256(
            keccak256(abi.encode(seed))
        );
        
        return randomNum % upToNumber;
    }
    
    function getOriginalColors(uint darkMode) public pure returns (Color[7] memory colors) {
        if (darkMode == 0) {
            colors[0].classIdx = 103;
            colors[1].classIdx = 97;
            colors[2].classIdx = 100;
            colors[3].classIdx = 102;
            colors[4].classIdx = 96;
            colors[5].classIdx = 101;
            colors[6].classIdx = 99;
        } else {
            colors[0].classIdx = 104;
            colors[1].classIdx = 105;
            colors[2].classIdx = 106;
            colors[3].classIdx = 107;
            colors[4].classIdx = 108;
            colors[5].classIdx = 109;
            colors[6].classIdx = 110;
        }
    }
    
    function getColors(bytes memory seed, uint8 darkMode) public view returns(
        Color[7] memory colors
    ) {
        uint j;
        bytes memory currentSeed;
        uint darkColorCount = darkPunkColors.length;
        uint brightColorCount = brightPunkColors.length;
        Color memory currentColor;
        
        while (colors[6].classIdx == 0) {
            ++j;
            
            currentSeed = abi.encode(seed, j);
            
            if (darkMode == 1) {
                currentColor = darkPunkColors[deterministicRandomNumber(currentSeed, darkColorCount)];
            } else {
                currentColor = brightPunkColors[deterministicRandomNumber(currentSeed, brightColorCount)];
            }
            
            if (colors[0].classIdx == 0) { // bg
                colors[0] = currentColor;
                colors[3] = currentColor;
            } else if (colors[1].classIdx == 0) { // hair
                if (
                    colorsVisiblyDifferent(colors[0], currentColor)
                ) {
                    colors[1] = currentColor;
                }
            } else if (colors[2].classIdx == 0) { // skin
                if (
                    colorsVisiblyDifferent(colors[0], currentColor) &&
                    colorsVisiblyDifferent(colors[1], currentColor)
                ) {
                    colors[2] = currentColor;
                }
            } else if (colors[4].classIdx == 0) { // light eye shadow
                if (
                    colorsVisiblyDifferent(colors[2], currentColor) &&
                    hueDifference(colors[3].h, currentColor.h) < (darkMode == 1 ? 350 : 120) &&
                    absoluteDiff(colors[3].v, currentColor.v) > 10
                ) {
                    colors[4] = currentColor;
                }
            } else if (colors[5].classIdx == 0) { // mole
                if (
                    colorsVisiblyDifferent(colors[2], currentColor)
                ) {
                    colors[5] = currentColor;
                }
            }
            else if (colors[6].classIdx == 0) { // lipstick
                if (
                    colorsVisiblyDifferent(colors[2], currentColor)
                ) {
                    colors[6] = currentColor;
                }
            }
        }
    }
    
    function walletOfOwner(address _owner)
        external
        view
        returns (uint[] memory)
    {
        uint ownerTokenCount = balanceOf(_owner);
        uint[] memory ownedTokenIds = new uint[](ownerTokenCount);
        uint currentTokenId = 0;
        uint ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId < maxSupply) {
            address currentTokenOwner = _exists(currentTokenId) ? ownerOf(currentTokenId) : address(0);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }
    
    function colorsVisiblyDifferent(Color memory color1, Color memory color2) public pure returns (bool) {
        return absoluteDiff(color1.v, color2.v) > 25 ||
               absoluteDiff(color1.s, color2.s) > 90 ||
               absoluteDiff(color1.h, color2.h) > 25;
    }
    
    function absoluteDiff(uint a, uint b) private pure returns (uint) {
        return a > b ? a - b : b - a;
    }
    
    function hueDifference(uint hue1, uint hue2) private pure returns (uint) {
        uint regularDiff = absoluteDiff(hue1, hue2);
        uint circularDiff = 360 - regularDiff;
        
        return regularDiff < circularDiff ? regularDiff : circularDiff;
    }
    
    address public svgCSS;
    address public svgDefs;
    
    function setSvgData(
        string calldata _css,
        string calldata _svgDefs
    ) external onlyOwner unsealed {
        svgCSS = SSTORE2.write(bytes(_css));
        svgDefs = SSTORE2.write(bytes(_svgDefs));
    }
    
    function setSideLength(uint8 _sideLength) external onlyOwner unsealed {
        sideLength = _sideLength;
    }
    
    function tokenImage(uint tokenId) public view returns (string memory) {
        (bytes memory svg,,) = tokenImageWithMetadata(tokenId, false, 0, 0);
        return string(svg);
    }
    
    function tokenImageWithMetadata(
        uint tokenId,
        bool renderSingle,
        uint rowIdx,
        uint colIdx
    ) public view returns (
        bytes memory svg,
        uint[2] memory squareCounts,
        bool pfpBrightMode
    ) {
        require(_exists(tokenId));
        bytes memory svgBytes = DynamicBuffer.allocate(200 * 1024);
        
        uint16 _sideLength = sideLength;
        
        if (renderSingle) {
            svgBytes.appendSafe('<svg width="1200" height="1200" shape-rendering="crispEdges" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><style>');
        } else {
            svgBytes.appendSafe('<svg shape-rendering="crispEdges" viewBox="0 0 ');
            svgBytes.appendSafe(bytes((_sideLength * 2 * 24).toString()));
            svgBytes.appendSafe(' ');
            svgBytes.appendSafe(bytes((_sideLength * 24).toString()));
            svgBytes.appendSafe('" xmlns="http://www.w3.org/2000/svg"><style>');
        }
        
        svgBytes.appendSafe(SSTORE2.read(svgCSS));
        
        svgBytes.appendSafe('</style>');
        svgBytes.appendSafe(SSTORE2.read(svgDefs));
        
        uint currentSeed = uint256(
            keccak256(abi.encode(tokenId, tokenIdToSeed[tokenId]))
        );
        
        uint p1 = ((tokenId * 100) / maxSupply) / 2;
        uint counter;
        bool[] memory mintedPFPs = PFPContract.getMintedPFPsOnDiptych(tokenId);
        
        for (uint16 y; y < _sideLength; ++y) {
            for (uint16 x; x < (2 * _sideLength); ++x) {
                bool brightMode = deterministicRandomNumber(abi.encode(currentSeed, counter), 100) >= (x < _sideLength ? p1 : (100 - p1));
                
                Color[7] memory colors = (!renderSingle && mintedPFPs[counter]) ?
                    getOriginalColors(x >= _sideLength ? 0 : 1) :
                    getColors(
                        abi.encode(currentSeed, counter),
                        brightMode ? 0 : 1
                    );
                
                if (brightMode) {
                    if (x >= _sideLength) {
                        squareCounts[1]++;
                    }
                } else {
                    squareCounts[0]++;
                    if (x < _sideLength) {
                        squareCounts[1]++;
                    }
                }
                
                ++counter;
                
                if (!renderSingle) {
                    svgBytes.appendSafe('<g transform="translate(');
                    svgBytes.appendSafe(bytes((x * 24).toString()));
                    svgBytes.appendSafe(', ');
                    svgBytes.appendSafe(bytes((y * 24).toString()));
                    svgBytes.appendSafe(')">');
                }
                
                if (!renderSingle || (renderSingle && (x == colIdx && y == rowIdx))) {
                    pfpBrightMode = brightMode;
                    svgBytes.appendSafe('<rect class="bg c');
                    svgBytes.appendSafe(bytes(colors[0].classIdx.toString()));
                    svgBytes.appendSafe('"></rect>');
                    
                    svgBytes.appendSafe('<use href="#h" class="c');
                    svgBytes.appendSafe(bytes(colors[1].classIdx.toString()));
                    svgBytes.appendSafe('" />');
                    
                    svgBytes.appendSafe('<use href="#s" class="c');
                    svgBytes.appendSafe(bytes(colors[2].classIdx.toString()));
                    svgBytes.appendSafe('" />');
                    
                    svgBytes.appendSafe('<use href="#de" class="c');
                    svgBytes.appendSafe(bytes(colors[3].classIdx.toString()));
                    svgBytes.appendSafe('" />');
                    
                    svgBytes.appendSafe('<use href="#le" class="c');
                    svgBytes.appendSafe(bytes(colors[4].classIdx.toString()));
                    svgBytes.appendSafe('" />');
                    
                    svgBytes.appendSafe('<use href="#m" class="c');
                    svgBytes.appendSafe(bytes(colors[5].classIdx.toString()));
                    svgBytes.appendSafe('" />');
                    
                    svgBytes.appendSafe('<use href="#l" class="c');
                    svgBytes.appendSafe(bytes(colors[6].classIdx.toString()));
                    svgBytes.appendSafe('" />');
                    
                    svgBytes.appendSafe('<use href="#o" fill="black" />');
                    
                    if (!renderSingle) {
                        svgBytes.appendSafe('</g>');
                    }
                }
            }
        }
        
        svgBytes.appendSafe('</svg>');
        
        svg = svgBytes;
    }
    
    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }
    
    function totalMintCost(uint numTokens, address minter) public view returns (uint) {
        if (minter == owner()) {
            return 0;
        }
        
        return numTokens * costPerToken;
    }
}