//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

//       ___          ___          ___                     ___          ___                   ___          ___       ___
//      /\  \        /\__\        /\  \         ___       /\__\        /\  \                 /\__\        /\  \     /\  \
//     /::\  \      /:/  /       /::\  \       /\  \     /::|  |      /::\  \               /::|  |      /::\  \    \:\  \
//    /:/\:\  \    /:/__/       /:/\:\  \      \:\  \   /:|:|  |     /:/\ \  \             /:|:|  |     /:/\:\  \    \:\  \
//   /:/  \:\  \  /::\  \ ___  /::\~\:\  \     /::\__\ /:/|:|  |__  _\:\~\ \  \           /:/|:|  |__  /::\~\:\  \   /::\  \
//  /:/__/ \:\__\/:/\:\  /\__\/:/\:\ \:\__\ __/:/\/__//:/ |:| /\__\/\ \:\ \ \__\         /:/ |:| /\__\/:/\:\ \:\__\ /:/\:\__\
//  \:\  \  \/__/\/__\:\/:/  /\/__\:\/:/  //\/:/  /   \/__|:|/:/  /\:\ \:\ \/__/         \/__|:|/:/  /\/__\:\ \/__//:/  \/__/
//   \:\  \           \::/  /      \::/  / \::/__/        |:/:/  /  \:\ \:\__\               |:/:/  /      \:\__\ /:/  /
//    \:\  \          /:/  /       /:/  /   \:\__\        |::/  /    \:\/:/  /               |::/  /        \/__/ \/__/
//     \:\__\        /:/  /       /:/  /     \/__/        /:/  /      \::/  /                /:/  /
//      \/__/        \/__/        \/__/                   \/__/        \/__/                 \/__/

// Contract by: @backseats_eth


// This is a free claimable "airdrop" contract that allows holders at the time of a snapshot to claim the level of their holdings plus everything below it.
contract ChainsAirdrop is ERC1155, Ownable {
  using ECDSA for bytes32;

  uint private constant MEGADIAMOND = 1;
  uint private constant DIAMONDM = 2;
  uint private constant DIAMONDF = 3;
  uint private constant PLATINUM = 4;
  uint private constant GOLDM = 5;
  uint private constant GOLDF = 6;
  uint private constant BASE = 7;

  bool public mintEnabled;

  // The address of the private key that signs a combination of the address and amount of Chains held as signatures for the mint.
  // NOTE: Always ensure you update your private key environment variable between testnet and mainnet deploys.
  address public systemAddress;

  // Tracks if the airdrop recipient has claimed.
  mapping(address => bool) public hasMinted;

  // Constructor

  constructor(address _systemAddress) ERC1155("https://gateway.pinata.cloud/ipfs/QmRjDoufviftnfQU3xaemNpGuG7co9ub3HJ4LCpdmvYnVH/{id}") {
    systemAddress = _systemAddress;
  }

  // Mint Function

  /// @notice This function can only be called from the aidrop site and will fail if you attempt to call it from Etherscan since it requires the `_signature` parameter.
  function mint(uint256 _ownerCount, bool _diamondMens, bool _goldMens, bytes calldata _signature) external {
    require(mintEnabled, "Mint disabled");
    require(!hasMinted[msg.sender], "Already minted");
    hasMinted[msg.sender] = true;

    // On the server, we send in a signature comprising of the msg.sender and the amount the address held at the time of the snapshot.
    require(isValidSignature(keccak256(abi.encodePacked(msg.sender, _ownerCount)), _signature), "Invalid signature");

    if (_ownerCount > 29) {
      mintMegaDiamond(_diamondMens, _goldMens);

    } else if (_ownerCount > 9 && _ownerCount < 30) {
      mintDiamond(_diamondMens, _goldMens);

    } else if (_ownerCount > 5 && _ownerCount < 10) {
      mintPlatinum(_goldMens);

    } else if (_ownerCount > 2 && _ownerCount < 6) {
      mintGold(_goldMens);

    } else {
      mintBase();
    }
  }

  // Private Functions

  function mintMegaDiamond(bool _diamondMens, bool _goldMens) private {
    mint(MEGADIAMOND);
    mintDiamond(_diamondMens, _goldMens);
  }

  function mintDiamond(bool _diamondMens, bool _goldMens) private {
    mint(_diamondMens ? DIAMONDM : DIAMONDF);
    mintPlatinum(_goldMens);
  }

  function mintPlatinum(bool _mens) private {
    mint(PLATINUM);
    mintGold(_mens);
  }

  function mintGold(bool _mens) private {
    mint(_mens ? GOLDM : GOLDF);
    mintBase();
  }

  function mintBase() private {
    mint(BASE);
  }

  function mint(uint _type) private {
    _mint(msg.sender, _type, 1, "");
  }

  function isValidSignature(bytes32 hash, bytes calldata signature) internal view returns (bool) {
    require(systemAddress != address(0), "Missing system address");
    bytes32 signedHash = hash.toEthSignedMessageHash();
    return signedHash.recover(signature) == systemAddress;
  }

  // Ownable functions

  // Sets the system address that corresponds to the private key being used in the API. For good measure and good security, make sure your systemAddress and the contract's owner are different addresses and private keys so there isn't a single point of failure.
  function setSystemAddress(address _systemAddress) external onlyOwner {
    systemAddress = _systemAddress;
  }

  // Enables/disables mint
  function setMintEnabled(bool _val) external onlyOwner {
    mintEnabled = _val;
  }

 }