// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IMintableInterface, CollectionV2} from "../collection/CollectionV2.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract EscrowV2 is AccessControl {
    event Claimed(
        string profileId,
        address wallet,
        address collection,
        uint256 tokenId
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    bytes32 immutable MINTER_ROLE = bytes32(keccak256("MINTER_ROLE"));
    bytes32 immutable MATIC_MINTER_ROLE =
        bytes32(keccak256("MATIC_MINTER_ROLE"));

    bytes internal personalSignPrefix = "\x19Ethereum Signed Message:\n";

    address[] public holderWallets;

    function grantMinter(address _minter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(MINTER_ROLE, _minter);
    }

    function revokeMinter(address _minter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(MINTER_ROLE, _minter);
    }

    function setHolderWallets(address[] memory _holderWallets)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        delete holderWallets;
        for (uint32 i = 0; i < _holderWallets.length; i++) {
            holderWallets.push(_holderWallets[i]);
        }
        holderWallets = _holderWallets;
    }

    function mintToEscrow(address collectionAddr, uint256 tokenId)
        external
        onlyRole(MATIC_MINTER_ROLE)
    {
        IMintableInterface(collectionAddr).mint(address(this), tokenId);
    }

    function claim(
        address collectionAddr,
        uint256 tokenId,
        address wallet,
        string calldata profileId,
        bytes calldata signature
    ) public {
        bytes32 hash = keccak256(
            abi.encode(collectionAddr, tokenId, wallet, profileId)
        );
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(
            signature,
            (uint8, bytes32, bytes32)
        );
        address recovered = ecrecover(
            keccak256(abi.encodePacked(personalSignPrefix, "32", hash)),
            v,
            r,
            s
        );

        require(hasRole(MINTER_ROLE, recovered), "Invalid signature");
        if (transferExistingNfts(collectionAddr, tokenId, wallet, profileId)) {
            return;
        }
        IMintableInterface(collectionAddr).mint(wallet, tokenId);
        emit Claimed(profileId, wallet, collectionAddr, tokenId);
    }

    function transferExistingNfts(
        address collectionAddr,
        uint256 tokenId,
        address wallet,
        string calldata profileId
    ) internal returns (bool) {
        for (uint32 i = 0; i < holderWallets.length; i++) {
            if (
                IERC1155(collectionAddr).balanceOf(holderWallets[i], tokenId) >
                0
            ) {
                IERC1155(collectionAddr).safeTransferFrom(
                    holderWallets[i],
                    wallet,
                    tokenId,
                    1,
                    ""
                );
                emit Claimed(profileId, wallet, collectionAddr, tokenId);
                return true;
            }
        }
        return false;
    }
}