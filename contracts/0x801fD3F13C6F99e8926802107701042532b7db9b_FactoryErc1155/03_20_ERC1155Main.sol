// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "openzeppelin-solidity/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "openzeppelin-solidity/contracts/access/AccessControl.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "./exchange-provider/IExchangeProvider.sol";
import "./ERC1155URIStorage.sol";
import "./IFees.sol";

contract ERC1155Main is ERC1155Burnable, ERC1155URIStorage, AccessControl, ReentrancyGuard {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    address public factory;
    string public name;

    uint256 private _lastMintedId; 
    mapping(string => bool) hasTokenWithURI;

    string private CONTRACT_URI;
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    constructor(string memory _name, string memory _baseUri, string memory _CONTRACT_URI, address signer) ERC1155("") {
        factory = _msgSender();
        name = _name;
        _setBaseUri(_baseUri);
        _setupRole(DEFAULT_ADMIN_ROLE, signer);
        _setupRole(SIGNER_ROLE, signer);
        CONTRACT_URI = _CONTRACT_URI;
    }

    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(CONTRACT_URI, _toString(uint256(uint160(address(this)))), "/"));
    }

    function mint(
        uint256 amount,
        string calldata _tokenURI,
        bytes calldata signature
    ) external payable nonReentrant{
        _verifySigner(_tokenURI, amount, signature);
        require(!hasTokenWithURI[_tokenURI], "ERC1155Main: URI already exists");

        require(msg.value == IFees(factory).getFee(), "Wrong mint fees");
        payable(IFees(factory).getReceiver()).transfer(msg.value);

        uint256 id = _lastMintedId++;
        _mint(_msgSender(), id, amount, "");
        setApprovalForAll(IExchangeProvider(factory).exchange(), true);
        _markTokenId(id);
        hasTokenWithURI[_tokenURI] = true;
        _setTokenURI(id, _tokenURI);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC1155URIStorage)
        returns (string memory)
    {
        return ERC1155URIStorage.tokenURI(tokenId);
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return ERC1155URIStorage.tokenURI(tokenId);
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

    function _verifySigner(
        string calldata _tokenURI,
        uint256 amount,
        bytes calldata signature
    ) private view {
        address signer =
            ECDSA.recover(
                keccak256(abi.encodePacked(this, _tokenURI, amount)),
                signature
            );
        require(
            hasRole(SIGNER_ROLE, signer),
            "ERC1155Main: Signer should sign transaction"
        );
    }
}