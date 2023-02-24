// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "ens-contracts/registry/ENS.sol";
import "lib/solidity-stringutils/src/strings.sol";

// additions by @lcfr_eth
// original implementation by @hodl_esf

// AccountShort
struct Account {
    string name;
    address addr;
    string avatar;
}

// AccountFull
struct AccountFull {
    string name;
    address addr;
    address payaddr;
    bytes content;
    string avatar;
    string email;
    string url;
    string description;
    string notice;
    string keywords;
    string discord;
    string twitter;
}

struct tokenInfo {
    uint scheme;
    uint tokenId;
    address token;
}

struct metadataInfo {
    address token;
    uint tokenId;
    string metadataURI;
}

interface IRegistrar {
    function node(address _addr) external view returns (bytes32);
}

interface IResolver {
    function name(bytes32 _node) external view returns (string memory);
}

interface IPublicResolver {
    function text(
        bytes32 node,
        string calldata text
    ) external view returns (string memory);

    function addr(bytes32 node) external view returns (address);

    function contenthash(bytes32 node) external view returns (bytes memory);

    function supportsInterface(bytes4 interfaceID) external pure returns (bool);
}

contract AddressLookup is Ownable {
    using strings for *;

    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant TEXT_INTERFACE_ID = 0x59d1d43c;
    bytes4 constant CONTENT_HASH_INTERFACE_ID = 0xbc1c58d1;

    address REVERSE_REGISTRAR_ADDRESS =
        0x084b1c3C81545d370f3634392De611CaaBFf8148;
    address REVERSE_RESOLVER_ADDRESS =
        0xA2C122BE93b0074270ebeE7f6b7292C7deB45047;
    address ENS_ADDRESS = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;

    IResolver reverse_resolver = IResolver(REVERSE_RESOLVER_ADDRESS);
    IRegistrar reverse_registrar = IRegistrar(REVERSE_REGISTRAR_ADDRESS);

    ENS public ens = ENS(ENS_ADDRESS);

    function setReverseResolver(address _new) external onlyOwner {
        REVERSE_RESOLVER_ADDRESS = _new;
    }

    function setReverseRegsitrar(address _new) external onlyOwner {
        REVERSE_REGISTRAR_ADDRESS = _new;
    }

    function setENS(address _new) external onlyOwner {
        ENS_ADDRESS = _new;
    }

    function batchNamesAndAvatars(
        address[] calldata _addr
    ) external view returns (Account[] memory) {
        Account[] memory names = new Account[](_addr.length);

        for (uint256 i; i < _addr.length; i++) {
            Account memory account;
            account.addr = _addr[i];

            bytes32 reverse_node = reverse_registrar.node(_addr[i]);
            string memory name = reverse_resolver.name(reverse_node);
            bytes32 node = getDomainHash(name);
            address resolverAddr = ens.resolver(node);

            if (resolverAddr != address(0)) {
                IPublicResolver resolv = IPublicResolver(resolverAddr);

                address addr = resolv.addr(node);

                if (addr == _addr[i]) {
                    account.name = name;

                    // do forward resolution check and interface check
                    if (resolv.supportsInterface(TEXT_INTERFACE_ID)) {
                        account.avatar = resolv.text(node, "avatar");
                    }
                }
            }
            names[i] = account;
        }
        return names;
    }

    function batchAccountsFull(
        address[] calldata _addr
    ) external view returns (AccountFull[] memory) {
        AccountFull[] memory names = new AccountFull[](_addr.length);

        for (uint256 i; i < _addr.length; i++) {
            AccountFull memory account;
            account.addr = _addr[i];

            bytes32 reverse_node = reverse_registrar.node(_addr[i]);
            string memory name = reverse_resolver.name(reverse_node);
            bytes32 node = getDomainHash(name);
            address resolverAddr = ens.resolver(node);

            if (resolverAddr != address(0)) {
                IPublicResolver resolv = IPublicResolver(resolverAddr);

                address addr = resolv.addr(node);

                if (addr == _addr[i]) {
                    if (resolv.supportsInterface(CONTENT_HASH_INTERFACE_ID)) {
                        account.content = resolv.contenthash(node);
                    }

                    if (resolv.supportsInterface(ADDR_INTERFACE_ID)) {
                        account.payaddr = resolv.addr(node);
                    }

                    if (resolv.supportsInterface(TEXT_INTERFACE_ID)) {
                        account.avatar = resolv.text(node, "avatar");
                        account.email = resolv.text(node, "email");
                        account.url = resolv.text(node, "url");
                        account.description = resolv.text(node, "description");
                        account.notice = resolv.text(node, "notice");
                        account.keywords = resolv.text(node, "keywords");
                        account.discord = resolv.text(node, "discord");
                        account.twitter = resolv.text(node, "twitter");
                    }
                }
            }

            names[i] = account;
        }
        return names;
    }

    function batchMetaData(
        tokenInfo[] calldata _tokens
    ) external view returns (metadataInfo[] memory) {
        metadataInfo[] memory _metadata = new metadataInfo[](_tokens.length);

        for (uint i = 0; i < _tokens.length; i++) {
            if (_tokens[i].scheme == 721) {
                string memory metadataURI = IERC721Metadata(_tokens[i].token)
                    .tokenURI(_tokens[i].tokenId);
                _metadata[i] = metadataInfo(
                    _tokens[i].token,
                    _tokens[i].tokenId,
                    metadataURI
                );
            }

            if (_tokens[i].scheme == 1155) {
                string memory metadataURI = IERC1155MetadataURI(
                    _tokens[i].token
                ).uri(_tokens[i].tokenId);
                _metadata[i] = metadataInfo(
                    _tokens[i].token,
                    _tokens[i].tokenId,
                    metadataURI
                );
            }
        }
        return _metadata;
    }

    function getParts(
        string memory _string
    ) internal view returns (string[] memory) {
        strings.slice memory delim = ".".toSlice();
        strings.slice memory _string = _string.toSlice();
        uint256 count = _string.count(delim);

        if (count == 0) {
            string[] memory x = new string[](0);
            return x;
        }

        string[] memory parts = new string[](_string.count(delim) + 1);
        for (uint i = 0; i < parts.length; i++) {
            parts[i] = _string.split(delim).toString();
        }
        return parts;
    }

    function getDomainHash(
        string memory _ensName
    ) internal view returns (bytes32 namehash) {
        string[] memory _arr = getParts(_ensName);
        namehash = 0x0;
        for (uint256 i; i < _arr.length; ) {
            unchecked {
                ++i;
            }
            namehash = keccak256(
                abi.encodePacked(
                    namehash,
                    keccak256(abi.encodePacked(_arr[_arr.length - i]))
                )
            );
        }
        return namehash;
    }
}