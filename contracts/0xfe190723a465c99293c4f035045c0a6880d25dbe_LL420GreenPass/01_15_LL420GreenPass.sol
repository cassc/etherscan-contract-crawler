//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game Green Pass and O.G. Pass
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LL420GreenPass is ERC1155Burnable, ReentrancyGuard, Ownable {
	using SafeMath for uint256;

	string private baseURI;

	uint256 public constant GREEN_PASS_FEE = 0.142 ether;
	uint256 public constant OG_TIME_LIMIT = 4 hours + 20 minutes;
	uint256 public constant GREEN_LIST_TIME_LIMIT = 48 hours;

	uint8 public constant GREEN_PASS_TOKEN_ID = 0;
	uint8 public constant OG_TOKEN_ID = 1;
	uint8 public constant MAX_PASSES = 3;
	string public constant NAME = "420.game Green Pass";
	string public constant SYMBOL = "420GP";
	address public VAULT;

	uint16[2] public supplyCaps = [10000, 420];

	bytes32 public ogMerkleRoot;
	bytes32 public greenListMerkleRoot;
	uint256 public startTimestamp;

	mapping(address => bool) public hasOGClaimed;
	mapping(uint8 => uint256) public supplies;

	mapping(address => uint256) public amountPerWallets;

	event SetStartTimestamp(uint256 indexed _timestamp);
	event ClaimOGNFT(address indexed _user);
	event ClaimGreenPassNFT(address indexed _user);
	event VaultPasses(address indexed _user);

	modifier onlyUnclaimedOG() {
		require(
			hasOGClaimed[msg.sender] == false,
			"LL420GreenPass: Can't claim multiple times"
		);

		_;
	}

	modifier onlyStarted() {
		require(
			block.timestamp >= startTimestamp,
			"LL420GreenPass: Not started yet"
		);

		_;
	}

	constructor(
		string memory _baseURI,
		uint256 _startTimestamp,
		bytes32 _ogMerkleRoot,
		bytes32 _greenListMerkleRoot
	) ERC1155(_baseURI) {
		baseURI = _baseURI;
		ogMerkleRoot = _ogMerkleRoot;
		greenListMerkleRoot = _greenListMerkleRoot;
		startTimestamp = _startTimestamp;

		emit SetStartTimestamp(startTimestamp);
	}

	function claim(bytes32[] calldata merkleProof, uint256 _qty)
		external
		payable
		nonReentrant
		onlyStarted
	{
		require(
			_qty > 0 && _qty <= MAX_PASSES,
			"LL420GreenPass: Can't mint 0 or more than MAX_PASSES"
		);
		require(
			msg.value >= GREEN_PASS_FEE.mul(_qty),
			"LL420GreenPass: Not enough fee"
		);

		bytes32 node = keccak256(abi.encodePacked(msg.sender));
		bool isOGVerified = MerkleProof.verify(merkleProof, ogMerkleRoot, node);
		uint256 timePeriod = block.timestamp - startTimestamp;

		if (timePeriod <= OG_TIME_LIMIT) {
			require(isOGVerified, "LL420GreenPass: Not allowed time");
			require(
				amountPerWallets[msg.sender] + _qty <= MAX_PASSES,
				"LL420GreenPass: Can't mint more than MAX_PASSES during OG period"
			);

			amountPerWallets[msg.sender] += _qty;
		} else if (timePeriod <= OG_TIME_LIMIT + GREEN_LIST_TIME_LIMIT) {
			bool isGreenListVerified = MerkleProof.verify(
				merkleProof,
				greenListMerkleRoot,
				node
			);

			require(
				isOGVerified || isGreenListVerified,
				"LL420GreenPass: Not allowed time"
			);
			require(
				amountPerWallets[msg.sender] + _qty <= MAX_PASSES,
				"LL420GreenPass: Can't mint more than MAX_PASSES during Green List period"
			);
			amountPerWallets[msg.sender] += _qty;
		}

		_mint(msg.sender, GREEN_PASS_TOKEN_ID, _qty, "");
		emit ClaimGreenPassNFT(msg.sender);
	}

	function claimOG(bytes32[] calldata merkleProof)
		external
		nonReentrant
		onlyStarted
		onlyUnclaimedOG
	{
		bytes32 node = keccak256(abi.encodePacked(msg.sender));
		require(
			MerkleProof.verify(merkleProof, ogMerkleRoot, node),
			"LL420GreenPass: Not OG address"
		);

		hasOGClaimed[msg.sender] = true;
		_mint(msg.sender, OG_TOKEN_ID, 1, "");

		emit ClaimOGNFT(msg.sender);
	}

	function setBaseUri(string memory _baseURI) external onlyOwner {
		baseURI = _baseURI;
	}

	function setOgMerkleRoot(bytes32 _ogMerkleRoot) external onlyOwner {
		ogMerkleRoot = _ogMerkleRoot;
	}

	function setGreenListMerkleRoot(bytes32 _greenListMerkleRoot)
		external
		onlyOwner
	{
		greenListMerkleRoot = _greenListMerkleRoot;
	}

	function setStartTimestamp(uint256 _startTimestamp) external onlyOwner {
		startTimestamp = _startTimestamp;

		emit SetStartTimestamp(startTimestamp);
	}

	function name() public pure returns (string memory) {
		return NAME;
	}

	function symbol() public pure returns (string memory) {
		return SYMBOL;
	}

	function uri(uint256 typeId) public view override returns (string memory) {
		require(
			typeId == GREEN_PASS_TOKEN_ID || typeId == OG_TOKEN_ID,
			"LL420GreenPass: URI requested for invalid token type"
		);
		require(bytes(baseURI).length > 0, "LL420GreenPass: base URI is not set");

		return string(abi.encodePacked(baseURI, Strings.toString(typeId)));
	}

	function withdrawAll() external onlyOwner {
		(bool success, ) = payable(VAULT).call{value: address(this).balance}("");

		require(success, "LL420GreenPass: Failed to withdraw to the owner");
	}

	function setVault(address _newVaultAddress) external onlyOwner {
		VAULT = _newVaultAddress;
	}

	function withdraw(uint256 _amount) external onlyOwner {
		require(address(VAULT) != address(0), "LL420GreenPass: No vault");
		require(payable(VAULT).send(_amount), "LL420GreenPass: Withdraw failed");
	}

	function _mint(
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal override {
		require(
			supplies[uint8(id)] < supplyCaps[uint8(id)],
			"LL420GreenPass: Suppy limit was hit"
		);

		supplies[uint8(id)] += amount;
		super._mint(to, id, amount, data);
	}

	function vaultMint(uint256 _id, uint256 _amount) external onlyOwner {
		_mint(msg.sender, _id, _amount, "");
		emit VaultPasses(msg.sender);
	}
}