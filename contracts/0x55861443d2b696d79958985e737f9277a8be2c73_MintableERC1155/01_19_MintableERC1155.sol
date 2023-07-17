// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract MintableERC1155 is Initializable, ERC1155Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    address public owner;
    address public signer;
    uint256 public ownerPercent;

    string public name;
    string public symbol;

    mapping(uint256 => string) private _tokenURIs;
    mapping (uint256 => uint256) public tokenSupply;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        address upgrader_,
        address signer_,
        address operator_,
        uint256 ownerPercent_
    ) initializer public {
        __ERC1155_init("");
        __AccessControl_init();
        __UUPSUpgradeable_init();

        owner = owner_;
        signer = signer_;

        name = name_;
        symbol = symbol_;
        ownerPercent = ownerPercent_;

        _grantRole(DEFAULT_ADMIN_ROLE, owner_);
        _grantRole(MINTER_ROLE, owner_);
        _grantRole(MINTER_ROLE, upgrader_);
        _grantRole(UPGRADER_ROLE, upgrader_);
        _grantRole(OPERATOR_ROLE, operator_);
    }

    function totalSupply(uint256 id_) public view returns (uint256) {
        return tokenSupply[id_];
    }

    function mint(address to_, uint256 id_, uint256 amount_, string memory uri_, bytes memory data_)
        public
        onlyRole(MINTER_ROLE)
    {
        _mint(to_, id_, amount_, data_);
        _setURI(id_, uri_);
        tokenSupply[id_] = tokenSupply[id_].add(1);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    function uri(uint256 tokenId)
        public
        view
        override(ERC1155Upgradeable)
        returns (string memory)
    {
        return _tokenURIs[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdrawComission() public onlyRole(OPERATOR_ROLE) {
        uint balance = address(this).balance;

        (bool sent, /* bytes memory data */) = msg.sender.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    function purchase(
      uint256 id_,
      uint256 price_,
      uint256 amount_,
      string memory uri_,
      bytes memory signature_,
      bytes memory data
    )
        public
        payable
    {
        require(price_ <= msg.value, "insuffient amount");

        string memory message = getMessage(id_, price_, amount_, uri_);
        address recovered = verify(getEthSignedHash(message), signature_);

        require(recovered == signer, "Signature mismatch");

        (bool sent, /* bytes memory data */) = owner.call{value: msg.value.div(100).mul(ownerPercent)}("");
        require(sent, "Failed to send Ether");

        _mint(msg.sender, id_, amount_, data);
        _setURI(id_, uri_);
        tokenSupply[id_] = tokenSupply[id_].add(1);
    }

    function getMessage(uint256 id_, uint256 price_, uint256 amount_, string memory uri_) public pure returns (string memory) {
        return string(abi.encodePacked(uri_, StringsUpgradeable.toString(id_), StringsUpgradeable.toString(price_), StringsUpgradeable.toString(amount_)));
    }

    function getEthSignedHash(string memory str) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(bytes(str).length), str));
    }
    
    function verify(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     */
    function _setURI(uint256 tokenId, string memory tokenURI) internal virtual {
        if (tokenSupply[tokenId] == 0) {
            _tokenURIs[tokenId] = tokenURI;
            emit URI(uri(tokenId), tokenId);
        }
    }
}