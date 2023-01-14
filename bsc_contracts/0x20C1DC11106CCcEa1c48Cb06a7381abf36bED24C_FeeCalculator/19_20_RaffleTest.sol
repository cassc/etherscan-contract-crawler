// This contract is made only for testing Raffle contract, it extends it with the event needed to properly setup the test environment!
import "../Raffle.sol";

contract AndleDustRaffleTest is AngelDustRaffle {
    constructor(
        address _vrfCoordinator,
        address _linkToken,
        uint256 _fee,
        bytes32 _keyHash,
        address _feeCalculator
    ) AngelDustRaffle(_vrfCoordinator, _linkToken, _fee, _keyHash, _feeCalculator) {}

    event RequestID(bytes32 id);

    function chooseWinner(uint256 _raffleId) internal override {
        // Request a random number from Chainlink
        require(
            LINK.balanceOf(address(this)) > fee,
            "Not enough LINK, notify the administrators to top up to contract to complete this action"
        );

        raffles[_raffleId].status = RaffleStatus.PENDING_COMPLETION;

        bytes32 requestId = requestRandomness(keyHash, fee);
        randomnessRequestToRaffle[requestId] = _raffleId;

        emit RequestID(requestId);
    }
}