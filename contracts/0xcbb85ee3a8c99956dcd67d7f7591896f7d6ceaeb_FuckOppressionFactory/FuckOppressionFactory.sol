/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

/*
*  ______          _       ____                                _             
* |  ____|        | |     / __ \                              (_)            
* | |__ _   _  ___| | __ | |  | |_ __  _ __  _ __ ___  ___ ___ _  ___  _ __  
* |  __| | | |/ __| |/ / | |  | | '_ \| '_ \| '__/ _ \/ __/ __| |/ _ \| '_ \ 
* | |  | |_| | (__|   <  | |__| | |_) | |_) | | |  __/\__ \__ \ | (_) | | | |
* |_|   \__,_|\___|_|\_\  \____/| .__/| .__/|_|  \___||___/___/_|\___/|_| |_|
*                               | |   | |                                    
*                               |_|   |_|  
*
* made with ♡ by GNSPS
* 
* This factory will deploy a dummy, unoperational version of the latest Tornado Cash main contract 
* and associate it with your address. It pays you back for the costs of deployment if it still
* has funds.
*
* Use at their risk.
*/

//         ,----,                                                        
//       ,/   .`|                                                        
//     ,`   .'  :                               ___                      
//   ;    ;     /            ,--,             ,--.'|_                    
// .'___,/    ,'       .---,--.'|             |  | :,'           __  ,-. 
// |    :     |       /. ./|  |,     .--.--.  :  : ' :         ,' ,'/ /| 
// ;    |.';  ;    .-'-. ' `--'_    /  /    .;__,'  /    ,---. '  | |' | 
// `----'  |  |   /___/ \: ,' ,'|  |  :  /`.|  |   |    /     \|  |   ,' 
//     '   :  ;.-'.. '   ' '  | |  |  :  ;_ :__,'| :   /    /  '  :  /   
//     |   |  /___/ \:     |  | :   \  \    `.'  : |__.    ' / |  | '    
//     '   :  .   \  ' .\  '  : |__  `----.   |  | '.''   ;   /;  : |    
//     ;   |.' \   \   ' \ |  | '.'|/  /`--'  ;  :    '   |  / |  , ;    
//     '---'    \   \  |--";  :    '--'.     /|  ,   /|   :    |---'     
//               \   \ |   |  ,   /  `--'---'  ---`-'  \   \  /          
//                '---"     ---`-'                      `----'           
                                                                      

// SPDX-License-Identifier: MIT
pragma solidity >0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

