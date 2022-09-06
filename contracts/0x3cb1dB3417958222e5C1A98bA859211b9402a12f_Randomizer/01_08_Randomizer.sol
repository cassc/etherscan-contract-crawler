// SPDX-License-Identifier: MIT
// An example of a consumer contract that also owns and manages the subscription
pragma solidity ^0.8.7;
pragma abicoder v2;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract Randomizer is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;

  // Goerli coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;

  // Goerli LINK token contract. For other networks, see
  // https://docs.chain.link/docs/vrf-contracts/#configurations
  address link_token_contract = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

  // A reasonable default is 100000, but this value could be different
  // on other networks.
  uint32 callbackGasLimit = 2500000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  500;

  // Storage parameters
  uint256[] private s_randomWords;
  uint256 public s_requestId;
  uint64 public s_subscriptionId;
  address s_owner;

  mapping(address => bool) gameContracts;

  uint256 wordsThreshold = 75;
  bool requestPending;
  
  ISwapRouter public constant swapRouter = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
  address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
  uint24 public constant poolFee = 3000;
  uint256 public swapThreshold = 10000000000000000;

  constructor() VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link_token_contract);
    s_owner = msg.sender;
    //Create a new subscription when you deploy the contract.
    createNewSubscription();
    gameContracts[address(this)] = true;
  }

  receive() external payable {}

  modifier onlyGames() {
    require(gameContracts[msg.sender], "only game contracts allowed");
    _;
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() public onlyGames {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
    requestPending = false;
  }

  function getRandomWords(uint256 number) external onlyGames returns (uint256[] memory ranWords) {
    ranWords = new uint256[](number);
    for (uint i = 0; i < number; i++) {
      uint256 curIndex = s_randomWords.length-1;
      ranWords[i] = s_randomWords[curIndex];
      s_randomWords.pop();
    }

    uint256 remainingWords = s_randomWords.length;
    if(remainingWords < wordsThreshold && !requestPending) {
      swapAndTopLink(); 
      requestRandomWords(); 
      requestPending = true;
    }
  }

  function getRemainingWords() external view onlyGames returns (uint256) {
    return s_randomWords.length;
  }

  // Create a new subscription when the contract is initially deployed.
  function createNewSubscription() private onlyOwner {
    s_subscriptionId = COORDINATOR.createSubscription();
    // Add this contract as a consumer of its own subscription.
    COORDINATOR.addConsumer(s_subscriptionId, address(this));
  }

  function swapAndTopLink() public onlyGames {

    uint256 amountIn = address(this).balance;

    if(amountIn < swapThreshold) {
      return;
    }

    swapExactInputSingle(amountIn);
    uint256 amount = LINKTOKEN.balanceOf(address(this));
    LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
  }

  /// @notice swapExactInputSingle swaps a fixed amount of DAI for a maximum possible amount of WETH9
  /// using the DAI/WETH9 0.3% pool by calling `exactInputSingle` in the swap router.
  /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its DAI for this function to succeed.
  /// @param amountIn The exact amount of DAI that will be swapped for WETH9.
  /// @return amountOut The amount of WETH9 received.
  function swapExactInputSingle(uint256 amountIn) internal returns (uint256 amountOut) {

      TransferHelper.safeApprove(WETH9, address(swapRouter), amountIn);

      ISwapRouter.ExactInputSingleParams memory params =
          ISwapRouter.ExactInputSingleParams({
              tokenIn: WETH9,
              tokenOut: LINK,
              fee: poolFee,
              recipient: address(this),
              deadline: block.timestamp,
              amountIn: amountIn,
              amountOutMinimum: 0,
              sqrtPriceLimitX96: 0
          });

      // The call to `exactInputSingle` executes the swap.
      amountOut = swapRouter.exactInputSingle(params);
  }

  // Assumes this contract owns link.
  // 1000000000000000000 = 1 LINK
  function topUpSubscription(uint256 amount) external onlyOwner {
    LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
  }

  function addConsumer(address consumerAddress) external onlyOwner {
    // Add a consumer contract to the subscription.
    COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
  }

  function removeConsumer(address consumerAddress) external onlyOwner {
    // Remove a consumer contract from the subscription.
    COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
  }

  function cancelSubscription(address receivingWallet) external onlyOwner {
    // Cancel the subscription and send the remaining LINK to a wallet address.
    COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
    s_subscriptionId = 0;
  }

  // Transfer this contract's funds to an address.
  // 1000000000000000000 = 1 LINK
  function withdraw(uint256 amount, address to) external onlyOwner {
    LINKTOKEN.transfer(to, amount);
  }

  function setGameContract(address _contract, bool flag)external onlyOwner {
        gameContracts[_contract] = flag;
  }

  function setCallbackGas(uint32 _gas) external onlyOwner {
    callbackGasLimit = _gas;
  }

  function setNumWords(uint32 _numWords) external onlyOwner {
    numWords = _numWords;
  }

  function setSwapThreshold(uint256 _threshold) external onlyOwner {
    swapThreshold = _threshold;
  }

  function setWordsThreshold(uint256 _threshold) external onlyOwner {
    wordsThreshold = _threshold;
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}