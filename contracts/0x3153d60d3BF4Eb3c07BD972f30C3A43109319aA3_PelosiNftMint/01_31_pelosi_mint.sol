// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../other/divestor_upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INft is IERC721 {
	function mint(address player_) external returns (uint256);
}

contract PelosiNftMint is OwnableUpgradeable {
	using SafeERC20Upgradeable for IERC20Upgradeable;
	struct MetaInfo {
		bool isOpen;
		uint256 maxAmount;
		uint256 mintAmount;
		uint256 mintPrice;
		INft nft;
	}
	MetaInfo public meta;

	mapping(address => bool) public whiteList;

	modifier isOpen() {
		require(meta.isOpen, "not open yet");
		_;
	}

	function initialize(address nft_) public initializer {
		__Ownable_init_unchained();

		meta.nft = INft(nft_);
		meta.mintPrice = 2 ether / 100;
		meta.maxAmount = 2000;
	}

	event Mint(address indexed player, uint256 indexed tokenId);
	event Divest(address token, address payee, uint256 value);

	function setOpen(bool isOpen_) external onlyOwner {
		meta.isOpen = isOpen_;
	}

	function setPrice(uint256 price_) external onlyOwner {
		meta.mintPrice = price_;
	}

	function setWhiteList(address[] calldata accounts_, bool[] calldata status_) public onlyOwner {
		for (uint256 i = 0; i < accounts_.length; i++) {
			whiteList[accounts_[i]] = status_[i];
		}
	}

	function divest(
		address token_,
		address payee_,
		uint256 value_
	) external onlyOwner {
		if (token_ == address(0)) {
			payable(payee_).transfer(address(this).balance);
			emit Divest(address(0), payee_, value_);
		} else {
			IERC20Upgradeable(token_).safeTransfer(payee_, value_);
			emit Divest(address(token_), payee_, value_);
		}
	}

	function mint() public payable {
		require(msg.value == meta.mintPrice, "wrong amount");
		require(meta.maxAmount >= meta.mintAmount + 1, "out of limit");

		meta.mintAmount += 1;
		_mint();
	}

	function _mint() private {
		uint256 tokenId = meta.nft.mint(_msgSender());
		emit Mint(_msgSender(), tokenId);
	}

	function batchMint(uint256 amount_) public payable {
		uint256 value = meta.mintPrice * amount_;
		require(msg.value == value, "wrong amount");
		require(meta.maxAmount >= meta.mintAmount + amount_, "out of limit");

		meta.mintAmount += amount_;

		for (uint256 i; i < amount_; i++) {
			_mint();
		}
	}
}