pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Sergs.sol";

contract CryptoSergs is ERC721, Ownable {
	using ECDSA for bytes32;

	string public baseURI;

	Sergs public sergs;

    bool public migrationIsActive = false;

	address public constant burn = address(0x000000000000000000000000000000000000dEaD);
	IERC1155 public constant OPENSEA_STORE = IERC1155(0x495f947276749Ce646f68AC8c248420045cb7b5e);


	constructor(string memory _baseURI) ERC721("CryptoSergs","CRYPTOSERGS") {
		setBaseURI(_baseURI);
	}

    function setSergs(address _sergs) public onlyOwner {
		sergs = Sergs(_sergs);
	}

	function isValidCryptoSerg(uint256 _id) pure internal returns(bool) {
		if (_id >> 96 != 0x000000000000000000000000d909545440f2eFFBB7393D238E0d73c159f05869)
			return false;
		if (_id & 0x000000000000000000000000000000000000000000000000000000ffffffffff != 1)
			return false;
		return true;
	}

	function returnCorrectId(uint256 _id) pure internal returns(uint256) {
		_id = (_id & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
		
        //single
        if(_id == 175){
            return 170;
        }
            
        if(_id == 405){
            return 361;
        }

        if(_id == 506){
            return 502;
        }
        
        if(_id == 507){
            return 501;
        }
            
        if(_id == 558){
            return 551;
        }
            
        if(_id == 596){
            return 600;
        }
           
        if(_id == 735){
            return 740;
        }
            
        if(_id == 781){
            return 756;
        }

        if(_id == 805){
            return 705;
        }

        if(_id == 994){
            return 970;
        }

        if(_id == 1108){
            return 999;
        }

        if(_id == 1111){
            return 103;
        }
    
        //diff 6
        if(_id >= 597 && _id <= 605){
            return _id - 6;
        }
        
        //diff 3
        if(_id == 556 || _id >= 760 && _id <= 780){
            return _id - 3;
        }
        //diff 4
        if(_id >= 5 && _id <= 281){
            return _id - 4;
        }
        if(_id >= 366 && _id <= 404){
            return _id - 4;
        }
        if(_id >= 710 && _id <= 734){
            return _id -4;
        }
        if(_id >= 745 && _id <= 759){
            return _id -4;
        }
        if(_id >= 782 && _id <= 804){
            return _id -4;
        }
        if(_id >= 975 && _id <= 993){
            return _id -4;
        }
        if(_id >= 1004 && _id <= 1067){
            return _id -4;
        }
        if(_id == 427 || _id == 506){
            return _id -4;
        }
        //diff 5
        if(_id >= 283 && _id <= 1090){
            return _id - 5;
        }
        //diff 6
        if(_id >= 1092 && _id <= 1106){
            return _id - 6;
        }
        //diff 8
        if(_id == 1109 || _id == 1110 || _id >= 1112 && _id <= 1119){
            return _id - 8;
        }

        return 0;
	}

	function migrate(uint256 _tokenId) external {
		require(isValidCryptoSerg(_tokenId), "Not valid CryptoSerg");
        require(migrationIsActive, "Wait for migration to start!");
		uint256 id = returnCorrectId(_tokenId);
        require(id != 0, "Invalid id");
		_safeMint(msg.sender, id);
		sergs.migrate(msg.sender, id);
		OPENSEA_STORE.safeTransferFrom(msg.sender, burn, _tokenId, 1, "");
	}

    // contract functions
    
	function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4) {
		require(msg.sender == address(OPENSEA_STORE), "Not opensea asset");
		return CryptoSergs.onERC1155Received.selector;
	} 
	

    function switchMigrationIsActive() public onlyOwner {
        migrationIsActive = !migrationIsActive;
    }

    function baseTokenURI() private view returns (string memory) {
        return baseURI;
    }

	function setBaseURI(string memory _newUri) public onlyOwner {
		baseURI = _newUri;
	}

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
		return string(abi.encodePacked(baseURI, uint2str(_tokenId)));
    }

	function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}
}