// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface kWRLD_Token_Ethereum {
	function balanceOf(address owner) external view returns(uint256);
	function transferFrom(address, address, uint256) external;
	function allowance(address owner, address spender) external view returns(uint256);
	function transfer(address recipient, uint256 amount) external returns(bool);
	function approve(address spender, uint256 amount) external returns(bool);
}

contract WRLDMarketplace is Ownable, ReentrancyGuard{
	 event ListingPurchased(address indexed seller, address indexed buyer, address indexed hostContract, uint tokenId, uint price);
	 event kickbackClaimed(address indexed to, uint amount);

	address public payoutWallet;
	uint16 public communityPercent;
	kWRLD_Token_Ethereum public wrld;

	constructor (address _wrldToken){
		wrld = kWRLD_Token_Ethereum(_wrldToken);
		communityPercent = 100;
	}

	mapping(bytes => bool) private claimSignatures;
	mapping(bytes => bool) private creatorSignatures;
	mapping(address => address) private creatorWallet;

	function purchase(address _seller, address _hostContract, uint _price, uint _tokenId, uint nounce, uint _creatorPercent, bytes calldata _signature) external payable nonReentrant{
		{
			bytes32 hash =  ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_seller, _hostContract, _price, _tokenId, nounce, _creatorPercent)));
			address signer = ECDSA.recover(hash, _signature);
			require(signer == owner(), "Invalid signature");
		}
		require (wrld.balanceOf(msg.sender) >= _price, "Not enough world");
		require (wrld.allowance(msg.sender, address(this)) >= _price, "Not enough allowance");

		ERC721 hostContract = ERC721(_hostContract);
		require (hostContract.ownerOf(_tokenId) == _seller, "Seller is no longer holder");
		hostContract.safeTransferFrom(_seller, msg.sender, _tokenId);

		uint communityPayout = (_price / 1000) * communityPercent;
		wrld.transferFrom(msg.sender, address(this), communityPayout);
		uint buyerPayout = _price - communityPayout;

		if(creatorWallet[_hostContract] != address(0x0)){
			uint creatorPayout = (buyerPayout / 1000) * _creatorPercent;
			wrld.transferFrom(msg.sender, creatorWallet[_hostContract], creatorPayout);
			buyerPayout = buyerPayout - creatorPayout;
		}

		wrld.transferFrom(msg.sender, _seller, buyerPayout);

		emit ListingPurchased(_seller, msg.sender, _hostContract, _tokenId, _price);
	}

	function claim(uint256 _amount, uint _nounce, bytes calldata _signature) external payable nonReentrant{
		require(!claimSignatures[_signature], "Signature already used");
		bytes32 hash =  ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_amount, msg.sender, _nounce)));
		address signer = ECDSA.recover(hash, _signature);
		require(signer == owner(), "Invalid signature");
		claimSignatures[_signature] = true;
		wrld.transfer(msg.sender, _amount);
		emit kickbackClaimed(msg.sender, _amount);
	}

	function setCreatorWallet(address _contract, address _wallet, uint _nounce, bytes calldata _signature) external {
		require(!creatorSignatures[_signature], "Signature already used");
		bytes32 hash =  ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_contract, _wallet, _nounce)));
		address signer = ECDSA.recover(hash, _signature);
		require(signer == owner(), "Invalid signature");
		creatorSignatures[_signature] = true;
		creatorWallet[_contract] = _wallet;
	}

	function getCreatorWallet(address _contract) public view returns(address){
		return creatorWallet[_contract];
	}

	function setCommunityPercent(uint16 _percent) external onlyOwner{
		communityPercent = _percent;
	}

	function ownerSetCreatorWallet(address _contract, address _wallet) external onlyOwner{
		creatorWallet[_contract] = _wallet;
	}

	function setPayoutWallet(address _wallet) external onlyOwner{
		payoutWallet = _wallet;
	}

	function withdraw() external payable onlyOwner{
		uint256 balance = wrld.balanceOf(address(this));
		wrld.approve(address(this), balance);
		wrld.transferFrom(address(this), payoutWallet, balance);
	}
}