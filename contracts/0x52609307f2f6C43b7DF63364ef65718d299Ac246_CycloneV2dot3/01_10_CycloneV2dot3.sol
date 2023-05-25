pragma solidity <0.6 >=0.4.24;

import "./math/SafeMath.sol";
import "./token/IMintableToken.sol";
import "./token/SafeERC20.sol";
import "./utils/Address.sol";
import "./zksnarklib/MerkleTreeWithHistory.sol";
import "./zksnarklib/IVerifier.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract CycloneV2dot3 is MerkleTreeWithHistory, ReentrancyGuard {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public tokenDenomination; // (10K or 100k or 1M) * 10^18
  uint256 public coinDenomination;
  uint256 public initCYCDenomination;
  mapping(bytes32 => bool) public nullifierHashes;
  mapping(bytes32 => bool) public commitments; // we store all commitments just to prevent accidental deposits with the same commitment
  IVerifier public verifier;
  IERC20 public token;
  IMintableToken public cycToken;
  address public treasury;
  address public govDAO;
  uint256 public numOfShares;
  uint256 public lastRewardBlock;
  uint256 public rewardPerBlock;
  uint256 public accumulateCYC;
  uint256 public anonymityFee;

  modifier onlyGovDAO {
    // Start with an governance DAO address and will transfer to a governance DAO, e.g., Timelock + GovernorAlpha, after launch
    require(msg.sender == govDAO, "Only Governance DAO can call this function.");
    _;
  }

  event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp, uint256 cycDenomination, uint256 anonymityFee);
  event Withdrawal(address to, bytes32 nullifierHash, address indexed relayer, uint256 reward, uint256 relayerFee);
  event RewardPerBlockUpdated(uint256 oldValue, uint256 newValue);
  event AnonymityFeeUpdated(uint256 oldValue, uint256 newValue);

  /**
    @dev The constructor
    @param _verifier the address of SNARK verifier for this contract
    @param _merkleTreeHeight the height of deposits' Merkle Tree
    @param _govDAO governance DAO address
  */
  constructor(
    address _govDAO,
    IERC20 _token,
    IMintableToken _cycToken,
    address _treasury,
    uint256 _initCYCDenomination,
    uint256 _coinDenomination,
    uint256 _tokenDenomination,
    uint256 _startBlock,
    IVerifier _verifier,
    uint32 _merkleTreeHeight
  ) MerkleTreeWithHistory(_merkleTreeHeight) public {
    require(address(_token) != address(_cycToken), "token cannot be identical to CYC token");
    verifier = _verifier;
    treasury = _treasury;
    cycToken = _cycToken;
    token = _token;
    govDAO = _govDAO;
    if (_startBlock < block.number) {
      lastRewardBlock = block.number;
    } else {
      lastRewardBlock = _startBlock;
    }
    initCYCDenomination = _initCYCDenomination;
    coinDenomination = _coinDenomination;
    tokenDenomination = _tokenDenomination;
    numOfShares = 0;
  }

  function calcAccumulateCYC() internal view returns (uint256) {
    uint256 reward = block.number.sub(lastRewardBlock).mul(rewardPerBlock);
    uint256 remaining = cycToken.balanceOf(address(this)).sub(accumulateCYC);
    if (remaining < reward) {
      reward = remaining;
    }
    return accumulateCYC.add(reward);
  }

  function updateBlockReward() public {
    uint256 blockNumber = block.number;
    if (blockNumber <= lastRewardBlock) {
      return;
    }
    if (rewardPerBlock != 0) {
      accumulateCYC = calcAccumulateCYC();
    }
    // always update lastRewardBlock no matter there is sufficient reward or not
    lastRewardBlock = blockNumber;
  }

  function cycDenomination() public view returns (uint256) {
    if (numOfShares == 0) {
      return initCYCDenomination;
    }
    uint256 blockNumber = block.number;
    uint256 accCYC = accumulateCYC;
    if (blockNumber > lastRewardBlock && rewardPerBlock > 0) {
      accCYC = calcAccumulateCYC();
    }
    return accCYC.add(numOfShares - 1).div(numOfShares);
  }

  /**
    @dev Deposit funds into the contract. The caller must send (for Coin) or approve (for ERC20) value equal to or `denomination` of this instance.
    @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
  */
  function deposit(bytes32 _commitment) external payable nonReentrant {
    require(!commitments[_commitment], "The commitment has been submitted");
    require(msg.value >= coinDenomination, "insufficient coin amount");
    uint256 refund = msg.value - coinDenomination;
    uint32 insertedIndex = _insert(_commitment);
    commitments[_commitment] = true;
    updateBlockReward();
    uint256 cycDeno = cycDenomination();
    uint256 fee = anonymityFee;
    if (cycDeno.add(fee) > 0) {
      require(cycToken.transferFrom(msg.sender, address(this), cycDeno.add(fee)), "insufficient CYC allowance");
    }
    if (fee > 0) {
      address t = treasury;
      if (t == address(0)) {
        require(cycToken.burn(fee), "failed to burn anonymity fee");
      } else {
        safeTransfer(cycToken, t, fee);
      }
    }
    uint256 td = tokenDenomination;
    if (td > 0) {
      token.safeTransferFrom(msg.sender, address(this), td);
    }
    accumulateCYC += cycDeno;
    numOfShares += 1;
    if (refund > 0) {
      (bool success, ) = msg.sender.call.value(refund)("");
      require(success, "failed to refund");
    }
    emit Deposit(_commitment, insertedIndex, block.timestamp, cycDeno, fee);
  }

  /**
    @dev Withdraw a deposit from the contract. `proof` is a zkSNARK proof data, and input is an array of circuit public inputs
    `input` array consists of:
      - merkle root of all deposits in the contract
      - hash of unique deposit nullifier to prevent double spends
      - the recipient of funds
      - optional fee that goes to the transaction sender (usually a relay)
  */
  function withdraw(bytes calldata _proof, bytes32 _root, bytes32 _nullifierHash, address payable _recipient, address payable _relayer, uint256 _relayerFee, uint256 _refund) external payable nonReentrant {
    require(_refund == 0, "refund is not zero");
    require(!Address.isContract(_recipient), "recipient of cannot be contract");
    require(!nullifierHashes[_nullifierHash], "The note has been already spent");
    require(isKnownRoot(_root), "Cannot find your merkle root"); // Make sure to use a recent one
    require(verifier.verifyProof(_proof, [uint256(_root), uint256(_nullifierHash), uint256(_recipient), uint256(_relayer), _relayerFee, _refund]), "Invalid withdraw proof");

    nullifierHashes[_nullifierHash] = true;
    uint256 td = tokenDenomination;
    if (td > 0) {
      safeTransfer(token, _recipient, td);
    }
    updateBlockReward();
    uint256 relayerFee = 0;
    // numOfShares should be larger than 0
    uint256 cycDeno = accumulateCYC.div(numOfShares);
    if (cycDeno > 0) {
      accumulateCYC -= cycDeno;
      safeTransfer(cycToken, _recipient, cycDeno);
    }
    uint256 cd = coinDenomination;
    if (_relayerFee > cd) {
      _relayerFee = cd;
    }
    if (_relayerFee > 0) {
      (bool success,) = _relayer.call.value(_relayerFee)("");
      require(success, "failed to send relayer fee");
      cd -= _relayerFee;
    }
    if (cd > 0) {
      (bool success,) = _recipient.call.value(cd)("");
      require(success, "failed to withdraw coin");
    }
    numOfShares -= 1;
    emit Withdrawal(_recipient, _nullifierHash, _relayer, cycDeno, relayerFee);
  }

  /** @dev whether a note is already spent */
  function isSpent(bytes32 _nullifierHash) public view returns(bool) {
    return nullifierHashes[_nullifierHash];
  }

  /** @dev whether an array of notes is already spent */
  function isSpentArray(bytes32[] calldata _nullifierHashes) external view returns(bool[] memory spent) {
    spent = new bool[](_nullifierHashes.length);
    for(uint i = 0; i < _nullifierHashes.length; i++) {
      if (isSpent(_nullifierHashes[i])) {
        spent[i] = true;
      }
    }
  }

  /**
    @dev allow governance DAO to update SNARK verification keys. This is needed to
    update keys if tornado.cash update their keys in production.
  */
  function updateVerifier(address _newVerifier) external onlyGovDAO {
    verifier = IVerifier(_newVerifier);
  }

  /** @dev governance DAO can change his address */
  function changeGovDAO(address _newGovDAO) external onlyGovDAO {
    govDAO = _newGovDAO;
  }

  function setRewardPerBlock(uint256 _rewardPerBlock) public onlyGovDAO {
    updateBlockReward();
    emit RewardPerBlockUpdated(rewardPerBlock, _rewardPerBlock);
    rewardPerBlock = _rewardPerBlock;
  }

  function setAnonymityFee(uint256 _fee) public onlyGovDAO {
    emit AnonymityFeeUpdated(anonymityFee, _fee);
    anonymityFee = _fee;
  }

  // Safe transfer function, just in case if rounding error causes pool to not have enough CYCs.
  function safeTransfer(IERC20 _token, address _to, uint256 _amount) internal {
    uint256 balance = _token.balanceOf(address(this));
    if (_amount > balance) {
      _token.safeTransfer(_to, balance);
    } else {
      _token.safeTransfer(_to, _amount);
    }
  }

  function version() public pure returns(string memory) {
    return "2.3";
  }

}