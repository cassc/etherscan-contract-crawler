// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "AccessControlUpgradeable.sol";
import "UUPSUpgradeable.sol";
import "ERC721AUpgradeable.sol";
import "IVoiceA.sol";

// This uses ERC721AStorage for storage layout
// This seems to have token increment built in
contract VoiceA is
    IVoiceA,
    ERC721AUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PRIMARY_MINTER_ROLE =
        keccak256("PRIMARY_MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes16 public constant _HEX_SYMBOLS = "0123456789abcdef";

    string _tokenBaseURI;
    bool _tokenUseArweave;
    mapping(uint256 => uint256) private _tokenURIs;
    mapping(uint256 => uint256) private _holdExpirations;

    constructor() {
        _disableInitializers();
    }

    function initialize(string memory baseURI, bool useArweave)
        public
        initializer
        initializerERC721A
    {
        __ERC721A_init("Voice", "VOICE");
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setBaseURI(baseURI);
        _setUseArweave(useArweave);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PRIMARY_MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function mintOne(
        address to,
        uint256 tokenURI_,
        uint256 holdDuration
    ) public onlyRole(PRIMARY_MINTER_ROLE) {
        uint256 tokenId = _nextTokenId();
        _safeMint(to, 1);
        _tokenURIs[tokenId] = tokenURI_;
        if (holdDuration > 0) {
            _holdExpirations[tokenId] = block.timestamp + holdDuration;
        }
        emit Mint(to, tokenId, tokenURI_);
    }

    function mintBatch(
        address to,
        uint256[] calldata tokenURIs,
        uint256 holdDuration
    ) public onlyRole(PRIMARY_MINTER_ROLE) {
        uint256 quantity = tokenURIs.length;
        uint256 tokenId = _nextTokenId();
        _safeMint(to, quantity);
        uint256 holdExpiration = block.timestamp + holdDuration;
        unchecked {
            uint256 length_ = tokenURIs.length;
            for (uint256 i = 0; i < length_; i++) {
                _tokenURIs[tokenId + i] = tokenURIs[i];
                if (holdDuration > 0) {
                    _holdExpirations[tokenId] = holdExpiration;
                }
                emit Mint(to, tokenId + i, tokenURIs[i]);
            }
        }
    }

    function setBaseUri(string memory baseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(baseUri);
    }

    function getBaseUri() external view virtual returns (string memory) {
        return _baseURI();
    }

    function setUseArweave(bool useArweave) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setUseArweave(useArweave);
    }

    function getUseArweave() external view virtual returns (bool) {
        return _useArweave();
    }

    // UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function _setBaseURI(string memory baseURI) internal virtual {
        _tokenBaseURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    function _setUseArweave(bool useArweave) internal virtual {
        _tokenUseArweave = useArweave;
    }

    function _useArweave() internal view virtual returns (bool) {
        return _tokenUseArweave;
    }

    function _holdExpired(uint256 tokenId) internal view virtual returns (bool) {
        uint256 holdExpiration = _holdExpirations[tokenId];
        return block.timestamp >= holdExpiration;
    }

    function burn(uint256 tokenId) public {
        require(_exists(tokenId), "VoiceA: Cannot burn non-existant NFT");
        bool holdExpired = _holdExpired(tokenId);
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || holdExpired,
            "VoiceA: NFT may not be burned until security hold has expired"
        );

        super._burn(tokenId, holdExpired);
        delete _tokenURIs[tokenId];
        delete _holdExpirations[tokenId];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IVoiceA, ERC721AUpgradeable) {
        require(
            _holdExpired(tokenId),
            "VoiceA: NFT may not be transferred until security hold has expired"
        );

        super.safeTransferFrom(from, to, tokenId);
        delete _holdExpirations[tokenId];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(IVoiceA, ERC721AUpgradeable) {
        require(
            _holdExpired(tokenId),
            "VoiceA: NFT may not be transferred until security hold has expired"
        );

        super.safeTransferFrom(from, to, tokenId, _data);
        delete _holdExpirations[tokenId];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IVoiceA, ERC721AUpgradeable) {
        require(
            _holdExpired(tokenId),
            "VoiceA: NFT may not be transferred until security hold has expired"
        );

        super.transferFrom(from, to, tokenId);
        delete _holdExpirations[tokenId];
    }

    function bareTokenURI(uint256 tokenId) view external returns(uint256) {
        require(
            _exists(tokenId),
            "VoiceA: Cannot fetch URI of non-existant NFT"
        );

        return _tokenURIs[tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "VoiceA: Cannot fetch URI of non-existant NFT"
        );

        uint256 _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            base = "";
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (_tokenURI > 0) {
            string memory hash = toHexStringNoPrefix(_tokenURI);
            if (_useArweave()) {
                hash = encode(_tokenURI);
            }
            return
                string(
                    abi.encodePacked(
                        base,
                        "/",
                        hash
                    )
                );
            // return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    // super goes right to left
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            IERC721AUpgradeable,
            ERC721AUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
    @dev copy&paste of https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Base64.sol
    @dev with string length calculation and '=' padding removed
    */
    string constant _TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+_";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(uint256 base) internal pure returns (string memory) {
        bytes memory data = bytes.concat(bytes32(base));

        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */

        // Loads the table into memory
        string memory table = _TABLE;

        string memory result = new string(43);

        /// @solidity memory-safe-assembly
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
        }

        return result;
    }

    function toHexStringNoPrefix(uint256 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(64);
        for (uint256 i = 64; i > 0; --i) {
            buffer[i - 1] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}