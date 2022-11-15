// SPDX-License-Identifier: MIT
// Creator: promos.wtf

pragma solidity ^0.8.0;

import "@promos/contracts/IPromos.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract PromosMint is Ownable {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    event Mint(
        address indexed collection,
        address indexed owner,
        address indexed referrer,
        uint256 amount,
        string campaign,
        uint256 gained,
        uint256 spent,
        uint256 reward
    );

    struct MintRequest {
        uint256 nonce;
        uint256 price;
        uint256 amount;
        address referralAddress;
        address collectionAddress;
        address tokensOwnerAddress;
        uint256 systemRewardPercent;
        uint256 referralRewardPercent;
        string campaign;
        bool isTransferToCollection;
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

    function verify(MintRequest memory mintRequest, bytes memory signature)
        public
        view
        returns (bool)
    {
        return
            keccak256(
                abi.encodePacked(
                    mintRequest.nonce,
                    mintRequest.price,
                    mintRequest.amount,
                    mintRequest.referralAddress,
                    mintRequest.collectionAddress,
                    mintRequest.tokensOwnerAddress,
                    mintRequest.systemRewardPercent,
                    mintRequest.referralRewardPercent,
                    mintRequest.campaign,
                    mintRequest.isTransferToCollection
                )
            ).toEthSignedMessageHash().recover(signature) == signer;
    }

    function mint(MintRequest calldata mintRequest, bytes calldata signature)
        external
        payable
    {
        uint256 totalPrice = mintRequest.price.mul(mintRequest.amount);
        require(
            block.timestamp.sub(mintRequest.nonce) <= interval,
            "Signature is stale"
        );
        require(totalPrice != 0, "Total price cannot be zero");
        require(msg.value >= totalPrice, "Not enough ETH");
        require(msg.value >= minPrice, "Not enough Ether sent");
        require(verify(mintRequest, signature), "Invalid request");

        IPromos(mintRequest.collectionAddress).mintPromos(
            msg.sender,
            mintRequest.amount
        );

        uint256 percent = msg.value.div(10000);
        uint256 systemReward = percent.mul(mintRequest.systemRewardPercent);
        uint256 referralReward = percent.mul(mintRequest.referralRewardPercent);
        uint256 spent = systemReward.add(referralReward);
        uint256 ownerReward = msg.value.sub(spent);

        if (referralReward != 0) {
            (bool referralPaymentSuccess, ) = mintRequest.referralAddress.call{
                value: referralReward
            }("");
            require(referralPaymentSuccess, "Failed to send Ether to referral");
        }

        if (ownerReward != 0) {
            if (mintRequest.isTransferToCollection) {
                (bool _sucess, ) = mintRequest.collectionAddress.call{
                    value: ownerReward
                }("");
                require(_sucess, "Failed to send Ether to collection contract");
            } else {
                (bool _sucess, ) = mintRequest.tokensOwnerAddress.call{
                    value: ownerReward
                }("");
                require(_sucess, "Failed to send Ether to owner");
            }
        }

        emit Mint(
            mintRequest.collectionAddress,
            mintRequest.tokensOwnerAddress,
            mintRequest.referralAddress,
            mintRequest.amount,
            mintRequest.campaign,
            ownerReward,
            spent,
            referralReward
        );
    }

    function withdraw(address _to, uint256 _amount) external onlyOwner {
        payable(_to).transfer(_amount);
    }
}