pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./CryptoSergs.sol";

contract Sergs is ERC721, Ownable {
		
     using SafeMath for uint256;

    uint256 public TOTAL_SUPPLY = 5555;

    uint256 public sergPrice = 0.07 ether;

    uint256 public MAX_PURCHASE = 5;

    bool public saleIsActive = false;

    string private baseURI;

    uint256 private _currentTokenId = 1111;

    CryptoSergs public cryptoSergs;


    event SergMinted(uint tokenId, address sender);
    event SergMigrated(uint tokenId, address sender);

   constructor(string memory _baseURI) ERC721("Sergs","SERGS") {
		setBaseURI(_baseURI);
	}

	function migrate(address _to, uint256 _tokenId) external {
        require(msg.sender == address(cryptoSergs), "Can't call this");
        _safeMint(_to, _tokenId);
        emit SergMigrated(_tokenId, msg.sender);
    }

    function setCryptoSergs(address _cryptoSergs) public onlyOwner {
		cryptoSergs = CryptoSergs(_cryptoSergs);
	}

	function mintSergsTo(address _to, uint numberOfTokens) public payable {
        require(saleIsActive, "Wait for sales to start!");
        require(numberOfTokens <= MAX_PURCHASE, "Too many Sergs to mint!");
        require(_currentTokenId.add(numberOfTokens) <= TOTAL_SUPPLY, "All Sergs has been minted!");
        require(msg.value >= sergPrice, "insufficient ETH");

        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 newTokenId = _nextTokenId();

            if (newTokenId <= TOTAL_SUPPLY) {
                _safeMint(_to, newTokenId);
                emit SergMinted(newTokenId, msg.sender);
                _incrementTokenId();
            }
        }
    }

    function mintTo(address _to, uint numberOfTokens) public onlyOwner {
        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 newTokenId = _nextTokenId();

            if (newTokenId <= TOTAL_SUPPLY) {
                _safeMint(_to, newTokenId);
                emit SergMinted(newTokenId, msg.sender);
                _incrementTokenId();
               
            }
        }
    }

    // contract functions


    function assetsLeft() public view returns (uint256) {
        if (supplyReached()) {
            return 0;
        }

        return TOTAL_SUPPLY - _currentTokenId;
    }

    function _nextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function supplyReached() public view returns (bool) {
        return _currentTokenId > TOTAL_SUPPLY;
    }

    function totalSupply() public view returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function switchSaleIsActive() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function baseTokenURI() private view returns (string memory) {
        return baseURI;
    }

    function getPrice() public view returns (uint256) {
        return sergPrice;
    }

	function setBaseURI(string memory _newUri) public onlyOwner {
		baseURI = _newUri;
	}

	function setTotalSupply(uint256 _newTotalSupply) public onlyOwner {
		TOTAL_SUPPLY = _newTotalSupply;
	}

	function setPrice(uint256 _newPrice) public onlyOwner {
		sergPrice = _newPrice;
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