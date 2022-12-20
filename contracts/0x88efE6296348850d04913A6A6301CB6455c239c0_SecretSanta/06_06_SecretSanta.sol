// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████▀▀╙╙╙└     ,▄▓██████████
// █████████████████████████████████████████▀▀▀▀▀╙╙'   ¡╟▓      ,,,▄▓▓█████████████
// ████████████████████████▀▀╙╙╙╙╙▀▀█████▒         ,▄▄▓██▌    ⁿ▀▀▀▀▀▀██████████████
// ██████████████████▀╙              ╚███     ▓▓▓████████          ╓▓██████████████
// ██████████████████,     ╔▓▓▓██▒    ╟█          ,╟▓███▌    ╔▄▄▓██████████████████
// ███████████████████ε    ▓█████╩    ╠⌐    ≡▄▄▄▓███████╬   ╔██████████████████████
// ██████████████████▌    ╟████▀`    ▄▌   «▓██▀▀▀▀▀╙╙╠╠╣▒  ╔███████████████████████
// ██████████████████    ║███╨     ╔██╬          ,╔▓████▓▒▄████████████████████████
// █████████████████▓   ╔█▀`    ,▄████▌ ,,,╓▄▄▓▓███████████████████████████████████
// █████████████████▌,;φ╙   ,╔▓████████▓███████████████████████████████████████████
// ██████████████████▓▒╓▄▄▓████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀

/**
 * @author emrecolako.eth
 * @title SecretSanta for DEF DAO!
 */

