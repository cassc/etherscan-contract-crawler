// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC721ABurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
      _____                    _____                    _____                            _____                    _____                _____                    _____                _____                    _____                    _____          
     /\    \                  /\    \                  /\    \                          /\    \                  /\    \              /\    \                  /\    \              /\    \                  /\    \                  /\    \         
    /::\    \                /::\____\                /::\    \                        /::\    \                /::\    \            /::\    \                /::\    \            /::\    \                /::\    \                /::\    \        
    \:::\    \              /:::/    /               /::::\    \                      /::::\    \              /::::\    \           \:::\    \              /::::\    \           \:::\    \              /::::\    \              /::::\    \       
     \:::\    \            /:::/    /               /::::::\    \                    /::::::\    \            /::::::\    \           \:::\    \            /::::::\    \           \:::\    \            /::::::\    \            /::::::\    \      
      \:::\    \          /:::/    /               /:::/\:::\    \                  /:::/\:::\    \          /:::/\:::\    \           \:::\    \          /:::/\:::\    \           \:::\    \          /:::/\:::\    \          /:::/\:::\    \     
       \:::\    \        /:::/____/               /:::/__\:::\    \                /:::/__\:::\    \        /:::/__\:::\    \           \:::\    \        /:::/__\:::\    \           \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
       /::::\    \      /::::\    \              /::::\   \:::\    \              /::::\   \:::\    \       \:::\   \:::\    \          /::::\    \      /::::\   \:::\    \          /::::\    \      /::::\   \:::\    \       \:::\   \:::\    \   
      /::::::\    \    /::::::\    \   _____    /::::::\   \:::\    \            /::::::\   \:::\    \    ___\:::\   \:::\    \        /::::::\    \    /::::::\   \:::\    \        /::::::\    \    /::::::\   \:::\    \    ___\:::\   \:::\    \  
     /:::/\:::\    \  /:::/\:::\    \ /\    \  /:::/\:::\   \:::\    \          /:::/\:::\   \:::\    \  /\   \:::\   \:::\    \      /:::/\:::\    \  /:::/\:::\   \:::\    \      /:::/\:::\    \  /:::/\:::\   \:::\    \  /\   \:::\   \:::\    \ 
    /:::/  \:::\____\/:::/  \:::\    /::\____\/:::/__\:::\   \:::\____\        /:::/__\:::\   \:::\____\/::\   \:::\   \:::\____\    /:::/  \:::\____\/:::/  \:::\   \:::\____\    /:::/  \:::\____\/:::/__\:::\   \:::\____\/::\   \:::\   \:::\____\
   /:::/    \::/    /\::/    \:::\  /:::/    /\:::\   \:::\   \::/    /        \:::\   \:::\   \::/    /\:::\   \:::\   \::/    /   /:::/    \::/    /\::/    \:::\  /:::/    /   /:::/    \::/    /\:::\   \:::\   \::/    /\:::\   \:::\   \::/    /
  /:::/    / \/____/  \/____/ \:::\/:::/    /  \:::\   \:::\   \/____/          \:::\   \:::\   \/____/  \:::\   \:::\   \/____/   /:::/    / \/____/  \/____/ \:::\/:::/    /   /:::/    / \/____/  \:::\   \:::\   \/____/  \:::\   \:::\   \/____/ 
 /:::/    /                    \::::::/    /    \:::\   \:::\    \               \:::\   \:::\    \       \:::\   \:::\    \      /:::/    /                    \::::::/    /   /:::/    /            \:::\   \:::\    \       \:::\   \:::\    \     
/:::/    /                      \::::/    /      \:::\   \:::\____\               \:::\   \:::\____\       \:::\   \:::\____\    /:::/    /                      \::::/    /   /:::/    /              \:::\   \:::\____\       \:::\   \:::\____\    
\::/    /                       /:::/    /        \:::\   \::/    /                \:::\   \::/    /        \:::\  /:::/    /    \::/    /                       /:::/    /    \::/    /                \:::\   \::/    /        \:::\  /:::/    /    
 \/____/                       /:::/    /          \:::\   \/____/                  \:::\   \/____/          \:::\/:::/    /      \/____/                       /:::/    /      \/____/                  \:::\   \/____/          \:::\/:::/    /     
                              /:::/    /            \:::\    \                       \:::\    \               \::::::/    /                                    /:::/    /                                 \:::\    \               \::::::/    /      
                             /:::/    /              \:::\____\                       \:::\____\               \::::/    /                                    /:::/    /                                   \:::\____\               \::::/    /       
                             \::/    /                \::/    /                        \::/    /                \::/    /                                     \::/    /                                     \::/    /                \::/    /        
                              \/____/                  \/____/                          \/____/                  \/____/                                       \/____/                                       \/____/                  \/____/         


 * @title The Estates ERC721ABurnable
 * Standard ERC721ABurnable with burn to breed functionality, mint to stake and breeding from staked
 */

