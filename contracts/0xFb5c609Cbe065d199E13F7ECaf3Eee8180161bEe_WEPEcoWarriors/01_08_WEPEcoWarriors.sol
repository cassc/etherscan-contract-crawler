// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";

interface IWRLD_Token_Ethereum {
	function balanceOf(address owner) external view returns(uint256);
	function transferFrom(address, address, uint256) external;
	function allowance(address owner, address spender) external view returns(uint256);
	function approve(address spender, uint256 amount) external returns(bool);
}

contract WEPEcoWarriors is ERC721A, Ownable, ReentrancyGuard{
	using Strings for uint256;

	IWRLD_Token_Ethereum public wrld;

	bool public CLAIM_MINT_ACTIVE = false;
	bool public WRLD_MINT_ACTIVE = false;
	bool public ETH_MINT_ACTIVE = false;

	uint256 public MAX_SUPPLY = 6000;
	uint256 public WRLD_MAX = 100;
	uint256 public WRLD_PRICE = 1000 ether;
	uint256 public ETH_MAX = 100;
	uint256 public ETH_PRICE = .025 ether;

	mapping(address => uint256) public claimable_wallets;
	mapping(address => uint256) public claimed_count;

	string public baseURI;
	string public baseExtension = ".json";
	address public payoutWallet;

	constructor(address _wrld_token, address[] memory _addresses, uint256[] memory _amount) ERC721A("WEP Eco Warriors", "WEW"){
		require(_addresses.length == _amount.length, "Invalid params");
		wrld = IWRLD_Token_Ethereum(_wrld_token);
		payoutWallet = msg.sender;
		for(uint256 i; i < _addresses.length;i++){
			_safeMint(_addresses[i], _amount[i]);
		}
	}

	function claimMint(uint256 _amount) external nonReentrant{
		require(CLAIM_MINT_ACTIVE == true, "Claim is not active");
		require(_amount > 0, "Amount must be greater than 0");
		require(this.totalSupply() + _amount <= MAX_SUPPLY, "Max Supply reached");
		require(claimed_count[msg.sender] + _amount <=  claimable_wallets[msg.sender], "Not eligable to claim or already claimed max amount");
		claimed_count[msg.sender] += _amount;
		_safeMint(msg.sender, _amount);
	}

	function wrldMint(uint256 _amount) external nonReentrant{
		require(WRLD_MINT_ACTIVE == true, "WrldMint is not active");
		require(_amount > 0 && _amount <= WRLD_MAX, "Invalid amount");
		require(this.totalSupply() + _amount <= MAX_SUPPLY, "Max Supply reached");
		uint256 cost = WRLD_PRICE * _amount;
		require (wrld.balanceOf(msg.sender) >= cost, "Not enough wrld");
		require (wrld.allowance(msg.sender, address(this)) >= cost, "Not enough allowance");
		wrld.transferFrom(msg.sender, address(this), cost);
		_safeMint(msg.sender, _amount);
	}

	function ethMint(uint256 _amount) external payable nonReentrant{
		require(ETH_MINT_ACTIVE == true, "EthMint is not active");
		require(_amount > 0 && _amount <= ETH_MAX, "Invalid amount");
		require(this.totalSupply() + _amount <= MAX_SUPPLY, "Max Supply reached");
		require(msg.value >= ETH_PRICE * _amount, "Not enough ETH");
		_safeMint(msg.sender, _amount);
	}

	function setClaimableWallets(address[] memory _addresses, uint256[] memory _amount) external onlyOwner{
		require(_addresses.length == _amount.length, "Invalid params");
		for(uint256 i; i < _addresses.length;i++){
			claimable_wallets[_addresses[i]] = _amount[i];
		}
	}

	function setClaimMint(bool _state) external onlyOwner{
		CLAIM_MINT_ACTIVE = _state;
	}

	function setWrldMint(bool _state) external onlyOwner{
		WRLD_MINT_ACTIVE = _state;
	}

	function setWrldMax(uint256 _amount) external onlyOwner{
		WRLD_MAX = _amount;
	}

	function setEthMint(bool _state) external onlyOwner{
		ETH_MINT_ACTIVE = _state;
	}

	function setEthMax(uint256 _amount) external onlyOwner{
		ETH_MAX = _amount;
	}

	function setMaxSupply(uint256 _amount) external onlyOwner{
		MAX_SUPPLY = _amount;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner{
		baseURI = _newBaseURI;
	}

	function setBaseExtension(string memory _extension) public onlyOwner{
		baseExtension = _extension;
	}

	function setPayoutWallet(address _wallet) external onlyOwner{
		payoutWallet = _wallet;
	}

	function withdraw() external payable onlyOwner{
		uint256 balance = wrld.balanceOf(address(this));
		wrld.approve(address(this), balance);
		wrld.transferFrom(address(this), payoutWallet, balance);
		payable(payoutWallet).transfer(address(this).balance);
	}

	function tokenURI(uint _token_id) public view override returns(string memory){
		return string(abi.encodePacked(baseURI, _token_id.toString(), baseExtension));
	}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}