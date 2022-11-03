// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface ALNFTs {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract LycanProtocol is ERC721A, Ownable, ReentrancyGuard {

	bool public _mintingActive = false;
	uint256 public PRICE_PER_MINT = 66000000000000000 wei; // == 0.066 ether
	
	uint256 public _MAX_SUPPLY = 6666;
	uint256 public _FREE_SUPPLY = 666;
	uint256 public _STAFF_SUPPLY = 66;
	uint256 public _PAID_SUPPLY = _MAX_SUPPLY - _FREE_SUPPLY - _STAFF_SUPPLY;
	
	uint256 public _MAX_PER_WALLET_PAID = 10;
	
	// incremented with each token minted
	uint256 public PAID_TOKENS_MINTED = 1;
	uint256 public FREE_TOKENS_MINTED = 1;

	// used to enforce per wallet mint limits
	mapping(address => uint256) public WALLET_PAID_MINTS;
	mapping(address => uint256) public WALLET_FREE_MINTS;

	address receiver = ROYALTY_SPLIT_ADDRESS;
	uint256 ROYALTY_AMOUNT = 660;

	address public FWB_ADDRESS = address(0x35bD01FC9d6D5D81CA9E055Db88Dc49aa2c699A8);
	address public ID_ADDRESS = address(0xA66F3bd98b4741bad68BCd7511163c6F855d2129);
	address public DENZA_ADDRESS = address(0x24288944e667B129f0b9E30fFB7c4af90FB0e7E0);
	address public ALLSTARZ_ADDRESS = address(0xEC0a7A26456B8451aefc4b00393ce1BefF5eB3e9);
	address public MANNY_ADDRESS = address(0x2bd58A19C7E4AbF17638c5eE6fA96EE5EB53aed9);
	address public CHUMS_ADDRESS = address(0xe987E9b07cA431FE0C7e8f431FA4F94ab9CA2423);
	address public PSSSSD_ADDRESS = address(0x3A2096754Df385553C4252E5A82DC862e64169Bb);
	
	// Save which form each token is in
	bool ALL_ALLOWED_TO_CHANGE = false;
	string[2] FORMS = ["Human", "Wolf"];
	mapping(uint256 => uint256) public TOKEN_FORM;
	mapping(uint256 => bool) public TOKENS_ALLOWED_TO_CHANGE;

	string public BASE_HUMAN_TOKEN_URL;
	string public BASE_WOLF_TOKEN_URL;
	
	address internal TREASURY_ADDRESS;
	address internal TEAM_SPLIT_ADDRESS;
	address internal ROYALTY_SPLIT_ADDRESS;

	constructor(
		address _TREASURY_ADDRESS,
		address _TEAM_SPLIT_ADDRESS,
		address _ROYALTY_SPLIT_ADDRESS,
		string memory _BASE_TOKEN_URL
	) ERC721A("Lycan Protocol", "LP") {
		TREASURY_ADDRESS = _TREASURY_ADDRESS;
		TEAM_SPLIT_ADDRESS = _TEAM_SPLIT_ADDRESS;
		ROYALTY_SPLIT_ADDRESS = _ROYALTY_SPLIT_ADDRESS;
		BASE_WOLF_TOKEN_URL = _BASE_TOKEN_URL;
		BASE_HUMAN_TOKEN_URL = _BASE_TOKEN_URL;
	}

	function maxSupply() external view returns (uint256) {
		return _MAX_SUPPLY;
	}

	function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

	function burn(uint256 tokenId) external {
		require(ownerOf(tokenId) == msg.sender);
        _burn(tokenId);
    }

	function mint(uint256 amount) external nonReentrant payable {
		require(msg.sender == tx.origin);
    	require(_mintingActive, "Minting is not yet active");
		// Check that there is still paid supply left
		require(PAID_TOKENS_MINTED + amount <= _PAID_SUPPLY);
		// Check that msg value is correct for number of mints
		require(PRICE_PER_MINT * amount == msg.value, "Incorrect ETH value");
		// Check that user has more paid mints
		require(WALLET_PAID_MINTS[msg.sender] + amount <= _MAX_PER_WALLET_PAID);
		
		WALLET_PAID_MINTS[msg.sender] = WALLET_PAID_MINTS[msg.sender] + amount;
		_safeMint(msg.sender, amount);
		PAID_TOKENS_MINTED = PAID_TOKENS_MINTED + amount;
	}

	function freeMint() external nonReentrant {
		require(msg.sender == tx.origin);
    	require(_mintingActive, "Minting is not yet active");
		// Check that there is still free supply left
		require(FREE_TOKENS_MINTED <= _FREE_SUPPLY, "No more free mints!");
		// Check if user already got their free mint
		require(WALLET_FREE_MINTS[msg.sender] == 0, "You got your free mint");
		// Check that they have an AL NFT
		require(hasALNFT(msg.sender), "Missing AL NFT");
		WALLET_FREE_MINTS[msg.sender] = 1;
		_safeMint(msg.sender, 1);
		++FREE_TOKENS_MINTED;
	}

	function hasALNFT(address user_address) internal view returns (bool) {
        if (ALNFTs(FWB_ADDRESS).balanceOf(user_address) > 75) {
			return true;
		} else if (ALNFTs(CHUMS_ADDRESS).balanceOf(user_address) > 0) {
			return true;
		} else if (ALNFTs(ALLSTARZ_ADDRESS).balanceOf(user_address) > 0) {
			return true;
		} else if (ALNFTs(MANNY_ADDRESS).balanceOf(user_address) > 0) {
			return true;
		} else if (ALNFTs(DENZA_ADDRESS).balanceOf(user_address) > 0) {
			return true;
		} else if (ALNFTs(ID_ADDRESS).balanceOf(user_address) > 0) {
			return true;
		} else if (ALNFTs(PSSSSD_ADDRESS).balanceOf(user_address) > 0) {
			return true;
		} else {
			return false;
		}
    }

	function _change_form(uint256 tokenId, uint256 form) public {
		require(msg.sender == tx.origin);
		require(ownerOf(tokenId) == msg.sender);
		require(form <= 1, "Form can only be 0 or 1");
		require((TOKENS_ALLOWED_TO_CHANGE[tokenId] == true) || (ALL_ALLOWED_TO_CHANGE));
		TOKEN_FORM[tokenId] = form;
	}
	
	function tokenURI(uint256 tokenId) override public view returns (string memory) {
		if (TOKEN_FORM[tokenId] == 1) {
			return string.concat(BASE_WOLF_TOKEN_URL, Strings.toString(tokenId));
		} else {
			return string.concat(BASE_HUMAN_TOKEN_URL, Strings.toString(tokenId));
		}
  	}

	function _check_ALStatus(address _address) external view returns (bool) {
		// Lets users check if they hold any of the Allowlist NFTs
		return hasALNFT(_address);
	}

	function _flipMintable() external onlyOwner {_mintingActive = !_mintingActive;}
	function _changePrice(uint256 _PRICE_PER_MINT) external onlyOwner {PRICE_PER_MINT = _PRICE_PER_MINT;}
	function _changePaidWalletMax(uint256 _NEW_MAX) external onlyOwner {_MAX_PER_WALLET_PAID = _NEW_MAX;}

	function _activateMint() external onlyOwner {_mintingActive = !_mintingActive;}
	function _activateWolves() external onlyOwner {ALL_ALLOWED_TO_CHANGE = !ALL_ALLOWED_TO_CHANGE;}

	function _staffMints() external onlyOwner {
		_safeMint(TREASURY_ADDRESS, _STAFF_SUPPLY);
	}

	function _staffMint(address to) external onlyOwner {
		require(msg.sender == tx.origin);
		require(PAID_TOKENS_MINTED + 1 <= _PAID_SUPPLY);
		_safeMint(to, 1);
		PAID_TOKENS_MINTED = PAID_TOKENS_MINTED + 1;
	}

	function _allowToChange(uint256 tokenId) external onlyOwner {
		TOKENS_ALLOWED_TO_CHANGE[tokenId] = !TOKENS_ALLOWED_TO_CHANGE[tokenId];
	}

	function _withdrawFunds() public payable onlyOwner {
        (bool success, ) = payable(address(TEAM_SPLIT_ADDRESS)).call{value: address(this).balance}("");
        require(success);
    }

	function _changeBaseWolfTokenURI(string memory _BASE_WOLF_TOKEN_URL) external onlyOwner {
		BASE_WOLF_TOKEN_URL = _BASE_WOLF_TOKEN_URL;
	}
	function _changeBaseHumanTokenURI(string memory _BASE_HUMAN_TOKEN_URL) external onlyOwner {
		BASE_HUMAN_TOKEN_URL = _BASE_HUMAN_TOKEN_URL;
	}

	function royaltyInfo(uint256, uint256 _salePrice) external view returns (address _ROYALTY_SPLIT_ADDRESS, uint256 _ROYALTY_AMOUNT) {
		_ROYALTY_AMOUNT = (_salePrice * ROYALTY_AMOUNT) / 10000;
		_ROYALTY_SPLIT_ADDRESS = ROYALTY_SPLIT_ADDRESS;
	}
}