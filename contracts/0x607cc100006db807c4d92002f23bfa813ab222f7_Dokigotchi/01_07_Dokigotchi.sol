// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'lib/ERC721A/contracts/ERC721A.sol';

import 'lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol';

import 'lib/solmate/src/auth/Owned.sol';
import 'lib/solmate/src/utils/ReentrancyGuard.sol';
import 'lib/solmate/src/tokens/ERC20.sol';

error NotEOA();
error NotOwner();
error NotDevs();
error NotArtists();
error InvalidAddress();

error MintPriceNotPaid();
error MintLimitReached();
error MintStartTime();

error MaxHonoraries();
error MaxSupply();

error AlreadyClaimed();
error InvalidMerkleProof();
error NonExistentTokenURI();

error Ownership();
error NotEnoughGasToTeleport();

contract Dokigotchi is ERC721A, Owned, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant MAX_HONORARIES = 41;
    uint256 public constant MAX_MINT_PER_TX = 20;

    uint256 public immutable mintPrice;

    bytes32 public merkleRoot;
    uint256 public whitelistStartTime;
    uint256 public publicStartTime;

    address public artists;
    address public devs;

    mapping(address => bool) public claimed;

    string public baseURI;

    /// @dev Contract constructor.
    /// @param _name name of the NFT.
    /// @param _symbol symbol of the NFT.
    /// @param _uri base URL that all tokens will share.
    /// @param _mintPrice mint price per NFT.
    /// @param _merkleRoot merkle root for the whitelist.
    /// @param _whitelistStartTime start of the whitelisted mint.
    /// @param _publicStartTime start of the public mint.
    /// @param _artists address to pay out artists rewards.
    /// @param _devs address to pay out devs rewards.
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _mintPrice,
        bytes32 _merkleRoot,
        uint256 _whitelistStartTime,
        uint256 _publicStartTime,
        address _owner,
        address _artists,
        address _devs
    ) ERC721A(_name, _symbol) Owned(_owner) {
        mintPrice = _mintPrice;
        baseURI = _uri;
        merkleRoot = _merkleRoot;
        whitelistStartTime = _whitelistStartTime;
        publicStartTime = _publicStartTime;
        artists = _artists;
        devs = _devs;
    }

    /// @dev Prevents contracts from calling a function.
    modifier callerIsUser() {
        if (tx.origin != msg.sender) {
            revert NotEOA();
        }
        _;
    }

    // MINT FUNCTIONS.

    /// @notice Mints for free a limited number of honoraries.
    /// @param to The address of the honorary recipient.
    /// @param quantity Number of pets to mint.
    function honorariesMint(address to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > MAX_HONORARIES) {
            revert MaxHonoraries();
        }

        _safeMint(to, quantity);
    }

    /// @notice Mints one pet for whitelisted addresses.
    /// @param merkleProof merkle proof for the msg.sender
    function whitelistMint(bytes32[] calldata merkleProof)
        external
        payable
        callerIsUser
    {
        if (block.timestamp < whitelistStartTime) {
            revert MintStartTime();
        }
        if (msg.value != mintPrice) {
            revert MintPriceNotPaid();
        }
        if (totalSupply() + 1 > MAX_SUPPLY) {
            revert MaxSupply();
        }
        if (claimed[msg.sender] == true) {
            revert AlreadyClaimed();
        }
        if (
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                toBytes32(msg.sender)
            ) == false
        ) {
            revert InvalidMerkleProof();
        }

        claimed[msg.sender] = true;

        _mint(msg.sender, 1);
    }

    /// @notice Mints pets during the public sale.
    /// @param quantity Number of pets to mint.
    function publicMint(uint256 quantity) external payable callerIsUser {
        if (block.timestamp < publicStartTime) {
            revert MintStartTime();
        }
        if (quantity > MAX_MINT_PER_TX) {
            revert MintLimitReached();
        }
        if (msg.value != mintPrice * quantity) {
            revert MintPriceNotPaid();
        }
        if (totalSupply() + quantity > MAX_SUPPLY) {
            revert MaxSupply();
        }

        _mint(msg.sender, quantity);
    }

    // ADMIN FUNCTIONS.

    /// @notice Sets the base URI for the collection.
    /// @dev Needed for the reveal. Can burn owner after nfts are fully minted.
    /// @param uri The new base URI to use.
    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    /// @notice Returns the base URI for the collection
    /// @dev Used internally by ERC721A.
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice Updates the merkle root used to validate the whitelist sale.
    /// @param _merkleRoot New merkle root.
    function setMerkleRoot(bytes32 _merkleRoot)
        external
        onlyOwner
    {
        if (block.timestamp > whitelistStartTime) {
            revert MintStartTime();
        }
        merkleRoot = _merkleRoot;
    }

    /// @notice Sets the start of the whitelist sale.
    /// @param _whitelistStartTime New start time.
    function setWhitelistStartTime(uint256 _whitelistStartTime)
        external
        onlyOwner
    {
        if (block.timestamp > _whitelistStartTime) {
            revert MintStartTime();
        }
        whitelistStartTime = _whitelistStartTime;
    }

    /// @notice Sets the start of the public sale.
    /// @param _publicStartTime New start time.
    function setPublicStartTime(uint256 _publicStartTime) external onlyOwner {
        if (block.timestamp > _publicStartTime) {
            revert MintStartTime();
        }
        publicStartTime = _publicStartTime;
    }

    /// @notice Sets a new address for artist payouts.
    /// @dev In case the artists want a new recipient address.
    /// @param _artists New address to use.
    function setArtists(address _artists) external {
        if (msg.sender != artists) {
            revert NotArtists();
        }
        if (_artists == address(0)) {
            revert InvalidAddress();
        }
        if (_artists == owner) {
            revert NotOwner();
        }

        artists = _artists;
    }

    /// @notice Sets a new address for devs payouts.
    /// @dev In case the devs want a new recipient address.
    /// @param _devs New address to use.
    function setDevs(address _devs) external {
        if (msg.sender != devs) {
            revert NotDevs();
        }
        if (_devs == address(0)) {
            revert InvalidAddress();
        }
        if (_devs == owner) {
            revert NotOwner();
        }

        devs = _devs;
    }

    /// @notice Sends sale funds to devs and artists.
    /// @dev 30% go to devs and 70% to the artists.
    function retrieveFunds() external nonReentrant {
        uint256 bal = address(this).balance;
        uint256 devShare = (bal * 30) / 100;
        safeTransferETH(devs, devShare);

        bal = address(this).balance;
        safeTransferETH(artists, bal);
    }

    // AUX FUNCTIONS.

    /// @notice Safe low level ETH transfer call (solmate).
    /// @dev Used while retrieving funds from the smart contract.
    /// @param to Destination address.
    /// @param amount How much ether will be transfered.
    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, 'ETH_TRANSFER_FAILED');
    }

    /// @notice Convert addresses to bytes32.
    /// @dev Needed for merkle proof verification.
    /// @param addr The address to convert.
    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    /// EMERGENCY FUNCTIONS

    /// @notice Rescues ERC20 tokens sent to the contract by mistake.
    /// @param token Address of the ERC20 token to rescue.
    function rescue(address token) external onlyOwner {
        uint256 bal = ERC20(token).balanceOf(address(this));
        ERC20(token).transfer(msg.sender, bal);
    }
}