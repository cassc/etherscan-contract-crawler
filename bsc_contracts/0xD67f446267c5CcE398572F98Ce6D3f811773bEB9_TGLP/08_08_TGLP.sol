// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TGLP is Ownable {
    using SafeERC20 for IERC20;

    struct Offer {
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 price;
        uint256 seatsSold;
        uint256 seatsAvailable;
    }

    IERC20 public token;

    /// @dev merkle tree root hash
    bytes32 public rootHash;

    Offer public extensionOffer;

    mapping(address => uint256) public subscriptionExtendedAt;

    event SubscriptionExtended(address indexed owner, uint256 price, uint256 timestamp);

    modifier onlyWhitelisted(bytes32[] calldata proof) {
        bytes32 leaf = keccak256(abi.encode(_msgSender()));
        require(MerkleProof.verify(proof, rootHash, leaf), "Sender is not whitelisted");
        _;
    }

    receive() external payable {}

    /* Configuration
     ****************************************************************/

    /**
     * @param startTimestamp A start timestamp of the offer.
     * @param endTimestamp A end timestamp of the offer. When the value is 0 the offer has no time limit.
     * @param price A subscription extension price in ethers.
     * @param seatsAvailable A maximum number of extensions. When the value is 0 the offer has no seats limit.
     */
    function scheduleExtensionOffer(
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 price,
        uint256 seatsAvailable
    ) external onlyOwner {
        require(endTimestamp != 0 || seatsAvailable != 0, "Unlimited extension offer");

        extensionOffer = Offer({
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            price: price,
            seatsAvailable: seatsAvailable,
            seatsSold: 0
        });
    }

    function setToken(address token_) external onlyOwner {
        token = IERC20(token_);
    }

    function setRootHash(bytes32 rootHash_) external onlyOwner {
        rootHash = rootHash_;
    }

    /* Domain
     ****************************************************************/

    function extend(bytes32[] calldata proof) external onlyWhitelisted(proof) {
        require(extensionOffer.startTimestamp != 0, "Offer not started");

        require(subscriptionExtendedAt[_msgSender()] == 0, "Subscription already extended");

        bool isInTimeframe = block.timestamp >= extensionOffer.startTimestamp &&
            (extensionOffer.endTimestamp == 0 || block.timestamp <= extensionOffer.endTimestamp);

        require(isInTimeframe, "Outside the timeframe");

        require(extensionOffer.seatsAvailable == 0 || extensionOffer.seatsSold < extensionOffer.seatsAvailable, "Out of seats");

        extensionOffer.seatsSold++;

        require(token.transferFrom(_msgSender(), address(this), extensionOffer.price), "Token transfer failed");

        subscriptionExtendedAt[_msgSender()] = block.timestamp;

        emit SubscriptionExtended(_msgSender(), extensionOffer.price, block.timestamp);
    }

    /* Utils
     ****************************************************************/

    function withdrawToken(address to, address token_) external onlyOwner {
        IERC20 tokenToWithdraw = IERC20(token_);
        tokenToWithdraw.safeTransfer(to, tokenToWithdraw.balanceOf(address(this)));
    }

    function withdrawETH(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }
}