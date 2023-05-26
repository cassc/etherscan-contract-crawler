// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract IDODistributor is Ownable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    struct Order {
        address sender;
        address receiver;
        address asset;
        uint192 amount;
        uint64 startTime;
        bytes signature;
    }

    event NewTokenDistribution(
        uint256 amount
    );

    event TokensClaimed(
        address receiver,
        uint192 amount,
        bytes32 orderHash
    );

    address public idoToken;
    address public verifier;

    mapping(bytes32 => bool) public claimedOrders;

    constructor(address idoToken_, address verifier_) {
        idoToken = idoToken_;
        verifier = verifier_;
    }

    function updateParams(address idoToken_, address verifier_) external onlyOwner {
        idoToken = idoToken_;
        verifier = verifier_;
    }

    function distibuteNewTokens(uint256 amount) external onlyOwner {
        IERC20(idoToken).safeTransferFrom(msg.sender, address(this), uint256(amount));
        emit NewTokenDistribution(amount);
    }

    function claimTokens(Order calldata order_) public {
        bytes32 orderHash = validateOrder(order_, block.timestamp);
        require(order_.sender == verifier, "INVALID_VERIFIER");
        require(!claimedOrders[orderHash], "ALREADY_CLAIMED");
        claimedOrders[orderHash] = true;
        IERC20(idoToken).safeTransfer(order_.receiver, order_.amount);

        emit TokensClaimed(order_.receiver, order_.amount, orderHash);
    }

    function emergencyAssetWithdrawal(address asset) external onlyOwner {
        IERC20 token = IERC20(asset);
        token.safeTransfer(Ownable.owner(), token.balanceOf(address(this)));
    }

    function getOrderHash(Order calldata order_) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "distributionOrder",
                    order_.sender,
                    order_.receiver,
                    order_.asset,
                    order_.amount,
                    order_.startTime
                )
            );
    }

    function validateOrder(Order calldata order_, uint currentTime) internal pure returns (bytes32 orderHash) {
        orderHash = getOrderHash(order_);
        require(orderHash.toEthSignedMessageHash().recover(order_.signature) == order_.sender, "INVALID_SIG");
        require(uint(order_.startTime) <= currentTime, "NOT_YET_ALLOWED");
    }

}