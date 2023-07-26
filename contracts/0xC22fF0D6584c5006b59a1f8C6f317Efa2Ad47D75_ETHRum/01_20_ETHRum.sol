/**
 _____ _____ _____ _____
|   __|_   _|  |  | __  |_ _ _____
|   __| | | |     |    -| | |     |
|_____| |_| |__|__|__|__|___|_|_|_|
ETHRUM, a digital experience to get you responsibly rekt
SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

import "ERC721Consecutive.sol";
import "VRFV2WrapperConsumerBase.sol";

/**
 * @title ETHRum
 * @notice changes media URI based on each token's status -
 * @notice unopened, winner, or empty
 * @author Gene A. Tsvigun
 * @author Denise Epstein
 * @dev status switch is only permitted to the randomizer contract
 * @dev providing fair randomness
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
contract ETHRum is ERC721Consecutive, VRFV2WrapperConsumerBase {
    enum Status {
        Unopened,
        Empty,
        Winner
    }

    uint96 public constant TOTAL_BOTTLES = 100;
    uint32 public constant CALLBACK_GAS_LIMIT = 5 * 10 ** 4;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 1;

    uint256 public revealWindowStart;
    uint256 public revealWindowEnd;
    bool public isRevealed;

    string private emptyURI;
    string private unopenedURI;
    string private winnerURI;
    uint8 private numberOfWinners;
    address private croupier;

    uint256 private randomness;


    event Revealed(uint256 randomness);

    constructor(
        string memory _emptyURI,
        string memory _unopenedURI,
        string memory _winnerURI,
        string memory name,
        string memory symbol,
        uint8 _numberOfWinners,
        address _crupier,
        uint256 _revealWindowStart,
        uint256 _revealWindowEnd,
        address link_,
        address _vrfV2Wrapper
    )
    ERC721(name, symbol)
    VRFV2WrapperConsumerBase(
        link_,
        _vrfV2Wrapper
    ) {
        emptyURI = _emptyURI;
        unopenedURI = _unopenedURI;
        winnerURI = _winnerURI;
        numberOfWinners = _numberOfWinners;
        croupier = _crupier;
        revealWindowStart = _revealWindowStart;
        revealWindowEnd = _revealWindowEnd;
        _mintConsecutive(msg.sender, TOTAL_BOTTLES);
    }

    /**
     * @notice roll the dice to reveal winners
     * @notice only the croupier can roll before reveal window ends
     * @notice anyone can roll after reveal window ends
     * @dev request randomness from Chainlink VRF
     */
    function roll() external {
        require(!isRevealed, "ETHRum: already revealed");
        require(block.timestamp >= revealWindowStart, "ETHRum: reveal window has not started yet");
        require(msg.sender == croupier || block.timestamp >= revealWindowEnd, "ETHRum: only croupier can roll before reveal window ends");
        requestRandomness();
    }

    function roll(uint32 callbackGasLimit) external {
        require(!isRevealed, "ETHRum: already revealed");
        require(block.timestamp >= revealWindowStart, "ETHRum: reveal window has not started yet");
        require(msg.sender == croupier || block.timestamp >= revealWindowEnd, "ETHRum: only croupier can roll before reveal window ends");
        requestRandomness(callbackGasLimit);
    }

    /**
    * @dev reveal the winners, called by Chainlink VRF
    */
    function revealStatus(uint256 _randomness) private {
        require(!isRevealed, "ETHRum: already revealed");
        randomness = _randomness % 100;
        isRevealed = true;
        emit Revealed(randomness);
    }


    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        Status status = getStatus(tokenId);
        return status == Status.Empty ? emptyURI : status == Status.Unopened ? unopenedURI : winnerURI;
    }

    /**
     * @notice get the status of a token based on randomness from Chainlink VRF
     * @param tokenId the token to check
     * @return the status of the token
     */
    function getStatus(uint256 tokenId) public view returns (Status) {
        if (!isRevealed) {
            return Status.Unopened;
        }
        uint256 top = (randomness + numberOfWinners) % TOTAL_BOTTLES;
        bool isWinner = top > randomness && (tokenId >= randomness && tokenId < top) || top < randomness && (tokenId >= randomness || tokenId < top);
        return isWinner ? Status.Winner : Status.Empty;
    }

    /**
     * @notice fulfillRandomWords handles the VRF V2 wrapper response.
     * @notice this function is called by rawFulfillRandomWords in VRFV2WrapperConsumerBase
     * @param _requestId is the VRF V2 request ID.
     * @param _randomWords is the randomness result.
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        revealStatus(_randomWords[0]);
    }

    /**
     * @dev request randomness from Chainlink VRF
     */
    function requestRandomness() private returns (uint256 requestId){
        return requestRandomness(CALLBACK_GAS_LIMIT, REQUEST_CONFIRMATIONS, NUM_WORDS);
    }

    /**
     * @dev request randomness from Chainlink VRF
     */
    function requestRandomness(uint32 callbackGasLimit) private returns (uint256 requestId){
        return requestRandomness(callbackGasLimit, REQUEST_CONFIRMATIONS, NUM_WORDS);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return TOTAL_BOTTLES;
    }
}