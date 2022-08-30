// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTProtocolDEX {
    /**
     * Structure representing a single component of a swap.
     */
    struct Component {
        uint8 assetType;
        address tokenAddress;
        uint256[] tokenIDs;
        uint256[] amounts;
    }

    /**
     * Swap structure.
     */
    struct Swap {
        uint256 id;
        uint8 status;
        Component[][2] components;
        address maker;
        address taker;
        bool whitelist;
        bool custodial;
        uint256 expiration;
        uint256 seqNum;
    }

    /**
     * Returns the name of the DEX contract.
     */
    function name() external view returns (string memory);

    /**
     * Returns the major version of the DEX contract.
     */
    function majorVersion() external view returns (uint16);

    /**
     * Returns the minor version of the DEX contract.
     */
    function minorVersion() external view returns (uint16);

    /**
     * Returns the address of NFT Protocol Token.
     */
    function token() external view returns (address);

    /**
     * The total number of swaps in the contract.
     */
    function numSwaps() external view returns (uint256);

    /**
     * Returns `True` if sender is in the whitelist of a swap.
     *
     * @param sender_ Account of the sender.
     * @param swapID_ ID of the swap.
     */
    function whitelistedWith(address sender_, uint256 swapID_) external view returns (bool);

    /**
     * Same as :sol:func:`whitelisted` with the sender account.
     */
    function whitelisted(uint256 swapID_) external view returns (bool);

    /**
     * Checks if a swap can be taken by the caller.
     *
     * This function reverts with a message if the swap cannot be taken by the caller.
     * Reasons include:
     * - Swap not open.
     * - Swap has a whitelist and caller is not included.
     * - Taker assets are not available.
     * - Swap is non-custodial and maker has not made all assets available (e.g., moved assets or revoked allowances).
     * - Sender is swap maker.
     *
     * @param sender_ Address of the hypothetical swap taker.
     * @param swapID_ ID of the swap.
     */
    function requireCanTakeSwapWith(address sender_, uint256 swapID_) external view;

    /**
     * Same as :sol:func:`requireCanTakeSwapWith` with the sender account.
     */
    function requireCanTakeSwap(uint256 swapID_) external view;

    /**
     * Checks if all maker assets are available for non-custodial swaps, including balances and allowances.
     *
     * @param swapID_ ID of the swap.
     */
    function requireMakerAssets(uint256 swapID_) external view;

    /**
     * Checks if all taker assets are available.
     *
     * @param sender_ Address of the hypothetical swap taker.
     * @param swapID_ ID of the swap.
     */
    function requireTakerAssetsWith(address sender_, uint256 swapID_) external view;

    /**
     * Same as :sol:func:`requireTakerAssetsWith` with the sender account.
     */
    function requireTakerAssets(uint256 swapID_) external view;

    /**
     * Returns the total ether value locked (tvl), including all deposited swap ether,
     * excluding the fees collected by the administrator.
     */
    function tvl() external view returns (uint256);

    /**
     * Opens a swap with a list of assets on the maker side (`make_`) and on the taker side (`take_`).
     *
     * All assets listed on the maker side have to be available in the caller's account.
     * They are transferred to the DEX contract during this contract call.
     *
     * If the maker list contains Ether assets, then the total Ether funds have to be sent along with
     * the message of this contract call.
     *
     * Emits a :sol:event:`SwapMade` event, if successful.
     *
     * @param make_ Array of components for the maker side of the swap.
     * @param take_ Array of components for the taker side of the swap.
     * @param custodial_ True if the swap is custodial, e.g., maker assets are transfered into the DEX.
     * @param expiration_ Block number at which the swap expires, 0 for no expiration.
     * @param whitelist_ List of addresses that shall be permitted to take the swap.
     * If empty, then whitelisting will be disabled for this swap.
     */
    function makeSwap(
        Component[] calldata make_,
        Component[] calldata take_,
        bool custodial_,
        uint256 expiration_,
        address[] calldata whitelist_
    ) external payable;

    /**
     * Takes a swap that is currently open.
     *
     * All assets listed on the taker side have to be available in the caller's account, see :sol:func:`make`.
     * They are transferred to the maker's account in exchange for the maker's assets that currently reside within the DEX contract for custodial swaps,
     * which are transferred to the taker's account. For non-custodial swaps, the maker assets are transfered from the maker account.
     * This functions checks allowances, ownerships, and balances of all assets that are involved in this swap.
     *
     * The fee for this trade has to be sent along with the message of this contract call, see :sol:func:`fees`.
     *
     * If the taker list contains ETHER assets, then the total ETHER value also has to be added in WEI to the value that is sent along with
     * the message of this contract call.
     *
     * This function requires the caller to provide the most recent sequence number of the swap, which only changes when
     * the swap ether component is updated. The sequence number is used to prevent mempool front-running attacks.
     *
     * @param swapID_ ID of the swap to be taken.
     * @param seqNum_ Most recent sequence number of the swap.
     */
    function takeSwap(uint256 swapID_, uint256 seqNum_) external payable;

    /**
     * Drop a swap and return the assets on the maker side back to the maker.
     *
     * All ERC1155, ERC721, and ERC20 assets will the transferred back directly to the maker.
     * Ether assets are booked to the maker account and can be extracted via :sol:func:`withdraw` and :sol:func:`withdrawFull`.
     *
     * Only the swap maker will be able to call this function successfully.
     *
     * Only swaps that are currently open can be dropped.
     *
     * @param swapID_ id of the swap to be dropped.
     */
    function dropSwap(uint256 swapID_) external;

    /**
     * Amend ether value of a swap.
     *
     * @param swapID_ ID fo the swap to be modified.
     * @param side_ Swap side to modify, see :sol:func:`MAKER_SIDE` and :sol:func:`TAKER_SIDE`.
     * @param value_ New Ether value in Wei to be set for the swap side.
     */
    function amendSwapEther(
        uint256 swapID_,
        uint8 side_,
        uint256 value_
    ) external payable;

    /**
     * Returns the total Ether value in Wei that is required by the sender to take a swap.
     *
     * @param sender_ Address of the sender.
     * @param swapID_ ID of the swap.
     */
    function takerSendValueWith(address sender_, uint256 swapID_) external view returns (uint256);

    /**
     * Same as :sol:func:`takerSendValueWith` with the sender account.
     */
    function takerSendValue(uint256 swapID_) external view returns (uint256);

    /**
     * Returns the total Ether value in Wei that is required by the sender to make a swap.
     *
     * @param sender_ Address of the sender.
     * @param make_ Component array for make side of the swap, see :sol:func:`makeSwap`.
     */
    function makerSendValueWith(address sender_, Component[] calldata make_) external view returns (uint256);

    /**
     * Same as :sol:func:`makerSendValueWith` with the sender account.
     */
    function makerSendValue(Component[] calldata make_) external view returns (uint256);

    /**
     * Returns the total Ether value in Wei that is required by the caller to send in order to adjust the Ether of a swap,
     * see :sol:func:`adjustSwapEther`.
     *
     * @param sender_ Sender account.
     * @param swapID_ ID of the swap to be modified.
     * @param side_ Swap side to modify, see :sol:func:`MAKER_SIDE` and :sol:func:`TAKER_SIDE`.
     * @param value_ New Ether value in Wei to be set for the swap side.
     */
    function amendSwapEtherSendValueWith(
        address sender_,
        uint256 swapID_,
        uint8 side_,
        uint256 value_
    ) external view returns (uint256);

    /**
     * Same as :sol:func:`amendSwapEtherSendValueWith` with the sender account.
     */
    function amendSwapEtherSendValue(
        uint256 swapID_,
        uint8 side_,
        uint256 value_
    ) external view returns (uint256);

    /**
     * Returns the Wei of Ether balance of a user, see :sol:func:`withdraw` and :sol:func:`withdrawFull`.
     *
     * @param of_ Address of the account.
     */
    function balanceOf(address of_) external view returns (uint256);

    /**
     * Same as :sol:func:`balanceOf` with the sender account.
     */
    function balance() external view returns (uint256);

    /**
     * Withdraw funds in Wei of Ether from the contract, see :sol:func:`balance`.
     *
     * @param value_ Wei of Ether to withdraw.
     */
    function withdraw(uint256 value_) external;

    /**
     * Withdraw all Ether funds from the contract that are available to the caller, see :sol:func:`withdraw`.
     */
    function withdrawFull() external;

    /**
     * Rescue funds that are stuck in the DEX, e.g., no user has access to.
     * This function only runs successfully if , which should never happen.
     */
    function rescue() external;

    /**
     * Get a swap, including closed and dropped swaps.
     *
     * @param swapID_ ID of the swap.
     * @return Swap data structure.
     */
    function swap(uint256 swapID_) external view returns (Swap memory);

    /**
     * The flat fee in Wei of Ether to take a swap, see :sol:func:`setFlatFee`.
     *
     * @return Flat fee in Wei of Ether.
     */
    function flatFee() external view returns (uint256);

    /**
     * The threshold of NFT Protocol token holdings for swap takersto get a 10% discount on the flat fee.
     *
     * @return Threshold for amounts in smallest unit of NFT Protocol token holdings to get a 10% discount.
     */
    function lowFee() external view returns (uint256);

    /**
     * The threshold of NFT Protocol token holdings for swap takes to waive the flat fee.
     *
     * @return Threshold for amount in smallest unit of NFT Protocol token holdings to waive the flat fee.
     */
    function highFee() external view returns (uint256);

    /**
     * Returns the taker fee owed for a swap, taking into account the holdings of NFT Protocol tokens,
     * see :sol:func:`flatFee`, :sol:func:`lowFee`, :sol:func:`highFee`.
     *
     * @param sender_ Address of the sender.
     */
    function takerFeeWith(address sender_) external view returns (uint256);

    /**
     * Same as :sol:func:`takerFeeOf` with the sender account.
     */
    function takerFee() external view returns (uint256);

    /**
     * Set the flat fee structure for swaps taking.
     *
     * @param flatFee_ Flat fee in Wei of Ether paid by the taker of swap,
     * if they hold less than `lowFee_` in smallest units of NFT Protocol token.
     * @param lowFee_ Threshold in smallest unit of NFT Protocol token to be held by the swap taker to get a 10% fee discount.
     * @param highFee_ Threshold in smallest unit of NFT Protocol token to be held by the swap taker to pay no fees.
     */
    function setFees(
        uint256 flatFee_,
        uint256 lowFee_,
        uint256 highFee_
    ) external;

    /**
     * Emitted when a swap was opened, see :sol:func:`makeSwap`.
     *
     * @param swapID ID of the swap.
     * @param make Array of swap components on the maker side, see :sol:struct:`Component`.
     * @param take Array of swap components on the taker side, see :sol:struct:`Component`.
     * @param maker Account of the swap maker.
     * @param custodial True if swap is custodial.
     * @param expiration Block where the swap expires, 0 for no expiration.
     * @param whitelist Array of addresses that are allowed to take the swap.
     */
    event SwapMade(
        uint256 indexed swapID,
        Component[] make,
        Component[] take,
        address indexed maker,
        bool indexed custodial,
        uint256 expiration,
        address[] whitelist
    );

    /**
     * Emitted when a swap was executed, see :sol:func:`takeSwap`.
     *
     * @param swapID ID of the swap that was taken.
     * @param seqNum Sequence number of the swap.
     * @param taker Address of the account that executed the swap.
     * @param fee Fee value in Wei of Ether paid by the swap taker.
     */
    event SwapTaken(uint256 indexed swapID, uint256 seqNum, address indexed taker, uint256 fee);

    /**
     * Emitted when a swap was dropped, ie. cancelled.
     *
     * @param swapID ID of the dropped swap.
     */
    event SwapDropped(uint256 indexed swapID);

    /**
     * Emitted when a Ether component of a swap was amended, see :sol:func:`amendSwapEther`.
     *
     * @param swapID ID of the swap.
     * @param seqNum New sequence number of the swap.
     * @param side Swap side, either MAKER_SIDE or TAKER_SIDE.
     * @param index Index of the amended or added Ether component in the components array.
     * @param from Previous amount of Ether in Wei.
     * @param to Updated amount of Ether in Wei.
     */
    event SwapEtherAmended(
        uint256 indexed swapID,
        uint256 seqNum,
        uint8 indexed side,
        uint256 index,
        uint256 from,
        uint256 to
    );

    /**
     * Emitted when the flat fee parameters have changed, see :sol:func:`setFees`.
     *
     * @param flatFee Fee to be paid by a swap taker in Wei of Ether.
     * @param lowFee Threshold of NFT Protocol tokens to be held by a swap taker in order to get a 10% fee discount.
     * @param highFee Threshold of NFT Protocol tokens to be held by a swap taker in order to pay no fees.
     */
    event FeesChanged(uint256 flatFee, uint256 lowFee, uint256 highFee);

    /**
     * Emitted when Ether funds were deposited into the DEX, see :sol:func:`balance`.
     *
     * @param account Address of the account.
     * @param value Wei of Ether deposited.
     */
    event Deposited(address indexed account, uint256 value);

    /**
     * Emitted when Ether funds were withdrawn from the DEX, see :sol:func:`balance`.
     *
     * @param account Address of the account.
     * @param value Wei of Ether withdrawn.
     */
    event Withdrawn(address indexed account, uint256 value);

    /**
     * Emitted when Ether funds were spent during a make or take swap operation, see :sol:func:`balance`.
     *
     * @param spender Address of the spender.
     * @param value Wei of Ether spent.
     * @param swapID ID of the swap, the Ether was spent on, see :sol:func:`takeSwap`, :sol:func:`amendSwapEther`.
     */
    event Spent(address indexed spender, uint256 value, uint256 indexed swapID);

    /**
     * Emitted when funds were rescued, see :sol:func:`rescue`.
     *
     * @param recipient Address of the beneficiary, e.g., the administrator account.
     * @param value Wei of Ether rescued.
     */
    event Rescued(address indexed recipient, uint256 value);
}