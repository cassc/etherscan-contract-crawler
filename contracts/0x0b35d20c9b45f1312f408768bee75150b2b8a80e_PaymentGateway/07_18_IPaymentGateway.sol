// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IPaymentGateway {

  ///////////////////// FUNCTIONS /////////////////////

  function pay(
    bytes32 paymentId,
    uint256 amount,
    address token,
    address receiver,
    uint256 deadline,
    bytes memory signature
  ) external;

  function payETH(
    bytes32 paymentId,
    uint256 amount,
    address receiver,
    uint256 deadline,
    bytes memory signature
  ) external payable;


  ///////////////////// ERRORS /////////////////////

  error InvalidSignature();       // 0x8baa579f
  error TokenPaymentWithValue();  // 0x4a5c1927
  error ETHPaymentWrongValue();   // 0x2ed87482
  error TokenNotAllowed();        // 0xa29c4986
  error PastDeadline();           // 0x81efbd8d
  error EthTransferFailed();      // 0x6d963f88
  error SignerAddressZero();      // 0x2b561add
  error TokenAddressZero();       // 0x81c609f7
  error SameSigner();             // 0x77576900
  error AlreadyAllowed();         // 0x6a4648d7
  error AlreadyRemoved();         // 0xab5bea8e
  error SignatureUsed();          // 0x0d754933
  error ReceiverAddressZero();    // 0x0ce16b51
  error NoBalance();              // 0xc2caa2a6
  error ZeroAddressToken();       // 0x14f28f2b
  error WrongSigner();            // 0xa7932e6a

  ///////////////////// EVENTS /////////////////////

  event PaymentExecuted(bytes32 indexed paymentId, address indexed sender);
  event SignerUpdated(address indexed newSigner, address indexed oldSigner);
  event TokenAdded(address indexed token);
  event TokenRemoved(address indexed token);
}