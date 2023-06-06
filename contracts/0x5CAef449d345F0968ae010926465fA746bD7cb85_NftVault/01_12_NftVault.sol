// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./interfaces/INftVault.sol";

contract NftVault is INftVault, Initializable, OwnableUpgradeable {
    address public signerAddress;
    mapping(bytes32 => bool) public isPaymentIdUsed;

    function initialize(address _signer) public initializer {
        __Ownable_init();
        changeSigner(_signer);
    }

    function changeSigner(address _signer) public onlyOwner {
        require(_signer != address(0), "Invalid signer address");
        signerAddress = _signer;
    }

    function deposit(
        bytes32 _merchantId,
        bytes32 _paymentId,
        uint256 _deadline,
        NFT[] memory _nfts,
        bytes calldata signature
    ) external {
        require(_nfts.length > 0, "No NFTs to deposit");
        require(!isPaymentIdUsed[_paymentId], "Payment ID already used");
        require(_deadline > block.timestamp, "Deposit deadline passed");

        isPaymentIdUsed[_paymentId] = true;

        bytes memory encoded_data = abi.encodePacked(
            _merchantId,
            _paymentId,
            _deadline,
            abi.encode(_nfts)
        );
        require(verifySignature(encoded_data, signature), "Invalid signature");

        uint256 count = _nfts.length;

        for (uint256 i = 0; i < count; i++) {
            IERC721Upgradeable(_nfts[i].tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _nfts[i].tokenId
            );
        }
        emit Deposit(_merchantId, _paymentId, _nfts);
    }

    function withdraw(
        bytes32 _merchantId,
        bytes32 _paymentId,
        uint256 _deadline,
        NFT[] memory _nfts,
        bytes calldata signature
    ) external {
        require(!isPaymentIdUsed[_paymentId], "Payment ID already used");
        require(_deadline > block.timestamp, "Withdrawal deadline passed");

        isPaymentIdUsed[_paymentId] = true;

        bytes memory encoded_data = abi.encodePacked(
            _merchantId,
            _paymentId,
            msg.sender,
            block.chainid,
            _deadline,
            abi.encode(_nfts)
        );
        require(verifySignature(encoded_data, signature), "Invalid signature");

        for (uint256 i = 0; i < _nfts.length; i++) {
            IERC721Upgradeable(_nfts[i].tokenAddress).transferFrom(
                address(this),
                msg.sender,
                _nfts[i].tokenId
            );
        }

        emit Withdraw(_merchantId, _paymentId, _nfts);
    }

    function verifySignature(
        bytes memory data,
        bytes calldata signature
    ) private view returns (bool) {
        bytes32 keccak = keccak256(data);
        bytes32 signedMessageHash = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak
        );

        address recoveredSigner = ECDSAUpgradeable.recover(
            signedMessageHash,
            signature
        );
        return recoveredSigner == signerAddress;
    }
}