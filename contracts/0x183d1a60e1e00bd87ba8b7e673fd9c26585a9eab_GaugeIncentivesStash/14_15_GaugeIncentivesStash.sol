// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// ==========================================
// |            ____  _ __       __         |
// |           / __ \(_) /______/ /_        |
// |          / /_/ / / __/ ___/ __ \       |
// |         / ____/ / /_/ /__/ / / /       |
// |        /_/   /_/\__/\___/_/ /_/        |
// |                                        |
// ==========================================
// ================= Pitch ==================
// ==========================================

// Authored by Pitch Research: [email protected]

import "@openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@interfaces/IPitchDepositor.sol";

contract GaugeIncentivesStash is OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Claim structure
    struct ClaimData {
        address token;
        uint256 index;
        uint256 amount;
        bytes32[] merkleProof;
    }

    // Refund structure
    struct RefundData {
        address account;
        uint256 amount;
    }

    // Constants
    // Denominates weights, bps to %
    uint256 public constant DENOMINATOR = 10000;

    // Contract parameters
    address public feeAddress;
    uint256 public platformFee;

    // Stash state
    // Merkle root for each reward token
    mapping(address => bytes32) public merkleRoot;

    // Current claim period for each reward token
    mapping(address => uint256) public claimPeriod;

    // Packed array of boolean values to determine whether reward is claimed
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private claimedBitMap;

    // Reward Blacklist
    // Globally blacklisted addresses
    address[] public globalBlacklistedAddresses;

    // Addresses blacklisted for individual gauges
    mapping(address => address[]) public gaugeBlacklistedAddresses;

    // Token whitelist
    mapping(address => bool) public tokenWhitelist;

    error TokenNotListed();
    error CannotBeZero();
    error ClaimsPaused();
    error ClaimsMustBeFrozen();
    error AlreadyClaimed();
    error InvalidMerkleProof();

    /* =========== Initializer =========== */
    function initialize(address _feeAddress, uint256 _platformFee) public initializer {
        __UUPSUpgradeable_init_unchained();
        __Context_init_unchained();
        __Ownable_init_unchained();
        feeAddress = _feeAddress;
        platformFee = _platformFee;
    }

    /* =========== Public and External Functions =========== */
    function addReward(
        address _gauge,
        address _token,
        uint256 _amount,
        uint256 _pricePerToken
    ) external returns (bool) {
        if (_amount <= 0 || _pricePerToken <= 0) revert CannotBeZero();
        if (!tokenWhitelist[_token]) revert TokenNotListed();

        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);

        emit RewardAdded(_gauge, _token, msg.sender, _amount, _pricePerToken, block.timestamp);

        return true;
    }

    function isClaimed(address _token, uint256 _index) public view returns (bool) {
        uint256 claimedWordIndex = _index / 256;
        uint256 claimedBitIndex = _index % 256;
        uint256 claimedWord = claimedBitMap[_token][claimPeriod[_token]][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);

        return claimedWord & mask == mask;
    }

    function claim(
        address _token,
        uint256 _index,
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) public {
        if (merkleRoot[_token] == 0) revert ClaimsPaused();
        if (isClaimed(_token, _index)) revert AlreadyClaimed();

        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(_index, _account, _amount));
        if (!MerkleProof.verify(_merkleProof, merkleRoot[_token], node)) revert InvalidMerkleProof();

        _setClaimed(_token, _index);
        IERC20Upgradeable(_token).safeTransfer(_account, _amount);

        emit RewardClaimed(_token, _account, _index, _amount, claimPeriod[_token]);
    }

    function claimMulti(address _account, ClaimData[] calldata claims) external {
        for (uint256 i; i < claims.length; i++) {
            claim(claims[i].token, claims[i].index, _account, claims[i].amount, claims[i].merkleProof);
        }
    }

    function numBlacklistedAddresses() external view returns (uint256) {
        return globalBlacklistedAddresses.length;
    }

    function numGaugeBlacklistedAddresses(address _gauge) external view returns (uint256) {
        return gaugeBlacklistedAddresses[_gauge].length;
    }

    /* =========== Private and Internal Functions =========== */
    function _setClaimed(address _token, uint256 _index) private {
        uint256 claimedWordIndex = _index / 256;
        uint256 claimedBitIndex = _index % 256;
        claimedBitMap[_token][claimPeriod[_token]][claimedWordIndex] =
            claimedBitMap[_token][claimPeriod[_token]][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /* =========== Owner Only Functions =========== */
    // Used to upgrade contract
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @notice Allows conversion of incentive tokens to be locked through depositor & wrapped token used for incentive
    /// @param _gauge Address of the gauge to adjust.
    /// @param _incentiveToken Address of the incentive token to convert.
    /// @param _pitchDepositor Address of the depositor to use for the token.
    /// @param _pitchWrappedToken The returned pitch wrapped token from deposit.
    /// @param _amountIncentiveToConvert The amount of the deposited incentive token to convert/lock.
    /// @param _valuePerWrappedToken The dollar value of the wrapped token (in wei).
    function convertIncentives(
        address _gauge,
        address _incentiveToken,
        address _pitchDepositor,
        address _pitchWrappedToken,
        uint256 _amountIncentiveToConvert,
        uint256 _valuePerWrappedToken
    ) external onlyOwner {
        // Approve the depositor to spend the token
        IERC20Upgradeable(_incentiveToken).safeApprove(_pitchDepositor, _amountIncentiveToConvert);

        // Deposit token to appropriate depositor  & lock, receive minted amounot of pitchWrappedToken back
        IPitchDepositor(_pitchDepositor).deposit(_amountIncentiveToConvert, true);

        emit RewardDeducted(_gauge, _incentiveToken, _amountIncentiveToConvert, block.timestamp);
        emit RewardConverted(
            _gauge,
            _pitchWrappedToken,
            _amountIncentiveToConvert,
            _valuePerWrappedToken,
            _incentiveToken,
            block.timestamp
        );
    }

    // Halt claiming prior to updating merkle roots
    function freezeClaiming(address[] calldata _tokens) external onlyOwner {
        for (uint256 i; i < _tokens.length; i++) {
            _updateMerkleRoot(_tokens[i], 0);
        }
    }

    // Update multiple roots
    function updateMerkleRoots(address[] calldata _tokens, bytes32[] calldata _roots) external onlyOwner {
        for (uint256 i; i < _tokens.length; i++) {
            if (merkleRoot[_tokens[i]] != 0) revert ClaimsMustBeFrozen();
            _updateMerkleRoot(_tokens[i], _roots[i]);
        }
    }

    // Just updates merkle root
    function _updateMerkleRoot(address _token, bytes32 _merkleRoot) internal onlyOwner {
        // Increment claim period
        claimPeriod[_token] += 1;

        // Set the new merkle root
        merkleRoot[_token] = _merkleRoot;

        emit MerkleRootUpdated(_token, claimPeriod[_token], _merkleRoot);
    }

    function updateMerkleAndCheckpointAndRefunds(
        address[] calldata _tokens,
        bytes32[] calldata _roots,
        uint256 _periodFee,
        RefundData[][] calldata _refunds
    ) external onlyOwner {
        for (uint256 i; i < _tokens.length; i++) {
            if (merkleRoot[_tokens[i]] != 0) revert ClaimsMustBeFrozen();
            _updateMerkleRoot(_tokens[i], _roots[i]);
            checkpointClaimPeriod(_tokens[i], _periodFee, _refunds[i]);
        }
    }

    // Transfers fee, refunds limit orders, does not update the merkle root
    function checkpointClaimPeriod(
        address _token,
        uint256 _periodFee,
        RefundData[] calldata _refunds
    ) public onlyOwner {
        for (uint256 i; i < _refunds.length; i++) {
            IERC20Upgradeable(_token).safeTransfer(_refunds[i].account, _refunds[i].amount);

            emit RefundIssued(_token, claimPeriod[_token], _refunds[i].account, _refunds[i].amount);
        }

        IERC20Upgradeable(_token).safeTransfer(feeAddress, _periodFee);

        emit FeeCollected(_token, claimPeriod[_token], _periodFee);
    }

    // Manage token whitelist
    function listTokens(address[] calldata _tokensToList) public onlyOwner {
        for (uint256 i; i < _tokensToList.length; i++) {
            tokenWhitelist[_tokensToList[i]] = true;
            emit TokenListed(_tokensToList[i]);
        }
    }

    function unlistTokens(address[] calldata _tokensToUnlist) public onlyOwner {
        for (uint256 i; i < _tokensToUnlist.length; i++) {
            tokenWhitelist[_tokensToUnlist[i]] = false;
            emit TokenUnlisted(_tokensToUnlist[i]);
        }
    }

    // Manage blacklist
    function blacklistAddressGlobal(address _addressToBlacklist) external onlyOwner {
        globalBlacklistedAddresses.push(_addressToBlacklist);
    }

    function blacklistAddressGauge(address _gauge, address _addressToBlacklist) external onlyOwner {
        gaugeBlacklistedAddresses[_gauge].push(_addressToBlacklist);
    }

    function removeBlacklistAddressGlobal(address _addressToRemove) external onlyOwner {
        uint256 blacklistLength = globalBlacklistedAddresses.length;

        for (uint256 i; i < blacklistLength; i++) {
            if (globalBlacklistedAddresses[i] == _addressToRemove) {
                globalBlacklistedAddresses[i] = globalBlacklistedAddresses[blacklistLength - 1];
                globalBlacklistedAddresses.pop();
                return;
            }
        }
    }

    function removeBlacklistAddressGauge(address _gauge, address _addressToRemove) external onlyOwner {
        uint256 blacklistLength = gaugeBlacklistedAddresses[_gauge].length;

        for (uint256 i; i < blacklistLength; i++) {
            if (gaugeBlacklistedAddresses[_gauge][i] == _addressToRemove) {
                gaugeBlacklistedAddresses[_gauge][i] = gaugeBlacklistedAddresses[_gauge][blacklistLength - 1];
                gaugeBlacklistedAddresses[_gauge].pop();
                return;
            }
        }
    }

    /* =========== Events =========== */
    event MerkleRootUpdated(address indexed token, uint256 indexed tokenClaimPeriod, bytes32 indexed merkleRoot);
    event FeeCollected(address indexed token, uint256 indexed tokenClaimPeriod, uint256 fee);
    event RefundIssued(
        address indexed token,
        uint256 indexed tokenClaimPeriod,
        address indexed account,
        uint256 amount
    );
    event RewardClaimed(
        address indexed token,
        address indexed account,
        uint256 index,
        uint256 amount,
        uint256 indexed tokenClaimPeriod
    );
    event RewardAdded(
        address indexed gauge,
        address indexed token,
        address sender,
        uint256 amount,
        uint256 pricePerToken,
        uint256 time
    );
    event RewardDeducted(address indexed gauge, address indexed token, uint256 indexed amount, uint256 time);
    event RewardConverted(
        address indexed gauge,
        address indexed pitchWrappedIncentiveToken,
        uint256 indexed amountIncentiveTokenConverted,
        uint256 valuePerWrappedToken,
        address incentiveToken,
        uint256 timestamp
    );
    event TokenListed(address token);
    event TokenUnlisted(address token);
    event ClaimPause(uint256 pauseStatus);
}