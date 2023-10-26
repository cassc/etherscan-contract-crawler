/////////////////////////////////////////////////////////////////////////////////////
//
//  SPDX-License-Identifier: MIT
//
//  ███    ███  ██████  ███    ██ ███████ ██    ██ ██████  ██ ██████  ███████
//  ████  ████ ██    ██ ████   ██ ██       ██  ██  ██   ██ ██ ██   ██ ██
//  ██ ████ ██ ██    ██ ██ ██  ██ █████     ████   ██████  ██ ██████  █████
//  ██  ██  ██ ██    ██ ██  ██ ██ ██         ██    ██      ██ ██      ██
//  ██      ██  ██████  ██   ████ ███████    ██    ██      ██ ██      ███████
//  
//  
//  ██████  ██    ██ ███████ ███████ ███████ ██████      ██████
//  ██   ██ ██    ██ ██      ██      ██      ██   ██          ██
//  ██████  ██    ██ █████   █████   █████   ██████       █████
//  ██   ██ ██    ██ ██      ██      ██      ██   ██     ██
//  ██████   ██████  ██      ██      ███████ ██   ██     ███████
//
//  https://moneypipe.xyz
//
/////////////////////////////////////////////////////////////////////////////////////
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
contract Buffer2 is Initializable {

  using SafeERC20 for IERC20;
  mapping (address => uint) public withdrawn;                                     // total ETH withdrawn
  mapping (address => mapping (address => uint)) public token_withdrawn;          // user ERC20 token withdrawn (for each token addressand user account)
  mapping (address => uint) public total_token_withdrawn;                         // total ERC20 token withdrawn (for each address)
  bytes32 private root;                                                           // Merkle root
  bytes32 private id;                                                             // IPFS cid hash digest
  bool public encoding;                                                           // IPFS cid encoding
  uint public totalReceived;                                                      // total ETH received

  // initialize the buffer pipe with merkle root and CID of the JSON that stores the members list (which will be used to construct the merkle tree)
  function initialize(bytes32 _root, bytes32 _cidDigest, bool _cidEncoding) initializer public {
    root = _root;
    id = _cidDigest;
    encoding = _cidEncoding;
  }

  // track totalreceived whenever an ETH payment is made
  receive () external payable {
    totalReceived += msg.value;
  }

  // account: the account to withdraw to (must be part of the merkle tree
  // amount: the amount (out of 10^12) of shares in the split owned by the account
  // proof: merkle proof containing the account and split
  // tokens: an array of ERC20 addresses
  //    - if empty, only withdraw ETH
  //    - if not empty, withdraw from the ETH balance AND from the balance for the specified ERC20 tokens
  function withdraw(address account, uint256 amount, bytes32[] calldata proof, address[] calldata tokens) external {

    // 1. verify merkle proof
    bytes32 hash = keccak256(abi.encodePacked(account, amount));
    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];
      if (hash <= proofElement) {
        hash = _hash(hash, proofElement);
      } else {
        hash = _hash(proofElement, hash);
      }
    }
    require(hash == root, "1");

    // 2. calculate amount to withdraw based on "amount" (out of 1,000,000,000,000)
    uint payment = totalReceived * amount / 10**12 - withdrawn[account];
    withdrawn[account] += payment;

    // 3. withdraw ETH
    _transfer(account, payment);

    // 4. withdraw erc20 tokens
    for(uint i=0; i<tokens.length; i++) {
      address token = tokens[i];
      uint total_token_received = IERC20(token).balanceOf(address(this)) + total_token_withdrawn[token];
      uint token_payment = total_token_received * amount / 10**12 - token_withdrawn[token][account];
      token_withdrawn[token][account] += token_payment;
      total_token_withdrawn[token] += token_payment;
      IERC20(token).safeTransfer(account, token_payment);
    }

  }

  // Calculate IPFS CID from id and encoding
  function cid() public view returns (string memory) {
    bytes32 data = bytes32(id);
    bytes memory alphabet = bytes("abcdefghijklmnopqrstuvwxyz234567");
    bytes memory _cid = bytes(encoding ? "bafybei" : "bafkrei");
    uint bits = 2;
    uint buffer = 24121888;
    uint bitsPerChar = 5;
    uint mask = uint((1 << bitsPerChar) - 1);
    for(uint i=0; i<data.length; ++i) {
      bytes1 char = bytes1(bytes32(id << (8*i)));
      buffer = (uint32(buffer) << 8) | uint(uint8(char));
      bits += 8;
      while (bits > bitsPerChar) {
        bits -= bitsPerChar;
        _cid = abi.encodePacked(_cid, alphabet[mask & (buffer >> bits)]);
      }
    }
    if (bits > 0) {
      _cid = abi.encodePacked(_cid, alphabet[mask & (buffer << (bitsPerChar-bits))]);
    }
    return string(_cid);
  }

  // memory optimization from: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/3039
  function _hash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
    assembly {
      mstore(0x00, a)
      mstore(0x20, b)
      value := keccak256(0x00, 0x40)
    }
  }
  // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
  error TransferFailed();
  function _transfer(address to, uint256 amount) internal {
    bool callStatus;
    assembly {
      callStatus := call(gas(), to, amount, 0, 0, 0, 0)
    }
    if (!callStatus) revert TransferFailed();
  }
}