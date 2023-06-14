// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./derived/OwnableClone.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./legacy/ERC721.sol";

import "./HasSecondarySalesFees.sol";
import "./sales/Saleable.sol";

contract infinityTokensPublic is ERC721, OwnableClone, HasSecondarySaleFees, Saleable {
	using SafeMath for uint256;

	uint256 NFTIndex;
	address public factoryContract;

	struct Attributes {
		string name;
		string value;
	}

	mapping(address => bool) public authorisedCaller;
	
	mapping(uint256 => bool[100]) artworkSlotFilled;

	mapping(uint256 => string[100]) hashIPFSMemory;
	mapping(uint256 => string[100]) hashArweaveMemory;
	mapping(uint256 => string[100]) artworkTypeMemory;

	mapping(uint256 => string) mouldName;
	mapping(uint256 => string) mouldDescription;
	mapping(uint256 => Attributes[]) mouldAttributes;

	mapping(uint256 => uint256) editionSizeMemory;
	mapping(uint256 => uint256) editionNumberMemory;
 	mapping(uint256 => uint256) redemptionMouldMemory;
	mapping(uint256 => uint64)  redemptionExpirationMouldMemory;
 	mapping(uint256 => uint256) redemptionMemory;
	mapping(uint256 => uint256) evolutionLevelMemory;
	
 	mapping(uint256 => uint256) totalCreated;
	mapping(uint256 => uint256) totalMinted;
  
	mapping (uint256 => bool) mintingActive;
	
	string public fileIPFSReferenceURL;
    string public fileArweaveReferenceURL;

    string multiURI1;
    string multiURI2;
    string multiURI3;
    
    address public artistWalletAddress;
    address public factoryAddressRef;

    function addressToString(address input) internal pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(input)));
    }

	constructor(string memory _name, string memory _symbol, address factoryAddress, address contractCreator) ERC721(_name, _symbol) {
        _init(factoryAddress, contractCreator);
    }

    function init(string memory _name, string memory _symbol, address factoryAddress, address contractCreator) public {
        require(factoryContract == address(0), "already initialized");
        OwnableClone.init(factoryAddress);
        ERC721.init(_name, _symbol);
        _init(factoryAddress, contractCreator);
        
    }

    function _init(address factoryAddress, address contractCreator) internal {
        updateURI(string(abi.encodePacked("https://infinitytokens.azurewebsites.net/api/HttpTrigger?artContract=",addressToString(address(this)),"&id=")));
        NFTIndex = 1;
        fileIPFSReferenceURL = "https://ipfs.infura.io/ipfs/";
        fileArweaveReferenceURL = "https://arweave.net/";
        updateMultiURI("https://infinitytokensmulti.azurewebsites.net/api/HttpTrigger?artContract=", "&id=", "&artworkIndex=");
        factoryContract = factoryAddress;
        artistWalletAddress = contractCreator;
    }

	event NewNFTMouldCreated(uint256 NFTIndex);
	event NewNFTCreatedFor(uint256 NFTId, uint256 tokenId, address recipient);
	event NewArtworkAdded(uint256 mouldToUpdate, string IPFSHash, string arweaveHash, string artworkType, uint256 artworkIndex);
	event EvolvedNFT(uint256 NFTId, uint256 currentEvolutionLevel);
	event RedeemNFT(uint256 tokenId, string redemptionNote);
	event CloseNFTWindow(uint256 NFTId);
	
	modifier authorised() {
		require(authorisedCaller[msg.sender] || msg.sender == owner(), "VendingMachine: Not authorised to execute");
		_;
	}

	function setCaller(address _caller, bool _value) external onlyOwner {
		authorisedCaller[_caller] = _value;
	}

	function createNFTMould(
		string memory artworkHashIPFS,
		string memory artworkHashArweave,
		string memory artworkType,
		string memory name,
		string memory description,
		Attributes[] memory attributes,
		uint256 editionSize,
        uint256 totalRedemptions,
		uint64 redemptionExpiration,
		address payable[] memory royaltyAddress,
		uint256[] memory royaltyBps) 
		public onlyOwner {
		    
		mintingActive[NFTIndex] = true;
		
		hashIPFSMemory[NFTIndex][1] = artworkHashIPFS;
		hashArweaveMemory[NFTIndex][1] = artworkHashArweave;
		artworkTypeMemory[NFTIndex][1] = artworkType;

		mouldName[NFTIndex] = name;
		mouldDescription[NFTIndex] = description;
		while(mouldAttributes[NFTIndex].length < attributes.length) {
			mouldAttributes[NFTIndex].push();
			uint256 idx = mouldAttributes[NFTIndex].length - 1;
			mouldAttributes[NFTIndex][idx] = attributes[idx];
		}
		
		editionSizeMemory[NFTIndex] = editionSize;
        redemptionMouldMemory[NFTIndex] = totalRedemptions;
		redemptionExpirationMouldMemory[NFTIndex] = redemptionExpiration;
		
		artworkSlotFilled[NFTIndex][1] = true;
		evolutionLevelMemory[NFTIndex] = 1;
		
		royaltyAddressMemory[NFTIndex] = royaltyAddress;
		royaltyMemory[NFTIndex] = royaltyBps;
		
		totalCreated[NFTIndex] = 0;
		totalMinted[NFTIndex] = 0;

		emit NewNFTMouldCreated(NFTIndex);
			
		NFTIndex = NFTIndex + 1;
	}

    function addFile(uint256 mouldToUpdate, string memory hashIPFS, string memory hashArweave, string memory artworkType, uint256 artworkIndex) public onlyOwner{
        require(artworkSlotFilled[mouldToUpdate][artworkIndex] == false);
        
        hashIPFSMemory[mouldToUpdate][artworkIndex] = hashIPFS;
        hashArweaveMemory[mouldToUpdate][artworkIndex] = hashArweave;
        artworkTypeMemory[mouldToUpdate][artworkIndex] = artworkType;
            
        artworkSlotFilled[mouldToUpdate][artworkIndex] = true;
        
        emit NewArtworkAdded(mouldToUpdate, hashIPFS, hashArweave, artworkType, artworkIndex);
    }
    
    function evolveNFT(uint256 NFTId) public authorised {
        uint256 currentEvolutionLevel = evolutionLevelMemory[NFTId];
        evolutionLevelMemory[NFTId] = currentEvolutionLevel + 1;
        
        emit EvolvedNFT(NFTId, currentEvolutionLevel);
    }

    function devolveNFT(uint256 NFTId) public authorised {
        uint256 currentEvolutionLevel = evolutionLevelMemory[NFTId];
        evolutionLevelMemory[NFTId] = currentEvolutionLevel - 1;
    }

    function setEvolutionLevel(uint256 NFTId, uint256 newLevel) public authorised {
        evolutionLevelMemory[NFTId] = newLevel;
    }    
    
    function redeemNFT(uint256 tokenId, string memory redemptionNote) public {
        require(msg.sender == ownerOf(tokenId), "Must own this NFT to redeem");
        require(redemptionMemory[tokenId] > 0, "Token has been fully redeemed");
        redemptionMemory[tokenId] = redemptionMemory[tokenId] - 1;
        
        emit RedeemNFT(tokenId, redemptionNote);
    }

    function _mintInternal(uint256 NFTId, address _recipient ) internal {
		require(mintingActive[NFTId] == true, "Mint not active");
        uint256 tokenId = totalSupply() + 1;
		redemptionMemory[tokenId] = redemptionMouldMemory[NFTId];
        artworkNFTReference[tokenId] = NFTId;
		editionNumberMemory[tokenId] = totalMinted[NFTId] + 1;
        totalMinted[NFTId] = editionNumberMemory[tokenId];
		_safeMint(_recipient, tokenId);
        emit NewNFTCreatedFor(NFTId, tokenId, _recipient);

        if (totalMinted[NFTId] == editionSizeMemory[NFTId]) {
			_closeNFTWindow(NFTId);
		}
    }

    function ownerMint(uint256 NFTId, uint256 amountToMint) public onlyOwner {
        require(totalMinted[NFTId] + amountToMint <= editionSizeMemory[NFTId], "Cannot mint that many editions");
        
        for(uint256 i=0; i<amountToMint; i++) {
            _mintInternal(NFTId, msg.sender);
        }
    }
    
    function updateActiveState(uint256 NFTId, bool newState) public onlyOwner {
        mintingActive[NFTId] = newState;
    }

	function closeNFTWindow(uint256 NFTId) public onlyOwner {
		mintingActive[NFTId] = false;
		editionSizeMemory[NFTId] = totalMinted[NFTId];
		
		emit CloseNFTWindow(NFTId); 
	}

	function _closeNFTWindow(uint256 NFTId) internal {
		mintingActive[NFTId] = false;
		editionSizeMemory[NFTId] = totalMinted[NFTId];
		
		emit CloseNFTWindow(NFTId); 
	}
	
	function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function getFileData(uint256 tokenId, uint256 index) public view returns (string memory hashIPFS, string memory hashArweave, string memory artworkType) {
		require(_exists(tokenId), "Token does not exist.");
		uint256 NFTRef = artworkNFTReference[tokenId];
		
		hashIPFS = hashIPFSMemory[NFTRef][index];
		hashArweave = hashArweaveMemory[NFTRef][index];
		artworkType = artworkTypeMemory[NFTRef][index];

	}

    function getMetadata(uint256 tokenId) public view returns (uint256 NFTRef, string memory name, string memory description, Attributes[] memory attributes, uint256 editionSize, uint256 editionNumber, uint256 evolutionLevel, uint256 totalRedemptions, uint64 redemptionExpiration, uint256 remainingRedemptions, bool isActive) {		require(_exists(tokenId), "Token does not exist.");
		NFTRef = artworkNFTReference[tokenId];
		
		name = mouldName[NFTRef];
		description = mouldDescription[NFTRef];
		attributes = mouldAttributes[NFTRef];
		editionSize = editionSizeMemory[NFTRef];
		editionNumber = editionNumberMemory[tokenId];
		evolutionLevel = evolutionLevelMemory[NFTRef];
		totalRedemptions = redemptionMouldMemory[NFTRef];
		redemptionExpiration = redemptionExpirationMouldMemory[NFTRef];
        remainingRedemptions = redemptionMemory[tokenId];
		isActive = mintingActive[NFTRef];
	}

	function NFTMouldFileData(uint256 NFTId, uint256 index) public view returns (string memory hashIPFS, string memory hashArweave, string memory artworkType, uint256 unmintedEditions) {
		hashIPFS = hashIPFSMemory[NFTId][index];
		hashArweave = hashArweaveMemory[NFTId][index];
		artworkType = artworkTypeMemory[NFTId][index];
		unmintedEditions = editionSizeMemory[NFTId] - totalMinted[NFTId];
	}

	function NFTMouldMetadata(uint256 NFTId) public view returns (string memory name, string memory description, Attributes[] memory attributes, uint256 editionSize, uint256 editionsMinted, uint256 evolutionLevel, uint256 totalRedemptions, uint64 redemptionExpiration, bool isActive) {
		name = mouldName[NFTId];
		description = mouldDescription[NFTId];
		attributes = mouldAttributes[NFTId];
		editionSize = editionSizeMemory[NFTId];
		editionsMinted = totalMinted[NFTId];
		
		evolutionLevel = evolutionLevelMemory[NFTId];
		totalRedemptions = redemptionMouldMemory[NFTId];
		redemptionExpiration = redemptionExpirationMouldMemory[NFTId];
		
		isActive = mintingActive[NFTId];
	}

	function updateURI(string memory newURI) public onlyOwner {
		_setBaseURI(newURI);
	}

	function updateFactoryContract(address newfactoryContract) public onlyOwner {
		factoryContract = newfactoryContract;
	}  
	
	function updateMultiURI(string memory newURI1, string memory newURI2, string memory newURI3) public onlyOwner {
        multiURI1 = newURI1;
        multiURI2 = newURI2;
        multiURI3 = newURI3;
    }

    function multiURI(uint256 tokenId, uint256 artworkIndex) external view returns (string memory uri) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uri = string(abi.encodePacked(multiURI1, addressToString(address(this)), multiURI2, Strings.toString(tokenId), multiURI3, Strings.toString(artworkIndex)));
    }


	/**
	 * Saleable interface
	 */

	function _processSaleOffering( uint256 mouldId, address buyer ) internal override {
	    require(totalMinted[mouldId] < editionSizeMemory[mouldId], "Maximum editions already minted");
 		_mintInternal(mouldId, buyer);
	}

	function RegisterSeller( uint256 mouldId, address seller) public onlyOwner {
        _registerSeller(mouldId, seller);
    }

    function DeregisterSeller( uint256 mouldId, address seller) public onlyOwner {
		_deregisterSeller(mouldId, seller);
	}
}