pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ..................................................
// ..................................................
// ..................-/+syyyo+:-.....................
// ...............-ohddddmmddddho/...................
// ..............oddmmmdddddddmdhhy:.................
// .............ommdmmddmmmddddddhdd/................
// .............ddddmmddmdddddddddddh/...............
// .............//oyyhhhdddmmmddmdddddhs/-...........
// ..............`.:-......-::+yhddddhddy+...........
// .............---s...-y:::.  -+o+///:-.............
// ..........-``.``s----:hddy../hdh/:................
// ://++osyosy+`.``o.``.+dddh:.+hdd/-................
// N:++os/+oNmo:  `/:````.::.``..-.`-................
// h/yo+/+:NNyo/.` .+   ````.. ```` -................
// +hNhohhoNN/s.o   s      `  ``   -N++-.............
// y+NNmmhsNN:+.o`  ::   `...```  `dN+ymds/..........
// Md+dNNyyMN:+..+/ `o`   `    `  hNd:mmmNNm/........
// MMNodNsyMN:++..:+-.o.        `hNN+smhNNNNho:......
// mNMNshhsds/:ho.../+.//.     -dNNh/m++ohNmssso+....
// sydMNys++++:+ys-..-+o:hhoy++dNNm:yo++hhNhssos/o:..
// s/:+mNs+sos:.yyy-..soh+:shs-mNN+oysyoo/dyyyos//o:.
// ooooodN-dhso-/yyy++o+:oyys-:Nhy/mmNNddhyhhssssssy:
//  	 ____                                  _ 
//  	/ ___|  __ _ _ __ ___  _   _ _ __ __ _(_)
//  	\___ \ / _` | '_ ` _ \| | | | '__/ _` | |
//  	 ___) | (_| | | | | | | |_| | | | (_| | |
//  	|____/ \__,_|_| |_| |_|\__,_|_|  \__,_|_|


contract KatanaNSamurai is ERC721, Ownable {

	using SafeMath for uint256;
	uint public constant MAX_PUNKS = 10000;
	uint public constant MAX_GIVEAWAYS = 500; 
	uint public constant PRICE = 50000000000000000; // 0.05 ETH
	uint public numGiveaways = 0;
	bool public hasShogunateStarted = false;
	bool public hasSaleStarted = false;

	mapping (uint256 => string) public shogunateBelong;
	mapping (string => uint256) public shogunateQuantity;
	mapping (string => bool) public validShogunate;

	event mintEvent(address owner, uint256 numPurchase, uint256 totalSupply);
	event shogunateEvent(address owner, uint256 tokenId, string from, string to);

	constructor() ERC721("Katana N Samurai", "KNS") {
		setBaseURI("http://api.katanansamurai.art/Metadata/");
	}

	// Marketing giveaway
	function giveawayMintSamurai(address _to, uint256 numPurchase) public onlyOwner{
		require(totalSupply() < MAX_PUNKS, "Sold out!");
		require(numPurchase > 0 && numPurchase <= 50, "You can mint minimum 1, maximum 50 punks.");
		require(totalSupply().add(numPurchase) <= MAX_PUNKS, "Exceeds MAX_PUNKS.");
		require(numGiveaways.add(numPurchase) <= MAX_GIVEAWAYS, "Exceeds the MAX_GIVEAWAYS.");

		for (uint i = 0; i < numPurchase; i++) {
			uint mintIndex = totalSupply().add(1);
			_safeMint(_to, mintIndex);
		}

		numGiveaways = numGiveaways.add(numPurchase);
		emit mintEvent(_to, numPurchase, totalSupply());
	}

	// Mint NFT
	function mintSamurai(uint256 numPurchase) public payable {
		require(hasSaleStarted == true, "Sale hasn't started.");
		require(totalSupply() < MAX_PUNKS, "Sold out!");
		require(numPurchase > 0 && numPurchase <= 50, "You can mint minimum 1, maximum 50 punks.");
		require(totalSupply().add(numPurchase) <= MAX_PUNKS, "Exceeds MAX_PUNKS.");
		require(msg.value >= PRICE.mul(numPurchase), "Ether value sent is below the price.");

		for (uint i = 0; i < numPurchase; i++) {
			uint mintIndex = totalSupply().add(1);
			_safeMint(msg.sender, mintIndex);
		}

		emit mintEvent(msg.sender, numPurchase, totalSupply());
	}

	function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
		uint256 tokenCount = balanceOf(_owner);
		
		if (tokenCount == 0) {
			// Return an empty array
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = 0; index < tokenCount; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}

	// Add valid shogunate name
	function addShogunateName(string memory name) public onlyOwner {
		validShogunate[name] = true;
	}

	// Delete valid shogunate name
	function deleteShogunateName(string memory name) public onlyOwner {
		validShogunate[name] = false;
	}

	// Change clothes and shogunate
	function shogunate(uint256 _tokenId, string memory _from, string memory _to) public {
		require(hasShogunateStarted == true, "Shogunate hasn't started.");
		require(_tokenId <= totalSupply(), "TokenId out of totalSupply.");
		require(ownerOf(_tokenId) == msg.sender, "Not the tokenId owner.");

		if (keccak256(abi.encodePacked(_from)) == keccak256(abi.encodePacked("None"))) { // Join shogunate
			require(keccak256(abi.encodePacked(shogunateBelong[_tokenId])) == keccak256(abi.encodePacked("")), "Shogunate is not None.");
			require(validShogunate[_to] == true, "Shogunate name is invalid.");
			
			shogunateBelong[_tokenId] = _to;
			shogunateQuantity[_to] = shogunateQuantity[_to].add(1);
		} else { // Change shogunate 
			require(keccak256(abi.encodePacked(shogunateBelong[_tokenId])) == keccak256(abi.encodePacked(_from)), "Shogunate verification failed.");
			require(validShogunate[_to] == true, "Shogunate name is invalid.");
			
			shogunateBelong[_tokenId] = _to;
			shogunateQuantity[_to] = shogunateQuantity[_to].add(1);
			shogunateQuantity[_from] = shogunateQuantity[_from].sub(1);
		}
		
		emit shogunateEvent(msg.sender, _tokenId, _from, _to);
	}

	function setBaseURI(string memory baseURI) public onlyOwner {
		_setBaseURI(baseURI);
	}

	function startShogunate() public onlyOwner {
		hasShogunateStarted = true;
	}

	function pauseShogunate() public onlyOwner {
		hasShogunateStarted = false;
	}
	
	function startSale() public onlyOwner {
		hasSaleStarted = true;
	}

	function pauseSale() public onlyOwner {
		hasSaleStarted = false;
	}

	function withdrawAll() public payable onlyOwner {
		require(payable(msg.sender).send(address(this).balance));
	}
}