// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721ALowCap.sol";

contract Spaceship is ERC721ALowCap, AccessControl, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address private stakingAddress;
    string private tokenBaseURI;
    uint256 public mintableSupply;
    uint256 public currentMinted;
    uint256 public currMerkleIndex;

    mapping(uint256 => bytes32) private whitelistMerkleRoots;
    mapping(uint256 => mapping(address => uint256))
        private whitelistClaimedMapping;

    bool public whitelistPaused; // toggle

    bytes32 public WL_ADMIN = keccak256("WHITELIST_ADMIN"); // solhint-disable-line

    constructor()
        ERC721A("Notorious Alien Space Agents Spaceships", "SPACESHIP")
    {
        currentMinted = 0;
        mintableSupply = 8888;

        whitelistPaused = false;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(WL_ADMIN, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mintWithMerkle(
        uint256 redeemableAmount,
        bytes32[] calldata proof,
        uint256 redeemAmount
    ) external whenWhitelistActive nonReentrant {
        address redeemer = msg.sender;
        if (
            !_verifyWhitelistMerkle(
                _whitelistLeaf(redeemer, redeemableAmount),
                proof
            )
        ) {
            revert InvalidRedeemer();
        }

        uint256 claimedSoFar = whitelistClaimedMapping[currMerkleIndex][
            redeemer
        ];

        // if the claimedAmountSoFar + the amount intended to redeem is larger than amount available, throw
        // if redeem amount + current minted > total supply, throw
        if (
            (currentMinted + redeemAmount > mintableSupply) ||
            (claimedSoFar + redeemAmount > redeemableAmount)
        ) {
            revert NotEnoughRedeemsAvailable();
        }

        whitelistClaimedMapping[currMerkleIndex][redeemer] += redeemAmount;
        _mintSpaceship(redeemer, redeemAmount);
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        // allow the staking contract to transfer without approval to save one transaction fee.
        if (_operator == stakingAddress) {
            return true;
        }
        return super.isApprovedForAll(_owner, _operator);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(tokenBaseURI, Strings.toString(tokenId)));
    }

    // -------------------------------- internals

    /**
     * @dev internal function for minting Burger
     */
    function _mintSpaceship(address to, uint256 quantity_) internal {
        currentMinted += quantity_;
        _safeMint(to, quantity_);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _whitelistLeaf(address account, uint256 redeemableAmount)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, redeemableAmount));
    }

    function _verifyWhitelistMerkle(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                proof,
                whitelistMerkleRoots[currMerkleIndex],
                leaf
            );
    }

    // -------------------------------- getters

    function getMintedAmounts(uint256 merkleIndex, address minter)
        public
        view
        returns (uint256)
    {
        return whitelistClaimedMapping[merkleIndex][minter];
    }

    function getMerkleRoot(uint256 rootIndex) public view returns (bytes32) {
        return whitelistMerkleRoots[rootIndex];
    }

    // -------------------------------- admin setter functions
    function setBaseURI(string memory baseURI_) external onlyOwner {
        tokenBaseURI = baseURI_;
    }

    function setStakingAddress(address address_) external onlyOwner {
        stakingAddress = address_;
    }

    function setMaxTokens(uint256 mintableSupply_) external onlyOwner {
        if (mintableSupply_ < mintableSupply) {
            revert InvalidNewMax();
        }
        mintableSupply = mintableSupply_;
    }

    function setMintableSupply(uint256 _mintableSupply) external onlyOwner {
        if (_mintableSupply < currentMinted) {
            revert InvalidmintableSupplyAdmin();
        }

        mintableSupply = _mintableSupply;
    }

    function toggleWhitelistPause() external adminOrWL {
        if (whitelistPaused) {
            emit WhitelistActiveEvent();
        } else {
            emit WhitelistPausedEvent();
        }
        whitelistPaused = !whitelistPaused;
    }

    function setNextMerkleRoot(bytes32 merkleRoot) external adminOrWL {
        if (merkleRoot == 0) {
            revert InvalidMerkleRoot();
        }

        // This will invalidate the previous merkle from being claimed
        currMerkleIndex += 1;
        whitelistMerkleRoots[currMerkleIndex] = merkleRoot;
        whitelistPaused = false;
    }

    // ---------------------- Modifiers

    modifier whenWhitelistActive() {
        if (whitelistPaused) {
            revert WhitelistPausedError();
        }
        _;
    }

    modifier adminOrWL() {
        if (
            !(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(WL_ADMIN, msg.sender))
        ) {
            revert InvalidRole();
        }
        _;
    }

    // -------------------- Errors
    error InvalidNewMax();
    error WhitelistPausedError();
    error InvalidRole();
    error InvalidMerkleRoot();
    error InvalidRedeemer();
    error NotEnoughRedeemsAvailable();
    error PublicMintPausedError();
    error NotYourSpaceship();
    error InvalidmintableSupplyAdmin();
    error InvalidMaxMintCount();

    // -------------------- Events
    event WhitelistPausedEvent();
    event WhitelistActiveEvent();
    event PublicMintActiveEvent();
    event PublicMintPausedEvent();
}