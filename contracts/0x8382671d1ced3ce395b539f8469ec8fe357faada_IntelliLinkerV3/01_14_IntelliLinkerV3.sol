// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ERC721Spec.sol";
import "./IntelligentNFTv2.sol";
import "../utils/UpgradeableAccessControl.sol";

/**
 * @title Intelligent Token Linker (iNFT Linker)
 *
 * @notice iNFT Linker is a helper smart contract responsible for managing iNFTs.
 *      It creates and destroys iNFTs, determines iNFT creation price and destruction fee.
 *
 * @dev Known limitations (to be resolved in the future releases):
 *      - doesn't check AI Personality / target NFT compatibility: any personality
 *        can be linked to any NFT (NFT contract must be whitelisted)
 *      - doesn't support unlinking + linking in a single transaction
 *      - doesn't support AI Personality smart contract upgrades: in case when new
 *        AI Personality contract is deployed, new iNFT Linker should also be deployed
 *
 * @dev V2 modification
 *      - supports two separate whitelists for linking and unlinking
 *      - is upgradeable
 *
 * @dev V3 modification: "custom iNFT request" feature
 *      - separates feature "ALLOW_ANY_NFT_CONTRACT" into "ALLOW_ANY_NFT_CONTRACT_FOR_LINKING"
 *        and "ALLOW_ANY_NFT_CONTRACT_FOR_UNLINKING"
 *      - introduces two separate blacklists for linking and unlinking, having the priority over
 *        the whitelists introduced in V2
 *
 * @dev NOTE: Contract MUST NOT be deployed from scratch, only V2 -> V3 upgrade is supported!
 *
 */
