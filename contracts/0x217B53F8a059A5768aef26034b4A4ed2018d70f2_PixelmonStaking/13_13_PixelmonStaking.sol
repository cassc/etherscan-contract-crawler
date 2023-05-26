// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/// @notice Thrown when invalid destination address specified (address(0) or address(this))
error InvalidAddress();
/// @notice Thrown when provided token does not belongs to function caller
error NotAnOwner();
/// @notice Thrown when input array length limits exceeded or input array is empty
error InvalidInputArrayLength();
/// @notice Thrown when caller tries to stake token which has already been staked
error TokenWasStaked();
/// @notice Thrown when staking lock period not yet passed
error TokenLocked();
/// @notice Thrown when contract stake/unstake/claim functions is paused
error Paused();
/// @notice Thrown when emergencyUnstake function called in regular working mode
error NotAvailableInRegularMode();

/* solhint-disable not-rely-on-time */
contract PixelmonStaking is IERC721Receiver, Ownable, ReentrancyGuard, EIP712, AccessControl {
    /// @dev Use storage wisely
    /// structure will be packed in single storage word (32 bytes)
    /// sizeof(address) = 20 bytes
    /// sizeof(uint64) = 8 bytes
    /// sizeof(uint32) = 4 bytes
    struct StakeInfo {
        address owner;
        uint64 timestamp;
        uint32 rewardTokenId;
    }

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    string private constant SIGNING_DOMAIN = "Pixelmon-Staking";
    string private constant SIGNATURE_VERSION = "1";

    /// @notice Period of time during which the token cannot be unstaked
    uint256 public constant LOCK_PERIOD = 21 days;
    /// @notice Max amount of tokens to stake/unstake in single transaction
    uint256 public constant MAX_TOKENS_PER_STAKE = 25;
    
    /// @notice Pixelmon NFT contract address
    address public immutable pixelmonContract;
    /// @notice PixelmonTrainer NFT contract address
    address public immutable pixelmonTrainerContract;

    uint32 public rangeOneCurrentTokenId = 1;

    /// @notice Is contract main functions paused flag
    bool public paused;
    /// @notice Emergency mode flag, emergencyUnstake function available in this mode
    bool public emergencyMode;

    /// @notice Tokens stake info
    mapping(uint256 => StakeInfo) public stakes;
    

    event TokenRescue(address indexed token, address indexed to, uint256 indexed tokenId);
    event Pause(address indexed caller);
    event Unpause(address indexed caller);
    event ToggleEmergencyMode(bool _isEmergency);
    event Staked(address indexed _address, uint256 indexed pixelmonId, uint256 indexed trainerId);
    event Unstaked(address indexed _address, uint256 indexed _tokenId);
    
    modifier validInputLength(uint256[] calldata tokens) {
        if (tokens.length == 0 || tokens.length > MAX_TOKENS_PER_STAKE) {
            revert InvalidInputArrayLength();
        }
        _;
    }

    modifier validAddress(address _address) {
        if (_address == address(0) || _address == address(this)) {
            revert InvalidAddress();
        }
        _;
    }

    /// @dev Same as OpenZeppelin's pausable, just moved here to reduce gas
    modifier whenNotPaused() {
        if (paused) {
            revert Paused();
        }
        _;
    }

    constructor(
        address _pixelmonContract,
        address _pixelmonTrainerContract
    ) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        if (_pixelmonContract == address(0) || _pixelmonTrainerContract == address(0)) {
            revert InvalidAddress();
        }

        _grantRole(SIGNER_ROLE, msg.sender);

        pixelmonContract = _pixelmonContract;
        pixelmonTrainerContract = _pixelmonTrainerContract;
    }

    /// @notice Function to set new signature verifier address. Callable only by contract owner
    /// @param _signer new signer wallet address.
    function setSigner(address _signer) external onlyOwner {
        _grantRole(SIGNER_ROLE, _signer);
    }

    /// @notice Pause contract. Functions marked with whenNotPaused modifier will be paused. Callable only by contract owner
    function pause() public onlyOwner {
        paused = true;

        emit Pause(msg.sender);
    }

    /// @notice Unpause contract. Callable only by contract owner
    function unpause() external onlyOwner {
        paused = false;

        emit Unpause(msg.sender);
    }

    /// @notice Toggle emergency mode and enables emergencyUnstake function. Callable only by contract owner
    /// Contract will be paused, so stake/unstake/claim will not work until unpause
    /// @param _isEmergency bool flag
    function toggleEmergencyMode(bool _isEmergency) external onlyOwner {
        emergencyMode = _isEmergency;

        if (_isEmergency) {
            pause();
        }

        emit ToggleEmergencyMode(_isEmergency);
    }

    /// @notice Rescue stucked NFT tokens. Callable only by contract owner
    /// Cannot be used to transfer Pixelmon tokens
    /// @param token address of ERC721 contract
    /// @param to receiver address
    /// @param tokenId id of token to rescue
    function rescueNFT(
        address token,
        address to,
        uint256 tokenId
    ) external onlyOwner nonReentrant validAddress(token) validAddress(to) {
        // Contract owner shouldnt be able to transfer Pixelmons staker by user
        if (token == pixelmonContract) {
            revert InvalidAddress();
        }

        IERC721(token).safeTransferFrom(address(this), to, tokenId);

        emit TokenRescue(token, to, tokenId);
    }

    /// @dev To support safeTransfers of ERC721 if operator is this contract.
    /// Reverts on direct safeTransfers from anyone else
    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes calldata
    ) external view override returns (bytes4) {
        if (operator == address(this)) {
            return this.onERC721Received.selector;
        } else {
            return bytes4(0);
        }
    }

    function hashTokenIds(uint256[] calldata _tokenIds) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_tokenIds)));
    }

    /// @notice Verifies the signature for a given tokenIds hash and tokens owner, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to stake NFTs.
    function verifyStakingSignature(
        uint256[] calldata _tokenIds,
        address _tokenOwner,
        bytes calldata _signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("PixelmonSignature(uint256 tokenIds,address tokenOwner)"),
                    hashTokenIds(_tokenIds),
                    _tokenOwner
                )
            )
        );
        return ECDSA.recover(digest, _signature);
    }

    /// @notice Returns the chain id of the current blockchain.
    /// @dev This is used to workaround an issue with getting actual chaingID returning different values from the on-chain chainid() function and
    ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /// @notice Stake Pixelmon NFT tokens to receive PixelmonTrainer NFT  Range #1 tokens
    /// Lock period is 21 days
    /// @dev PixelmonTrainer tokens should be preminted to this contract, otherwise function will revert
    /// @param _tokenIds valid array of Pixelmon token ids to stake
    /// @param _signature signature to check validity of staking
    function stake(uint256[] calldata _tokenIds, bytes calldata _signature)
        external
        nonReentrant
        whenNotPaused
        validInputLength(_tokenIds)
    {
        uint32 _rewardTokenId = rangeOneCurrentTokenId;
        uint256 inputLength = _tokenIds.length;

        /// @dev make sure signature is valid and get the address of the signer
        address signer = verifyStakingSignature(_tokenIds, msg.sender, _signature);

        /// @dev make sure that the signer is authorized to mint NFTs
        require(hasRole(SIGNER_ROLE, signer), "Signature invalid or unauthorized");

        for (uint256 i = 0; i < inputLength; i = _uncheckedInc(i)) {
            uint256 tokenId = _tokenIds[i];

            if (isTokenStaked(tokenId)) {
                revert TokenWasStaked();
            }

            if (IERC721(pixelmonContract).ownerOf(tokenId) != msg.sender) {
                revert NotAnOwner();
            }

            stakes[tokenId] = StakeInfo(msg.sender, uint64(block.timestamp), _rewardTokenId);

            IERC721(pixelmonContract).safeTransferFrom(msg.sender, address(this), tokenId);
            IERC721(pixelmonTrainerContract).safeTransferFrom(
                address(this),
                msg.sender,
                _rewardTokenId
            );

            emit Staked(msg.sender, tokenId, _rewardTokenId);

            unchecked {
                ++_rewardTokenId;
            }
        }

        rangeOneCurrentTokenId = _rewardTokenId;
    }

    /// @notice Unstake Pixelmon tokens
    /// @param _tokenIds array of token ids to unstake
    function unstake(uint256[] calldata _tokenIds)
        external
        nonReentrant
        whenNotPaused
        validInputLength(_tokenIds)
    {
        uint256 inputLength = _tokenIds.length;

        for (uint256 i = 0; i < inputLength; i = _uncheckedInc(i)) {
            StakeInfo storage stakeInfo = stakes[_tokenIds[i]];

            if (stakeInfo.owner != msg.sender) {
                revert NotAnOwner();
            }

            if (stakeInfo.timestamp + LOCK_PERIOD >= block.timestamp) {
                revert TokenLocked();
            }

            _unstake(_tokenIds[i]);
        }
    }

    /// @notice Unstake tokens in emergency situation. Does not perform lock period check
    /// @dev Transfer tokens to address, specified in stakes info mapping
    /// @param _tokenIds array of tokens to unstake
    function emergencyUnstake(uint256[] calldata _tokenIds) external nonReentrant {
        if (!emergencyMode) {
            revert NotAvailableInRegularMode();
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _unstake(_tokenIds[i]);
        }
    }

    /// @notice Get token stake status
    /// @param _tokenId Pixelmon token id
    /// @return true if token was staked, otherwise false
    function isTokenStaked(uint256 _tokenId) public view returns (bool) {
        return stakes[_tokenId].owner != address(0);
    }

    /// @dev Helper functions for tokens unstake
    function _unstake(uint256 _tokenId) private {
        IERC721(pixelmonContract).safeTransferFrom(address(this), stakes[_tokenId].owner, _tokenId);

        emit Unstaked(msg.sender, _tokenId);
    }

    /// @dev Unchecked increment function, just to reduce gas usage
    /// @param val value to be incremented, should not overflow 2**256 - 1
    /// @return incremented value
    function _uncheckedInc(uint256 val) private pure returns (uint256) {
        unchecked {
            return val + 1;
        }
    }
}