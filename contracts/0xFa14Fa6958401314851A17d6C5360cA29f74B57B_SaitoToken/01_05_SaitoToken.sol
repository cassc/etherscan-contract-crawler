// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;

//import "./lib/openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SaitoToken is ERC20 {
  address owner1;
  address owner2;
  address owner3;
  uint32 public mintingNonce = 0;
  
  constructor (string memory name_, string memory symbol_) ERC20(name_, symbol_) {
    // The tests will replace these keys in the contract binary with the test owner keys.
    // These must be replaced with the real owner keys during deployment, however this will
    // also cause the tests to break, so please do not commit changes to these.
    owner1 = 0x41Afad17a0B0e4135022CcC448D7FCe0C6469d16;
    owner2 = 0x5aC2F364482759C54c9A08B8a16F5723C8eD4Cf0;
    owner3 = 0xA357D59D38dD963d1930efb55e1a262b42c53748;
  }
  function isOwner() public view returns (bool) {
    return msg.sender == owner1 || msg.sender == owner2 || msg.sender == owner3;
  }
  
  function incrementNonce() external {
    require(isOwner(), "Only owners can increment the nonce");
    mintingNonce++;
  }
  
  /**
  * Creates new tokens. Can only be called by one of the three owners. Includes
  * signatures from each of the 3 owners.
  * The signed messages is a bytes32(equivalent to uint256), which includes the
  * nonce and the amount intended to be minted. The network ID is not included,
  * which means owner keys cannot be shared across networks because of the
  * possibility of replay. The lower 128 bits of the signedMessage contain
  * the amount to be minted, and the upper 128 bits contain the nonce.
  */
   
  function mint(bytes32 signedMessage, uint8 sigV1, bytes32 sigR1, bytes32 sigS1, uint8 sigV2, bytes32 sigR2, bytes32 sigS2, uint8 sigV3, bytes32 sigR3, bytes32 sigS3) external {
    require(isOwner(), "Must be owner");
    require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", signedMessage)), sigV1, sigR1, sigS1) == owner1, "Not approved by owner1");
    require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", signedMessage)), sigV2, sigR2, sigS2) == owner2, "Not approved by owner2");
    require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", signedMessage)), sigV3, sigR3, sigS3) == owner3, "Not approved by owner3");
    // cast message to a uint256
    uint256 signedMessageUint256 = uint256(signedMessage);
    // bitwise-and the lower 128 bits of message to get the amount
    uint256 amount = signedMessageUint256 & (2**128-1);
    // right-shift the message by 128 bits to get the nonce in the correct position
    signedMessageUint256 = signedMessageUint256 / (2**128);
    // bitwise-and the message by 128 bits to get the nonce
    uint32 nonce = uint32(signedMessageUint256 & (2**128-1));
    require(nonce == mintingNonce, "nonce must match");
    mintingNonce += 1;
    _mint(owner1, amount);
    emit Minted(owner1, amount);
  }
  
  function burn(uint256 amount, bytes memory data) external {
    super._burn(msg.sender, amount);
    emit Burned(msg.sender, amount, data);
  }
  event Minted(address receiver, uint256 amount);
  event Burned(address from, uint256 amount, bytes data);
  //event Minted(address indexed to, uint256 amount);
  //event Burned(address indexed from, uint256 amount, bytes data);
}