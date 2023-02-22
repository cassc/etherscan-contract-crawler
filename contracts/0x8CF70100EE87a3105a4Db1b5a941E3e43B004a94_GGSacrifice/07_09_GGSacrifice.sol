//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract GGSacrifice is Ownable {
  using ECDSA for bytes32;

  State public state;
  IERC721 public seekers;
  address public deadAddress = address(0x000000000000000000000000000000000000dEaD);

  address private signer;

  enum State {
    Closed,
    Open
  }

  event SeekerSacrificed(address indexed from, uint256 indexed amount, bytes encoded);
  event ClaimOpen();
  event ClaimClosed();
  event SeekersUpdated(address indexed _address);

  constructor(IERC721 _seekers, address _signer) {
    seekers = _seekers;
    signer = _signer;
  }

  /* @dev: Allows no contracts
   */
  modifier noContract() {
    require(msg.sender == tx.origin, "contract not allowed");
    _;
  }

  /* @dev: Update the approached Seekers NFT address
   * @param: _seekers - Seekers address to update to
   */
  function setSeekers(IERC721 _seekers) external onlyOwner {
    seekers = _seekers;
    emit SeekersUpdated({_address: address(_seekers)});
  }

  /* @dev: Update the address of the signing wallet to sign message for token
   * @param: _signer - public address of new signer
   */
  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
  }

  /* @dev: Sets claim to open
   */
  function setOpen() external onlyOwner {
    state = State.Open;
    emit ClaimOpen();
  }

  /* @dev: Sets claim to closed
   */
  function setClosed() external onlyOwner {
    state = State.Closed;
    emit ClaimClosed();
  }

  function _verify(
    bytes memory message,
    bytes calldata signature,
    address account
  ) internal pure returns (bool) {
    return keccak256(message).toEthSignedMessageHash().recover(signature) == account;
  }

  // Description
  // Those Seekers which are pledged are now able to be sacrificed.
  // Those who sacrifice their Seekers are gifted an amulet in return (to happen later on ROOT)
  /* @dev: Seekers sacrificed and sent to burn wallet
   * @param: encoded - bytes of encoded data (wallet, contractAddress, tokenIds[])
   * @param: token  - signer signature as bytes
   */
  function sacrifice(bytes calldata encoded, bytes calldata token) external noContract {
    require(state == State.Open, "sacrifice not open");
    // get values out of ABI encoded string
    (address wallet, address contractAddress, uint256[] memory tokenIds) = abi.decode(
      encoded,
      (address, address, uint256[])
    );
    // fail if wallet is not msg.sender
    require(wallet == msg.sender, "invalid wallet");
    // fail if contract does not match that of the token
    require(contractAddress == address(this), "invalid contract");
    // fail if token cannot be verified as signed by signer
    require(_verify(encoded, token, signer), "invalid token");
    // fail if token array is not length 1, 5 or 15
    require(tokenIds.length == 1 || tokenIds.length == 5 || tokenIds.length == 15, "invalid tokenId array");

    for (uint256 i = 0; i < tokenIds.length; i++) {
      seekers.safeTransferFrom(msg.sender, deadAddress, tokenIds[i]);
    }
    emit SeekerSacrificed({from: msg.sender, amount: tokenIds.length, encoded: encoded});
  }
}