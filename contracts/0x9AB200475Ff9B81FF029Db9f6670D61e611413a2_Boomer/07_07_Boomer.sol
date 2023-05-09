//                                                                                                                                  
//BBBBBBBBBBBBBBBBB        OOOOOOOOO          OOOOOOOOO     MMMMMMMM               MMMMMMMMEEEEEEEEEEEEEEEEEEEEEERRRRRRRRRRRRRRRRR   
//B::::::::::::::::B     OO:::::::::OO      OO:::::::::OO   M:::::::M             M:::::::ME::::::::::::::::::::ER::::::::::::::::R  
//B::::::BBBBBB:::::B  OO:::::::::::::OO  OO:::::::::::::OO M::::::::M           M::::::::ME::::::::::::::::::::ER::::::RRRRRR:::::R 
//BB:::::B     B:::::BO:::::::OOO:::::::OO:::::::OOO:::::::OM:::::::::M         M:::::::::MEE::::::EEEEEEEEE::::ERR:::::R     R:::::R
//  B::::B     B:::::BO::::::O   O::::::OO::::::O   O::::::OM::::::::::M       M::::::::::M  E:::::E       EEEEEE  R::::R     R:::::R
//  B::::B     B:::::BO:::::O     O:::::OO:::::O     O:::::OM:::::::::::M     M:::::::::::M  E:::::E               R::::R     R:::::R
//  B::::BBBBBB:::::B O:::::O     O:::::OO:::::O     O:::::OM:::::::M::::M   M::::M:::::::M  E::::::EEEEEEEEEE     R::::RRRRRR:::::R 
//  B:::::::::::::BB  O:::::O     O:::::OO:::::O     O:::::OM::::::M M::::M M::::M M::::::M  E:::::::::::::::E     R:::::::::::::RR  
//  B::::BBBBBB:::::B O:::::O     O:::::OO:::::O     O:::::OM::::::M  M::::M::::M  M::::::M  E:::::::::::::::E     R::::RRRRRR:::::R 
//  B::::B     B:::::BO:::::O     O:::::OO:::::O     O:::::OM::::::M   M:::::::M   M::::::M  E::::::EEEEEEEEEE     R::::R     R:::::R
//  B::::B     B:::::BO:::::O     O:::::OO:::::O     O:::::OM::::::M    M:::::M    M::::::M  E:::::E               R::::R     R:::::R
//  B::::B     B:::::BO::::::O   O::::::OO::::::O   O::::::OM::::::M     MMMMM     M::::::M  E:::::E       EEEEEE  R::::R     R:::::R
//BB:::::BBBBBB::::::BO:::::::OOO:::::::OO:::::::OOO:::::::OM::::::M               M::::::MEE::::::EEEEEEEE:::::ERR:::::R     R:::::R
//B:::::::::::::::::B  OO:::::::::::::OO  OO:::::::::::::OO M::::::M               M::::::ME::::::::::::::::::::ER::::::R     R:::::R
//B::::::::::::::::B     OO:::::::::OO      OO:::::::::OO   M::::::M               M::::::ME::::::::::::::::::::ER::::::R     R:::::R
//BBBBBBBBBBBBBBBBB        OOOOOOOOO          OOOOOOOOO     MMMMMMMM               MMMMMMMMEEEEEEEEEEEEEEEEEEEEEERRRRRRRR     RRRRRRR
                                                                                                                                   
//https://t.me/boomereth                                                                                         
                                                                                                                                   
                                                                                                                                   
                                                                                                                                   
                                                                                                                                   
                                                                                                                                   

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// ============ Imports ============

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title MerkleClaimERC20
/// @notice ERC20 claimable by members of a merkle tree

contract Boomer is ERC20, Ownable {

  /// ============ Immutable storage ============

  /// @notice ERC20-claimee inclusion root
  bytes32 public immutable merkleRoot;

  /// ============ Mutable storage ============

  /// @notice Mapping of addresses who have claimed tokens
  mapping(address => bool) public hasClaimed;
  
  bool public limited;
  uint256 public maxHoldingAmount;
  uint256 public minHoldingAmount;
  address public uniswapV2Pair;
  mapping(address => bool) public blacklists;

  /// ============ Errors ============

  /// @notice Thrown if address has already claimed
  error AlreadyClaimed();
  /// @notice Thrown if address/amount are not part of Merkle tree
  error NotInMerkle();

  /// ============ Constructor ============

  /// @notice Creates a new MerkleClaimERC20 contract
  /// @param _name of token
  /// @param _symbol of token
  /// @param _decimals of token
  /// @param _merkleRoot of claimees
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    uint256 _totalSupply,
    bytes32 _merkleRoot
  ) ERC20(_name, _symbol) {
    _decimals = _decimals;
      _mint(msg.sender, _totalSupply * 10 ** uint256(decimals()));
    merkleRoot = _merkleRoot;
  }

  /// ============ Events ============

  /// @notice Emitted after a successful token claim
  /// @param to recipient of claim
  /// @param amount of tokens claimed
  event Claim(address indexed to, uint256 amount);

  /// ============ Modifiers ============

  /// @notice Modifier to check if address has already claimed tokens
  modifier notClaimed(address to) {
    if (hasClaimed[to]) revert AlreadyClaimed();
    _;
  }

  /// ============ Functions ============

  /// @notice Allows claiming tokens if address is part of merkle tree
  /// @param to address of claimee
  /// @param amount of tokens owed to claimee
  /// @param proof merkle proof to prove address and amount are in tree
  function claim(address to, uint256 amount, bytes32[] calldata proof) external notClaimed(to) {
    // Verify merkle proof, or revert if not in tree
    bytes32 leaf = keccak256(abi.encodePacked(to, amount));
    bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
    if (!isValidLeaf) revert NotInMerkle();

    // Set address to claimed
    hasClaimed[to] = true;

    // Transfer tokens to address
    _transfer(address(this), to, amount);

    // Emit claim event
    emit Claim(to, amount);
  }


    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
    blacklists[_address] = _isBlacklisting;
  }

  function setRule(bool _limited, address _uniswapV2Pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
    limited = _limited;
    uniswapV2Pair = _uniswapV2Pair;
    maxHoldingAmount = _maxHoldingAmount;
    minHoldingAmount = _minHoldingAmount;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) override internal virtual {
    require(!blacklists[to] && !blacklists[from], "Blacklisted");

    if (uniswapV2Pair == address(0)) {
      require(from == owner() || to == owner(), "trading is not started");
      return;
    }

    if (limited && from == uniswapV2Pair) {
      require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
    }
  }
}