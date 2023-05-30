// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract Redeemables is ContextUpgradeable {
    struct Redeemable {
        string tokenURI;
        uint256 price;
        uint256 maxQuantity;
        uint256 maxPerWallet;
        uint256 maxPerMint;
        uint256 redeemedCount;
        bytes32 merkleRoot;
        bool active;
        uint256 nonce;
    }

    event RedeemableCreated(uint256 indexed redeemableId);
    event TokenRedeemed(
        address indexed to,
        uint256 indexed redeemableId,
        uint256 quantity
    );

    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _redeemablesCounter;
    mapping(uint256 => Redeemable) private _redeemables;
    mapping(uint256 => mapping(address => uint256)) private _redeemedByWallet;

    function totalRedeemables() external view returns (uint256) {
        return _redeemablesCounter.current();
    }

    function redeemableAt(uint256 index)
        public
        view
        returns (Redeemable memory data)
    {
        return _redeemables[index];
    }

    function _createRedeemable(
        string memory uri,
        uint256 price,
        uint256 maxQuantity,
        uint256 maxPerWallet,
        uint256 maxPerMint
    ) internal {
        uint256 redeemableId = _redeemablesCounter.current();
        _redeemablesCounter.increment();

        _redeemables[redeemableId] = Redeemable({
            tokenURI: uri,
            price: price,
            maxQuantity: maxQuantity,
            maxPerWallet: maxPerWallet,
            maxPerMint: maxPerMint,
            redeemedCount: 0,
            merkleRoot: "",
            active: true,
            nonce: 0
        });

        emit RedeemableCreated(redeemableId);
    }

    function _redeem(
        uint256 redeemableId,
        uint256 quantity,
        bytes calldata signature,
        address signer,
        bytes32[] calldata proof
    ) internal {
        Redeemable memory redeemable = redeemableAt(redeemableId);
        require(redeemable.active, "Not active");
        require(redeemable.price.mul(quantity) <= msg.value, "Value incorrect");
        require(quantity <= redeemable.maxPerMint, "Exceeded max per mint");
        require(
            redeemable.redeemedCount.add(quantity) <= redeemable.maxQuantity,
            "Exceeded max amount"
        );
        require(
            _redeemedByWallet[redeemableId][_msgSender()].add(quantity) <=
                redeemable.maxPerWallet,
            "Exceeded max per wallet"
        );
        require(
            keccak256(abi.encodePacked(redeemableId.add(redeemable.nonce)))
                .toEthSignedMessageHash()
                .recover(signature) == signer,
            "Invalid signature"
        );
        if (redeemable.merkleRoot != "") {
            require(
                MerkleProofUpgradeable.verify(
                    proof,
                    redeemable.merkleRoot,
                    keccak256(abi.encodePacked(_msgSender()))
                ),
                "Invalid proof"
            );
        }

        unchecked {
            _redeemables[redeemableId].redeemedCount++;
            _redeemedByWallet[redeemableId][_msgSender()]++;
        }

        emit TokenRedeemed(_msgSender(), redeemableId, quantity);
    }

    function _setMerkleRoot(uint256 redeemableId, bytes32 newRoot) internal {
        require(_redeemables[redeemableId].active, "Not active");

        _redeemables[redeemableId].merkleRoot = newRoot;
    }

    function _invalidate(uint256 redeemableId) internal {
        require(_redeemables[redeemableId].active, "Not active");

        _redeemables[redeemableId].nonce = _redeemables[redeemableId].nonce.add(
            1
        );
    }

    function _revoke(uint256 redeemableId) internal {
        require(_redeemables[redeemableId].active, "Not active");

        _redeemables[redeemableId].active = false;
    }
}