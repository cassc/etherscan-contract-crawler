// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

import "./LotteryNFT.sol";

error MaxTokensMinted();
error LimitReached();
error LotteryNotActive();
error IncorrectAmount();

contract Lottery is
    VRFV2WrapperConsumerBase,
    ConfirmedOwner,
    AutomationCompatibleInterface
{
    address public lotteryNFTAddress;
    address public charityAddress;
    address public destinationWallet;
    bool public isLotteryActive;
    LotteryNFT lotteryNFT;

    uint128 public price;
    uint64 public startTime;
    uint64 public interval;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    struct RequestStatus {
        uint256 paid;
        bool fulfilled;
        uint256[] randomWords;
    }

    struct Winner {
        address winnerAddress;
        uint256 tokenId;
        uint256 amount;
    }

    Winner[] public winners;

    mapping(uint256 => RequestStatus) public s_requests;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    uint32 callbackGasLimit = 1000000;

    uint16 requestConfirmations = 5;

    uint32 numWords = 10;

    address linkAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    address wrapperAddress = 0x5A861794B927983406fCE1D062e00b9368d97Df6;

    constructor()
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {}

    // This function was called by the owner of the contract to create a new lottery
    // @param name - name of the lotteryNFT
    // @param symbol - symbol of the lotteryNFT
    // @param uri - uri of the lotteryNFT
    // @param _price - price of the lotteryNFT
    // @param _charityAddress - address of the charity
    // @param _interval - interval of the lotteryNFT
    // @dev - interval means max time for the lottery to be active in seconds when the interval is reached the lottery will be closed and winner will be picked
    function createLotteryNFT(
        string memory name,
        string memory symbol,
        string memory uri,
        uint128 _price,
        address _charityAddress,
        address _destinationWallet,
        uint64 _interval
    ) external onlyOwner {
        require(!isLotteryActive, "Lottery is already active");
        lotteryNFT = new LotteryNFT(name, symbol, uri);
        lotteryNFTAddress = address(lotteryNFT);
        isLotteryActive = true;
        destinationWallet = _destinationWallet;
        price = _price;
        charityAddress = _charityAddress;
        interval = _interval;
        startTime = uint64(block.timestamp);
        if (winners.length > 0) {
            delete winners;
        }
    }

    // This function was to buy tickets for the lottery with max limit of 10 tickets per transaction
    // @param amount - amount of tickets to buy
    // @dev - the function will revert if the amount is more than 10 or if the lottery is not active or if the amount is not equal to the price of the ticket
    // and also picks the winner when all the tickets are sold
    function buyTicket(uint8 amount) external payable {
        if (lotteryNFT.tokenId() + amount > 2222) {
            revert MaxTokensMinted();
        }
        if (amount > 10) {
            revert LimitReached();
        }
        if (!isLotteryActive) {
            revert LotteryNotActive();
        }
        if (msg.value < price * amount) {
            revert IncorrectAmount();
        }
        for (uint8 i = 0; i < amount; ) {
            lotteryNFT.mint(msg.sender);
            unchecked {
                ++i;
            }
        }
        if (lotteryNFT.tokenId() == 2222) {
            pickWinners();
        }
    }

    // This function was to generate random numbers to pick the winner powered by Chainlink VRF
    function pickWinners() internal returns (uint256 requestId) {
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    // This function was called by Chainlink VRF to fulfill the request
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        execute(_randomWords);
        isLotteryActive = false;
        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }

    // This function was powered by Chainlink automation to check whether the interval is reached or not
    // if reached it will pick the winners by running PerformUpkeep function
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded =
            (block.timestamp >= startTime + interval) &&
            isLotteryActive;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if (block.timestamp > startTime + interval) {
            pickWinners();
        }
    }

    function setCharityAddress(address _charityAddress) external onlyOwner {
        charityAddress = _charityAddress;
    }

    function setURI(string memory _uri) external onlyOwner {
        lotteryNFT.setURI(_uri);
    }

    function updateInterval(uint32 _interval) external onlyOwner {
        interval = _interval;
    }

    function updatePrice(uint128 _price) external onlyOwner {
        price = _price;
    }

    function pickUpWinners() external onlyOwner {
        pickWinners();
    }

    // This function was called by the contract to distribute the prize to the winners
    function execute(uint256[] memory winner) internal {
        uint16 tokenId = lotteryNFT.tokenId();
        uint256 balance = address(this).balance;
        uint256 id = (winner[0] % tokenId) + 1;
        address winnerAdd = lotteryNFT.ownerOf(id);
        uint256 winnerAmount = (balance * 5902230) / 10000000;
        winners.push(Winner(winnerAdd, id, winnerAmount));
        payable(winnerAdd).transfer(winnerAmount);
        for (uint8 i = 1; i <= winner.length; ) {
            if (winners.length == 5) {
                break;
            }
            // if tokenId already exists in winners array then it will pick another winner iteratively
            bool alreadySelected = false;
            id = (winner[i] % tokenId) + 1;
            for (uint8 j = 0; j < winners.length; j++) {
                if (winners[j].tokenId == id) {
                    alreadySelected = true;
                    break;
                }
            }

            if (!alreadySelected) {
                winnerAdd = lotteryNFT.ownerOf(id);
                winnerAmount = (balance * 737779) / 10000000;
                winners.push(Winner(winnerAdd, id, winnerAmount));
                payable(winnerAdd).transfer(winnerAmount);
            }
            unchecked {
                ++i;
            }
        }
        payable(charityAddress).transfer((balance * 553334) / 10000000);
        payable(destinationWallet).transfer(address(this).balance);
    }

    function getWinners() external view returns (Winner[] memory) {
        return winners;
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    receive() external payable {}
}