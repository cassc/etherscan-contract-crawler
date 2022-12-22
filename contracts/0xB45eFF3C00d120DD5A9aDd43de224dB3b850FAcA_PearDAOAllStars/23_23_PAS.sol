// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract PearDAOAllStars is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;
    bytes32 private root;
    address public uriOperator;

    mapping(uint8 => mapping(address => uint8)) public whiteList;
    mapping(uint8 => mapping(address => bool)) public verifyAddress;

    uint8 public currentRound;

    function initialize() public initializer {
        __ERC721_init("PearDAO All Stars", "PAS");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        currentRound = 1;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setRound(uint8 round) external onlyOwner {
        currentRound = round;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setOperatorAddress(address addr) external onlyOwner {
        uriOperator = addr;
    }

    function setTokenURI(uint256 tokenId, string calldata uri) external {
        require(uriOperator == _msgSender(), "invalid address");
        _setTokenURI(tokenId, uri);
    }

    event UserMint(address userAddr, uint256 tokenId, string uri);

    function mint(
        bytes32[] memory proof,
        uint8 amount,
        string[] memory uris
    ) external {
        address addr = _msgSender();

        if (!verifyAddress[currentRound][addr]) {
            bytes32 leaf = keccak256(
                bytes.concat(keccak256(abi.encode(addr, amount)))
            );
            require(
                MerkleProofUpgradeable.verify(proof, root, leaf),
                "Invalid proof"
            );

            whiteList[currentRound][addr] = amount;
            verifyAddress[currentRound][addr] = true;
        }
        require(
            uris.length <= whiteList[currentRound][addr],
            "invalid address"
        );

        for (uint16 i = 0; i < uris.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(addr, tokenId);
            _setTokenURI(tokenId, uris[i]);
            emit UserMint(addr, tokenId, uris[i]);
        }
        whiteList[currentRound][addr] =
            whiteList[currentRound][addr] -
            uint8(uris.length);
    }
}