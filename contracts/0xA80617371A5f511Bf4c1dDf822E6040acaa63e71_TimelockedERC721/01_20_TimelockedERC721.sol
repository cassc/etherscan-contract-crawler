// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

contract TimelockedERC721 is
    Initializable,
    ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant METADATA_MODIFIER_ROLE = keccak256("METADATA_MODIFIER_ROLE");

    mapping(uint256 => bool) public lockedTokens;

    uint256 public tokenUnlockTimestamp;

    bool public metadataUpdatable = true;

    string private _baseTokenURI;

    event TokenUnlockTimestampSet(address adminAddress, uint256 timestamp);
    event TokenLocked(address ownerAddress, uint256 tokenId);
    event MinterAdded(address minterAddress);
    event MinterRemoved(address minterAddress);

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Doesn't have admin role!"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Doesn't have minter role!"
        );
        _;
    }

    modifier onlyMetadataModifier() {
        require(
            hasRole(METADATA_MODIFIER_ROLE, _msgSender()),
            "Doesn't have metadata modifier role!"
        );
        _;
    }

    modifier futureTimestamp(uint256 timestamp_) {
        require(timestamp_ > block.timestamp, "timestamp must be in future!");
        _;
    }

    modifier metadataLocked() {
        require(
            metadataUpdatable,
            "Metadata cannot be updated!"
        );
        _;
    }

    modifier tokenLocked(uint256 tokenId_) {
        if (lockedTokens[tokenId_]) {
            if (block.timestamp >= tokenUnlockTimestamp) {
                // unlock tokens if we are at or past the unlock timestamp
                lockedTokens[tokenId_] = false;
            } else {
                // revert transaction if the token is still locked
                revert("token is locked!");
            }
        }
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 unlockTimestamp
    ) external virtual initializer futureTimestamp(unlockTimestamp) {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC721_init_unchained(name, symbol);
        __ERC721Enumerable_init_unchained();

        _baseTokenURI = baseTokenURI;
        tokenUnlockTimestamp = unlockTimestamp;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(METADATA_MODIFIER_ROLE, _msgSender());
    }

    function setTokenUnlockTimestamp(uint256 timestamp_)
        external
        onlyAdmin
        futureTimestamp(timestamp_)
    {
        tokenUnlockTimestamp = timestamp_;
        emit TokenUnlockTimestampSet(_msgSender(), timestamp_);
    }

    function removeMinter(address minter_) external onlyAdmin {
        revokeRole(MINTER_ROLE, minter_);
        emit MinterRemoved(minter_);
    }

    function addMinter(address minter_) external onlyAdmin {
        grantRole(MINTER_ROLE, minter_);
        emit MinterAdded(minter_);
    }

    function addMetadataModifier(address metadataUpdater_) external onlyAdmin {
        grantRole(METADATA_MODIFIER_ROLE, metadataUpdater_);
    }

    function updateBaseTokenURI(string memory newBaseTokenURI_) external onlyMetadataModifier metadataLocked {
        _baseTokenURI = newBaseTokenURI_;
    }

    function lockMetadata() external onlyMetadataModifier {
        metadataUpdatable = false;
    }


    function lockToken(uint256 tokenId) external {
        require(ownerOf(tokenId) == _msgSender(), "token not owned!");
        require(!lockedTokens[tokenId], "token already locked!");
        lockedTokens[tokenId] = true;
        emit TokenLocked(_msgSender(), tokenId);
    }

    function mint(address to_, uint256 id_) external onlyMinter {
        super._mint(to_, id_);
    }

    function batchMint(address to_, uint256[] memory ids_) external onlyMinter {
        for (uint256 i = 0; i < ids_.length; i++) {
            super._mint(to_, ids_[i]);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            AccessControlEnumerableUpgradeable,
            ERC721EnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        tokenLocked(tokenId_)
    {
        super._beforeTokenTransfer(from_, to_, tokenId_);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}