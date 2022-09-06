// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "solmate/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./Particles.sol";
import "./Errors.sol";

// Non-reusable dumb implementation of merkle minter for the particle #1

/*  

                 :-:..        
              :*%@@*#@%+:     
      :-:. .+*%@@@@%[email protected]@@@#:   
   .##%@@%*#@@@@@@@%%@@@@@#   
   -%@@@@@@@@@%##%@@%@@@@@@-  
  =%@@@@@@@@@@#.  *@@@@@@@@*. 
  [email protected]@@@@@@@@@@@%: .%@@@@%#*-  
  :@@@@@@@@@@@@@%-#@@@@%#*:.  
   #@@@%@%%@@@@@@@%@@%-.      
   .*@%#=..=%@@@@@%%@#.       
     :-.     =%%@@%#*.        
               =#%%%*         
               ..-*%#.        
                   ..         

*/

contract MerkleMinter is Ownable, ReentrancyGuard {
  bytes32 public merkleRoot;
  Particles public particles;
  uint256 private immutable tokenId;

  // track if wallet has already minted (one mint per wallet)
  mapping(address => bool) public minted;

  // interface labs multisig
  address public constant beneficiary =
    0x0F789fbca6D2fB9207B795154b04aa8a02b9d40d;

  // mint config
  uint256 public constant mintPrice = 0.21 ether;
  uint256 public constant mintMerklePrice = 0.07 ether;
  uint256 public immutable mintStart;

  constructor(bytes32 _merkleRoot, address _particles, uint256 _mintStart, uint256 _tokenId) {
    if (_tokenId == 0) revert Errors.UnknownParticle();
    merkleRoot = _merkleRoot;
    particles = Particles(_particles);
    tokenId = _tokenId;
    mintStart = _mintStart;
  }

  modifier enough(uint256 _mintPrice) {
    if (msg.value < _mintPrice) revert Errors.InsufficientFunds();
    _;
  }

  modifier started() {
    if (block.number < mintStart) revert Errors.MintNotStarted();
    _;
  }

  function allowListed(address wallet, bytes32[] calldata proof)
    public
    view
    returns (bool)
  {
    return
      MerkleProof.verify(
        proof,
        merkleRoot,
        keccak256(abi.encodePacked(wallet))
      );
  }

  function mintWithProof(
    bytes32[] calldata _proof
  ) external payable enough(mintMerklePrice) started nonReentrant {
    if (!allowListed(msg.sender, _proof)) revert Errors.NotAllowListed();
    _mintLogic();
  }

  function mintPublic()
    external
    payable
    enough(mintPrice)
    started
    nonReentrant
  {
    _mintLogic();
  }

  function _mintLogic() internal {
    if (minted[msg.sender]) revert Errors.AlreadyMinted();

    minted[msg.sender] = true;
    particles.mint(msg.sender, tokenId, 1);
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    (bool transferTx, ) = beneficiary.call{value: balance}("");
    if (!transferTx) {
      revert Errors.WithdrawTransfer();
    }
  }
}