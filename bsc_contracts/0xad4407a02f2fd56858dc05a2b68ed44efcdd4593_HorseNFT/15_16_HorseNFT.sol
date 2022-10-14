// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "./IHorseNFT.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract HorseNFT is
    Initializable,
    OwnableUpgradeable,
    IERC721Upgradeable,
    ERC721EnumerableUpgradeable,
	IHorseNFT
{
    address salesContract;
	string private __baseURI;
	
    modifier onlySalesContract() {
        require(msg.sender == salesContract, "not sales caller");
        _;
    }
	
    function initialize(string memory name, string memory symbol, string memory baseURI_) public initializer {
        __Ownable_init();
		
        __ERC721Enumerable_init();
        __ERC721_init(name, symbol);
		
		__baseURI = baseURI_;
    }
	
	function setSalesContract(address _salesContract) public onlyOwner {
        salesContract = _salesContract;
    }
	
	function setBaseURI(string memory baseURI_) public onlyOwner {
        __baseURI = baseURI_;//must end with /
    }
	
	function baseTokenURI() public view returns (string memory) {
		return __baseURI;
	}
	
	function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function mint(uint256 tokenId, address user) external onlySalesContract {
        _mint(user, tokenId);
    }
	
	function burn(uint256 tokenId) external onlySalesContract{
        _burn(tokenId);
    }

	function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, IHorseNFT) returns (string memory) {
		string memory filename = string(abi.encodePacked(Strings.toString(tokenId), ".json"));
		return string(abi.encodePacked(_baseURI(), filename));
	}
	
	function allTokens(address owner) public view returns (uint256[] memory) {

        uint256 balance = balanceOf(owner);
        uint256[] memory tokens = new uint256[](balance);

        for (uint256 i=0; i<balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }

        return tokens;
    }
	
	receive() external payable{
		revert();
	}
	
	fallback() external payable{
		revert();
	}
	
}