// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./IChallenge.sol";

interface INFTChallenge is IChallenge{
    /**
     * @dev Returns true if this contract implements the interface defined by
     */

    struct Challenge {
        address seller;
        address collection;
        uint256 assetId;
        uint256 amount;
        uint256 airdropStartAt;
        uint256 airdropEndAt;
        ChallengeStatus status;
    }
    /**
     * @dev Emitted when `challengeId` challenge is created.
     */
    event AddChallenge(
        bytes32 challengeId,
        address indexed seller,
        address indexed collection,
        uint256 assetId,
        uint256 amount,
        uint256 airdropStartAt,
        uint256 airdropEndAt,
        uint256 indexed eventIdAddChallenge
    );
    /**
     * @dev Emitted when `challengeId` challenge is created.
     */
    event AirDropChallenge(
        bytes32 indexed challengeId,
        address indexed receiver,
        uint256 amount,
        uint256 airdropFee,
        uint256 indexed eventIdAirDropChallenge
    );
    event WithdrawChallenge(
        bytes32 indexed challengeId,
        uint256 indexed eventIdWithdrawChallenge
    );

    function addChallenge(
        address collection,
        uint256 assetId,
        uint256 amount,
        uint256 airdropStartAt,
        uint256 airdropEndAt,
        uint256 eventIdAddChallenge
    ) external;

    /**
     * @dev airdrop NFT token
     */
    function airdropChallenge(
        bytes32 challengeId,
        address receiver,
        uint256 amount,
        uint256 eventIdAirDropChallenge
    ) external returns (bool);

    function withdrawChallenge(
        bytes32 challengeId,
        uint256 eventIdWithdrawChallenge
    ) external returns (bool);
}