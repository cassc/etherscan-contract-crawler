// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
// @cryptoconner simple but effective. 
//1 billion = 1eth mintPrice for gwei denomented price 
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OfficialWelcomeBackTrump is ERC721, Ownable {
	using Strings for uint256;
	using Counters for Counters.Counter;

	Counters.Counter private _supply;

	string private baseURI;
	string private baseExt = ".json";

	bool public revealed = false;
	string private notRevealedUri;

	// Total supply
	uint256 public constant MAX_SUPPLY = 1000;

	// Whitelist mint constants
	bool public wlMintActive = false;
	uint256 private constant WL_MAX_PER_WALLET = 45; // 2/wallet (uses < to save gas)
	//uint256 private constant WL_MINT_PRICE = 0.05 ether;
	mapping(address => bool) private whitelists;


	// Public mint constants
	bool public pubMintActive = false;
	uint256 private constant PUB_MAX_PER_WALLET = 45; // 3/wallet (uses < to save gas)
	//uint256 private constant PUB_MINT_PRICE = 0.065 ether;

	bool private _locked = false; // for re-entrancy guard

    uint256 public WL_MINT_PRICE;
    uint256 public PUB_MINT_PRICE;

	// Initializes the contract by setting a `name` and a `symbol`
	constructor(string memory _initBaseURI, string memory _initNotRevealedUri, uint256 PUB_PRICE, uint256 WL_PRICE) ERC721("OfficialWelcomeBackTrump", "WBT") {
		setBaseURI(_initBaseURI);
		setNotRevealedURI(_initNotRevealedUri);
        setWlPrice(WL_PRICE);
        setPrice(PUB_PRICE);
        _supply.increment();
	}


	// Whitelist mint
	function whitelistMint(uint256 _quantity) external payable nonReentrant {
		require(wlMintActive, "Whitelist sale is closed at the moment.");

		address _to = msg.sender;
		require(_quantity > 0 && (balanceOf(_to) + _quantity) < WL_MAX_PER_WALLET, "Invalid mint quantity.");
		require(whitelists[_to], "You're not whitelisted.");
		require(msg.value >= (WL_MINT_PRICE * _quantity), "Not enough ETH.");

		mint(_to, _quantity);
	}

	// Public mint
	function publicMint(uint256 _quantity) external payable nonReentrant {
		require(pubMintActive, "Public sale is closed at the moment.");

		address _to = msg.sender;
		require(_quantity > 0 && (balanceOf(_to) + _quantity) < PUB_MAX_PER_WALLET, "Invalid mint quantity.");
		require(msg.value >= (PUB_MINT_PRICE * _quantity), "Not enough ETH.");

		mint(_to, _quantity);
	}

	/**
	 * Airdrop for promotions & collaborations
	 * You can remove this block if you don't need it
	 */
	function airDropMint(address _to, uint256 _quantity) external onlyOwner {
		require(_quantity > 0, "Invalid mint quantity.");
		mint(_to, _quantity);
	}

	// Mint an NFT
	function mint(address _to, uint256 _quantity) private {
		/**
		 * To save gas, since we know _quantity won't underflow / overflow
		 * Checks are performed in caller functions / methods
		 */
		unchecked {
			require((_quantity + _supply.current()) <= MAX_SUPPLY, "Max supply exceeded.");

			for (uint256 i = 0; i < _quantity; i++) {
				_safeMint(_to, _supply.current());
				_supply.increment();
			}
		}
	}

	// Toggle whitelist sales activity
	function toggleWlMintActive() public onlyOwner {
		wlMintActive = !wlMintActive;
	}

	// Toggle public sales activity
	function togglePubMintActive() public onlyOwner {
		pubMintActive = !pubMintActive;
	}

	// Set whitelist
	function toggleWhitelist(address _address) public onlyOwner {
		whitelists[_address] = !whitelists[_address];
	}

	// Get total supply
	function totalSupply() public view returns (uint256) {
		return _supply.current();
	}

    function setWlPrice(uint256 WL_PRICE) public onlyOwner {
        WL_MINT_PRICE = WL_PRICE * 1e9;
    
    }

    function setPrice(uint256 PUB_PRICE) public onlyOwner {
        PUB_MINT_PRICE = PUB_PRICE * 1e9;
    
    }

    

	// Get whitelist
	function isWhitelisted(address _address) public view returns (bool) {
		return whitelists[_address];
	}

	// Base URI
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	// Set base URI
	function setBaseURI(string memory _newBaseURI) public {
		baseURI = _newBaseURI;
	}

	// Get metadata URI
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");

		if (revealed == false) {
			return notRevealedUri;
		}

		string memory currentBaseURI = _baseURI();
		return
			bytes(currentBaseURI).length > 0
				? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExt))
				: "";
	}

	// Activate reveal
	function setReveal() public onlyOwner {
		revealed = true;
	}

	// Set not revealed URI
	function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
		notRevealedUri = _notRevealedURI;
	}

	// Withdraw balance
	function withdraw() external onlyOwner {
		// Transfer the remaining balance to the owner
		// Do not remove this line, else you won't be able to withdraw the funds
		(bool sent, ) = payable(owner()).call{ value: address(this).balance }("");
		require(sent, "Failed to withdraw Ether.");
	}

	// Receive any funds sent to the contract
	receive() external payable {}

	// Reentrancy guard modifier
	modifier nonReentrant() {
		require(!_locked, "No re-entrant call.");
		_locked = true;
		_;
		_locked = false;
	}
}