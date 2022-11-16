//                             .*+=.
//                        .#+.  -###: *#*-
//                         ###+   --   -=:
//                         .#+:.+###*.+*=.
//       .::-----.       *:   :#######:*##=                                                             +++++=-:.
//  -+#%@@@@@@@@@@@%+.  :#%*  *########-*##.                                                           [email protected]@@@@@@@@@%*=:
// %@@@@@@@@@@@@@@@@@@#. :*#+ +############:           :-=++++=:                                       [email protected]@@@@@@@@@@@@@@=
// [email protected]@@@@@@@@@@@@@@@@@@@:     .########=:.            #@@@@@@@@@@#.                                    *@@@@@@@@@@@@@@@@@-
//  %@@@@@@%=--=+%@@@@@@@:      =+***=:  :=+*+=:      %@@@@:.-*@@@@.   .::::::::::-.      =****+:      %@@@@@@++*@@@@@@@@@-
//  [email protected]@@@@@@      [email protected]@@@@@#   *%+.      [email protected]@@@@@@@@-    #@@@#    *@@@=   %@@@@@@@@@@@=     #@@@@@@%      @@@@@@#    -%@@@@@@%
//   #@@@@@@=      :@@@@@@   @@@@@=   [email protected]@@@%#%@@@@.   *@@@#   .%@@@.   @@@@@@@@@@@%     [email protected]@@@@@@@     [email protected]@@@@@=      #@@@@@@
//   :@@@@@@%       *@@@@@   #@@@@@   [email protected]@@@   #@@@-   [email protected]@@@  -%@@%:    @@@@#-:::::      %@@@:%@@@:    [email protected]@@@@@.      [email protected]@@@@%
//    *@@@@@@=      *@@@@%   [email protected]@@@@.  [email protected]@@#   :**+.   [email protected]@@@%@@@@#      @@@@+           [email protected]@@+ [email protected]@@-    [email protected]@@@@@       *@@@@@+
//     @@@@@@%     [email protected]@@@@=   [email protected]@@@@=  [email protected]@@#           [email protected]@@@@@@@@@*.    @@@@+           @@@@  :@@@+    *@@@@@*      [email protected]@@@@%
//     [email protected]@@@@@+:-*@@@@@@+    [email protected]@@@@*  [email protected]@@%  ==---:   [email protected]@@@==*@@@@@+   @@@@%**#*      [email protected]@@=   @@@#    #@@@@@-   .=%@@@@@*
//      #@@@@@@@@@@@@@@*      @@@@@%  :@@@@ :@@@@@@*   @@@@   .%@@@@:  @@@@@@@@@      %@@@    @@@@    @@@@@@@%%@@@@@@@%:
//      [email protected]@@@@@@@@@@@@@@%=    #@@@@@   @@@@ [email protected]@@@@@%   @@@%    :@@@@+  @@@@%===-     [email protected]@@%**[email protected]@@@   [email protected]@@@@@@@@@@@@@*-
//       [email protected]@@@@@%**#@@@@@@*   [email protected]@@@@:  %@@@:   #@@@@   #@@%     @@@@+  @@@@+         %@@@@@@@@@@@@:  :@@@@@@@@@@@@*
//        %@@@@%     %@@@@@:  :@@@@@=  *@@@+   %@@@%   *@@@    [email protected]@@@-  @@@@+        [email protected]@@@%***@@@@@=  [email protected]@@@@@:#@@@@@:
//        :@@@@@:    *@@@@@-   @@@@@#  :@@@@#+%@@@@*   [email protected]@@--=#@@@@#   @@@@@@@@@#   %@@@@-   [email protected]@@@*  [email protected]@@@@%  %@@@@@.
//         [email protected]@@@*  [email protected]@@@@#    #@@@@@   [email protected]@@@@@@@@#    [email protected]@@@@@@@@@=    @@@@@@@@@@  [email protected]@@@@    [email protected]@@@%  #@@@@@*  [email protected]@@@@%.
//          @@@@@@@@@@@@%=     -###*+    .+#@@%#+:      %@@@@%#+-      #%##%%%%#*  +%%%%+    -%%%%%  %@@@@@-   :@@@@@%
//          :%@@@@%#*+-.                                                                              ::---     :@@@@@%.
//                        .---:                                                                                  .-==++:
//                      =*+:.++-      :=.   ..  .:.  .---:    ::.    .::.       .         ....   ...:::::
//                     +##=  ##+ =*+- -==- ###: ##=  *#####-  ###  :######=   =###. ##########= *########-
//                     ####+-:   -###+##+ -+=+=.++. :##==###  ###  ###:.###.  +#*#* .-::###:... -###=---:
//                     -######.   .*###+  #######*  ==-  .=+  ###  ###  .--   ##=-#+    *##-     ###=-=-
//                   --   .###:    :##+  =##-####- .##= .*#* .===  -=+   === .##*=##-   :##*     =######.
//                  :##+  -##+    :##=  .##* *###. =#######- =###  +*+-.:--- :+*#+###:   *##:     ###=..
//                  -###+*##=    .##=   +##: -##+  +######:  =###: -#######: =+=: .::-   :##*     +##*::::....
//                   =*##*+.      .     .::   ::.  .::-::    .::.   :=+++=.  :==.  .**+   :-=:    .###########:

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./interfaces/IBigBearSyndicate.sol";
import "../utils/Whitelists.sol";

