// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract PandaNft is Initializable, OwnableUpgradeable, AccessControlUpgradeable, ERC721EnumerableUpgradeable {

	bytes public constant SIGN_PREFIX = "\x19Ethereum Signed Message:\n32";
	bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
	
	using StringsUpgradeable for uint256;
    string public baseURI;
	
	address[] public signers;
	
	using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;
	
	mapping(uint256 => uint256) public tokenMapValue; //token id => value
	
	mapping(uint256 => uint256) public uniqueIds;
	
	event UniqueIdUsed(uint256 indexed uniqueId, uint256 indexed tokenId);
	
	address public toolsContract;
	
	function initialize(string memory name, string memory symbol, string memory baseURI_, address[] memory _signers, address admin) public virtual initializer {
		 __ERC721_init(name, symbol);
		__Ownable_init();
		__AccessControl_init();
		
		baseURI = baseURI_;
		signers = _signers;
		
		_setupRole(ADMIN_ROLE, admin);
	}
	/*+========+
	  | admin |
	  +========+*/
	function adminBatchTransfer(uint256 timestamp, address[] memory tos, uint256[] memory tokenIds, uint8 vs, bytes32 rs, bytes32 ss) public {
		require(hasRole(ADMIN_ROLE, msg.sender), "unauthorized");
		require(timestamp >= block.timestamp, "expired");
		
		bytes32 hashMsg = keccak256(abi.encodePacked(this, msg.sender, timestamp, _encodeAddressArray(tos), _encodeUint256Array(tokenIds)));
		
		address recovered = ecrecover(keccak256(abi.encodePacked(SIGN_PREFIX,hashMsg)), vs, rs, ss);
        require(signers[1]==recovered, "invalid sign");
		
		for(uint256 i=0; i < tos.length; i++) {
			_transfer(ownerOf(tokenIds[i]),tos[i], tokenIds[i]);
		}
	}
	
	function setAdminRole(address admin) public onlyOwner {
        _setupRole(ADMIN_ROLE, admin);
    }  
	
	function setSigners(address[] memory _signers) public onlyOwner {
        signers = _signers;
    }  
	
	/*+========+
	  | erc721 |
	  +========+*/
	function burn(uint256 tokenId) public{
		require(ownerOf(tokenId) == msg.sender, "wrong owner");
        _burn(tokenId);
    }
	
	function mint(uint256 uniqueId, uint256 value, address to, uint8[2] memory vs, bytes32[2] memory rs, bytes32[2] memory ss) public {
		
		require(value % 100 == 0, "invalid value");
		require(uniqueIds[uniqueId] == 0, "unique id exists");
		require(to != address(0), "zero address");
		
		bytes32 hashMsg = keccak256(abi.encodePacked(this, uniqueId));
		address recovered = ecrecover(keccak256(abi.encodePacked(SIGN_PREFIX,hashMsg)), vs[0], rs[0], ss[0]);
        require(signers[0]==recovered, "invalid sign1");
		
		hashMsg = keccak256(abi.encodePacked(this, value, to, vs[0], rs[0], ss[0]));
		recovered = ecrecover(keccak256(abi.encodePacked(SIGN_PREFIX,hashMsg)), vs[1], rs[1], ss[1]);
        require(signers[1]==recovered, "invalid sign2");
		
		_tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
		
		tokenMapValue[tokenId] = value;
		uniqueIds[uniqueId] = tokenId;
		
		emit UniqueIdUsed(uniqueId, tokenId);
    }
	
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "token id not exist");
		require(bytes(baseTokenURI()).length > 0, "base uri empty");
		
		string memory filename = string(abi.encodePacked(tokenMapValue[tokenId].toString()/*, ".json"*/));
		
		return string(abi.encodePacked(baseTokenURI(), filename));
	}
	
	function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;//must end with /
    }
    
	function baseTokenURI() public view returns (string memory) {
		return baseURI;
	}
	
	/*+==========+
	  | internal |
	  +==========+*/
	function _encodeUint256Array(uint256[] memory inputs) internal pure returns(bytes memory data){
        for(uint i=0; i<inputs.length; i++){
            data = abi.encodePacked(data, inputs[i]);
        }
    }
	
	function _encodeAddressArray(address[] memory inputs) internal pure returns(bytes memory data){
        for(uint i=0; i<inputs.length; i++){
            data = abi.encodePacked(data, inputs[i]);
        }
    }
	
	/*+=======+
	  | other |
	  +=======+*/ 
	function batchOwnerOf(uint256[] calldata tokenIds) public view returns (address[] memory) {
		address[] memory owners = new address[](tokenIds.length);
		for(uint256 i=0; i < tokenIds.length; i++) {
			owners[i] = ownerOf(tokenIds[i]);
		}
		return owners;
	}

	function allTokens(address owner) public view returns (uint256[] memory) {

        uint256 balance = balanceOf(owner);
        uint256[] memory tokens = new uint256[](balance);

        for (uint256 i=0; i<balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }

        return tokens;
    }
	
	function allValues(uint256[] memory tokenIds) public view returns (uint256[] memory) {
		uint256[] memory values = new uint256[](tokenIds.length);

        for (uint256 i=0; i<tokenIds.length; i++) {
            values[i] = tokenMapValue[tokenIds[i]];
        }

        return values;
	}
	
	function version() public pure returns (string memory) {
		return "1.0";
	}
	
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721EnumerableUpgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
	
	receive() external payable{
		revert();
	}
	
	fallback() external payable{
		revert();
	}
}