pragma experimental ABIEncoderV2;
pragma solidity ^0.5.0;

import "@studydefi/money-legos/dydx/contracts/DydxFlashloanBase.sol";
import "@studydefi/money-legos/compound/contracts/ICToken.sol";
import "@studydefi/money-legos/dydx/contracts/ICallee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//cuz @studydefi doesn't contain clamComp();
interface Comptroller {
  function enterMarkets(address[] calldata) external returns (uint256[] memory);
  function claimComp(address holder) external;
}

contract LeveragedYieldFarm is ICallee, DydxFlashloanBase {
  // Mainnet Dai
  // https://etherscan.io/address/0x6b175474e89094c44da98b954eedeac495271d0f#readContract
  address daiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  IERC20 dai = IERC20(daiAddress);

  // Mainnet cDai
  // https://etherscan.io/address/0x5d3a536e4d6dbd6114cc1ead35777bab948e3643#readProxyContract
  address cDaiAddress = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
  ICToken cDai = ICToken(cDaiAddress);

  // Mainnet Comptroller
  // https://etherscan.io/address/0x3d9819210a31b4961b30ef54be2aed79b9c9cd3b#readProxyContract
  address comptrollerAddress = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
  Comptroller comptroller = Comptroller(comptrollerAddress);

  // COMP ERC-20 token
  // https://etherscan.io/token/0xc00e94cb662c3520282e6f5717214004a7f26888
  IERC20 compToken = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);

  // Mainnet dYdX SoloMargin contract
  // https://etherscan.io/address/0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e#readProxyContract
  address soloMarginAddress = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

  // Contract owner
  address payable owner;

  struct MyCustomData {
    address token;
    uint256 repayAmount;
    uint256 fullAmount;
    bool isDeposit;
  }

  event FlashLoan(address indexed _from, bytes32 indexed _id, uint _value);

  // Modifiers
  modifier onlyOwner() {
    require(msg.sender == owner, "caller is not the owner!");
    _;
  }

  constructor() public {
    // Track the contract owner
    owner = msg.sender;

    // Enter the cDai market so you can borrow another type of asset
    address[] memory cTokens = new address[](1);
    cTokens[0] = cDaiAddress;
    uint256[] memory errors = comptroller.enterMarkets(cTokens);
    if (errors[0] != 0) {
      revert("Comptroller.enterMarkets failed.");
    }
  }

  // Don't allow contract to receive Ether by mistake
  function() external payable {
    revert();
  }

  function flashLoan(address _solo, address _token, uint256 _amount, uint256 _fullAmount, bool _isDeposit) internal {
    ISoloMargin solo = ISoloMargin(_solo);

    // Get marketId from token address
    uint256 marketId = _getMarketIdFromTokenAddress(_solo, _token);

    // Calculate repay amount (_amount + (2 wei))
    // Approve transfer from
    uint256 repayAmount = _getRepaymentAmountInternal(_amount);
    IERC20(_token).approve(_solo, repayAmount);

    // 1. Withdraw $
    // 2. Call callFunction(...)
    // 3. Deposit back $
    Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

    operations[0] = _getWithdrawAction(marketId, _amount);
    operations[1] = _getCallAction(
      // Encode MyCustomData for callFunction
      abi.encode(MyCustomData({
        token: _token,
        repayAmount: repayAmount,
        fullAmount: _fullAmount,
        isDeposit: _isDeposit}
      ))
    );
    operations[2] = _getDepositAction(marketId, repayAmount);

    Account.Info[] memory accountInfos = new Account.Info[](1);
    accountInfos[0] = _getAccountInfo();

    solo.operate(accountInfos, operations);
  }

  // Do not deposit all your DAI because you must pay flash loan fees
  // Always keep at least 1 DAI in the contract
  function depositDai(uint256 initialAmount) external onlyOwner returns (bool) {
    // Total deposit: 30% initial amount, 70% flash loan
    uint256 totalAmount = (initialAmount * 10) / 3;

    // loan is 70% of total deposit
    uint256 flashLoanAmount = totalAmount - initialAmount;

    // Get DAI Flash Loan for "DEPOSIT"
    bool isDeposit = true;
    flashLoan(soloMarginAddress, daiAddress, flashLoanAmount, totalAmount, isDeposit); // execution goes to `callFunction`

    // Handle remaining execution inside handleDeposit() function

    return true;
  }

  // You must have some Dai in your contract still to pay flash loan fee!
  // Always keep at least 1 DAI in the contract
  function withdrawDai(uint256 initialAmount) external onlyOwner returns (bool) {
    // Total deposit: 30% initial amount, 70% flash loan
    uint256 totalAmount = (initialAmount * 10) / 3;

    // loan is 70% of total deposit
    uint256 flashLoanAmount = totalAmount - initialAmount;

    // Use flash loan to payback borrowed amount
    bool isDeposit = false; //false means withdraw
    flashLoan(soloMarginAddress, daiAddress, flashLoanAmount, totalAmount, isDeposit); // execution goes to `callFunction`

    // Handle repayment inside handleWithdraw() function

    // Claim COMP tokens
    comptroller.claimComp(address(this));

    // Withdraw COMP tokens
    compToken.transfer(owner, compToken.balanceOf(address(this)));

    // Withdraw Dai to the wallet
    dai.transfer(owner, dai.balanceOf(address(this)));

    return true;
  }

  // This is the function that will be called postLoan
  // i.e. Encode the logic to handle your flashloaned funds here
  function callFunction(address sender, Account.Info memory account, bytes memory data) public {
    MyCustomData memory mcd = abi.decode(data, (MyCustomData));
    uint256 balOfLoanedToken = IERC20(mcd.token).balanceOf(address(this));

    // Note that you can ignore the line below
    // if your dydx account (this contract in this case)
    // has deposited at least ~2 Wei of assets into the account
    // to balance out the collaterization ratio
    require(
      balOfLoanedToken >= mcd.repayAmount,
      "Not enough funds to repay dYdX loan!"
    );

    if(mcd.isDeposit == true) {
      handleDeposit(mcd.fullAmount, mcd.repayAmount);
    }

    if(mcd.isDeposit == false) {
      handleWithdraw();
    }
  }

  // You must first send DAI to this contract before you can call this function
  function handleDeposit(uint256 totalAmount, uint256 flashLoanAmount) internal returns (bool) {
    // Approve Dai tokens as collateral
    dai.approve(cDaiAddress, totalAmount);

    // Provide collateral by minting cDai tokens
    cDai.mint(totalAmount);

    // Borrow Dai
    cDai.borrow(flashLoanAmount);

    // Start earning COMP tokens, yay!
    return true;
  }

  function handleWithdraw() internal returns (bool) {
    uint256 balance;

    // Get current borrow Balance
    balance = cDai.borrowBalanceCurrent(address(this));

    // Approve tokens for repayment
    dai.approve(address(cDai), balance);

    // Repay tokens
    cDai.repayBorrow(balance);

    // Get cDai balance
    balance = cDai.balanceOf(address(this));

    // Redeem cDai
    cDai.redeem(balance);

    return true;
  }

  // Fallback in case any other tokens are sent to this contract
  function withdrawToken(address _tokenAddress) public onlyOwner {
    uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
    IERC20(_tokenAddress).transfer(owner, balance);
  }
}