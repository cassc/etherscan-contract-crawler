// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract OrionReferral is Initializable, OwnableUpgradeable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    mapping(address => uint256) public totalFeeAccrued;
    address public verifier;

    struct FeeOrder {
        address referrer;
        uint256 amount;
        bytes signature;
    }

    function initialize(IERC20 rewardToken_, address verifier_) public initializer {
        __Ownable_init();
        rewardToken = rewardToken_;
        verifier = verifier_;
    }

    function setVerifier(address verifier_) external onlyOwner{
        verifier = verifier_;
        emit VerifierUpdate(verifier_);
    }

    function getFee(FeeOrder calldata order) external {
        validateOrder(order);

        uint256 accruedAmount = totalFeeAccrued[order.referrer];
        require(accruedAmount < order.amount, "OrionReferral: already accrued");
        totalFeeAccrued[order.referrer] = order.amount;

        uint256 feeToTransfer;
        unchecked { feeToTransfer = order.amount - accruedAmount; }
        rewardToken.safeTransfer(order.referrer, feeToTransfer);

        emit FeeAccrued(order.referrer, feeToTransfer);
    }

    function validateOrder(FeeOrder calldata order) internal view returns (bytes32 orderHash) {
        uint256 id;
        assembly {
            id := chainid()
        }
        orderHash = keccak256(
            abi.encodePacked(
                "FeeOrder",
                order.referrer,
                order.amount,
                id
            )
        );
        require(orderHash.toEthSignedMessageHash().recover(order.signature) == verifier, "OrionReferral: invalid signature");
    }

    event FeeAccrued (
        address referrer,
        uint256 amountAccrued
    );

    event VerifierUpdate (
        address verifier
    );
}