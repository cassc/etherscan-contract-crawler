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
import "./StringUtilsLib.sol";

contract MaMoMe is Ownable, ERC721A, ERC2981 {
    using StringUtils for string;
    using DynamicBuffer for bytes;
    using Strings for uint256;
    using Strings for uint160;
    
    string public constant contractDescription = unicode"MaMoMe is Capsule21’s first on-chain Open Edition, minting for 48 hours only and in honor of the OC Marilyns @ Sovpunk Museum exhibition. \\n\\nMaMoMe is a derivative of two earlier Capsule 21 projects: OC Marilyn PFPs and mememe.\\n\\nIn OC Marilyn PFPs, a mirrored CryptoPunk 3725 (representing Marilyn Monroe) was colored with Punk colors in all possible combinations. In MaMoME, the Marilyn is filled in with the seven “soulbound” colors derived from the unique hexadecimal Ethereum address of her minter, a technique borrowed from mememe.\\n\\nMaMoMe mints are not soulbound and can be traded, but be assured that when you do you always sell a piece of yourself.";
    
    string public constant tokenDescription = contractDescription;
    
    uint public constant costPerToken = 0;
    
    uint public constant mintBatchSize = 30;
    uint public constant maxMintsPerTx = 1_000;
    
    uint public mintActivatedAt;
    uint public mintDuration = 48 hours;
    
    bytes public constant contractExternalURI = "https://capsule21.com/collections/mamome";
    
    mapping(uint => address) private tokenIdToMinter;
    
    function startMint() external onlyOwner {
        mintActivatedAt = block.timestamp;
    }
    
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
    
    constructor() ERC721A("MaMoMe", "MAMO") {
        _setDefaultRoyalty(address(this), 1_000); // 10%
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
    
    function mintEndTime() public view returns (uint) {
        return mintActivatedAt + mintDuration;
    }
    
    function _internalMint(address toAddress, uint numTokens) private {
        require(mintActivatedAt != 0, "Mint is not active");
        require(block.timestamp < mintEndTime(), "Mint has ended");
        
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
        
        string memory title = string.concat("MaMoMe #", tokenId.toString());
        
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
        string memory image = addressToImage(0x54846F7A1b0D0E0F20494D46353D2028383a0368);
        
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"MaMoMe",'
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
    
    function getMinterColorsAsUints(address minter) public pure returns (uint24[] memory) {
        uint addressAsUint = uint(uint160(minter));
        uint24[] memory ret = new uint24[](7);
        
        for (uint i; i < 7; ++i) {
            ret[i] = uint24(addressAsUint);
            addressAsUint = addressAsUint >> 24;
        }
        
        return ret;
    }
    
    function computeColorLuminanceFrom24BitUint(uint24 color) public pure returns (uint24) {
        uint24 b = uint8(color);
        uint24 g = uint8(color >> 8);
        uint24 r = uint8(color >> 16);
        
        return (r * 299 + g * 587 + b * 114) / 1000;
    }
    
    function quickSort(uint24[] memory items, uint24[] memory data, int left, int right) public pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = data[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (data[uint(i)] < pivot) i++;
            while (pivot < data[uint(j)]) j--;
            if (i <= j) {
                (items[uint(i)], items[uint(j)]) = (items[uint(j)], items[uint(i)]);
                (data[uint(i)], data[uint(j)]) = (data[uint(j)], data[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(items, data, left, j);
        if (i < right)
            quickSort(items, data, i, right);
    }

    function sortDataAndItems(uint24[] memory items, uint24[] memory data) public pure returns (uint24[] memory, uint24[] memory) {
        quickSort(items, data, int(0), int(data.length - 1));
        return (items, data);
    }
    
    function getMinterColorsAsStringsSortedByLuminance(address minter) public pure returns (string[] memory, uint24[] memory) {
        uint24[] memory items = getMinterColorsAsUints(minter);
        uint24[] memory data = new uint24[](items.length);
        
        for (uint i; i < items.length; ++i) {
            data[i] = computeColorLuminanceFrom24BitUint(items[i]);
        }
        
        (uint24[] memory sortedColors, uint24[] memory lums) = sortDataAndItems(items, data);
        
        string[] memory ret = new string[](7);
        
        for (uint i; i < 7; ++i) {
            ret[i] = toHexStringNoPrefix(sortedColors[i], 3);
        }
        
        return (ret, lums);
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
    
    function addressToImage(address minter) public view returns (string memory) {
        (string[] memory colors, ) = getMinterColorsAsStringsSortedByLuminance(minter);
        return internalImage(colors);
    }
    
    function tokenImage(uint tokenId) public view returns (string memory) {
        require(_exists(tokenId));
        (string[] memory colors, ) = getMinterColorsAsStringsSortedByLuminance(getMinter(tokenId));
        return internalImage(colors);
    }
    
    function internalImage(string[] memory colors) internal view returns (string memory) {
        bytes memory svgBytes = DynamicBuffer.allocate(200 * 1024);
        
        // svgBytes.appendSafe('<svg width="1200" height="1200" shape-rendering="crispEdges" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><style>rect{width:1px;height:1px}rect.bg{width:24px;height:24px}</style><defs xmlns="http://www.w3.org/2000/svg"><g id="h"><rect x="12" y="3"/><rect x="9" y="3"/><rect x="8" y="3"/><rect x="15" y="4"/><rect x="14" y="4"/><rect x="11" y="4"/><rect x="10" y="4"/><rect x="9" y="4"/><rect x="8" y="4"/><rect x="6" y="4"/><rect x="17" y="5"/><rect x="16" y="5"/><rect x="15" y="5"/><rect x="14" y="5"/><rect x="13" y="5"/><rect x="11" y="5"/><rect x="10" y="5"/><rect x="9" y="5"/><rect x="8" y="5"/><rect x="7" y="5"/><rect x="18" y="6"/><rect x="17" y="6"/><rect x="16" y="6"/><rect x="14" y="6"/><rect x="13" y="6"/><rect x="12" y="6"/><rect x="11" y="6"/><rect x="10" y="6"/><rect x="9" y="6"/><rect x="7" y="6"/><rect x="6" y="6"/><rect x="5" y="6"/><rect x="4" y="6"/><rect x="3" y="6"/><rect x="19" y="7"/><rect x="18" y="7"/><rect x="16" y="7"/><rect x="15" y="7"/><rect x="14" y="7"/><rect x="13" y="7"/><rect x="12" y="7"/><rect x="11" y="7"/><rect x="10" y="7"/><rect x="9" y="7"/><rect x="8" y="7"/><rect x="7" y="7"/><rect x="6" y="7"/><rect x="5" y="7"/><rect x="20" y="8"/><rect x="19" y="8"/><rect x="18" y="8"/><rect x="17" y="8"/><rect x="16" y="8"/><rect x="15" y="8"/><rect x="14" y="8"/><rect x="13" y="8"/><rect x="12" y="8"/><rect x="11" y="8"/><rect x="10" y="8"/><rect x="9" y="8"/><rect x="8" y="8"/><rect x="7" y="8"/><rect x="6" y="8"/><rect x="18" y="9"/><rect x="17" y="9"/><rect x="16" y="9"/><rect x="15" y="9"/><rect x="14" y="9"/><rect x="9" y="9"/><rect x="8" y="9"/><rect x="7" y="9"/><rect x="6" y="9"/><rect x="5" y="9"/><rect x="4" y="9"/><rect x="19" y="10"/><rect x="18" y="10"/><rect x="17" y="10"/><rect x="16" y="10"/><rect x="13" y="10"/><rect x="9" y="10"/><rect x="7" y="10"/><rect x="6" y="10"/><rect x="5" y="10"/><rect x="3" y="10"/><rect x="20" y="11"/><rect x="19" y="11"/><rect x="18" y="11"/><rect x="17" y="11"/><rect x="16" y="11"/><rect x="10" y="11"/><rect x="6" y="11"/><rect x="5" y="11"/><rect x="4" y="11"/><rect x="19" y="12"/><rect x="18" y="12"/><rect x="6" y="12"/><rect x="5" y="12"/><rect x="4" y="12"/><rect x="3" y="12"/><rect x="20" y="13"/><rect x="19" y="13"/><rect x="18" y="13"/><rect x="6" y="13"/><rect x="5" y="13"/><rect x="4" y="13"/><rect x="3" y="13"/><rect x="19" y="14"/><rect x="18" y="14"/><rect x="6" y="14"/><rect x="5" y="14"/><rect x="4" y="14"/><rect x="20" y="15"/><rect x="19" y="15"/><rect x="18" y="15"/><rect x="17" y="15"/><rect x="6" y="15"/><rect x="4" y="15"/><rect x="19" y="16"/><rect x="17" y="16"/><rect x="16" y="16"/><rect x="7" y="16"/><rect x="5" y="16"/><rect x="19" y="17"/><rect x="18" y="17"/><rect x="17" y="17"/><rect x="5" y="17"/><rect x="4" y="17"/><rect x="18" y="18"/></g><g id="s"><rect x="13" y="9"/> <rect x="12" y="9"/> <rect x="11" y="9"/> <rect x="10" y="9"/> <rect x="15" y="10"/> <rect x="14" y="10"/> <rect x="12" y="10"/> <rect x="11" y="10"/> <rect x="10" y="10"/> <rect x="8" y="10"/> <rect x="15" y="11"/> <rect x="14" y="11"/> <rect x="13" y="11"/> <rect x="12" y="11"/> <rect x="11" y="11"/> <rect x="9" y="11"/> <rect x="8" y="11"/> <rect x="16" y="12"/> <rect x="15" y="12"/> <rect x="12" y="12"/> <rect x="11" y="12"/> <rect x="10" y="12"/> <rect x="16" y="13"/> <rect x="15" y="13"/> <rect x="12" y="13"/> <rect x="11" y="13"/> <rect x="10" y="13"/> <rect x="15" y="14"/> <rect x="14" y="14"/> <rect x="13" y="14"/> <rect x="12" y="14"/> <rect x="11" y="14"/> <rect x="10" y="14"/> <rect x="9" y="14"/> <rect x="8" y="14"/> <rect x="15" y="15"/> <rect x="14" y="15"/> <rect x="13" y="15"/> <rect x="12" y="15"/> <rect x="11" y="15"/> <rect x="10" y="15"/> <rect x="9" y="15"/> <rect x="8" y="15"/> <rect x="15" y="16"/> <rect x="13" y="16"/> <rect x="12" y="16"/> <rect x="10" y="16"/> <rect x="9" y="16"/> <rect x="8" y="16"/> <rect x="15" y="17"/> <rect x="14" y="17"/> <rect x="13" y="17"/> <rect x="12" y="17"/> <rect x="11" y="17"/> <rect x="10" y="17"/> <rect x="9" y="17"/> <rect x="8" y="17"/> <rect x="15" y="18"/> <rect x="14" y="18"/> <rect x="13" y="18"/> <rect x="9" y="18"/> <rect x="8" y="18"/> <rect x="14" y="19"/> <rect x="13" y="19"/> <rect x="12" y="19"/> <rect x="11" y="19"/> <rect x="10" y="19"/> <rect x="9" y="19"/> <rect x="14" y="20"/> <rect x="12" y="20"/> <rect x="11" y="20"/> <rect x="10" y="20"/> <rect x="14" y="21"/> <rect x="13" y="21"/> <rect x="14" y="22"/> <rect x="13" y="22"/> <rect x="12" y="22"/> <rect x="14" y="23"/> <rect x="13" y="23"/> <rect x="12" y="23"/></g><g id="o"><rect x="7" y="11"/><rect x="17" y="12"/><rect x="7" y="12"/><rect x="17" y="13"/><rect x="14" y="13"/><rect x="9" y="13"/><rect x="7" y="13"/><rect x="17" y="14"/><rect x="16" y="14"/><rect x="7" y="14"/><rect x="16" y="15"/><rect x="7" y="15"/><rect x="11" y="16"/><rect x="16" y="17"/><rect x="7" y="17"/><rect x="16" y="18"/><rect x="7" y="18"/><rect x="15" y="19"/><rect x="8" y="19"/><rect x="15" y="20"/><rect x="13" y="20"/><rect x="9" y="20"/><rect x="15" y="21"/><rect x="12" y="21"/><rect x="11" y="21"/><rect x="10" y="21"/><rect x="15" y="22"/><rect x="11" y="22"/><rect x="15" y="23"/><rect x="11" y="23"/></g><g id="de"><rect x="14" y="12"/><rect x="13" y="12"/><rect x="9" y="12"/><rect x="8" y="12"/></g><g id="le"><rect x="13" y="13"/><rect x="8" y="13"/></g><g id="l"><rect x="12" y="18"/><rect x="11" y="18"/><rect x="10" y="18"/></g><g id="m"><rect x="14" y="16"/></g></defs>');
        svgBytes.appendSafe('<svg width="1200" height="1200" shape-rendering="crispEdges" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><style>rect{width:1px;height:1px}rect.bg{width:24px;height:24px}</style>');
        
        svgBytes.appendSafe(SSTORE2.read(0x6eC4C8a4F17dA98C1c3e5064481904dad86c7262));
        
        svgBytes.appendSafe('<rect class="bg" fill="#');
        svgBytes.appendSafe(bytes(colors[4]));
        svgBytes.appendSafe('"></rect>');
        
        svgBytes.appendSafe('<use href="#h" fill="#');
        svgBytes.appendSafe(bytes(colors[2]));
        svgBytes.appendSafe('" />');
        
        svgBytes.appendSafe('<use href="#s" fill="#');
        svgBytes.appendSafe(bytes(colors[5]));
        svgBytes.appendSafe('" />');
        
        svgBytes.appendSafe('<use href="#de" fill="#');
        svgBytes.appendSafe(bytes(colors[4]));
        svgBytes.appendSafe('" />');
        
        svgBytes.appendSafe('<use href="#le" fill="#');
        svgBytes.appendSafe(bytes(colors[6]));
        svgBytes.appendSafe('" />');
        
        svgBytes.appendSafe('<use href="#m" fill="#');
        svgBytes.appendSafe(bytes(colors[1]));
        svgBytes.appendSafe('" />');
        
        svgBytes.appendSafe('<use href="#l" fill="#');
        svgBytes.appendSafe(bytes(colors[3]));
        svgBytes.appendSafe('" />');
        
        svgBytes.appendSafe(abi.encodePacked('<use href="#o" fill="#', colors[0], '" />'));
        
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