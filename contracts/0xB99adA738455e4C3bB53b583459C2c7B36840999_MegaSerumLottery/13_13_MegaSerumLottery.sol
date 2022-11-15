//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

interface DogcSerumInterface {
  function balanceOf(address account, uint256 id)
  external
  view
  returns (uint256);

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;
}


contract MegaSerumLottery is VRFV2WrapperConsumerBase, ConfirmedOwner, ReentrancyGuard, ERC1155Holder {
  DogcSerumInterface public immutable serum;

  event RequestSent(uint256 requestId, uint32 numWords);
  event RequestFulfilled(
    uint256 requestId,
    uint256[] randomWords,
    uint256 payment
  );

  event LotteryResults(uint16[] results);

  event ClaimSerum(uint256 _phase);

  struct RequestStatus {
    uint256 paid; // amount paid in link
    bool fulfilled; // whether the request has been successfully fulfilled
    uint256[] randomWords;
  }
  mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */


  uint256[] public requestIds;
  uint256 public lastRequestId;
  address public linkAddress;
  address public wrapperAddress;

  uint32 private callbackGasLimit = 100000;
  uint16 private requestConfirmations = 3;
  uint32 private numWords = 1;

  uint16[] public results;

  struct PhaseInfo {
    string ticketUrl;
    uint256 ticketsAmount;
    address winner;
  }
  mapping(uint256 => PhaseInfo) public phaseInfo;
  mapping(uint256 => bool) public claimed;

  constructor(address _linkAddress, address _wrapperAddress, address _serum)
    ConfirmedOwner(msg.sender)
    VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress)
  {
    linkAddress = _linkAddress;
    wrapperAddress = _wrapperAddress;
    serum = DogcSerumInterface(_serum);
  }

  function requestRandomWords() external onlyOwner returns (uint256 requestId) {
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

  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords)
    internal
    override
  {
    require(s_requests[_requestId].paid > 0, "request not found");
    s_requests[_requestId].fulfilled = true;
    s_requests[_requestId].randomWords = _randomWords;
    emit RequestFulfilled(
      _requestId,
      _randomWords,
      s_requests[_requestId].paid
    );
  }

  function getRequestStatus(uint256 _requestId)
    external
    view
    returns (
      uint256 paid,
      bool fulfilled,
      uint256[] memory randomWords
    )
  {
    require(s_requests[_requestId].paid > 0, "request not found");
    RequestStatus memory request = s_requests[_requestId];
    return (request.paid, request.fulfilled, request.randomWords);
  }

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(linkAddress);
    require(
      link.transfer(msg.sender, link.balanceOf(address(this))),
      "Unable to transfer"
    );
  }

  function lottery(uint256 _phase) external onlyOwner returns (uint16[] memory) {
    require(phaseInfo[_phase].ticketsAmount > 0, "Haven't set participants number");
    require(s_requests[lastRequestId].fulfilled, "Haven't got randomness");
    uint256 random = s_requests[lastRequestId].randomWords[0];

    uint16 result = uint16(random % phaseInfo[_phase].ticketsAmount);
    results.push(result);

    emit LotteryResults(results);
    return results;
  }

  function setTicketUrl(uint256 _phase, string memory _baseuri, uint256 _ticketsAmount) external onlyOwner {
    phaseInfo[_phase] = PhaseInfo(_baseuri, _ticketsAmount, address(0));
  }

  function setWinner(uint256 _phase, address _winner) external onlyOwner {
    phaseInfo[_phase].winner = _winner;
  }

  function balance(uint256 id) public view returns (uint256) {
    return serum.balanceOf(address(this), id);
  }

  function claim(uint256 _phase) external {
    require(!claimed[_phase], 'Already claimed the mega serum');
    require(msg.sender == phaseInfo[_phase].winner, 'Not the winner');
    require(balance(3) >= 1, "Insufficient remains");

    claimed[_phase] = true;
    serum.safeTransferFrom(address(this), msg.sender, 3, 1, "");
    emit ClaimSerum(_phase);
  }
}