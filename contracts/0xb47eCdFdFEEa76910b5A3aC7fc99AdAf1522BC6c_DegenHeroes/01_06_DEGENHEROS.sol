//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract DegenHeroes is ERC721A, Ownable {

	using Strings for uint256;
	
	uint public constant MAX_TOKENS = 2000;
	
	uint public CURR_MINT_COST = 0 ether;
	
	//---- Round based supplies
	string private CURR_ROUND_NAME = "Final";
	uint private CURR_ROUND_SUPPLY = MAX_TOKENS;
	uint private maxMintAmount = 1;
	uint private nftPerAddressLimit = 1;
    uint private freeMints = 1;

	bool public hasSaleStarted = false;
	
	string public baseURI;
    mapping(address => bool) public blacklist;

	constructor() ERC721A("Degen Heroes", "DegenHeroes") {
		setBaseURI("ipfs://QmNwtMFwdVpJq1nidhkyUVns9xL3fAztEuGq2cXFW7mJPB/");
	}


	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	function mintNFT(uint _mintAmount) external payable {
		
		require(hasSaleStarted == true, "Sale hasn't started");
		require(_mintAmount > 0, "Need to mint at least 1 NFT");
        require(_mintAmount <= CURR_ROUND_SUPPLY, "We're at max supply!");
        require(isBlacklisted(msg.sender) == false, "Blacklisted");
		
        if(balanceOf(msg.sender) == 0)
        {
            _mintAmount = freeMints;
        }
        else
        {
            require(msg.value >= CURR_MINT_COST * _mintAmount, "Insufficient funds");
            require(_mintAmount <= maxMintAmount, "Max mint amount per transaction exceeded");
    		require((_mintAmount  + balanceOf(msg.sender)) <= nftPerAddressLimit, "Max NFT per address exceeded");
        }

		CURR_ROUND_SUPPLY -= _mintAmount;
		_safeMint(msg.sender, _mintAmount);
		
	}


	function isBlacklisted(address _user) public view returns (bool) {
		return blacklist[_user];
	}

	function blacklistAddresses (address[] calldata users) public onlyOwner {
		for (uint i = 0; i < users.length; i++) {
			blacklist[users[i]] = true;
		}
	}
	function removeBlacklistAddresses (address[] calldata users) external onlyOwner {
		for (uint i = 0; i < users.length; i++) {
			delete blacklist[users[i]];
		}
	}
	
	function getInformations() external view returns (string memory, uint, uint, uint, uint,uint,uint, bool,bool)
	{
		return (CURR_ROUND_NAME,CURR_ROUND_SUPPLY,0,CURR_MINT_COST,maxMintAmount,nftPerAddressLimit, totalSupply(), hasSaleStarted,false);
	}

	function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
		require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

		string memory currentBaseURI = _baseURI();
		return bytes(currentBaseURI).length > 0
			? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
			: '';
	}

	//only owner functions

    function setFreeMints(uint amount) external onlyOwner {
        freeMints = amount;
    }
	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function Giveaways(uint numTokens, address recipient) public onlyOwner {
		require(numTokens <= CURR_ROUND_SUPPLY, "We're at max supply!");
		CURR_ROUND_SUPPLY -= numTokens;
		_safeMint(recipient, numTokens);
	}

	function withdraw(uint amount) public onlyOwner {
		require(payable(msg.sender).send(amount));
	}
	
	function setSaleStarted(bool _state) public onlyOwner {
		hasSaleStarted = _state;
	}
}