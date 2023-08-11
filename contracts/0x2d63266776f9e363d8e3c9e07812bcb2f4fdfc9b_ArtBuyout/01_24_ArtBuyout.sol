// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./Interfaces/ICrowdsale.sol";
import "./Interfaces/IArtBuyout.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title ArtBuyout
 */
contract ArtBuyout is
    Initializable,
    Context,
    ReentrancyGuard,
    AccessControl,
    IArtBuyout
{
    using SafeERC20 for IERC20;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice the ERC20 token address of the token for buyout votes
    IERC20Upgradeable private tokenAT;
    mapping(address => uint256) private votesAT;

    /// @notice the ERC20 token address of the token for buyout proceeds
    IERC20 private tokenBT;

    uint256 private supplyAT;

    /// @notice the address of the buyer who initiated the buyout and deployed this contract
    address public buyer;

    /// @notice the amount of BT tokens to be distributed to the voters
    uint256 public amountBT;

    /// @notice the total amount of AT tokens voted for the buyout
    uint256 public totalVotesAT;

    uint256 public endTimestamp;

    /// @notice totalVotesAT should be greater than this value for the ArtBuyout to be successful
    uint256 public successVoteThreshold;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _buyer,
        IERC20Upgradeable _tokenAT,
        uint256 _endTimestamp,
        uint256 _successVoteThreshold,
        IERC20 _tokenBT,
        uint256 _amountBT
    ) external initializer {
        buyer = _buyer;
        tokenAT = _tokenAT;
        endTimestamp = _endTimestamp;
        successVoteThreshold = _successVoteThreshold;
        tokenBT = _tokenBT;
        amountBT = _amountBT;
        supplyAT = _tokenAT.totalSupply();
    }

    // -------------------  EXTERNAL, VIEW  -------------------
    function status() public view virtual returns (BuyoutStatus) {
        if (totalVotesAT > successVoteThreshold) {
            return BuyoutStatus.SUCCESSFUL;
        } else if (block.timestamp <= endTimestamp) {
            return BuyoutStatus.IN_PROGRESS;
        } else {
            return BuyoutStatus.UNSUCCESSFUL;
        }
    }

    // -------------------  INTERNAL, MUTATING  -------------------

    /// @notice collect all AT tokens from a holder and add them to the votes
    /// @param holder the owner of the AT tokens
    function _collectAllAT(address holder) internal {
        uint256 balance = tokenAT.balanceOf(holder);
        if (balance > 0) {
            votesAT[holder] = balance;
            totalVotesAT = totalVotesAT + balance;
            tokenAT.safeTransferFrom(holder, address(this), balance);
        }
    }

    // -------------------  EXTERNAL, MUTATING  -------------------
    function voteFor() external {
        require(
            block.timestamp <= endTimestamp,
            "ArtBuyout: should vote before endTimestamp"
        );
        _collectAllAT(_msgSender());
    }

    function claimBuyoutShare() external {
        require(
            status() == BuyoutStatus.SUCCESSFUL,
            "ArtBuyout: should be successful to claim"
        );
        _collectAllAT(_msgSender());
        uint256 balanceBT = (votesAT[_msgSender()] * amountBT) / supplyAT;
        votesAT[_msgSender()] = 0;
        // TODO: should we burn AT tokens here?
        tokenBT.safeTransfer(_msgSender(), balanceBT);
    }

    function refundVote() external {
        require(
            status() == BuyoutStatus.UNSUCCESSFUL,
            "ArtBuyout: should be unsuccessful to refund"
        );
        uint256 balance = votesAT[_msgSender()];
        votesAT[_msgSender()] = 0;
        tokenAT.safeTransfer(_msgSender(), balance);
    }

    function refundBuyoutAmount() external {
        require(
            status() == BuyoutStatus.UNSUCCESSFUL,
            "ArtBuyout: should be unsuccessful to refund"
        );
        require(_msgSender() == buyer, "ArtBuyout: only buyer can refund");
        uint256 balance = amountBT;
        amountBT = 0;
        tokenBT.safeTransfer(_msgSender(), balance);
    }
}