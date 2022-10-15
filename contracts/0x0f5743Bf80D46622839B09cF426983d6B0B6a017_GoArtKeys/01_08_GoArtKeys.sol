// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @author GoArt Metaverse Blockchain Team
 * @title GoArtKeys
 * @notice Free mint GoArtKeys.
 */
contract GoArtKeys is ERC721A, Pausable, Ownable, ReentrancyGuard {
	using Strings for uint256;

	/// Sale phases are defined here.
	enum SalePhase {
		Phase01,
		Phase02,
		Phase03,
		Phase04
	}

	/// There can be only 4 types of coupons as defined here.
	enum CouponType {
		Og,
		Whitelist,
		Public,
		Custom
	}

	/// max supply for this collection
	uint64 public constant maxSupply = 5555;

	/// base token uri
	string private baseURI = "https://goartlive.blob.core.windows.net/free-mint/unrevealed/data/";

	/// admin signer address for mints
	address private adminSigner;

	/// airdrop
	bool airdrop;

	/// Listing all admins
	address[] public admins;

	/// Modifier for easier checking if user is admin
	mapping(address => bool) public isAdmin;

	/// store used signatures to avoid them from being reused
	mapping(bytes => bool) private usedSignatures;

	/// event for EVM logging
	event AdminAdded(address adminAddress);
	event AdminRemoved(address adminAddress);
	event NewURI(string newURI, address updatedBy);
	event PhaseUpdated(SalePhase phase, address updatedBy);
	event AdminSignerUpdated(address adminSigner, address updatedBy);
	event AirdropPerformed(address to, uint256 amount);

	/// Start from Phase01
	SalePhase public phase = SalePhase.Phase01;

	// Modifier restricting access to only admin
	modifier onlyAdmin() {
		require(isAdmin[msg.sender], "Only admin can call.");
		_;
	}

	/**
	 * @notice constructor
	 *
	 * @param _adminSigner admin signer address for mint
	 *
	 */
	constructor(address _adminSigner) ERC721A("GoArtKeys", "GAK") {
		admins.push(msg.sender);
		isAdmin[msg.sender] = true;
		adminSigner = _adminSigner;
		_pause();
	}

	/**
	 * @dev register a new admin with the given wallet address
	 *
	 * @param _adminAddress admin address to be added
	 */
	function addAdmin(address _adminAddress) external onlyAdmin {
		// Can't add 0x address as an admin
		require(_adminAddress != address(0x0), "[RBAC] : Admin must be != than 0x0 address");
		// Can't add existing admin
		require(!isAdmin[_adminAddress], "[RBAC] : Admin already exists.");
		// Add admin to array of admins
		admins.push(_adminAddress);
		// Set mapping
		isAdmin[_adminAddress] = true;
		emit AdminAdded(_adminAddress);
	}

	/**
	 * @dev remove an existing admin address
	 *
	 * @param _adminAddress admin address to be removed
	 */
	function removeAdmin(address _adminAddress) external onlyAdmin {
		// Admin has to exist
		require(isAdmin[_adminAddress]);
		require(admins.length > 1, "Can not remove all admins since contract becomes unusable.");
		uint256 i = 0;

		while (admins[i] != _adminAddress) {
			if (i == admins.length) {
				revert("Passed admin address does not exist");
			}
			i++;
		}

		// Copy the last admin position to the current index
		admins[i] = admins[admins.length - 1];

		isAdmin[_adminAddress] = false;

		// Remove the last admin, since it's double present
		admins.pop();
		emit AdminRemoved(_adminAddress);
	}

	/**
	 * @dev setAdminSigner updates adminSigner
	 *
	 * Emits a {AdminSignerUpdated} event.
	 *
	 * Requirements:
	 *
	 * - Only the admins can call this function
	 */
	function setAdminSigner(address _newAdminSigner) external onlyAdmin {
		adminSigner = _newAdminSigner;
		emit AdminSignerUpdated(_newAdminSigner, msg.sender);
	}

	/**
	 * @dev giveAway airdrops NFTs premint.
	 *
	 * Emits a {AirdropPerformed} event.
	 *
	 * Requirements:
	 *
	 * - Only the admins can call this function
	 */
	function giveAway(address to, uint256 amount) external onlyAdmin {
		require(totalSupply() + amount < maxSupply + 1, "Max supply reached");
		require(!airdrop, "Airdrop is already performed.");
		airdrop = true;
		_mint(to, amount);
		emit AirdropPerformed(to, amount);
	}

	/**
     * @dev setPhase updates the phase to (Phase01, Phase02, Phase03 or Phase04).
     $
     * Emits a {Unpaused} event.
     *
     * Requirements:
     *
     * - Only the admins can call this function
     */
	function setPhase(SalePhase phase_) external onlyAdmin {
		phase = phase_;
		emit PhaseUpdated(phase_, msg.sender);
	}

	/**
	 * @dev setBaseUri updates the new token URI in contract.
	 *
	 * Emits a {NewURI} event.
	 *
	 * Requirements:
	 *
	 * - Only the admins of contract can call this function
	 **/
	function setBaseUri(string memory uri) external onlyAdmin {
		baseURI = uri;
		emit NewURI(uri, msg.sender);
	}

	/**
	 * @dev Mint to mint nft
	 *
	 * Emits [Transfer] event.
	 *
	 * Requirements:
	 *
	 * - should have a valid coupon if we are ()
	 **/
	function mint(
		uint256 amount,
		bytes memory signature,
		CouponType couponType
	) external whenNotPaused nonReentrant {
		// this recreates the message that was signed on the client
		bytes32 message = prefixed(
			keccak256(abi.encodePacked(msg.sender, couponType, amount, block.chainid, this))
		);

		require(recoverSigner(message, signature) == adminSigner, "Invalid signature");

		require(!usedSignatures[signature], "Signature has been used earlier");

		usedSignatures[signature] = true;

		require(totalSupply() + amount < maxSupply + 1, "Max supply reached");

		if (phase == SalePhase.Phase01) {
			require(
				couponType == CouponType.Og || couponType == CouponType.Custom,
				"Invalid coupon"
			);
		} else if (phase == SalePhase.Phase02) {
			require(
				couponType == CouponType.Whitelist || couponType == CouponType.Custom,
				"Invalid coupon"
			);
		} else if (phase == SalePhase.Phase03) {
			require(
				couponType == CouponType.Og ||
					couponType == CouponType.Whitelist ||
					couponType == CouponType.Public ||
					couponType == CouponType.Custom,
				"Invalid coupon"
			);
		} else if (phase == SalePhase.Phase04) {
			require(
				couponType == CouponType.Public || couponType == CouponType.Custom,
				"Invalid coupon"
			);
		} else {
			revert("Invalid phase.");
		}

		/// mint
		_mint(msg.sender, amount);
	}

	/**
	 * Add support for interfaces
	 * @dev ERC721A
	 * @param interfaceId corresponding interfaceId
	 * @return bool true if supported, false otherwise
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC721A)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

	/**
	 * @dev getAdminSigner returns the adminSigner address
	 *
	 */
	function getAdminSigner() public view returns (address) {
		return adminSigner;
	}

	/**
	 * @dev getbaseURI returns the base uri
	 *
	 */
	function getbaseURI() public view returns (string memory) {
		return baseURI;
	}

	/**
	 * @dev getbaseURI returns the base uri
	 *
	 */
	function getAllAdmins() external view returns (address[] memory) {
		return admins;
	}

	/**
	 * @dev tokenURI returns the uri to meta data
	 *
	 */
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "GoArt Keys: Query for non-existent token");
		return
			bytes(baseURI).length > 0
				? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"))
				: "";
	}

	/// @dev Returns the starting token ID.
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	/**
	 * @dev pause() is used to pause contract.
	 *
	 * Emits a {Paused} event.
	 *
	 * Requirements:
	 *
	 * - Only the owner can call this function
	 **/
	function pause() public onlyAdmin whenNotPaused {
		_pause();
	}

	/**
	 * @dev unpause() is used to unpause contract.
	 *
	 * Emits a {Unpaused} event.
	 *
	 * Requirements:
	 *
	 * - Only the owner can call this function
	 **/
	function unpause() public onlyAdmin whenPaused {
		_unpause();
	}

	/// signature methods.
	function splitSignature(bytes memory sig)
		internal
		pure
		returns (
			uint8 v,
			bytes32 r,
			bytes32 s
		)
	{
		require(sig.length == 65);

		assembly {
			// first 32 bytes, after the length prefix.
			r := mload(add(sig, 32))
			// second 32 bytes.
			s := mload(add(sig, 64))
			// final byte (first byte of the next 32 bytes).
			v := byte(0, mload(add(sig, 96)))
		}

		return (v, r, s);
	}

	function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
		(uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

		return ecrecover(message, v, r, s);
	}

	/// builds a prefixed hash to mimic the behavior of eth_sign.
	function prefixed(bytes32 hash) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
	}
}