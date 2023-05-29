// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interface/IRouter.sol";
import "./ERC721BasicFrame.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libs/BitOperator.sol";

contract DHVN is ERC721BasicFrame {
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
     * 1        update index like burnin without changing token id
     * 2..9     currentUpdateIndex
     */
    uint256 private constant BITPOS_LOCK_STATUS = 0;
    uint256 private constant BITPOS_UPDATE_INDEX = BITPOS_LOCK_STATUS + 1;
    uint256 private constant BITPOS_CURRENT_UPDATE_INDEX = BITPOS_UPDATE_INDEX + 8;

    uint8 public currentUpdateIndex;
    IRouter public router;

    event UpdateToken(uint256 indexed tokenId, uint8 indexed updateIndex);
    event IncreaseUpdateIndex(uint8 indexed updateIndex);
    
    error InvalidUpdateIndex();
    error ZeroUpdateIndex();
    error RouterNotSet();
    
    ///////////////////////////////////////////////////////////////////////////
    // Constructor
    ///////////////////////////////////////////////////////////////////////////
    constructor() ERC721BasicFrame("DAO Heaven", "DHV", 777) {
        // default royalty set
        _setDefaultRoyalty(
            IEIP2981RoyaltyOverride.TokenRoyalty({bps: 1000, recipient: 0xFBb189698A54570d5c82399486049b6f5D008923})
        );
        // Grants minter and burner role for owner address
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(UPDATER_ROLE, msg.sender);
        // Please burn by yourself for token number starts from 1
        _mint(msg.sender, 1);   // tokenId 0
        _mint(0x2F4F52FCb7C752d6847B9d333c47A77a49E3977C, 20);
        _mint(0x108BE80b8f2E44034171723AC720A7177b002FAE, 15);
        _mint(0x45E39b215C7F4890A4F8f9b35e5d963c61B97828, 10);
        _mint(0x36839f9a73C8305ad4626f712cB011FD8B448310, 9);
        _mint(0x2ab41637C245950ace453fB2C1863F3641FCE83b, 8);
        _mint(0x24aae0A135985Dc8aE6B8BaC64051aF645C2b3f9, 7);
        _mint(0x2c45a206f3Ba662c69e9Ae9831B56f6242e2b16F, 7);
        _mint(0x4519a5973d718C184Fe8823e95A3549b8B48A5be, 5);
        _mint(0x74087c451c335645D9DF705DF4B8567425d36fEE, 5);
        _mint(0xBb6Ac8101DF081AC7A2639168734Bc18Aaaf06Da, 3);
        _mint(0xA581532f474915867eC82059242CcCc7d5118DFf, 2);
        _mint(0xdf6e1e8945bcB7f1B17f4D83e36Ab79a5d724607, 1);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Setter functions : router
    ///////////////////////////////////////////////////////////////////////////
    function setRouter(IRouter _router) external onlyAdmin{
        router = _router;
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
        param = param.setBitValueUint8(BITPOS_CURRENT_UPDATE_INDEX,currentUpdateIndex);

        return router.tokenURI(tokenId,param);
    }
}