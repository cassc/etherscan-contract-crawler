// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface INft is IERC721 {
	function mint(address player_) external returns (uint256);

	function batchMint(address account, uint256 amount) external returns (uint256[] memory tokenIds);
}

contract HeroWorldCupMint is OwnableUpgradeable, ReentrancyGuardUpgradeable {
	struct MetaInfo {
		bool isOpen;
		uint256 maxAmount;
		uint256 mintAmount;
		uint256 mintPrice;
		INft nft;
	}

	MetaInfo public meta;

	mapping(address => uint256) public userMint;

	modifier isOpen() {
		require(meta.isOpen, "not open yet");
		_;
	}

	function initialize(address nft_) public initializer {
		__Ownable_init_unchained();

		meta.nft = INft(nft_);
		meta.mintPrice = 2 ether / 10;
		meta.maxAmount = 1398;
	}

	event Mint(address indexed player, uint256[] indexed tokenIds);
	event Divest(address token, address payee, uint256 value);

	function setOpen(bool isOpen_) external onlyOwner {
		meta.isOpen = isOpen_;
	}

	function setPrice(uint256 price_, uint256 maxAmount_) external onlyOwner {
		meta.mintPrice = price_;
		meta.maxAmount = maxAmount_;
	}

	function divest(address payee_, uint256 value_) external onlyOwner {
		payable(payee_).transfer(address(this).balance);
		emit Divest(address(0), payee_, value_);
	}

	function mint(uint256 amount_) public payable nonReentrant {
		uint256 value = meta.mintPrice * amount_;
		require(msg.value == value, "wrong amount");
		require(meta.maxAmount >= meta.mintAmount + amount_, "out of limit");
		require(userMint[msg.sender] + amount_ <= 5, "out of limit");

		meta.mintAmount += amount_;
		userMint[msg.sender] += amount_;

		uint256[] memory tokenIds = meta.nft.batchMint(msg.sender, amount_);
		emit Mint(_msgSender(), tokenIds);
	}
}