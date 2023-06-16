// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ERC20Spec.sol";
import "../interfaces/ERC721Spec.sol";
import "../lib/StringUtils.sol";
import "../utils/AccessControl.sol";

/**
 * @title Intelligent NFT Interface
 *        Version 2
 *
 * @notice External interface of IntelligentNFTv2 declared to support ERC165 detection.
 *      Despite some similarity with ERC721 interfaces, iNFT is not ERC721, any similarity
 *      should be treated as coincidental. Client applications may benefit from this similarity
 *      to reuse some of the ERC721 client code for display/reading.
 *
 * @dev See Intelligent NFT documentation below.
 *
 */
interface IntelligentNFTv2Spec {
	/**
	 * @dev ERC20/ERC721 like name - Intelligent NFT
	 *
	 * @return "Intelligent NFT"
	 */
	function name() external view returns (string memory);

	/**
	 * @dev ERC20/ERC721 like symbol - iNFT
	 *
	 * @return "iNFT"
	 */
	function symbol() external view returns (string memory);

	/**
	 * @dev ERC721 like link to the iNFT metadata
	 *
	 * @param recordId iNFT ID to get metadata URI for
	 */
	function tokenURI(uint256 recordId) external view returns (string memory);

	/**
	 * @dev ERC20/ERC721 like counter of the iNFTs in existence (upper bound),
	 *      some (or all) of which may not exist due to target NFT destruction
	 *
	 * @return amount of iNFT tracked by this smart contract
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @dev Check if iNFT binding with the given ID exists
	 *
	 * @return true if iNFT binding exist, false otherwise
	 */
	function exists(uint256 recordId) external view returns (bool);

	/**
	 * @dev ERC721 like function to get owner of the iNFT, which is by definition
	 *      an owner of the underlying NFT
	 */
	function ownerOf(uint256 recordId) external view returns (address);
}

/**
 * @title Intelligent NFT (iNFT)
 *        Version 2
 *
 * @notice Intelligent NFT (iNFT) represents an enhancement to an existing NFT
 *      (we call it a "target" or "target NFT"), it binds a GPT-3 prompt (a "personality prompt",
 *      delivered as a Personality Pod ERC721 token bound to iNFT)
 *      to the target to embed intelligence, is controlled and belongs to the owner of the target.
 *
 * @notice iNFT stores AI Personality and some amount of ALI tokens locked, available for
 *      unlocking when iNFT is destroyed
 *
 * @notice iNFT is not an ERC721 token, but it has some very limited similarity to an ERC721:
 *      every record is identified by ID and this ID has an owner, which is effectively the target NFT owner;
 *      still, it doesn't store ownership information itself and fully relies on the target ownership instead
 *
 * @dev Internally iNFTs consist of:
 *      - target NFT - smart contract address and ID of the NFT the iNFT is bound to
 *      - AI Personality - smart contract address and ID of the AI Personality used to produce given iNFT,
 *        representing a "personality prompt", and locked within an iNFT
 *      - ALI tokens amount - amount of the ALI tokens used to produce given iNFT, also locked
 *
 * @dev iNFTs can be
 *      - created, this process requires an AI Personality and ALI tokens to be locked
 *      - destroyed, this process releases an AI Personality and ALI tokens previously locked
 *
 */
