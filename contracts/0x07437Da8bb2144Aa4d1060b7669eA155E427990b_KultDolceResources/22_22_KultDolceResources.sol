// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @custom:security-contact [email protected]
contract KultDolceResources is
    ERC1155,
    Ownable,
    AccessControl,
    ERC1155Burnable,
    ERC1155Supply,
    ERC2981,
    ReentrancyGuard,
    EIP712
{
    using Counters for Counters.Counter;

    string public name;
    string public version;
    Token[] public tokens;

    struct Token {
        string name;
        uint256 maxSupply;
    }

    mapping(address => mapping(address => Counters.Counter)) private _nonces;
    bytes32 private constant _CLAIM_BATCH_TYPEHASH =
        keccak256(
            "ClaimBatch(address signer,address account,uint256[] ids,uint256[] amounts,uint256[] burnIds,uint256[] burnAmounts,uint256 nonce)"
        );

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event ClaimBatch(
        address signer,
        address account,
        uint256[] ids,
        uint256[] amounts,
        uint256[] burnIds,
        uint256[] burnAmounts,
        uint256 nonce
    );

    constructor(
        string memory name_,
        string memory version_,
        string memory uri_
    ) ERC1155(uri_) EIP712(name_, version_) {
        name = name_;
        version = version_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function _withinSupply(
        uint256 tokenId,
        uint256 quantity
    ) internal view returns (bool isWithinSupply) {
        isWithinSupply =
            tokens[tokenId].maxSupply == 0 ||
            totalSupply(tokenId) + quantity <= tokens[tokenId].maxSupply;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setTokens(Token[] memory _tokens) public onlyOwner {
        delete tokens;
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokens.push(_tokens[i]);
        }
    }

    function tokenCount() external view returns (uint256 _tokenCount) {
        _tokenCount = tokens.length;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        require(_withinSupply(id, amount), "AMOUNT_EXCEED_MAX_SUPPLY");
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                _withinSupply(ids[i], amounts[i]),
                "AMOUNT_EXCEED_MAX_SUPPLY"
            );
        }
        _mintBatch(to, ids, amounts, data);
    }

    // Claim functions

    function claimBatch(
        address signer,
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory burnIds,
        uint256[] memory burnAmounts,
        bytes memory data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public nonReentrant {
        require(hasRole(MINTER_ROLE, signer), "MINTER_NOT_ALLOWED");

        uint256 nonce = _useNonce(signer, account);

        bytes32 structHash = keccak256(
            abi.encode(
                _CLAIM_BATCH_TYPEHASH,
                signer,
                account,
                keccak256(abi.encodePacked(ids)),
                keccak256(abi.encodePacked(amounts)),
                keccak256(abi.encodePacked(burnIds)),
                keccak256(abi.encodePacked(burnAmounts)),
                nonce
            )
        );

        bytes32 typedHash = _hashTypedDataV4(structHash);

        address recoveredSigner = ECDSA.recover(typedHash, v, r, s);
        require(recoveredSigner == signer, "INVALID_SIGNATURE");

        for (uint256 i = 0; i < ids.length; i++) {
            require(
                _withinSupply(ids[i], amounts[i]),
                "AMOUNT_EXCEED_MAX_SUPPLY"
            );
        }

        _mintBatch(account, ids, amounts, data);
        _burnBatch(account, burnIds, burnAmounts);

        emit ClaimBatch(
            signer,
            account,
            ids,
            amounts,
            burnIds,
            burnAmounts,
            nonce
        );
    }

    function nonces(
        address signer,
        address account
    ) public view returns (uint256) {
        return _nonces[signer][account].current();
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     */
    function _useNonce(
        address signer,
        address account
    ) internal returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[signer][account];
        current = nonce.current();
        nonce.increment();
    }

    // Royalty functions

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) public onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}