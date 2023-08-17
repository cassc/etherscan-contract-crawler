// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LuckyDraw is VRFV2WrapperConsumerBase, Ownable {
    using SafeERC20 for ERC20;
    /* ========== EVENTS ========== */

    event Recovered(address token, uint256 amount);
    event RequestDraw(
        uint round,
        uint256 requestId,
        uint256 paid,
        uint256 maxSoulpassId
    );
    event FulfillDraw(
        uint round,
        uint256 soulpassId,
        address soulpassOwner,
        uint256 payment
    );

    /* ========== DATA STRUCTURES ========== */

    //
    struct RequestDrawStatus {
        uint256 paid;
        uint256[] randomWords;
        uint256 maxSoulpassId;
        uint round;
        bool fulfilled;
    }

    //
    struct FulfillDrawStatus {
        uint256 soulpassId;
        address soulpassOwner;
        uint256 amount;
    }

    /* ========== STATE VARIABLES ========== */

    mapping(uint256 => RequestDrawStatus) public requests;
    uint256[] public requestIds;
    uint256 public lastRequestId;

    mapping(uint => FulfillDrawStatus) public results;
    mapping(uint256 => uint) _winnerRecord;
    //
    address public soulpassAddress;
    // maxSoulpassId can be increased only
    uint256 public maxSoulpassId;
    uint public immutable totalRounds;
    uint256 public immutable luckyAmount;
    uint256 public startTimestamp;
    uint256 public endTimestamp;

    address public operator;
    modifier onlyOperator() {
        require(_msgSender() == operator, "Caller is not the operator");
        _;
    }

    /*
     * @notice Constructor inherits VRFConsumerBase
     * @param _linkAddress - address of the LINK token
     * @param _wrapperAddress - address of the VRFV2Wrapper
     * @param _soulpassAddress - address of the Phemex Soulpass NFT
     * @param _totalRounds - total rounds of the lucky draw
     * @param _luckyAmount - amount of every lucky draw
     * @param _startTimestamp - start timestamp of the lucky draw event
     * @param _endTimestamp - end timestamp of the lucky draw event
     * @param _maxSoulpassId - the initialize max soulpass id
     */
    constructor(
        address _linkAddress,
        address _wrapperAddress,
        address _soulpassAddress,
        uint _totalRounds,
        uint256 _luckyAmount,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _maxSoulpassId
    ) VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress) {
        soulpassAddress = _soulpassAddress;
        totalRounds = _totalRounds;
        luckyAmount = _luckyAmount;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        maxSoulpassId = _maxSoulpassId;
    }

    //
    function requestDraw(
        uint _round,
        uint32 _callbackGasLimit,
        uint256 _maxSoulpassId
    ) external onlyOperator returns (uint256 requestId) {
        require(block.timestamp > startTimestamp, "lucky draw is not start");
        require(block.timestamp < endTimestamp, "lucky draw is finished");
        require(_maxSoulpassId >= maxSoulpassId, "invalid max soulpass id"); // maxSoulpassId must increase
        require(_round >= 1 && _round <= totalRounds, "invalid round");

        uint256 paid = VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit);
        uint256 balance = LINK.balanceOf(address(this));
        require(balance > paid, "insufficient funds");

        requestId = requestRandomness(_callbackGasLimit, uint16(3), uint32(1));
        requestIds.push(requestId);
        lastRequestId = requestId;
        maxSoulpassId = _maxSoulpassId;
        //
        requests[requestId] = RequestDrawStatus({
            paid: paid,
            randomWords: new uint256[](0),
            maxSoulpassId: _maxSoulpassId,
            round: _round,
            fulfilled: false
        });
        emit RequestDraw(_round, requestId, paid, _maxSoulpassId);
        return requestId;
    }

    /**
     * @notice Callback function used by VRF Coordinator
     *
     * @param _requestId - id of the request
     * @param _randomWords - array of random results from VRF Coordinator
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        RequestDrawStatus storage request = requests[_requestId];
        require(request.paid > 0, "request is not found");
        require(request.fulfilled == false, "request is fulfilled");
        request.fulfilled = true;
        request.randomWords = _randomWords;
        //
        fulfillDraw(_requestId);
    }

    function fulfillDraw(uint256 _requestId) internal {
        RequestDrawStatus memory request = requests[_requestId];
        require(request.fulfilled == true, "request is not fulfiled");
        require(
            request.round >= 1 && request.round <= totalRounds,
            "invalid round"
        );
        uint round = request.round;
        FulfillDrawStatus storage fulfill = results[round];
        require(fulfill.soulpassId == 0, "this round is finished");
        uint256[] memory randomWords = request.randomWords;
        require(randomWords.length >= 1, "invalid random words");
        uint256 randomWord = randomWords[0];
        //
        for (uint i = 0; i < 20; i++) {
            // iterate 20 times at most to find a winner
            uint256 random = uint256(
                keccak256(abi.encodePacked(randomWord, i))
            );
            uint256 soulpassId = (random % maxSoulpassId) + 1; // roll a number between 1 and maxSoulpassId (inclusive)
            if (_winnerRecord[soulpassId] != 0) {
                // skip if this soulpassId has won before
                continue;
            }
            address soulpassOwner = ownerOf(soulpassId);
            if (soulpassOwner == address(0)) {
                // skip if this soulpassId has been revoked or burned
                continue;
            }

            _winnerRecord[soulpassId] = round;
            fulfill.soulpassId = soulpassId;
            fulfill.soulpassOwner = soulpassOwner;
            fulfill.amount = luckyAmount;

            address payable winner = payable(soulpassOwner);
            (bool success, ) = winner.call{value: luckyAmount}("");
            require(success, "failed to send ether");
            emit FulfillDraw(round, soulpassId, soulpassOwner, luckyAmount);
            break;
        }
    }

    function ownerOf(uint256 soulpassId) internal view returns (address) {
        try IERC721(soulpassAddress).ownerOf(soulpassId) returns (
            address owner
        ) {
            return owner;
        } catch {
            return address(0);
        }
    }

    function getNumberOfRequests() external view returns (uint256) {
        return requestIds.length;
    }

    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (
            uint256 paid,
            bool fulfilled,
            uint256[] memory randomWords,
            uint256 soulpassId
        )
    {
        require(requests[_requestId].paid > 0, "request is not found");
        RequestDrawStatus memory request = requests[_requestId];
        return (
            request.paid,
            request.fulfilled,
            request.randomWords,
            request.maxSoulpassId
        );
    }

    function getFulfillStatus(
        uint _round
    )
        external
        view
        returns (uint256 soulpassId, address soulpassOwner, uint256 amount)
    {
        require(_round > 0 && _round <= totalRounds, "round is invalid");
        FulfillDrawStatus memory result = results[_round];
        return (result.soulpassId, result.soulpassOwner, result.amount);
    }

    function isWinner(uint256 _soulpassId) external view returns (bool) {
        return (_winnerRecord[_soulpassId] != 0);
    }

    // @notice recoverERC20 is used to recover any ERC20 tokens that are sent to
    // the contract address. Only the owner can call this function.
    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    ) external onlyOwner {
        // Only the owner address can ever receive the recovery withdrawal
        ERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    // @notice withdrawEther is used to withdraw any remaining ETH on the contract
    // after the lucky draw has ended. Only the owner can call this function.
    function withdrawEther(address payable _receiver) public onlyOwner {
        require(block.timestamp > endTimestamp, "ether is locked");
        (bool success, ) = _receiver.call{value: address(this).balance}("");
        require(success, "failed to send ether");
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    receive() external payable {}
}