//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Openzeppelin Contracts
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// PlaySide Contracts
import "./SignatureVerify.sol";
import "./LootItems.sol";
import "./Roles.sol";
import "./Items.sol";
import "./Settings.sol";
import "./ErrorCodes.sol";

contract HoldersLoot is
    ERC1155,
    AccessControl,
    Pausable,
    ERC1155Supply,
	ERC1155Burnable,
    SignatureVerify,
    Settings,
    LootItems
{
    using Strings for uint256;
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                    CONTRACT SETTINGS
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @dev The name of this contract.
    ///     This will get pulled by clients and name this contract using this string.
    string public constant name = "BEANS HOLDERS LOOT - Dumb Ways to Die";

    /// @dev The symbol of this contract ( When referenced in short hand )
    ///     This will get pulled by clients and symbol this contract using this string.
    string public constant symbol = "DWTD_HOLDERS_LOOT";

	/// @dev Keeps track of all of the minting calls that a certain address has 
	/// 	minted
    /// address => (tokenID => balance)
	mapping(address => mapping(uint256 => uint256)) accountsMintedCount;

    constructor()
        ERC1155(
            "https://dwtd.playsidestudios-devel.com/loot/founders/metadata/{id}.json"
        )
    {}

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                        URI
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @dev Sets a new base URI for all tokens.
    /// @param newuri: The new URI of all tokens.
    /// This should be a directory holding all the json data for each token
    //  This is unused currently as each token is using an array to map each tokens URI
    function setURI(string memory newuri) public onlyRole(Roles.ROLE_SAFE) {
        _setURI(newuri);
    }

    /// @dev Returns the URI for a specfic token ID. Returns from an array that was filled
    ///     in by the admin for each specifc item.
    /// @param tokenID: The token ID that should be returned.
    function uri(uint256 tokenID)
        public
        view
        virtual
        override
        returns (string memory) {
        return LootItems.lootItemList[tokenID].Uri;
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                    PAUSE
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function setPause() public onlyRole(Roles.ROLE_SAFE) {
        _pause();
    }

    function unpause() public onlyRole(Roles.ROLE_SAFE) {
        _unpause();
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                        MINT
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @dev Mints target tokens and amounts from the daily store array.
    /// Will fail if 'Settings.dailyStoreActive' is set to false.
    /// @param tokenIndicies: An array of tokens that the user is requesting to mint.
    //      example: [1,2,3] will mint token IDs : 1,2,3.
    /// @param mintAmounts: The amount respectivly of each token that the user is requesting to mint.
    //      example: [1,2,1] will mint token IDs [(TokenID: 1 Amount: 1), (TokenID: 2 Amount: 2),(TokenID: 3 Amount: 1)]
    function mintDailyStore(
        // Token Params
        uint256[] calldata tokenIndices,
        uint256[] calldata mintAmounts
    ) public payable whenNotPaused {
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // *            ENSURE THE PUBLIC SALE IS ACTIVE
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        if (!Settings.dailyStoreActive) revert ErrorCodes.DailyStoreInactive();

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // *          CHECK ITEM EXISTS IN DAILY STORE
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // Loop Through All The Requested Token Indicies
        for (
            uint256 index_TokenIndicies = 0;
            index_TokenIndicies < tokenIndices.length;
            index_TokenIndicies++
        ) {
            bool indexExists = false;
            // Check that each of them are in the daily store, if not, error out
            for (
                uint256 index_DailyStore = 0;
                index_DailyStore < dailyStore.length;
                index_DailyStore++
            ) {
                // Check if this index matches one in the daily store
                if (
                    tokenIndices[index_TokenIndicies] ==
                    LootItems.dailyStore[index_DailyStore]
                ) {
                    indexExists = true;
                    break;
                }
            }

            // If not, revert this transaction
            if (indexExists == false) revert ErrorCodes.NotInDailyStore();
        }

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // *              CHECK ALL REQUIRES
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        CheckRequires(tokenIndices, mintAmounts, true);

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // *                 FINALLY MINT
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        _mintBatch(msg.sender, tokenIndices, mintAmounts, "");
    }

    /// @dev This is a nonpayable function that will allow a user to claim a token that they are whitelisted to claim.
    /// Will fail if the signature wasnt signed with the correct data and by a signer address on server side.
    /// @param tokenIndicies: An array of tokens that the user is requesting to mint.
    //      example: [1,2,3] will mint token IDs : 1,2,3.
    /// @param mintAmounts: The amount respectivly of each token that the user is requesting to mint.
    //      example: [1,2,1] will mint token IDs [(TokenID: 1 Amount: 1), (TokenID: 2 Amount: 2),(TokenID: 3 Amount: 1)].
    /// @param networkName: The network name that this contract is on. Removes the ability for users to create a dummy contract on a test network
    ///     and sign using that contract.
    /// @param contractAddress: Similar to the network name this ensures that this data was signed using this contract address removing the ability
    ///     for users to sign using a different contract.
    /// @param nonce: This removes the ability to repeat attack this contract in order to control the amount of tokens a user can get.
    /// @param signature: All of the data that is sent through this function is also signed by a signer address and the user and hashed
    ///     out to this param. This signature will be reveresed engineered to ensure that the data is the same as what was signed by the server.
    function mintClaim(
        // Token Params
        uint256[] calldata tokenIndices,
        uint256[] calldata mintAmounts,
        // Signature Params
        uint256 networkName,
        address contractAddress,
        uint256 nonce,
        bytes memory signature
    ) public whenNotPaused {

		// Check not paused
		if(Settings.claimActive == false) revert ErrorCodes.ClaimMintDisabled();

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // *              CHECK IF MESSAGE WAS SIGNED
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        bool isOwner = (msg.sender == Settings.signerAddress);
        if ((isOwner == false)) {
            // Verify Signature
            if (
                !verify(
                    Settings.signerAddress,
                    msg.sender,
                    tokenIndices,
                    mintAmounts,
                    networkName,
                    contractAddress,
                    nonce,
                    signature
                )
            ) revert ErrorCodes.SignatureVerify();
        }

		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // *              CHECK CORRECT NETWORK ID
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		// Check that the network passed into the contract was the correct network
		// 	Doing this after the verify as that ensures that the network passed in matches
		// 	the signed data from the server
		if(networkName != Settings.blockchain) revert ErrorCodes.NetworkMissmatch();

		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // *              CHECK CORRECT CONTRACT ADDRESS
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		if(contractAddress != address(this)) revert ErrorCodes.IncorrectContractSignature(); 

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // *              CHECK ALL REQUIRES
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        CheckRequires(tokenIndices, mintAmounts, false);

		// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // *                 ADD TO MAPPING
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		CacheMintRequests(tokenIndices, mintAmounts);

        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // *                 FINALLY MINT
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        _mintBatch(msg.sender, tokenIndices, mintAmounts, "");
    }

    /// @dev Checks all of the requires in order to allow a user to mint a token.
    /// @param tokenIndicies: An array of tokens that the user is requesting to mint.
    //      example: [1,2,3] will mint token IDs : 1,2,3.
    /// @param mintAmounts: The amount respectivly of each token that the user is requesting to mint.
    //      example: [1,2,1] will mint token IDs [(TokenID: 1 Amount: 1), (TokenID: 2 Amount: 2),(TokenID: 3 Amount: 1)]
    /// @param shouldCheckCost: A bool that controls if this function should check the cost of the message matches the cost
    ///     of all of of the tokens that a user is requesting.
    function CheckRequires(
        uint256[] calldata tokenIndices,
        uint256[] calldata mintAmounts,
        bool shouldCheckCost
    ) internal view {
        // Check the length of each array
        if (tokenIndices.length <= 0 || tokenIndices.length != mintAmounts.length)
            revert ErrorCodes.ArrayMissmatch();

        uint256 _totalCost = 0;
        for (uint256 index = 0; index < tokenIndices.length; index++) {
            // Get Source Data
            uint256 tokenID = tokenIndices[index];
            LootItems.LootItem memory _sourceData = LootItems.getLootItem(
                tokenID
            );

            // Get the total supply of the token index above the current index
            uint256 supplyCount = totalSupply(tokenID);

            // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            // *                    CACHE VARIABLES
            // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            // Cache the desired mint amount
            uint256 mintAmount = mintAmounts[index];

            // Get the cost of this item that is being minted and add it to the total cost
            if (shouldCheckCost) {
                _totalCost =
                    _totalCost +
                    (
                        _sourceData.IsOnSale
                            ? (_sourceData.WeiSaleCost 	* mintAmount)
                            : (_sourceData.WeiCost 		* mintAmount)
                    );
            }

            // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            // *              FINALLY VALIDATE SETTINGS
            // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            // Has to mint at least 1 item
            if (mintAmount <= 0) revert ErrorCodes.RequestedIncorrectAmount();

            // Check has enough supply to mint
            if (supplyCount + mintAmount > _sourceData.TotalSupply)
                revert ErrorCodes.SoldOut();

            // Check for the entire cost of this transaction
            if (shouldCheckCost && msg.value < _totalCost)
                revert ErrorCodes.InsufficientFunds(_totalCost, msg.value);
        }
    }

	function CacheMintRequests(uint256[] calldata tokenIndices, uint256[] calldata mintAmounts) internal
	{
		uint256 tokenIndicesLength 	= tokenIndices.length;

		// Loop through all token indicies and mint amounts and add them into the mapping
		for(uint256 tokenIndex = 0; tokenIndex < tokenIndicesLength; tokenIndex++)
		{
			// Get the current token index
			uint256 tokenID = tokenIndices[tokenIndex];

			// Get the current mint amount for this token index
			uint256 mintAmount = mintAmounts[tokenIndex];

			// Calculate the new mint amount from what they have already minted + requested mint amount
			uint256 newMintAmount = accountsMintedCount[msg.sender][tokenID] + mintAmount;

			// Check that this item exists in our database
			LootItems.LootItem memory sourceData = LootItems.getLootItem(tokenID);

			// If the item doesnt exist, revert transaction
			if(sourceData.exists == false) revert ErrorCodes.LootItem_ItemDoesntExist();

			// Check the new mint amount against the settings for this item
			if(newMintAmount > sourceData.MaxMintPerUser) {
				revert ErrorCodes.LootItem_MaxMintError();
			}

			// Add to mapping of this address and this token index
			accountsMintedCount[msg.sender][tokenID] = newMintAmount;
		}
	}

	/// @dev Withdraws all the funds 
	function withdraw() public onlyRole(Roles.ROLE_SAFE) {
    	(bool os, ) = payable(0x1e9C6144c06Bb4B21586E11bb9d0D526Dc590C9d).call{value: address(this).balance}("");
    	require(os);
	}

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *      ERC1155 OVERRIDE ( Used for supply tracking )
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following function override is required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}