//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*
 *         ^
 *        / \
 *       / _ \
 *      |.ETH.|      ██╗      █████╗ ██╗   ██╗███╗   ██╗ ██████╗██╗  ██╗
 *      |'._.'|      ██║     ██╔══██╗██║   ██║████╗  ██║██╔════╝██║  ██║
 *      |     |      ██║     ███████║██║   ██║██╔██╗ ██║██║     ███████║
 *      |  S  |      ██║     ██╔══██║██║   ██║██║╚██╗██║██║     ██╔══██║
 *      |  P  |      ███████╗██║  ██║╚██████╔╝██║ ╚████║╚██████╗██║  ██║
 *      |  A  |      ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝
 *      |  C  |
 *      |  E  |      ██████╗  █████╗ ███████╗███████╗
 *      |  +  |      ██╔══██╗██╔══██╗██╔════╝██╔════╝
 *     ||     ||     ██████╔╝███████║███████╗███████╗
 *    .'|  |  |'.    ██╔═══╝ ██╔══██║╚════██║╚════██║
 *   /  |  |  |  \   ██║     ██║  ██║███████║███████║
 *   |.-'--|--'-.|   ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝
 */

interface ISpacePlusAvatar {
	function transferLaunchPasses(address to, uint256 amountToRedeem) external;
}

