// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "../MetToken.sol";

interface MetroPrimeMintable {
  function mint(address to, uint256 packedMiniIds) external returns (uint256 tokenId);
}

contract MetroBridge is EIP712, Ownable {

  enum Operation {
    BURN_MET,
    MINT_MET,
    MINT_PRIME
  }

  struct Transaction {
    address sender;
    Operation operation;
    uint256 data;
    uint256 nonce;
    uint256 expirationTimestamp;
    bytes16 bridgeTransactionId;
  }

  bytes32 constant TRANSACTION_STRUCT_HASH = keccak256("Transaction(address sender,uint8 operation,uint256 data,uint256 nonce,uint256 expirationTimestamp,bytes16 bridgeTransactionId)");

  address public signerAddress;
  address immutable public metTokenAddress;
  address immutable public primeBlockAddress;

  uint256 public transactionMetLimit = 10_000_000 ether;

  mapping(address => uint256) public nonces;

  event BurnedMET(address indexed sender, bytes16 indexed bridgeTransactionId, uint256 nonce, uint256 data);
  event MintedMET(address indexed sender, bytes16 indexed bridgeTransactionId, uint256 nonce, uint256 data);
  event MintedPrime(address indexed sender, bytes16 indexed bridgeTransactionId, uint256 nonce, uint256 data, uint256 primeTokenId);

  constructor(address _signerAddress, address _metTokenAddress, address _primeBlockAddress) EIP712('MetroBridge', '2') {
    signerAddress = _signerAddress;
    metTokenAddress = _metTokenAddress;
    primeBlockAddress = _primeBlockAddress;
  }

  function setSignerAddress(address _signerAddress) external onlyOwner {
    signerAddress = _signerAddress;
  }

  function setTransactionMetLimit(uint256 _transactionMetLimit) external onlyOwner {
    transactionMetLimit = _transactionMetLimit;
  }

  function buildStructHash(Transaction calldata transaction) private pure returns (bytes32) {
    return keccak256(
      abi.encode(
        TRANSACTION_STRUCT_HASH,
        transaction.sender,
        transaction.operation,
        transaction.data,
        transaction.nonce,
        transaction.expirationTimestamp,
        transaction.bridgeTransactionId
      )
    );
  }

  function verifyTransaction(address sender, Transaction calldata transaction, bytes32 signatureR, bytes32 signatureVS) internal {
    require(sender == transaction.sender, 'Sender does not match');
    require(nonces[transaction.sender]++ == transaction.nonce, 'Invalid nonce');
    require(block.timestamp < transaction.expirationTimestamp, 'Signed transaction expired');

    bytes32 structHash = buildStructHash(transaction);
    bytes32 hash = _hashTypedDataV4(structHash);
    address signer = ECDSA.recover(hash, signatureR, signatureVS);

    require(signer != address(0), 'Invalid signature');
    require(signer == signerAddress, 'Invalid signer');
  }

  function burnMET(Transaction calldata transaction, bytes32 signatureR, bytes32 signatureVS) external {
    require(transaction.operation == Operation.BURN_MET, 'Expected burn MET operation');
    require(transaction.data <= transactionMetLimit, 'Exceeded MET transaction limit');

    verifyTransaction(msg.sender, transaction, signatureR, signatureVS);

    MetToken(metTokenAddress).burnFrom(transaction.sender, transaction.data);
    emit BurnedMET(transaction.sender, transaction.bridgeTransactionId, transaction.nonce, transaction.data);
  }

  function mintMET(Transaction calldata transaction, bytes32 signatureR, bytes32 signatureVS) external {
    require(transaction.operation == Operation.MINT_MET, 'Expected mint MET operation');
    require(transaction.data <= transactionMetLimit, 'Exceeded MET transaction limit');

    verifyTransaction(msg.sender, transaction, signatureR, signatureVS);

    MetToken(metTokenAddress).mint(transaction.sender, transaction.data);
    emit MintedMET(transaction.sender, transaction.bridgeTransactionId, transaction.nonce, transaction.data);
  }

  function mintPrime(Transaction calldata transaction, bytes32 signatureR, bytes32 signatureVS) external {
    require(transaction.operation == Operation.MINT_PRIME, 'Expected mint Prime operation');

    verifyTransaction(msg.sender, transaction, signatureR, signatureVS);

    uint256 primeTokenId = MetroPrimeMintable(primeBlockAddress).mint(transaction.sender, transaction.data);
    emit MintedPrime(transaction.sender, transaction.bridgeTransactionId, transaction.nonce, transaction.data, primeTokenId);
  }
}