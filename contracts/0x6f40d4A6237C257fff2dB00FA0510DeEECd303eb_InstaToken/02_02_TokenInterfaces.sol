pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IndexInterface {
    function master() external view returns (address);
}

contract TokenEvents {
    
    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice An event thats emitted when the minter changes
    event MinterChanged(address indexed oldMinter, address indexed newMinter);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Emitted when implementation is changed
    event NewImplementation(address oldImplementation, address newImplementation);

    /// @notice An event thats emitted when the token transfered is paused
    event TransferPaused(address indexed minter);

    /// @notice An event thats emitted when the token transfered is unpaused
    event TransferUnpaused(address indexed minter);

    /// @notice An event thats emitted when the token symbol is changed
    event ChangedSymbol(string oldSybmol, string newSybmol);

    /// @notice An event thats emitted when the token name is changed
    event ChangedName(string oldName, string newName);
}

contract TokenDelegatorStorage {
    /// @notice InstaIndex contract
    IndexInterface constant public instaIndex = IndexInterface(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);

    /// @notice Active brains of Token
    address public implementation;

    /// @notice EIP-20 token name for this token
    string public name = "Instadapp";

    /// @notice EIP-20 token symbol for this token
    string public symbol = "INST";

    /// @notice Total number of tokens in circulation
    uint public totalSupply;

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    modifier isMaster() {
        require(instaIndex.master() == msg.sender, "Tkn::isMaster: msg.sender not master");
        _;
    }
}

/**
 * @title Storage for Token Delegate
 * @notice For future upgrades, do not change TokenDelegateStorageV1. Create a new
 * contract which implements TokenDelegateStorageV1 and following the naming convention
 * TokenDelegateStorageVX.
 */
contract TokenDelegateStorageV1 is TokenDelegatorStorage {
    /// @notice The timestamp after which minting may occur
    uint public mintingAllowedAfter;

    /// @notice token transfer pause state
    bool public transferPaused;

    // Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    // Official record of token balances for each account
    mapping (address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;
}