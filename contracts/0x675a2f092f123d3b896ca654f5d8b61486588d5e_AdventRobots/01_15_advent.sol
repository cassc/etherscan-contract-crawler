// SPDX-License-Identifier: MIT
// Created by petdomaa100 | Managed by Satoshi Design

/*
                                                          &#&%&&%#((                                                    
                                                      .%%%%&&&%%%%(&(%                                                  
                                                       /&%%&%&&&%#%%(*                                                  
                                                      /#%%&@&%&&#/#&(((                                                 
                                                    &%%%@%&&&&&&%%#(((##,                                               
                                                    *@%%%%%&&&&&&&&%## /                                                
                                     ..              #@#/**#&%&&%(###((                                                 
                           &%######%%%%%              .,%%%%&&&&&&%#%(    %&%%%%%##%%#/                                 
                        %#%%#/, *%%%%%                  (&@&&&%&(&%&#        @%%%%%#* #%##                              
                     %%%%%%%#%%#*%%%%*                  .&&@@@@&&%&/         @%%%%&,%%/%%%%%/                           
                    %%# %%%%%%%%%#*. .%%%%#,            #@&@@@&&&&%    .%%%%%%#.  #%%%%%%%*&&%                          
                        ,%%%%%&&&%%##(&%&%%%%%%%@&   %@&@@&&@@&%&@%%%%%%%%%&&%%##(#% /%%%(                              
                      *%%%%%%%%&#%//,.&%&(%%%&&&&%%&@&@@&@@&&@&#@#@@#@%%%&&&&###**#%% /%%%%,                            
                    *%%%%%%%&&&&%%&,[email protected]&%#%&%%##%%%%&&%&%%&@&%#(###(%&&##%(#&/#,,&&/%%#%%%%%%%.                          
                  (%%%%%%%%%%&&&&&&&%#//(%&&&%./&%%%%%%%%&&&&#(#%&%&%(//////&%%%%%%%%%%%%%&%%%%,                        
                %%%%%%%%%%%%%%%&&&&&@@@&&&%&&% @%&&&&&%%%%%%%#/(%%#(/////////#%%%%%%%%%%%%%%@%%%%,                      
              &%%%%%%%%%%%%%%%%%%&@@@@@&&@@@&(&%&%&&&&%%%%%%%((/&%&%(/////////&#%%%%%%%%%%%%%&%%%%%,                    
            &&&&&&&%%%%%%%%%%%&&&@@@@@&&@@@@@@&&&&&&&&&&&&&%#((/@%&&%#(///////#&%%%%%%%%%%%%%%%@%%%%%,                  
          %&&&&&&&%%%&&&&&&&&@@@@@@&@@&@@@@@@&&&&&&&&&&&&&%##(((&%&&%##(((((((%&%&&&&&&&&@@&&&&&&&&&&&%*                
        %&&&&&&&&&&&&&&&&&&&&&&&@@&&&&&@@@@@@@@@&&&&&&&&&&&####(%%&&&####(((%%##((%%%%%%%%&&@&&&&&&&&&&&&*              
      %&&&&&&&&&&&&&&&&&&&&&&&&@@@&&&&&@@@@@@@@@&@@@@@@@@&&&&&&#/%#&&&&&&&&&&&%#((%%%%%%%%%%&&@@&&&&&&&&&&&*            
    %&&&&&&&&&&&&&&%%%&&&&#/,    @@&&&&@@@@@@&@@@&&&&&&&&&&&&&&#(&#(((#((((%%&&##(#      *%%%%%&&@&&&&&&&&&&%,          
 ,%%&&&&&&&&&&&&%%%%%%(         (&&&&&@@@@@@@@&@%@&&&&&&&&&&&%%&&@&&%((((((%&&&%###         ,%%%%&&@@&&&&&&&&%&/        
&&%&&&&&&&&&&%%%%%%(           *@@&&&@@@@@@@@@ &@&@%&&&&&&&&@&&& @@%(@@&(#%%@@&&&%%            ,%%%%&&@@&&&&&%&&&/      
&&%&&&&&&&%%%%%%*             &&&@@&@@@@ &@@@@ ,@#%&&&#&#@&@&@@&@@@@(@&&&@&@@@@&&&%               .%%%&&&@&%%%&&&&&(    
&%%%%%&%%%%%%*               @&@&&&@@&   (@@@@    ,&&&/*& @&@@@&&&&@#%/ &% *@@@@&&(                  .%%%&&@@&&&&&&&&(  
&&&&&%%%%%,                  &&@&@@@.     @@@@      && /(.%&&@%(%%&@&(.,#   @&&&*(%.                    .%%%&&@&&&&&&&&(
&&%%%%%.                    ,%&&&&(&@#    &@@@      %&(/// &&%%,.&&@%( /#   @@&%&#%##                       %%&&&@&&&&&&
%%%%.                        %&&&&#&#      @@@      #&&.*& &&%&/,&&&(% *((  #&&,(&  /(                         %%&&@@&&&
%                            #&&&&%,/%     &@@       &&///(#&#  %&(  ,./#    @&&/&/ ##                            %&&&@&
                              %&&&%(&,      @@   (&@@&&&@@&%&%  %&,  [email protected]%&@&   &@@%& #(                               %&&
                              (%&&&#%       &    #&&&@&@@@&(&&  %%.   &%&%%(   &@&&&((                                  
                               %&&&%%           (@@&&&&&&&#/&&. /&.   #%%%%#    @@@&%(                                  
                                %&&&(*         #&&&%&@@&&&&/&&( *%*  /%%%&/&#%.  @@@&((                                 
                                %&&&%%        %&&%@%&%&@@@&&%&&#*&%##%%&&#&&%@#   &@&&/                                 
                                (#@&&%*      %%&&@@%&&&@&&&&&&&&&&&&&&@%&&&@%@&&  *@&%(/                                
                                 @&&%&(      #&@%@@&@@@&@@&@&&&&&&&&&&%@&#@@&@%%   %@&%&                                
                                 /%&@&&%&   (%@&&%@&#@&@@&@@@&&&&&&&&@&&@@%@&&%%   ,&%/&(                               
                                  &%&@@&&#  #@@&&&%&@&@@&&@@@&&&&&&&@@@&@/&@&%%&(  &&(&@/                               
                                  %&&&&@ &&(%@@&&&&%&%@&@@&@  @@@&&@&@@@&%&@&&&&&  ##(@#(.                              
                                   &@&&    &&@&&&&&%&&&&&&&@    #@@@@&&&&&&@&&&&&  &(&@&(                               
                                   [email protected]@&#   %&&&&&&&&@&&&&&&&    &@@@@&&&&&&&&&&&&     @&(                               
                                    @@%&, *%&&&@&&&&@&&&&&&&    &@@@@@&&&&@&&&&&&     &&(                               
                                     @&#& (@@&@@&&&&%&&&&&&     ,@@@@@&&&&&&&&&&&      &#                               
                                       .  #%%@@&&&&&&@&&&&#      &@@@@@&@&&&&&&&&      ,%                               
                                          /%@@@&&&&&&&&&&&       [email protected]@@@@@&&&&&&&&%                                       
*/



