// contracts/HyperCert.sol
// SPDX-License-Identifier: MIT

/**
 *								 555555555555555   
 *								555555	  5B55   
 *							  555   5555   5555	
 *							 5B555555555  55B55	
 *	 55555555555			555555555  555555	  
 *	555555555555555		 5555555555555555	   
 *	55B5	   555B55	555B55555555555		   
 *	 5B55   5555  55B5  55555					  
 *	  55555  55555555555B555  5555555555		   
 *	   55555555555BB555555  555555555555		   
 *		 5555555555555B5B5 5B555555 55B5		   
 *			   5555 5555B55B55555555555			
 *			555555	5B5B555555555555			 
 *		   5555555555 5B5B555555555				
 *			55555555B55B55						 
 *			55B55B55555555						 
 *			  55555BB555B5						 
 *					 555B5						 
 *					  5BB5						 
 *					  5555						 
 *					  5BB5						 
 *				 555555BB555555					
 *			   5555555555555555555				 
 *			  555555555555  555B555				
 *			   55555555555  5555555					  
 *									)									  )	)  
 *			)		   (   (	( /( (	  (	(	   (	 )  (	( /( ( /(  
 *  `  )   ( /(  `  )	))\  )(   )\()))(	))\  ))\	 ))\ ( /(  )(   )\()))\()) 
 *  /(/(   )(_)) /(/(   /((_)(()\ (_))/(()\  /((_)/((_)   /((_))(_))(()\ (_))((_)\  
 * ((_)_\ ((_)_ ((_)_\ (_))   ((_)| |_  ((_)(_)) (_))	(_)) ((_)_  ((_) | |_ | |_)_ 
 * | '_ \)/ _` || '_ \)/ -_) | '_||  _|| '_|/ -_)/ -_) _ / -_)/ _` || '_||  _|| '  \  
 * | .__/ \__,_|| .__/ \___| |_|   \__||_|  \___|\___|(_)\___|\__,_||_|   \__||_||_| 
 * |_|			|_|																  
 *
 **/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./utils/UIntArrays.sol";

/**
 * @dev Implementation of the basic standard hypercert.
 * Originally based on a talk by David Dalrymple @ Protocol Labs
 *
 */
