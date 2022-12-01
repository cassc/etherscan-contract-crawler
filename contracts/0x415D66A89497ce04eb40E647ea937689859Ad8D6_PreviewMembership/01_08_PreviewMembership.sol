// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PreviewMembership is Context, ERC721A, Ownable, ReentrancyGuard {
	using Strings for uint256;
	string public baseURI;
	uint256 public earnings;
	AggregatorV3Interface public eth2usd;
	address public chainlinkTarget;
	uint256 public holdMax;
	uint256 public maxSupply;
	uint256 public mintMax;
	uint256 public usdPrice;
	address public payoutAddress;
	address public signer;
	uint256 public stage;
	bool public open;
	bool public whitelisted;
	bool public airdropFreeToken;

	mapping(address => uint256) public walletHoldings;
	mapping(uint256 => string) private _tokenURIs;

	event Received(address, uint256);
	event WithdrawalSuccess(uint256 amount);

	struct SettingsStruct {
		string name;
		string symbol;
		address signer;
		address payoutAddress;
		bool open;
		uint256 stage;
		address chainlinkTarget;
		string baseURI;
		uint256 earnings;
		uint256 mintPrice;
		uint256 usdPrice;
		uint256 holdMax;
		uint256 maxSupply;
		uint256 mintMax;
		bool whitelisted;
		uint256 totalMinted;
		uint256 totalBurned;
		uint256 totalSupply;
	}

	modifier noZeroAddress(address _address) {
		require(_address != address(0), "10:signer");
		_;
	}

	constructor(
		string memory _name,
		string memory _symbol,
		uint256 _maxSupply,
		uint256 _usdPrice,
		uint256 _mintMax,
		uint256 _holdMax,
		address _signer,
		address _payoutAddress,
		address _chainlinkTarget
	)
		ERC721A(_name, _symbol)
		noZeroAddress(_signer)
		noZeroAddress(_payoutAddress)
	{
		usdPrice = _usdPrice;
		maxSupply = _maxSupply;
		mintMax = _mintMax;
		holdMax = _holdMax;
		signer = _signer;
		payoutAddress = _payoutAddress;
		open = false;
		whitelisted = true;
		airdropFreeToken = true;
		stage = 1;
		eth2usd = AggregatorV3Interface(_chainlinkTarget);
		chainlinkTarget = _chainlinkTarget;
	}

	receive() external payable {
		emit Received(msg.sender, msg.value);
	}

	function airdrop(
		address receiver,
		uint256 amount
	) public onlyOwner noZeroAddress(receiver) nonReentrant {
		require(amount > 0, "20:mintingLimit");
		require(maxSupply >= amount + _totalMinted(), "20:maxSupply");
		_buy(receiver, amount);
	}

	function burn(uint256 tokenId) public virtual {
		super._burn(tokenId);
	}

	/**
	 * Returns the latest price
	 */
	function getETHPrice() public view returns (uint256) {
		(, int256 price, , , ) = eth2usd.latestRoundData();
		return uint256(price);
	}

	function mintingPrice() public view returns (uint256) {
		return
			(1000000000000000000 * usdPrice * 10 ** eth2usd.decimals()) /
			getETHPrice();
	}

	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	function totalMinted() public view returns (uint256) {
		return _totalMinted();
	}

	function setPayoutAddress(
		address _payoutAddress
	) external noZeroAddress(_payoutAddress) onlyOwner nonReentrant {
		payoutAddress = _payoutAddress;
	}

	function setBaseURI(string memory newURI) external onlyOwner nonReentrant {
		require(bytes(newURI).length > 0, "10:url");
		baseURI = newURI;
	}

	function tokenURI(
		uint256 tokenId
	) public view virtual override returns (string memory) {
		require(
			_exists(tokenId),
			"ERC721Metadata: URI query for nonexistent token"
		);

		string memory _tokenURI = _tokenURIs[tokenId];
		string memory base = baseURI;

		// If there is no base URI, return the token URI.
		if (bytes(base).length == 0) {
			return _tokenURI;
		}
		// If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
		if (bytes(_tokenURI).length > 0) {
			return string(abi.encodePacked(base, _tokenURI));
		}
		// If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
		return string(abi.encodePacked(base, tokenId.toString()));
	}

	function setAggregatorInterface(
		address _chainlinkTarget
	) external noZeroAddress(_chainlinkTarget) onlyOwner {
		eth2usd = AggregatorV3Interface(_chainlinkTarget);
		chainlinkTarget = _chainlinkTarget;
	}

	function setSigner(
		address _signer
	) external onlyOwner noZeroAddress(_signer) {
		signer = _signer;
	}

	function setUSDPrice(uint256 price) public onlyOwner nonReentrant {
		require(price > 0, "10:price");
		usdPrice = price;
	}

	function setMintMax(uint256 limit) public onlyOwner nonReentrant {
		require(limit > 0, "10:limit");
		mintMax = limit;
	}

	function setStage(uint256 _stage) public onlyOwner nonReentrant {
		require(_stage > 0, "10:limit");
		stage = _stage;
	}

	function setHoldMax(uint256 limit) public onlyOwner nonReentrant {
		require(limit > 0, "10:limit");
		holdMax = limit;
	}

	function mint(
		bytes memory signature,
		uint256 tokenAmount,
		uint256 tier,
		uint256 walletLimit
	) public payable nonReentrant {
		require(open, "Contract closed");
		require(msg.value >= mintingPrice() * tokenAmount, "30:amount");
		require(maxSupply >= tokenAmount + _totalMinted(), "Supply limit");
		require(
			holdMax >= walletHoldings[msg.sender] + tokenAmount,
			"Holding limit"
		);
		require(mintMax >= tokenAmount, "Too many tokens");
		require(
			_verify(signature, tokenAmount, tier, walletLimit),
			"Wallet is not whitelisted"
		);
		if (whitelisted) {
			require(tier == stage, "Tier is not valid");
		}

		walletHoldings[msg.sender] += tokenAmount;

		if (airdropFreeToken) {
			tokenAmount *= 2;
		}
		_buy(msg.sender, tokenAmount);
	}

	function setWhitelisted(bool _whitelisted) external onlyOwner {
		whitelisted = _whitelisted;
	}

	function setAirdropFreeToken(bool _airdropFreeToken) external onlyOwner {
		airdropFreeToken = _airdropFreeToken;
	}

	function setMaxSupply(uint256 _totalSupply) external onlyOwner {
		require(_totalSupply >= _totalMinted(), "Total supply too low");
		maxSupply = _totalSupply;
	}

	function setMultiple(
		uint256 _maxSupply,
		uint256 _usdPrice,
		uint256 _mintMax,
		uint256 _holdMax,
		uint256 _newStage,
		bool _whitelisted,
		string memory _newBaseURI
	) external onlyOwner {
		require(_maxSupply > _totalMinted(), "Total supply too low");
		maxSupply = _maxSupply;
		usdPrice = _usdPrice;
		mintMax = _mintMax;
		holdMax = _holdMax;
		stage = _newStage;
		whitelisted = _whitelisted;
		baseURI = _newBaseURI;
	}

	function withdrawETH(uint256 amount) public nonReentrant onlyOwner {
		require(amount <= address(this).balance, "Insufficient funds");
		require(payoutAddress != address(0), "Invalid address");
		(bool success, ) = payoutAddress.call{ value: amount }("");
	}

	function setSecret(address _secret) external onlyOwner {
		require(_secret != address(0), "200:ZERO_ADDRESS");
		signer = _secret;
	}

	function setOpen(bool _open) external onlyOwner {
		open = _open;
	}

	function getSettings() public view returns (SettingsStruct memory) {
		SettingsStruct memory settings = SettingsStruct({
			name: name(),
			symbol: symbol(),
			signer: signer,
			payoutAddress: payoutAddress,
			open: open,
			stage: stage,
			chainlinkTarget: chainlinkTarget,
			baseURI: baseURI,
			earnings: earnings,
			mintPrice: mintingPrice(),
			usdPrice: usdPrice,
			holdMax: holdMax,
			maxSupply: maxSupply,
			mintMax: mintMax,
			whitelisted: whitelisted,
			totalMinted: _totalMinted(),
			totalBurned: _totalBurned(),
			totalSupply: totalSupply()
		});
		return settings;
	}

	function _buy(address to, uint256 quantity) internal {
		_safeMint(to, quantity);
	}

	function _verifyHashSignature(
		bytes32 hash,
		bytes memory signature
	) internal view returns (bool) {
		bytes32 r;
		bytes32 s;
		uint8 v;

		if (signature.length != 65) {
			return false;
		}

		assembly {
			r := mload(add(signature, 32))
			s := mload(add(signature, 64))
			v := byte(0, mload(add(signature, 96)))
		}

		if (v < 27) {
			v += 27;
		}

		address recoverySigner = address(0);
		// If the version is correct, gather info
		if (v == 27 || v == 28) {
			// solium-disable-next-line arg-overflow
			recoverySigner = ecrecover(hash, v, r, s);
		}
		return signer == recoverySigner;
	}

	function _verify(
		bytes memory signature,
		uint256 tokenAmount,
		uint256 tier,
		uint256 walletLimit
	) internal view returns (bool) {
		if (!whitelisted) {
			return true;
		}
		bytes32 freshHash = keccak256(
			abi.encode(msg.sender, tokenAmount, tier, walletLimit)
		);
		bytes32 candidateHash = keccak256(
			abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
		);
		return _verifyHashSignature(candidateHash, signature);
	}
}