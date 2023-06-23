// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract AVXNFT is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter public _tokenIdCounter;

    uint256 public flagCounter;
    string private baseTokenURI;
    address public owner;
    address public operator;

    event BaseURIUpdated(string previousBaseURI, string newBaseURI);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event OperatorChanged(
        address indexed previousOperator,
        address indexed newOperator
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _flagCounter) public initializer {
        __ERC721_init("AVX", "AVX");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        owner = msg.sender;
        operator = msg.sender;
        _grantRole("ADMIN_ROLE", msg.sender);
        _grantRole("OPERATOR_ROLE", msg.sender);
        _tokenIdCounter.increment();
        flagCounter = _flagCounter;
        baseTokenURI = "https://ipfs.io/ipfs/";
    }

    function transferOwnership(
        address newOwner
    ) external onlyRole("ADMIN_ROLE") returns (bool) {
        require(newOwner != address(0), "new owner is the zero address");
        _revokeRole("ADMIN_ROLE", owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        _grantRole("ADMIN_ROLE", newOwner);
        return true;
    }

    function changeOperator(
        address newOperator
    ) external onlyRole("ADMIN_ROLE") returns (bool) {
        require(newOperator != address(0), "new Operator is the zero address");
        _revokeRole("OPERATOR_ROLE", operator);
        emit OperatorChanged(operator, newOperator);
        operator = newOperator;
        _grantRole("OPERATOR_ROLE", newOperator);
        return true;
    }

    function safeMint(
        address receiver,
        string calldata uri,
        bool regionFlag
    ) external onlyRole("OPERATOR_ROLE") returns (uint256) {
        uint256 tokenId;
        if(!regionFlag || _tokenIdCounter.current() > 150000){
            tokenId = flagCounter;
            unchecked {
                flagCounter += 1;
            }
        }
        else
        {
            tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
        }
        _safeMint(receiver, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    function setBaseURI(
        string calldata _baseTokenURI
    ) external onlyRole("ADMIN_ROLE") {
        emit BaseURIUpdated(baseTokenURI, _baseTokenURI);
        baseTokenURI = _baseTokenURI;
    }

    function baseURI() external view returns (string memory) {
        //[email protected] why do have to return
        return _baseURI();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole("ADMIN_ROLE") {}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        require(from == address(0) || to == address(0), "Transfer restricted");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC721URIStorageUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}