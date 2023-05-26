// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./libs/IMetadataRouter.sol";
import "./libs/ERC721BasicFrame.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libs/BitOperator.sol";

contract PixelHeroesVillains is ERC721BasicFrame {
    using Strings for uint256;
    using BitOperator for uint256;
    /*
     * @dev Token aux for routing parameter : bit layout
     * 0..7     update index like burnin without changing token id
     */
    uint256 private constant BITPOS_AUX_UPDATE_INDEX = 0;
    
    /*
     * @dev Routing parameter bit layout
     * 0        bool of lock status
     * 1..8     update index like burnin without changing token id
     */
    uint256 private constant BITPOS_LOCK_STATUS = 0;
    uint256 private constant BITPOS_UPDATE_INDEX = BITPOS_LOCK_STATUS + 1;

    uint8 public currentUpdateIndex;

    event UpdateToken(uint256 indexed tokenId, uint8 indexed updateIndex);
    event IncreaseUpdateIndex(uint8 indexed updateIndex);
    
    error InvalidUpdateIndex();
    error ZeroUpdateIndex();
    error RouterNotSet();
    IMetadataRouter public router;

    ///////////////////////////////////////////////////////////////////////////
    // Constructor
    ///////////////////////////////////////////////////////////////////////////
    constructor() ERC721BasicFrame("Pixel Heroes Villains", "PHV", 10000) {
        royaltyAddress = 0x56b75E59Ced86AB9C9eA4A0cAB89Db334620fA15;
        // Grants minter and burner role for owner address
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        // mint 1. please burn by yourself for token number starts from 1
        _mint(msg.sender, 1);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Setter functions : Metadata Router
    ///////////////////////////////////////////////////////////////////////////
    function setRouter(IMetadataRouter _new) external onlyAdmin {
        router = _new;
    }

    /**
      * @dev Allow administrators to change the lock status so that locked tokens are not listed in the marketplace.
      */
    function setTokenLockByAdmin(uint256[] calldata tokenIds, LockStatus lockStatus)
        external
        onlyAdmin
    {
        // _setTokenLock call _exists(tokenId) in ownerOf() function.
        // So this function calls internal function without checking token existance
        _setTokenLock(tokenIds, lockStatus);
    }
    ///////////////////////////////////////////////////////////////////////////
    // Update Index functions
    ///////////////////////////////////////////////////////////////////////////
    function getTokenUpdateIndex(uint256 tokenId) external view virtual returns(uint8){
        if (!_exists(tokenId)) revert TokenNonexistent(tokenId);
        return _getTokenUpdateIndex(tokenId);
    }

    function _getTokenUpdateIndex(uint256 tokenId) internal view virtual returns(uint8){
        return _getTokenAux(tokenId).getBitValueUint8(BITPOS_AUX_UPDATE_INDEX);
    }

    function updateToken(uint256 tokenId)
        external
        virtual
        onlyRole(UPDATER_ROLE)
    {
        // Grab from strage
        uint8 index = currentUpdateIndex;
        uint256 aux = _getTokenAux(tokenId);

        if (!_exists(tokenId)) revert TokenNonexistent(tokenId);
        if (index == 0) revert ZeroUpdateIndex();
        if (aux.getBitValueUint8(BITPOS_AUX_UPDATE_INDEX) >= index) revert InvalidUpdateIndex();
        emit UpdateToken(tokenId, index);
        _setTokenAux(tokenId, aux.setBitValueUint8(BITPOS_AUX_UPDATE_INDEX, index));
    }

    function increaseCurrentUpdateIndex()
        external
        virtual
        onlyRole(UPDATER_ROLE)
        returns(uint8)
    {
        uint8 newIndex = currentUpdateIndex++;
        emit IncreaseUpdateIndex(newIndex);
        return newIndex;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Metadata functions
    ///////////////////////////////////////////////////////////////////////////
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (address(router) == address(0)) revert RouterNotSet();
        if (!_exists(tokenId)) revert TokenNonexistent(tokenId);

        uint256 param = isLocked(tokenId) ? 1 : 0;
        param = param.setBitValueUint8(BITPOS_UPDATE_INDEX, _getTokenUpdateIndex(tokenId));

        return router.getURI(tokenId, ownerOf(tokenId), param);
    }


    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        // reset SubIdForToken when tansfers
        if (from != address(0) && address(router) != address(0)) {
            router.resetTokenPriority(startTokenId);
        }
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }

}