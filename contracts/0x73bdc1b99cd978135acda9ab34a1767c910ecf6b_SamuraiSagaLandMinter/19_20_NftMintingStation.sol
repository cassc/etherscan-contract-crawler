// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/INftCollection.sol";
import "./AuthorizeAccess.sol";
import "./OperatorAccess.sol";

/** @title NftMintingStation.
 */
contract NftMintingStation is AuthorizeAccess, OperatorAccess, EIP712 {
    using Address for address;
    using ECDSA for bytes32;

    uint256 public maxSupply;
    uint256 public availableSupply;

    INftCollection public nftCollection;

    // modifier to allow execution by owner or operator
    modifier onlyOwnerOrOperator() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(OPERATOR_ROLE, _msgSender()),
            "Not an owner or operator"
        );
        _;
    }

    modifier whenValidQuantity(uint256 quantity) {
        require(availableSupply > 0, "No more supply");
        require(availableSupply >= quantity, "Not enough supply");
        require(quantity > 0, "Qty <= 0");
        _;
    }

    constructor(
        INftCollection nftCollection_,
        string memory eipName_,
        string memory eipVersion_
    ) EIP712(eipName_, eipVersion_) {
        nftCollection = nftCollection_;
    }

    function getNextTokenId() internal virtual returns (uint256) {
        return maxSupply - availableSupply + 1;
    }

    function _mint(address to, uint256 quantity) internal returns (uint256[] memory) {
        require(availableSupply >= quantity, "Not enough supply");

        uint256[] memory tokenIds = new uint256[](quantity);

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = getNextTokenId();
            availableSupply = availableSupply - 1;
            tokenIds[i] = tokenId;
        }

        if (quantity == 1) {
            nftCollection.mint(to, tokenIds[0]);
        } else {
            nftCollection.mintBatch(to, tokenIds);
        }

        return tokenIds;
    }

    function _syncSupply() internal {
        uint256 totalSupply = nftCollection.totalSupply();
        maxSupply = nftCollection.maxSupply();
        availableSupply = maxSupply - totalSupply;
    }

    function syncSupply() external onlyOwnerOrOperator {
        _syncSupply();
    }

    /**
     * @notice verifify signature is valid for `structHash` and signers is a member of role `AUTHORIZER_ROLE`
     * @param structHash: hash of the structure to verify the signature against
     */
    function isAuthorized(bytes32 structHash, bytes memory signature) internal view returns (bool) {
        bytes32 hash = _hashTypedDataV4(structHash);
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && hasRole(AUTHORIZER_ROLE, recovered)) {
            return true;
        }

        return false;
    }
}