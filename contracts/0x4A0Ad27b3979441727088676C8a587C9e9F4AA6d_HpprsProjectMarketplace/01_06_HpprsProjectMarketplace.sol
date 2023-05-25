// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HpprsProjectMarketplace is Ownable {
    address vault = 0x579D29cd3eaa87be6900c8BA16c9D9b2DD22D9Bb;
    address secret = 0x9C17E0f19f6480747436876Cee672150d39426A5;

    bool isOn = true;

    mapping(bytes => bool) isSignatureUsed;

    event Redeem (
        uint256 _purchaseId
    );

    function setWallets(
        address _vault,
        address _secret) external onlyOwner {
        vault = _vault;
        secret = _secret;
    }

    function turnOnOff(bool _isOn) external onlyOwner {
        isOn = _isOn;
    }

    function redeemERC721(
        address _nftAddress,
        uint256 _purchaseId,
        uint256 _assetId,
        uint256 _timeOut,
        bytes calldata _signature
    ) external {
        require(isOn == true, "Marketplace is disabled");
        require(_timeOut > block.timestamp, "Signature is expired");
        require(!isSignatureUsed[_signature], "Signature is already used");
        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(
                        msg.sender,
                        _nftAddress,
                        _purchaseId,
                        _assetId,
                        _timeOut
                    )
                ),
                _signature
            ),
            "Invalid signature"
        );

        isSignatureUsed[_signature] = true;

        IERC721(_nftAddress).safeTransferFrom(
            vault,
            msg.sender,
            _assetId
        );

        emit Redeem(_purchaseId);
    }

    function redeemERC1155(
        address _nftAddress,
        uint256 _purchaseId,
        uint256 _assetId,
        uint256 _timeOut,
        uint256 _amount,
        bytes calldata _signature
    ) external {
        require(isOn == true, "Marketplace is disabled");
        require(_timeOut > block.timestamp, "Signature is expired");
        require(!isSignatureUsed[_signature], "Signature is already used");
        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(
                        msg.sender,
                        _nftAddress,
                        _purchaseId,
                        _assetId,
                        _timeOut,
                        _amount
                    )
                ),
                _signature
            ),
            "Invalid signature"
        );

        isSignatureUsed[_signature] = true;

        IERC1155(_nftAddress).safeTransferFrom(
            vault,
            msg.sender,
            _assetId,
            _amount,
            ""
        );

        emit Redeem(_purchaseId);
    }

    function _verifyHashSignature(bytes32 freshHash, bytes memory signature) internal view returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}