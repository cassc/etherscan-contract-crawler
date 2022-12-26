// SPDX-License-Identifier: CC0-1.0

/// @title ENS Avatar Mirror

/**
 *        ><<    ><<<<< ><<    ><<      ><<
 *      > ><<          ><<      ><<      ><<
 *     >< ><<         ><<       ><<      ><<
 *   ><<  ><<        ><<        ><<      ><<
 *  ><<<< >< ><<     ><<        ><<      ><<
 *        ><<        ><<       ><<<<    ><<<<
 */

pragma solidity ^0.8.17;

import "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";

error NotDomainOwner();
error SameSenderAndReceiver();
error AccountBoundToken();

contract ENSAvatarMirror is
    Initializable,
    ERC721Upgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    struct TokenDetails {
        address minter;
        bytes32 node;
        string domain;
    }

    mapping(uint256 => TokenDetails) internal _tokenDetails;

    address public ens;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
        _transferOwnership(admin);

        __ERC721_init("ENS Avatar Mirror", "ENSMIRROR");
        ens = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    }

    function transferOwnership(address newOwner) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _transferOwnership(newOwner);
    }

    function namehashLabelCount(string memory domain) internal pure returns (uint256 count) {
        bytes memory domainBytes = bytes(domain);

        if (domainBytes.length > 0) {
            count += 1;
        }

        for (uint256 i = 0; i < domainBytes.length; i++) {
            if (domainBytes[i] == ".") {
                count += 1;
            }
        }
    }

    function namehashLabels(string memory domain) internal pure returns (bytes32[] memory) {
        bytes memory domainBytes = bytes(domain);
        bytes32[] memory labels = new bytes32[](namehashLabelCount(domain));

        if (labels.length == 0) {
            return labels;
        }

        uint256 fromIndex = 0;
        uint256 labelIndex = labels.length - 1;
        for (uint256 i = 0; i < domainBytes.length && labelIndex > 0; i++) {
            if (domainBytes[i] == ".") {
                labels[labelIndex] = keccak256(abi.encodePacked(substring(domain, fromIndex, i)));
                labelIndex -= 1;
                fromIndex = i + 1;
            }
        }

        labels[labelIndex] = keccak256(abi.encodePacked(substring(domain, fromIndex, domainBytes.length)));

        return labels;
    }

    function namehash(string memory domain) internal pure returns (bytes32 result) {
        bytes32[] memory labels = namehashLabels(domain);
        for (uint256 i = 0; i < labels.length; i++) {
            result = keccak256(abi.encodePacked(result, labels[i]));
        }
    }

    function mint(string memory domain, address to) external returns (uint256) {
        bytes32 node = namehash(domain);

        if (getNodeOwner(node) != msg.sender) {
            revert NotDomainOwner();
        }

        if (to == msg.sender) {
            revert SameSenderAndReceiver();
        }

        uint256 tokenId = uint256(keccak256(abi.encodePacked(node, to)));
        _safeMint(to, tokenId);
        _tokenDetails[tokenId] = TokenDetails(msg.sender, node, domain);

        return tokenId;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 tokenId)
        internal
        virtual
        override
    {
        super._beforeTokenTransfer(from, to, firstTokenId, tokenId);

        if (from == address(0) || to == address(0)) {
            /* allow during minting or burning */
            return;
        }

        if (from != to) {
            revert AccountBoundToken();
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function getNodeResolver(bytes32 node) internal view returns (address) {
        (bool success, bytes memory data) = ens.staticcall(abi.encodeWithSignature("resolver(bytes32)", node));

        // solhint-disable-next-line reason-string
        require(success);

        return abi.decode(data, (address));
    }

    function getNodeOwner(bytes32 node) internal view returns (address owner) {
        (bool success, bytes memory data) = ens.staticcall(abi.encodeWithSignature("owner(bytes32)", node));

        // solhint-disable-next-line reason-string
        require(success);

        owner = abi.decode(data, (address));

        if (owner.code.length > 0) {
            (success, data) = owner.staticcall(abi.encodeWithSignature("isWrapped(bytes32)", node));

            // solhint-disable-next-line reason-string
            require(success && abi.decode(data, (bool)));

            (success, data) = owner.staticcall(abi.encodeWithSignature("ownerOf(uint256)", node));

            // solhint-disable-next-line reason-string
            require(success);

            owner = abi.decode(data, (address));
        }

        return owner;
    }

    function resolveText(address resolver, bytes32 node, string memory key) internal view returns (string memory) {
        (bool success, bytes memory data) =
            resolver.staticcall(abi.encodeWithSignature("text(bytes32,string)", node, key));

        if (success) {
            return abi.decode(data, (string));
        }
        return "";
    }

    function substring(string memory str, uint256 startIndex, uint256 endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function parseAddrString(string memory addr) internal pure returns (address) {
        bytes memory addrBytes = bytes(addr);
        uint160 intAddr;

        for (uint256 i = 2; i < 42; i += 2) {
            uint8 b1 = uint8(addrBytes[i]);
            if (b1 >= 97 && b1 <= 102) {
                b1 -= 87;
            } else if (b1 >= 65 && b1 <= 70) {
                b1 -= 55;
            } else if (b1 >= 48 && b1 <= 57) {
                b1 -= 48;
            }

            uint8 b2 = uint8(addrBytes[i + 1]);
            if (b2 >= 97 && b2 <= 102) {
                b2 -= 87;
            } else if (b2 >= 65 && b2 <= 70) {
                b2 -= 55;
            } else if (b2 >= 48 && b2 <= 57) {
                b2 -= 48;
            }

            intAddr = intAddr * 256 + (b1 * 16 + b2);
        }

        return address(intAddr);
    }

    function parseIntString(string memory intStr) internal pure returns (uint256 result) {
        bytes memory intStrBytes = bytes(intStr);

        for (uint256 i = 0; i < intStrBytes.length; i++) {
            result = result * 10 + uint8(intStrBytes[i]) - 48;
        }

        return result;
    }

    function uriScheme(string memory uri) internal pure returns (bytes32 scheme, uint256 len, bytes32 root) {
        bytes memory uriBytes = bytes(uri);
        uint256 maxIndex = uriBytes.length > 32 ? 32 : uriBytes.length;
        for (uint256 i = 1; i < maxIndex; i++) {
            if (uriBytes[i] == ":") {
                scheme = bytes32(abi.encodePacked(substring(uri, 0, i)));
                len = i;
                if (root == 0) {
                    root = scheme;
                }
                if (scheme != "eip155") {
                    break;
                }
            }
        }
    }

    function defaultTokenURIUninitialized(uint256 tokenId) internal view returns (string memory) {
        return defaultTokenURI(
            tokenId, "https://avatar-mirror.infura-ipfs.io/ipfs/QmT89YMj7S9bM7t4i6JoaYqgMuRMrMys2xGtgoBLioGfCM"
        );
    }

    function defaultTokenURIError(uint256 tokenId) internal view returns (string memory) {
        return defaultTokenURI(
            tokenId, "https://avatar-mirror.infura-ipfs.io/ipfs/QmP4jH3hfU6CWh9hPxoDk93SVYrHCjQwHoNdHoRPWskpoW"
        );
    }

    function defaultTokenURI(uint256 tokenId, string memory image) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                "{\"name\": \"",
                name(),
                " [",
                _tokenDetails[tokenId].domain,
                "]\", \"description\": \"",
                "Mirrors an ERC721 or ERC1155 token referenced in the avatar field on an ENS node. Useful for hot wallet accounts that want to show the same avatar as their cold wallet otherwise would.",
                "\", \"image\": \"",
                image,
                "\"}"
            )
        );
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        bytes32 node = _tokenDetails[tokenId].node;
        address resolver = getNodeResolver(node);
        string memory avatarURI = resolveText(resolver, node, "avatar");

        if (bytes(avatarURI).length == 0) {
            return defaultTokenURIUninitialized(tokenId);
        }

        (, uint256 len, bytes32 root) = uriScheme(avatarURI);
        if (root == "eip155") {
            address nftContract = parseAddrString(substring(avatarURI, len + 1, len + 43));
            uint256 nftContractTokenId = parseIntString(substring(avatarURI, len + 44, bytes(avatarURI).length));

            (bool success, bytes memory data) =
                nftContract.staticcall(abi.encodeWithSignature("tokenURI(uint256)", nftContractTokenId));

            if (!success) {
                (success, data) = nftContract.staticcall(abi.encodeWithSignature("uri(uint256)", nftContractTokenId));

                if (!success) {
                    return defaultTokenURIError(tokenId);
                }
            }

            return abi.decode(data, (string));
        }

        if (len > 1) {
            return defaultTokenURI(tokenId, avatarURI);
        }

        return defaultTokenURIUninitialized(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}