contract HyperCert is ERC1155 {
	using Counters for Counters.Counter;
	using UIntArrays for uint256[];

	Counters.Counter private _claimIds;

 	/**
 	 * @dev Emitted when `claims` are minted by `operator` with credit to `contributors`.
 	 */
 	event ContributionCredit(
 		address indexed operator,  
 		uint256[] claims, 
 		address[] contributors);

 	/**
 	 * @dev Emitted when `account` claiming `claims` are attested to by `operator` .
 	 */
 	event Attestation(
 		address indexed operator,  
 		uint256[] claims, 
 		address indexed account);

	
	struct HyperCertURIMetadata {
		// Used as the metadata URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
		string uri;
		// Used as the public goods space URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}/claims/{claimId}.json
		string claimsUri;
	}

	HyperCertURIMetadata private _certMetadata;

	// Mapping from token ID to transferability
	mapping(uint256 => mapping(address => bool)) private _retirements;

	// Mapping from token ID to list of claimIds
	mapping(uint256 => mapping(address => uint256[])) private _claims;

	/**
	* @dev See {_setURI}.
	*/
	constructor(string memory uri_, string memory claimsUri_) ERC1155(uri_) {
		_setURI(uri_, claimsUri_);
	}

	function supportsInterface(bytes4 interfaceId) public view override(ERC1155) returns (bool) {
		return super.supportsInterface(interfaceId);
	}

	/**
	* @dev See {IERC1155MetadataURI-uri}.
	*
	* This implementation returns the same URI for *all* token types. It relies
	* on the token type ID substitution mechanism
	* https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
	*
	* Clients calling this function must replace the `\{id\}` substring with the
	* actual token type ID.
	*/
	function uri(uint256) public view virtual override returns (string memory) {
		return _certMetadata.uri;
	}

	function claimsUri(uint256) public view virtual returns (string memory) {
		return _certMetadata.claimsUri;
	}

	function _setURI(string memory uri_, string memory claimsUri_) internal virtual {
		_certMetadata.uri = uri_;
		_certMetadata.claimsUri = claimsUri_;
	}

	function retirementOf(address account, uint256 id) public view virtual returns (bool) {
		return _retirements[id][account];
	}

	function claimsOf(address account, uint256 id) public view virtual returns (uint256[] memory) {
		return _claims[id][account];
	}

	function claimsOfBatch(address[] memory accounts, uint256[] memory ids)
		public
		view
		virtual
		returns (uint256[][] memory)
	{
		_isEqual(accounts.length, ids.length);
		uint256[][] memory batchClaims = new uint256[][](ids.length);

		for (uint256 i = 0; i < ids.length; ++i) {
			batchClaims[i] = claimsOf(accounts[i], ids[i]);
		}

		return batchClaims;
	}

	function mint(
		address to,
		uint256 id,
		uint256 amount,
		uint256 unitsOfPublicGoodsSpace,
		address[] memory contributors_
	) public virtual {
		_minimumIsMet(amount, unitsOfPublicGoodsSpace, 0);

		for (uint256 i = 0; i < unitsOfPublicGoodsSpace; i++) {
			_claimIds.increment();
			_claims[id][to].push(_claimIds.current());
		}
		emit ContributionCredit(_msgSender(), _claims[id][to], contributors_);
		_mint(to, id, amount, "");
	}


	function mintBatch(
		address to,
		uint256[] calldata ids,
		uint256[] calldata amounts,
		uint256[] calldata unitsOfPublicGoodsSpace,
		address[][] calldata contributors_
	) public virtual {
		_isEqual(ids.length, amounts.length);
		_isEqual(ids.length, unitsOfPublicGoodsSpace.length);
		_isEqual(ids.length, contributors_.length);

		for (uint256 i = 0; i < ids.length; i++) {

			_minimumIsMet(amounts[i], unitsOfPublicGoodsSpace[i], 0);

			for (uint256 y = 0; y < unitsOfPublicGoodsSpace[i]; y++) {
				_claimIds.increment();
				_claims[ids[i]][to].push(_claimIds.current());
			}

			emit ContributionCredit(_msgSender(), _claims[ids[i]][to], contributors_[i]);
		}
		_mintBatch(to, ids, amounts, "");
	}

	/**
	 * @notice Mergeable and splittable thus providing additional avenues of liquidity for investors
	 * @dev 
	 *
	 * Emits a {} event.
	 *
	 * Requirements:
	 *
	 * - 
	 * - 
	 */
	function atomicMergeAndSplit(
		address from,
		address to,
		uint256[] calldata existingIds,
		uint256[] calldata newIds,
		uint256[] calldata newAmounts,
		uint256[][] calldata newClaims_
	) public virtual {
		_isApproved(from);
		_isEqual(newIds.length, newClaims_.length);
		_isEqual(newIds.length, newAmounts.length);
		_isGreaterThan(newIds.length, 0);
		
		{
			require( 
					_flattenArray(newClaims_).isSameList(
						_flattenArray(
							claimsOfBatch(
								_asManyArray(from, existingIds.length),
								existingIds
							)
						)
					)
					, "HyperCert: INVALID_CLAIMS" );
		}
		{
			uint256[] memory balances;
			balances = balanceOfBatch(
									_asManyArray(from, existingIds.length),
									existingIds
								);

			_isEqual(balances.sum(), newAmounts.sum());
			_isGreaterThan(balances.sum() + newAmounts.sum(), 0);

			// Reassign claims
			for (uint256 i = 0; i < newIds.length; i++) {
				_claims[newIds[i]][to] = newClaims_[i];
			}

			_burnBatch(from, existingIds, balances );
			_mintBatch(to, newIds, newAmounts, "");
		}
	}

	/**
	 * @dev See {ERC1155-_beforeTokenTransfer}.
	 */
	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual override {
		super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

		if (to == address(0)) {
			for (uint256 i = 0; i < ids.length; ++i) {
				_isTransferable(from, ids[i]);
				delete _claims[ids[i]][from];
			}
		}

		if (to != address(0) && from != address(0)) {
			for (uint256 i = 0; i < ids.length; ++i) {
				_isTransferable(from, ids[i]);
				_claims[ids[i]][to] = _claims[ids[i]][from];
				delete _claims[ids[i]][from];
			}
		}
	}

	/**
	 * @notice Retireable after attestation thus providing incentives to state owner funded the full value stream of realized impact
	 * @dev 
	 *
	 * Emits a {} event.
	 *
	 * Requirements:
	 *
	 * - 
	 * - 
	 */
	function retire(
		address account,
		uint256 id
	) public virtual {
		_isApproved(account);
		require(balanceOf(account, id) > 0, "HyperCert: NO_BALANCE");
		_retirements[id][account] = true;
	}

	/**
	 * @notice Attestable by 3rd parties thus creating a clear transition from promised impact to realized impact. 
	 * Trusted party has ability to take NFTs, so should be a truly trusted party.
	 * 
	 * @dev `msg.sender` attests to realization of `_claims` attributed to token type `id` owned by `account`
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - .
	 */
	function attest(
		address account,
		uint256 id
	) public virtual {
		_isApproved(account);
		emit Attestation(_msgSender(), _claims[id][account], account);
	}

	// Added isTransferable only
	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual override {
		_isApproved(from);
		_safeTransferFrom(from, to, id, amount, data);
	}

	// Added retirement check
	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual override {
		_isApproved(from);
		_safeBatchTransferFrom(from, to, ids, amounts, data);
	}

	//===== Utilities =====//

	function _asManyArray(address element, uint256 n) internal pure returns (address[] memory) {
		address[] memory array = new address[](n);
		for (uint256 i = 0; i < n; ++i) {
			array[i] = element;
		}

		return array;
	}

	function _flattenArray(uint256[][] memory arr) internal pure returns (uint256[] memory) {
		uint256 childLengths;
		uint256 n = 0;
		for (uint256 i = 0; i < arr.length; i++) {
			childLengths += arr[i].length;
		}
		uint256[] memory flattenedArray = new uint256[](childLengths);
		for (uint256 i = 0; i < arr.length; i++) {
			for (uint256 y = 0; y < arr[i].length; y++) {
				flattenedArray[n] = arr[i][y];
				n += 1;
			}
		}
		return flattenedArray;
	}

	//===== Modifiers =====//


	function _isTransferable(address account, uint256 id) internal view {
		require(!retirementOf(account, id), "HyperCert: RETIRED");
	}

	function _isApproved(address account) internal view {
		require(
			account == _msgSender() || isApprovedForAll(account, _msgSender()),
			"HyperCert: NOT_APPROVED"
		);
	}

	function _isEqual(uint256 x, uint256 y) internal pure {
		require(x == y, "HyperCert: BAD_INPUT");
	}

	function _isGreaterThan(uint256 x, uint256 y) internal pure {
		require(x > y, "HyperCert: BAD_INPUT");
	}

	function _minimumIsMet(uint256 x, uint256 y, uint256 min) internal pure {
		require(
			x > min || y == 0
			, "HyperCert: BAD_INPUT");
	}

}