contract SecretSanta is ERC721Holder {
    /// @notice Individual NFT details + Index
    struct Vault {
        address erc721Address;
        uint256 erc721TokenId;
        uint256 erc721Index;
    }

    /// @notice Gift address & tokenId
    struct Gift {
        address erc721Address;
        uint256 erc721TokenId;
    }

    /*//////////////////////////////////////////////////////////////
                          ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice If user has already collected
    error AlreadyCollected();
    /// @notice If collection period is not active
    error CollectionPeriodIsNotActive();
    /// @notice Throws error if depositWindow is closed
    error DepositWindowClosed();
    /// @notice If user has already deposited
    error GiftAlreadyDeposited();
    /// @notice User isn't allowed
    error MerkleProofInvalid();
    /// @notice If user hasn't made any deposits
    error No_Deposits();
    /// @notice No Gifts available
    error No_Gifts_Available();
    /// @notice If user is not the token owner
    error NotTokenOwner();
    /// @notice If user is not the owner of the contract
    error NotOwner();
    /// @notice Throws error if address = 0
    error ZeroAddress();

    uint256 public reclaimTimestamp;
    uint256 private _offSet;
    address public ownerAddress;
    bool public collectionOpen = false;

    bytes32 public merkleRoot;

    Gift[] public gifts;

    mapping(address => Vault) public Depositors;
    mapping(address => Gift) public collectedGifts;
    mapping(address => uint256) public DepositCount;
    mapping(address => bool) public depositedGifts;

    // Events
    event AllowlistUpdated(bytes32 merkleRoot);
    event GiftCollected(
        address erc721Address,
        address senderAddress,
        uint256 erc721TokenId
    );

    event GiftDeposited(
        address erc721Address,
        address senderAddress,
        uint256 erc721TokenId
    );

    /*//////////////////////////////////////////////////////////////
                          MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier nonZeroAddress(address _nftaddress) {
        if (_nftaddress == address(0)) revert ZeroAddress();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != ownerAddress) revert NotOwner();
        _;
    }

    modifier onlyOwnerOf(address _nftaddress, uint256 _tokenId) {
        if (
            msg.sender != IERC721(_nftaddress).ownerOf(_tokenId) &&
            msg.sender != IERC721(_nftaddress).getApproved(_tokenId)
        ) revert NotTokenOwner();
        _;
    }

    // @notice Requires a valid merkle proof for the specified merkle root.
    modifier onlyIfValidMerkleProof(bytes32 root, bytes32[] calldata proof) {
        if (
            !MerkleProof.verify(
                proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) {
            revert MerkleProofInvalid();
        }
        _;
    }

    modifier CollectionPeriodActive() {
        if (!collectionOpen) revert CollectionPeriodIsNotActive();
        _;
    }

    modifier DepositWindowActive() {
        if (collectionOpen) revert DepositWindowClosed();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                          CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(uint256 _reclaimTimestamp, bytes32 _merkleRoot) {
        reclaimTimestamp = _reclaimTimestamp;
        ownerAddress = msg.sender;
        merkleRoot = _merkleRoot;
    }

    /*//////////////////////////////////////////////////////////////
                          SANTA FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows users to deposit gifts
    function deposit(
        address _nftaddress,
        uint256 _tokenId,
        bytes32[] calldata proof
    )
        public
        nonZeroAddress(_nftaddress)
        onlyOwnerOf(_nftaddress, _tokenId)
        onlyIfValidMerkleProof(merkleRoot, proof)
        DepositWindowActive
    {
        // Check if the user has already deposited a gift
        if (depositedGifts[msg.sender]) {
            revert GiftAlreadyDeposited();
        }

        IERC721(_nftaddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        gifts.push(Gift(_nftaddress, _tokenId));

        DepositCount[msg.sender]++;
        Depositors[msg.sender] = Vault(_nftaddress, _tokenId, gifts.length);

        // Mark the user as having deposited a gift
        depositedGifts[msg.sender] = true;
        emit GiftDeposited(_nftaddress, msg.sender, _tokenId);
    }

    function toggleCollection() public onlyOwner {
        collectionOpen = !collectionOpen;
    }

    /// @notice Allows depositors to collect gifts
    function collect() public CollectionPeriodActive {
        if (!depositedGifts[msg.sender]) {
            revert No_Deposits();
        }

        if (collectedGifts[msg.sender].erc721Address != address(0))
            revert AlreadyCollected();

        uint256 giftIdx;

        if (gifts.length == 0) {
            revert No_Gifts_Available();
        } else if (gifts.length == 1) {
            giftIdx = 0;
        } else if (gifts.length == 2) {
            giftIdx = (_offSet % 2 == 0) ? 0 : 1;
        } else {
            uint256 randomNumber = _randomNumber();
            giftIdx = ((randomNumber % gifts.length) + _offSet) % gifts.length;
        }

        Gift memory gift = gifts[giftIdx];

        emit GiftCollected(gift.erc721Address, msg.sender, gift.erc721TokenId);

        IERC721(gift.erc721Address).safeTransferFrom(
            address(this),
            msg.sender,
            gift.erc721TokenId
        );

        _offSet = _offSet + 1;
    }

    /*//////////////////////////////////////////////////////////////
                          ALLOWLIST FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // @notice Allows users to check if their wallet has been allowlisted
    function allowListed(address _wallet, bytes32[] calldata _proof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _proof,
                merkleRoot,
                keccak256(abi.encodePacked(_wallet))
            );
    }

    // @notice Updates merkleRoot of allowlist
    function updateAllowList(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit AllowlistUpdated(merkleRoot);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL + ADMIN
    //////////////////////////////////////////////////////////////*/

    /// @notice Random number generator
    function _randomNumber() internal view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    gifts.length,
                    block.number,
                    blockhash(block.number - 1),
                    msg.sender,
                    tx.gasprice
                )
            )
        );
        return randomNumber;
    }

    /// @notice Emergency function to withdraw certain NFT
    function adminWithdraw(
        address _nftaddress,
        uint256 _tokenId,
        address recipient
    ) external onlyOwner {
        IERC721(_nftaddress).transferFrom(address(this), recipient, _tokenId);
    }

    ///@notice function that allows the contract owner to reclaim uncollected gifts
    function reclaimGifts(address _transferAddress) public onlyOwner {
        // Check if the reclaim timestamp has passed
        if (block.timestamp < reclaimTimestamp) {
            // Reclaim timestamp has not passed, do nothing
            return;
        }

        // Loop through all gifts and check if they have been collected
        for (uint256 i = 0; i < gifts.length; i++) {
            Gift memory gift = gifts[i];
            if (gift.erc721Address == address(0)) continue;

            // Check if the gift has been collected
            if (
                IERC721(gift.erc721Address).ownerOf(gift.erc721TokenId) !=
                address(this)
            ) {
                // Gift has been collected, do nothing
                continue;
            }

            // Gift has not been collected, reclaim it
            if (_transferAddress == address(0)) {
                // Transfer the gift back to the original depositor
                IERC721(gift.erc721Address).safeTransferFrom(
                    ownerAddress,
                    IERC721(gift.erc721Address).ownerOf(gift.erc721TokenId),
                    gift.erc721TokenId
                );
            } else {
                // Transfer the gift to the specified address
                IERC721(gift.erc721Address).safeTransferFrom(
                    ownerAddress,
                    _transferAddress,
                    gift.erc721TokenId
                );
            }
        }
    }
}