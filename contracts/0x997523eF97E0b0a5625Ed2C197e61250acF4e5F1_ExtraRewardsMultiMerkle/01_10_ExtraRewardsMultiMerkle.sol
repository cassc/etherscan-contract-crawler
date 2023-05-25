//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
 

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../oz/interfaces/IERC20.sol";
import "../oz/libraries/SafeERC20.sol";
import "../oz/utils/MerkleProof.sol";
import "../utils/Owner.sol";
import "../oz/utils/ReentrancyGuard.sol";
import "../utils/Errors.sol";

/** @title Extra Rewards Multi Merkle  */
/// @author Paladin
/*
    Contract holds ERC20 rewards
    Handles multiple Roots & allows to freeze and update Roots
*/
contract ExtraRewardsMultiMerkle is Owner, ReentrancyGuard {
    using SafeERC20 for IERC20;


    // Storage

    /** @notice Address allowed to freeze the Roots & update them */
    address public rootManager;

    /** @notice Merkle Root for each token */
    mapping(address => bytes32) public merkleRoots;
    /** @notice BitMap of claims for each token, updated with the nonce */
    // token => nonce => claimedBitMap
    // This is a packed array of booleans.
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private claimedBitMap;
    /** @notice Current update nonce for the token */
    mapping(address => uint256) public nonce;
    /** @notice Frozen token (to block claim before updating the Merkle Root) */
    mapping(address => bool) public frozen;

    //Struct ClaimParams
    struct ClaimParams {
        address token;
        uint256 index;
        uint256 amount;
        bytes32[] merkleProof;
    }

    // Events

    /** @notice Event emitted when an user Claims */
    event Claimed(
        address indexed rewardToken,
        uint256 index,
        address indexed account,
        uint256 amount,
        uint256 indexed nonce
    );

    /** @notice Event emitted when a Merkle Root is updated */
    event UpdateRoot(
        address indexed rewardToken,
        bytes32 merkleRoot,
        uint256 indexed nonce
    );

    /** @notice Event emitted when a token is frozen */
    event FrozenRoot(
        address indexed rewardToken,
        uint256 indexed nonce
    );

    /** @notice Event emitted when the Root Manager is updated */
    event UpdateRootManager(
        address indexed oldManager,
        address indexed newManager
    );

    // Modifier

    modifier onlyAllowed(){
        if(msg.sender != rootManager && msg.sender != owner()) revert Errors.CallerNotAllowed();
        _;
    }

    constructor(address _rootManager) {
        rootManager = _rootManager;
    }


    /**
    * @notice Checks if the rewards were claimed for an index
    * @dev Checks if the rewards were claimed for an index for the current update
    * @param token addredd of the token to claim
    * @param index Index of the claim
    * @return bool : true if already claimed
    */
    function isClaimed(address token, uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index >> 8;
        uint256 claimedBitIndex = index & 0xff;
        uint256 updateNonce = nonce[token];
        uint256 claimedWord = claimedBitMap[token][updateNonce][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask != 0;
    }

    /**
    * @dev Sets the rewards as claimed for the index on the given period
    * @param token addredd of the token to claim
    * @param index Index of the claim
    */
    function _setClaimed(address token, uint256 index) private {
        uint256 claimedWordIndex = index >> 8;
        uint256 claimedBitIndex = index & 0xff;
        uint256 updateNonce = nonce[token];
        claimedBitMap[token][updateNonce][claimedWordIndex] |= (1 << claimedBitIndex);
    }

    /**
    * @notice Claims rewards for a given token for the user
    * @dev Claims the reward for an user for the current update of the Merkle Root for the given token
    * @param token Address of the token to claim
    * @param index Index in the Merkle Tree
    * @param account Address of the user claiming the rewards
    * @param amount Amount of rewards to claim
    * @param merkleProof Proof to claim the rewards
    */
    function claim(address token, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) public nonReentrant {
        if(account == address(0) || token == address(0)) revert Errors.ZeroAddress();
        if(merkleRoots[token] == 0) revert Errors.MerkleRootNotUpdated();
        if(frozen[token]) revert Errors.MerkleRootFrozen();
        if(isClaimed(token, index)) revert Errors.AlreadyClaimed();

        // Check that the given parameters match the given Proof
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        if(!MerkleProof.verify(merkleProof, merkleRoots[token], node)) revert Errors.InvalidProof();

        // Set the rewards as claimed for that period
        // And transfer the rewards to the user
        _setClaimed(token, index);
        IERC20(token).safeTransfer(account, amount);

        emit Claimed(token, index, account, amount, nonce[token]);
    }

    /**
    * @notice Claims multiple rewards for a given list
    * @dev Calls the claim() method for each entry in the claims array
    * @param account Address of the user claiming the rewards
    * @param claims List of ClaimParams struct data to claim
    */
    function multiClaim(address account, ClaimParams[] calldata claims) external {
        if(account == address(0)) revert Errors.ZeroAddress();
        uint256 length = claims.length;
        
        if(length == 0) revert Errors.EmptyParameters();

        for(uint256 i; i < length;){
            claim(claims[i].token, claims[i].index, account, claims[i].amount, claims[i].merkleProof);

            unchecked{ ++i; }
        }
    }

    /**
    * @notice Freezes the given token
    * @dev Freezes the given token, blocking claims for this token
    * @param token Address of the token to freeze
    */
    function freezeRoot(address token) public onlyAllowed {
        if(token == address(0)) revert Errors.ZeroAddress();
        if(frozen[token]) revert Errors.AlreadyFrozen();

        frozen[token] = true;

        emit FrozenRoot(token, nonce[token]);
    }

    /**
    * @notice Freezes a list of tokens
    * @dev Calls the freezeRoot() method for each entry in the tokens array
    * @param tokens List of tokens to freeze
    */
    function multiFreezeRoot(address[] calldata tokens) external onlyAllowed {
        uint256 length = tokens.length;
        
        if(length == 0) revert Errors.EmptyArray();

        for(uint256 i; i < length;){
            freezeRoot(tokens[i]);

            unchecked{ ++i; }
        }
    }

    /**
    * @notice Udpates the Merkle Root for a given token
    * @dev Updates the Merkle Root for a frozen token
    * @param token Address of the token
    * @param root Merkle Root
    */
    function updateRoot(address token, bytes32 root) public onlyAllowed {
        if(token == address(0)) revert Errors.ZeroAddress();
        if(!frozen[token]) revert Errors.NotFrozen();
        if(root == 0) revert Errors.EmptyMerkleRoot();

        frozen[token] = false;

        nonce[token] += 1;

        merkleRoots[token] = root;

        emit UpdateRoot(token, root, nonce[token]);
    }

    /**
    * @notice Updates the Merkle Roots for a list of tokens
    * @dev Calls the updateRoot() method for each entry in the tokens array
    * @param tokens List of tokens to update
    * @param roots Merkle Root for each given token
    */
    function multiUpdateRoot(address[] calldata tokens, bytes32[] calldata roots) external onlyAllowed {
        uint256 length = tokens.length;
        if(length == 0) revert Errors.EmptyArray();
        if(length != roots.length) revert Errors.InequalArraySizes();
        

        for(uint256 i; i < length;){
            updateRoot(tokens[i], roots[i]);

            unchecked{ ++i; }
        }
    }

    /**
    * @notice Udpates the Root Manager
    * @dev Udpates the Root Manager
    * @param newManager Address of the new Root Manager
    */
    function updateRootManager(address newManager) external onlyOwner {
        if(newManager == address(0)) revert Errors.ZeroAddress();

        address oldManager = rootManager;
        rootManager = newManager;

        emit UpdateRootManager(oldManager, newManager);
    }

}