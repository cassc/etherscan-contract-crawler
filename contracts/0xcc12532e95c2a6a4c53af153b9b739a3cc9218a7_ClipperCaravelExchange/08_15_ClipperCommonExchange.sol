//SPDX-License-Identifier: Copyright 2021 Shipyard Software, Inc.
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/WrapperContractInterface.sol";

abstract contract ClipperCommonExchange is ERC20, ReentrancyGuard {

  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct Deposit {
      uint lockedUntil;
      uint256 poolTokenAmount;
  }

  uint256 constant ONE_IN_TEN_DECIMALS = 1e10;
  // Allow for inputs up to 0.5% more than quoted values to have scaled output.
  // Inputs higher than this value just get 0.5% more.
  uint256 constant MAX_ALLOWED_OVER_TEN_DECIMALS = ONE_IN_TEN_DECIMALS+50*1e6;

  // Signer is passed in on construction, hence "immutable"
  address immutable public DESIGNATED_SIGNER;
  address immutable public WRAPPER_CONTRACT;
  // Constant values for EIP-712 signing
  bytes32 immutable DOMAIN_SEPARATOR;
  string constant VERSION = '1.0.0';
  string constant NAME = 'ClipperDirect';

  address constant CLIPPER_ETH_SIGIL = address(0);

  bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
     abi.encodePacked("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
  );

  bytes32 constant OFFERSTRUCT_TYPEHASH = keccak256(
    abi.encodePacked("OfferStruct(address input_token,address output_token,uint256 input_amount,uint256 output_amount,uint256 good_until,address destination_address)")
  );

  bytes32 constant DEPOSITSTRUCT_TYPEHASH = keccak256(
    abi.encodePacked("DepositStruct(address sender,uint256[] deposit_amounts,uint256 days_locked,uint256 pool_tokens,uint256 good_until)")
  );

  bytes32 constant SINGLEDEPOSITSTRUCT_TYPEHASH = keccak256(
    abi.encodePacked("SingleDepositStruct(address sender,address token,uint256 amount,uint256 days_locked,uint256 pool_tokens,uint256 good_until)")
  );

  bytes32 constant WITHDRAWALSTRUCT_TYPEHASH = keccak256(
    abi.encodePacked("WithdrawalStruct(address token_holder,uint256 pool_token_amount_to_burn,address asset_address,uint256 asset_amount,uint256 good_until)")
  );

  // Assets
  // lastBalances: used for "transmit then swap then sync" modality
  // assetSet is a set of keys that have lastBalances
  mapping(address => uint256) public lastBalances;
  EnumerableSet.AddressSet assetSet;


  // Allows lookup
  mapping(address => Deposit) public vestingDeposits;

  // Events
  event Swapped(
    address indexed inAsset,
    address indexed outAsset,
    address indexed recipient,
    uint256 inAmount,
    uint256 outAmount,
    bytes auxiliaryData
  );

  event Deposited(
    address indexed depositor,
    uint256 poolTokens,
    uint256 nDays
  );

  event Withdrawn(
    address indexed withdrawer,
    uint256 poolTokens,
    uint256 fractionOfPool
  );

  event AssetWithdrawn(
    address indexed withdrawer,
    uint256 poolTokens,    
    address indexed assetAddress,
    uint256 assetAmount
  );

  // Take in the designated signer address and the token list
  constructor(address theSigner, address theWrapper, address[] memory tokens) ERC20("ClipperDirect Pool Token", "CLPRDRPL") {
    DESIGNATED_SIGNER = theSigner;
    uint i;
    uint n = tokens.length;
    while(i < n) {
        assetSet.add(tokens[i]);
        i++;
    }
    DOMAIN_SEPARATOR = createDomainSeparator(NAME, VERSION, address(this));
    WRAPPER_CONTRACT = theWrapper;
  }

  // Allows the receipt of ETH directly
  receive() external payable {
  }

  function safeEthSend(address recipient, uint256 howMuch) internal {
    (bool success, ) = payable(recipient).call{value: howMuch}("");
    require(success, "Call with value failed");
  }

  /* TOKEN AND ASSET FUNCTIONS */
  function nTokens() public view returns (uint) {
    return assetSet.length();
  }

  function tokenAt(uint i) public view returns (address) {
    return assetSet.at(i);
  }

  function isToken(address token) public view returns (bool) {
    return assetSet.contains(token);
  }

  function _sync(address token) internal virtual;

  // Can be overridden as in Caravel
  function getLastBalance(address token) public view virtual returns (uint256) {
    return lastBalances[token];
  }

  function allTokensBalance() external view returns (uint256[] memory, address[] memory, uint256){
    uint n = nTokens();
    uint256[] memory balances = new uint256[](n);
    address[] memory tokens = new address[](n);
    for (uint i = 0; i < n; i++) {
      address token = tokenAt(i);
      balances[i] = getLastBalance(token);
      tokens[i] = token;
    }

    return (balances, tokens, totalSupply());
  }

  // nonReentrant asset transfer
  function transferAsset(address token, address recipient, uint256 amount) internal nonReentrant {
    IERC20(token).safeTransfer(recipient, amount);
    // We never want to transfer an asset without sync'ing
    _sync(token);
  }

  function calculateFairOutput(uint256 statedInput, uint256 actualInput, uint256 statedOutput) internal pure returns (uint256) {
    if(actualInput == statedInput) {
      return statedOutput;
    } else {
      uint256 theFraction = (ONE_IN_TEN_DECIMALS*actualInput)/statedInput;
      if(theFraction >= MAX_ALLOWED_OVER_TEN_DECIMALS) {
        return (MAX_ALLOWED_OVER_TEN_DECIMALS*statedOutput)/ONE_IN_TEN_DECIMALS;
      } else {
        return (theFraction*statedOutput)/ONE_IN_TEN_DECIMALS;
      }
    }
  }

  /* DEPOSIT FUNCTIONALITY */
  function canUnlockDeposit(address theAddress) public view returns (bool) {
      Deposit storage myDeposit = vestingDeposits[theAddress];
      return (myDeposit.poolTokenAmount > 0) && (myDeposit.lockedUntil <= block.timestamp);
  }

  function unlockDeposit() external returns (uint256 poolTokens) {
    require(canUnlockDeposit(msg.sender), "ClipperDirect: Deposit cannot be unlocked");
    poolTokens = vestingDeposits[msg.sender].poolTokenAmount;
    delete vestingDeposits[msg.sender];

    _transfer(address(this), msg.sender, poolTokens);
  }

  function _mintOrVesting(address sender, uint256 nDays, uint256 poolTokens) internal {
    if(nDays==0){
      // No vesting period required - mint tokens directly for the user
      _mint(sender, poolTokens);
    } else {
      // Set up a vesting deposit for the sender
      _createVestingDeposit(sender, nDays, poolTokens);
    }
  }

  // Mints tokens to this contract to hold for vesting
  function _createVestingDeposit(address theAddress, uint256 nDays, uint256 numPoolTokens) internal {
    require(nDays > 0, "ClipperDirect: Cannot create vesting deposit without positive vesting period");
    require(vestingDeposits[theAddress].poolTokenAmount==0, "ClipperDirect: Depositor already has an active deposit");

    Deposit memory myDeposit = Deposit({
      lockedUntil: block.timestamp + (nDays * 1 days),
      poolTokenAmount: numPoolTokens
    });
    vestingDeposits[theAddress] = myDeposit;
    _mint(address(this), numPoolTokens);
  }

  function transmitAndDeposit(uint256[] calldata depositAmounts, uint256 nDays, uint256 poolTokens, uint256 goodUntil, Signature calldata theSignature) external {
    uint i=0;
    uint n = depositAmounts.length;
    while(i < n){
      uint256 transferAmount = depositAmounts[i];
      if(transferAmount > 0){
        IERC20(tokenAt(i)).safeTransferFrom(msg.sender, address(this), transferAmount);
      }
      i++;
    }
    deposit(msg.sender, depositAmounts, nDays, poolTokens, goodUntil, theSignature);
  }

  function transmitAndDepositSingleAsset(address inputToken, uint256 inputAmount, uint256 nDays, uint256 poolTokens, uint256 goodUntil, Signature calldata theSignature) external virtual;

  function deposit(address sender, uint256[] calldata depositAmounts, uint256 nDays, uint256 poolTokens, uint256 goodUntil, Signature calldata theSignature) public payable virtual;

  function depositSingleAsset(address sender, address inputToken, uint256 inputAmount, uint256 nDays, uint256 poolTokens, uint256 goodUntil, Signature calldata theSignature) public payable virtual;

  /* WITHDRAWAL FUNCTIONALITY */
  function _proportionalWithdrawal(uint256 myFraction) internal {
    uint256 toTransfer;

    uint i;
    uint n = nTokens();
    while(i < n) {
        address theToken = tokenAt(i);
        toTransfer = (myFraction*getLastBalance(theToken)) / ONE_IN_TEN_DECIMALS;
        // syncs done automatically on transfer
        transferAsset(theToken, msg.sender, toTransfer);
        i++;
    }
  }

  function burnToWithdraw(uint256 amount) external {
    // Capture the fraction first, before burning
    uint256 theFractionBaseTen = (ONE_IN_TEN_DECIMALS*amount)/totalSupply();
    
    // Reverts if balance is insufficient
    _burn(msg.sender, amount);

    _proportionalWithdrawal(theFractionBaseTen);
    emit Withdrawn(msg.sender, amount, theFractionBaseTen);
  }

  function withdrawSingleAsset(address tokenHolder, uint256 poolTokenAmountToBurn, address assetAddress, uint256 assetAmount, uint256 goodUntil, Signature calldata theSignature) external virtual;

  /* SWAP Functionality: Virtual */
  function sellEthForToken(address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external payable virtual;
  function sellTokenForEth(address inputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external virtual;
  function transmitAndSellTokenForEth(address inputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external virtual;
  function transmitAndSwap(address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external virtual;
  function swap(address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) public virtual;

  /* SIGNING Functionality */
  function createDomainSeparator(string memory name, string memory version, address theSigner) internal view returns (bytes32) {
    return keccak256(abi.encode(
        EIP712DOMAIN_TYPEHASH,
        keccak256(abi.encodePacked(name)),
        keccak256(abi.encodePacked(version)),
        uint256(block.chainid),
        theSigner
      ));
  }

  function hashInputOffer(address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress) internal pure returns (bytes32) {
    return keccak256(abi.encode(
            OFFERSTRUCT_TYPEHASH,
            inputToken,
            outputToken,
            inputAmount,
            outputAmount,
            goodUntil,
            destinationAddress
        ));
  }

  function hashDeposit(address sender, uint256[] calldata depositAmounts, uint256 daysLocked, uint256 poolTokens, uint256 goodUntil) internal pure returns (bytes32) {
    bytes32 depositAmountsHash = keccak256(abi.encodePacked(depositAmounts));
    return keccak256(abi.encode(
        DEPOSITSTRUCT_TYPEHASH,
        sender,
        depositAmountsHash,
        daysLocked,
        poolTokens,
        goodUntil
      ));
  }

  function hashSingleDeposit(address sender, address inputToken, uint256 inputAmount, uint256 daysLocked, uint256 poolTokens, uint256 goodUntil) internal pure returns (bytes32) {
    return keccak256(abi.encode(
        SINGLEDEPOSITSTRUCT_TYPEHASH,
        sender,
        inputToken,
        inputAmount,
        daysLocked,
        poolTokens,
        goodUntil
      ));
  }

  function hashWithdrawal(address tokenHolder, uint256 poolTokenAmountToBurn, address assetAddress, uint256 assetAmount,
                    uint256 goodUntil) internal pure returns (bytes32) {
    return keccak256(abi.encode(
        WITHDRAWALSTRUCT_TYPEHASH,
        tokenHolder,
        poolTokenAmountToBurn,
        assetAddress,
        assetAmount,
        goodUntil
      ));
  }

  function createSwapDigest(address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress) internal view returns (bytes32 digest){
    bytes32 hashedInput = hashInputOffer(inputToken, outputToken, inputAmount, outputAmount, goodUntil, destinationAddress);    
    digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, hashedInput);
  }

  function createDepositDigest(address sender, uint256[] calldata depositAmounts, uint256 nDays, uint256 poolTokens, uint256 goodUntil) internal view returns (bytes32 depositDigest){
    bytes32 hashedInput = hashDeposit(sender, depositAmounts, nDays, poolTokens, goodUntil);    
    depositDigest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, hashedInput);
  }

  function createSingleDepositDigest(address sender, address inputToken, uint256 inputAmount, uint256 nDays, uint256 poolTokens, uint256 goodUntil) internal view returns (bytes32 depositDigest){
    bytes32 hashedInput = hashSingleDeposit(sender, inputToken, inputAmount, nDays, poolTokens, goodUntil);
    depositDigest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, hashedInput);
  }

  function createWithdrawalDigest(address tokenHolder, uint256 poolTokenAmountToBurn, address assetAddress, uint256 assetAmount,
                    uint256 goodUntil) internal view returns (bytes32 withdrawalDigest){
    bytes32 hashedInput = hashWithdrawal(tokenHolder, poolTokenAmountToBurn, assetAddress, assetAmount, goodUntil);
    withdrawalDigest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, hashedInput);
  }

  function verifyDigestSignature(bytes32 theDigest, Signature calldata theSignature) internal view {
    address signingAddress = ecrecover(theDigest, theSignature.v, theSignature.r, theSignature.s);

    require(signingAddress==DESIGNATED_SIGNER, "Message signed by incorrect address");
  }

}