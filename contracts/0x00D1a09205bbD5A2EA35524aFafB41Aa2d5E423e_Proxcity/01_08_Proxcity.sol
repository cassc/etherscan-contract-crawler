// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";

contract Proxcity is ERC721A, Ownable, ReentrancyGuard{
	using Strings for uint256;

	uint256 public MAX_SUPPLY = 1000;
	uint256 public MINT_COST = .07 ether;

	bool public WM_ACTIVE = false;
	bool public WM_LIMTED = true;
	bool public MINT_ENABLED = false;
	bool public FREE_MINT_ENABLED = false;
	bool public BURN_ENABLED = false;

	struct Stake {
		address owner;
		uint256 timestamp;
	}
	mapping(uint256 => Stake) public staked;
	mapping(address => uint256) public wmMints;
	mapping(address => uint256) public allowedWmMints;
	mapping(address => uint256) public freeMints;

	string public baseURI;
	string public baseExtension = ".json";
	address public payoutWallet;

	constructor() ERC721A("Proxcity", "PRXCTY"){
	}

	function wmMint(uint256 _quantity) external nonReentrant{
		require(WM_ACTIVE == true, "WMMint not active");
		require(_quantity > 0, "Mint amount must be greater then 0");
		require(this.totalSupply() + _quantity <= MAX_SUPPLY, "WM mint complete");

		if(WM_LIMTED){
			require(wmMints[msg.sender] + _quantity <= allowedWmMints[msg.sender], "Max allowed mints reached");
		} else{
			require(allowedWmMints[msg.sender] > 0, "Not eligable to mint in this phase");
		}
		wmMints[msg.sender] += _quantity;
		_safeMint(msg.sender, _quantity);
	}

	function freeMint(uint256 _quantity) external nonReentrant{
		require(FREE_MINT_ENABLED == true, "Phase not active");
		require(_quantity > 0 && _quantity <= 5, "Mint amount must be greater then 0 and less than or equal to 5");
		require(freeMints[msg.sender] + _quantity <= 5, "Address has reached the max free mints");
		require(this.totalSupply() + _quantity <= MAX_SUPPLY, "Free mint complete");
		freeMints[msg.sender] += _quantity;
		_safeMint(msg.sender, _quantity);
	}

	function mint(uint256 _quantity) external payable nonReentrant{
		require(MINT_ENABLED == true, "Phase not active");
		require(_quantity > 0 && _quantity <= 10, "Mint amount must be greater then 0 and less than or equal to 10");
		require(this.totalSupply() + _quantity <= MAX_SUPPLY, "Mint complete");
		require(_quantity * MINT_COST == msg.value, "Not enough eth");
		_safeMint(msg.sender, _quantity);
	}

	function stake(uint256 _token_id) external{
		require (this.ownerOf(_token_id) == msg.sender, "Not owner");
		staked[_token_id] = Stake(msg.sender, block.timestamp);
	}

	function unstake(uint256 _token_id) external{
		require(staked[_token_id].owner == msg.sender, "Not owner");
		staked[_token_id] = Stake(address(0x0), 0);
	}

	function burn(uint256 _token_id) external{
		require(BURN_ENABLED == true, "Burn is not enabled");
		require(this.ownerOf(_token_id) == msg.sender, "Caller is not token owner");
		_burn(_token_id, true);
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

	function setWMMints(address[] memory _wallet, uint256[] memory _amount) external onlyOwner{
		for(uint256 x = 0;x < _wallet.length; x++){
			allowedWmMints[_wallet[x]] = _amount[x];
		}
	}

	function setWMLimited(bool _active) external onlyOwner{
		WM_LIMTED = _active;
	}

	function setBurn(bool _active) external onlyOwner{
		BURN_ENABLED = _active;
	}

	function setSupply(uint256 _supply) external onlyOwner{
		MAX_SUPPLY = _supply;
	}

	function setPrice(uint256 _price) external onlyOwner{
		MINT_COST = _price;
	}

	function setPhase(uint256 _phase, bool _active) external onlyOwner{
		if(_phase == 1){
			WM_ACTIVE = _active;
		} else if (_phase == 2){
			MINT_ENABLED = _active;
		} else if(_phase == 3){
			FREE_MINT_ENABLED = _active;
		}
	}

	function withdraw() external payable onlyOwner{
		payable(payoutWallet).transfer(address(this).balance);
	}

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        require(staked[startTokenId].timestamp == 0, "Cannot transfer - currently staked");
    }

	function tokenURI(uint _token_id) public view override returns(string memory){
		return string(abi.encodePacked(baseURI, _token_id.toString(), baseExtension));
	}
}