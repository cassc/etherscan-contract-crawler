// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";

pragma solidity ^0.8.0;

abstract contract IFridge {
    function burnForAddress(uint index) 
        external
        virtual;

    function isOwnerOf(uint _tokenId, address _owner)
        public
        view
        virtual
        returns (bool);
}

contract Mega404 is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
	using Strings for uint;

    IFridge public immutable FRIDGE;
    bytes32 public root;

	uint public maxSupply = 4404;

    string public _baseURL = "https://reveal.mega404.com/api/metadata/";
	string public suffix = "";
	
	string public prerevealURL = "";
    bool public isMetadataFinal;

    //**                          WITHDRAW WALLET                          **//
    address public withdrawAddress = 0x112dC0acac7DC10236779a1C36158E2Fea09b689;

	address public fridgeAddress = 0x1628D51eDc96F158Df31316063F0b4f5b12d2f28;
	bool public burnsEnabled = false;

	mapping(address => uint) private _walletMintedCount;

	constructor()
	ERC721A("MEGA 404", "MEGA404") {
        FRIDGE = IFridge(fridgeAddress);
    }
    
    function mintedCount(address owner) external view returns (uint) {
        return _walletMintedCount[owner];
    }

	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}

	function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

	function contractURI() public pure returns (string memory) {
		return "";
	}

    function finalizeMetadata() external onlyOwner {
        isMetadataFinal = true;
    }

	function reveal(string memory url) external onlyOwner {
        require(!isMetadataFinal, "Metadata is finalized");
		_baseURL = url;
	}

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(withdrawAddress).transfer(balance);
    }

	function airdrop(address to, uint count) external onlyOwner {
		require(
			_totalMinted() + count <= maxSupply,
			"Exceeds max supply"
		);
		_safeMint(to, count);
	}

	function tokenURI(uint tokenId)
		public
		view
		override
		returns (string memory)
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), suffix))
            : prerevealURL;
	}

	/*
			"SET VARIABLE" FUNCTIONS
	*/

    function setBurnsEnabled(bool value) external onlyOwner {
		burnsEnabled = value;
	}   

	function setMaxSupply(uint newMaxSupply) external onlyOwner {
		maxSupply = newMaxSupply;
	}

	function setSuffix(string memory _suffix) external onlyOwner {
		suffix = _suffix;
	}

	/*
			MINT FUNCTIONS
	*/
    
    function burnFridge(uint _index) external payable {
		require(burnsEnabled, "Burning fridges is not enabled");
        require(FRIDGE.isOwnerOf(_index, msg.sender), "You cannot burn that fridge");

        FRIDGE.burnForAddress(_index);
		_walletMintedCount[msg.sender] += 1;
		_safeMint(msg.sender, 1);
	}
    
    function burnManyFridges(uint[] memory _index) external payable {
		require(burnsEnabled, "Burning fridges is not enabled");
		for (uint i = 0; i < _index.length; i++) {
			require(FRIDGE.isOwnerOf(_index[i], msg.sender), "You cannot burn that fridge");

			FRIDGE.burnForAddress(_index[i]);
			_walletMintedCount[msg.sender] += 1;
			_safeMint(msg.sender, 1);
		}
	}

	/*
			OPENSEA OPERATOR OVERRIDES (ROYALTIES)
	*/

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    string public DEV = unicode"Viperware Labs 🧪";

}