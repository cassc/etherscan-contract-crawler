// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721A.sol";

interface IJuice {
	function ownerOf(uint256 tokenId) external view returns (address owner);

	function burn(uint256 tokenId) external;
}

contract CloneMachine is ERC721A, Ownable, Pausable, ReentrancyGuard {
	using Address for address;
	using Strings for uint256;
	using ECDSA for bytes32;

	uint256 private constant NONE = 0;
	uint256 private constant CAT = 1;
	uint256 private constant RAT = 2;
	uint256 private constant PIGEON = 3;
	uint256 private constant DOG = 4;

	IJuice private juiceContract;
	address private gutterCats;
	address private gutterRats;
	address private gutterPigeons;
	address private gutterDogs;

	address private signerAddress;
	bool public upgradeIsLive = false;

	mapping(uint256 => bool) public usedCats;
	mapping(uint256 => bool) public usedRats;
	mapping(uint256 => bool) public usedPigeons;
	mapping(uint256 => bool) public usedDogs;

	mapping(uint256 => bool) public upgradedClones;

	string private _contractBaseURI = "https://guttercloneapi.guttercatgang.com/metadata/";
	string private _contractURI = "ipfs://QmdotChEKgUZ38CiYxr7PSC23N5Mh4a28uQLDXRfVfhYNH";

	event JuiceBurned(uint256 cloneId, uint256 juiceId, uint256 speciesType, uint256 speciesId);
	event CloneUpgraded(uint256 oldCloneID, uint256 newCloneID, uint256 juiceID);

	modifier burnValid(
		bytes32 hash,
		bytes memory sig,
		uint256 speciesType,
		uint256 speciesID,
		uint256 juiceID
	) {
		require(matchAddresSigner(hash, sig), "invalid signer");
		require(hashClone(_msgSender(), speciesID, speciesType, juiceID) == hash, "invalid hash");
		require(juiceContract.ownerOf(juiceID) == _msgSender(), "not the owner");
		_;
	}

	constructor() ERC721A("Gutter Clone", "CLONE") {
		_pause();
	}

	/**
	 * @dev setup function run initially
	 */
	function setup(
		address juicesAddress,
		address cats,
		address rats,
		address pigeons,
		address dogs,
		address signer
	) external onlyOwner {
		juiceContract = IJuice(juicesAddress);
		gutterCats = cats;
		gutterRats = rats;
		gutterPigeons = pigeons;
		gutterDogs = dogs;
		signerAddress = signer;
	}

	/**
	 * @dev clones a cat
	 */
	function cloneWithCat(
		bytes memory sig,
		bytes32 hash,
		uint256 juiceId,
		uint256 speciesId
	) external whenNotPaused nonReentrant burnValid(hash, sig, CAT, speciesId, juiceId) {
		require(IERC1155(gutterCats).balanceOf(_msgSender(), speciesId) > 0, "not the cat owner");
		require(!usedCats[speciesId], "cat is used");

		juiceContract.burn(juiceId);

		_safeMint(_msgSender(), 1);
		usedCats[speciesId] = true;

		emit JuiceBurned(totalSupply(), juiceId, CAT, speciesId);
	}

	/**
	 * @dev clones a rat
	 */
	function cloneWithRat(
		bytes memory sig,
		bytes32 hash,
		uint256 juiceId,
		uint256 speciesId
	) external whenNotPaused nonReentrant burnValid(hash, sig, RAT, speciesId, juiceId) {
		require(IERC1155(gutterRats).balanceOf(_msgSender(), speciesId) > 0, "not the rat owner");
		require(!usedRats[speciesId], "rat is used");

		juiceContract.burn(juiceId);

		_safeMint(_msgSender(), 1);
		usedRats[speciesId] = true;

		emit JuiceBurned(totalSupply(), juiceId, RAT, speciesId);
	}

	/**
	 * @dev clones a pigeon
	 */
	function cloneWithPigeon(
		bytes memory sig,
		bytes32 hash,
		uint256 juiceId,
		uint256 speciesId
	) external whenNotPaused nonReentrant burnValid(hash, sig, PIGEON, speciesId, juiceId) {
		require(IERC721(gutterPigeons).ownerOf(speciesId) == _msgSender(), "not the pigeon owner");
		require(!usedPigeons[speciesId], "pigeon is used");

		juiceContract.burn(juiceId);

		_safeMint(_msgSender(), 1);
		usedPigeons[speciesId] = true;

		emit JuiceBurned(totalSupply(), juiceId, PIGEON, speciesId);
	}

	/**
	 * @dev clones a dog
	 */
	function cloneWithDog(
		bytes memory sig,
		bytes32 hash,
		uint256 juiceId,
		uint256 speciesId
	) external whenNotPaused nonReentrant burnValid(hash, sig, DOG, speciesId, juiceId) {
		require(IERC721(gutterDogs).ownerOf(speciesId) == _msgSender(), "not the dog owner");
		require(!usedDogs[speciesId], "dog is used");

		juiceContract.burn(juiceId);

		_safeMint(_msgSender(), 1);
		usedDogs[speciesId] = true;

		emit JuiceBurned(totalSupply(), juiceId, DOG, speciesId);
	}

	function cloneWithoutSpecies(
		bytes memory sig,
		bytes32 hash,
		uint256 juiceId
	) external whenNotPaused nonReentrant burnValid(hash, sig, NONE, 0, juiceId) {
		juiceContract.burn(juiceId);

		_safeMint(_msgSender(), 1);

		emit JuiceBurned(totalSupply(), juiceId, NONE, 0);
	}

	/**
	 * @dev upgrades a clone
	 * @param sig  - backend signature
	 * @param hash  - hash of transaction
	 * @param juiceId  - nft id of the juice
	 * @param tokenID  - the clone that you own
	 */
	function upgradeClone(
		bytes memory sig,
		bytes32 hash,
		uint256 juiceId,
		uint256 tokenID //the old clone
	) external nonReentrant {
		require(upgradeIsLive, "not live");
		require(matchAddresSigner(hash, sig), "invalid signer");
		require(hashUpgrade(_msgSender(), juiceId, tokenID) == hash, "invalid hash");
		require(ownerOf(tokenID) == _msgSender(), "not the owner");
		require(juiceContract.ownerOf(juiceId) == _msgSender(), "not juice owner");
		require(!upgradedClones[tokenID], "clone was already upgraded");

		juiceContract.burn(juiceId);

		_safeMint(_msgSender(), 1);

		upgradedClones[tokenID] = true;

		emit CloneUpgraded(tokenID, totalSupply(), juiceId); //old clone, new clone, juice id
	}

	/**
	 * READ FUNCTIONS
	 */
	function exists(uint256 _tokenId) external view returns (bool) {
		return _exists(_tokenId);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_contractBaseURI, _tokenId.toString()));
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns (bool) {
		return signerAddress == hash.recover(signature);
	}

    function hashClone(
		address sender,
        uint256 speciesID,
        uint256 speciesType,
        uint256 juiceID
	) private pure returns (bytes32) {
		bytes32 hash = ECDSA.toEthSignedMessageHash(
			keccak256(abi.encodePacked(sender, speciesID, speciesType, juiceID))
		);
		return hash;
	}

	function hashUpgrade(
		address sender,
		uint256 param1,
		uint256 param2
	) private pure returns (bytes32) {
		bytes32 hash = ECDSA.toEthSignedMessageHash(
			keccak256(abi.encodePacked(sender, param1, param2))
		);
		return hash;
	}

	//------- ADMIN FUNCTIONS -------
	function setUpgradeLiveness(bool isLive) external onlyOwner {
		upgradeIsLive = isLive;
	}

	function changeSigner(address newSigner) external onlyOwner {
		signerAddress = newSigner;
	}

	function setPaused(bool _setPaused) external onlyOwner {
		return (_setPaused) ? _pause() : _unpause();
	}

	function setBaseURI(string memory newBaseURI) external onlyOwner {
		_contractBaseURI = newBaseURI;
	}

	function setContractURI(string memory newContractURI) external onlyOwner {
		_contractURI = newContractURI;
	}

	function adminMint(address to, uint256 qty) external onlyOwner {
		_safeMint(to, qty);
	}

	function reclaimERC20(IERC20 erc20Token) external onlyOwner {
		erc20Token.transfer(_msgSender(), erc20Token.balanceOf(address(this)));
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), _msgSender(), id);
	}

	function reclaimERC1155(
		address erc1155Token,
		uint256 id,
		uint256 amount
	) public onlyOwner {
		IERC1155(erc1155Token).safeTransferFrom(address(this), _msgSender(), id, amount, "");
	}

	function withdrawEarnings() external onlyOwner {
		payable(_msgSender()).transfer(address(this).balance);
	}

	//------- OTHER -------
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}
}