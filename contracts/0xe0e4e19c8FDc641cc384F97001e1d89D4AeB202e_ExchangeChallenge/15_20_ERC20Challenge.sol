// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @dev contract to manage NFT challenges
 */
import "./Challenge.sol";
import "./interfaces/IERC20Challenge.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract ERC20Challenge is Ownable, Challenge, IERC20Challenge {
    using Counters for Counters.Counter;
    Counters.Counter private _challengeIdCounter;
    mapping(bytes32 => TokenChallenge) public tokenChallenges; // marketplace challenges

    /**
     * @dev Save new token challenge
     * @param token ERC20 contract address
     * @param winnerCount Max number of winner to airdrop
     * @param tokenAmount the amount in token per airdrop
     * @param airdropStartAt airdrop start date
     * @param airdropEndAt airdrop start date
     * @param eventIdAddTokenChallenge a tracking id used to sync db
     */
    function addTokenChallenge(
        address token,
        uint256 winnerCount,
        uint256 tokenAmount,
        uint256 airdropStartAt,
        uint256 airdropEndAt,
        uint256 eventIdAddTokenChallenge
    ) external override returns (bytes32) {
        require(
            token != address(0),
            "Challenge Exchange: Token address not valid"
        );
        require(winnerCount > 0, "Winner count must be upper to 0");
        IERC20 challengeToken = IERC20(token);
        uint256 tokenAirdropFee = _getTokenAirdropFee(token, tokenAmount);
        uint256 escrowAmountAndFee = _getEscrowAmount(
            tokenAirdropFee,
            tokenAmount,
            winnerCount
        );
        require(
            challengeToken.balanceOf(_msgSender()) >= escrowAmountAndFee,
            "Challenge Exchange: Insufficient balance"
        );
        require(
            airdropStartAt > block.timestamp,
            "Challenge Exchange: invalid start at airdrop"
        );
        require(
            airdropEndAt > airdropStartAt,
            "Challenge Exchange: invalid end at airdrop"
        );

        _challengeIdCounter.increment();
        bytes32 challengeId = keccak256(
            abi.encodePacked(
                block.timestamp,
                msg.sender,
                _challengeIdCounter.current()
            )
        );
        tokenChallenges[challengeId] = TokenChallenge(
            _msgSender(),
            token,
            winnerCount,
            tokenAmount,
            airdropStartAt,
            airdropEndAt,
            tokenAirdropFee,
            ChallengeStatus.CREATED
        );

        emit AddTokenChallenge(
            challengeId,
            _msgSender(),
            token,
            winnerCount,
            tokenAmount,
            airdropStartAt,
            airdropEndAt,
            tokenAirdropFee,
            eventIdAddTokenChallenge
        );

        uint256 previousBalance = challengeToken.balanceOf(address(this));
        SafeERC20.safeTransferFrom(
            challengeToken,
            _msgSender(),
            address(this),
            escrowAmountAndFee
        );
        require((challengeToken.balanceOf(address(this)) - previousBalance) == escrowAmountAndFee, "Challenge Exchange: token transfer is not succeeded") ;
        return challengeId;
    }

    function airdropTokenChallenge(
        bytes32 challengeId,
        address receiver,
        uint256 eventIdAirDropTokenChallenge
    ) external override returns (bool) {
        require(
            receiver != address(0),
            "Challenge Exchange: Receiver address not valid"
        );

        TokenChallenge memory challenge = tokenChallenges[challengeId];
        require(
            challenge.seller == _msgSender(),
            "Challenge Exchange: caller not an owner"
        );
        require(challenge.winnerCount > 0, "Challenge Exchange: Airdrop done");
        require(
            block.timestamp >= challenge.airdropStartAt,
            "Challenge Exchange: invalid start at airdrop"
        );

        IERC20 challengeToken = IERC20(challenge.token);
        challenge.winnerCount = challenge.winnerCount - 1;
        challenge.status = ChallengeStatus.IN_AIRDROP;

        tokenChallenges[challengeId] = challenge;

        SafeERC20.safeTransfer(challengeToken, owner(), challenge.airdropFee);

        SafeERC20.safeTransfer(challengeToken, receiver, challenge.tokenAmount);

        emit AirDropTokenChallenge(
            challengeId,
            receiver,
            challenge.tokenAmount,
            challenge.airdropFee,
            eventIdAirDropTokenChallenge
        );
        return true;
    }

    function withdrawTokenChallenge(
        bytes32 challengeId,
        uint256 eventIdWithdrawTokenChallenge
    ) external override returns (bool) {
        TokenChallenge memory challenge = tokenChallenges[challengeId];
        require(
            challenge.seller == _msgSender(),
            "Challenge Exchange: caller not an owner"
        );
        require(
            challenge.airdropEndAt < block.timestamp,
            "Challenge exchange: airdrop not ended"
        );

        require(
            challenge.status == ChallengeStatus.CREATED ||
                challenge.status == ChallengeStatus.IN_AIRDROP,
            "Challenge exchange: challenge not withdrawable"
        );

        require(
            challenge.winnerCount > 0,
            "Challenge Exchange: No token left."
        );
        challenge.status = ChallengeStatus.WITHDRAWN;
        tokenChallenges[challengeId] = challenge;
        
        SafeERC20.safeTransfer(
            IERC20(challenge.token),
            _msgSender(),
            _getEscrowAmount(
                challenge.airdropFee,
                challenge.tokenAmount,
                challenge.winnerCount
            )
        );

        emit WithdrawTokenChallenge(challengeId, eventIdWithdrawTokenChallenge);
        return true;
    }

    function _getTokenAirdropFee(address token, uint256 amount)
        internal
        view
        returns (uint256)
    {
        uint256 airdropFeePercent = _getAirdropFeePercent(token);

        return (airdropFeePercent * amount) / (10000);
    }

    function _getEscrowAmount(
        uint256 airdropFee,
        uint256 tokenAmount,
        uint256 winnerCount
    ) internal pure returns (uint256) {
        return winnerCount * (tokenAmount + airdropFee);
    }
}