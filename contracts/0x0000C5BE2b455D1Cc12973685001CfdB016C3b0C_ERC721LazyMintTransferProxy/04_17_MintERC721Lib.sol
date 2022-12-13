// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC721LazyMint.sol";
import "./SecurityLib.sol";
import "./SignatureLib.sol";

library MintERC721Lib {
    bytes4 constant _INTERFACE_ID_LAZY_MINT = type(IERC721LazyMint).interfaceId;

    struct MintERC721Data {
        SecurityLib.SecurityData securityData;
        address minter;
        address to;
        uint256 tokenId;
        bytes data;
    }

    bytes32 private constant _MINT_ERC721_TYPEHASH =
        keccak256(
            bytes(
                "MintERC721Data(SecurityData securityData,address minter,address to,uint256 tokenId,bytes data)SecurityData(uint256 validFrom,uint256 validTo,uint256 salt)"
            )
        );

    function validate(MintERC721Data memory mintERC721Data)
        internal
        view
        returns (bool, string memory)
    {
        address minter = address(uint160(mintERC721Data.tokenId >> 96));
        if (minter != mintERC721Data.minter) {
            return (false, "MintERC721Lib: valid tokenId verification failed");
        }
        (
            bool isSecurityDataValid,
            string memory securityDataErrorMessage
        ) = SecurityLib.validate(mintERC721Data.securityData);
        if (!isSecurityDataValid) {
            return (false, securityDataErrorMessage);
        }
        return (true, "");
    }

    function hash(MintERC721Data memory mintERC721Data)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _MINT_ERC721_TYPEHASH,
                    SecurityLib.hash(mintERC721Data.securityData),
                    mintERC721Data.minter,
                    mintERC721Data.to,
                    mintERC721Data.tokenId,
                    keccak256(mintERC721Data.data)
                )
            );
    }
}