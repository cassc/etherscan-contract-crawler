// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract OkOctopus is Initializable, ERC721AUpgradeable, OwnableUpgradeable,ReentrancyGuardUpgradeable, PausableUpgradeable, AccessControlUpgradeable {

    bytes32 public constant SALE_ROLE = keccak256("SALE_ROLE");
	using StringsUpgradeable for uint256;
    string public baseURI;
	
	struct blindBoxEvent{
		uint256 startIndex;
		uint256 fromToken;
		uint256 toToken;
	}
	
	blindBoxEvent[] private blindBoxEvents;
	
	modifier onlyValidCaller() {
		require(hasRole(SALE_ROLE, msg.sender) || owner() == msg.sender, "Caller is not valid");
		_;
	}
	
	function initialize(string memory name, string memory symbol, string memory baseURI_, address takoAddress) public virtual initializer {
		 __ERC721A_init(name, symbol);
		__Ownable_init();
		__ReentrancyGuard_init();
		__Pausable_init();
		__AccessControl_init();
		
		baseURI = baseURI_;
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		
		_safeMint(takoAddress, 80 + 390);//80 special + 390 common reserved for team usage
	}
	
	function newBlindBoxEvent(uint256 fromToken, uint256 toToken, uint256 startIndex) external onlyValidCaller{
		require(toToken > fromToken, "Wrong to token");
		
		blindBoxEvent memory newEvent;
		
		newEvent.fromToken = fromToken;
		newEvent.toToken = toToken;
		newEvent.startIndex = startIndex;
		
		blindBoxEvents.push(newEvent);
	}
	
	function openBlindBox(uint256 eventId) public onlyOwner {
		blindBoxEvent storage thisEvent = blindBoxEvents[ eventId ];
		
		require(thisEvent.toToken > 0, "Event not found");
		
		if (thisEvent.startIndex == 0) {
			thisEvent.startIndex = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
		}
	}
	
	function setSaleContract(address saleContract) public onlyOwner{
		_setupRole(SALE_ROLE, saleContract);
	}
	
	function getConfig() public view returns(string memory, blindBoxEvent[] memory) {
		return (baseURI, blindBoxEvents);
	}
	
	
	//============
	//erc721a
	//============
    function mint(address to, uint256 quantity) external onlyValidCaller {
        _safeMint(to, quantity);
    }
	
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "token id not exist");
		require(bytes(baseTokenURI()).length > 0, "base uri empty");
		uint256 seqId;
		bool hasBox;
		
		if (blindBoxEvents.length > 0) {
			for(uint256 i = blindBoxEvents.length; i > 0; i--) {
				if (tokenId >= blindBoxEvents[i-1].fromToken && tokenId <= blindBoxEvents[i-1].toToken) {
					hasBox = true;
					
					if (blindBoxEvents[i-1].startIndex > 0) { 
						seqId = (tokenId + blindBoxEvents[i-1].startIndex) % (blindBoxEvents[i-1].toToken - blindBoxEvents[i-1].fromToken + 1);
						seqId += blindBoxEvents[i-1].fromToken;
					}
					
					break;
				}
			}
		}
		
		string memory filename;
		if (seqId > 0) {
			filename = string(abi.encodePacked(seqId.toString(), ".json"));
		} else if (hasBox) {
			filename = "0.json";
		} else {
			filename = string(abi.encodePacked(tokenId.toString(), ".json"));
		}	
		
		return string(abi.encodePacked(baseTokenURI(), filename));
	}
	
	function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;//must end with /
    }
    
	function baseTokenURI() public view returns (string memory) {
		return baseURI;
	}
	
	 function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
	//============
	//solidity/oz
	//============
	function version() public pure returns (string memory) {
		return "1.1";
	}
	
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AUpgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
	
	receive() external payable{
		revert();
	}
	
	fallback() external payable{
		revert();
	}
}