// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./NutsCoin.sol";
import "./DeezNuts.sol";


contract DeezNutsCasino is Ownable, IERC721Receiver, Pausable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeMath for uint128;
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint72 dailyRate;
    uint40 value;
    address owner;
  }


  event GambleOutcome(address sender, uint128 wonAmount);

  // reference to the DeezNuts NFT contract
  DeezNuts deezNutsNFT;

  // reference to the $NUTS contract for minting $NUTS earnings
  NutsCoin nuts;

  // maps tokenId to stake
  mapping(uint16 => Stake) public casinoEmployees; 

  mapping(address => uint16[]) public ownershipMapping;

  // Each nuts earns 0 $NUTS per day
  uint256 public DAILY_NUTS_RATE = 0 ether;

  // there will only ever be (roughly) 6 billion $NUTS earned through staking
  uint256 public MAXIMUM_GLOBAL_NUTS = 6000000000 ether;

  // amount of $NUTS earned so far
  uint256 public totalNutsEarned;

  // the last time $NUTS was claimed
  uint256 public lastClaimTimestamp;

  uint256 public totalStaked;

  mapping(string => bytes32) public rootHashes;

  // emergency rescue to allow unstaking without any checks but without $NUTS
  bool public rescueEnabled = false;

  /**
   * @param _deezNuts reference to the DeezNuts NFT contract
   * @param _nuts reference to the $NUTS token
   */
  constructor(address _deezNuts, address _nuts) { 
    deezNutsNFT = DeezNuts(_deezNuts);
    nuts = NutsCoin(_nuts);
    totalStaked = 0;
    rootHashes["casinoBossRoot"] = 0xfa02561f4779941bd09da0d95b8cbe7480cc5e25f485cb9edae925fac99104d3;
    rootHashes["floorManagerRoot"] = 0xcd47c4886790fefc6bb37a6b059204c9203fe85fbd4582588497606a140876bd;
    rootHashes["blueNutRoot"] = 0xdd60bd53a57e91693a9cb50bde0c1f5305359d4d39038e53901d6b19b5a2245a;
    rootHashes["chefRoot"] = 0x29896d4e6dea9fcba447d1a01707916f541260e79b3f1d4eea4d1478740bd77f;
    rootHashes["djRoot"] = 0xbf1d196a3f6575e0131e833d783e01c25c32801c6ded2c0828b84656eb417aba;
    rootHashes["bartenderRoot"] = 0x5df7f1188bb0d1ae32808007d67dcc6f66cf238230653eb558ab508848f9dfb9;
    rootHashes["impersonatorRoot"] = 0xdacb828b187ddfab251c00861ea62b71b4e1f32590b080249a2b7cca85b3d71e;
    rootHashes["dealerRoot"] = 0xb2b2d91dec60669d941f038c2b3d924a2ce1ef63de2c74dec02bd51abe7b7a2d;
    rootHashes["slotRoot"] = 0x77ca07f4452ea3e642a01a4807e18e4d0d2f167278ec2e4f6f138f64286dfaba;
    rootHashes["weddingOfficiantRoot"] = 0x31ebcfd78167e3016e69ed146d132d80fb0b34804b7af27e13af0aeb3c7c4058;
    rootHashes["busDriverRoot"] = 0x6e13c174c07bed341d3327089c982860b78900ca20d8dd8d297599ffdb76c9ea;
    rootHashes["penCollectorRoot"] = 0xb338e9eb86a679b212873dd4904fb9d7aa25d3923e55886236edb2546be72a3b;
    rootHashes["phMonitorRoot"] = 0xba9276a497ed4baca93bda576c688d3573631f1a0cdc0ae44af477ab34bb6887;
  }

  function setNewMax(uint256 newMaxGlobal) public onlyOwner {
    MAXIMUM_GLOBAL_NUTS = newMaxGlobal;
  }

  function updateCasinoJobRates(string calldata title, bytes32 newRoot) public onlyOwner {
    rootHashes[title] = newRoot;
  }

  function getAllStakedForAddress(address _address) public view returns (uint16[] memory allStaked){
    return ownershipMapping[_address];
  }

  function getTotalCalimable(address _address) public view returns (uint128 totalClaimable) {
    uint16[] memory tokenIds = ownershipMapping[_address];

    for (uint i = 0; i < tokenIds.length; i++) {
      Stake memory stake = casinoEmployees[tokenIds[i]];
      require(stake.owner == _address, "Not the stake owner");

      uint128 owed = 0;

      if (totalNutsEarned < MAXIMUM_GLOBAL_NUTS) {
        owed = uint128(((block.timestamp.sub(stake.value)).mul(stake.dailyRate)).div(1 days));
      } else if (stake.value > lastClaimTimestamp) {
        owed = 0; // $NUTS production stopped already
      } else {
        owed = uint128((lastClaimTimestamp.sub(stake.value)).mul(stake.dailyRate / 1 days)); // stop earning additional $NUTS if it's all been earned
      }

      totalClaimable += owed;
    }

  }

  function getDailyRateForToken(uint256 tokenId, bytes32[] calldata employementProof) public view returns (uint72 dailyRate){

        bytes32 leaf = keccak256(abi.encodePacked(Strings.toString(tokenId)));

        dailyRate = 420 ether;
        if ( MerkleProof.verify(employementProof, rootHashes["casinoBossRoot"], leaf) ) {
            dailyRate = 3318 ether;
        } else if (MerkleProof.verify(employementProof, rootHashes["floorManagerRoot"], leaf)) {
            dailyRate = 3101 ether;
        } else if (MerkleProof.verify(employementProof, rootHashes["blueNutRoot"], leaf)) {
            dailyRate = 2883 ether;
        } else if (MerkleProof.verify(employementProof, rootHashes["chefRoot"], leaf)) {
            dailyRate = 2658 ether;
        } else if (MerkleProof.verify(employementProof, rootHashes["djRoot"], leaf)) {
            dailyRate = 2449 ether;
        } else if (MerkleProof.verify(employementProof, rootHashes["bartenderRoot"], leaf)) {
            dailyRate = 2231 ether;
        } else if (MerkleProof.verify(employementProof, rootHashes["impersonatorRoot"], leaf)) {
            dailyRate = 2014 ether;
        } else if (MerkleProof.verify(employementProof, rootHashes["dealerRoot"], leaf)) {
            dailyRate = 1797 ether;
        } else if (MerkleProof.verify(employementProof, rootHashes["slotRoot"], leaf)) {
            dailyRate = 1579 ether;
        } else if (MerkleProof.verify(employementProof, rootHashes["weddingOfficiantRoot"], leaf)) {
            dailyRate = 1362 ether;
        } else if (MerkleProof.verify(employementProof, rootHashes["busDriverRoot"], leaf)) {
            dailyRate = 1145 ether;
        } else if (MerkleProof.verify(employementProof, rootHashes["penCollectorRoot"], leaf)) {
            dailyRate = 927 ether;
        } else if (MerkleProof.verify(employementProof, rootHashes["phMonitorRoot"], leaf)) {
            dailyRate = 710 ether;
        }
    }

  /** STAKING */
  /**
   * adds DeezNuts NFT to the CasinoEmployees (staking)
   * @param account the address of the staker
   * @param tokenIds the IDs of the Sheep and Wolves to stake
   */
  function addManyToCasino(address account, uint16[] calldata tokenIds, bytes32[][] calldata employmentProof) external whenNotPaused nonReentrant {
    require(account == _msgSender(), "Rechek sender of transaction");
    require(tokenIds.length > 0, "No tokens sent"); 

    for (uint i = 0; i < tokenIds.length; i++) {
        require(deezNutsNFT.ownerOf(tokenIds[i]) == _msgSender(), "Token isn't yours!");
        deezNutsNFT.transferFrom(_msgSender(), address(this), tokenIds[i]);
        _addTokenToCasino(account, tokenIds[i], employmentProof[i]);
        ownershipMapping[account].push(tokenIds[i]);
    }

    totalStaked += tokenIds.length;
    nuts.mint(msg.sender, tokenIds.length * 1000000000000000000);
  }

  /**
   * adds a single Sheep to the Barn
   * @param account the address of the staker
   * @param tokenId the ID of the Sheep to add to the Barn
   */
  function _addTokenToCasino(address account, uint16 tokenId, bytes32[] calldata proofOfEmployment) internal whenNotPaused _updateEarnings {
    uint72 tokenDailyRate = getDailyRateForToken(tokenId, proofOfEmployment);
    casinoEmployees[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint40(block.timestamp),
      dailyRate: tokenDailyRate
    });
    DAILY_NUTS_RATE += tokenDailyRate;
  }

  /** CLAIMING / UNSTAKING */

  /**
   * realize $NUTS earnings and optionally unstake tokens from the Casino
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   * @param gambleOption int to determine withdrawal risk
   */
  function claimManyFromCasino(uint16[] calldata tokenIds, bool unstake, uint256 gambleOption) external nonReentrant whenNotPaused _updateEarnings {
    require(0 < gambleOption && gambleOption < 5, "Gamble option has to be 1, 2 or 3. Only use 4 if you don't want any bonus");
    
    uint128 owed;
    for (uint i = 0; i < tokenIds.length; i++) {
      owed += _claimNutFromCasino(tokenIds[i], unstake);
    }

    // remove unstaked from ownership mapping
    if (unstake) {
          if (tokenIds.length == ownershipMapping[_msgSender()].length) {
            ownershipMapping[_msgSender()] = new uint16[](0);
          } else {
            uint16[] memory remainingStaked = new uint16[](ownershipMapping[_msgSender()].  length - tokenIds.length);
            uint16[] memory stakedTokens = ownershipMapping[_msgSender()];
            uint index = 0;
            for (uint i = 0; i < stakedTokens.length; i++) {
              bool keepIt = true;
              for (uint j = 0; j < tokenIds.length; j++) {
                if (tokenIds[j] == stakedTokens[i]) {
                  keepIt = false;
                }
              }
              if (keepIt) {
                remainingStaked[index] = stakedTokens[i];
                index += 1;
              }
            }
            ownershipMapping[_msgSender()] = remainingStaked;
          }
          totalStaked -= tokenIds.length;
    }

    if (owed == 0) return;
    uint128 bonus;
    if (gambleOption == 1) {
      bonus = owed * 25 / 100;
      owed += bonus;
      totalNutsEarned += bonus;
    } else if (gambleOption == 2) {
      if (random(tokenIds[0]) % 100 <= 60) {
        bonus = owed * 75 / 100;
        owed += bonus;
        totalNutsEarned += bonus;
      }
    } else if (gambleOption == 3) {
      if (random(tokenIds[0]) % 4 == 0) {
        bonus = owed * 25 / 100;
        owed -= bonus;
        totalNutsEarned -= bonus;
      } else {
        totalNutsEarned += owed;
        owed += owed;
      }
    } else if (gambleOption == 4) {
      // to be used in case contract is close to empty and people couldn't withdraw with the 25% bonus
    }


    nuts.mint(_msgSender(), owed);
    emit GambleOutcome(_msgSender(), owed);
  }

  /**
   * realize $NUTS earnings for a single Nut
   * @param tokenId the ID of the Sheep to claim earnings from
   * @param unstake whether or not to unstake the Sheep
   * @return owed - the amount of $NUTS earned
   */
  function _claimNutFromCasino(uint16 tokenId, bool unstake) internal returns (uint128 owed) {
    Stake memory stake = casinoEmployees[tokenId];
    require(stake.owner == _msgSender(), "Not the stake owner");

    if (totalNutsEarned < MAXIMUM_GLOBAL_NUTS) {
        owed = uint128(((block.timestamp.sub(stake.value)).mul(stake.dailyRate)).div(1 days));
      } else if (stake.value > lastClaimTimestamp) {
        owed = 0; // $NUTS production stopped already
      } else {
        owed = uint128((lastClaimTimestamp.sub(stake.value)).mul(stake.dailyRate / 1 days)); // stop earning additional $NUTS if it's all been earned
      }

    if (unstake) {
      deezNutsNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Nut
      DAILY_NUTS_RATE -= stake.dailyRate;
      delete casinoEmployees[tokenId];
    } else {
      casinoEmployees[tokenId] = Stake({
        owner: stake.owner,
        tokenId: uint16(tokenId),
        value: uint40(block.timestamp),
        dailyRate: stake.dailyRate
      });
    }
  }


  /**
   * emergency unstake tokens
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function rescue(uint16[] calldata tokenIds) external nonReentrant {
    require(rescueEnabled, "RESCUE DISABLED");
    uint16 tokenId;
    Stake memory stake;
    for (uint i = 0; i < tokenIds.length; i++) {
        tokenId = tokenIds[i];
        stake = casinoEmployees[tokenId];
        require(stake.owner == _msgSender(), "Only owner can withdraw");
        deezNutsNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Nut
        delete casinoEmployees[tokenId];
        DAILY_NUTS_RATE -= stake.dailyRate;
    }                                                       
  }

  /** ACCOUNTING */
  /**
   * tracks $NUTS earnings to ensure it stops once 6.9 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalNutsEarned < MAXIMUM_GLOBAL_NUTS) {
      totalNutsEarned += 

        (block.timestamp - lastClaimTimestamp)
        * DAILY_NUTS_RATE / 1 days; 

      lastClaimTimestamp = block.timestamp;
    }
    _;
  }

  /** ADMIN */

  /**
   * allows owner to enable "rescue mode"
   * simplifies accounting, prioritizes tokens out in emergency
   */
  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  /**
   * enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /** READ ONLY */

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens to Casino directly");
      return IERC721Receiver.onERC721Received.selector;
    }

  /**
   * generates a pseudorandom number
   * @param seed a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
  function random(uint256 seed) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      block.timestamp,
      seed
    )));
  }
}