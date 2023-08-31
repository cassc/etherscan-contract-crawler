// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/ISignatureMintERC721.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

abstract contract SignatureMint is Initializable, EIP712Upgradeable, ISignatureMintERC721 {
    using ECDSAUpgradeable for bytes32;

    mapping(address => uint256) public nonces;
    mapping(address => uint256) public minted;

    bytes32 private constant TYPEHASH =
        keccak256(
            "MintRequest(address userAddress,uint256 mintNumber,uint256 nftPrice,address paymentToken,uint128 validityStartTimestamp,uint128 validityEndTimestamp,uint256 totalSupply,uint256 nonce)"
        );

    mapping(bytes => bool) private invalid;

    function __SignatureMintERC721_init() internal onlyInitializing {
        __EIP712_init("SignatureMintERC721", "1");
    }

    function __SignatureMintERC721_init_unchained() internal onlyInitializing {}

    function verify(MintRequest calldata _req, bytes calldata _signature)
        public
        view
        override
        returns (bool success, address signer)
    {
        signer = _recoverAddress(_req, _signature);

        success = !invalid[_signature]&&_isAuthorizedSigner(signer);
    }

    function _isAuthorizedSigner(address _signer) internal view virtual returns (bool);


    function _processRequest(MintRequest calldata _req, bytes calldata _signature) internal returns (address signer) {
        bool success;
        (success, signer) = verify(_req, _signature);

        if (!success) {
            revert("Invalid req");
        }

        if (_req.validityStartTimestamp > block.timestamp || block.timestamp > _req.validityEndTimestamp) {
            revert("Req StartTime or EndTimestamp expired");
        }

        require(_req.userAddress != address(0), "recipient undefined");
        require(_req.mintNumber > 0, "0 mintNumber is invalid"); 
        
        invalid[_signature] = true;
        nonces[_req.userAddress] += 1;
        minted[_req.userAddress] += _req.mintNumber;
    }

    function _recoverAddress(MintRequest calldata _req, bytes calldata _signature) internal view returns (address) {

        bytes32 structHash = keccak256(_encodeRequest(_req, nonces[_req.userAddress]));

        return _hashTypedDataV4(structHash).recover(_signature);
    }

    function _encodeRequest(MintRequest calldata _req, uint256 nonce) internal pure returns (bytes memory) {
        return
            abi.encode(
                TYPEHASH,
                _req.userAddress,
                _req.mintNumber,
                _req.nftPrice,
                _req.paymentToken,
                _req.validityStartTimestamp,
                _req.validityEndTimestamp,
                _req.totalSupply,
                nonce
            );
    }
}