// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import "forge-std/console.sol";

contract PaperHandsClaim {
    address public paperhandsContractAddress =
        0x863846e7ed0D21824104b425672Af7b9C6097F8f;
    address public paperhandsWalletAddress =
        0x3cf5ff236aeb83f959313CbD0050af41174C4F5D;
    address public signer = 0xecF05De8fEfbC149a198d4c18ca9707f7EF728b8;

    mapping(address => bool) private isAdmin;

    error Unauthorized();

    constructor() {
        isAdmin[msg.sender] = true;
    }

    modifier adminRequired() {
        if (!isAdmin[msg.sender]) revert Unauthorized();
        _;
    }

    function allowedToClaim(
        uint256 _tokenId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        return (signer ==
            ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        keccak256(
                            abi.encodePacked(
                                msg.sender,
                                _tokenId,
                                paperhandsContractAddress,
                                paperhandsWalletAddress
                            )
                        )
                    )
                ),
                v,
                r,
                s
            ));
    }

    function setPaperHandsContractAddress(
        address _address
    ) external adminRequired {
        paperhandsContractAddress = _address;
    }

    function setPaperHandsWalletAddress(
        address _address
    ) external adminRequired {
        paperhandsWalletAddress = _address;
    }

    function setSignerAddress(address _address) external adminRequired {
        signer = _address;
    }

    function toggleAdmin(address _admin) external adminRequired {
        isAdmin[_admin] = !isAdmin[_admin];
    }

    function claim(uint256 _tokenId, uint8 v, bytes32 r, bytes32 s) external {
        if (!allowedToClaim(_tokenId, v, r, s)) revert Unauthorized();
        ERC721(paperhandsContractAddress).safeTransferFrom(
            paperhandsWalletAddress,
            msg.sender,
            _tokenId
        );
    }
}