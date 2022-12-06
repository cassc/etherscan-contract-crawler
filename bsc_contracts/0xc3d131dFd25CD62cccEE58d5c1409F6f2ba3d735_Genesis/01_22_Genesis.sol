// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import { IGenesis, IERC20Upgradeable } from "./interfaces/IGenesis.sol";
import { IERC2981, IERC165 } from "../node_modules/@openzeppelin/contracts/interfaces/IERC2981.sol";

import "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import { SafeERC20Upgradeable } from "../node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ECDSAUpgradeable } from "../node_modules/@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { Math } from "./libraries/Math.sol";


/**
* @notice affiliate enabled nft collection
* @author Phil Thomsen
*/
contract Genesis is ERC721Upgradeable, AccessControlUpgradeable, IGenesis, IERC2981 {
	using SafeERC20Upgradeable for IERC20Upgradeable;
	using ECDSAUpgradeable for bytes;
	using StringsUpgradeable for uint256;

	uint256 private constant BASIS_POINTS = 10_000;

	bytes32 public constant override METADATA_MANAGER_ROLE = keccak256("METADATA_MANAGER");
	bytes32 public constant override WHITELIST_SIGNER_ROLE = keccak256("WHITELIST_SIGNER");
	bytes32 public constant override MINTING_MANAGER_ROLE = keccak256("MINTING_MANAGER");
	bytes32 public constant override DEFAULT_APPROVED_ROLE = keccak256("DEFAULT_APPROVED");
	bytes32 public constant override STRIVE_CONTRACT_ROLE = keccak256("STRIVE_CONTRACT");

	uint256 public constant MASTER_TOKEN_ZERO = 0;
	uint256 public constant override REFERRAL_LAYERS = 3;
	uint256 public constant override VALIDITY_LENGTH = 4 weeks;
	uint256 public constant override EXPLOTER_BASIS_POINTS = 100;

	IERC20Upgradeable public immutable override USDC;
	IERC20Upgradeable public immutable override USDT;
	IERC20Upgradeable public immutable override BUSD;
	

	uint24 internal _maxSupply;
	uint24 internal _totalSupply;
	bool internal _mintOpen;
	bool internal _transfersPaused;
	address internal royaltyReceiver;
	uint16 internal  royaltyBasisPoints;
	bool public metadataFrozen;

	VolumeProps public volumeProps;

	string internal _unrevealedMetadata;
	string internal _revealedMetadata;
	uint256 internal _revealedUntil;

	mapping(uint256 => Token) internal _token;
	mapping(address => Customer) internal _customers;

	constructor(IERC20Upgradeable _usdc, IERC20Upgradeable _usdt, IERC20Upgradeable _busd)  { 
		USDC = _usdc;
		USDT = _usdt;
		BUSD = _busd;
		_disableInitializers(); 
	}

	function initialize(
		address defaultAdmin,
		address mintingManager,
		address metadataManager,
		address whitelistSignerWallet, 
		VolumeProps calldata props
	)
		external override initializer
	{
		__ERC721_init("STRIVE FOR GREATNESS", "STRV");
		__AccessControl_init();

		_mint(defaultAdmin, MASTER_TOKEN_ZERO);

		_totalSupply = 1; 
		setMaxSupply(101);

		_grantRole(MINTING_MANAGER_ROLE, mintingManager);
		_grantRole(METADATA_MANAGER_ROLE, metadataManager);
		_grantRole(WHITELIST_SIGNER_ROLE, whitelistSignerWallet);

		setVolumeProps(props);

		emit Minted(defaultAdmin, 0, 1, 0, 0);
	}

  // EXTERNAL USER FUNCTIONS
	function mint(
		address currency,
		uint256 amount,
		address recipient,
		Referral calldata referral
	)
		external override 
	{
		_registerCustomer(recipient, referral);

		if(amount == 0) revert ZeroParameter("uint256 amount");

        uint256 toBeMintedNext   = _totalSupply;
        uint256 totalSupplyAfter = toBeMintedNext + amount;
		uint256 totalFeeInUSDC = totalMintingFee(toBeMintedNext, amount);

		bool isValidReferral = _verifyReferralSignature(recipient, referral);
		address[REFERRAL_LAYERS] memory referrers = _getReferrers(referral.tokenId);

		// check if mint open and supply restrictions
        require(_mintAllowed(totalSupplyAfter));

		// check referral validity
		if(! isValidReferral) revert InvalidReferral(msg.sender, referral.tokenId, referral.sig);

		emit Minted(recipient, toBeMintedNext, amount, totalFeeInUSDC, referral.tokenId);

        // now mint `amount` tokens
		_mintRangeWithReferrerToken(
			recipient,
			toBeMintedNext, 
			totalSupplyAfter,
			referral.tokenId,
			totalFeeInUSDC / amount / 1 ether
		);

		// ensure payment is made by the caller and pay out to the referrer
        _processPayment(msg.sender, IERC20Upgradeable(currency), totalFeeInUSDC, referrers);
    }

	function renew(uint256[] calldata tokenIds, IERC20Upgradeable currency) external override {
		_enforceCurrency(currency);
		uint256 length = tokenIds.length;
		for(uint256 i = 0; i < length; i++) {
			uint256 validUntil = _renew(_getTokenInStorage(tokenIds[i]));
			emit TokenRenewed(tokenIds[i], validUntil);
		}
		currency.safeTransferFrom(msg.sender, address(this), length * 1 ether *  volumeProps.renewalFeeInDollar);
	}

	function registerAsCustomer(Referral calldata referral) external {
		_registerCustomer(msg.sender, referral);
	}

	function placeForVolumeBonus(uint256 parentTokenId, uint256 childTokenId, bool rightSide) external {		
		Token storage child = _getTokenInStorage(childTokenId);

		if(
			msg.sender != ownerOf(parentTokenId) ||
			child.referrerToken != parentTokenId ||
			child.up != MASTER_TOKEN_ZERO  ||
			parentTokenId == MASTER_TOKEN_ZERO
		) revert NotAuthorized(); 

		uint256 lastTokenInChain = _getEndOfVolumeBonusChain(parentTokenId, rightSide);

		if(rightSide)  _getTokenInStorage(lastTokenInChain).downR = uint24(childTokenId);
		else 			_getTokenInStorage(lastTokenInChain).downL = uint24(childTokenId);

		child.up = uint24(lastTokenInChain);

		emit Placed(childTokenId, lastTokenInChain, rightSide);
	}

	/// @param rightSideBase true means less right volume will be used, false means less left volume will be used
	function claimVolumeBonus(
		uint256 tokenId,
		uint256 cycles,
		bool rightSideBase,
		IERC20Upgradeable currency
	) external {		
		Token storage token = _getTokenInStorage(tokenId);
		VolumeProps memory props = volumeProps;

		// checks
		_enforceCurrency(currency);
		if(cycles == 0) revert ZeroParameter("cycles");
		if(! props.enabled) revert VolumeBonusDisabled();
		if(token.nextActivityCheck < block.timestamp) revert TokenNotActive();

		// cache for efficiency
		address tokenOwner = ownerOf(tokenId);
		uint256 earnedBeforeClaim = token.bonusPaidByVolumeEpoche[props.epoche];

		// calculate volume based on cycles and volumeProps
		(uint256 volumeLeftToUse, uint256 volumeRightToUse) = rightSideBase 
			? (
				cycles * props.volumeBaseAmount * props.otherTeamMultiplier, 
				cycles * props.volumeBaseAmount
			) : (
				cycles * props.volumeBaseAmount, 
				cycles * props.volumeBaseAmount * props.otherTeamMultiplier
			);

		(uint256 availableLeft, uint256 availableRight) = _getAvailableVolumesForToken(token);

		if(availableLeft < volumeLeftToUse)   revert InsufficientVolume(availableLeft, volumeLeftToUse);
		if(availableRight < volumeRightToUse) revert InsufficientVolume(availableRight, volumeRightToUse);

		uint256 earned = _calculateVolumeBonus(volumeLeftToUse, volumeRightToUse, props.basisPointsPayout);

		// check if token already earned too much this epoche
		if(earnedBeforeClaim + earned > props.maximumPerEpocheInDollar) revert EarnedMoreThanMaximumPerEpoche();

		token.usedLeft  += uint32(volumeLeftToUse);
		token.usedRight += uint32(volumeRightToUse);
		token.bonusPaidByVolumeEpoche[props.epoche] = earnedBeforeClaim + earned;

		emit VolumeBonusClaimed(tokenOwner, tokenId, earned, cycles, rightSideBase);

		currency.safeTransfer(tokenOwner, 1 ether * earned);
	}

	function updateVolumesForToken(uint256[] calldata tokenIds) external {
		for(uint256 i = 0; i < tokenIds.length; i = Math.unsafeInc(i)) {
			_updateVolumesForToken(_token[tokenIds[i]]);
		}

		emit VolumesUpdated(tokenIds);
	}

	function exploitActivity(uint256 tokenId, IERC20Upgradeable currency) external {
		_enforceCurrency(currency);

		Token storage token = _getTokenInStorage(tokenId);
		if(token.nextActivityCheck >= block.timestamp) revert TokenStillActive(token.nextActivityCheck);

		(uint256 availableLeft, uint256 availableRight) = _getAvailableVolumesForToken(token);

		_zeroOutVolumes(token);

		uint256 exploiterBonus = _calculateVolumeBonus(
			availableLeft, 
			availableRight, 
			volumeProps.basisPointsPayout
		) * EXPLOTER_BASIS_POINTS / BASIS_POINTS;

		emit Exploited(msg.sender, tokenId, exploiterBonus);

		currency.safeTransfer(
			msg.sender,
			1 ether * exploiterBonus
		);
	}

  // EXTERNAL ADMIN FUNCTIONS
	function allocate(
		address recipient, 
		uint256 amount,
		uint256 referrerToken
	)
		external override onlyRole(DEFAULT_ADMIN_ROLE) 
	{
		uint256 toBeMintedNext   = _totalSupply;
        uint256 totalSupplyAfter = toBeMintedNext + amount;
		if(totalSupplyAfter > _maxSupply) revert SupplyCapExceeded(totalSupplyAfter, _maxSupply);

		emit Minted(recipient, toBeMintedNext, amount, 0, referrerToken);

		_mintRangeWithReferrerToken(
			recipient, 
			toBeMintedNext, 
			totalSupplyAfter, 
			referrerToken,
			0
		);

		_registerCustomer(recipient, Referral(MASTER_TOKEN_ZERO, ""));
	}

	function retrieve(
		IERC20Upgradeable currency,
		address recipient,
		uint256 amount
	)
		external override onlyRole(DEFAULT_ADMIN_ROLE) 
	{
		if(address(currency) == address(0)) {
			amount = Math.min(amount, address(this).balance);
			(bool suc, ) = recipient.call{ value: amount }("");
			if(!suc) revert();
		} else {
			amount = Math.min(amount, currency.balanceOf(address(this)));
			currency.safeTransfer(recipient, amount);
		}
	}

	function setTransfersPaused(
		bool transfersPaused_
	) 
		external override onlyRole(DEFAULT_ADMIN_ROLE) 
	{
		if(_transfersPaused == transfersPaused_) revert ValueWasAlreadySet("transfersPaused_", abi.encodePacked(transfersPaused_));
		_transfersPaused = transfersPaused_;
		emit TransferStatusChanged(transfersPaused_);
	}

	function setMaxSupply(
		uint24 maxSupply_
	) 
		public override onlyRole(DEFAULT_ADMIN_ROLE)
	{
		if(maxSupply_ < _totalSupply) revert SupplyCapExceeded(_totalSupply, maxSupply_);
		_maxSupply = maxSupply_;

		emit NewMaxSupply(maxSupply_);
	}

	function setMetadata(
		string calldata unrevealedMetadata, 
		string calldata revealedMetadata
	)
		external override onlyRole(METADATA_MANAGER_ROLE) 
	{
		require(!metadataFrozen, "metadata frozen");
		_unrevealedMetadata = unrevealedMetadata;
		_revealedMetadata = revealedMetadata;
		emit MetadataChanged(unrevealedMetadata, revealedMetadata, _revealedUntil);
	}

	function revealMetadata(
		uint256 revealedUntil
	) 
		external override onlyRole(METADATA_MANAGER_ROLE) 
	{
		require(!metadataFrozen, "metadata frozen");
		_revealedUntil = revealedUntil;
		emit MetadataChanged(_unrevealedMetadata, _revealedMetadata, revealedUntil);
	}

	function freezeMetadata(
		bytes4 magicValue
	) 
		external override onlyRole(METADATA_MANAGER_ROLE) 
	{
		require(magicValue == this.freezeMetadata.selector, "must provide magic value");
		metadataFrozen = true;
		emit MetadataFrozen();
	}

	function setMintingStatus(
		bool mintingEnabled_
	)
		external override onlyRole(MINTING_MANAGER_ROLE) 
	{
		if(_mintOpen == mintingEnabled_) revert ValueWasAlreadySet("mintingEnabled_", abi.encodePacked(mintingEnabled_));
		_mintOpen = mintingEnabled_;
		emit MintingStatusChanged(mintingEnabled_);
	}

	// enable claiming volume bonus and record timestamp
	function setVolumeBonusStatus(
		bool volumeBonusEnabled_
	)
		external
		override
		onlyRole(DEFAULT_ADMIN_ROLE) 
	{
		if(
			volumeProps.enabled == volumeBonusEnabled_
		) revert ValueWasAlreadySet("volumeBonusEnabled", abi.encodePacked(volumeBonusEnabled_));

		volumeProps.enabled = volumeBonusEnabled_;
		volumeProps.epoche++;
		emit VolumeBonusStatusChanged(volumeBonusEnabled_);
	}

	function setVolumeProps(VolumeProps memory newProps) public onlyRole(DEFAULT_ADMIN_ROLE) {
		require((!volumeProps.enabled) && (!newProps.enabled), "cannot change on the fly");
		require(newProps.basisPointsPayout < BASIS_POINTS, "basis points payout too high");
		require(newProps.volumeBaseAmount != 0, "base volume cannot be 0");
		require(newProps.otherTeamMultiplier != 0, "otherTeamMultiplier cannot be 0");

		newProps.epoche = volumeProps.epoche;

		volumeProps = newProps;

		emit NewVolumeProps(newProps);
	}

	function setRoyaltyInfo(address recipient, uint256 feeBasisPoints) external override onlyRole(DEFAULT_ADMIN_ROLE) {
		if(recipient == address(0)) revert ZeroParameter("recipient");

		royaltyBasisPoints = uint16(feeBasisPoints);
		royaltyReceiver = recipient;

		emit NewRoyaltyInfo(recipient, feeBasisPoints);
	}

	function registerPurchase(
		address customerAddress,
		IERC20Upgradeable currency,
		address seller,
		uint256 sellerCutBasisPoints,
		uint256 feeInUSDC
	) external onlyRole(STRIVE_CONTRACT_ROLE) {
		Customer storage cust = _customers[customerAddress];

		if(! cust.isRegistered) _registerCustomer(customerAddress, Referral(MASTER_TOKEN_ZERO, ""));

		// sanity check to never overpay the seller
		if(sellerCutBasisPoints > BASIS_POINTS) revert("SELLER SHARE OUT OF BOUND");

		uint256 referrerToken = cust.referrerToken;

		// register the volume for volume bonuses if its not default referrer
		if(referrerToken != MASTER_TOKEN_ZERO) {
			_getTokenInStorage(referrerToken).volumeGenerated += uint32(feeInUSDC / 1 ether);
		}

		emit VolumeGenerated(customerAddress, seller, sellerCutBasisPoints, feeInUSDC);

		// pull payment and pay out matching bonus, currency check is done inside
		_processPayment(customerAddress, currency, feeInUSDC, _getReferrers(referrerToken));

		if(seller != address(0) && sellerCutBasisPoints != 0) {
			currency.safeTransfer(
				seller, 
				feeInUSDC * sellerCutBasisPoints / BASIS_POINTS
			);
		}
	}


  // INTERNAL (Non view)

	function _mintRangeWithReferrerToken(
		address recipient,
		uint256 toBeMintedNext, 
		uint256 totalSupplyAfter,
		uint256 referrerToken,
		uint256 volumePerTokenInUSD
	) internal {
		while(toBeMintedNext < totalSupplyAfter) {
			_mint(recipient, toBeMintedNext);
			Token storage token = _token[toBeMintedNext];
			_renew(token);
			if(referrerToken != MASTER_TOKEN_ZERO) {
			    token.referrerToken = uint24(referrerToken);
				token.volumeGenerated = uint32(volumePerTokenInUSD);
			}
			toBeMintedNext = Math.unsafeInc(toBeMintedNext);
		}
		_totalSupply = uint24(totalSupplyAfter);
	}

	function _processPayment(
		address from,
		IERC20Upgradeable currency,
		uint256 feeInUSDC,
		address[REFERRAL_LAYERS] memory referrers
	)
		internal 
	{
		_enforceCurrency(currency);

		currency.safeTransferFrom(from, address(this), feeInUSDC);

		for(uint256 i = 0; i < REFERRAL_LAYERS; i++) {
			if(referrers[i] == address(0)) break;
			currency.safeTransfer(referrers[i], _calculateReferralAmount(feeInUSDC, i));
		}
    }

	function _renew(Token storage token) internal returns(uint256 nextCheck) {
		nextCheck = VALIDITY_LENGTH + Math.max(block.timestamp, token.nextActivityCheck);

		token.nextActivityCheck = uint64(nextCheck);
	}

	function _registerCustomer(
		address customerAddress, 
		Referral memory referral
	) internal {
		Customer storage cust = _customers[customerAddress];

		if(cust.isRegistered) return;

		cust.isRegistered = true;
		emit CustomerRegistered(customerAddress, referral.tokenId);

		if(referral.tokenId == MASTER_TOKEN_ZERO) {
			return;
		}

		if(_verifyReferralSignature(customerAddress, referral)) {
			cust.referrerToken = uint24(referral.tokenId);
			return;
		}

		revert InvalidReferral(customerAddress, referral.tokenId, referral.sig);
	}

	function _updateVolumesForToken(Token storage token) internal {
		(uint256 downL, uint256 downR) = (token.downL, token.downR);

		if(downL != MASTER_TOKEN_ZERO) {
			Token storage leftC = _token[downL];
			token.totalVolLeft = leftC.volumeGenerated + leftC.totalVolLeft + leftC.totalVolRight;
		}
		if(downR != MASTER_TOKEN_ZERO) {
			Token storage rightC = _token[token.downR];
			token.totalVolRight = rightC.volumeGenerated + rightC.totalVolLeft + rightC.totalVolRight;
		}
	}

	function _zeroOutVolumes(Token storage token) internal {
		token.usedLeft = token.totalVolLeft;
		token.usedRight = token.totalVolRight;
	}

	function _beforeTokenTransfer(
		address from, 
		address to, 
		uint256 tokenId
	)
		internal virtual override 
	{
		super._beforeTokenTransfer(from, to, tokenId);
		if(
			from != address(0) && 
			_transfersPaused && 
			tokenId != MASTER_TOKEN_ZERO
		) revert TransfersPaused();

		if(
			tokenId == MASTER_TOKEN_ZERO && 
			from != address(0)
		) require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "invalid master token transfer");
	}


  // INTERNAL VIEW
	function _mintAllowed(
        uint256 totalSupplyAfter
    )
		internal view returns(bool) 
	{
		/// minting enabled from admin? 
		/// supply cap respected?
		if(!_mintOpen)                          revert MintNotOpen();
        if(totalSupplyAfter > _maxSupply)      revert SupplyCapExceeded(totalSupplyAfter, _maxSupply);

		return true;
    }

	/// @return referrers might satisfy referrers[i] == address(0) for some i
	function _getReferrers(uint256 tokenId) internal view returns(address[REFERRAL_LAYERS] memory referrers) {
		for(uint256 i = 0; i < REFERRAL_LAYERS; i++) {
			if(tokenId == MASTER_TOKEN_ZERO) break;

			referrers[i] = ownerOf(tokenId);
			tokenId = _getTokenInStorage(tokenId).referrerToken;
		}
	}

	function _verifyReferralSignature(
		address invitee,
        Referral memory referral
	)
		internal view returns(bool isValid) 
	{
        return hasRole(
			WHITELIST_SIGNER_ROLE,
			ECDSAUpgradeable.recover(
				_getWhitelistMsgHash(
					invitee,
					referral.tokenId
				),
				referral.sig
			)
		);
    }

	function _getEndOfVolumeBonusChain(uint256 tokenId, bool rightSide) internal view returns(uint256 endToken) {
		uint256 temp;
		if(rightSide) {
			while(true) {
				temp = _getTokenInStorage(tokenId).downR;
				if(temp == MASTER_TOKEN_ZERO) return tokenId;
				tokenId = temp;
			}
		} else {
			while(true) {
				temp = _getTokenInStorage(tokenId).downL;
				if(temp == MASTER_TOKEN_ZERO) return tokenId;
				tokenId = temp;
			}
		}
	}

	function _getAvailableVolumesForToken(Token storage token) internal view returns(
		uint256 volumeLeft,
		uint256 volumeRight
	) {
		return (token.totalVolLeft - token.usedLeft, token.totalVolRight - token.usedRight);
	}

	function _isDefaultApproved(address operator) internal view returns(bool) {
		return hasRole(DEFAULT_APPROVED_ROLE, operator);
	}

	function _getTokenInStorage(uint256 tokenId) internal view returns(Token storage token) {
		if(! _exists(tokenId)) revert TokenDoesntExist(tokenId);
		return _token[tokenId];
	}

	function _enforceCurrency(IERC20Upgradeable currency) internal view {
		if(currency != USDC && currency != USDT && currency != BUSD)
			revert InvalidCurrency(address(USDT), address(USDC), address(BUSD));
	}


  // PURE 
	function _getWhitelistMsgHash(address invitee, uint256 referrerToken) internal pure returns(bytes32) {
		return ECDSAUpgradeable.toEthSignedMessageHash(abi.encodePacked(invitee, referrerToken));
	}

	function _calculateReferralAmount(uint256 amountSpent, uint256 layer) internal pure returns(uint256) {
		return amountSpent / 10 / (2 ** layer);
	}

	function _calculateVolumeBonus(uint256 l, uint256 r, uint256 payoutBasisPoints) internal pure returns(uint256 earned) {
		return (l + r) * payoutBasisPoints / BASIS_POINTS;
	}
	
	function totalMintingFee(uint256 firstTokenId, uint256 amount) public pure override returns(uint256 totalFeeInUSDC) {
		for(; amount > 0;) {
			amount--;
			totalFeeInUSDC += mintingFee(firstTokenId + amount);
		}
	}

    function mintingFee(uint256 tokenId) public pure override returns(uint256 feeInUSDC) {
		return 1085736 * uint256(Math.lnWad(int256(tokenId**4 * 1 ether))) / 100000 + 300 ether;
    }

  // OVERRIDES 

	function royaltyInfo(uint256, uint256 amount) external view override returns(address, uint256) {
		return (royaltyReceiver, royaltyBasisPoints * amount / BASIS_POINTS);
	}

	function isApprovedForAll(
		address owner, 
		address operator
	) 
		public view virtual override
		returns (bool)
	{
        return _isDefaultApproved(operator)  || super.isApprovedForAll(owner, operator);
    }

	/// @dev the owner of the MASTER_TOKEN_ZERO is default admin
	function hasRole(bytes32 role, address account) 
		public 
		view 
		override 
		returns (bool) 
	{
        return  super.hasRole(role, account) || 
				(
				   role == DEFAULT_ADMIN_ROLE && account == ownerOf(MASTER_TOKEN_ZERO)
				);
    }

  // EXTERNAL VIEW
   // Token and Customer Queries
    function getTokenInfo(uint256 tokenId) 
        external 
		view 
		override
        returns(
            address _owner, 
            string memory _tokenURI,
            uint256 _referrerTokenId
        )
	{
		Token storage token = _getTokenInStorage(tokenId);

		_owner = ownerOf(tokenId);
		_tokenURI = tokenURI(tokenId);
		_referrerTokenId = token.referrerToken;
	}

	/// @return route does NOT include `tokenId` itself in position 0, unless `tokenId` == 0
	function getReferralRoute(uint256 tokenId, uint256 length) external view returns(uint256[] memory route) {
		route = new uint256[](length);

		for(uint256 i = 0; i < length; i++) {
			tokenId = _getTokenInStorage(tokenId).referrerToken;
			if(tokenId == MASTER_TOKEN_ZERO) break;
			route[i] = tokenId;
		}

		return route;
	}

	function getVolumeInfoForToken(uint256 tokenId) external view returns(
		uint24 up,
		uint24 downLeft,
		uint24 downRight,
		uint32 totalVolLeft,
		uint32 totalVolRight,
		uint32 volumeGenerated,
		uint64 nextActivityCheck,
		uint32 usedLeft,
		uint32 usedRight,
		uint256 earnedThisEpoche
	) {
		Token storage token = _getTokenInStorage(tokenId);
		return (
			token.up,
			token.downL,
			token.downR,
			token.totalVolLeft,
			token.totalVolRight,
			token.volumeGenerated,
			token.nextActivityCheck,
			token.usedLeft, 
			token.usedRight,
			token.bonusPaidByVolumeEpoche[volumeProps.epoche]
		);
	}

	function getAvailableVolumesForToken(uint256 tokenId) external view returns(uint256 leftVolume, uint256 rightVolume) {
		return _getAvailableVolumesForToken(
			_getTokenInStorage(tokenId)
		);
	}

	function getCustomer(address customerAddress) external view returns(Customer memory) {
		return _customers[customerAddress];
	}

    function tokenURI(uint256 tokenId)
		public view override returns (string memory) 
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = tokenId < _revealedUntil ? _revealedMetadata : _unrevealedMetadata;

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

   // other contract state queries:
	function transfersPaused() external view override returns(bool) {
		return _transfersPaused;
	}

	function mintingEnabled() external view override returns(bool) {
		return _mintOpen;
	}

	function maxSupply() external view override returns(uint256) {
		return _maxSupply;
	}

	function totalSupply() external view override returns(uint256) {
		return _totalSupply;
	}

	function verifyReferralSignature(
		address invitee,
		Referral calldata referral
	) external view override returns(bool) {
		return _verifyReferralSignature(invitee, referral);
	}

	function supportsInterface(bytes4 interfaceId) 
		public view virtual 
		override(ERC721Upgradeable, AccessControlUpgradeable, IERC165) 
		returns (bool)
	{
        	return  interfaceId == type(AccessControlUpgradeable).interfaceId || 
					interfaceId == type(IAccessControlUpgradeable).interfaceId ||
			        interfaceId == type(IERC721Upgradeable).interfaceId ||
            		interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
					interfaceId == type(IERC165Upgradeable).interfaceId ||
            		super.supportsInterface(interfaceId);
    }
}