// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./IChallenge.sol";

interface IERC20Challenge is IChallenge {

    event BulkAirdrop(
        address owner,
        address indexed collection,
        uint256 nftId,
        address[] recipient
    );

    struct TokenChallenge {
        address seller;
        address token;
        uint256 winnerCount;
        uint256 tokenAmount;
        uint256 airdropStartAt;
        uint256 airdropEndAt;
        uint256 airdropFee;
        ChallengeStatus status;
    }

    event AddTokenChallenge(
        bytes32 challengeId,
        address indexed seller,
        address indexed token,
        uint256 winnerCount,
        uint256 tokenAmount,
        uint256 airdropStartAt,
        uint256 airdropEndAt,
        uint256 tokenAirdropFee,
        uint256 indexed eventIdAddTokenChallenge
    );

    function addTokenChallenge(
        address token,
        uint256 winnerCount,
        uint256 tokenAmount,
        uint256 airdropStartAt,
        uint256 airdropEndAt,
        uint256 eventIdAddTokenChallenge
    ) external returns (bytes32);

    event AirDropTokenChallenge(
        bytes32 indexed challengeId,
        address indexed receiver,
        uint256 tokenAmount,
        uint256 airdropFee,
        uint256 indexed eventIdAirDropTokenChallenge
    );

    function airdropTokenChallenge(
        bytes32 challengeId,
        address receiver,
        uint256 eventIdAirDropTokenChallenge
    ) external returns (bool);

    event WithdrawTokenChallenge(
        bytes32 indexed challengeId,
        uint256 indexed eventIdWithdrawTokenChallenge
    );

    function withdrawTokenChallenge(
        bytes32 challengeId,
        uint256 eventIdWithdrawTokenChallenge
    ) external returns (bool);
}