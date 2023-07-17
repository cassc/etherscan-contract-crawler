// SPDX-License-Identifier: MIT

// Art by PIV, contract by middlemarch.eth

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "base64-sol/base64.sol";
import "erc721a/contracts/ERC721A.sol";

import "./sstore2/SSTORE2.sol";
import "./utils/DynamicBuffer.sol";

import "hardhat/console.sol";

interface IMaMoMe {
    function sortDataAndItems(uint24[] memory items, uint24[] memory data) external pure returns (uint24[] memory, uint24[] memory);
    function getMinterColorsAsStringsSortedByLuminance(address minter) external pure returns (string[] memory, uint24[] memory);
}

contract Vanitas is Ownable, ERC721A, ERC2981 {
    using DynamicBuffer for bytes;
    using Strings for uint256;
    using Strings for uint160;
    
    IMaMoMe public immutable MaMoMeContract;
    
    address rectPointer;
    
    string[] usings;
    
    struct Point {
        int32 x;
        int32 y;
    }
    
    string public constant contractDescription = unicode"Vanitas draws from three previous Capsule 21 projects—namely mememe, MaMoMe and Still Lifes—but it adds something new: address-derived compositions.\\n\\nBy interpreting each letter of your base-16 Ethereum address as a number 0–15, your 40 character address defines the coordinates of 20 points on a 16x16 grid.\\n\\nIn Vanistas, the three first points of this 20 are used to locate three still life elements (skull, bottle. and cigarette) in a unique composition.\\n\\nVanitas NFTs can be mined indefinitely, but the same ETH address always leads to the same colors and composition. Capsule 21 disclaims all liability for unbalanced compositions and takes the firm position that they are solely the fault and responsibility of the minting ETH address.";
    
    string public constant tokenDescription = contractDescription;
    
    uint public constant costPerToken = 0.01 ether;
    
    uint public constant mintBatchSize = 30;
    uint public constant maxMintsPerTx = 1_000;
    
    bytes public constant contractExternalURI = "https://capsule21.com/collections/vanitas";
    
    mapping(uint => address) private tokenIdToMinter;
    
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }
    
    constructor(address mamomeAddress) ERC721A("Vanitas", "VA") {
        MaMoMeContract = IMaMoMe(mamomeAddress);
        usings = [
            '<use href="#p0" />',
            '<use href="#p1" />',
            '<use href="#p2" />'
        ];
        
        _setDefaultRoyalty(address(this), 1_000); // 10%
    }
    
    bool public contractSealed;

    modifier unsealed() {
        require(!contractSealed, "Contract sealed.");
        _;
    }
    
    function sealContract() external onlyOwner unsealed {
        contractSealed = true;
    }
    
    function setSVGRects(string memory rects) public onlyOwner unsealed {
        rectPointer = SSTORE2.write(bytes(rects));
    }
    
    address constant pivAddress = 0xf98537696e2Cf486F8F32604B2Ca2CDa120DBBa8;
    address constant middleAddress = 0xC2172a6315c1D7f6855768F843c420EbB36eDa97;
    
    function withdraw() external {
        require(address(this).balance > 0, "Nothing to withdraw");
        
        uint total = address(this).balance;
        uint half = total / 2;
        
        Address.sendValue(payable(middleAddress), half);
        Address.sendValue(payable(pivAddress), total - half);
    }
    
    fallback (bytes calldata _inputText) external payable returns (bytes memory _output) {}
    
    receive () external payable {}
    
    function totalMintCost(uint numTokens) public pure returns (uint) {
        return numTokens * costPerToken;
    }
    
    function _internalMint(address toAddress, uint numTokens) private {
        require(numTokens > 0, "Mint at least one");
        require(numTokens <= maxMintsPerTx, "Can't mint this many in one transaction");
        
        require(msg.value == totalMintCost(numTokens), "Need exact payment");
        require(msg.sender == tx.origin, "Contracts cannot mint");
        
        uint batchCount = numTokens / mintBatchSize;
        uint remainder = numTokens % mintBatchSize;
        
        tokenIdToMinter[_nextTokenId()] = msg.sender;
        
        for (uint i; i < batchCount; i++) {
            _mint(toAddress, mintBatchSize);
        }
        
        if (remainder > 0) {
            _mint(toAddress, remainder);
        }
    }
    
    function exists(uint tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
    
    function airdrop(address toAddress, uint numTokens) external payable {
        _internalMint(toAddress, numTokens);
    }
    
    function mint(uint numTokens) external payable {
        _internalMint(msg.sender, numTokens);
    }
    
    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Token does not exist");

        return constructTokenURI(id);
    }
    
    function constructTokenURI(uint tokenId) private view returns (string memory) {
        bytes memory svg = bytes(tokenImage(tokenId));
        address minter = getMinter(tokenId);
        
        string memory title = string.concat("Vanitas #", tokenId.toString());
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', title, '",'
                                '"description":"', tokenDescription, '",'
                                '"image_data":"data:image/svg+xml;base64,', Base64.encode(svg), '",'
                                '"external_url":"', contractExternalURI, '",'
                                    '"attributes": [',
                                        '{',
                                            '"trait_type": "Minter",',
                                            '"value": "', uint160(minter).toHexString(20), '"',
                                        '}'
                                    ']'
                                '}'
                            )
                        )
                    )
                )
            );
    }

    function contractURI() public view returns (string memory) {
        string memory image = addressToImage(0x376aa0A284829bbb7A77a0D8a7afC6ccC6535159);
        
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"Vanitas",'
                                '"description":"', contractDescription, '",'
                                '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(image)), '",'
                                '"external_link":"', contractExternalURI, '"'
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    function getMinter(uint tokenId) public view returns (address candidate) {
        require(_exists(tokenId), "Token does not exist");
        candidate = tokenIdToMinter[tokenId];
        uint newTokenId = tokenId;
        
        while (candidate == address(0)) {
            newTokenId -= 1;
            candidate = tokenIdToMinter[newTokenId];
        }
    }
    
    function addressToPoints(address addr) public pure returns (Point[20] memory ret) {
        bytes memory addressBytes = abi.encodePacked(addr);
        
        for(uint i = 0; i < 20; i++) {
            int32 cur = int32(uint32(uint8(addressBytes[i])));
            
            ret[i].x = cur >> 4;
            ret[i].y = cur & 0x0F;
        }
    }
    
    function addressToImage(address minter) public view returns (string memory) {
        (string[] memory colors, ) = MaMoMeContract.getMinterColorsAsStringsSortedByLuminance(minter);
        Point[20] memory points = addressToPoints(minter);
        return internalImage(colors, minter, points);
    }
    
    function tokenImage(uint tokenId) public view returns (string memory) {
        require(_exists(tokenId));
        (string[] memory colors, ) = MaMoMeContract.getMinterColorsAsStringsSortedByLuminance(getMinter(tokenId));
        Point[20] memory points = addressToPoints(getMinter(tokenId));
        return internalImage(colors, getMinter(tokenId), points);
    }
    
    function intToString(int256 value) internal pure returns (string memory) {
        if (value >= 0) {
            return uint(value).toString();
        } else {
            return string(abi.encodePacked("-", uint(-value).toString()));
        }
    }
    
    function internalImage(string[] memory colors, address minter, Point[20] memory points) internal view returns (string memory) {
        bytes memory svgBytes = DynamicBuffer.allocate(200 * 1024);
        
        svgBytes.appendSafe('<svg width="1200" height="1200" shape-rendering="crispEdges" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><style>rect{width:1px;height:1px}');
        
        svgBytes.appendSafe(
            abi.encodePacked(
            '.c0{fill:#', colors[4], '}.c1{fill:#', colors[1],'}.c2{fill:#', colors[0],'}.c3{fill:#', colors[5],'}.c4{fill:#', colors[6],'}.c5{fill:#', colors[2],'}.c6{fill:#', colors[6],'80}.c7{fill:#', colors[3],'}')
        );
        
        points[0].x -= 1;
        points[0].y -= 11;
        
        points[1].x -= 9;
        points[1].y -= 4;
        
        points[2].x -= 14;
        points[2].y -= 13;
        
        uint24[] memory items = new uint24[](3);
        items[0] = 0;
        items[1] = 1;
        items[2] = 2;
        
        uint24[] memory data = new uint24[](3);
        data[0] = uint24(uint32(points[0].y + 11 + 24));
        data[1] = uint24(uint32(points[1].y + 4 + 24));
        data[2] = uint24(uint32(points[2].y + 13 + 24));
        
        console.log(items[0], items[1], items[2]);
        console.log(data[0], data[1], data[2]);
        
        (uint24[] memory sortedItems,) = MaMoMeContract.sortDataAndItems(items, data);
        
        svgBytes.appendSafe(
            abi.encodePacked(
                '.p0{transform:translate(', intToString(points[0].x),'px,', intToString(points[0].y),'px)}.p1{transform:translate(', intToString(points[1].x),'px,', intToString(points[1].y),'px)}.p2{transform:translate(', intToString(points[2].x),'px,', intToString(points[2].y),'px)}'
            )
        );
        
        svgBytes.appendSafe("</style>");
        
        svgBytes.appendSafe(SSTORE2.read(rectPointer));
        
        svgBytes.appendSafe(bytes(usings[sortedItems[0]]));
        svgBytes.appendSafe(bytes(usings[sortedItems[1]]));
        svgBytes.appendSafe(bytes(usings[sortedItems[2]]));
        
        svgBytes.appendSafe('</svg>');
        
        return string(svgBytes);
    }
    
    bytes16 internal constant ALPHABET = '0123456789abcdef';
    
    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}