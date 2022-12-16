// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IMetaRegistry.sol";
import "./ERC721.sol";

library Utils {
    function rUint8(bytes memory self, uint8 i)
        internal
        pure
        returns (uint8, uint8)
    {
        return (i + 1, uint8(self[i]));
    }

    function rName(bytes memory self, uint8 i)
        internal
        pure
        returns (uint8, bytes memory b)
    {
        uint8 size = uint8(self[i++]);
        b = new bytes(size);
        for (uint8 j = 0; j < size; j++) {
            b[j] = self[i + j];
        }
        return (i + size, b);
    }

    function rValue(bytes memory self, uint8 i)
        internal
        pure
        returns (uint8, string memory)
    {
        if (self[i] == 0x00) {
            // uint
            uint32 value;
            assembly {
                value := mload(add(self, add(i, 5)))
            }
            return (i + 5, Strings.toString(uint256(value)));
        } else {
            // string
            uint8 size = uint8(self[i + 1]);
            bytes memory str = new bytes(size);
            for (uint8 j = 0; j < size; j++) {
                str[j] = self[i + 2 + j];
            }
            return (i + 2 + size, string(str));
        }
    }
}

contract MetaERC721 is Ownable, ERC721 {
    using Utils for bytes;

    string public name;
    string public symbol;
    string internal baseURI;

    uint256 public increase;
    IMetaRegistry public registry;
    mapping(uint256 => bytes) public props;
    mapping(uint16 => bytes) public typeOf;

    event Upgraded(address indexed owner, uint256 indexed tokenId, bytes props);

    function setIncrease(uint256 _increase) external onlyOwner {
        increase = _increase;
    }

    function setup(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _registry
    ) external onlyOwner {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;

        _setup(_name);
        updateRegistry(_registry);
    }

    function updateRegistry(address _registry) public onlyOwner {
        registry = IMetaRegistry(_registry);
        if (registry.getManager(address(this)) == address(this)) {
            registry.setManager(address(this), _msgSender());
        }
    }

    function regist(uint16 typ, bytes calldata data) external onlyOwner {
        typeOf[typ] = data;
    }

    function batchMint(address to, uint256 typ) external onlyOwner {
        uint256 tokenId = (++increase) * 1e4 + typ;
        _safeMint(to, tokenId);
    }

    function safeMine(
        address to,
        uint256 typ,
        bytes32 interfaceHash
    ) external onlyRegistry(interfaceHash) {
        uint256 tokenId = (++increase) * 1e4 + typ;
        _safeMint(to, tokenId);
    }

    function safeUpdate(
        uint256 tokenId,
        bytes calldata data,
        bytes32 interfaceHash
    ) external onlyRegistry(interfaceHash) {
        require(_exists(tokenId), "token does not exist");
        props[tokenId] = data;
        emit Upgraded(ownerOf(tokenId), tokenId, data);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "token does not exist");
        bytes memory rets = abi.encodePacked(
            baseURI,
            Strings.toHexString(uint160(address(this)), 20),
            Strings.toString(tokenId)
        );

        uint8 size;
        uint8 offset;
        bytes storage prop = props[tokenId];
        if (prop.length == 0) {
            (prop, offset) = (typeOf[uint16(tokenId % 1e4)], 2);
        }

        (offset, size) = prop.rUint8(offset);
        for (uint8 i = 0; i < size; i++) {
            bytes memory key;
            (offset, key) = prop.rName(offset);
            string memory value;
            (offset, value) = prop.rValue(offset);
            rets = abi.encodePacked(rets, i == 0 ? "?" : "&", key, "=", value);
        }
        return string(rets);
    }

    modifier onlyRegistry(bytes32 interfaceHash) {
        address impl = registry.getInterfaceImplementer(
            address(this),
            interfaceHash
        );
        require(_msgSender() == impl, "caller not implementer");

        _;
    }
}