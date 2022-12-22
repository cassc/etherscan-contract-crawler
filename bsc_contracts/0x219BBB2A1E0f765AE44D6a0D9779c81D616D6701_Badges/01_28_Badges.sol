// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @custom:security-contact [email protected]
contract Badges is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    ERC1155SupplyUpgradeable,
    UUPSUpgradeable
{
    string public constant name = "Badges by 3GATE";
    string public constant symbol = "Badges";
    address public signer;
    mapping(bytes => bool) _usedHash;

    error UsedHash();
    error InvalidSignature();
    error ExpiredTimeStamp();
    error WrongETHValue();
    error WrongCurrencyValue();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function initialize(address _signer) public initializer {
        __ERC1155_init("https://rugquantum.s3.amazonaws.com/badges/metadata/");
        __Ownable_init();
        __AccessControl_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();
        signer = _signer;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        transferOwnership(0xE42E4F21A750C1cC1ba839E5B1e4EfC3eD1fe454);
        _mint(0x86a8A293fB94048189F76552eba5EC47bc272223, 0, 1, "0x");
    }

    modifier onlyNewhash(bytes memory signature, uint256 validUntil) {
        if (_usedHash[signature]) revert UsedHash();
        if (block.timestamp > validUntil) revert ExpiredTimeStamp();
        _usedHash[signature] = true;
        _;
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function mint(uint256 validUntil, bytes memory uniqueHash)
        public
        payable
        onlyNewhash(uniqueHash, validUntil)
    {
        (
            address to,
            uint256[] memory tokenId,
            uint256[] memory amount,
            uint256 price,
            address erc20,
            ,
            ,
            bytes memory signature
        ) = decode(uniqueHash);
        if (
            recover(tokenId, validUntil, amount, price, erc20, signature) ==
            false
        ) revert InvalidSignature();
        if (price > 0) {
            if (erc20 == address(0)) {
                if (price == msg.value) payable(to).transfer(price);
                else revert WrongETHValue();
            } else if (erc20 != address(0)) {
                IERC20(erc20).transferFrom(msg.sender, to, price);
            }
        }
        _mintBatch(to, tokenId, amount, "0x");
    }

    function decode(bytes memory data)
        public
        pure
        returns (
            address,
            uint256[] memory,
            uint256[] memory,
            uint256,
            address,
            uint256,
            uint256,
            bytes memory
        )
    {
        return
            abi.decode(
                data,
                (
                    address,
                    uint256[],
                    uint256[],
                    uint256,
                    address,
                    uint256,
                    uint256,
                    bytes
                )
            );
    }

    function uri(uint256 collectionId)
        public
        view
        override
        returns (string memory)
    {
        string memory uri_ = super.uri(collectionId);
        return
            bytes(uri_).length > 0
                ? string(abi.encodePacked(uri_, _toString(collectionId)))
                : "";
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function recover(
        uint256[] memory tokenIds,
        uint256 validUntil,
        uint256[] memory amounts,
        uint256 price,
        address erc20,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 message = keccak256(
            abi.encodePacked(
                msg.sender,
                tokenIds,
                amounts,
                price,
                erc20,
                validUntil,
                block.chainid
            )
        );
        bytes32 messageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );
        return
            SignatureChecker.isValidSignatureNow(
                signer,
                messageHash,
                signature
            );
    }

    function setSigner(address _signer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = _signer;
    }

    function setOwner(address ownership) public onlyRole(DEFAULT_ADMIN_ROLE) {
        transferOwnership(ownership);
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawERC20(address erc20) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 total = IERC20(erc20).balanceOf(address(this));
        IERC20(erc20).transfer(owner(), total);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}