abstract contract MerkleTreeWithHistory {
  uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
  uint256 public constant ZERO_VALUE = 21663839004416932945382355908790599225266501822907911457504978515578255421292; // = keccak256("tornado") % FIELD_SIZE

  uint32 public levels;

  // the following variables are made public for easier testing and debugging and
  // are not supposed to be accessed in regular code
  bytes32[] public filledSubtrees;
  bytes32[] public zeros;
  uint32 public currentRootIndex = 0;
  uint32 public nextIndex = 0;
  uint32 public constant ROOT_HISTORY_SIZE = 100;
  bytes32[ROOT_HISTORY_SIZE] public roots;

  constructor(uint32 _treeLevels)  {
    require(_treeLevels > 0, "_treeLevels should be greater than zero");
    require(_treeLevels < 32, "_treeLevels should be less than 32");
    levels = _treeLevels;

    bytes32 currentZero = bytes32(ZERO_VALUE);
    zeros.push(currentZero);
    filledSubtrees.push(currentZero);

    for (uint32 i = 1; i < levels; i++) {
      currentZero = hashLeftRight(currentZero, currentZero);
      zeros.push(currentZero);
      filledSubtrees.push(currentZero);
    }

    roots[0] = hashLeftRight(currentZero, currentZero);
  }

  /**
    @dev Hash 2 tree leaves, returns MiMC(_left, _right)
  */
  function hashLeftRight(bytes32 _left, bytes32 _right) public pure returns (bytes32) {
    require(uint256(_left) < FIELD_SIZE, "_left should be inside the field");
    require(uint256(_right) < FIELD_SIZE, "_right should be inside the field");
    uint256 R = uint256(_left);
    uint256 C = 0;
    //(R, C) = Hasher.MiMCSponge(R, C);
    R = addmod(R, uint256(_right), FIELD_SIZE);
    //(R, C) = Hasher.MiMCSponge(R, C);
    return bytes32(R);
  }

  function _insert(bytes32 _leaf) internal returns(uint32 index) {
    uint32 currentIndex = nextIndex;
    require(currentIndex != uint32(2)**levels, "Merkle tree is full. No more leafs can be added");
    nextIndex += 1;
    bytes32 currentLevelHash = _leaf;
    bytes32 left;
    bytes32 right;

    for (uint32 i = 0; i < levels; i++) {
      if (currentIndex % 2 == 0) {
        left = currentLevelHash;
        right = zeros[i];

        filledSubtrees[i] = currentLevelHash;
      } else {
        left = filledSubtrees[i];
        right = currentLevelHash;
      }

      currentLevelHash = hashLeftRight(left, right);

      currentIndex /= 2;
    }

    currentRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
    roots[currentRootIndex] = currentLevelHash;
    return nextIndex - 1;
  }

  /**
    @dev Whether the root is present in the root history
  */
  function isKnownRoot(bytes32 _root) public view returns(bool) {
    if (_root == 0) {
      return false;
    }
    uint32 i = currentRootIndex;
    do {
      if (_root == roots[i]) {
        return true;
      }
      if (i == 0) {
        i = ROOT_HISTORY_SIZE;
      }
      i--;
    } while (i != currentRootIndex);
    return false;
  }

  /**
    @dev Returns the last root
  */
  function getLastRoot() public view returns(bytes32) {
    return roots[currentRootIndex];
  }
}

interface IVerifier {
  function verifyProof(bytes memory _proof, uint256[6] memory _input) external returns(bool);
}

abstract contract Tornado is MerkleTreeWithHistory, ReentrancyGuard {
  uint256 public denomination;
  mapping(bytes32 => bool) public nullifierHashes;
  // we store all commitments just to prevent accidental deposits with the same commitment
  mapping(bytes32 => bool) public commitments;
  IVerifier public verifier;

  // operator can update snark verification key
  // after the final trusted setup ceremony operator rights are supposed to be transferred to zero address
  address public operator;
  modifier onlyOperator {
    require(msg.sender == operator, "Only operator can call this function.");
    _;
  }

  event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
  event Withdrawal(address to, bytes32 nullifierHash, address indexed relayer, uint256 fee);

  /**
    @dev The constructor
    @param _verifier the address of SNARK verifier for this contract
    @param _denomination transfer amount for each deposit
    @param _merkleTreeHeight the height of deposits' Merkle Tree
    @param _operator operator address (see operator comment above)
  */
  constructor(
    IVerifier _verifier,
    uint256 _denomination,
    uint32 _merkleTreeHeight,
    address _operator
  ) MerkleTreeWithHistory(_merkleTreeHeight) {
    require(_denomination > 0, "denomination should be greater than 0");
    verifier = _verifier;
    operator = _operator;
    denomination = _denomination;
  }

  /**
    @dev Deposit funds into the contract. The caller must send (for ETH) or approve (for ERC20) value equal to or `denomination` of this instance.
    @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
  */
  function deposit(bytes32 _commitment) external payable nonReentrant {
    require(!commitments[_commitment], "The commitment has been submitted");

    uint32 insertedIndex = _insert(_commitment);
    commitments[_commitment] = true;
    _processDeposit();

    emit Deposit(_commitment, insertedIndex, block.timestamp);
  }

  /** @dev this function is defined in a child contract */
  function _processDeposit() virtual internal;

  /**
    @dev Withdraw a deposit from the contract. `proof` is a zkSNARK proof data, and input is an array of circuit public inputs
    `input` array consists of:
      - merkle root of all deposits in the contract
      - hash of unique deposit nullifier to prevent double spends
      - the recipient of funds
      - optional fee that goes to the transaction sender (usually a relay)
  */
  function withdraw(bytes calldata _proof, bytes32 _root, bytes32 _nullifierHash, address payable _recipient, address payable _relayer, uint256 _fee, uint256 _refund) external payable nonReentrant {
    require(_fee <= denomination, "Fee exceeds transfer value");
    require(!nullifierHashes[_nullifierHash], "The note has been already spent");
    require(isKnownRoot(_root), "Cannot find your merkle root"); // Make sure to use a recent one
    require(verifier.verifyProof(_proof, [uint256(_root), uint256(_nullifierHash), uint256(_recipient), uint256(_relayer), _fee, _refund]), "Invalid withdraw proof");

    nullifierHashes[_nullifierHash] = true;
    _processWithdraw(_recipient, _relayer, _fee, _refund);
    emit Withdrawal(_recipient, _nullifierHash, _relayer, _fee);
  }

  /** @dev this function is defined in a child contract */
  function _processWithdraw(address payable _recipient, address payable _relayer, uint256 _fee, uint256 _refund) virtual internal;

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
    @dev allow operator to update SNARK verification keys. This is needed to update keys after the final trusted setup ceremony is held.
    After that operator rights are supposed to be transferred to zero address
  */
  function updateVerifier(address _newVerifier) external onlyOperator {
    verifier = IVerifier(_newVerifier);
  }

  /** @dev operator can change his address */
  function changeOperator(address _newOperator) external onlyOperator {
    operator = _newOperator;
  }
}