error NotEnoughSupply();
error IncorrectEtherValue(uint256 expectedValue);
error PhaseNotStarted(uint256 startTime);
error PhaseOver(uint256 endTime);
error NotWhitelisted(address address_);
error InvalidAddress(address address_);
error InvalidTier(uint256 tier);
error MintAllowanceExceeded(address address_, uint256 allowance);
error MintLimitExceeded(uint256 limit);
error InsufficientBalance(uint256 balance, uint256 required);

/**
 * @notice This is a 2-phase minter contract that includes a allow list and public sale.
 * @dev This is a heavily modified version of the Forgotten Runes Warriors Minters contract.
 * @dev The contract can be found at https://etherscan.io/address/0xB4d9AcB0a6735058908E943e966867A266619fBD#code.
 */
contract BigBearSyndicateMinter is
	AccessControlUpgradeable,
	PausableUpgradeable,
	ReentrancyGuardUpgradeable
{
	// ------------------------------
	// 			V1 Variables
	// ------------------------------

	/// @notice The address of the BigBearSyndicate contract
	IBigBearSyndicate public bbs;

	/// @notice Tracks the total count of bears for sale
	uint256 public supplyLimit;

	/// @dev Used for incrementing the token IDs
	uint256 public currentTokenId;

	using Whitelists for Whitelists.MerkleProofWhitelist;

	/// @notice The start timestamp for the free mint
	uint256 public freeMintStartTime;

	/// @notice The start timestamp for the allow list sale
	uint256 public allowListStartTime;

	/// @notice The start timestamp for the public sale
	uint256 public publicStartTime;

	/// @notice The whitelist for the allow list sale
	Whitelists.MerkleProofWhitelist private allowListWhitelist;

	/// @notice The number of tokens that can be minted by an address through the allow list mint
	uint256 public allowListMints;

	/// @notice Tracks the number of tokens an address has minted through the allow list mint
	mapping(address => uint256) public addressToAllowListMints;

	/// @notice Tracks addresses that can still claim a free mint
	mapping(address => uint256) public addressToFreeMintClaim;

	/// @notice Tracks the number of tokens an address can mint during allow list mint if not the same as allowListMints
	mapping(address => uint256) public addressToPaidMints;

	/// @notice The maximum number of tokens that can be minted per transaction
	uint256 public mintLimit;

	/// @notice The address of the vault
	address payable public vault;

	/// @notice The price of a mint
	uint256 public price;

	/*
	 * DO NOT ADD OR REMOVE VARIABLES ABOVE THIS LINE. INSTEAD, CREATE A NEW VERSION SECTION BELOW.
	 * MOVE THIS COMMENT BLOCK TO THE END OF THE LATEST VERSION SECTION PRE-DEPLOYMENT.
	 */

	function initialize(IBigBearSyndicate bbs_) public initializer {
		// Call parent initializers
		__AccessControl_init();
		__Pausable_init();
		__ReentrancyGuard_init();

		// Set defaults
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

		setSupplyLimit(5000);
		currentTokenId = 0;

		vault = payable(msg.sender);

		uint256 defaultStartTime = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

		setFreeMintStartTime(defaultStartTime);
		setAllowListStartTime(defaultStartTime);
		setPublicStartTime(defaultStartTime);

		allowListMints = 1;
		mintLimit = 20;
		price = 0.01337 ether;

		// Set constructor arguments
		setBigBearSyndicateAddress(bbs_);
	}

	/*
	 Timeline:
	 
	 freeMintSale    :|------------|
	 allowListSale   :			   |------------|
	 publicSale      :             				|------------|
	 */

	// ------------------------------
	// 		   Free Mint Sale
	// ------------------------------
	/**
	@notice Returns true if the free mint sale has started
	 */
	function isInFreeMintPhase() external view returns (bool) {
		return
			_hasStarted(freeMintStartTime) && !_hasStarted(allowListStartTime);
	}

	/**
	@notice Mint a free BigBearSyndicate
	*/
	function freeMint(uint256 numBears)
		external
		nonReentrant
		whenNotPaused
		inFreeMintPhase
		whenSupplyRemains(numBears)
		withinMintLimit(numBears)
	{
		uint256 mints = addressToFreeMintClaim[msg.sender];

		if (numBears > mints) {
			revert MintAllowanceExceeded(msg.sender, mints);
		}

		addressToFreeMintClaim[msg.sender] -= numBears;

		_mint(msg.sender, numBears);
	}

	function setFreeMintClaims(address user, uint256 mints)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		addressToFreeMintClaim[user] = mints;
	}

	/**
	 * @notice Sets the number of tokens an address can mint in a paid tier
	 * @param user address of the user
	 * @param mints uint256 of the number of BigBearSyndicate the user can mint
	 */
	function setPaidMints(address user, uint256 mints)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		addressToPaidMints[user] = mints;
	}

	// ------------------------------
	// 		   Allow List Sale
	// ------------------------------

	/**
	@notice Mint a BigBearSyndicate in the allow list phase (paid)
	@param numBears uint256 of the number of BigBearSyndicates to mint
	@param merkleProof bytes32[] of the merkle proof of the minting address
	*/
	function allowListMint(uint256 numBears, bytes32[] calldata merkleProof)
		external
		payable
		nonReentrant
		whenNotPaused
		inAllowListPhase
		onlyWhitelisted(msg.sender, merkleProof, allowListWhitelist)
		whenSupplyRemains(numBears)
		withinMintLimit(numBears)
	{
		uint256 paidMints = addressToPaidMints[msg.sender];
		if (paidMints > 0) {
			if (addressToAllowListMints[msg.sender] + numBears > paidMints) {
				revert MintAllowanceExceeded(msg.sender, paidMints);
			}
		} else {
			if (
				addressToAllowListMints[msg.sender] + numBears > allowListMints
			) {
				revert MintAllowanceExceeded(msg.sender, allowListMints);
			}
		}

		uint256 expectedValue = price * numBears;

		if (msg.value != expectedValue) {
			revert IncorrectEtherValue(expectedValue);
		}

		addressToAllowListMints[msg.sender] += numBears;

		_mint(msg.sender, numBears);
	}

	/**
    @notice Returns true it the user is included in the allow list whitelist
    @param user address of the user
    @param merkleProof uint256[] of the merkle proof of the user address
    */
	function isAllowListWhitelisted(
		address user,
		bytes32[] calldata merkleProof
	) external view returns (bool) {
		return allowListWhitelist.isWhitelisted(user, merkleProof);
	}

	/**
	@notice Returns true if the allow list sale has started
	 */
	function isInAllowListPhase() external view returns (bool) {
		return _hasStarted(allowListStartTime) && !_hasStarted(publicStartTime);
	}

	/**
	@notice Returns the root hash of the allow list Merkle tree
	 */
	function allowListMerkleRoot() external view returns (bytes32) {
		return allowListWhitelist.getRootHash();
	}

	/**
	 @notice Returns the number of allowlist mints remaining for the user
	 */
	function allowListMintsRemaining(address user)
		external
		view
		returns (uint256)
	{
		uint256 paidMints = addressToPaidMints[user];
		if (paidMints > 0) {
			return paidMints - addressToAllowListMints[user];
		}

		return allowListMints - addressToAllowListMints[user];
	}

	// ------------------------------
	// 			Public Sale
	// ------------------------------

	/**
	@notice Mint a BigBearSyndicate in the Public phase (paid)
	@param numBears uint256 of the number of BigBearSyndicates to mint
	*/
	function publicMint(uint256 numBears)
		external
		payable
		nonReentrant
		whenNotPaused
		inPublicPhase
		whenSupplyRemains(numBears)
		withinMintLimit(numBears)
	{
		uint256 expectedValue = price * numBears;

		if (msg.value != expectedValue) {
			revert IncorrectEtherValue(expectedValue);
		}

		_mint(msg.sender, numBears);
	}

	/**
	@notice Returns true if the public sale has started
	*/
	function isInPublicPhase() external view returns (bool) {
		return _hasStarted(publicStartTime);
	}

	// ------------------------------
	// 			  Minting
	// ------------------------------

	function _mint(address to, uint256 numBears) internal {
		for (uint256 i = 0; i < numBears; i++) {
			// Generate token id
			currentTokenId += 1;

			bbs.mint(to, currentTokenId);
		}
	}

	function availableSupply() external view returns (uint256) {
		return supplyLimit - currentTokenId;
	}

	// ------------------------------
	// 			  Pausing
	// ------------------------------

	function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
		_pause();
	}

	function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
		_unpause();
	}

	// ------------------------------
	// 			 Withdrawal
	// ------------------------------

	/**
	 @notice Withdraw funds to the vault
	 @param _amount uint256 the amount to withdraw
	 */
	function withdraw(uint256 _amount)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
		hasVault
	{
		if (address(this).balance < _amount) {
			revert InsufficientBalance(address(this).balance, _amount);
		}

		payable(vault).transfer(_amount);
	}

	/**
	 @notice Withdraw all funds to the vault
	 */
	function withdrawAll() external onlyRole(DEFAULT_ADMIN_ROLE) hasVault {
		if (address(this).balance < 1) {
			revert InsufficientBalance(address(this).balance, 1);
		}

		payable(vault).transfer(address(this).balance);
	}

	// ------------------------------
	// 			  Setters
	// ------------------------------

	/// @notice Sets the address of the BigBearSyndicate contract
	function setBigBearSyndicateAddress(IBigBearSyndicate bbs_)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		bbs = bbs_;
	}

	/// @notice Sets the number of available tokens
	function setSupplyLimit(uint256 supplyLimit_)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		supplyLimit = supplyLimit_;
	}

	/**
	@notice A convenient way to set phase times at once
	@param freeMintStartTime_ uint256 the free mint start time
	@param allowListStartTime_ uint256 the allow list start time
	@param publicStartTime_ uint256 the public sale start time
	*/
	function setPhaseTimes(
		uint256 freeMintStartTime_,
		uint256 allowListStartTime_,
		uint256 publicStartTime_
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		setFreeMintStartTime(freeMintStartTime_);
		setAllowListStartTime(allowListStartTime_);
		setPublicStartTime(publicStartTime_);
	}

	/**
	@notice Sets the allow list start time
	@param freeMintStartTime_ uint256 the allow list start time
	*/
	function setFreeMintStartTime(uint256 freeMintStartTime_)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		freeMintStartTime = freeMintStartTime_;
	}

	/**
	@notice Sets the allow list start time
	@param allowListStartTime_ uint256 the allow list start time
	*/
	function setAllowListStartTime(uint256 allowListStartTime_)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		allowListStartTime = allowListStartTime_;
	}

	/**
	@notice Sets the public start time
	@param publicStartTime_ uint256 the public sale start time
	*/
	function setPublicStartTime(uint256 publicStartTime_)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		publicStartTime = publicStartTime_;
	}

	/**
	@notice Sets the vault address
	@param vault_ address of the vault
	*/
	function setVaultAddress(address payable vault_)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		vault = vault_;
	}

	/**
	@notice Sets the price of a mint
	@param price_ uint256 the price of a mint
	*/
	function setPrice(uint256 price_) external onlyRole(DEFAULT_ADMIN_ROLE) {
		price = price_;
	}

	/**
	 * @notice Sets the number of BigBearSyndicates that can be minted in the allow list phase
	 * @param mints uint256 the number of BigBearSyndicates that can be minted in the allow list phase
	 */
	function setAllowListMints(uint256 mints)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		allowListMints = mints;
	}

	/**
	 * @notice Sets the number of BigBearSyndicates that can be minted in one transaction
	 * @param limit uint256 the number of BigBearSyndicates that can be minted in one transaction
	 */
	function setMintLimit(uint256 limit) external onlyRole(DEFAULT_ADMIN_ROLE) {
		mintLimit = limit;
	}

	/**
	@notice Sets the root hash of the allow list Merkle tree
	@param rootHash bytes32 the root hash of the allow list Merkle tree
	*/
	function setAllowListMerkleRoot(bytes32 rootHash)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		allowListWhitelist.setRootHash(rootHash);
	}

	// ------------------------------
	// 			  Modifiers
	// ------------------------------

	/**
	@dev Modifier to make a function callable only when there is enough bears left for sale
	
	Requirements:

	- Number of bears sold must be less than the maximum for sale
	*/
	modifier whenSupplyRemains(uint256 mintAmount) {
		if (currentTokenId + mintAmount > supplyLimit) {
			revert NotEnoughSupply();
		}
		_;
	}

	/**
    @dev Modifier to make a function callable only when in the allow list phase

    Requirements:

    - Current block timestamp must be greater than the allow list start time
    */
	modifier inFreeMintPhase() {
		if (!_hasStarted(freeMintStartTime)) {
			revert PhaseNotStarted(freeMintStartTime);
		}
		if (_hasStarted(allowListStartTime)) {
			revert PhaseOver(allowListStartTime);
		}
		_;
	}

	/**
    @dev Modifier to make a function callable only when in the allow list phase

    Requirements:

    - Current block timestamp must be greater than the allow list start time
    */
	modifier inAllowListPhase() {
		if (!_hasStarted(allowListStartTime)) {
			revert PhaseNotStarted(allowListStartTime);
		}
		if (_hasStarted(publicStartTime)) {
			revert PhaseOver(publicStartTime);
		}
		_;
	}

	/**
    @dev Modifier to make a function callable only when in the public sale phase

    Requirements:

    - Current block timestamp must be greater than the public sale start time
    */
	modifier inPublicPhase() {
		if (!_hasStarted(publicStartTime)) {
			revert PhaseNotStarted(publicStartTime);
		}
		_;
	}

	/**
    @dev Modifier to make a function callable only when the user is included in the allow list whitelist

    Requirements:

    - Merkle proof of user address must be valid
    */
	modifier onlyWhitelisted(
		address user,
		bytes32[] calldata merkleProof,
		Whitelists.MerkleProofWhitelist storage whitelist
	) {
		if (!whitelist.isWhitelisted(user, merkleProof)) {
			revert NotWhitelisted(user);
		}
		_;
	}

	/**
    @dev Modifier to make a function callable only when the vault address is valid

    Requirements:

    - The vault must be a non-zero address
    */
	modifier hasVault() {
		if (vault == address(0)) {
			revert InvalidAddress(vault);
		}
		_;
	}

	/**
    @dev Modifier to make a function callable only when the requested number of BigBearSyndicates is valid
    Requirements:

    - The requested number of BigBearSyndicates must be less than or equal to mint limit
    */
	modifier withinMintLimit(uint256 numBears) {
		if (numBears > mintLimit) {
			revert MintLimitExceeded(mintLimit);
		}
		_;
	}

	/**
	 @notice Returns true if the start time has passed
	 @param startTime uint256 of the start time
	 */
	function _hasStarted(uint256 startTime) internal view returns (bool) {
		return block.timestamp > startTime;
	}
}