pragma solidity 0.8.13;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";



contract AdventRobots is ERC721A, PaymentSplitter, Ownable {
	using Strings for uint256;

	bool public paused;
	bool public revealed;
	bool public whitelistOnly;

	string private _unrevealedUriPrefix;
	string private _uriPrefix;
	string private _uriSuffix;

	uint256 public cost;
	uint256 public presaleCost;
	uint256 public maxSupply;
	uint256 public presaleSupply;
	uint256 public maxMintAmountPerAddress;

	bytes32 private _whitelistMerkleRoot;

	uint256 private constant _MAX_MINT_AMOUNT_RESET_INTERVAL = 1 hours;

	event Revealed();
	event PausedChanged(bool indexed oldPaused, bool indexed newPaused);
	event URIprefixChanged(string indexed oldURIprefix, string indexed newURIprefix);
	event UnrevealedURIprefixChanged(string indexed oldUnrevealedURIprefix, string indexed newUnrevealedURIprefix);
	event URIsuffixChanged(string indexed oldURIsuffix, string indexed newURIsuffix);
	event MaxSupplyChanged(uint256 indexed oldMaxSupply, uint256 indexed newMaxSupply);
	event PresaleSupplyChanged(uint256 indexed oldPresaleSupply, uint256 indexed newPresaleSupply);
	event MaxMintAmountPerAddressChanged(uint256 indexed oldMaxMintAmountPerAddress, uint256 indexed newMaxMintAmountPerAddress);
	event CostChanged(uint256 indexed oldCost, uint256 indexed newCost);
	event PresaleCostChanged(uint256 indexed oldPresaleCost, uint256 indexed newPresaleCost);
	event WhitelistMerkleRootChanged(bytes32 indexed oldWhitelistMerkleRoot, bytes32 indexed newWhitelistMerkleRoot);


	constructor(string memory initUnrevealedUriPrefix, bytes32 initWhitelistMerkleRoot, address[] memory payees, uint256[] memory shares) ERC721A("AdventRobots", "AR") PaymentSplitter(payees, shares) {
		paused = true;
		whitelistOnly = false;

		cost = 0.25 ether;
		presaleCost = 0.25 ether;
		maxSupply = 11_111;
		presaleSupply = 7_777;
		maxMintAmountPerAddress = 10;

		_whitelistMerkleRoot = initWhitelistMerkleRoot;

		_uriSuffix = ".json";
		_unrevealedUriPrefix = initUnrevealedUriPrefix;
	}


	function mint(uint256 amount) external payable {
		require(tx.origin == msg.sender, "AdventRobots: contract denied");
		require(!paused, "AdventRobots: minting is paused");
		require(!whitelistOnly, "AdventRobots: minting currently in presale, use presale mint");
		require(msg.value >= cost * amount, "AdventRobots: insufficient ether");
		require(_totalMinted() + amount <= maxSupply, "AdventRobots: max token supply exceeded");

		(uint256 intervalStart, uint256 numberOfMinted) = _getMintAmountData(_msgSender());
		bool newBatch = block.timestamp > intervalStart + _MAX_MINT_AMOUNT_RESET_INTERVAL;

		require(amount > 0 && amount <= (newBatch ? maxMintAmountPerAddress : maxMintAmountPerAddress - numberOfMinted), "AdventRobots: invalid mint amount");


		_safeMint(_msgSender(), amount);


		if (newBatch) {
			_setAux(_msgSender(), uint56(block.timestamp) << 8 | uint8(amount));
		} else {
			_setAux(_msgSender(), uint56(intervalStart) << 8 | uint8(numberOfMinted + amount));
		}
	}

	function presaleMint(uint256 amount, bytes32[] calldata merkleProof) external payable {
		require(tx.origin == msg.sender, "AdventRobots: contract denied");
		require(!paused, "AdventRobots: minting is paused");
		require(whitelistOnly, "AdventRobots: minting no longer restricted to presale, use public mint");
		require(msg.value >= presaleCost * amount, "AdventRobots: insufficient ether");

		(uint256 intervalStart, uint256 numberOfMinted) = _getMintAmountData(_msgSender());

		bool newBatch = block.timestamp > intervalStart + _MAX_MINT_AMOUNT_RESET_INTERVAL;
		uint256 newSupply = _totalMinted() + amount;

		require(amount > 0 && amount <= (newBatch ? maxMintAmountPerAddress : maxMintAmountPerAddress - numberOfMinted), "AdventRobots: invalid mint amount");
		require(newSupply <= presaleSupply, "AdventRobots: presale token supply exceeded");
		require(_isAddressWhitelisted(_msgSender(), merkleProof), "AdventRobots: invalid merkle proof");


		_safeMint(_msgSender(), amount);


		if (newBatch) {
			_setAux(_msgSender(), uint56(block.timestamp) << 8 | uint8(amount));
		} else {
			_setAux(_msgSender(), uint56(intervalStart) << 8 | uint8(numberOfMinted + amount));
		}

		if (newSupply >= presaleSupply) whitelistOnly = false;
	}

	function airDrop(address[] calldata addresses, uint8[] calldata amounts) external onlyOwner {
		require(addresses.length == amounts.length && addresses.length > 0, "AdventRobots: invalid function arguments");


		uint256 newSupply = _totalMinted();
		for (uint256 i = 0; i < amounts.length; i++) newSupply += amounts[i];

		require(newSupply <= maxSupply, "AdventRobots: max token supply exceeded");


		for (uint256 i = 0; i < addresses.length; i++) {
			_safeMint(addresses[i], amounts[i]);
		}

		if (whitelistOnly && newSupply >= presaleSupply) whitelistOnly = false;
	}

	function flipPausedState() external onlyOwner {
		emit PausedChanged(paused, !paused);		

		paused = !paused;
	}

	function reveal(string memory initUriPrefix) external onlyOwner {
		revealed = true;

		emit URIprefixChanged(_uriPrefix, initUriPrefix);
		emit Revealed();

		_uriPrefix = initUriPrefix;
	}

	function release(address payable account) public override {
		require(account == _msgSender(), "AdventRobots: caller is not the specified payee");

		super.release(account);
	}

	function tokenURI(uint256 tokenID) public view override returns(string memory) {
		require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

		if (!revealed) return _unrevealedUriPrefix;

		string memory currentBaseURI = _baseURI();

		return bytes(currentBaseURI).length > 0 ? string( abi.encodePacked(currentBaseURI, tokenID.toString(), _uriSuffix) ) : "";
	}

	function walletOfOwner(address account) external view returns(uint256[] memory) {
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

	function getMintsOfAddress(address account) external view returns(uint256) {
		return _numberMinted(account);
	}

	function getMaxMintAmountForAddress(address account) external view returns(uint256) {
		(uint256 intervalStart, uint256 numberOfMinted) = _getMintAmountData(account);

		if (block.timestamp > intervalStart + _MAX_MINT_AMOUNT_RESET_INTERVAL) {
			return maxMintAmountPerAddress;
		} else {
			return maxMintAmountPerAddress - numberOfMinted;
		}
	}


	function setURIprefix(string memory newPrefix) external onlyOwner {
		emit URIprefixChanged(_uriPrefix, newPrefix);

		_uriPrefix = newPrefix;
	}

	function setUnrevealedURIprefix(string memory newUnrevealedURI) external onlyOwner {
		emit UnrevealedURIprefixChanged(_unrevealedUriPrefix, newUnrevealedURI);

		_unrevealedUriPrefix = newUnrevealedURI;
	}

	function setURIsuffix(string memory newSuffix) external onlyOwner {
		emit URIsuffixChanged(_uriSuffix, newSuffix);

		_uriSuffix = newSuffix;
	}

	function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
		require(newMaxSupply > _totalMinted() && newMaxSupply > presaleSupply, "AdventRobots: invalid amount");

		emit MaxSupplyChanged(maxSupply, newMaxSupply);

		maxSupply = newMaxSupply;
	}

	function setPresaleSupply(uint256 newPresaleSupply) external onlyOwner {
		require(newPresaleSupply > _totalMinted() && newPresaleSupply < maxSupply, "AdventRobots: invalid amount");

		emit PresaleSupplyChanged(presaleSupply, newPresaleSupply);

		presaleSupply = newPresaleSupply;
	}

	function setMaxMintAmountPerAddress(uint256 newMaxMintAmountPerAddress) external onlyOwner {
		emit MaxMintAmountPerAddressChanged(maxMintAmountPerAddress, newMaxMintAmountPerAddress);

		maxMintAmountPerAddress = newMaxMintAmountPerAddress;
	}

	function setCost(uint256 newCost) external onlyOwner {
		emit CostChanged(cost, newCost);

		cost = newCost;
	}

	function setPresaleCost(uint256 newPresaleCost) external onlyOwner {
		emit PresaleCostChanged(presaleCost, newPresaleCost);

		presaleCost = newPresaleCost;
	}

	function setWhitelistMerkleRoot(bytes32 newWhitelistMerkleRoot) external onlyOwner {
		emit WhitelistMerkleRootChanged(_whitelistMerkleRoot, newWhitelistMerkleRoot);

		_whitelistMerkleRoot = newWhitelistMerkleRoot;
	}


	function _baseURI() internal view override returns(string memory) {
		return _uriPrefix;
	}

	function _startTokenId() internal pure override returns(uint256) {
		return 1;
	}

	function _isAddressWhitelisted(address account, bytes32[] calldata merkleProof) internal view returns(bool) {
		if (account == owner()) return true;

		bytes32 leaf = keccak256( abi.encodePacked(account) );
		bool whitelisted = MerkleProof.verify(merkleProof, _whitelistMerkleRoot, leaf);

		return whitelisted;
	}

	function _getMintAmountData(address account) internal view returns(uint256, uint256) {
		uint64 aux = _getAux(account);

		return ( uint256(aux >> 8), uint256(uint8(aux)) );
	}
}