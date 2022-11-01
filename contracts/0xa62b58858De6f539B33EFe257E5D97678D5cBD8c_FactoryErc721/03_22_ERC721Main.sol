// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-solidity/contracts/access/AccessControl.sol";
import "./exchange-provider/IExchangeProvider.sol";

import "./IFees.sol";

contract ERC721Main is
    ERC721Burnable,
    ERC721Enumerable,
    ERC721URIStorage,
    ReentrancyGuard,
    AccessControl
{
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    string public baseURI;

    address public factory;

    uint256 private _lastMintedId; 
    mapping(string => bool) private hasTokenWithURI;

    string private CONTRACT_URI;
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseURI_,
        string memory _CONTRACT_URI,
        address signer
    ) ERC721(_name, _symbol) {
        factory = _msgSender();
        baseURI = baseURI_;
        _setupRole(DEFAULT_ADMIN_ROLE, signer);
        _setupRole(SIGNER_ROLE, signer);
        CONTRACT_URI = _CONTRACT_URI;
    }

    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(CONTRACT_URI, _toString(uint256(uint160(address(this)))), "/"));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        ERC721._beforeTokenTransfer(from, to, tokenId);
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        hasTokenWithURI[tokenURI(tokenId)] = false;
        ERC721URIStorage._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC721Enumerable.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function mint (
        string calldata _tokenURI,
        bytes calldata signature
    ) external payable nonReentrant {
        _verifySigner(_tokenURI, signature);
        require(!hasTokenWithURI[_tokenURI], "ERC721Main: URI already exists");

        require(msg.value == IFees(factory).getFee(), "Wrong mint fees");
        payable(IFees(factory).getReceiver()).transfer(msg.value);

        uint256 tokenId = _lastMintedId++;
        _safeMint(_msgSender(), tokenId);
        
        hasTokenWithURI[_tokenURI] = true;
        _setTokenURI(tokenId, _tokenURI);
        setApprovalForAll(IExchangeProvider(factory).exchange(), true);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _toString(uint256 value) private pure returns (string memory) {
        bytes memory buffer = new bytes(42);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 41; i > 1; i--) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }

    function _verifySigner(string calldata _tokenURI, bytes calldata signature) private view {
        address signer =
            ECDSA.recover(keccak256(abi.encodePacked(this, _tokenURI)), signature);
        require(
            hasRole(SIGNER_ROLE, signer),
            "ERC721Main: Signer should sign transaction"
        );
    }
}