interface IStaking {
	function stakeMint(uint256 startTokenId, address user, uint256 _vol) external;
	function setStake(uint64 tokenId, address user) external;
	function setGroupStake(uint64[] memory tokenId, address user) external;
}

interface IEquity {
    function burn(address _from, uint256 _amount) external;
}

contract Estate is ERC721ABurnable, Ownable {
	using Address for address;
	using ECDSA for bytes32;
	using Strings for uint256;

	IEquity public equityContract;
	IStaking public stakingContract;

	// || SUPPLY ||
	// total that will ever be generated including all four generations, and including those that will be burned 
	uint256 public maxGenesis = 8888;
	// how much will be sold in each minting batch
	uint256 public maxBatch = 2222;

	// || MINT LIMITS ||
	// max mints in total per wallet per batch
	uint public ADDRESS_MAX_MINTS = 6;
	// max OG and WL mints per wallet per batch
	uint public OG_MAX_MINTS = 2;
	uint public PSL_MAX_MINTS = 1;
	// mappings of batch - address - number minted
	mapping (uint256 => mapping (address => uint256)) public numberOfWLMintsOnAddress;	
	mapping (uint256 => mapping (address => uint256)) public numberOfPublicMintsOnAddress;

	// || SALE STATE CONFIG ||
	// wallet used to sign private mints
	address public whitelistAdmin;
	// used to limit where public can be minted from
	uint256 public publicSaleKey;
	// which stages of sale are active
	bool public WLSaleActive;
	bool public publicSaleActive;
	// 1-4 mints for the entire collection
	uint256 public mintingPhase = 1;
	// Pricing
	uint256 public WLPrice = 0.15 ether;
	uint256 public PublicPrice = 0.2 ether;

	// || UPGRADING (breeding) ||
	bool public upgradesActive;
	event Upgraded(uint256 newEstate, uint256 parent1, uint256 parent2);
	uint256 baseUpgradeCost = 1800 ether;
	/**
	 * @dev Keeps track of gen of each Estate because breeding won't be sequential
	 * 0 - Gen1
	 * 1 - Gen2
	 * 2 - Gen3
	 * 3 - Gen4
	 */
	mapping(uint256 => uint256) public estateGeneration;

	// || META CONFIG ||
	string private baseURI;
	string private contURI;

	event Donation(uint256 amount);

	constructor(
		address _whitelistAdmin
	) ERC721A("The Estates", "ESTATES") {
		whitelistAdmin = _whitelistAdmin;
	}

	/** *********************************** **/
	/** ********* Internal Functions ****** **/
	/** *********************************** **/
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

	modifier estateOwner(uint256 estateId) {
		require(ownerOf(estateId) == msg.sender, "Cannot interact with a Estates you do not own");
		_;
	}

	function _isvalidsig(
		bytes32 data,
		bytes memory signature,
		address signerAddress
	) private pure returns (bool) {
		return
			data.toEthSignedMessageHash().recover(signature) == signerAddress;
	}

	// override start token to 1.
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}		

	/** *********************************** **/
	/** ********* Minting Functions ******* **/
	/** *********************************** **/

	// used to mint Estate #1 to allow Opensea setup before WL mints, and for airdrop if necessary
	function adminMint (address _address, uint256 _vol) external onlyOwner {
		require(_totalMinted() + _vol <= maxGenesis,"Purchase would exceed max supply of Genesis Estates");
		require(_totalMinted() + _vol <= maxBatch*mintingPhase,"Purchase would exceed max supply of Estates in this phase.");
		_safeMint(_address, _vol);
	}

	function donate (uint256 _amount) external payable {
		require(msg.value == 0.0001 ether*_amount);	
		emit Donation(_amount);
	}

	// option 0 = OG
	// option 1 = PSL
	// privateMint is used by two types of WL, OG (2 mints each), PSL (1 mint).
	function privateMint(
		address _contractAddress, // address of this contract
		uint256 _vol, //how many to mint
		uint256 _option, // whether i am OG '0' or PSL '1'
		bool _mintToStake, // whether to stake immediately during minting
		bytes memory _signature
	) external payable {
		require(isContract(msg.sender) == false, "Cannot mint from contract");
		require(WLSaleActive, "Presale must be active to mint");
		require(WLPrice * _vol == msg.value,"Ether value sent is not correct");
		if (_option == 0){
			// can mint 2		
			require(numberOfWLMintsOnAddress[mintingPhase][msg.sender] + _vol <= OG_MAX_MINTS , "Already minted your max OG WL amount");
		} else {
			// can mint 1
			require(numberOfWLMintsOnAddress[mintingPhase][msg.sender] + _vol <= PSL_MAX_MINTS , "Already minted your max PSL WL amount");
		}
		numberOfWLMintsOnAddress[mintingPhase][msg.sender] += _vol;
		require(_totalMinted() + _vol <= maxGenesis,"Purchase would exceed max supply of Genesis Estates");
		require(_totalMinted() + _vol <= maxBatch*mintingPhase,"Purchase would exceed max supply of Estates in this phase.");	
		
		require(
			_isvalidsig(
				keccak256(
					abi.encodePacked(
						_contractAddress,
						msg.sender,
						_option
					)
				),
				_signature,
				whitelistAdmin
			),
			"Signature was not valid"
		);

		if (_mintToStake){
			// mint directly to the staking contract and assign token to actual owner
			_safeMint(address(stakingContract),_vol);
			stakingContract.stakeMint(_currentIndex-_vol, msg.sender, _vol);
		} else {
			_safeMint(msg.sender, _vol);
		}
		
	}

	// Public fixed price mint to capture any WL mint that didn't sell..
	function publicMint(uint256 _vol, bool _mintToStake, uint256 callerPublicSaleKey)
		external
		payable
	{
		require(isContract(msg.sender) == false, "Cannot mint from contract");
		require(publicSaleActive, "Public sale is not yet active");
		require(publicSaleKey == callerPublicSaleKey,"called with incorrect public sale key");
		require(_totalMinted() + _vol <= maxGenesis,"Purchase would exceed max supply of Genesis Estates");
		require(_totalMinted() + _vol <= maxBatch*mintingPhase,"Purchase would exceed max supply of Estates in this phase.");	
		require(numberOfPublicMintsOnAddress[mintingPhase][msg.sender] + numberOfWLMintsOnAddress[mintingPhase][msg.sender] + _vol <= ADDRESS_MAX_MINTS, "Amount to be minted would exceed maximum per address.");
		require(PublicPrice * _vol == msg.value,"Eth amount sent is not enough.");
		numberOfPublicMintsOnAddress[mintingPhase][msg.sender] += _vol;
		if (_mintToStake){
			_safeMint(address(stakingContract),_vol);
			stakingContract.stakeMint(_currentIndex-_vol, msg.sender, _vol);
		} else {
			_safeMint(msg.sender, _vol);
		}
	}

	/** *********************************** **/
	/** ********* Upgrading / 'Breeding'  ********* **/
	/** *********************************** **/

	// Generations breakdown
	// Gen 2 costs 1800 to create
	// Gen 3 costs 4320 to create
	// Gen 4 costs 10800 to create

	// WARNING: CALLING THIS FUNCTION WILL PERMANENTLY DESTROY TWO ESTATES NFTs
	function Upgrade(uint256 estate1, uint256 estate2) external estateOwner(estate1) estateOwner(estate2) {
		require(upgradesActive, "Upgrading is not currently active");
		require(estateGeneration[estate1] == estateGeneration[estate2], "Two estates of the same generation required to upgrade");
		require(estateGeneration[estate1] < 3, "4th generation estates cannot be upgraded.");
		uint burnprice = baseUpgradeCost;
		if (estateGeneration[estate1] == 1) {
			burnprice = burnprice*12/5;
		}
		if (estateGeneration[estate1] == 2) {
			burnprice = burnprice*6;
		}
		equityContract.burn(msg.sender,burnprice);
		_burn(estate1);
		_burn(estate2);
		// record the generation of the baby, required for staking and breeding 
		estateGeneration[_currentIndex] = estateGeneration[estate1]+1;
		_safeMint(msg.sender, 1);
		emit Upgraded(_currentIndex-1, estate1, estate2);
	}

	/** *********************************** **/
	/** ********* Staking  ********* **/
	/** *********************************** **/	

	function Stake(uint64 tokenId) external {
		stakingContract.setStake(tokenId, msg.sender);
		safeTransferFrom(msg.sender,address(stakingContract),uint256(tokenId));

	}

    function groupStake(uint64[] memory tokenIds) external {
        stakingContract.setGroupStake(tokenIds, msg.sender);
		for (uint64 i = 0; i < tokenIds.length; ++i) {
			safeTransferFrom(msg.sender,address(stakingContract),uint256(tokenIds[i]));
        }
    }	

	/** *********************************** **/
	/** ********* Sale State Functions ******* **/
	/** *********************************** **/

	// view sale states
	function getSaleState() public view returns (bool, bool, uint256) {
		return (WLSaleActive, publicSaleActive, mintingPhase);
	}

	// SALE OWNER FUNCTIONS

	// set sale states
	function togglePrivateSale(bool state) external onlyOwner {
		WLSaleActive = state;
	}

	function togglePublicSale(uint256 saleKey, bool state) external onlyOwner {
		publicSaleActive = state;
		publicSaleKey = saleKey;
	}		

	// mint phases broken into 4, with 2222 supply cap each
	function setMintingPhase(uint256 newPhase) external onlyOwner {
		require(newPhase <= 4 && newPhase >= 1, "Wrong minting phase");
		mintingPhase = newPhase;
	}	

	// set the wallet used to sign WL mints
	function setWLAdmin(address _whitelistAdmin) external onlyOwner {
		whitelistAdmin = _whitelistAdmin;
	}

	// Permanently Lower Supply in event of non-mint out
	function lowerSupply(uint256 newSupply) external onlyOwner {
		require(newSupply < maxGenesis, "Cannot increase supply of tokens");
		maxGenesis = newSupply;
	}

	// Change the max batch size to alter minting phase size
	function setMaxBatch(uint256 newBatchSize) external onlyOwner {
		maxBatch = newBatchSize;
	}	

	function setAddressMaxMints(uint256 newAddressMaxMints) external onlyOwner {
		ADDRESS_MAX_MINTS = newAddressMaxMints;
	}

	function setOGMaxMints(uint256 newWLMaxMints) external onlyOwner {
		OG_MAX_MINTS = newWLMaxMints;
	}

	// adjust WL price
	function setWLPrice(uint256 newPrice) external onlyOwner {
		WLPrice = newPrice;
	}

	// adjust WL price
	function setPublicPrice(uint256 newPrice) external onlyOwner {
		PublicPrice = newPrice;
	}				

	/** *********************************** **/
	/** ********* Other Owner Functions ********* **/
	/** *********************************** **/

	// enable or disable breeding
	function toggleUpgrades(bool state) external onlyOwner {
		upgradesActive = state;
	}

	function withdraw() external onlyOwner {
		require(address(this).balance > 0, "No balance to withdraw");
		uint256 contractBalance = address(this).balance;
        _withdraw(address(0x92654837dAF31303D87d39BE71b4565088E875B2), contractBalance * 50/100);
        _withdraw(address(0xA32f146226EF206137a090E6481EF283Aa9DbADB), contractBalance * 50/100);		
	}

	function _withdraw(address _address, uint256 _amount) private {
		(bool success, ) = _address.call{value: _amount}("");
		require(success, "Transfer failed.");
	}

	function setBaseURI(string memory uri) public onlyOwner {
		baseURI = uri;
	}

	function setContractURI(string memory uri) public onlyOwner {
		contURI = uri;
	}

	// Set Staking contract
    function setStakingContract(address address_) external onlyOwner {
        stakingContract = IStaking(address_);
    }

	// Set $Equity contract
    function setEquityContract(address address_) external onlyOwner {
        equityContract = IEquity(address_);
    }	

	/** *********************************** **/
	/** ********* View Functions ********* **/
	/** *********************************** **/

	//base url for returning info about an individual adventurer
	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

	//base url for returning info about the token collection contract
	function contractURI() external view returns (string memory) {
		return contURI;
	}

	/* Added to return all token ids held by owner */
	// never call on-chain, very expensive!
	function tokensOfOwner(address owner) external view returns (uint256[] memory) {
		unchecked {
			uint256 tokenIdsIdx;
			address currOwnershipAddr;
			uint256 tokenIdsLength = balanceOf(owner);
			uint256[] memory tokenIds = new uint256[](tokenIdsLength);
			TokenOwnership memory ownership;
			for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
				ownership = _ownerships[i];
				if (ownership.burned) {
					continue;
				}
				if (ownership.addr != address(0)) {
					currOwnershipAddr = ownership.addr;
				}
				if (currOwnershipAddr == owner) {
					tokenIds[tokenIdsIdx++] = i;
				}
			}
			return tokenIds;
		}
	}

	function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
		return _ownershipOf(tokenId);
	}	

	function numberMinted(address owner) public view returns (uint256) {
		return _numberMinted(owner);
	}

}