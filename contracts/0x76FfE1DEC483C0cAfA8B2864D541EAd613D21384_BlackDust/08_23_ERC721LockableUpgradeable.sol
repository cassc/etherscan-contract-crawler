// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "hardhat/console.sol";

import "./erc721-operator-filter/ERC721OperatorFilterUpgradeable.sol";
import "./IERC721Lockable.sol";
import "./OnlyExpellerUpgradeable.sol";

abstract contract ERC721LockableUpgradeable is
    OnlyExpellerUpgradeable,
    ERC721OperatorFilterUpgradeable
{
    error OwnerIndexOutOfBounds();
    error OwnerIndexNotExist();

    uint256 public mintedAmount;
    uint256 public collectionSize;

    /*///////////////////////////////////////////////////////////////
                            LOCKABLE EXTENSION STORAGE                        
    //////////////////////////////////////////////////////////////*/
    /**
    @notice Whether locking is currently allowed.
    @dev If false then locking is blocked, but unlocking is always allowed.
     */
    bool public lockingOpen;

    /**
    @dev tokenId to locking start time (0 = not locking).
     */
    mapping(uint256 => uint256) private lockingStarted;

    /**
    @dev Cumulative per-token locking, excluding the current period.
     */
    mapping(uint256 => uint256) private lockingTotal;

    mapping(uint256 => bool) private lockingTransfer;

    /*///////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/
    /**
    @dev Emitted when NFT begins locking.
     */
    event Locked(uint256 indexed tokenId);

    /**
    @dev Emitted when a NFT stops locking; either through standard means or
    by expulsion.
     */
    event Unlocked(uint256 indexed tokenId);

    /**
    @dev Emitted when a NFT is expelled from the lock.
     */
    event Expelled(uint256 indexed tokenId);

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        address tokenOwner = ownerOf(tokenId);

        require(
            msg.sender == tokenOwner ||
                isApprovedForAll(tokenOwner, msg.sender),
            "NOT_AUTHORIZED"
        );
        _;
    }

    function __ERC721Lockable_init(
        string memory name_,
        string memory symbol_,
        address expellerWallet_,
        uint256 collectionSize_
    ) internal onlyInitializing {
        __ERC721Lockable_init_unchained(
            name_,
            symbol_,
            expellerWallet_,
            collectionSize_
        );
    }

    function __ERC721Lockable_init_unchained(
        string memory name_,
        string memory symbol_,
        address expellerWallet_,
        uint256 collectionSize_
    ) internal onlyInitializing {
        lockingOpen = false;
        _setNewSupply(collectionSize_);

        __ERC721_init(name_, symbol_);
        __Ownable_init();
        __OnlyExpeller_init(expellerWallet_);
    }

    /*///////////////////////////////////////////////////////////////
                              LOCKABLE LOGIC
    //////////////////////////////////////////////////////////////*/
    /**
    @notice Toggles the `lockingOpen` flag.
     */
    function setLockingOpen(bool open) external onlyOwner {
        lockingOpen = open;
    }

    function lockingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool locking,
            uint256 current,
            uint256 total
        )
    {
        uint256 start = lockingStarted[tokenId];
        if (start != 0) {
            locking = true;
            current = block.timestamp - start;
        }
        total = current + lockingTotal[tokenId];
    }

    /**
    @notice Changes NFT's locking status.
    */
    function toggleLocking(uint256 tokenId)
        internal
        onlyApprovedOrOwner(tokenId)
    {
        uint256 start = lockingStarted[tokenId];
        if (start == 0) {
            require(lockingOpen, "Locking closed");
            lockingStarted[tokenId] = block.timestamp;
            emit Locked(tokenId);
        } else {
            lockingTotal[tokenId] += block.timestamp - start;
            lockingStarted[tokenId] = 0;
            emit Unlocked(tokenId);
        }
    }

    /**
    @notice Changes multiple NFTs' locking status.
     */
    function toggleLocking(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleLocking(tokenIds[i]);
        }
    }

    /**
    @notice Admin-only ability to expel NFT from the lock.
    @dev As most sales listings use off-chain signatures it's impossible to
    detect someone who has locked and then deliberately undercuts the floor
    price in the knowledge that the sale can't proceed. This function allows for
    monitoring of such practices and expulsion if abuse is detected, allowing
    the undercutting nft to be sold on the open market. Since OpenSea uses
    isApprovedForAll() in its pre-listing checks, we can't block by that means
    because locking would then be all-or-nothing for all of a particular owner's
    NFT.
     */
    function expelFromLock(uint256 tokenId) external onlyExpeller {
        require(
            lockingStarted[tokenId] != 0,
            "ERC721ALockableUpgradeable: not locked"
        );
        lockingTotal[tokenId] += block.timestamp - lockingStarted[tokenId];
        lockingStarted[tokenId] = 0;
        emit Unlocked(tokenId);
        emit Expelled(tokenId);
    }

    // /**
    // @notice Transfer a token between addresses while the NFT is minting,
    // thus not resetting the locking period.
    //  */
    function safeTransferWhileLocking(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == _msgSender(), "Only owner");
        lockingTransfer[tokenId] = true;
        safeTransferFrom(from, to, tokenId);
        lockingTransfer[tokenId] = false;
    }

    /*///////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(
            lockingStarted[tokenId] == 0 || lockingTransfer[tokenId] == true,
            "Locking"
        );
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            mintedAmount += 1;
        }
        if (to == address(0)) {
            mintedAmount -= 1;
        }

        if (to == address(0x000000000000000000000000000000000000dEaD)) {
            mintedAmount -= 1;
        }
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _burn(tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (
            // override(ERC721Upgradeable, IERC165Upgradeable)
            bool
        )
    {
        return
            interfaceId == type(IERC721Lockable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);

        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    /**
     * @notice Returns the total amount of tokens stored by the contract
     */
    function totalSupply() public view returns (uint256) {
        return mintedAmount;
    }

    /**
     * @notice Returns a token ID owned by `owner` at a given `index` of its token list.
     * @dev This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     * @param owner token owner
     * @param index index of its token list
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        if (index >= balanceOf(owner)) {
            revert OwnerIndexOutOfBounds();
        }

        uint256 currentIndex = 0;
        unchecked {
            for (uint256 tokenId = 0; tokenId < collectionSize; tokenId++) {
                if (_exists(tokenId) && owner == ownerOf(tokenId)) {
                    if (currentIndex == index) {
                        return tokenId;
                    }
                    currentIndex++;
                }
            }
        }

        // Execution should never reach this point.
        revert OwnerIndexNotExist();
    }

    function _setNewSupply(uint256 collectionSize_) internal {
        collectionSize = collectionSize_;
    }

    function setNewSupply(uint256 collectionSize_) public onlyOwner {
        _setNewSupply(collectionSize_);
    }
}