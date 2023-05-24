// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DoItDogeRaffle is
    VRFV2WrapperConsumerBase,
    ConfirmedOwner
{
    event WinnerPicked(address[] indexed winner);
    event RequestSent(uint256 requestId, uint32 numWords, uint256 paid);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );
    error InsufficientFunds(uint256 balance, uint256 paid);
    error RequestNotFound(uint256 requestId);
    error LinkTransferError(address sender, address receiver, uint256 amount);

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;
    IERC721A public NFT;


    // configuration: https://docs.chain.link/vrf/v2/direct-funding/supported-networks#configurations
    constructor(
        address _linkAddress,
        address _wrapperAddress,
        address NFTAddress
    )
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress)
    {
        NFT = IERC721A(NFTAddress);
    }

    function requestRandomWords(
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) external onlyOwner returns (uint256 requestId) {
        requestId = requestRandomness(
            _callbackGasLimit,
            _requestConfirmations,
            _numWords
        );
        uint256 paid = VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit);
        uint256 balance = LINK.balanceOf(address(this));
        if (balance < paid) revert InsufficientFunds(balance, paid);
        s_requests[requestId] = RequestStatus({
            paid: paid,
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, _numWords, paid);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {

        RequestStatus storage request = s_requests[_requestId];
        if (request.paid == 0) revert RequestNotFound(_requestId);
        request.fulfilled = true;
        request.randomWords = _randomWords;
        // emit RequestFulfilled(_requestId, _randomWords, request.paid);

    }

 
    // Raffle functions
    function distributePrizeETH() public onlyOwner {
        address[] memory winners = getWinners();
        uint256 balance = address(this).balance;
        uint256 prize = balance / winners.length;
        for (uint256 i=0; i < winners.length; i++) {
            payable(winners[i]).transfer(prize);
        }
        emit WinnerPicked(winners);
    }

    function distributePrizeERC20(address tokenAddress) public onlyOwner {
        address[] memory winners = getWinners();
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        uint256 prize = balance / winners.length;
        for (uint256 i=0; i < winners.length; i++) {
            IERC20(tokenAddress).transfer(winners[i], prize);
        }
        emit WinnerPicked(winners);
    }

    function getWinners() public view returns(address[] memory) {
        uint256[] memory WinnerTokenIds = getWinnerTokenIds();
        address[] memory winners = new address[](WinnerTokenIds.length);
        for (uint256 i = 0; i < WinnerTokenIds.length; i++) {
            winners[i] = NFT.ownerOf(WinnerTokenIds[i]);
        }
        return winners;
    }

    function getWinnerTokenIds() public view returns(uint256[] memory) {
        uint256 currentSupply = NFT.totalSupply();
        uint256[] memory randomNumbers = getRandomWords();
        uint256[] memory randomTokenIds = new uint256[](randomNumbers.length);
        for (uint256 i = 0 ; i < randomNumbers.length; i++) {
            uint256 randomTokenId = randomNumbers[i] % currentSupply;
            randomTokenIds[i] = randomTokenId;
        }
        return randomTokenIds;
    }

    function getRandomWords() private view returns(uint256[] memory) {
        require(s_requests[lastRequestId].paid > 0, "last random word request not found");
        RequestStatus memory request = s_requests[lastRequestId];
        return request.randomWords;
    }

    function withdrawLink(address _receiver) public onlyOwner {
        bool success = LINK.transfer(_receiver, LINK.balanceOf(address(this)));
        if (!success)
            revert LinkTransferError(
                msg.sender,
                _receiver,
                LINK.balanceOf(address(this))
            );
    }

    function withdrawETH(address _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_receiver).transfer(balance);
    }

    function withdrawERC20(address tokenAddress, address _receiver) external onlyOwner {
            uint balance = IERC20(tokenAddress).balanceOf(address(this));
            IERC20(tokenAddress).transfer(_receiver, balance);
    }

    receive() external payable {}

}