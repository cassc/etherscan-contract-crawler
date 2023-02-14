// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./base/RolesManager.sol";

contract HoldingFeeDistributor is RolesManager {
    using SafeERC20 for IERC20;

    uint256 public cumulativeBtcSnacksFeeAmount;
    uint256 public cumulativeEthSnacksFeeAmount;
    address public btcSnacks;
    address public ethSnacks;
    bytes32 public merkleRoot;

    event BtcSnacksFeeAdded(uint256 indexed feeAmount);
    event EthSnacksFeeAdded(uint256 indexed feeAmount);
    event BtcSnacksClaimed(address indexed account, uint256 indexed amount);
    event EthSnacksClaimed(address indexed account, uint256 indexed amount);
    event MerkleRootUpdated(bytes32 indexed oldMerkleRoot, bytes32 indexed newMerkleRoot);

    mapping(address => uint256) public cumulativeBtcSnacksClaimed;
    mapping(address => uint256) public cumulativeEthSnacksClaimed;

    modifier onlyBtcSnacks {
        require(
            msg.sender == btcSnacks,
            "HoldingFeeDistributor: caller is not the BtcSnacks contract"
        );
        _;
    }
    
    modifier onlyEthSnacks {
        require(
            msg.sender == ethSnacks,
            "HoldingFeeDistributor: caller is not the EthSnacks contract"
        );
        _;
    }

    /**
    * @notice Configures the contract.
    * @dev Could be called by the owner in case of resetting addresses.
    * @param btcSnacks_ BtcSnacks token address.
    * @param ethSnacks_ EthSnacks token address.
    * @param authority_ Authorised address.
    */
    function configure(
        address btcSnacks_,
        address ethSnacks_,
        address authority_
    ) 
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        btcSnacks = btcSnacks_;
        ethSnacks = ethSnacks_;
        _grantRole(AUTHORITY_ROLE, authority_);
    }

    /**
    * @notice Notifies the contract about the incoming fee in BtcSnacks token.
    * @dev Called by the BtcSnacks contract once every 12 hours.
    * @param feeAmount_ Fee amount.
    */
    function notifyBtcSnacksFeeAmount(uint256 feeAmount_) external onlyBtcSnacks {
        cumulativeBtcSnacksFeeAmount += feeAmount_;
        emit BtcSnacksFeeAdded(feeAmount_);
    }
    
    /**
    * @notice Notifies the contract about the incoming fee in EthSnacks token.
    * @dev Called by the EthSnacks contract once every 12 hours.
    * @param feeAmount_ Fee amount.
    */
    function notifyEthSnacksFeeAmount(uint256 feeAmount_) external onlyEthSnacks {
        cumulativeEthSnacksFeeAmount += feeAmount_;
        emit EthSnacksFeeAdded(feeAmount_);
    }

    /**
    * @notice Sets the root of the Merkle tree.
    * @dev Called by the authorised address once every 12 hours.
    * @param merkleRoot_ Merkle tree root.
    */
    function setMerkleRoot(bytes32 merkleRoot_) external whenNotPaused onlyRole(AUTHORITY_ROLE) {
        emit MerkleRootUpdated(merkleRoot, merkleRoot_);
        merkleRoot = merkleRoot_;
    }

    /**
    * @notice Transfers BtcSnacks and EthSnacks tokens to `account_`.
    * @dev Updates cumulative claimed amounts for `account_` to avoid double-spending.
    * @param account_ Account address.
    * @param cumulativeBtcSnacksAmount_ Cumulative BtcSnacks tokens amount.
    * @param cumulativeEthSnacksAmount_ Cumulative EthSnacks tokens amount.
    * @param expectedMerkleRoot_ Expected Merkle root.
    * @param merkleProof_ Merkle proof.
    */
    function claim(
        address account_,
        uint256 cumulativeBtcSnacksAmount_,
        uint256 cumulativeEthSnacksAmount_,
        bytes32 expectedMerkleRoot_,
        bytes32[] calldata merkleProof_
    ) 
        external 
        whenNotPaused
    {
        require(
            merkleRoot == expectedMerkleRoot_, 
            "HoldingFeeDistributor: merkle root was updated"
        );
        bytes32 leaf = keccak256(
            abi.encodePacked(
                account_, 
                cumulativeBtcSnacksAmount_,
                cumulativeEthSnacksAmount_
            )
        );
        require(
            MerkleProof.verifyCalldata(
                merkleProof_,
                merkleRoot,
                leaf
            ),
            "HoldingFeeDistributor: invalid proof"
        );
        uint256 btcSnacksPreclaimed = cumulativeBtcSnacksClaimed[account_];
        uint256 ethSnacksPreclaimed = cumulativeEthSnacksClaimed[account_];
        bool validBtcSnacksDifference = btcSnacksPreclaimed < cumulativeBtcSnacksAmount_;
        bool validEthSnacksDifference = ethSnacksPreclaimed < cumulativeEthSnacksAmount_;
        require(
            validBtcSnacksDifference ||
            validEthSnacksDifference, 
            "HoldingFeeDistributor: nothing to claim"
        );
        if (validBtcSnacksDifference) {
            uint256 amount = cumulativeBtcSnacksAmount_ - btcSnacksPreclaimed;
            cumulativeBtcSnacksClaimed[account_] = cumulativeBtcSnacksAmount_;
            IERC20(btcSnacks).safeTransfer(account_, amount);
            emit BtcSnacksClaimed(account_, amount);
        }
        if (validEthSnacksDifference) {
            uint256 amount = cumulativeEthSnacksAmount_ - ethSnacksPreclaimed;
            cumulativeEthSnacksClaimed[account_] = cumulativeEthSnacksAmount_;
            IERC20(ethSnacks).safeTransfer(account_, amount);
            emit EthSnacksClaimed(account_, amount);
        }
    }
}