contract LaunchPass is ERC1155, Ownable, ERC2981, ERC1155Burnable {
	/**
	 * @dev Supply minted under token id 1 to keep burning simple.
	 */
	uint256 public constant TOKEN_ID = 1;

	//==== AVATAR CONTRACT ====\\
	address public avatarContractAddress;

	//==== EVENTS ====\\
	event Received(address, uint256);

	//==== SUPPLY ====\\
	uint256 public constant MAX_PASSES = 10921; // Circumference of the moon in km
	uint256 public constant COMMUNITY_DEVELOPMENT = 250; // Passes reserved for giveaways and community development
	uint256 public constant THE_TEAM = 225; // Will be airdropped to all those who helped make Space+ possible
	uint256 public constant MAX_PER_AL_WALLET = 2; // Max number of passes a wallet in the allowlist can mint
	uint256 public constant MAX_PER_PUBLIC_MINT = 5; // Max number of passes a wallet can mint during public sale
	uint256 public devMintRemaining = 382; // Maximum possible dev mints, but may not mint out before the dev mint window closes

	//==== PRICE ====\\
	uint256 public tokenPrice = 170000000000000000; // 0.17 ETH

	//==== CONTRACT STATE ====\\
	uint256 public mintCount;
	bool public isAllowlistMintOpen;
	bool public isDevMintOpen;
	bool public isPublicMintOpen;
	bool public isRedemptionEnabled;

	//==== ROYALTIES ====\\
	uint96 public royaltyFee = 750; // Royalty percentage is 7.5%
	address public royaltyAddress;

	//==== ALLOWLIST ====\\
	bytes32 public merkleRoot;
	mapping(address => uint256) public allowlistMinted;

	/**
	 * @dev Record of reserved mints remaining per wallet for developers.
	 */
	mapping(address => uint256) public devMintList;

	constructor() ERC1155("ipfs://bafkreig26hjqlvrv6rq2jh5alvtnwvxxxgxjv7whvs5gup6utu3ekbpv2q") {
		royaltyAddress = owner();
		_setDefaultRoyalty(royaltyAddress, royaltyFee);
	}

	/**
	 * @notice Modifier that only allows the caller to be an externally owned account, not a contract.
	 */
	modifier onlyEoa() {
		require(tx.origin == msg.sender, "The caller is a contract");
		_;
	}

	/**
	 * @notice Allows minting of up to two passes, for eligible allowlist wallets.
	 */
	function allowlistMint(uint256 amountToMint, bytes32[] calldata merkleProof) external payable onlyEoa {
		require(isAllowlistMintOpen, "Allowlist mint not open");
		require(amountToMint > 0 && amountToMint <= MAX_PER_AL_WALLET, "Amount must be 1 or 2");
		require(allowlistMinted[msg.sender] + amountToMint <= MAX_PER_AL_WALLET, "Exceeds wallet allowance");

		bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
		require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Address not found in allowlist");

		allowlistMinted[msg.sender] += amountToMint;
		_internalMint(amountToMint);
	}

	/**
	 * @notice Allows eligible developers to mint.
	 */
	function devMint(uint256 amountToMint) external payable onlyEoa {
		require(isDevMintOpen, "Developer mint not open");
		require(devMintList[msg.sender] > 0, "Not eligible for dev mint");

		require(devMintRemaining >= amountToMint, "Exceeds dev supply limit");
		require(amountToMint <= devMintList[msg.sender], "Exceeds dev wallet's allotted amount");

		devMintList[msg.sender] -= amountToMint;
		devMintRemaining -= amountToMint;
		_internalMint(amountToMint);
	}

	/**
	 * @notice Allows the public to mint.
	 */
	function publicMint(uint256 amountToMint) external payable onlyEoa {
		require(isPublicMintOpen, "Public mint not open");
		require(amountToMint > 0 && amountToMint < 6, "1 to 5 tokens per transaction");

		_internalMint(amountToMint);
	}

	/**
	 * @notice Handles minting for allowlistMint, devMint, and publicMint.
	 */
	function _internalMint(uint256 amountToMint) internal {
		require(amountToMint + mintCount + COMMUNITY_DEVELOPMENT <= MAX_PASSES, "Mint will exceed total supply");
		require(msg.value == tokenPrice * amountToMint, "ETH sent must be equal to mint price");

		mintCount += amountToMint;
		_mint(msg.sender, TOKEN_ID, amountToMint, "");
	}

	/**
	 * @notice Exchanges Launch Pass tokens for Space+ Avatars. Launch Passes are burned in the process.
	 */
	function redeemTokens(uint256 amountToRedeem) external onlyEoa {
		require(isRedemptionEnabled, "Redemption period not enabled");
		require(amountToRedeem > 0 && amountToRedeem <= balanceOf(msg.sender, 1), "Amount must be between 1 and tokens owned");
		ISpacePlusAvatar avatarContract = ISpacePlusAvatar(avatarContractAddress);

		// Burn launch pass token
		burn(msg.sender, TOKEN_ID, amountToRedeem);

		// Mint avatar in separate contract
		avatarContract.transferLaunchPasses(msg.sender, amountToRedeem);
	}

	/**
	 * @notice For gifting Launch Pass tokens.
	 */
	function airdrop(address[] calldata to, uint256[] calldata amountToMint) external onlyOwner {
		require(to.length == amountToMint.length, "Addresses length does not match amountToMint length");
		uint256 tokenCount = mintCount;
		for (uint256 i = 0; i < to.length; i++) {
			require(amountToMint[i] + tokenCount <= MAX_PASSES, "Mint will exceed total supply");
			tokenCount += amountToMint[i];
			_mint(to[i], TOKEN_ID, amountToMint[i], "");
		}
		mintCount = tokenCount;
	}

	/**
	 * @notice Seeds the developer list with max mint amount by address.
	 */
	function seedDevList(address[] memory addresses, uint256[] memory mintAmounts) external onlyOwner {
		require(addresses.length == mintAmounts.length, "Addresses length does not match mintAmounts length");
		for (uint256 i = 0; i < addresses.length; i++) {
			devMintList[addresses[i]] = mintAmounts[i];
		}
	}

	/**
	 * @notice Stores the Space+ Avatar contract address, used during Launch Pass to Avatar migration.
	 */
	function setSpacePlusAvatarContract(address contractAddress) external onlyOwner {
		avatarContractAddress = contractAddress;
	}

	/**
	 * @notice Sets the merkle root for the allowlist mint.
	 */
	function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
		merkleRoot = _merkleRoot;
	}

	/**
	 * @notice Verifies wallet address eligibility for the allowlist mint.
	 */
	function isAllowlistEligible(address wallet, bytes32[] calldata merkleProof) external view returns (bool) {
		bytes32 leaf = keccak256(abi.encodePacked(wallet));
		return MerkleProof.verify(merkleProof, merkleRoot, leaf);
	}

	/**
	 * @notice Updates price if necessary.
	 */
	function setPrice(uint256 newPrice) external onlyOwner {
		tokenPrice = newPrice;
	}

	/**
	 * @notice Toggles the allowlist mint.
	 */
	function toggleAllowlistMint() external onlyOwner {
		require(merkleRoot != "", "Empty merkle root");
		isAllowlistMintOpen = !isAllowlistMintOpen;
	}

	/**
	 * @notice Toggles the developer mint.
	 */
	function toggleDevMint() external onlyOwner {
		isDevMintOpen = !isDevMintOpen;
	}

	/**
 	 * @notice Toggles the public mint.
	 */
	function togglePublicMint() external onlyOwner {
		require(!isAllowlistMintOpen && !isDevMintOpen, "All other mints must be closed");
		isPublicMintOpen = !isPublicMintOpen;
	}

	/**
	 * @notice Toggles the migration period for redeeming a Launch Pass for an Avatar.
	 */
	function toggleRedemptionPeriod() external onlyOwner {
		require(avatarContractAddress != address(0), "Missing Avatar contract");
		isRedemptionEnabled = !isRedemptionEnabled;
	}

	/**
	 * @notice Sets the royalty information that all ids in this contract will default to.
	 */
	function setRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner {
		royaltyAddress = receiver;
		royaltyFee = feeNumerator;
		_setDefaultRoyalty(receiver, feeNumerator);
	}

	/**
	 * @notice Withdraws funds from the contract.
	 */
	function withdraw(address payable to, uint256 amount) external onlyOwner {
		(bool success, ) = to.call{value: amount}("");
		require(success, "Withdraw failed");
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981) returns (bool) {
		return super.supportsInterface(interfaceId);
	}

	/**
	 * @notice Allows contract to receive funds.
	 */
	receive() external payable {
		emit Received(msg.sender, msg.value);
	}
}