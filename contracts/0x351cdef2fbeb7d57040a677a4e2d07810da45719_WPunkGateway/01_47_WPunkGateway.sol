// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "../dependencies/openzeppelin/upgradeability/OwnableUpgradeable.sol";
import {IPool} from "../interfaces/IPool.sol";
import {ReserveConfiguration} from "../protocol/libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

// ERC721 imports
import {IERC721} from "../dependencies/openzeppelin/contracts/IERC721.sol";
import {IERC721Receiver} from "../dependencies/openzeppelin/contracts/IERC721Receiver.sol";
import {IPunks} from "../misc/interfaces/IPunks.sol";
import {IWrappedPunks} from "../misc/interfaces/IWrappedPunks.sol";
import {IWPunkGateway} from "./interfaces/IWPunkGateway.sol";
import {INToken} from "../interfaces/INToken.sol";
import {ReentrancyGuard} from "../dependencies/openzeppelin/contracts/ReentrancyGuard.sol";

contract WPunkGateway is
    ReentrancyGuard,
    IWPunkGateway,
    IERC721Receiver,
    OwnableUpgradeable
{
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    IPunks internal immutable Punk;
    IWrappedPunks internal immutable WPunk;
    IPool internal immutable Pool;
    address public proxy;

    address public immutable punk;
    address public immutable wpunk;
    address public immutable pool;

    /**
     * @dev Sets the WETH address and the PoolAddressesProvider address. Infinite approves pool.
     * @param _punk Address of the Punk contract
     * @param _wpunk Address of the Wrapped Punk contract
     * @param _pool Address of the proxy pool of this contract
     **/
    constructor(
        address _punk,
        address _wpunk,
        address _pool
    ) {
        punk = _punk;
        wpunk = _wpunk;
        pool = _pool;

        Punk = IPunks(punk);
        WPunk = IWrappedPunks(wpunk);
        Pool = IPool(pool);
    }

    function initialize() external initializer {
        __Ownable_init();

        // create new WPunk Proxy for PunkGateway contract
        WPunk.registerProxy();

        // address(this) = WPunkGatewayProxy
        // proxy of PunkGateway contract is the new Proxy created above
        proxy = WPunk.proxyInfo(address(this));

        WPunk.setApprovalForAll(pool, true);
    }

    /**
     * @dev supplies (deposits) WPunk into the reserve, using native Punk. A corresponding amount of the overlying asset (xTokens)
     * is minted.
     * @param punkIndexes punkIndexes to supply to gateway
     * @param onBehalfOf address of the user who will receive the xTokens representing the supply
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
     **/
    function supplyPunk(
        DataTypes.ERC721SupplyParams[] calldata punkIndexes,
        address onBehalfOf,
        uint16 referralCode
    ) external nonReentrant {
        for (uint256 i = 0; i < punkIndexes.length; i++) {
            address punkOwner = Punk.punkIndexToAddress(punkIndexes[i].tokenId);
            require(punkOwner == msg.sender, "WPunkGateway: Not owner of Punk");

            Punk.buyPunk(punkIndexes[i].tokenId);
            Punk.transferPunk(proxy, punkIndexes[i].tokenId);
            // gatewayProxy is the sender of this function, not the original gateway
            WPunk.mint(punkIndexes[i].tokenId);
        }

        Pool.supplyERC721(
            address(WPunk),
            punkIndexes,
            onBehalfOf,
            referralCode
        );
    }

    /**
     * @dev withdraws the WPUNK _reserves of msg.sender.
     * @param punkIndexes indexes of nWPunks to withdraw and receive native WPunk
     * @param to address of the user who will receive native Punks
     */
    function withdrawPunk(uint256[] calldata punkIndexes, address to)
        external
        nonReentrant
    {
        INToken nWPunk = INToken(
            Pool.getReserveData(address(WPunk)).xTokenAddress
        );
        for (uint256 i = 0; i < punkIndexes.length; i++) {
            nWPunk.safeTransferFrom(msg.sender, address(this), punkIndexes[i]);
        }
        Pool.withdrawERC721(address(WPunk), punkIndexes, address(this));
        for (uint256 i = 0; i < punkIndexes.length; i++) {
            WPunk.burn(punkIndexes[i]);
            Punk.transferPunk(to, punkIndexes[i]);
        }
    }

    /**
     * @notice Implements the acceptBidWithCredit feature. AcceptBidWithCredit allows users to
     * accept a leveraged bid on ParaSpace NFT marketplace. Users can submit leveraged bid and pay
     * at most (1 - LTV) * $NFT
     * @dev The nft receiver just needs to do the downpayment
     * @param marketplaceId The marketplace identifier
     * @param payload The encoded parameters to be passed to marketplace contract (selector eliminated)
     * @param credit The credit that user would like to use for this purchase
     * @param referralCode The referral code used
     */
    function acceptBidWithCredit(
        bytes32 marketplaceId,
        bytes calldata payload,
        DataTypes.Credit calldata credit,
        uint256[] calldata punkIndexes,
        uint16 referralCode
    ) external nonReentrant {
        for (uint256 i = 0; i < punkIndexes.length; i++) {
            address punkOwner = Punk.punkIndexToAddress(punkIndexes[i]);
            require(punkOwner == msg.sender, "WPunkGateway: Not owner of Punk");

            Punk.buyPunk(punkIndexes[i]);
            Punk.transferPunk(proxy, punkIndexes[i]);
            // gatewayProxy is the sender of this function, not the original gateway
            WPunk.mint(punkIndexes[i]);

            IERC721(wpunk).safeTransferFrom(
                address(this),
                msg.sender,
                punkIndexes[i]
            );
        }
        Pool.acceptBidWithCredit(
            marketplaceId,
            payload,
            credit,
            msg.sender,
            referralCode
        );
    }

    /**
     * @notice Implements the batchAcceptBidWithCredit feature. AcceptBidWithCredit allows users to
     * accept a leveraged bid on ParaSpace NFT marketplace. Users can submit leveraged bid and pay
     * at most (1 - LTV) * $NFT
     * @dev The nft receiver just needs to do the downpayment
     * @param marketplaceIds The marketplace identifiers
     * @param payloads The encoded parameters to be passed to marketplace contract (selector eliminated)
     * @param credits The credits that the makers have approved to use for this purchase
     * @param referralCode The referral code used
     */
    function batchAcceptBidWithCredit(
        bytes32[] calldata marketplaceIds,
        bytes[] calldata payloads,
        DataTypes.Credit[] calldata credits,
        uint256[] calldata punkIndexes,
        uint16 referralCode
    ) external nonReentrant {
        for (uint256 i = 0; i < punkIndexes.length; i++) {
            address punkOwner = Punk.punkIndexToAddress(punkIndexes[i]);
            require(punkOwner == msg.sender, "WPunkGateway: Not owner of Punk");

            Punk.buyPunk(punkIndexes[i]);
            Punk.transferPunk(proxy, punkIndexes[i]);
            // gatewayProxy is the sender of this function, not the original gateway
            WPunk.mint(punkIndexes[i]);

            IERC721(wpunk).safeTransferFrom(
                address(this),
                msg.sender,
                punkIndexes[i]
            );
        }
        Pool.batchAcceptBidWithCredit(
            marketplaceIds,
            payloads,
            credits,
            msg.sender,
            referralCode
        );
    }

    /**
     * @dev transfer ERC721 from the utility contract, for ERC721 recovery in case of stuck tokens due
     * direct transfers to the contract address.
     * @param token ERC721 token to transfer
     * @param tokenId tokenId to send
     * @param to recipient of the transfer
     */
    function emergencyERC721TokenTransfer(
        address token,
        uint256 tokenId,
        address to
    ) external onlyOwner {
        IERC721(token).safeTransferFrom(address(this), to, tokenId);
        emit EmergencyERC721TokenTransfer(token, tokenId, to);
    }

    /**
     * @dev transfer native Punk from the utility contract, for native Punk recovery in case of stuck Punk
     * due selfdestructs or transfer punk to pre-computated contract address before deployment.
     * @param to recipient of the transfer
     * @param punkIndex punk to send
     */
    function emergencyPunkTransfer(address to, uint256 punkIndex)
        external
        onlyOwner
    {
        Punk.transferPunk(to, punkIndex);
        emit EmergencyPunkTransfer(to, punkIndex);
    }

    /**
     * @dev Get WPunk address used by WPunkGateway
     */
    function getWPunkAddress() external view returns (address) {
        return address(WPunk);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}