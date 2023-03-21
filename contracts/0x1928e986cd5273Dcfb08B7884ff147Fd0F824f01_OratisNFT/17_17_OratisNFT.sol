// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC4907A.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @author Based off of HeyMint Launchpad https://launchpad.heymint.xyz and modified by null-prophet
 * @notice This contract handles minting Oratis tokens.
 */
contract OratisNFT is ERC721A, ERC721AQueryable, ERC4907A, Ownable, ReentrancyGuard {
	using SafeERC20 for IERC20;
	using ECDSA for bytes32;
	// Recover the messages coming in with this signer address
	address private signerAddress;
	// Where we payout to
	address public payoutAddress;
	// The payment token we are accepting for NFT sales
	IERC20 public paymentToken;

	bool public isPublicSaleActive;

	// Permanently freezes metadata so it can never be changed
	bool public metadataFrozen;
	// If true, payout addresses and basis points are permanently frozen and can never be updated
	bool public payoutAddressesFrozen;

	string public baseTokenURI = "https://metadata.oratis.nft/pre-reveal/";
	string public contractURI = "https://metadata.oratis.nft/pre-reveal/contract";

	// Maximum supply of tokens that can be minted
	uint256 public MAX_SUPPLY = 1000;

	// USD has 6 decimals so $1 = 1030000 so $103 = 103_000000
	uint256 public usdcPublicPrice = 103_000000;

	// The respective share of funds to be sent to each address in payoutAddresses in basis points
	uint256 public constant payoutBasisPoints = 10000;

	event TokensMinted(address buyer, uint256 tokenQty, uint256 paidAmount);

	constructor(
		address _payoutAddress,
		address _signer,
		address payable _paymentTokenAddress
	) ERC721A("Oratis", "ORTS") {
		payoutAddress = _payoutAddress;
		signerAddress = _signer;
		paymentToken = IERC20(_paymentTokenAddress);
	}

	/**
	 * @notice we don't want this to accept ETH.
	 */
	receive() external payable {
		revert("CANNOT_ACCEPT_ETHER");
	}

	modifier originalUser() {
		require(tx.origin == msg.sender, "CANNOT_CALL_FROM_CONTRACT");
		_;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseTokenURI;
	}

	/**
	 * @dev Overrides the default ERC721A _startTokenId() so tokens begin at 1 instead of 0
	 */
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	/**
	 * @notice Wraps and exposes publicly _numberMinted() from ERC721A
	 */
	function numberMinted(address _owner) public view returns (uint256) {
		return _numberMinted(_owner);
	}

	/**
	 * @notice Update the base token URI
	 */
	function setBaseURI(string calldata _newBaseURI) external onlyOwner {
		require(!metadataFrozen, "METADATA_HAS_BEEN_FROZEN");
		baseTokenURI = _newBaseURI;
	}

	/**
	 * @notice allow you to set new contractUri
	 */
	function setContractURI(string memory _newContractUri) external onlyOwner {
		require(!metadataFrozen, "METADATA_HAS_BEEN_FROZEN");
		contractURI = _newContractUri;
	}

	/**
	 * @notice Reduce the max supply of tokens
	 * @param _newMaxSupply The new maximum supply of tokens available to mint
	 */
	function reduceMaxSupply(uint256 _newMaxSupply) external onlyOwner {
		require(_newMaxSupply < MAX_SUPPLY, "NEW_MAX_SUPPLY_TOO_HIGH");
		require(_newMaxSupply >= totalSupply(), "SUPPLY_LOWER_THAN_MINTED_TOKENS");
		MAX_SUPPLY = _newMaxSupply;
	}

	/**
	 * @notice Freeze metadata so it can never be changed again
	 */
	function freezeMetadata() external onlyOwner {
		require(!metadataFrozen, "METADATA_HAS_ALREADY_BEEN_FROZEN");
		metadataFrozen = true;
	}

	// https://chiru-labs.github.io/ERC721A/#/migration?id=supportsinterface
	function supportsInterface(
		bytes4 interfaceId
	) public view virtual override(ERC721A, IERC721A, ERC4907A) returns (bool) {
		// Supports the following interfaceIds:
		// - IERC165: 0x01ffc9a7
		// - IERC721: 0x80ac58cd
		// - IERC721Metadata: 0x5b5e139f
		// - IERC2981: 0x2a55205a
		// - IERC4907: 0xad092b5c
		return ERC721A.supportsInterface(interfaceId) || ERC4907A.supportsInterface(interfaceId);
	}

	/**
	 * @notice To be updated by contract owner to allow public sale minting
	 */
	function setPublicSaleState(bool _saleActiveState) external onlyOwner {
		require(isPublicSaleActive != _saleActiveState, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
		isPublicSaleActive = _saleActiveState;
	}

	/**
	 * @notice Update the public mint price in usdc. 6 decimal places
	 * @param _usdcPublicPrice the price per NFT in USDC. Remember 6 decimal places.
	 */
	function setUsdcPublicPrice(uint256 _usdcPublicPrice) external onlyOwner {
		usdcPublicPrice = _usdcPublicPrice;
	}

	/**
	 * @dev hash our message elements and return the hashed message.
	 */
	function _hashTransaction(address sender, string memory nonce) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked(sender, nonce)).toEthSignedMessageHash();
	}

	/**
	 *  @notice easy check to see if caller is allowed to mint
	 */
	function isValidSignature(address addr, bytes calldata _signature) public view returns (bool) {
		address hashSigner = _hashTransaction(addr, "kyc_valid").recover(_signature);
		return hashSigner == signerAddress;
	}

	/**
	 * @notice Allow for public minting of tokens. You will need to have the right amount of tokens allowance given
	 * to the contract prior to calling. Assumes the caller is going to pay for the transaction.
	 */
	function mint(address recipient, bytes calldata signature, uint256 numTokens) external nonReentrant originalUser {
		require(isPublicSaleActive, "PUBLIC_SALE_IS_NOT_ACTIVE");
		// so this is what we sign on the backside to check signature is correct.
		require(isValidSignature(recipient, signature), "HASH_FAIL");
		require(totalSupply() + numTokens <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED");

		uint256 priceInWei = usdcPublicPrice * numTokens;
		require(paymentToken.allowance(msg.sender, address(this)) >= priceInWei, "PAYMENT_NOT_APPROVED");
		paymentToken.safeTransferFrom(msg.sender, address(this), priceInWei);

		_safeMint(recipient, numTokens);

		if (totalSupply() >= MAX_SUPPLY) {
			isPublicSaleActive = false;
		}
		emit TokensMinted(recipient, numTokens, priceInWei);
	}

	/**
	 * @notice Freeze payout address so it can never be changed again
	 */
	function freezePayoutAddresses() external onlyOwner {
		require(!payoutAddressesFrozen, "PAYOUT_ADDRESSES_ALREADY_FROZEN");
		payoutAddressesFrozen = true;
	}

	/**
	 * @notice Update payout address
	 */
	function updatePayoutAddress(address _payoutAddress) external onlyOwner {
		require(!payoutAddressesFrozen, "PAYOUT_ADDRESSES_FROZEN");
		payoutAddress = _payoutAddress;
	}

	/**
	 * @notice Update payout token
	 */
	function updatePaymentToken(IERC20 _payoutToken) external onlyOwner {
		require(!payoutAddressesFrozen, "PAYOUT_ADDRESSES_FROZEN");
		paymentToken = _payoutToken;
	}

	/**
	 * @notice Update signing address
	 */
	function updateSigningAddress(address _signerAddress) external onlyOwner {
		signerAddress = _signerAddress;
	}

	/**
	 * @notice Withdraws all ETH funds held within contract
	 */
	function withdraw() external nonReentrant onlyOwner {
		require(address(this).balance > 0, "CONTRACT_HAS_NO_BALANCE");
		uint256 balance = address(this).balance;
		(bool success, ) = payoutAddress.call{value: balance}("");
		require(success, "Transfer failed.");
	}

	/**
	 *  @notice Withdraw a specific token from the account. In case something else gets sent.
	 *  this will also head to the payoutAddress
	 */
	function withdrawTokens(IERC20 token) external nonReentrant onlyOwner {
		token.safeTransfer(payoutAddress, token.balanceOf(address(this)));
	}

	/**
	 * @notice Withdraws all PaymentToken funds held within contract. Convenience.
	 */
	function withdrawPaymentToken() external nonReentrant onlyOwner {
		paymentToken.transfer(payoutAddress, paymentToken.balanceOf(address(this)));
	}

	function owner() public view virtual override(Ownable) returns (address) {
		return Ownable.owner();
	}

	function _beforeTokenTransfers(address from, address to, uint256, uint256) internal virtual override {
		if (from == address(0) || to == address(0)) {
			// this is a MINT or BURN; allow
		} else {
			require(!isPublicSaleActive, "TRANSFER_NOT_ALLOWED_WHILE_SALE_INCOMPLETE");
		}
	}
}