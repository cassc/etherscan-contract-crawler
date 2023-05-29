// SPDX-License-Identifier: MIT
// https://etherscan.io/address/0xcbe6b83e77cdc011cc18f6f0df8444e5783ed982#code
pragma solidity 0.8.9;

import "SafeERC20.sol";
import "MerkleProof.sol";
import "IGenericVault.sol";

// Allows anyone to claim a token if they exist in a merkle root.
contract GenericDistributor {
    using SafeERC20 for IERC20;

    address public vault;
    address public token;
    bytes32 public merkleRoot;
    uint32 public week;
    bool public frozen;

    address public admin;
    address public depositor;

    // This is a packed array of booleans.
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(
        uint256 index,
        uint256 indexed amount,
        address indexed account,
        uint256 week
    );
    // This event is triggered whenever the merkle root gets updated.
    event MerkleRootUpdated(bytes32 indexed merkleRoot, uint32 indexed week);
    // This event is triggered whenever the admin is updated.
    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);
    // This event is triggered whenever the depositor contract is updated.
    event DepositorUpdated(
        address indexed oldDepositor,
        address indexed newDepositor
    );
    // This event is triggered whenever the vault contract is updated.
    event VaultUpdated(address indexed oldVault, address indexed newVault);
    // When recovering stuck ERC20s
    event Recovered(address token, uint256 amount);

    constructor(
        address _vault,
        address _depositor,
        address _token
    ) {
        require(_vault != address(0));
        vault = _vault;
        admin = msg.sender;
        depositor = _depositor;
        token = _token;
        week = 0;
        frozen = true;
    }

    /// @notice Set approvals for the tokens used when swapping
    function setApprovals() external virtual onlyAdmin {
        IERC20(token).safeApprove(vault, 0);
        IERC20(token).safeApprove(vault, type(uint256).max);
    }

    /// @notice Check if the index has been marked as claimed.
    /// @param index - the index to check
    /// @return true if index has been marked as claimed.
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[week][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[week][claimedWordIndex] =
            claimedBitMap[week][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /// @notice Transfers ownership of the contract
    /// @param newAdmin - address of the new admin of the contract
    function updateAdmin(address newAdmin)
        external
        onlyAdmin
        notToZeroAddress(newAdmin)
    {
        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminUpdated(oldAdmin, newAdmin);
    }

    /// @notice Changes the contract allowed to freeze before depositing
    /// @param newDepositor - address of the new depositor contract
    function updateDepositor(address newDepositor)
        external
        onlyAdmin
        notToZeroAddress(newDepositor)
    {
        address oldDepositor = depositor;
        depositor = newDepositor;
        emit DepositorUpdated(oldDepositor, newDepositor);
    }

    /// @notice Changes the Vault where funds are staked
    /// @param newVault - address of the new vault contract
    function updateVault(address newVault)
        external
        onlyAdmin
        notToZeroAddress(newVault)
    {
        address oldVault = vault;
        vault = newVault;
        emit VaultUpdated(oldVault, newVault);
    }

    /// @notice Internal function to handle users' claims
    /// @param index - claimer index
    /// @param account - claimer account
    /// @param amount - claim amount
    /// @param merkleProof - merkle proof for the claim
    function _claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) internal {
        require(!frozen, "Claiming is frozen.");
        require(!isClaimed(index), "Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Invalid proof."
        );

        // Mark it claimed and send the token.
        _setClaimed(index);
    }

    /// @notice Claim the given amount of uCRV to the given address.
    /// @param index - claimer index
    /// @param account - claimer account
    /// @param amount - claim amount
    /// @param merkleProof - merkle proof for the claim
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        // Claim
        _claim(index, account, amount, merkleProof);

        // Send shares to account
        IERC20(vault).safeTransfer(account, amount);

        emit Claimed(index, amount, account, week);
    }

    /// @notice Stakes the contract's entire balance in the Vault
    function stake() external virtual onlyAdminOrDistributor {
        IGenericVault(vault).depositAll(address(this));
    }

    /// @notice Freezes the claim function to allow the merkleRoot to be changed
    /// @dev Can be called by the owner or the depositor zap contract
    function freeze() external onlyAdminOrDistributor {
        frozen = true;
    }

    /// @notice Unfreezes the claim function.
    function unfreeze() public onlyAdmin {
        frozen = false;
    }

    /// @notice Update the merkle root and increment the week.
    /// @param _merkleRoot - the new root to push
    /// @param _unfreeze - whether to unfreeze the contract after unlock
    function updateMerkleRoot(bytes32 _merkleRoot, bool _unfreeze)
        external
        onlyAdmin
    {
        require(frozen, "Contract not frozen.");

        // Increment the week (simulates the clearing of the claimedBitMap)
        week = week + 1;
        // Set the new merkle root
        merkleRoot = _merkleRoot;

        emit MerkleRootUpdated(merkleRoot, week);

        if (_unfreeze) {
            unfreeze();
        }
    }

    /// @notice Recover ERC20s mistakenly sent to the contract
    /// @param tokenAddress - address of the token to retrieve
    /// @param tokenAmount - amount to retrieve
    /// @dev Will revert if token is same as token being distributed
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyAdmin
    {
        require(
            tokenAddress != address(token),
            "Cannot withdraw the distributed token"
        );
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    receive() external payable {}

    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin only");
        _;
    }

    modifier onlyAdminOrDistributor() {
        require(
            (msg.sender == admin) || (msg.sender == depositor),
            "Admin or depositor only"
        );
        _;
    }

    modifier notToZeroAddress(address _to) {
        require(_to != address(0), "Invalid address!");
        _;
    }
}