pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

abstract contract ERC721PausableAndEnumerable is ERC721Enumerable, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

contract NFT is ERC721PausableAndEnumerable, Ownable, ReentrancyGuard {
    uint256 public maxSupply;
    string public baseURI;
    uint256 public maxBatch;
    string public defaultURI;
    bytes32 public root;

    uint256 public presalePrice;

    uint256 public whitelistPrice;

    uint256 public presaleStartTime;

    uint256 public presaleEndTime;

    uint256 public whitelistStartTime;

    uint256 public whitelistEndTime;

    uint256 public presaleNum;

    uint256 public whitelistNum;

    uint256 public maxPresaleNum;

    uint256 public maxWhitelistNum;

    uint256 public reservedNum;

    uint256 public maxReservedNum;

    mapping(address => bool) public whitelistMined;

    mapping(address => bool) public presaleMined;

    using Strings for uint256;

    constructor(
        string memory _baseURI,
        string memory _defaultURI,
        bool _isPause,
        bytes32 _root
    ) public ERC721("Litte Mami Pass NFT", "Litte Mami Pass NFT") {
        uint256 _maxBatch = 3;
        uint256 _maxSupply = 1100;
        setBaseURI(_baseURI);
        pause(_isPause);
        setMaxBatch(_maxBatch);
        maxSupply = _maxSupply;
        defaultURI = _defaultURI;
        root = _root;
        maxReservedNum = 1;
        maxWhitelistNum = 100;
        maxPresaleNum = 999;
        whitelistStartTime = 1655722800;
        whitelistEndTime = 1655895600;
        whitelistPrice = 0.5 ether;
        presaleStartTime = 1655730000;
        presaleEndTime = 1655902800;
        presalePrice = 0.55 ether;
    }

    function setPrice(uint256 _presalePrice, uint256 _whitelistPrice)
        external
        onlyOwner
    {
        presalePrice = _presalePrice;
        whitelistPrice = _whitelistPrice;
    }

    function setPresaleTime(
        uint256 _presaleStartTime,
        uint256 _presaleEndTime,
        uint256 _whitelistStartTime,
        uint256 _whitelistEndTime
    ) external onlyOwner {
        require(_whitelistEndTime > _whitelistStartTime);
        require(_presaleEndTime > _presaleStartTime);
        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleEndTime;
        whitelistStartTime = _whitelistStartTime;
        whitelistEndTime = _whitelistEndTime;
    }

    function setMaxNum(
        uint256 _maxPresaleNum,
        uint256 _maxWhitelistNum,
        uint256 _maxReservedNum
    ) external onlyOwner {
        maxPresaleNum = _maxPresaleNum;
        maxWhitelistNum = _maxWhitelistNum;
        maxReservedNum = _maxReservedNum;
    }

    function mint(address _addresss, uint256 _num) internal nonReentrant {
        require(
            _num <= maxBatch && _num > 0,
            "Num must greater 0 and lower maxBatch"
        );
        require(totalSupply() + _num <= maxSupply, "Num must lower maxSupply");
        for (uint256 i = 0; i < _num; i++) {
            _safeMint(_addresss, totalSupply() + 1);
        }
    }

    function mintReserved(address _address, uint256 _num) external onlyOwner {
        require(
            reservedNum + _num <= maxReservedNum,
            "reservedNum must lower maxReservedNum"
        );
        mint(_address, _num);
        reservedNum += _num;
    }

    function presaleWhitelist(uint256 _num, bytes32[] memory _proof)
        external
        payable
    {
        require(_num == 1, "Num must be 1");
        require(!whitelistMined[msg.sender], "Already whitelist mined");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, root, leaf), "Verification failed");
        require(
            msg.value == whitelistPrice * _num,
            "Value must eq whitelistPrice*num"
        );
        require(
            whitelistStartTime <= block.timestamp,
            "Whitelist pre-sale has not started yet"
        );
        require(
            whitelistEndTime > block.timestamp,
            "Whitelist pre-sale has ended"
        );
        require(
            whitelistNum + _num <= maxWhitelistNum,
            "Num must lower maxWhitelistNum"
        );
        mint(msg.sender, _num);
        whitelistNum += _num;
        whitelistMined[msg.sender] = true;
    }

    function presale(uint256 _num) external payable {
        require(!presaleMined[msg.sender], "Already presale mined");
        require(
            msg.value == presalePrice * _num,
            "Value must eq presalePrice1*num"
        );
        require(
            presaleStartTime <= block.timestamp,
            "Pre-sale has not started yet"
        );
        require(presaleEndTime > block.timestamp, "Pre-sale has ended");
        require(
            presaleNum + _num <= maxPresaleNum,
            "Num must lower maxPresaleNum"
        );
        mint(msg.sender, _num);
        presaleNum += _num;
        presaleMined[msg.sender] = true;
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setMaxBatch(uint256 _maxBatch) public onlyOwner {
        maxBatch = _maxBatch;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function pause(bool _isPause) public onlyOwner {
        if (paused() != _isPause) {
            if (_isPause) {
                _pause();
            } else {
                _unpause();
            }
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setDefaultURI(string memory _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory imageURI = bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _tokenId.toString()))
            : defaultURI;

        return imageURI;
    }
}