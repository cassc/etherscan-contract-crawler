/**
 *Submitted for verification at Etherscan.io on 2023-06-19
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// ============ Imports ============

interface IERC20 {
  
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library MerkleProof {
  
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

   
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
               
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract UPZachXBTMerkleClaim is Ownable {

  /// ============ Immutable storage ============

  address public immutable token;
  bytes32 public immutable merkleRoot;
  
  /// ============ Mutable storage ============

 
  mapping(address => bool) public hasClaimed;

  /// ============ Errors ============

  
  error AlreadyClaimed();
 
  error NotInMerkle();

  /// ============ Constructor ============


  constructor(address token_, bytes32 merkleRoot_)  {
        token = token_;
        merkleRoot = merkleRoot_;
    }
    
  /// ============ Events ============

 
  event Claim(address indexed to, uint256 amount);

  /// ============ Functions ============

 
  function claim(address to, uint256 amount, bytes32[] calldata proof) external {
    // Throw if address has already claimed tokens
    
    if (hasClaimed[to]) revert AlreadyClaimed();

    // Verify merkle proof, or revert if not in tree
    bytes32 leaf = keccak256(abi.encodePacked(to, amount));
    bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
    if (!isValidLeaf) revert NotInMerkle();

    // Set address to claimed
    hasClaimed[to] = true;

    // transfer tokens to address
    IERC20(token).transfer(to, amount);
  
    // Emit claim event
    emit Claim(to, amount);
  }

    
  function withdrawBalance() external onlyOwner {
    uint256 balance = IERC20(token).balanceOf(address(this));
    if (balance > 0) {
      IERC20(token).transfer(owner(), balance);
    }
  }
}