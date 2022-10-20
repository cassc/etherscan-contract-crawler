//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RHDC is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    string constant NAME = "RHDC Founders Tokens";
    string constant SYMBOL = "RHDC";

    uint256 public mintStart; // After this timestamp users can mint
    uint256 public mintEnd; // After this timestamp users can not mint any more
    uint256 public mintFee; // Fee collected from user for minting 1 token
    uint256 public mintLimit; // Limits how many tokens can be minted
    bytes32 public imageSalt; // Salt used to generate image id
    bytes32 public randomSeed; // Seed used to randomize images
    Counters.Counter private _mintCounter; // Counter of minted tokens
    string private baseTokenURI; // Base part of token URI. Wil be concatenated with token id to get full tokenURI. Also used contract-level metadata
    mapping(uint256 => bytes32) tokenCodes; // Mapping of tokens ids to token codes, used to generate image ids.

    constructor() ERC721(NAME, SYMBOL) {}

    /**
     * @notice Setup mint
     * @param _mintStart Unix timestamp when minting should be opened
     * @param _mintEnd Unix timestamp when minting should be closed
     * @param _mintFee Minting fee
     * @param _mintLimit Limits how many tokens can be minted
     */
    function setupMint(
        uint256 _mintStart,
        uint256 _mintEnd,
        uint256 _mintFee,
        uint256 _mintLimit
    ) external onlyOwner {
        require(_mintStart < _mintEnd, "wrong mint end");
        require(mintLimit == 0 || _mintLimit == mintLimit, "change mint limit not allowed");
        mintStart = _mintStart;
        mintEnd = _mintEnd;
        mintFee = _mintFee;
        mintLimit = _mintLimit;
    }

    function setImageSalt(bytes32 _imageSalt) external onlyOwner {
        imageSalt = _imageSalt;
        randomSeed = keccak256(abi.encodePacked(_imageSalt, blockhash(block.number - 1)));
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function claimFee() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @notice Mint single token
     * @param beneficiary This address will receive the token
     * @param mintCode Can be anything, but it affects the token code, which will also affect image id
     */
    function mint(address beneficiary, bytes32 mintCode) external payable {
        require(block.timestamp >= mintStart, "mint not started");
        require(block.timestamp <= mintEnd, "mint finished");
        require(msg.value == mintFee, "wrong mint fee");
        require(totalSupply() < mintLimit, "mint limit exceed");

        _mintInternal(beneficiary, mintCode);
    }

    /**
     * @notice Mint multiple tokens
     * @param beneficiaries List of addresses which will receive tokens
     * @param mintCodes List of mint codes (also see mint() function)
     */
    function bulkMint(address[] calldata beneficiaries, bytes32[] calldata mintCodes) external payable {
        require(block.timestamp >= mintStart, "mint not started");
        require(block.timestamp <= mintEnd, "mint finished");
        uint256 count = beneficiaries.length;
        require(mintCodes.length == count, "array length mismatch");
        require(msg.value == mintFee * count, "wrong mint fee");
        require(totalSupply() + count <= mintLimit, "mint limit exceed");

        for (uint256 i = 0; i < count; i++) {
            _mintInternal(beneficiaries[i], mintCodes[i]);
        }
    }

    /**
     * @notice URI of contract-level metadata
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "contract"));
    }

    /**
     * @notice Calculates image id
     * @param id Token id
     */
    function imageId(uint256 id) public view returns (bytes32) {
        if (imageSalt == bytes32(0)) {
            // Images are not revealed yet
            return bytes32(0);
        }
        bytes32 tokenCode = tokenCodes[id];
        if (tokenCode == bytes32(0)) return bytes32(0); // Non-existing token
        return keccak256(abi.encodePacked(imageSalt, tokenCode));
    }

    /**
     * @notice Returns imageIds for a range of token ids
     * @param startTokenId first token id in the range
     * @param rangeLength length of the range
     * @return imgIds array of image ids
     */
    function imageIdsForRange(uint256 startTokenId, uint256 rangeLength) public view returns (bytes32[] memory imgIds) {
        imgIds = new bytes32[](rangeLength);
        uint256 i = startTokenId;
        for (uint256 c = 0; c < rangeLength; c++) {
            imgIds[c] = imageId(i);
            i++;
        }
    }

    function _mintInternal(address beneficiary, bytes32 mintCode) internal {
        _mintCounter.increment();
        uint256 id = _mintCounter.current();
        tokenCodes[id] = generateTokenCode(beneficiary, mintCode, id, blockhash(block.number - 1));
        _safeMint(beneficiary, id);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function generateTokenCode(
        address beneficiary,
        bytes32 mintCode,
        uint256 mintCounter,
        bytes32 blockHash
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(blockHash, mintCounter, mintCode, beneficiary));
    }
}