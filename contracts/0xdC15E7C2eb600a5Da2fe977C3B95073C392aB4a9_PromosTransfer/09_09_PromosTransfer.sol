//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract PromosTransfer is Ownable {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    event PromosTransferStatistics(
        address indexed collection,
        address indexed owner,
        address indexed referrer,
        uint256[] tokens,
        string campaign,
        uint256 gained,
        uint256 spent,
        uint256 reward
    );

    struct TransferRequest {
        uint256 nonce;
        uint256 price;
        uint256[] tokenIds;
        address referralAddress;
        address collectionAddress;
        address tokensOwnerAddress;
        uint256 systemRewardPercent;
        uint256 referralRewardPercent;
        string campaign;
    }

    address public signer;
    uint256 public interval = 5 minutes;
    uint256 private minPrice = 0.001 ether;

    function setInterval(uint256 _interval) external onlyOwner {
        interval = _interval;
    }

    function setSigner(address signerAddress) external onlyOwner {
        signer = signerAddress;
    }

    function verify(
        TransferRequest memory transferRequest,
        bytes memory signature
    ) public view returns (bool) {
        return
            keccak256(
                abi.encodePacked(
                    transferRequest.nonce,
                    transferRequest.price,
                    transferRequest.tokenIds,
                    transferRequest.referralAddress,
                    transferRequest.collectionAddress,
                    transferRequest.tokensOwnerAddress,
                    transferRequest.systemRewardPercent,
                    transferRequest.referralRewardPercent,
                    transferRequest.campaign
                )
            ).toEthSignedMessageHash().recover(signature) == signer;
    }

    function promosTransfer(
        TransferRequest calldata transferRequest,
        bytes calldata signature
    ) external payable {
        uint256 totalPrice = transferRequest.price.mul(
            transferRequest.tokenIds.length
        );
        require(
            block.timestamp.sub(transferRequest.nonce) <= interval,
            "Signature is stale"
        );
        require(totalPrice != 0, "Total price cannot be zero");
        require(msg.value >= totalPrice, "Not enough ETH");
        require(msg.value >= minPrice, "Not enough Ether sent");
        require(verify(transferRequest, signature), "Invalid request");

        for (uint256 i; i < transferRequest.tokenIds.length; i++) {
            IERC721(transferRequest.collectionAddress).safeTransferFrom(
                transferRequest.tokensOwnerAddress,
                msg.sender,
                transferRequest.tokenIds[i]
            );
        }

        uint256 percent = msg.value.div(10000);
        uint256 systemReward = percent.mul(transferRequest.systemRewardPercent);
        uint256 referralReward = percent.mul(
            transferRequest.referralRewardPercent
        );
        uint256 spent = systemReward.add(referralReward);
        uint256 ownerReward = msg.value.sub(spent);

        if (referralReward != 0) {
            (bool referralPaymentSuccess, ) = transferRequest
                .referralAddress
                .call{value: referralReward}("");
            require(referralPaymentSuccess, "Failed to send Ether to referral");
        }

        if (ownerReward != 0) {
            (bool ownerPaymentSuccess, ) = transferRequest
                .tokensOwnerAddress
                .call{value: ownerReward}("");
            require(ownerPaymentSuccess, "Failed to send Ether to owner");
        }

        emit PromosTransferStatistics(
            transferRequest.collectionAddress,
            transferRequest.tokensOwnerAddress,
            transferRequest.referralAddress,
            transferRequest.tokenIds,
            transferRequest.campaign,
            ownerReward,
            spent,
            referralReward
        );
    }
}