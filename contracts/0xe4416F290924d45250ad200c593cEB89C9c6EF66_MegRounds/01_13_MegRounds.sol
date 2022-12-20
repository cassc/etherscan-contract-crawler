// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./interfaces/IMintableNFT.sol";

contract MegRounds is OwnableUpgradeable, ReentrancyGuardUpgradeable, EIP712Upgradeable, AccessControlUpgradeable {
  /// @dev Sold by type
  mapping(address => uint256) public walletCount;
  /// @dev Price against each round
  uint256 public price;

  uint256[] public startDate;
  uint256[] public endDate;

  uint256 public round1Id;
  uint256 public round1EndId;

  uint256 public round2Id;
  uint256 public round2EndId;


  /// @dev Validator role
  bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
  IMintableNFT public nft;

  /// @dev Time to get the NFT
  uint256 public receiveWindow;
  address public wallet;

  event Buy(address indexed user, uint256 id);
  event Buy(address indexed user, uint256[] ids);
  event Buy(address indexed user, uint256 _fromId, uint256 _toId);
  event CollectETHs(address sender, uint256 balance);
  event ChangeMintableNFT(address mintableNFT);


  /**
   * @dev Upgradable initializer
   * @param _nft NFT contract instance
   */
  function __MegRounds_init(IMintableNFT _nft) external initializer {
    __Ownable_init();
    __AccessControl_init();
    __EIP712_init("MegRounds", "1.0");
    __ReentrancyGuard_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(VALIDATOR_ROLE, _msgSender());
    nft = _nft;
    wallet = 0xad9E57901CF8a4346EB0964fA35B4209d2Da93e2;

    for (uint256 i = 0; i < 3; i++) {
      startDate.push(0);
      endDate.push(0);
    }

  }

  /**
   * @dev Set wallet by owner
   * @param _wallet Wallet address
   */
  function setWallet(address _wallet) external onlyOwner{
    wallet = _wallet;
  }

  function withdrawFunds() external {
    payable(wallet).transfer(address(this).balance);
  }

  /**
   * @dev Update round ids
   * @dev This function is only callable by owner
   * @param _round1Id Start Id
   * @param _round1EndId End id
   */
  function setRound1Id(uint256 _round1Id, uint256 _round1EndId) external onlyOwner{
    round1Id = _round1Id;
    round1EndId = _round1EndId;
  }

  /**
   * @dev Update round 2 ids
   * @dev This function is only callable by owner
   * @param _round2Id Start Id
   * @param _round2EndId End id
   */
  function setRound2Id(uint256 _round2Id, uint256 _round2EndId) external onlyOwner{
    round2Id = _round2Id;
    round2EndId = _round2EndId;
  }

  /**
   * @dev Update Price
   * @dev This function is only callable by owner
   * @param _price New price of NFTs
   */
  function updatePrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  /**
   * @dev Update Date
   * @dev This function is only callable by owner
   * @param _start New start date of round
   * @param _end New end date of round
   * @param _round The round to update dates for
   */
  function updateDates(uint256 _start, uint256 _end, uint256 _round) external onlyOwner {
    startDate[_round] = _start;
    endDate[_round] = _end;
  }

  /**
   * @dev Mint a new NFT for Round 0 for whitelisters
   * @param _fromId Mint from this ID
   * @param _toId Mint to this ID
   * @param _timestamp Timestamp
   * @param _signature Bytes signature
   */
  function round0Buy(uint256 _fromId, uint256 _toId,  uint256 _timestamp, bytes calldata _signature) public {
    require(block.timestamp >= startDate[0] && block.timestamp <= endDate[0], "Invalid time to buy");
    address verifyValidator = recover(msg.sender, _fromId, _toId, _timestamp, _signature);

    require(hasRole(VALIDATOR_ROLE, verifyValidator), "Validator role missing");

    nft.bulkMint(msg.sender, _fromId,_toId);
    emit Buy(msg.sender, _fromId, _toId);
  }

  /**
   * @dev Mint a new NFT for Round 1
   * @param _amount amount of NFT to buy
   */
  function round1Buy(uint256 _amount) public payable {
    require(block.timestamp >= startDate[1] && block.timestamp <= endDate[1], "Invalid time to buy");
    require(round1Id <= round1EndId, "not in the range");
    require(msg.value >= price * _amount, "invalid price");
    require(walletCount[msg.sender] + _amount <= 9, "max limit exceeded");
    walletCount[msg.sender]= walletCount[msg.sender] + _amount;

    for(uint256 id = round1Id; id < round1Id + _amount; id++){
      nft.mint(msg.sender, id);
    }

    round1Id = round1Id + _amount;
  }

  /**
   * @dev Mint a new NFT for Round 2
   * @param _amount amount of NFT
   */
  function round2Buy( uint256 _amount) public payable {
    require(block.timestamp >= startDate[2] && block.timestamp <= endDate[2], "Invalid time to buy");
    require(round2Id + _amount <= round2EndId, "not in the range");
     require(msg.value >= price * _amount, "invalid price");
    require(walletCount[msg.sender] + _amount <= 9, "max limit exceeded");
    walletCount[msg.sender]= walletCount[msg.sender] + _amount;

    for(uint256 id = round2Id; id < round2Id + _amount; id++){
      nft.mint(msg.sender, id);
    }

    round2Id = round2Id + _amount;
  }

  /**
   * @dev verify signature
   * @param _wallet Wallet address
   * @param _fromId Mint from this ID
   * @param _toId Mint to this ID
   * @param _timestamp Timestamp
   * @param _signature Bytes signature
   */
  function recover(
    address _wallet,
    uint256 _fromId,
    uint256 _toId,
    uint256 _timestamp,
    bytes calldata _signature
  ) public view returns (address) {
    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(keccak256("MegRounds(address _wallet,uint256 _fromId,uint256 _toId,uint256 _timestamp)"), _wallet, _fromId,_toId, _timestamp)
      )
    );
    return (ECDSAUpgradeable.recover(digest, _signature));
  }
}