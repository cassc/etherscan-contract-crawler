// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "DefaultOperatorFiltererUpgradeable.sol";
import "ERC721EnumerableUpgradeable.sol";
import "ERC2981Upgradeable.sol";
import "OwnableUpgradeable.sol";
import "nftBoxJsonParser.sol";


contract NFTBoxesNFTV2Upgradeable is ERC721EnumerableUpgradeable, ERC2981Upgradeable , OwnableUpgradeable, nftBoxJsonParser, DefaultOperatorFiltererUpgradeable {

	struct MouldData {
		address signatureAddress;
		string artworkHashIPFS;
		string artworkHashArweave;
		string artistName;
		string artistNote;
		string signatureHash;
		string signatureMessage;
		string artTitle;
		string artworkType;
	}

	struct MouldData2 {
		bool mintingActive;
		uint256 totalMinted;
		uint256 editionSize;
	}

	struct MouldData3 {
		string imageUrl;
		string animationUrl;
		string series;
		string theme;
		string boxName;
	}

	mapping(address => bool) public authorisedCaller;
	mapping(uint256 => MouldData) public mouldData;
	mapping(uint256 => MouldData2) public mouldData2;
	mapping(uint256 => MouldData3) public mouldData3;


	mapping(uint256 => uint256) public tokenIdToMould;
	mapping(uint256 => uint256) public idToEditionNumber;

	uint256 public nftIndex;
	uint256 public artistShare;

	event NewNFTMouldCreated(uint256 NFTIndex, string artworkHashIPFS, string artworkHashArweave, string artistName, 
		uint256 editionSize, string artTitle, string artworkType, string artworkSeries);
	event NewNFTMouldSignatures(uint256 NFTIndex, address signatureAddress, string signatureHash, string signatureMessage);
	event NewNFTCreatedFor(uint256 NFTId, uint256 tokenId, address recipient);
	event CloseNFTWindow(uint256 NFTId);

	// constructor() ERC721("NFTBoxes", "[NFT]") {

	// }

	function initialize() public initializer {
		__Ownable_init();
		__ERC721_init("NFTBoxes", "[NFT]");
		__DefaultOperatorFilterer_init();
	}

	modifier authorised() {
		require(authorisedCaller[msg.sender] || msg.sender == owner(), "VendingMachine: Not authorised to execute");
		_;
	}

    function supportsInterface(bytes4 interfaceId) public view override(ERC721EnumerableUpgradeable, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

	function setArtistShare(uint256 _value) external onlyOwner {
		artistShare = _value;
	}

	function setCaller(address _caller, bool _value) external onlyOwner {
		authorisedCaller[_caller] = _value;
	}

    function setApprovalForAll(address operator, bool approved) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

	function createNFTMould(
		MouldData memory _mould,
		MouldData3 memory _mould3,
		uint256 _collectionSize) 
		public authorised {

		uint256 _nftIndex = ++nftIndex;

		mouldData[_nftIndex] = _mould;
		mouldData2[_nftIndex] = MouldData2(true, 0, _collectionSize);
		mouldData3[_nftIndex] = _mould3;
		
		emit NewNFTMouldCreated(_nftIndex, _mould.artworkHashIPFS, _mould.artworkHashArweave, _mould.artistName, _collectionSize, _mould.artTitle, _mould.artworkType, _mould3.series);
		emit NewNFTMouldSignatures(_nftIndex, _mould.signatureAddress, _mould.signatureHash, _mould.signatureMessage);
	}

	function NFTMachineFor(uint256 _mouldId, address _recipient) public authorised {
		MouldData2 memory art2 = mouldData2[_mouldId];
		
		require(art2.mintingActive == true, "Mint not active");
		uint256 editionId = art2.totalMinted + 1;
		uint256 editionSize = art2.editionSize;
		require(editionId <= editionSize, "Cannot mint more");
		
		uint256 tokenId = totalSupply() + 1;
		tokenIdToMould[tokenId] = _mouldId;
		mouldData2[_mouldId].totalMinted = editionId;
		idToEditionNumber[tokenId] = editionId;
		_safeMint(_recipient, tokenId);
		if (editionId == editionSize) {
			_closeNFTWindow(_mouldId);
		}
		
		emit NewNFTCreatedFor(_mouldId, tokenId, _recipient);
	}

	function closeNFTWindow(uint256 _mouldId) external onlyOwner {
		_closeNFTWindow(_mouldId);
	}

	function _closeNFTWindow(uint256 _mouldId) internal {
		mouldData2[_mouldId].mintingActive = false;
		mouldData2[_mouldId].editionSize = mouldData2[_mouldId].totalMinted;
		
		emit CloseNFTWindow(_mouldId); 
	}

	// function getFileData(uint256 _tokenId) public view returns (string memory hashIPFS, string memory hashArweave, string memory artworkType) {
	// 	require(_exists(_tokenId), "Token does not exist.");
	// 	uint256 mouldId = tokenIdToMould[_tokenId];
	// 	MouldData memory mould = mouldData[mouldId];
		
	// 	hashIPFS = mould.artworkHashIPFS;
	// 	hashArweave = mould.artworkHashArweave;
	// 	artworkType = mould.artworkType;        
	// }

	// function getMetadata(uint256 _tokenId) public view returns (string memory artistName, string memory artistNote, uint256 editionSize, string memory artTitle, uint256 editionNumber, string memory boxDetails, bool isActive) {
	// 	require(_exists(_tokenId), "Token does not exist.");
	// 	uint256 mouldId = tokenIdToMould[_tokenId];
	// 	MouldData memory mould = mouldData[mouldId];
	// 	MouldData2 memory mould2 = mouldData2[mouldId];
		
	// 	artistName = mould.artistName;
	// 	artistNote = mould.artistNote;
	// 	editionSize = mould2.editionSize;
	// 	artTitle = mould.artTitle;
	// 	editionNumber = idToEditionNumber[_tokenId];

	// 	isActive = mould2.mintingActive;
	// }

	// function getSignatureData(uint256 _tokenId) public view returns (address signatureAddress, string memory signatureHash, string memory signatureMessage) {
	// 	require(_exists(_tokenId), "Token does not exist.");
	// 	uint256 mouldId = tokenIdToMould[_tokenId];
	// 	MouldData memory mould = mouldData[mouldId];
		
	// 	signatureAddress = mould.signatureAddress;
	// 	signatureHash = mould.signatureHash;
	// 	signatureMessage = mould.signatureMessage;
	// }

	function royaltyInfo(uint256 tokenId, uint256 salePrice) public view override returns (address, uint256) {
		uint256 mouldId = tokenIdToMould[tokenId];
		MouldData memory art = mouldData[mouldId];

        uint256 royaltyAmount = (salePrice * artistShare) / _feeDenominator();

        return (art.signatureAddress, royaltyAmount);
    }

	function tokenURI(uint256 _tokenId) public view override returns(string memory) {
		uint256 mouldId = tokenIdToMould[_tokenId];
		MouldData memory art = mouldData[mouldId];
		MouldData2 memory art2 = mouldData2[mouldId];
		MouldData3 memory art3 = mouldData3[mouldId];

		return string(
			abi.encodePacked(
				generateTokenUriPart1(
					idToEditionNumber[_tokenId],
					_generateDescription(
						art.artistName,
						Strings.toHexString(uint256(uint160(art.signatureAddress))),
						art.signatureHash,
						art.signatureMessage,
						art.artistNote),
					art3.animationUrl,
					art3.imageUrl,
					art.artTitle),
				generateTokenUriPart2(
					art.artistName,
					idToEditionNumber[_tokenId],
					art2.editionSize,
					art3.series,
					art.artworkType,
					art3.theme,
					art3.boxName)
			)
		);
	}
}