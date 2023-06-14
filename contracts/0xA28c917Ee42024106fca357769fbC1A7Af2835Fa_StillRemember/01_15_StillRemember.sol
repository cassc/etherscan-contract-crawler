// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface IBeach {
    function data() external view returns (bytes memory);
}

/// @title EIP-721 Metadata Update Extension
interface IERC4906 is IERC165, IERC721 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);
}

interface IDateTime {
    function timestampToDateTime(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );
}

contract StillRemember is ERC721, ERC2981, IERC4906, ReentrancyGuard, Ownable {
    uint256 private _tokenSupply;
    uint256 private constant EXPIRE_TIME = 1095 days;
    bool public isActive;
    string private _description;
    string private _baseExternalURI;
    IBeach private beach;
    IDateTime private datetime;

    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(uint256 => uint256) public lastRememberAt;
    mapping(uint256 => uint256) public mintAt;

    event ExchangeMemories(string _memory, uint256 _tokenId);

    constructor(address _beach, address _datetime) ERC721("Still Remember", "STLRMB") {
        // _setDefaultRoyalty(owner(), 1000);
        beach = IBeach(_beach);
        datetime = IDateTime(_datetime);
    }

    function exchangeMemories(string memory _memory) external nonReentrant {
        require(isActive, "INACTIVE");
        _tokenSupply++;
        mintAt[_tokenSupply] = block.timestamp;
        tokenIdToHash[_tokenSupply] = keccak256(
            abi.encodePacked(_memory, block.number, blockhash(block.number - 1))
        );
        _safeMint(_msgSender(), _tokenSupply);
        emit ExchangeMemories(_memory, _tokenSupply);
    }

    /* token utility */

    function setIsActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    function setDescription(string memory desc) external onlyOwner {
        _description = desc;
    }

    function setBaseExternalURI(string memory URI) external onlyOwner {
        _baseExternalURI = URI;
    }

    function rememberDays(uint256 _tokenId) private view returns (uint256) {
        return isRemember(_tokenId) ? (block.timestamp - mintAt[_tokenId]) / 1 days : 0;
    }

    function isRemember(uint256 _tokenId) private view returns (bool) {
        return lastRememberAt[_tokenId] + EXPIRE_TIME >= block.timestamp;
    }

    function brokenRate(uint256 value) public pure returns (uint256) {
        value = value / 60;
        uint256 _tmp;
        if (value <= 20) {
            _tmp = 100 - (value * 21000) / 10000;
        } else if (value <= 60) {
            _tmp = 58 - ((value - 20) * 3500) / 10000;
        } else if (value <= 90) {
            _tmp = 44 - ((value - 60) * 3000) / 10000;
        } else if (value <= 1440) {
            _tmp = 35 - ((value - 90) * 7) / 10000;
        } else if (value <= 2880) {
            _tmp = 34 - ((value - 1440) * 48) / 10000;
        } else if (value <= 8640) {
            _tmp = 27 - ((value - 2880) * 3) / 10000;
        } else if (value <= 259200) {
            _tmp = 25 - ((value - 8640) * 1) / 10000;
        } else {
            _tmp = 0;
        }
        return 100 - _tmp;
    }

    function tokenBrokenRate(uint256 _tokenId) private view returns (uint256) {
        return brokenRate(block.timestamp - lastRememberAt[_tokenId]);
    }

    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function image(bytes32 _seed, uint256 _level) public view returns (string memory) {
        unchecked {
            uint256 startBytes = 1000; // min450
            uint256 length = 18236;
            uint256 endBytes = length - startBytes - 0;
            bytes memory result = beach.data();
            for (uint256 i = 0; i < _level; i++) {
                uint256 rand = startBytes +
                    (uint256(keccak256(abi.encodePacked(_seed, i))) % endBytes);
                result[rand] = TABLE[uint256(keccak256(abi.encodePacked("C", _seed, i))) % 64];
            }
            return string(abi.encodePacked("data:image/jpeg;base64,", result));
        }
    }

    function timestampToString(uint256 _timestamp) public view returns (string memory) {
        (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        ) = datetime.timestampToDateTime(_timestamp);

        return
            string(
                abi.encodePacked(
                    Strings.toString(year),
                    "-",
                    month > 9 ? "" : "0",
                    Strings.toString(month),
                    "-",
                    day > 9 ? "" : "0",
                    Strings.toString(day),
                    "T",
                    hour > 9 ? "" : "0",
                    Strings.toString(hour),
                    ":",
                    minute > 9 ? "" : "0",
                    Strings.toString(minute),
                    ":",
                    second > 9 ? "" : "0",
                    Strings.toString(second)
                )
            );
    }

    function getMetaData(uint256 _tokenId) private view returns (string memory) {
        uint256 rate = tokenBrokenRate(_tokenId);
        return
            string(
                abi.encodePacked(
                    '{"name":"Still Remember #',
                    Strings.toString(_tokenId),
                    '","description":"',
                    _description,
                    '","image":"',
                    image(tokenIdToHash[_tokenId], rate),
                    '","external_url":"',
                    _baseExternalURI,
                    Strings.toString(_tokenId),
                    '","attributes":[{"trait_type":"Last Remembered","value":"',
                    timestampToString(lastRememberAt[_tokenId]),
                    '(UTC)"},{"trait_type":"Days","value":',
                    Strings.toString(rememberDays(_tokenId)),
                    '},{"trait_type":"Expiry Date","value":"',
                    timestampToString(lastRememberAt[_tokenId] + EXPIRE_TIME),
                    '(UTC)"},{"trait_type":"Still Remember","value":"',
                    isRemember(_tokenId) ? "YES" : "NO",
                    '"},{"trait_type":"Breakage Rate","value":',
                    Strings.toString(rate),
                    "}]}"
                )
            );
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked("data:application/json;utf8,", getMetaData(_tokenId)));
    }

    function totalSupply() external view returns (uint256) {
        return _tokenSupply;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, firstTokenId);
        if (from == address(0) || lastRememberAt[firstTokenId] + EXPIRE_TIME > block.timestamp) {
            lastRememberAt[firstTokenId] = block.timestamp;
        }
        if (from != address(0)) {
            emit MetadataUpdate(firstTokenId);
        }
    }

    function setRoyaltyInfo(address receiver_, uint96 royaltyBps_) external onlyOwner {
        _setDefaultRoyalty(receiver_, royaltyBps_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }
}