// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";


contract TheChinaNFT is ERC721A, Ownable {
	using Strings for uint256;

	string private _uriPrefix;
	string private _uriSuffix;

	uint256 public maxSupply;
	uint256 public presaleSupply;
	uint256 public maxMintAmountPerAddress;
	uint256 public maxMintAmountPerAddressForVip;

	bytes32 private _presaleMerkleRoot;
	bytes32 private _vipAddressesMerkleRoot;

	enum SaleState { PAUSED, PRESALE, PUBLIC_SALE }

	mapping(address => uint256) public helpers;

	string private contractMetadataURI;

	SaleState public saleState;

	event SaleStateChanged(SaleState indexed oldSaleState, SaleState indexed newSaleState);
	event UriPrefixUpdated(string indexed oldURIprefix, string indexed newURIprefix);
	event UriSuffixUpdated(string indexed oldURIsuffix, string indexed newURIsuffix);
	event MaxSupplyUpdated(uint256 indexed oldMaxSupply, uint256 indexed newMaxSupply);
	event PresaleSupplyUpdated(uint256 indexed oldPresaleSupply, uint256 indexed newPresaleSupply);
	event MaxMintAmountPerAddressUpdated(uint256 indexed oldMaxMintAmountPerAddress, uint256 indexed newMaxMintAmountPerAddress);
	event MaxMintAmountPerAddressForVipUpdated(uint256 indexed oldMaxMintAmountPerAddressForVip, uint256 indexed newMaxMintAmountPerAddressForVip);
	event PresaleMerkleRootUpdated(bytes32 indexed oldPresaleMerkleRoot, bytes32 indexed newPresaleMerkleRoot);
	event VipAddressesMerkleRootUpdated(bytes32 indexed oldVipAddressesMerkleRoot, bytes32 indexed newVipAddressesMerkleRoot);


	constructor(string memory initUriPrefix, bytes32 initPresaleMerkleRoot, bytes32 initVipAddressesMerkleRoot) ERC721A("The China NFT", "CHINA") {
		maxSupply = 5888;
		presaleSupply = 5888;
		maxMintAmountPerAddress = 1;
		maxMintAmountPerAddressForVip = 2;

		_uriPrefix = initUriPrefix;
		_uriSuffix = ".json";
		_presaleMerkleRoot = initPresaleMerkleRoot;
		_vipAddressesMerkleRoot = initVipAddressesMerkleRoot;

		saleState = SaleState.PAUSED;
		contractMetadataURI = "ipfs://QmNXXHFw1LdBbHzBnCWCdBVDUF3mEqUMjnfra7GJ1YeRt6/metadata.json";
	}

	function mint(uint256 amount, bytes32[] calldata vipMerkleProof) external payable {
		require(tx.origin == _msgSender(), "The China NFT: contract denied");
		require(saleState == SaleState.PUBLIC_SALE, "The China NFT: minting is not in public sale");
		require(amount > 0 && _numberMinted(_msgSender()) + amount <= _maxMintAmount(_msgSender(), vipMerkleProof), "The China NFT: invalid mint amount");
		require(_totalMinted() + amount <= maxSupply, "The China NFT: max token supply exceeded");

		_safeMint(_msgSender(), amount);
	}

	function presaleMint(uint256 amount, bytes32[] calldata vipMerkleProof, bytes32[] calldata presaleMerkleProof) external payable {
		require(tx.origin == _msgSender(), "The China NFT: contract denied");
		require(saleState == SaleState.PRESALE, "The China NFT: minting is not in presale");
		require(amount > 0 && _numberMinted(_msgSender()) + amount <= _maxMintAmount(_msgSender(), vipMerkleProof), "The China NFT: invalid mint amount");
		require(_merkleProof(_msgSender(), presaleMerkleProof, _presaleMerkleRoot), "The China NFT: invalid merkle proof");

		uint256 newSupply = _totalMinted() + amount;

		require(newSupply <= presaleSupply, "The China NFT: presale token supply exceeded");

		_safeMint(_msgSender(), amount);
	}


	function helperMint() external payable {
		require(tx.origin == _msgSender(), "The China NFT: contract denied");
		require(saleState != SaleState.PAUSED, "The China NFT: minting is paused");
		uint256 amount = helpers[msg.sender];
		require(_totalMinted() + amount <= maxSupply, "The China NFT: max token supply exceeded");
		helpers[msg.sender] = 0;
		_safeMint(_msgSender(), amount);

	}

	function contractURI() public view returns (string memory) {
    return contractMetadataURI;
  }

	function setContractMetadataURI(string memory _contractMetadataURI) external onlyOwner {
		contractMetadataURI = _contractMetadataURI;
	}

	function addHelper(address _address, uint256 _amount) external onlyOwner {
        helpers[_address] = _amount;
    }

	function addMultipleHelpers(address[] calldata _addresses, uint256[] calldata _amounts) external onlyOwner {
        require(_addresses.length <= 333,"too many addresses");
		require(_addresses.length == _amounts.length, "array sizes must match");
        for (uint256 i = 0; i < _addresses.length; i++) {
            helpers[_addresses[i]] = _amounts[i];
        }
    }

	 function removeHelper(address _address) external onlyOwner {
        helpers[_address] = 0;
    }

		function isHelper(address _address) public view returns(uint256) {
        return helpers[_address];
    }

	function setSaleState(SaleState newSaleState) external onlyOwner {
		emit SaleStateChanged(saleState, newSaleState);

		saleState = newSaleState;
	}


	function tokenURI(uint256 tokenId) public view override returns(string memory) {
		if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

		string memory baseURI = _baseURI();

		return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), _uriSuffix)) : "";
	}


	function setUriPrefix(string memory newPrefix) external onlyOwner {
		emit UriPrefixUpdated(_uriPrefix, newPrefix);

		_uriPrefix = newPrefix;
	}

	function setUriSuffix(string memory newSuffix) external onlyOwner {
		emit UriSuffixUpdated(_uriSuffix, newSuffix);

		_uriSuffix = newSuffix;
	}

	function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
		require(newMaxSupply > _totalMinted() && newMaxSupply > presaleSupply, "The China NFT: invalid amount");

		emit MaxSupplyUpdated(maxSupply, newMaxSupply);

		maxSupply = newMaxSupply;
	}

	function setPresaleSupply(uint256 newPresaleSupply) external onlyOwner {
		require(newPresaleSupply > _totalMinted() && newPresaleSupply < maxSupply, "The China NFT: invalid amount");

		emit PresaleSupplyUpdated(presaleSupply, newPresaleSupply);

		presaleSupply = newPresaleSupply;
	}

	function setMaxMintAmountPerAddress(uint256 newMaxMintAmountPerAddress) external onlyOwner {
		emit MaxMintAmountPerAddressUpdated(maxMintAmountPerAddress, newMaxMintAmountPerAddress);

		maxMintAmountPerAddress = newMaxMintAmountPerAddress;
	}

	function setMaxMintAmountPerAddressForVip(uint256 newMaxMintAmountPerAddressForVip) external onlyOwner {
		emit MaxMintAmountPerAddressForVipUpdated(maxMintAmountPerAddressForVip, newMaxMintAmountPerAddressForVip);

		maxMintAmountPerAddressForVip = newMaxMintAmountPerAddressForVip;
	}

	function setPresaleMerkleRoot(bytes32 newPresaleMerkleRoot) external onlyOwner {
		emit PresaleMerkleRootUpdated(_presaleMerkleRoot, newPresaleMerkleRoot);

		_presaleMerkleRoot = newPresaleMerkleRoot;
	}

	function setVipAddressesMerkleRoot(bytes32 newVipAddressesMerkleRoot) external onlyOwner {
		emit VipAddressesMerkleRootUpdated(_vipAddressesMerkleRoot, newVipAddressesMerkleRoot);

		_vipAddressesMerkleRoot = newVipAddressesMerkleRoot;
	}


	function _baseURI() internal view override returns(string memory) {
		return _uriPrefix;
	}

	function _startTokenId() internal pure override returns(uint256) {
		return 1;
	}

	function _maxMintAmount(address account, bytes32[] calldata merkleProof) internal view returns(uint256) {
		bool isVip = _merkleProof(account, merkleProof, _vipAddressesMerkleRoot);

		return isVip ? maxMintAmountPerAddressForVip : maxMintAmountPerAddress;
	}

	function _merkleProof(address account, bytes32[] calldata merkleProof, bytes32 merkleRoot) internal pure returns(bool) {
		bytes32 leaf = keccak256(abi.encodePacked(account));
		bool verified = MerkleProof.verify(merkleProof, merkleRoot, leaf);

		return verified;
	}
}