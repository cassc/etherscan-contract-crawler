// SPDX-License-Identifier: MIT
// Created by petdomaa100

/*
                                                                             %%%%%%%%%%%%%%%
                                                                           (%%%%%%#%%%%%%%%%
                                               (%%%%%%%%%%%%%%#           (%%%%%%%%%%%%%%%%%
                              *%%%#%#         %%%%#%%%%%%%#%%%%          /#%%%%%%%#%%%%%%%#%
                        %%%%%%%%%%#%%%       %%%%%%%%%%%%%%%%%%#        /%%%%%%%%%%%%%%%%%%%
                       %%%%%%%%%%%#%%%%      %%%%%#%%%%%%%%%%%%%       *%%%%%%%%%%#%%%%%%%%%
                     /%%%%%%%%%%%%#%%%%(    %%%%%%%%%%%%%%%%%%%%%     *%%%%%%%%%%%%%%%%%%%%%
                    #%#%%%#%%%#%%%#%%%#%    %%#%%%#%%%#%%%#%%%#%%    ,#%%%#%%%#%%%#%%%#%%%#%
                   %%%%%%%%%%%%%%%#%%%%%%  %%%%%%%%%%%%%%%%%%%%%%%  .%%%%%%%%%%%%%%%%%%%%%%%
                  #%%%%%%%%%%%%%%%#%%%%%%% %%%%%%%#%%%%%%%%%%%%%%% .%%%%%%%%%%%%%%#%%%%%%%%%
                 %%%%%%%%%%%%%%%%%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#%%%%%%%%%%%%%%%%%%%%%%%%%
                %%#%%%%%%%#%%%%%%%#%%%%%%%#%%%%%%%#%%%%%%%#%%%%%%%#%%%%%%%#%%%%%%%#%%%%%%%#%
              /%%%%%%%%%%%%%%%%%%%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#%%%%%%%%%%%%%%%%%%%%%%%%%
             %%%%%#%%%%%%%%%% %%%%#%%%%%%%%%%%%%%%#%%%%%%%%%%%%%%%#%%%%%%%%% (%%%%#%%%%%%%%%
            %%%%%%%%%%%%%%%%   %%%#%%%%%%%%%%%%%%%%%%%%/%%%%%%%%%%#%%%%%%%%, /%%%%%%%%%%%%%%
           %#%#%#%#%#%#%#%#    %#%#%#%#%#%#%#%#%#%#%#%  #%#%#%#%#%#%#%#%#%*  /#%#%#%#%#%#%#%
          %%%%%%%%%%%%%%%%      %%#%%%%%%%%%%%%%%%%%%#  *%%%%%%%%%#%%%%%%(   *%%%%%%%%%%%%%%
         %%%%%%%%%#%%%%%%       .%#%%%%%%%%%%%%%%%#%%    %%%%%%%%%#%%%%%(    ,%%%%#%%%%%%%%%
       (%%%%%%%%%%%%%%%%         %#%%%%%%%%%%%%%%%%%(    *%%%%%%%%#%%%%#      #%%%%%,       
      %%%%#%%%%%%%#%%%%           #%%%%%%%#%%%%%%%#%      #%%%%%%%#%%*                      
     %%%%%%%%%%%%%%%%%            .%%%%%%%%%%%%%%%%                                         
    %%%%%%%%%%%%%%#%%               %%%%#,                                                  
   %%%%%%%%%%%%%%%%(                                                                        
   %%%#%%%#/                                                                                
*/

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract ANIMALSMetaClub is ERC721, Ownable {
	using Counters for Counters.Counter;
	using Strings for uint256;

	bool public paused;
	bool public revealed;

	string private _unrevealedUriPrefix;
	string private _uriPrefix;
	string private _uriSuffix;

	uint256 public cost;
	uint256 public presaleCost;
	uint256 public maxSupply;
	uint256 public maxMintAmountPerTX;
	uint256 public maxMintAmountPerAddress;
	uint256 public maxMintAmountPerAddressForWL;

	Counters.Counter private _phase;
	Counters.Counter private _supply;

	address[] private _whitelistedAddresses;

	mapping(address => mapping(uint256 => uint256)) private _mintsOfAddress;

	uint256 private _vault;

	mapping(address => uint256) private _dividends;
	mapping(address => uint256) private _withdrawnDividends;

	event DividendsDistributed(address indexed from, uint256 amount);
	event DividendWithdrawn(address indexed to, uint256 amount);

	constructor(string memory initUnrevealedUriPrefix) ERC721("ANIMALS Meta Club", "AMCLUB") {
		paused = true;
		revealed = false;

		cost = 1 ether;
		presaleCost = 1 ether;
		maxSupply = 2000;
		maxMintAmountPerTX = 2;
		maxMintAmountPerAddress = 3;
		maxMintAmountPerAddressForWL = 2;

		_uriSuffix = ".json";
		_unrevealedUriPrefix = initUnrevealedUriPrefix;
	}

	function mint(uint256 amount) external payable {
		bool whitelisted = isAddressWhitelisted(_msgSender());
		uint256 maxMintAmount = whitelisted ? maxMintAmountPerAddressForWL : maxMintAmountPerAddress;

		require(amount > 0 && amount <= maxMintAmountPerTX, "ANIMALSMetaClub: invalid mint amount");
		require(getMintsOfAddress(_msgSender(), getCurrentPhase()) + amount <= maxMintAmount, "ANIMALSMetaClub: exceeded max mints for this phase");
		require(_supply.current() + amount <= maxSupply, "ANIMALSMetaClub: max token supply exceeded");
		require(!paused, "ANIMALSMetaClub: minting is paused");

		require(msg.value >= (whitelisted ? presaleCost : cost) * amount, "ANIMALSMetaClub: insufficient ether");

		_mintLoop(_msgSender(), amount);

		_mintsOfAddress[_msgSender()][getCurrentPhase()] += amount;
	}

	function airDrop(address[] calldata addresses, uint8[] calldata amounts) external onlyOwner {
		require(addresses.length == amounts.length, "ANIMALSMetaClub: invalid function arguments");
		require(addresses.length > 0, "ANIMALSMetaClub: invalid function arguments");

		uint256 newSupply = _supply.current();
		for (uint256 i = 0; i < amounts.length; i++) newSupply += amounts[i];

		require(newSupply <= maxSupply, "ANIMALSMetaClub: max token supply exceeded");

		for (uint256 i = 0; i < addresses.length; i++) {
			_mintLoop(addresses[i], amounts[i]);
		}
	}

	function beginNextPhase(uint256 newMaxSupply,uint256 newCost,uint256 newPresaleCost) external onlyOwner {
		_phase.increment();

		maxSupply = newMaxSupply;
		cost = newCost;
		presaleCost = newPresaleCost;
	}

	function flipPausedState() external onlyOwner {
		paused = !paused;
	}

	function reveal(string memory initUriPrefix) external onlyOwner {
		revealed = true;

		_uriPrefix = initUriPrefix;
	}

	function withdraw() external onlyOwner {
		(bool success, ) = payable(owner()).call{ value: address(this).balance - vault() }("");
		require(success);
	}

	function distributeDividends() public payable onlyOwner {
		uint256 supply = _supply.current();

		require(supply > 13, "ANIMALSMetaClub: total token supply need to be above 120");

		if (msg.value > 0) {
			uint256 dividendPerShare = msg.value / (supply - 13);
			uint256 totalDividend = dividendPerShare * (supply - 13);

			for (uint256 i = 14; i <= supply; i++) {
				address owner = ownerOf(i);

				_dividends[owner] += dividendPerShare;
			}

			_vault += totalDividend;

			emit DividendsDistributed(_msgSender(), totalDividend);
		}
	}

	function distributeDividendsToSpecifiedAddresses(address[] calldata addresses) public payable onlyOwner {
		require(addresses.length > 0, "ANIMALSMetaClub: invalid number of addresses");

		if (msg.value > 0) {
			uint256 dividendPerShare = msg.value / addresses.length;
			uint256 totalDividend = dividendPerShare * addresses.length;

			for (uint256 i = 0; i < addresses.length; i++) {
				_dividends[addresses[i]] += dividendPerShare;
			}

			_vault += totalDividend;

			emit DividendsDistributed(_msgSender(), totalDividend);
		}
	}

	function withdrawDividend() external {
		uint256 withdrawableDividend = dividendOf(_msgSender());

		if (withdrawableDividend > 0) {
			_withdrawnDividends[_msgSender()] += withdrawableDividend;
			_dividends[_msgSender()] -= withdrawableDividend;

			emit DividendWithdrawn(_msgSender(), withdrawableDividend);

			(bool success, ) = payable(_msgSender()).call{ value: withdrawableDividend }("");
			require(success, "ANIMALSMetaClub: failed to transfer withdrawable dividend");

			_vault -= withdrawableDividend;
		}
	}

	function dividendOf(address owner) public view returns (uint256) {
		return _dividends[owner];
	}

	function withdrawnDividendOf(address owner) public view returns (uint256) {
		return _withdrawnDividends[owner];
	}

	function vault() public view returns (uint256) {
		return _vault;
	}

	function totalSupply() external view returns (uint256) {
		return _supply.current();
	}

	function tokenURI(uint256 tokenID) public view override returns (string memory) {
		require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

		if (!revealed) return _unrevealedUriPrefix;

		string memory currentBaseURI = _baseURI();

		return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenID.toString(), _uriSuffix)) : "";
	}

	function walletOfOwner(address account) external view returns (uint256[] memory) {
		uint256 ownerTokenCount = balanceOf(account);

		uint256[] memory ownedTokenIDs = new uint256[](ownerTokenCount);

		uint256 tokenIndex = 1;
		uint256 ownedTokenIndex = 0;

		while (ownedTokenIndex < ownerTokenCount && tokenIndex <= maxSupply) {
			address owner = ownerOf(tokenIndex);

			if (owner == account) {
				ownedTokenIDs[ownedTokenIndex] = tokenIndex;

				ownedTokenIndex++;
			}

			tokenIndex++;
		}

		return ownedTokenIDs;
	}

	function isAddressWhitelisted(address account) public view returns (bool) {
		if (account == owner()) return true;

		for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
			if (_whitelistedAddresses[i] == account) return true;
		}

		return false;
	}

	function getMintsOfAddress(address account, uint256 phaseNumber) public view returns (uint256) {
		return _mintsOfAddress[account][phaseNumber];
	}

	function getCurrentPhase() public view returns (uint256) {
		return _phase.current();
	}

	function setURIprefix(string memory newPrefix) external onlyOwner {
		_uriPrefix = newPrefix;
	}

	function setUnrevealedURIprefix(string memory newUnrevealedURI) external onlyOwner {
		_unrevealedUriPrefix = newUnrevealedURI;
	}

	function setURIsuffix(string memory newSuffix) external onlyOwner {
		_uriSuffix = newSuffix;
	}

	function setMaxSupply(uint256 newAmount) external onlyOwner {
		maxSupply = newAmount;
	}

	function setMaxMintAmountPerTX(uint256 newAmount) external onlyOwner {
		maxMintAmountPerTX = newAmount;
	}

	function setMaxMintAmountPerAddress(uint256 newAmount) external onlyOwner {
		maxMintAmountPerAddress = newAmount;
	}

	function setMaxMintAmountPerAddressForWL(uint256 newAmount) external onlyOwner {
		maxMintAmountPerAddressForWL = newAmount;
	}

	function setCost(uint256 newCost) external onlyOwner {
		cost = newCost;
	}

	function setPresaleCost(uint256 newCost) external onlyOwner {
		presaleCost = newCost;
	}

	function setWhitelistedAddresses(address[] calldata addresses) external onlyOwner {
		delete _whitelistedAddresses;

		_whitelistedAddresses = addresses;
	}

	function _baseURI() internal view override returns (string memory) {
		return _uriPrefix;
	}

	function _mintLoop(address to, uint256 amount) internal {
		for (uint256 i = 0; i < amount; i++) {
			_supply.increment();

			_safeMint(to, _supply.current());
		}
	}
}