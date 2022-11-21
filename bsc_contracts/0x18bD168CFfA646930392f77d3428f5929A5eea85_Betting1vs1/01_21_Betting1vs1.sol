// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./libs/LibBet.sol";
import "./libs/LibMatch.sol";
import "./libs/LibReward.sol";

contract Betting1vs1 is
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    using LibBet for LibBet.Bet;
    using LibMatch for LibMatch.Match;
    using LibReward for LibReward.Reward;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(bytes32 => bool) public bets;
    mapping(bytes32 => bool) public rewards;
    mapping(address => uint256) public commissions;

    event Bets(bool indexed withOdds, LibBet.Bet leftBet, LibBet.Bet rightBet);
    event RewardClaimed(LibReward.Reward reward);
    event CommissionWithdrawal(
        LibTokenAsset.TokenAsset asset,
        address indexed to
    );

    function init() external initializer {
        __Ownable_init();
        __Pausable_init();
    }

    function makeBets(
        bool withOdds,
        LibBet.Bet calldata leftBet,
        LibBet.Bet calldata rightBet,
        bytes calldata leftBetSignature,
        LibMatch.Match calldata _match,
        bytes calldata matchSignature
    ) external whenNotPaused {
        require(rightBet.bettor == msg.sender, "Right bettor must be caller");
        require(
            _match.startTimestamp > block.timestamp,
            "Match is not available for betting"
        );
        require(isBetDataValid(leftBet, _match), "Left bet data is not valid");
        require(
            isBetDataValid(rightBet, _match),
            "Right bet data is not valid"
        );
        require(
            leftBet.bettor != rightBet.bettor,
            "Left and right bettors must not be the same address"
        );
        require(
            leftBet.betOn != rightBet.betOn,
            "Left and right bettors bets on same result"
        );

        if (withOdds) {
            require(
                isBetsOddsValid(leftBet, rightBet, _match),
                "Bets odds or tokens amount is not valid"
            );
        } else {
            require(
                leftBet.asset.amount == rightBet.asset.amount,
                "Token amount in bets without odds must be the same"
            );
        }

        require(!bets[leftBet.hash()], "Left bet has already been made");
        require(!bets[rightBet.hash()], "Right bet has already been made");
        require(
            isSignatureValid(leftBet.hash(), leftBetSignature, leftBet.bettor),
            "Left bet signature is not valid"
        );
        require(
            isSignatureValid(_match.hash(), matchSignature, owner()),
            "Match signature is not valid"
        );

        bets[leftBet.hash()] = true;
        bets[rightBet.hash()] = true;

        IERC20Upgradeable leftToken = IERC20Upgradeable(leftBet.asset.token);
        IERC20Upgradeable rightToken = IERC20Upgradeable(rightBet.asset.token);

        leftToken.safeTransferFrom(
            leftBet.bettor,
            address(this),
            leftBet.asset.amount
        );
        rightToken.safeTransferFrom(
            rightBet.bettor,
            address(this),
            rightBet.asset.amount
        );

        emit Bets(withOdds, leftBet, rightBet);
    }

    function claimReward(
        LibReward.Reward calldata reward,
        bytes calldata signature
    ) external whenNotPaused {
        require(!rewards[reward.hash()], "Reward has already been claimed");
        require(
            isSignatureValid(reward.hash(), signature, owner()),
            "Signature is not valid"
        );

        rewards[reward.hash()] = true;
        commissions[reward.asset.token] += reward.commission;

        IERC20Upgradeable(reward.asset.token).safeTransfer(
            reward.recipient,
            reward.asset.amount - reward.commission
        );

        emit RewardClaimed(reward);
    }

    function withdrawCommission(
        LibTokenAsset.TokenAsset calldata asset,
        address to
    ) external onlyOwner whenNotPaused {
        require(
            asset.amount <= commissions[asset.token],
            "Insufficient amount of token in contract"
        );

        commissions[asset.token] -= asset.amount;

        IERC20Upgradeable(asset.token).safeTransfer(to, asset.amount);

        emit CommissionWithdrawal(asset, to);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function getRewardHash(LibReward.Reward calldata reward)
        external
        pure
        returns (bytes32)
    {
        return reward.hash();
    }

    function getBetHash(LibBet.Bet calldata bet)
        external
        pure
        returns (bytes32)
    {
        return bet.hash();
    }

    function getMatchHash(LibMatch.Match calldata _match)
        external
        pure
        returns (bytes32)
    {
        return _match.hash();
    }

    function isBetDataValid(
        LibBet.Bet calldata bet,
        LibMatch.Match calldata _match
    ) internal pure returns (bool) {
        return bet.matchId == _match.id && bet.matchTypeId == _match.typeId;
    }

    function isBetsOddsValid(
        LibBet.Bet calldata leftBet,
        LibBet.Bet calldata rightBet,
        LibMatch.Match calldata _match
    ) internal pure returns (bool) {
        LibBet.Bet calldata leftOddsBet;
        LibBet.Bet calldata rightOddsBet;
        if (leftBet.betOn == LibBet.EventResult.LEFT) {
            leftOddsBet = leftBet;
            rightOddsBet = rightBet;
        } else {
            leftOddsBet = rightBet;
            rightOddsBet = leftBet;
        }

        uint256 leftReward = (leftOddsBet.asset.amount *
            _match.leftOdds.value) - leftOddsBet.asset.amount * 100;
        uint256 rightReward = (rightOddsBet.asset.amount *
            _match.rightOdds.value) - rightOddsBet.asset.amount * 100;

        return
            rightOddsBet.asset.amount * 100 == leftReward &&
            leftOddsBet.asset.amount * 100 == rightReward;
    }

    function isSignatureValid(
        bytes32 dataHash,
        bytes calldata signature,
        address signer
    ) internal pure returns (bool) {
        return dataHash.toEthSignedMessageHash().recover(signature) == signer;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    uint256[50] private __gap;
}