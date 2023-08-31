//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract MuskTokenDistributorV2 is Ownable {
    using ECDSA for bytes32;

    event Claim(address tokenOwner, uint256[] claimDays, uint256[] amounts, uint256 total);
    event Initialise(uint256 startTimestamp, bool isPaused);
    event SetIsPaused(bool paused);
    event SetTreasuryAddress(address treasuryAddress);
    event SetTrustedWallet(address trustedWallet);
    event SetMerkleTreeOwner(address merkleTreeOwner);
    event AddMerkleTreeRoots(bytes32[] treeRoots, uint256[] treeDays);
    event SetMerkleTreeRoot(bytes32 merkleTreeRoot, uint256 day);

    mapping(address => mapping(uint256 => bool)) private tokenClaims;

    mapping(uint256 => bytes32) public merkleTreeRoots;
    ERC20 public immutable muskToken;
    address public treasuryAddress;
    address public trustedWallet;
    address public merkleTreeOwner;
    uint256 public startTimestamp;
    bool public isInitialised = false;
    bool public isPaused = true;

    /**
     * @dev Only if the contract is not initialised
     **/
    modifier onlyNotInitialized() {
        require(isInitialised == false, 'MTD: already initialised');
        _;
    }

    /**
     * @dev Only if the contract is initialised
     **/
    modifier onlyInitialized() {
        require(isInitialised, 'MTD: not initialised');
        _;
    }

    /**
     * @dev Only if the contract is not paused
     **/
    modifier onlyNotPaused() {
        require(isPaused == false, 'MTD: paused');
        _;
    }

    /**
     * @dev Only if caller is the Merkle Tree owner
     **/
    modifier onlyMerkleTreeOwner() {
        require(msg.sender == merkleTreeOwner, 'MTD: not merkle tree owner');
        _;
    }

    constructor(
        address _muskToken,
        address _treasuryAddress,
        address _trustedWallet,
        address _merkleTreeOwner
    ) {
        require(_muskToken != address(0), 'MTD: invalid token address');

        muskToken = ERC20(_muskToken);
        _setTreasuryAddress(_treasuryAddress);
        _setTrustedWallet(_trustedWallet);
        _setMerkleTreeOwner(_merkleTreeOwner);
    }

    /**
     * @dev Initialise the contract
     * @param _startTimestamp The start timestamp after which $MUSK tokens can be claimed (in seconds)
     * @param _isPaused New isPaused value
     **/
    function initialise(uint256 _startTimestamp, bool _isPaused)
        external
        onlyNotInitialized
        onlyOwner
    {
        require(_startTimestamp > 0, 'MTD: invalid start timestamp');
        startTimestamp = _startTimestamp;
        isPaused = _isPaused;
        isInitialised = true;
        emit Initialise(_startTimestamp, _isPaused);
    }

    /**
     * @dev Setter for isPaused
     **/
    function setIsPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
        emit SetIsPaused(_isPaused);
    }

    /**
     * @dev Setter for treasuryAddress
     **/
    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        _setTreasuryAddress(_treasuryAddress);
        emit SetTreasuryAddress(_treasuryAddress);
    }

    /**
     * @dev Setter for treasuryAddress
     **/
    function _setTreasuryAddress(address _treasuryAddress) internal {
        require(_treasuryAddress != address(0), 'MTD: invalid treasury address');
        treasuryAddress = _treasuryAddress;
    }

    /**
     * @dev Setter for trustedWallet
     **/
    function setTrustedWallet(address _trustedWallet) external onlyOwner {
        _setTrustedWallet(_trustedWallet);
        emit SetTrustedWallet(_trustedWallet);
    }

    /**
     * @dev Setter for trustedWallet
     **/
    function _setTrustedWallet(address _trustedWallet) internal {
        require(_trustedWallet != address(0), 'MTD: invalid wallet address');
        trustedWallet = _trustedWallet;
    }

    /**
     * @dev Setter for merkleTreeOwner
     **/
    function setMerkleTreeOwner(address _merkleTreeOwner) external onlyOwner {
        _setMerkleTreeOwner(_merkleTreeOwner);
        emit SetMerkleTreeOwner(_merkleTreeOwner);
    }

    /**
     * @dev Setter for merkleTreeOwner
     **/
    function _setMerkleTreeOwner(address _merkleTreeOwner) internal {
        require(_merkleTreeOwner != address(0), 'MTD: invalid merkle tree owner');
        merkleTreeOwner = _merkleTreeOwner;
    }

    /**
     * @dev Add merkle tree roots
     * @param treeRoots The array of merkle tree roots
     * @param treeDays The array of days from start timestamp
     **/
    function addMerkleTreeRoots(bytes32[] calldata treeRoots, uint256[] calldata treeDays)
        external
        onlyMerkleTreeOwner
    {
        require(treeRoots.length > 0, 'MTD: empty treeRoots');
        require(treeRoots.length == treeDays.length, 'MTD: invalid treeDays length');

        uint256 today = _getDayFromStart(block.timestamp);

        for (uint256 i = 0; i < treeRoots.length; i++) {
            uint256 day = treeDays[i];
            require(merkleTreeRoots[day] == 0, 'MTD: already added');
            _setMerkleTreeRoot(treeRoots[i], day, today);
        }

        emit AddMerkleTreeRoots(treeRoots, treeDays);
    }

    /**
     * @dev Set merkle tree root for a day
     * @param merkleTreeRoot The merkle tree root
     * @param day The day from start timestamp
     **/
    function setMerkleTreeRoot(bytes32 merkleTreeRoot, uint256 day) external onlyOwner {
        uint256 today = _getDayFromStart(block.timestamp);
        _setMerkleTreeRoot(merkleTreeRoot, day, today);
        emit SetMerkleTreeRoot(merkleTreeRoot, day);
    }

    /**
     * @dev Set merkle tree root for a day
     * @param merkleTreeRoot The merkle tree root
     * @param day The day from start timestamp
     * @param today The current day from start timestamp
     **/
    function _setMerkleTreeRoot(
        bytes32 merkleTreeRoot,
        uint256 day,
        uint256 today
    ) internal {
        require(day > 0, 'MTD: invalid day');
        require(day < today, 'MTD: day not in the past');
        merkleTreeRoots[day] = merkleTreeRoot;
    }

    /**
     * @dev Claim $MUSK tokens
     * @param tokenOwner Owner address where the tokens will be transferred
     * @param claimDays The array claimed days
     * @param amounts The array of token amounts
     * @param signature Signature is based on tokenOwner + claim days + amounts
     * @param proofs The array of Merkle Tree Proofs
     **/
    function claim(
        address tokenOwner,
        uint256[] calldata claimDays,
        uint256[] calldata amounts,
        bytes calldata signature,
        bytes32[][] calldata proofs
    ) external onlyInitialized onlyNotPaused {
        require(claimDays.length > 0, 'MTD: empty claimDays');
        require(claimDays.length == amounts.length, 'MTD: invalid amounts length');
        require(claimDays.length == proofs.length, 'MTD: invalid proofs length');

        _checkSignature(_getHashArray(tokenOwner, claimDays, amounts), signature);

        uint256 total = 0;
        uint256 today = _getDayFromStart(block.timestamp);
        for (uint256 i = 0; i < claimDays.length; i++) {
            require(claimDays[i] > 0, 'MTD: invalid day');
            require(claimDays[i] < today, 'MTD: day not in the past');
            _claim(tokenOwner, claimDays[i], amounts[i], proofs[i]);
            total += amounts[i];
        }

        require(muskToken.transferFrom(treasuryAddress, tokenOwner, total), 'MTD: transfer failed');
        emit Claim(tokenOwner, claimDays, amounts, total);
    }

    function _claim(
        address tokenOwner,
        uint256 day,
        uint256 amount,
        bytes32[] calldata proof
    ) internal {
        require(amount > 0, 'MTD: invalid amount');
        require(tokenClaims[tokenOwner][day] == false, 'MTD: tokens already claimed');
        require(merkleTreeRoots[day] != bytes32(0), 'MTD: missing merkle tree');

        bytes32 hash = _getHash(tokenOwner, day, amount);
        require(MerkleProof.verify(proof, merkleTreeRoots[day], hash), 'MTD: invalid proof');

        tokenClaims[tokenOwner][day] = true;
    }

    /**
     * @dev Returns a hash based on address + day + amount
     * @param tokenOwner The address where the tokens will be transferred
     * @param day The day from start timestamp
     * @param amount The token amount
     **/
    function _getHash(
        address tokenOwner,
        uint256 day,
        uint256 amount
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(abi.encode(tokenOwner)),
                    keccak256(abi.encode(day)),
                    keccak256(abi.encode(amount))
                )
            );
    }

    /**
     * @dev Returns a hash based on address + claimDays + amounts
     * @param tokenOwner Token owner address
     * @param claimDays Array of claimDays
     * @param amounts Array of amounts
     **/
    function _getHashArray(
        address tokenOwner,
        uint256[] calldata claimDays,
        uint256[] calldata amounts
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(abi.encode(tokenOwner)),
                    keccak256(abi.encode(claimDays)),
                    keccak256(abi.encode(amounts))
                )
            );
    }

    /**
     * @dev Returns the day from start timestamp
     * @param timestamp The timestamp (in seconds)
     **/
    function _getDayFromStart(uint256 timestamp) internal view returns (uint256) {
        uint256 secondsFromStart = timestamp - startTimestamp;
        if (secondsFromStart < 1 days) {
            return 1;
        }

        return secondsFromStart / 1 days + 1;
    }

    function _checkSignature(bytes32 requestHash, bytes calldata signature) internal view {
        (address recovered, ECDSA.RecoverError error) = requestHash
            .toEthSignedMessageHash()
            .tryRecover(signature);
        require(
            error == ECDSA.RecoverError.NoError && recovered == trustedWallet,
            'MTD: not trusted wallet'
        );
    }
}