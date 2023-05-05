// Altura ERC1155 token
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev Interface of AlturaNFTV3.
 */
interface IAlturaNFTV3 {
    /**
        Cannot add an item with a royalty fee higher than 30% to the collection.
     */
    error InvalidNewItemRoyalty();

    /**
        @dev Emitted when items are added to the collection.
     */
    event ItemsAdded(uint256 from, uint256 count);

    /**
        @dev Emitted when an item creator changes its royalty fee.
     */
    event ItemRoyaltyChanged(uint256 itemId, uint256 newRoyalty);

    /**
        @dev Emitted when a creator consume an item.
     */
    event ItemConsumed(uint256 itemId, uint256 amount);

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct Item {
        uint256 supply;
        uint256 maxSupply;
        uint256 royaltyFee;
        address creator;
    }

    // =============================================================
    //                            ALTURA
    // =============================================================

    /**
		  Initialize from Swap contract
	   */
    function initialize(
        string memory _name,
        string memory _uri,
        address _creator,
        address _factory,
        bool _public
    ) external;

    /**
		  Create Item(s) - Only Minters
     */
    function addItems(uint256[] calldata newItems) external;

    /**
		  Mint - Only Minters or Creators
	   */
    function mint(address recipient, uint256 itemId, uint256 amount, bytes memory data) external returns (bool);

    /**
		  Change Item Royalty Fee - Only Minters or Creators
	   */
    function setItemRoyalty(uint256 itemId, uint256 royaltyFee) external;

    /**
		Consume (Burn) an Item - Only Minters or Creators
	    */
    function consumeItem(address from, uint256 itemId, uint256 amount) external;

    /**
		  Change Collection Name
	   */
    function setName(string memory newName) external;

    /**
		  Change Collection URI
	   */
    function setURI(string memory newUri) external;

    function getItem(uint256 itemId) external view returns (Item memory);

    // =============================================================
    //                            IERC1155
    // =============================================================

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    // =============================================================
    //                            IERC2981
    // =============================================================

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function creatorOf(uint256 id) external view returns (address);

    function royaltyOf(uint256 id) external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}