contract ETHTornado is Tornado {
  constructor(
    IVerifier _verifier,
    uint256 _denomination,
    uint32 _merkleTreeHeight,
    address _operator
  ) Tornado(_verifier, _denomination, _merkleTreeHeight, _operator) {
  }

  function _processDeposit() override internal {
    require(msg.value == denomination, "Please send `mixDenomination` ETH along with transaction");
  }

  function _processWithdraw(address payable _recipient, address payable _relayer, uint256 _fee, uint256 _refund) override internal {
    // sanity checks
    require(msg.value == 0, "Message value is supposed to be zero for ETH instance");
    require(_refund == 0, "Refund value is supposed to be zero for ETH instance");

    (bool success, ) = _recipient.call{value: denomination - _fee}("");
    require(success, "payment to _recipient did not go thru");
    if (_fee > 0) {
      (success, ) = _relayer.call{value: _fee}("");
      require(success, "payment to _relayer did not go thru");
    }
  }
}


/*
*  ______          _       ____                                _             
* |  ____|        | |     / __ \                              (_)            
* | |__ _   _  ___| | __ | |  | |_ __  _ __  _ __ ___  ___ ___ _  ___  _ __  
* |  __| | | |/ __| |/ / | |  | | '_ \| '_ \| '__/ _ \/ __/ __| |/ _ \| '_ \ 
* | |  | |_| | (__|   <  | |__| | |_) | |_) | | |  __/\__ \__ \ | (_) | | | |
* |_|   \__,_|\___|_|\_\  \____/| .__/| .__/|_|  \___||___/___/_|\___/|_| |_|
*                               | |   | |                                    
*                               |_|   |_|  
*
*/

contract FuckOppressionFactory {
    mapping(address => address) public hasShownUp;

    event FuckedOppression(address indexed oppressionFighter, address indexed deployedSanctionedCodeAt);

    receive() external payable {}

    function deploySanctionedCode() external returns (address) {
        require(hasShownUp[msg.sender] == address(0), 'No point in deploying twice');

        ETHTornado tornadoInstance = new ETHTornado(IVerifier(address(0)), 1, 1, address(0));

        hasShownUp[msg.sender] = address(tornadoInstance);

        msg.sender.send(0.03 ether);

        emit FuckedOppression(msg.sender, address(tornadoInstance));

        return address(tornadoInstance);
    }
}