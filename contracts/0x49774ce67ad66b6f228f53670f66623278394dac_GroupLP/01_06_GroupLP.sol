pragma solidity ^0.8.4;

import '@uniswap/v2-periphery/contracts/interfaces/IERC20.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import "@openzeppelin/contracts/proxy/Clones.sol";

interface IOptiVault {
  function initialize(address _token, uint256 _lockupDate, uint256 _minimumTokenCommitment, uint256 _withdrawalsLockedUntilTimestamp, address _balanceLookup) external;
}

contract GroupLP {
  receive() external payable {}

  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address private constant operations = 0x133A5437951EE1D312fD36a74481987Ec4Bf8A96;
  address private constant optiVaultMaster = 0xC5A00A96E6a7039daD5af5c41584469048B26038; // Address to clone OptiVault from

  IERC20 public token;                                   // Token to add LP for
  address public tokenSupplier;                          // Supplier of token
  uint256 public committedTokenAmount;                   // Amount to match
  uint256 public goalDate;                               // Date by which to complete the campaign
  uint256 public withdrawalsLockedDuration;              // Proposed duration of OptiVault lock
  uint256 public withdrawalsLockedUntilTimestamp;        // End time plus Duration
  IUniswapV2Pair private pair;                           // Pair to add to
  bool private initialized;                              // Campaign pamaters hav been set
  bool public campaignFailed;                            // Allows recovery of ETH under failure conditions

  mapping (address => uint256) public ethContributionOf; // Used as numerator for calculating users shares
  uint256 public totalFundingRaised;                     // Used as denominator for calculating users shares

  uint256 public mintedLP;                               // Amount of LP that has been minted
  address public optiVault;                              // cloned OptiVault contract that holds the minted LP

  function initialize(address _pair, address _tokenSupplier, uint256 _goalDate, uint256 _withdrawalsLockedDuration,  uint256 _commitment) external payable {
    require(!initialized, "GroupLP: Already initialized");
    committedTokenAmount = _commitment;
    pair = IUniswapV2Pair(_pair);
    token = (pair.token0() == WETH) ? IERC20(pair.token1()) : IERC20(pair.token0());
    goalDate = _goalDate;
    withdrawalsLockedDuration = _withdrawalsLockedDuration;
    tokenSupplier = _tokenSupplier;
    ethContributionOf[tokenSupplier] = msg.value;
    totalFundingRaised = msg.value; 
    initialized = true;
  }

  function supplierHasCommitedBalance() public view returns (bool valid) {
    // Campaign is valid IFF: (Commited tokens <= Supplier approval <= Supplier balance)
    uint256 approval = token.allowance(tokenSupplier, address(this));
    uint256 balance = token.balanceOf(tokenSupplier);
    valid = committedTokenAmount <= approval && approval <= balance;
  }

  function getReserves() internal view returns (uint256 ethReserves, uint256 tokenReserves) {
    (uint reserveA, uint reserveB, ) = pair.getReserves();
    (ethReserves, tokenReserves) = WETH < address(token) ? (reserveA, reserveB) : (reserveB, reserveA);
  }

  function uniswapQuote(uint amountToken) internal view returns (uint256 amountEth) {
    (uint256 ethReserves, uint256 tokenReserves) = getReserves();
    amountEth = amountToken * ethReserves / tokenReserves;
  }  

  function ethMatchEstimate() public view returns (uint256 ethGoal) {
    ethGoal = uniswapQuote(committedTokenAmount) * 1005 / 1000;
  }

  function fund() public payable {
    require(supplierHasCommitedBalance(), "GroupLP: Supplier is missing tokens");
    require(!campaignFailed, "GroupLP: Campaign failed, use recoverETH");
    require((ethMatchEstimate() * 110) / 100 >= address(this).balance, "GroupLP: Over funded!");
    ethContributionOf[msg.sender] += msg.value;
    totalFundingRaised += msg.value;
  }

  function endFailedCampaign() public {
    // Either the campaign is invalid (token supplier's balance or approval has fallen beneath the committed tokens)
    // Or the campaign goalDate is past with no LP created
    require(!campaignFailed, "GroupLP: Campaign already failed.");
    require(mintedLP == 0, "GroupLP: LP already added!");
    bool campaignHasExpired = (block.timestamp > (goalDate + 1 hours));
    if (!supplierHasCommitedBalance() || campaignHasExpired) {
      campaignFailed = true;
    }
  }

  function readyToMint() public view returns (bool ready) {
    require(address(this).balance >= ethMatchEstimate(), "GroupLP: Campaign needs more ETH to match supplier's committed tokens");
    require(supplierHasCommitedBalance(), "GroupLP: Supplier's token balance or approval has fallen below the required amount.");
    return true;
  }

  function supplyLP(uint minimumEth) public returns (uint256 amountToken, uint256 amountETH) {
    require(msg.sender == operations);
    require(readyToMint());
    address pairAddress = address(pair);
    uint256 tokenBalanceOfPairPreSupply = token.balanceOf(pairAddress);
    TransferHelper.safeTransferFrom(address(token), tokenSupplier, pairAddress, committedTokenAmount);
    uint256 tokenBalanceOfPairPostSupply = token.balanceOf(pairAddress);
    amountToken = tokenBalanceOfPairPostSupply - tokenBalanceOfPairPreSupply; 
    amountETH = uniswapQuote(amountToken); 
    require(amountETH >= minimumEth, "GroupLP: Tokens must be valued at least the minimum Eth"); 
    IWETH(WETH).deposit{value: amountETH}();
    assert(IWETH(WETH).transfer(pairAddress, amountETH));

    withdrawalsLockedUntilTimestamp = block.timestamp + withdrawalsLockedDuration;
    optiVault = Clones.clone(optiVaultMaster);
    mintedLP = IUniswapV2Pair(pairAddress).mint(optiVault);
    payable(operations).transfer(address(this).balance); //Excess ETH to operations
    IOptiVault(optiVault).initialize(pairAddress, 0, 0, withdrawalsLockedUntilTimestamp, address(this));
  }

  function recoverETH() public {
    require(campaignFailed, "GroupLP: Campaign is active. Use withdrawLP.");
    require(ethContributionOf[msg.sender] > 0, "GroupLP: You have recovered all your ETH");
    payable(msg.sender).transfer(ethContributionOf[msg.sender]);
    ethContributionOf[msg.sender] == 0;
  }

  function contributionOf(address user) external view returns (uint256 _ethBalance) {
    _ethBalance = ethContributionOf[user];
  }

  function sharesOf(address user) external view returns (uint256 _lpTokenShare) {
    _lpTokenShare = (mintedLP / 2) * ethContributionOf[user] / totalFundingRaised;
    if (user == tokenSupplier) {
      _lpTokenShare += mintedLP / 2;
    }
  }

}