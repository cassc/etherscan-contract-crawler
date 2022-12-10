// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IERC721} from "../dependencies/openzeppelin/contracts/IERC721.sol";
import {IERC721Receiver} from "../dependencies/openzeppelin/contracts/IERC721Receiver.sol";
import {IERC721Enumerable} from "../dependencies/openzeppelin/contracts/IERC721Enumerable.sol";
import {IERC1155Receiver} from "../dependencies/openzeppelin/contracts/IERC1155Receiver.sol";

import {IInitializableNToken} from "./IInitializableNToken.sol";
import {IXTokenType} from "./IXTokenType.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title INToken
 * @author ParallelFi
 * @notice Defines the basic interface for an NToken.
 **/
interface INToken is
    IERC721Enumerable,
    IInitializableNToken,
    IERC721Receiver,
    IERC1155Receiver,
    IXTokenType
{
    /**
     * @dev Emitted during rescueERC20()
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount being rescued
     **/
    event RescueERC20(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted during rescueERC721()
     * @param token The address of the token
     * @param to The address of the recipient
     * @param ids The ids of the tokens being rescued
     **/
    event RescueERC721(
        address indexed token,
        address indexed to,
        uint256[] ids
    );

    /**
     * @dev Emitted during RescueERC1155()
     * @param token The address of the token
     * @param to The address of the recipient
     * @param ids The ids of the tokens being rescued
     * @param amounts The amount of NFTs being rescued for a specific id.
     * @param data The data of the tokens that is being rescued. Usually this is 0.
     **/
    event RescueERC1155(
        address indexed token,
        address indexed to,
        uint256[] ids,
        uint256[] amounts,
        bytes data
    );

    /**
     * @dev Emitted during executeAirdrop()
     * @param airdropContract The address of the airdrop contract
     **/
    event ExecuteAirdrop(address indexed airdropContract);

    /**
     * @notice Mints `amount` nTokens to `user`
     * @param onBehalfOf The address of the user that will receive the minted nTokens
     * @param tokenData The list of the tokens getting minted and their collateral configs
     * @return old and new collateralized balance
     */
    function mint(
        address onBehalfOf,
        DataTypes.ERC721SupplyParams[] calldata tokenData
    ) external returns (uint64, uint64);

    /**
     * @notice Burns nTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @dev In some instances, the mint event could be emitted from a burn transaction
     * if the amount to burn is less than the interest that the user accrued
     * @param from The address from which the nTokens will be burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param tokenIds The ids of the tokens getting burned
     * @return old and new collateralized balance
     **/
    function burn(
        address from,
        address receiverOfUnderlying,
        uint256[] calldata tokenIds
    ) external returns (uint64, uint64);

    // TODO are we using the Treasury at all? Can we remove?
    // /**
    //  * @notice Mints nTokens to the reserve treasury
    //  * @param tokenId The id of the token getting minted
    //  * @param index The next liquidity index of the reserve
    //  */
    // function mintToTreasury(uint256 tokenId, uint256 index) external;

    /**
     * @notice Transfers nTokens in the event of a borrow being liquidated, in case the liquidators reclaims the nToken
     * @param from The address getting liquidated, current owner of the nTokens
     * @param to The recipient
     * @param tokenId The id of the token getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @notice Transfers the underlying asset to `target`.
     * @dev Used by the Pool to transfer assets in borrow(), withdraw() and flashLoan()
     * @param user The recipient of the underlying
     * @param tokenId The id of the token getting transferred
     **/
    function transferUnderlyingTo(address user, uint256 tokenId) external;

    /**
     * @notice Handles the underlying received by the nToken after the transfer has been completed.
     * @dev The default implementation is empty as with standard ERC721 tokens, nothing needs to be done after the
     * transfer is concluded. However in the future there may be nTokens that allow for example to stake the underlying
     * to receive LM rewards. In that case, `handleRepayment()` would perform the staking of the underlying asset.
     * @param user The user executing the repayment
     * @param tokenId The amount getting repaid
     **/
    function handleRepayment(address user, uint256 tokenId) external;

    /**
     * @notice Returns the address of the underlying asset of this nToken (E.g. WETH for pWETH)
     * @return The address of the underlying asset
     **/
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    /**
     * @notice Rescue ERC20 Token.
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount being rescued
     **/
    function rescueERC20(
        address token,
        address to,
        uint256 amount
    ) external;

    /**
     * @notice Rescue ERC721 Token.
     * @param token The address of the token
     * @param to The address of the recipient
     * @param ids The ids of the tokens being rescued
     **/
    function rescueERC721(
        address token,
        address to,
        uint256[] calldata ids
    ) external;

    /**
     * @notice Rescue ERC1155 Token.
     * @param token The address of the token
     * @param to The address of the recipient
     * @param ids The ids of the tokens being rescued
     * @param amounts The amount of NFTs being rescued for a specific id.
     * @param data The data of the tokens that is being rescued. Usually this is 0.
     **/
    function rescueERC1155(
        address token,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    /**
     * @notice Executes airdrop.
     * @param airdropContract The address of the airdrop contract
     * @param airdropParams Third party airdrop abi data. You need to get this from the third party airdrop.
     **/
    function executeAirdrop(
        address airdropContract,
        bytes calldata airdropParams
    ) external;

    function getAtomicPricingConfig() external view returns (bool);
}