contract IntelliLinkerV3 is UpgradeableAccessControl {
	/**
	 * @dev iNFT Linker locks/unlocks ALI tokens defined by `aliContract` to mint/burn iNFT
	 */
	address public aliContract;

	/**
	 * @dev iNFT Linker locks/unlocks AI Personality defined by `personalityContract` to mint/burn iNFT
	 */
	address public personalityContract;

	/**
	 * @dev iNFT Linker mints/burns iNFTs defined by `iNftContract`
	 */
	address public iNftContract;

	/**
	 * @dev iNFTs may get created with the ALI tokens bound to them,
	 *      linking fee may get charged when creating an iNFT
	 *
	 * @dev Linking price, how much ALI tokens is charged upon iNFT creation;
	 *      `linkPrice - linkFee` is locked within the iNFT created
	 */
	uint96 public linkPrice;

	/**
	 * @dev iNFTs may get created with the ALI tokens bound to them,
	 *      linking fee may get charged when creating an iNFT
	 *
	 * @dev Linking fee, how much ALI tokens is sent into treasury `feeDestination`
	 *      upon iNFT creation
	 *
	 * @dev Both `linkFee` and `feeDestination` must be set for the fee to be charged;
	 *      both `linkFee` and `feeDestination` can be either set or unset
	 */
	uint96 public linkFee;

	/**
	 * @dev iNFTs may get created with the ALI tokens bound to them,
	 *      linking fee may get charged when creating an iNFT
	 *
	 * @dev Treasury `feeDestination` is an address to send linking fee to upon iNFT creation
	 *
	 * @dev Both `linkFee` and `feeDestination` must be set for the fee to be charged;
	 *      both `linkFee` and `feeDestination` can be either set or unset
	 */
	address public feeDestination;

	/**
	/**
	 * @dev Next iNFT ID to mint; initially this is the first "free" ID which can be minted;
	 *      at any point in time this should point to a free, mintable ID for iNFT
	 *
	 * @dev iNFT ID space up to 0xFFFF_FFFF (uint32 max) is reserved for the sales
	 */
	uint256 public nextId;

	/**
	 * @notice Whitelist / blacklist mapping storing special linking / unlinking permissions
	 *
	 * @dev Target NFT Contracts which have special permissions (allowed or forbidden)
	 *      for iNFT to be linked to / unlinked from;
	 *      allowance permissions are not taken into account if features
	 *      ALLOW_ANY_NFT_CONTRACT_FOR_LINKING / ALLOW_ANY_NFT_CONTRACT_FOR_UNLINKING are enabled
	 *      forbiddance permissions are not taken into account if features
	 *      ALLOW_ANY_NFT_CONTRACT_FOR_LINKING / ALLOW_ANY_NFT_CONTRACT_FOR_UNLINKING are disabled
	 *
	 * @dev Lowest bit (zero) defines if contract is allowed to be linked to;
	 *      Next bit (one) defines if contract is allowed to be unlinked from;
	 *      Next bit (two) defines if contract is forbidden to be linked to;
	 *      Next bit (three) defines if contract is forbidden to be unlinked from;
	 */
	mapping(address => uint8) public whitelistedTargetContracts;

	/**
	 * @notice Enables iNFT linking (creation)
	 *
	 * @dev Feature FEATURE_LINKING must be enabled
	 *      as a prerequisite for `link()` function to succeed
	 */
	uint32 public constant FEATURE_LINKING = 0x0000_0001;

	/**
	 * @notice Enables iNFT unlinking (destruction)
	 *
	 * @dev Feature FEATURE_UNLINKING must be enabled
	 *      for the `unlink()` and `unlinkNFT()` functions to succeed
	 */
	uint32 public constant FEATURE_UNLINKING = 0x0000_0002;

	/**
	 * @notice Allows linker to link (mint) iNFT to any target NFT contract,
	 *      independently whether it was previously whitelisted or not
	 * @dev Feature FEATURE_ALLOW_ANY_NFT_CONTRACT_FOR_LINKING allows linking (minting) iNFTs
	 *      to any target NFT contract, without a check if it's whitelisted in
	 *      `whitelistedTargetContracts` or not
	 */
	uint32 public constant FEATURE_ALLOW_ANY_NFT_CONTRACT_FOR_LINKING = 0x0000_0004;

	/**
	 * @notice Allows linker to unlink (burn) iNFT bound to any target NFT contract,
	 *      independently whether it was previously whitelisted or not
	 * @dev Feature FEATURE_ALLOW_ANY_NFT_CONTRACT_FOR_UNLINKING allows unlinking (burning) iNFTs
	 *      bound to any target NFT contract, without a check if it's whitelisted in
	 *      `whitelistedTargetContracts` or not
	 */
	uint32 public constant FEATURE_ALLOW_ANY_NFT_CONTRACT_FOR_UNLINKING = 0x0000_0040;

	/**
	 * @notice Enables depositing more ALI to already existing iNFTs
	 *
	 * @dev Feature FEATURE_DEPOSITS must be enabled
	 *      for the `deposit()` function to succeed
	 */
	uint32 public constant FEATURE_DEPOSITS = 0x0000_0008;

	/**
	 * @notice Enables ALI withdrawals from the iNFT (without destroying them)
	 *
	 * @dev Feature FEATURE_WITHDRAWALS must be enabled
	 *      for the `withdraw()` function to succeed
	 */
	uint32 public constant FEATURE_WITHDRAWALS = 0x0000_0010;

	/**
	 * @notice Link price manager is responsible for updating linking price
	 *
	 * @dev Role ROLE_LINK_PRICE_MANAGER allows `updateLinkPrice` execution,
	 *      and `linkPrice` modification
	 */
	uint32 public constant ROLE_LINK_PRICE_MANAGER = 0x0001_0000;

	/**
	 * @notice Next ID manager is responsible for updating `nextId` variable,
	 *      pointing to the next iNFT ID free slot
	 *
	 * @dev Role ROLE_NEXT_ID_MANAGER allows `updateNextId` execution,
	 *     and `nextId` modification
	 */
	uint32 public constant ROLE_NEXT_ID_MANAGER = 0x0002_0000;

	/**
	 * @notice Whitelist manager is responsible for managing the target NFT contracts
	 *     whitelist, which are the contracts iNFT is allowed to be bound to
	 *
	 * @dev Role ROLE_WHITELIST_MANAGER allows `whitelistTargetContract` execution,
	 *     and `whitelistedTargetContracts` mapping modification
	 */
	uint32 public constant ROLE_WHITELIST_MANAGER = 0x0004_0000;

	/**
	 * @dev Fired in link() when new iNFT is created
	 *
	 * @param _by an address which executed (and funded) the link function
	 * @param _iNftId ID of the iNFT minted
	 * @param _linkPrice amount of ALI tokens locked (transferred) to newly created iNFT
	 * @param _linkFee amount of ALI tokens charged as a fee and sent to the treasury
	 * @param _personalityContract AI Personality contract address
	 * @param _personalityId ID of the AI Personality locked (transferred) to newly created iNFT
	 * @param _targetContract target NFT smart contract
	 * @param _targetId target NFT ID (where this iNFT binds to and belongs to)
	 */
	event Linked(
		address indexed _by,
		uint256 _iNftId,
		uint96 _linkPrice,
		uint96 _linkFee,
		address indexed _personalityContract,
		uint96 indexed _personalityId,
		address _targetContract,
		uint256 _targetId
	);

	/**
	 * @dev Fired in unlink() when an existing iNFT gets destroyed
	 *
	 * @param _by an address which executed the unlink function
	 *      (and which received unlocked AI Personality and ALI tokens)
	 * @param _iNftId ID of the iNFT burnt
	 */
	event Unlinked(address indexed _by, uint256 indexed _iNftId);

	/**
	 * @dev Fired in deposit(), withdraw() when an iNFT ALI balance gets changed
	 *
	 * @param _by an address which executed the deposit/withdraw function
	 *      (in case of withdraw it received unlocked ALI tokens)
	 * @param _iNftId ID of the iNFT to update
	 * @param _aliDelta locked ALI tokens delta, positive for deposit, negative for withdraw
	 * @param _feeValue amount of ALI tokens charged as a fee
	 */
	event LinkUpdated(address indexed _by, uint256 indexed _iNftId, int128 _aliDelta, uint96 _feeValue);

	/**
	 * @dev Fired in updateLinkPrice()
	 *
	 * @param _by an address which executed the operation
	 * @param _linkPrice new linking price set
	 * @param _linkFee new linking fee set
	 * @param _feeDestination new treasury address set
	 */
	event LinkPriceChanged(address indexed _by, uint96 _linkPrice, uint96 _linkFee, address indexed _feeDestination);

	/**
	 * @dev Fired in updateNextId()
	 *
	 * @param _by an address which executed the operation
	 * @param _oldVal old nextId value
	 * @param _newVal new nextId value
	 */
	event NextIdChanged(address indexed _by, uint256 _oldVal, uint256 _newVal);

	/**
	 * @dev Fired in whitelistTargetContract()
	 *
	 * @param _by an address which executed the operation
	 * @param _targetContract target NFT contract address affected
	 * @param _oldVal old whitelisted raw value (contains 4 flags)
	 * @param _newVal new whitelisted raw value (contains 4 flags)
	 */
	event TargetContractWhitelisted(address indexed _by, address indexed _targetContract, uint8 _oldVal, uint8 _newVal);

	/**
	 * @dev NOTE: No postConstruct() initializer function!
	 *      Contract must not be deployed from scratch, only V2 -> V3 upgrade is supported
	 */

	/**
	 * @notice Links given AI Personality with the given NFT and forms an iNFT.
	 *      AI Personality specified and `linkPrice` ALI are transferred into minted iNFT
	 *      and are effectively locked within an iNFT until it is destructed (burnt)
	 *
	 * @dev AI Personality and ALI tokens are transferred from the transaction sender account
	 *      to iNFT smart contract
	 * @dev Sender must approve both AI Personality and ALI tokens transfers to be
	 *      performed by the linker contract
	 *
	 * @param personalityId AI Personality ID to be locked into iNFT
	 * @param targetContract NFT address iNFT to be linked to
	 * @param targetId NFT ID iNFT to be linked to
	 */
	function link(uint96 personalityId, address targetContract, uint256 targetId) public virtual {
		// verify linking is enabled
		require(isFeatureEnabled(FEATURE_LINKING), "linking is disabled");

		// verify AI Personality belongs to transaction sender
		require(ERC721(personalityContract).ownerOf(personalityId) == msg.sender, "access denied");
		// verify NFT contract is either whitelisted or any NFT contract is allowed globally
		require(isAllowedForLinking(targetContract), "not a whitelisted NFT contract");

		// if linking fee is set
		if(linkFee > 0) {
			// transfer ALI tokens to the treasury - `feeDestination`
			ERC20(aliContract).transferFrom(msg.sender, feeDestination, linkFee);
		}

		// if linking price is set
		if(linkPrice > 0) {
			// transfer ALI tokens to iNFT contract to be locked
			ERC20(aliContract).transferFrom(msg.sender, iNftContract, linkPrice - linkFee);
		}

		// transfer AI Personality to iNFT contract to be locked
		ERC721(personalityContract).transferFrom(msg.sender, iNftContract, personalityId);

		// mint the next iNFT, increment next iNFT ID to be minted
		IntelligentNFTv2(iNftContract).mint(nextId++, linkPrice - linkFee, personalityContract, personalityId, targetContract, targetId);

		// emit an event
		emit Linked(msg.sender, nextId - 1, linkPrice, linkFee, personalityContract, personalityId, targetContract, targetId);
	}

	/**
	 * @notice Destroys given iNFT, unlinking it from underlying NFT and unlocking
	 *      the AI Personality and ALI tokens locked in iNFT.
	 *      AI Personality and ALI tokens are transferred to the underlying NFT owner
	 *
	 * @dev Can be executed only by iNFT owner (effectively underlying NFT owner)
	 *
	 * @param iNftId ID of the iNFT to unlink
	 */
	function unlink(uint256 iNftId) public virtual {
		// verify unlinking is enabled
		require(isFeatureEnabled(FEATURE_UNLINKING), "unlinking is disabled");

		// get a link to an iNFT contract to perform several actions with it
		IntelligentNFTv2 iNFT = IntelligentNFTv2(iNftContract);

		// get target NFT contract address from the iNFT binding
		(,,,address targetContract,) = iNFT.bindings(iNftId);
		// verify NFT contract is either whitelisted or any NFT contract is allowed globally
		require(isAllowedForUnlinking(targetContract), "not a whitelisted NFT contract");

		// verify the transaction is executed by iNFT owner (effectively by underlying NFT owner)
		require(iNFT.ownerOf(iNftId) == msg.sender, "not an iNFT owner");

		// burn the iNFT unlocking the AI Personality and ALI tokens - delegate to `IntelligentNFTv2.burn`
		iNFT.burn(iNftId);

		// emit an event
		emit Unlinked(msg.sender, iNftId);
	}

	/**
	 * @notice Unlinks given NFT by destroying iNFTs and unlocking
	 *      the AI Personality and ALI tokens locked in iNFTs.
	 *      AI Personality and ALI tokens are transferred to the underlying NFT owner
	 *
	 * @dev Can be executed only by NFT owner (effectively underlying NFT owner)
	 *
	 * @param nftContract NFT address iNFTs to be unlinked to
	 * @param nftId NFT ID iNFTs to be unlinked to
	 */
	function unlinkNFT(address nftContract, uint256 nftId) public virtual {
		// verify unlinking is enabled
		require(isFeatureEnabled(FEATURE_UNLINKING), "unlinking is disabled");

		// get a link to an iNFT contract to perform several actions with it
		IntelligentNFTv2 iNFT = IntelligentNFTv2(iNftContract);

		// verify the transaction is executed by NFT owner
		require(ERC721(nftContract).ownerOf(nftId) == msg.sender, "not an NFT owner");

		// get iNFT ID linked with given NFT
		uint256 iNftId = iNFT.reverseBindings(nftContract, nftId);

		// verify NFT contract is either whitelisted or any NFT contract is allowed globally
		require(isAllowedForUnlinking(nftContract), "not a whitelisted NFT contract");

		// burn the iNFT unlocking the AI Personality and ALI tokens - delegate to `IntelligentNFTv2.burn`
		iNFT.burn(iNftId);

		// emit an event
		emit Unlinked(msg.sender, iNftId);
	}

	/**
	 * @notice Deposits additional ALI tokens into already existing iNFT
	 *
	 * @dev Can be executed only by NFT owner (effectively underlying NFT owner)
	 *
	 * @dev ALI tokens are transferred from the transaction sender account to iNFT smart contract
	 *      Sender must approve ALI tokens transfers to be performed by the linker contract
	 *
	 * @param iNftId ID of the iNFT to transfer (and lock) tokens to
	 * @param aliValue amount of ALI tokens to transfer (and lock)
	 */
	function deposit(uint256 iNftId, uint96 aliValue) public virtual {
		// verify deposits are enabled
		require(isFeatureEnabled(FEATURE_DEPOSITS), "deposits are disabled");

		// get a link to an iNFT contract to perform several actions with it
		IntelligentNFTv2 iNFT = IntelligentNFTv2(iNftContract);

		// verify the transaction is executed by iNFT owner (effectively by underlying NFT owner)
		require(iNFT.ownerOf(iNftId) == msg.sender, "not an iNFT owner");

		// effective ALI value locked in iNFT may get altered according to the linking fee set
		// init effective fee as if linking fee is not set
		uint96 _linkFee = 0;
		// init effective ALI value locked as if linking fee is not set
		uint96 _aliValue = aliValue;
		// in case when link price/fee are set (effectively meaning fee percent is set)
		if(linkPrice != 0 && linkFee != 0) {
			// we need to make sure the fee is charged from the value supplied
			// proportionally to the value supplied and fee percent
			_linkFee = uint96(uint256(_aliValue) * linkFee / linkPrice);

			// recalculate ALI value to be locked accordingly
			_aliValue = aliValue - _linkFee;

			// transfer ALI tokens to the treasury - `feeDestination`
			ERC20(aliContract).transferFrom(msg.sender, feeDestination, _linkFee);
		}

		// transfer ALI tokens to iNFT contract to be locked
		ERC20(aliContract).transferFrom(msg.sender, iNftContract, _aliValue);

		// update the iNFT record
		iNFT.increaseAli(iNftId, _aliValue);

		// emit an event
		emit LinkUpdated(msg.sender, iNftId, int128(uint128(_aliValue)), _linkFee);
	}

	/**
	 * @notice Withdraws some ALI tokens from already existing iNFT without destroying it
	 *
	 * @dev Can be executed only by NFT owner (effectively underlying NFT owner)
	 *
	 * @dev ALI tokens are transferred to the iNFT owner (transaction executor)
	 *
	 * @param iNftId ID of the iNFT to unlock tokens from
	 * @param aliValue amount of ALI tokens to unlock
	 */
	function withdraw(uint256 iNftId, uint96 aliValue) public virtual {
		// verify withdrawals are enabled
		require(isFeatureEnabled(FEATURE_WITHDRAWALS), "withdrawals are disabled");

		// get a link to an iNFT contract to perform several actions with it
		IntelligentNFTv2 iNFT = IntelligentNFTv2(iNftContract);

		// verify the transaction is executed by iNFT owner (effectively by underlying NFT owner)
		require(iNFT.ownerOf(iNftId) == msg.sender, "not an iNFT owner");

		// ensure iNFT locked balance doesn't go below `linkPrice - linkFee`
		require(iNFT.lockedValue(iNftId) >= aliValue + linkPrice, "deposit too low");

		// update the iNFT record and transfer tokens back to the iNFT owner
		iNFT.decreaseAli(iNftId, aliValue, msg.sender);

		// emit an event
		emit LinkUpdated(msg.sender, iNftId, -int128(uint128(aliValue)), 0);
	}

	/**
	 * @dev Restricted access function to modify
	 *      - linking price `linkPrice`,
	 *      - linking fee `linkFee`, and
	 *      - treasury address `feeDestination`
	 *
	 * @dev Requires executor to have ROLE_LINK_PRICE_MANAGER permission
	 * @dev Requires linking price to be either unset (zero), or not less than 1e12 (0.000001 ALI)
	 * @dev Requires both linking fee and treasury address to be either set or unset (zero);
	 *      if set, linking fee must not be less than 1e12 (0.000001 ALI);
	 *      if set, linking fee must not exceed linking price
	 *
	 * @param _linkPrice new linking price to be set
	 * @param _linkFee new linking fee to be set
	 * @param _feeDestination treasury address
	 */
	function updateLinkPrice(uint96 _linkPrice, uint96 _linkFee, address _feeDestination) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_LINK_PRICE_MANAGER), "access denied");

		// verify the price is not too low if it's set
		require(_linkPrice == 0 || _linkPrice >= 1e12, "invalid price");

		// linking fee/treasury should be either both set or both unset
		// linking fee must not be too low if set
		require(_linkFee == 0 && _feeDestination == address(0) || _linkFee >= 1e12 && _feeDestination != address(0), "invalid linking fee/treasury");
		// linking fee must not exceed linking price
		require(_linkFee <= _linkPrice, "linking fee exceeds linking price");

		// update the linking price, fee, and treasury address
		linkPrice = _linkPrice;
		linkFee = _linkFee;
		feeDestination = _feeDestination;

		// emit an event
		emit LinkPriceChanged(msg.sender, _linkPrice, _linkFee, _feeDestination);
	}

	/**
	 * @dev Restricted access function to modify next iNFT ID `nextId`
	 *
	 * @param _nextId new next iNFT ID to be set
	 */
	function updateNextId(uint256 _nextId) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_NEXT_ID_MANAGER), "access denied");

		// verify nextId is in safe bounds
		require(_nextId > 0xFFFF_FFFF, "value too low");

		// emit a event
		emit NextIdChanged(msg.sender, nextId, _nextId);

		// update next ID
		nextId = _nextId;
	}

	/**
	 * @dev Restricted access function to manage whitelisted / blacklisted NFT contracts mapping
	 *      `whitelistedTargetContracts`
	 *
	 * @dev Requires executor to have ROLE_WHITELIST_MANAGER permission
	 *
	 * @param targetContract target NFT contract address to add/remove to/from the whitelist
	 * @param allowedForLinking true to add, false to remove to/from whitelist (allowed for linking)
	 * @param allowedForUnlinking true to add, false to remove to/from whitelist (allowed for unlinking)
	 * @param forbiddenForLinking true to add, false to remove to/from blacklist (forbidden for linking)
	 * @param forbiddenForUnlinking true to add, false to remove to/from blacklist (forbidden for unlinking)
	 */
	function whitelistTargetContract(
		address targetContract,
		bool allowedForLinking,
		bool allowedForUnlinking,
		bool forbiddenForLinking,
		bool forbiddenForUnlinking
	) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_WHITELIST_MANAGER), "access denied");

		// verify the address is set
		require(targetContract != address(0), "zero address");

		// delisting is always possible, whitelisting - only for valid ERC721
		if(allowedForLinking) {
			// verify targetContract is a valid ERC721
			require(ERC165(targetContract).supportsInterface(type(ERC721).interfaceId), "target NFT is not ERC721");
		}

		// derive the uint8 value representing two boolean flags:
		// Lowest bit (zero) defines if contract is allowed to be linked to;
		// Next bit (one) defines if contract is allowed to be unlinked from
		uint8 newVal = (allowedForLinking?     0x1: 0x0)
		             | (allowedForUnlinking?   0x2: 0x0)
		             | (forbiddenForLinking?   0x4: 0x0)
		             | (forbiddenForUnlinking? 0x8: 0x0);

		// emit an event
		emit TargetContractWhitelisted(msg.sender, targetContract, whitelistedTargetContracts[targetContract], newVal);

		// update the contract address in the whitelist
		whitelistedTargetContracts[targetContract] = newVal;
	}

	/**
	 * @notice Decodes the bit packed integer in whitelistedTargetContracts into boolean tuple
	 *
	 * @dev This function returns the values previously set with `whitelistTargetContract` or
	 *      (false, false, false, false) if the values were not set
	 *
	 * @param targetContract target NFT contract address to read the data from whitelist for
	 * @return allowedForLinking allowed for linking flag
	 * @return allowedForUnlinking allowed for unlinking flag
	 * @return forbiddenForLinking forbidden for linking flag
	 * @return forbiddenForUnlinking forbidden for unlinking flag
	 */
	function isWhitelisted(address targetContract) public view virtual returns(
		bool allowedForLinking,
		bool allowedForUnlinking,
		bool forbiddenForLinking,
		bool forbiddenForUnlinking
	) {
		// read the int (bit packed) value
		uint8 val = whitelistedTargetContracts[targetContract];

		// decode into boolean values
		allowedForLinking     = val & 0x1 == 0x1;
		allowedForUnlinking   = val & 0x2 == 0x2;
		forbiddenForLinking   = val & 0x4 == 0x4;
		forbiddenForUnlinking = val & 0x8 == 0x8;

		// results are returned implicitly
	}

	/**
	 * @notice Checks if specified target NFT contract is allowed to be linked to
	 *
	 * @dev Using this function can be more convenient than accessing the
	 *      `whitelistedTargetContracts` directly since the mapping contains linking/unlinking
	 *      flags packed into uint8
	 *
	 * @param targetContract target NFT contract address to query for
	 * @return true if target NFT contract is allowed to be linked to, false otherwise
	 */
	function isAllowedForLinking(address targetContract) public view virtual returns (bool) {
		// extract the information required from the mapping using helper function
		(bool allowedForLinking,, bool forbiddenForLinking,) = isWhitelisted(targetContract);

		// evaluate the result based on the values read
		return !forbiddenForLinking && (allowedForLinking || isFeatureEnabled(FEATURE_ALLOW_ANY_NFT_CONTRACT_FOR_LINKING));
	}

	/**
	 * @notice Checks if specified target NFT contract is allowed to be unlinked from
	 *
	 * @dev Using this function can be more convenient than accessing the
	 *      `whitelistedTargetContracts` directly since the mapping contains linking/unlinking
	 *      flags packed into uint8
	 *
	 * @param targetContract target NFT contract address to query for
	 * @return true if target NFT contract is allowed to be unlinked from, false otherwise
	 */
	function isAllowedForUnlinking(address targetContract) public view virtual returns (bool) {
		// extract the information required from the mapping using helper function
		(, bool allowedForUnlinking,, bool forbiddenForUnlinking) = isWhitelisted(targetContract);

		// evaluate the result based on the values read
		return !forbiddenForUnlinking && (allowedForUnlinking || isFeatureEnabled(FEATURE_ALLOW_ANY_NFT_CONTRACT_FOR_UNLINKING));
	}
}