// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;
// solhint-disable not-rely-on-time, max-states-count

// inheritance
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "./lib/BaseRouter.sol";
import "../../lib/TokenHelper.sol";
import "../../interface/module/router/IZOARouterV1.sol";

// external interfaces
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../interface/core/IGameFiCoreV2.sol";
import "../../interface/module/shop/IGameFiShopV1.sol";
import "../../interface/core/IGameFiProfileVaultV2.sol";

/**
 * @author Alex Kaufmann
 * @dev Special smart contract for transaction aggregation and routing.
 */
contract ZOARouterV1 is
    Initializable,
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable,
    TokenHelper,
    Router,
    ITrustedForwarder,
    IZOARouterV1
{
    // TODO delete this
    // solhint-disable

    uint256 public _avatarPropertyId;
    uint256 public _usernamePropertyId;

    modifier onlyCoreAdmin() {
        require(
            IGameFiCoreV2(gameFiCore()).isAdmin(_msgSender()),
            "ZOARouterV1: caller is not the admin in GameFiCore"
        );
        _;
    }

    modifier onlyCoreAdminOrOperator() {
        require(
            IGameFiCoreV2(gameFiCore()).isAdmin(_msgSender()) || IGameFiCoreV2(gameFiCore()).isOperator(_msgSender()),
            "ZOARouterV1: caller is not the admin/operator in GameFiCore"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Constructor method (https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers).
     * @param gameFiCore_ GameFiCore contract address.
     * @param gameFiShops_ GameFiShop contract address.
     * @param gameFiMarketplace GameFiMarketplace contract address.
     * @param avatarPropertyId_ Property Id for avatars (in the GameFiCore).
     * @param usernamePropertyId_ Property Id for usernames (in the GameFiCore).
     */
    function initialize(
        address gameFiCore_,
        address gameFiShops_,
        address gameFiMarketplace,
        uint256 avatarPropertyId_,
        uint256 usernamePropertyId_
    ) external initializer {
        __Router_init(gameFiCore_, gameFiShops_, gameFiMarketplace);

        _avatarPropertyId = avatarPropertyId_;
        _usernamePropertyId = usernamePropertyId_;
    }

    /**
     * @dev Creates and configures a new profile.
     * @param avatarShopId Avatar shop id.
     * @param username Username string.
     */
    function createProfile(uint256 avatarShopId, bytes32 username)
        external
        returns (
            // TODO сделать create profile с переводом на контракте
            uint256 profileId_
        )
    {
        // mint gameFiCore profile
        (uint256 profileId, address profileVault) = IGameFiCoreV2(gameFiCore()).mintProfile(
            address(this),
            _getRandomSalt()
        );
        uint256 avatarId;

        // buy an avatar
        {
            IGameFiShopV1.Shop memory shopDetails = IGameFiShopV1(gameFiShops()).shopDetails(avatarShopId);
            require(shopDetails.tokenOutStandart == TokenStandart.ERC1155, "ZOARouterV1: wrong token standart");

            if (shopDetails.tokenInOffer.amount > 0) {
                _tokenTransferFrom(shopDetails.tokenInStandart, shopDetails.tokenInOffer, msg.sender, profileVault);
            }
            // approve
            bytes memory approveCall = abi.encodeWithSelector(
                IERC20Upgradeable.approve.selector,
                gameFiShops(),
                shopDetails.tokenInOffer.amount
            );
            IGameFiProfileVaultV2(profileVault).call(shopDetails.tokenInOffer.tokenContract, approveCall, 0);
            // buy avatar
            bytes memory buyAvatarCall = abi.encodeWithSelector(IGameFiShopV1.buyToken.selector, avatarShopId);
            IGameFiProfileVaultV2(profileVault).call(gameFiShops(), buyAvatarCall, 0);

            avatarId = shopDetails.tokenOutOffer.tokenId;
        }

        // set avatar property
        {
            IGameFiCoreV2.Property memory avatarPropertyDetails = IGameFiCoreV2(gameFiCore()).propertyDetails(
                _avatarPropertyId
            );
            if (avatarPropertyDetails.feeTokenStandart != TokenStandart.NULL) {
                _tokenTransferFrom(
                    avatarPropertyDetails.feeTokenStandart,
                    avatarPropertyDetails.feeToken,
                    _msgSender(),
                    address(this)
                );
                _tokenApprove(avatarPropertyDetails.feeTokenStandart, avatarPropertyDetails.feeToken, gameFiCore());
            }
            IGameFiCoreV2(gameFiCore()).setPropertyValue(profileId, _avatarPropertyId, bytes32(avatarId), "0x");
        }

        // set username property
        {
            IGameFiCoreV2.Property memory usernamePropertyDetails = IGameFiCoreV2(gameFiCore()).propertyDetails(
                _usernamePropertyId
            );
            if (usernamePropertyDetails.feeTokenStandart != TokenStandart.NULL) {
                _tokenTransferFrom(
                    usernamePropertyDetails.feeTokenStandart,
                    usernamePropertyDetails.feeToken,
                    _msgSender(),
                    address(this)
                );
                _tokenApprove(usernamePropertyDetails.feeTokenStandart, usernamePropertyDetails.feeToken, gameFiCore());
            }
            IGameFiCoreV2(gameFiCore()).setPropertyValue(profileId, _usernamePropertyId, username, "0x");
        }

        // lock profile
        IGameFiCoreV2(gameFiCore()).lockProfile(profileId);

        // transfer profile to msg sender
        IERC721Upgradeable(gameFiCore()).safeTransferFrom(address(this), _msgSender(), profileId);

        return profileId;
    }

    function name() external pure returns (string memory) {
        return ("Zoa Router");
    }

    //
    // Getters
    //

    /**
     * @dev Returns linked GameFiCore contract.
     * @return GameFiCore address.
     */
    function gameFiCore() public view returns (address) {
        return _gameFiCore;
    }

    /**
     * @dev Returns linked GameFiShops contract.
     * @return GameFiShops address.
     */
    function gameFiShops() public view returns (address) {
        return _gameFiShops;
    }

    /**
     * @dev Returns linked GameFiMarketplace contract.
     * @return GameFiMarketplace address.
     */
    function gameFiMarketpalce() public view returns (address) {
        return _gameFiMarketpalce;
    }

    //
    // GSN
    //

    /**
     * @dev Sets trusted forwarder contract (see https://docs.opengsn.org/).
     * @param newTrustedForwarder New trusted forwarder contract.
     */
    function setTrustedForwarder(address newTrustedForwarder) external override {
        // onlyAdmin {
        _setTrustedForwarder(newTrustedForwarder);
    }

    /**
     * @dev Returns recipient version of the GSN protocol (see https://docs.opengsn.org/).
     * @return Version string in SemVer.
     */
    function versionRecipient() external pure override returns (string memory) {
        return "1.0.0";
    }
}