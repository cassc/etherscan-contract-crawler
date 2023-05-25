// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MerkleDistributor
 * @notice Handles token airdrops from an unlimited amount of token rewards
 * @dev Based on https://github.com/Uniswap/merkle-distributor but modified to handle multiple airdrops concurrently
 */
contract MerkleDistributor is Ownable {
    using SafeERC20 for IERC20;

    struct Distribution {
        address token;
        bool isPaused;
        uint256 expiryTimestamp;
        bytes32 merkleRoot;
        uint256 totalAmount;
        mapping(address => uint256) claimed;
    }
    address[] public tokens;
    mapping(address => Distribution) public distributions;

    event Claimed(address indexed token, uint256 index, address indexed account, uint256 amount);
    event DistributionAdded(uint256 indexed tokenIndex, address indexed token, uint256 totalAmount, uint256 expiryTimestamp);
    event DistributionUpdated(address indexed token, uint256 additionalAmount, uint256 expiryTimestamp);
    event SetExpiryTimestamp(address indexed token, uint256 expiryTimestamp);

    modifier distributionExists(address _token) {
        require(distributions[_token].token != address(0), "MerkleDistributor: Distribution does not exist.");
        _;
    }

    /**
     * @notice returns the total amount that an account has claimed from a distribution
     * @param _token token address
     * @param _account address of the account to return claimed amount for
     **/
    function getClaimed(address _token, address _account) external view distributionExists(_token) returns (uint256) {
        return distributions[_token].claimed[_account];
    }

    /**
     * @notice add multiple token distributions
     * @param _tokens the list of token addresses to add
     * @param _merkleRoots list of merkle roots for each distribution
     * @param _totalAmounts list of total distribution amounts for each token
     * @param _expiryTimestamps list of expiry timestamps for each distribution
     **/
    function addDistributions(
        address[] calldata _tokens,
        bytes32[] calldata _merkleRoots,
        uint256[] calldata _totalAmounts,
        uint256[] calldata _expiryTimestamps
    ) external onlyOwner {
        require(
            _tokens.length == _merkleRoots.length && _tokens.length == _totalAmounts.length,
            "MerkleDistributor: Array lengths need to match."
        );

        for (uint256 i = 0; i < _tokens.length; i++) {
            addDistribution(_tokens[i], _merkleRoots[i], _totalAmounts[i], _expiryTimestamps[i]);
        }
    }

    /**
     * @notice add a token distribution
     * @param _token token address
     * @param _merkleRoot merkle root for token distribution
     * @param _totalAmount total distribution amount
     * @param _expiryTimestamp timestamp when unclaimed tokens can be withdrawn
     **/
    function addDistribution(
        address _token,
        bytes32 _merkleRoot,
        uint256 _totalAmount,
        uint256 _expiryTimestamp
    ) public onlyOwner {
        require(distributions[_token].token == address(0), "MerkleDistributor: Distribution is already added.");
        require(IERC20(_token).balanceOf(address(this)) >= _totalAmount, "MerkleDistributor: Insufficient balance.");

        tokens.push(_token);
        distributions[_token].token = _token;
        distributions[_token].merkleRoot = _merkleRoot;
        distributions[_token].totalAmount = _totalAmount;
        distributions[_token].expiryTimestamp = _expiryTimestamp;

        emit DistributionAdded(tokens.length - 1, _token, _totalAmount, _expiryTimestamp);
    }

    /**
     * @notice update multiple token distributions
     * @param _tokens the list of token addresses to update
     * @param _merkleRoots list of updated merkle roots for the distributions
     * @param _additionalAmounts list of total additional distribution amounts for each token
     * @param _expiryTimestamps list of updated expiry timestamps for each distribution
     **/
    function updateDistributions(
        address[] calldata _tokens,
        bytes32[] calldata _merkleRoots,
        uint256[] calldata _additionalAmounts,
        uint256[] calldata _expiryTimestamps
    ) external onlyOwner {
        require(
            _tokens.length == _merkleRoots.length && _tokens.length == _additionalAmounts.length,
            "MerkleDistributor: Array lengths need to match."
        );

        for (uint256 i = 0; i < _tokens.length; i++) {
            updateDistribution(_tokens[i], _merkleRoots[i], _additionalAmounts[i], _expiryTimestamps[i]);
        }
    }

    /**
     * @notice update a token distribution
     * @dev merkle root should be updated to reflect additional amount - the amount for each
     * account should be incremented by any additional allocation and any new accounts should be added
     * to the tree
     * @param _token token address
     * @param _merkleRoot updated merkle root for token distribution
     * @param _additionalAmount total additional distribution amount
     * @param _expiryTimestamp timestamp when unclaimed tokens can be withdrawn
     **/
    function updateDistribution(
        address _token,
        bytes32 _merkleRoot,
        uint256 _additionalAmount,
        uint256 _expiryTimestamp
    ) public onlyOwner distributionExists(_token) {
        require(!distributions[_token].isPaused, "MerkleDistributor: Distribution is paused.");
        require(IERC20(_token).balanceOf(address(this)) >= _additionalAmount, "MerkleDistributor: Insufficient balance.");
        require(_expiryTimestamp >= distributions[_token].expiryTimestamp, "MerkleDistributor: Invalid expiry timestamp.");

        distributions[_token].merkleRoot = _merkleRoot;
        distributions[_token].totalAmount += _additionalAmount;
        distributions[_token].expiryTimestamp = _expiryTimestamp;

        emit DistributionUpdated(_token, _additionalAmount, _expiryTimestamp);
    }

    /**
     * @notice claim multiple token distributions
     * @param _tokens list of token address
     * @param _indexes list of indexes of the claims within the distributions
     * @param _account address of the account to claim for
     * @param _amounts list of lifetime amounts of the tokens allocated to account
     * @param _merkleProofs list of merkle proofs for the token claims
     **/
    function claimDistributions(
        address[] calldata _tokens,
        uint256[] calldata _indexes,
        address _account,
        uint256[] calldata _amounts,
        bytes32[][] calldata _merkleProofs
    ) external {
        require(
            _tokens.length == _indexes.length && _tokens.length == _amounts.length && _tokens.length == _merkleProofs.length,
            "MerkleDistributor: Array lengths need to match."
        );

        for (uint256 i = 0; i < _tokens.length; i++) {
            claimDistribution(_tokens[i], _indexes[i], _account, _amounts[i], _merkleProofs[i]);
        }
    }

    /**
     * @notice claim a token distribution
     * @param _token token address
     * @param _index index of the claim within the distribution
     * @param _account address of the account to claim for
     * @param _amount lifetime amount of the token allocated to account
     * @param _merkleProof the merkle proof for the token claim
     **/
    function claimDistribution(
        address _token,
        uint256 _index,
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) public distributionExists(_token) {
        require(!distributions[_token].isPaused, "MerkleDistributor: Distribution is paused.");
        Distribution storage distribution = distributions[_token];

        bytes32 node = keccak256(abi.encodePacked(_index, _account, _amount));
        require(MerkleProof.verify(_merkleProof, distribution.merkleRoot, node), "MerkleDistributor: Invalid proof.");

        require(distribution.claimed[_account] < _amount, "MerkleDistributor: No claimable tokens.");

        uint256 amount = _amount - distribution.claimed[_account];
        distribution.claimed[_account] = _amount;
        IERC20(_token).safeTransfer(_account, amount);

        emit Claimed(_token, _index, _account, amount);
    }

    /**
     * @notice withdraws unclaimed tokens
     * @dev merkle root should be updated to reflect current state of claims - the amount for each
     * account should be equal to it's claimed amount
     * @param _token token address
     * @param _merkleRoot updated merkle root
     * @param _totalAmount updated total amount
     **/
    function withdrawUnclaimedTokens(
        address _token,
        bytes32 _merkleRoot,
        uint256 _totalAmount
    ) external onlyOwner distributionExists(_token) {
        require(distributions[_token].isPaused, "MerkleDistributor: Distribution is not paused.");

        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.safeTransfer(msg.sender, balance);
        }

        distributions[_token].merkleRoot = _merkleRoot;
        distributions[_token].totalAmount = _totalAmount;
        distributions[_token].isPaused = false;
    }

    /**
     * @notice pauses a token distribution for withdrawal of unclaimed tokens
     * @dev must be called before withdrawUnlclaimedTokens to ensure state doesn't change
     * while the new merkle root is calculated
     * @param _token token address
     **/
    function pauseForWithdrawal(address _token) external onlyOwner distributionExists(_token) {
        require(
            distributions[_token].expiryTimestamp <= block.timestamp,
            "MerkleDistributor: Expiry timestamp not reached."
        );
        require(!distributions[_token].isPaused, "MerkleDistributor: Already paused.");
        distributions[_token].isPaused = true;
    }

    /**
     * @notice sets the timestamp when unclaimed tokens can be withdrawn for a token distribution
     * @param _token token address
     * @param _expiryTimestamp expiry timestamp
     **/
    function setExpiryTimestamp(address _token, uint256 _expiryTimestamp) external onlyOwner distributionExists(_token) {
        require(!distributions[_token].isPaused, "MerkleDistributor: Distribution is paused.");
        require(_expiryTimestamp >= distributions[_token].expiryTimestamp, "MerkleDistributor: Invalid expiry timestamp.");
        distributions[_token].expiryTimestamp = _expiryTimestamp;
        emit SetExpiryTimestamp(_token, _expiryTimestamp);
    }
}