contract IntelligentNFTv2 is IntelligentNFTv2Spec, AccessControl, ERC165 {
	/**
	 * @inheritdoc IntelligentNFTv2Spec
	 */
	string public override name = "Intelligent NFT";

	/**
	 * @inheritdoc IntelligentNFTv2Spec
	 */
	string public override symbol = "iNFT";

	/**
	 * @dev Each intelligent token, represented by its unique ID, is bound to the target NFT,
	 *      defined by the pair of the target NFT smart contract address and unique token ID
	 *      within the target NFT smart contract
	 *
	 * @dev Effectively iNFT is owned by the target NFT owner
	 *
	 * @dev Additionally, each token holds an AI Personality and some amount of ALI tokens bound to it
	 *
	 * @dev `IntelliBinding` keeps all the binding information, including target NFT coordinates,
	 *      bound AI Personality ID, and amount of ALI ERC20 tokens bound to the iNFT
	 */
	struct IntelliBinding {
		// Note: structure members are reordered to fit into less memory slots, see EVM memory layout
		// ----- SLOT.1 (256/256)
		/**
		 * @dev Specific AI Personality is defined by the pair of AI Personality smart contract address
		 *       and AI Personality ID
		 *
		 * @dev Address of the AI Personality smart contract
		 */
		address personalityContract;

		/**
		 * @dev AI Personality ID within the AI Personality smart contract
		 */
		uint96 personalityId;

		// ----- SLOT.2 (256/256)
		/**
		 * @dev Amount of an ALI ERC20 tokens bound to (owned by) the iNFTs
		 *
		 * @dev ALI ERC20 smart contract address is defined globally as `aliContract` constant
		 */
		uint96 aliValue;

		/**
		 * @dev Address of the target NFT deployed smart contract,
		 *      this is a contract a particular iNFT is bound to
		 */
		address targetContract;

		// ----- SLOT.3 (256/256)
		/**
		 * @dev Target NFT ID within the target NFT smart contract,
		 *      effectively target NFT ID and contract address define the owner of an iNFT
		 */
		uint256 targetId;
	}

	/**
	 * @notice iNFT binding storage, stores binding information for each existing iNFT
	 * @dev Maps iNFT ID to its binding data, which includes underlying NFT data
	 */
	mapping(uint256 => IntelliBinding) public bindings;

	/**
	 * @notice Reverse iNFT binding allows to find iNFT bound to a particular NFT
	 * @dev Maps target NFT (smart contract address and unique token ID) to the iNFT ID:
	 *      NFT Contract => NFT ID => iNFT ID
	 */
	mapping(address => mapping(uint256 => uint256)) public reverseBindings;

	/**
	 * @notice Ai Personality to iNFT binding allows to find iNFT bound to a particular Ai Personality
	 * @dev Maps Ai Personality NFT (unique token ID) to the linked iNFT:
	 *      AI Personality Contract => AI Personality ID => iNFT ID
	 */
	mapping(address => mapping(uint256 => uint256)) public personalityBindings;

	/**
	 * @notice Total amount (maximum value estimate) of iNFT in existence.
	 *       This value can be higher than number of effectively accessible iNFTs
	 *       since when underlying NFT gets burned this value doesn't get updated.
	 */
	uint256 public override totalSupply;

	/**
	 * @notice Each iNFT holds some ALI tokens, which are tracked by the ALI token ERC20 smart contract defined here
	 */
	address public immutable aliContract;

	/**
	 * @notice ALI token balance the contract is aware of, cumulative ALI obligation,
	 *      i.e. sum of all iNFT locked ALI balances
	 *
	 * @dev Sum of all `IntelliBinding.aliValue` for each iNFT in existence
	 */
	uint256 public aliBalance;

	/**
	 * @dev Base URI is used to construct ERC721Metadata.tokenURI as
	 *      `base URI + token ID` if token URI is not set (not present in `_tokenURIs` mapping)
	 *
	 * @dev For example, if base URI is https://api.com/token/, then token #1
	 *      will have an URI https://api.com/token/1
	 *
	 * @dev If token URI is set with `setTokenURI()` it will be returned as is via `tokenURI()`
	 */
	string public baseURI = "";

	/**
	 * @dev Optional mapping for token URIs to be returned as is when `tokenURI()`
	 *      is called; if mapping doesn't exist for token, the URI is constructed
	 *      as `base URI + token ID`, where plus (+) denotes string concatenation
	 */
	mapping(uint256 => string) internal _tokenURIs;

	/**
	 * @notice Minter is responsible for creating (minting) iNFTs
	 *
	 * @dev Role ROLE_MINTER allows minting iNFTs (calling `mint` function)
	 */
	uint32 public constant ROLE_MINTER = 0x0001_0000;

	/**
	 * @notice Burner is responsible for destroying (burning) iNFTs
	 *
	 * @dev Role ROLE_BURNER allows burning iNFTs (calling `burn` function)
	 */
	uint32 public constant ROLE_BURNER = 0x0002_0000;

	/**
	 * @notice Editor is responsible for editing (updating) iNFT records in general,
	 *      adding/removing locked ALI tokens to/from iNFT in particular
	 *
	 * @dev Role ROLE_EDITOR allows editing iNFTs (calling `increaseAli`, `decreaseAli` functions)
	 */
	uint32 public constant ROLE_EDITOR = 0x0004_0000;

	/**
	 * @notice URI manager is responsible for managing base URI
	 *      part of the token URI ERC721Metadata interface
	 *
	 * @dev Role ROLE_URI_MANAGER allows updating the base URI
	 *      (executing `setBaseURI` function)
	 */
	uint32 public constant ROLE_URI_MANAGER = 0x0010_0000;

	/**
	 * @dev Fired in setBaseURI()
	 *
	 * @param _by an address which executed update
	 * @param _oldVal old _baseURI value
	 * @param _newVal new _baseURI value
	 */
	event BaseURIUpdated(address indexed _by, string _oldVal, string _newVal);

	/**
	 * @dev Fired in setTokenURI()
	 *
	 * @param _by an address which executed update
	 * @param _tokenId token ID which URI was updated
	 * @param _oldVal old _baseURI value
	 * @param _newVal new _baseURI value
	 */
	event TokenURIUpdated(address indexed _by, uint256 indexed _tokenId, string _oldVal, string _newVal);

	/**
	 * @dev Fired in mint() when new iNFT is created
	 *
	 * @param _by an address which executed the mint function
	 * @param _owner current owner of the NFT
	 * @param _recordId ID of the iNFT minted (created, bound)
	 * @param _aliValue amount of ALI tokens locked within newly created iNFT
	 * @param _personalityContract AI Personality smart contract address
	 * @param _personalityId ID of the AI Personality locked within newly created iNFT
	 * @param _targetContract target NFT smart contract address
	 * @param _targetId target NFT ID (where this iNFT binds to and belongs to)
	 */
	event Minted(
		address indexed _by,
		address indexed _owner,
		uint256 indexed _recordId,
		uint96 _aliValue,
		address _personalityContract,
		uint96 _personalityId,
		address _targetContract,
		uint256 _targetId
	);

	/**
	 * @dev Fired in increaseAli() and decreaseAli() when iNFT record is updated
	 *
	 * @param _by an address which executed the update
	 * @param _owner iNFT (target NFT) owner
	 * @param _recordId ID of the updated iNFT
	 * @param _oldAliValue amount of ALI tokens locked within iNFT before update
	 * @param _newAliValue amount of ALI tokens locked within iNFT after update
	 */
	event Updated(
		address indexed _by,
		address indexed _owner,
		uint256 indexed _recordId,
		uint96 _oldAliValue,
		uint96 _newAliValue
	);

	/**
	 * @dev Fired in burn() when an existing iNFT gets destroyed
	 *
	 * @param _by an address which executed the burn function
	 * @param _recordId ID of the iNFT burnt (destroyed, unbound)
	 * @param _recipient and address which received unlocked AI Personality and ALI tokens
	 * @param _aliValue amount of ALI tokens transferred from the destroyed iNFT
	 * @param _personalityContract AI Personality smart contract address
	 * @param _personalityId ID of the AI Personality transferred from the destroyed iNFT
	 * @param _targetContract target NFT smart contract
	 * @param _targetId target NFT ID (where this iNFT was bound to and belonged to)
	 */
	event Burnt(
		address indexed _by,
		uint256 indexed _recordId,
		address indexed _recipient,
		uint96 _aliValue,
		address _personalityContract,
		uint96 _personalityId,
		address _targetContract,
		uint256 _targetId
	);

	/**
	 * @dev Creates/deploys an iNFT instance bound to already deployed ALI token instance
	 *
	 * @param _ali address of the deployed ALI ERC20 Token instance the iNFT is bound to
	 */
	constructor(address _ali) {
		// verify the inputs are set
		require(_ali != address(0), "ALI Token addr is not set");

		// verify _ali is a valid ERC20
		require(ERC165(_ali).supportsInterface(type(ERC20).interfaceId), "unexpected ALI Token type");

		// setup smart contract internal state
		aliContract = _ali;
	}

	/**
	 * @inheritdoc ERC165
	 */
	function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
		// reconstruct from current interface and super interface
		return interfaceId == type(IntelligentNFTv2Spec).interfaceId;
	}

	/**
	 * @dev Restricted access function which updates base URI used to construct
	 *      ERC721Metadata.tokenURI
	 *
	 * @param _baseURI new base URI to set
	 */
	function setBaseURI(string memory _baseURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// emit an event first - to log both old and new values
		emit BaseURIUpdated(msg.sender, baseURI, _baseURI);

		// and update base URI
		baseURI = _baseURI;
	}

	/**
	 * @dev Returns token URI if it was previously set with `setTokenURI`,
	 *      otherwise constructs it as base URI + token ID
	 *
	 * @param _recordId iNFT ID to query metadata link URI for
	 * @return URI link to fetch iNFT metadata from
	 */
	function tokenURI(uint256 _recordId) public view override returns (string memory) {
		// verify token exists
		require(exists(_recordId), "iNFT doesn't exist");

		// read the token URI for the token specified
		string memory _tokenURI = _tokenURIs[_recordId];

		// if token URI is set
		if(bytes(_tokenURI).length > 0) {
			// just return it
			return _tokenURI;
		}

		// if base URI is not set
		if(bytes(baseURI).length == 0) {
			// return an empty string
			return "";
		}

		// otherwise concatenate base URI + token ID
		return StringUtils.concat(baseURI, StringUtils.itoa(_recordId, 10));
	}

	/**
	 * @dev Sets the token URI for the token defined by its ID
	 *
	 * @param _tokenId an ID of the token to set URI for
	 * @param _tokenURI token URI to set
	 */
	function setTokenURI(uint256 _tokenId, string memory _tokenURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// we do not verify token existence: we want to be able to
		// preallocate token URIs before tokens are actually minted

		// emit an event first - to log both old and new values
		emit TokenURIUpdated(msg.sender, _tokenId, _tokenURIs[_tokenId], _tokenURI);

		// and update token URI
		_tokenURIs[_tokenId] = _tokenURI;
	}

	/**
	 * @notice Verifies if given iNFT exists
	 *
	 * @param recordId iNFT ID to verify existence of
	 * @return true if iNFT exists, false otherwise
	 */
	function exists(uint256 recordId) public view override returns (bool) {
		// verify if biding exists for that tokenId and return the result
		return bindings[recordId].targetContract != address(0);
	}

	/**
	 * @notice Returns an owner of the given iNFT.
	 *      By definition iNFT owner is an owner of the target NFT
	 *
	 * @param recordId iNFT ID to query ownership information for
	 * @return address of the given iNFT owner
	 */
	function ownerOf(uint256 recordId) public view override returns (address) {
		// get the link to the token binding (we need to access only one field)
		IntelliBinding storage binding = bindings[recordId];

		// verify the binding exists and throw standard Zeppelin message if not
		require(binding.targetContract != address(0), "iNFT doesn't exist");

		// delegate `ownerOf` call to the target NFT smart contract
		return ERC721(binding.targetContract).ownerOf(binding.targetId);
	}

	/**
	 * @dev Restricted access function which creates an iNFT, binding it to the specified
	 *      NFT, locking the AI Personality specified, and funded with the amount of ALI specified
	 *
	 * @dev Locks AI Personality defined by its ID within iNFT smart contract;
	 *      AI Personality must be transferred to the iNFT smart contract
	 *      prior to calling the `mint`, but in the same transaction with `mint`
	 *
	 * @dev Locks specified amount of ALI token within iNFT smart contract;
	 *      ALI token amount must be transferred to the iNFT smart contract
	 *      prior to calling the `mint`, but in the same transaction with `mint`
	 *
	 * @dev To summarize, minting transaction (a transaction which executes `mint`) must
	 *      1) transfer AI Personality
	 *      2) transfer ALI tokens if they are to be locked
	 *      3) mint iNFT
	 *      NOTE: breaking the items above into multiple transactions is not acceptable!
	 *            (results in a security risk)
	 *
	 * @dev The NFT to be linked to is not required to owned by the funder, but it must exist;
	 *      throws if target NFT doesn't exist
	 *
	 * @dev This is a restricted function which is accessed by iNFT Linker
	 *
	 * @param recordId ID of the iNFT to mint (create, bind)
	 * @param aliValue amount of ALI tokens to bind to newly created iNFT
	 * @param personalityContract AI Personality contract address
	 * @param personalityId ID of the AI Personality to bind to newly created iNFT
	 * @param targetContract target NFT smart contract
	 * @param targetId target NFT ID (where this iNFT binds to and belongs to)
	 */
	function mint(
		uint256 recordId,
		uint96 aliValue,
		address personalityContract,
		uint96 personalityId,
		address targetContract,
		uint256 targetId
	) public {
		// verify the access permission
		require(isSenderInRole(ROLE_MINTER), "access denied");

		// verify personalityContract is a valid ERC721
		require(ERC165(personalityContract).supportsInterface(type(ERC721).interfaceId), "personality is not ERC721");

		// verify targetContract is a valid ERC721
		require(ERC165(targetContract).supportsInterface(type(ERC721).interfaceId), "target NFT is not ERC721");

		// verify this iNFT is not yet minted
		require(!exists(recordId), "iNFT already exists");

		// verify target NFT is not yet bound to
		require(reverseBindings[targetContract][targetId] == 0, "NFT is already bound");

		// verify AI Personality is not yet locked
		require(personalityBindings[personalityContract][personalityId] == 0, "personality already linked");

		// verify if AI Personality is already transferred to iNFT
		require(ERC721(personalityContract).ownerOf(personalityId) == address(this), "personality is not yet transferred");

		// retrieve NFT owner and verify if target NFT exists
		address owner = ERC721(targetContract).ownerOf(targetId);
		// Note: we do not require funder to be NFT owner,
		// if required this constraint should be added by the caller (iNFT Linker)
		require(owner != address(0), "target NFT doesn't exist");

		// in case when ALI tokens are expected to be locked within iNFT
		if(aliValue > 0) {
			// verify ALI tokens are already transferred to iNFT
			require(aliBalance + aliValue <= ERC20(aliContract).balanceOf(address(this)), "ALI tokens not yet transferred");

			// update ALI balance on the contract
			aliBalance += aliValue;
		}

		// bind AI Personality transferred and ALI ERC20 value transferred to an NFT specified
		bindings[recordId] = IntelliBinding({
			personalityContract : personalityContract,
			personalityId : personalityId,
			aliValue : aliValue,
			targetContract : targetContract,
			targetId : targetId
		});

		// fill in the reverse binding
		reverseBindings[targetContract][targetId] = recordId;

		// fill in the AI Personality to iNFT binding
		personalityBindings[personalityContract][personalityId] = recordId;

		// increase total supply counter
		totalSupply++;

		// emit an event
		emit Minted(
			msg.sender,
			owner,
			recordId,
			aliValue,
			personalityContract,
			personalityId,
			targetContract,
			targetId
		);
	}

	/**
	 * @dev Restricted access function which creates several iNFTs, binding them to the specified
	 *      NFTs, locking the AI Personalities specified, each funded with the amount of ALI specified
	 *
	 * @dev Locks AI Personalities defined by their IDs within iNFT smart contract;
	 *      AI Personalities must be transferred to the iNFT smart contract
	 *      prior to calling the `mintBatch`, but in the same transaction with `mintBatch`
	 *
	 * @dev Locks specified amount of ALI token within iNFT smart contract for each iNFT minted;
	 *      ALI token amount must be transferred to the iNFT smart contract
	 *      prior to calling the `mintBatch`, but in the same transaction with `mintBatch`
	 *
	 * @dev To summarize, minting transaction (a transaction which executes `mintBatch`) must
	 *      1) transfer AI Personality
	 *      2) transfer ALI tokens if they are to be locked
	 *      3) mint iNFT
	 *      NOTE: breaking the items above into multiple transactions is not acceptable!
	 *            (results in a security risk)
	 *
	 * @dev The NFTs to be linked to are not required to owned by the funder, but they must exist;
	 *      throws if target NFTs don't exist
	 *
	 * @dev iNFT IDs to be minted: [recordId, recordId + n)
	 * @dev AI Personality IDs to be locked: [personalityId, personalityId + n)
	 * @dev NFT IDs to be bound to: [targetId, targetId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev This is a restricted function which is accessed by iNFT Linker
	 *
	 * @param recordId ID of the first iNFT to mint (create, bind)
	 * @param aliValue amount of ALI tokens to bind to each newly created iNFT
	 * @param personalityContract AI Personality contract address
	 * @param personalityId ID of the first AI Personality to bind to newly created iNFT
	 * @param targetContract target NFT smart contract
	 * @param targetId first target NFT ID (where this iNFT binds to and belongs to)
	 * @param n how many iNFTs to mint, sequentially increasing the recordId, personalityId, and targetId
	 */
	function mintBatch(
		uint256 recordId,
		uint96 aliValue,
		address personalityContract,
		uint96 personalityId,
		address targetContract,
		uint256 targetId,
		uint96 n
	) public {
		// verify the access permission
		require(isSenderInRole(ROLE_MINTER), "access denied");

		// verify n is set properly
		require(n > 1, "n is too small");

		// verify personalityContract is a valid ERC721
		require(ERC165(personalityContract).supportsInterface(type(ERC721).interfaceId), "personality is not ERC721");

		// verify targetContract is a valid ERC721
		require(ERC165(targetContract).supportsInterface(type(ERC721).interfaceId), "target NFT is not ERC721");

		// verifications: for each iNFT in a batch
		for(uint96 i = 0; i < n; i++) {
			// verify this token ID is not yet bound
			require(!exists(recordId + i), "iNFT already exists");

			// verify the AI Personality is not yet bound
			require(personalityBindings[personalityContract][personalityId + i] == 0, "personality already linked");

			// verify if AI Personality is already transferred to iNFT
			require(ERC721(personalityContract).ownerOf(personalityId + i) == address(this), "personality is not yet transferred");

			// retrieve NFT owner and verify if target NFT exists
			address owner = ERC721(targetContract).ownerOf(targetId + i);
			// Note: we do not require funder to be NFT owner,
			// if required this constraint should be added by the caller (iNFT Linker)
			require(owner != address(0), "target NFT doesn't exist");

			// emit an event - we log owner for each iNFT
			// and its convenient to do it here when we have the owner inline
			emit Minted(
				msg.sender,
				owner,
				recordId + i,
				aliValue,
				personalityContract,
				personalityId + i,
				targetContract,
				targetId + i
			);
		}

		// cumulative ALI value may overflow uint96, store it into uint256 on stack
		uint256 _aliValue = uint256(aliValue) * n;

		// in case when ALI tokens are expected to be locked within iNFT
		if(_aliValue > 0) {
			// verify ALI tokens are already transferred to iNFT
			require(aliBalance + _aliValue <= ERC20(aliContract).balanceOf(address(this)), "ALI tokens not yet transferred");
			// update ALI balance on the contract
			aliBalance += _aliValue;
		}

		// minting: for each iNFT in a batch
		for(uint96 i = 0; i < n; i++) {
			// bind AI Personality transferred and ALI ERC20 value transferred to an NFT specified
			bindings[recordId + i] = IntelliBinding({
				personalityContract : personalityContract,
				personalityId : personalityId + i,
				aliValue : aliValue,
				targetContract : targetContract,
				targetId : targetId + i
			});

			// fill in the AI Personality to iNFT binding
			personalityBindings[personalityContract][personalityId + i] = recordId + i;

			// fill in the reverse binding
			reverseBindings[targetContract][targetId + i] = recordId + i;
		}

		// increase total supply counter
		totalSupply += n;
	}

	/**
	 * @dev Restricted access function which destroys an iNFT, unbinding it from the
	 *      linked NFT, releasing an AI Personality, and ALI tokens locked in the iNFT
	 *
	 * @dev Transfers an AI Personality locked in iNFT to its owner via ERC721.safeTransferFrom;
	 *      owner must be an EOA or implement ERC721Receiver.onERC721Received properly
	 * @dev Transfers ALI tokens locked in iNFT to its owner
	 * @dev Since iNFT owner is determined as underlying NFT owner, this underlying NFT must
	 *      exist and its ownerOf function must not throw and must return non-zero owner address
	 *      for the underlying NFT ID
	 *
	 * @dev Doesn't verify if it's safe to send ALI tokens to the NFT owner, this check
	 *      must be handled by the transaction executor
	 *
	 * @dev This is a restricted function which is accessed by iNFT Linker
	 *
	 * @param recordId ID of the iNFT to burn (destroy, unbind)
	 */
	function burn(uint256 recordId) public {
		// verify the access permission
		require(isSenderInRole(ROLE_BURNER), "access denied");

		// decrease total supply counter
		totalSupply--;

		// read the token binding (we'll need to access all the fields)
		IntelliBinding memory binding = bindings[recordId];

		// verify binding exists
		require(binding.targetContract != address(0), "not bound");

		// destroy binding first to protect from any reentrancy possibility
		delete bindings[recordId];

		// free the reverse binding
		delete reverseBindings[binding.targetContract][binding.targetId];

		// free the AI Personality binding
		delete personalityBindings[binding.personalityContract][binding.personalityId];

		// determine an owner of the underlying NFT
		address owner = ERC721(binding.targetContract).ownerOf(binding.targetId);

		// verify that owner address is set (not a zero address)
		require(owner != address(0), "no such NFT");

		// transfer the AI Personality to the NFT owner
		// using safe transfer since we don't know if owner address can accept the AI Personality right now
		ERC721(binding.personalityContract).safeTransferFrom(address(this), owner, binding.personalityId);

		// in case when ALI tokens were locked within iNFT
		if(binding.aliValue > 0) {
			// update ALI balance on the contract prior to token transfer (reentrancy style)
			aliBalance -= binding.aliValue;

			// transfer the ALI tokens to the NFT owner
			ERC20(aliContract).transfer(owner, binding.aliValue);
		}

		// emit an event
		emit Burnt(
			msg.sender,
			recordId,
			owner,
			binding.aliValue,
			binding.personalityContract,
			binding.personalityId,
			binding.targetContract,
			binding.targetId
		);
	}

	/**
	 * @dev Restricted access function which updates iNFT record by increasing locked ALI tokens value,
	 *      effectively locking additional ALI tokens to the iNFT
	 *
	 * @dev Locks specified amount of ALI token within iNFT smart contract;
	 *      ALI token amount must be transferred to the iNFT smart contract
	 *      prior to calling the `increaseAli`, but in the same transaction with `increaseAli`
	 *
	 * @dev To summarize, update transaction (a transaction which executes `increaseAli`) must
	 *      1) transfer ALI tokens
	 *      2) update the iNFT
	 *      NOTE: breaking the items above into multiple transactions is not acceptable!
	 *            (results in a security risk)
	 *
	 * @dev This is a restricted function which is accessed by iNFT Linker
	 *
	 * @param recordId ID of the iNFT to update
	 * @param aliDelta amount of ALI tokens to lock
	 */
	function increaseAli(uint256 recordId, uint96 aliDelta) public {
		// verify the access permission
		require(isSenderInRole(ROLE_EDITOR), "access denied");

		// verify the inputs are set
		require(aliDelta != 0, "zero value");

		// get iNFT owner for logging (check iNFT record exists under the hood)
		address owner = ownerOf(recordId);

		// cache the ALI value of the record
		uint96 aliValue = bindings[recordId].aliValue;

		// verify ALI tokens are already transferred to iNFT
		require(aliBalance + aliDelta <= ERC20(aliContract).balanceOf(address(this)), "ALI tokens not yet transferred");

		// update ALI balance on the contract
		aliBalance += aliDelta;

		// update ALI balance on the binding
		bindings[recordId].aliValue = aliValue + aliDelta;

		// emit an event
		emit Updated(msg.sender, owner, recordId, aliValue, aliValue + aliDelta);
	}

	/**
	 * @dev Restricted access function which updates iNFT record by decreasing locked ALI tokens value,
	 *      effectively unlocking some or all ALI tokens from the iNFT
	 *
	 * @dev Unlocked tokens are sent to the recipient address specified
	 *
	 * @dev This is a restricted function which is accessed by iNFT Linker
	 *
	 * @param recordId ID of the iNFT to update
	 * @param aliDelta amount of ALI tokens to unlock
	 * @param recipient an address to send unlocked tokens to
	 */
	function decreaseAli(uint256 recordId, uint96 aliDelta, address recipient) public {
		// verify the access permission
		require(isSenderInRole(ROLE_EDITOR), "access denied");

		// verify the inputs are set
		require(aliDelta != 0, "zero value");
		require(recipient != address(0), "zero address");

		// get iNFT owner for logging (check iNFT record exists under the hood)
		address owner = ownerOf(recordId);

		// cache the ALI value of the record
		uint96 aliValue = bindings[recordId].aliValue;

		// positive or zero resulting balance check
		require(aliValue >= aliDelta, "not enough ALI");

		// update ALI balance on the contract
		aliBalance -= aliDelta;

		// update ALI balance on the binding
		bindings[recordId].aliValue = aliValue - aliDelta;

		// transfer the ALI tokens to the recipient
		ERC20(aliContract).transfer(recipient, aliDelta);

		// emit an event
		emit Updated(msg.sender, owner, recordId, aliValue, aliValue - aliDelta);
	}

	/**
	 * @notice Determines how many tokens are locked in a particular iNFT
	 *
	 * @dev A shortcut for bindings(recordId).aliValue
	 * @dev Throws if iNFT specified doesn't exist
	 *
	 * @param recordId iNFT ID to query locked tokens balance for
	 * @return locked tokens balance, bindings[recordId].aliValue
	 */
	function lockedValue(uint256 recordId) public view returns(uint96) {
		// ensure iNFT exists
		require(exists(recordId), "iNFT doesn't exist");

		// read and return ALI value locked in the binding
		return bindings[recordId].aliValue;
	}
}