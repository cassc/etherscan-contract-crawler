// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Reclaimable.sol";
import "./DefaultOperatorFilterer.sol";

interface ISG {

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function forge(address from, uint256 id, uint256 amount) external;
}

contract SGForged is ERC721AQueryable, Ownable, Reclaimable, Pausable, IERC2981, DefaultOperatorFilterer {
    using Strings for uint256;

    ISG public unforgedContract;

    // metadata
    bool public isMetadataById;
    mapping(uint256 => uint256) private idToMetadataType;
    mapping(uint256 => string) private metadataTypeToURI;

    string private _baseTokenURI = "";
    string private _contractBaseURI = "https://sg-metadata.s3.us-east-2.amazonaws.com/collection/collection_forged.json";

    // royalties
    uint256 private royaltyBps = 500;
    address private royaltyReceiver = 0x5748bf284B8e001bd535C5dE6e9C52EC64501FdC;

    constructor() ERC721A("SGForged", "SG") {}

    function forgeMultiple(
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external whenNotPaused {
        require(ids.length == amounts.length, "Invalid parameters");
        for (uint256 i = 0; i < ids.length; i++) {
            require(unforgedContract.balanceOf(msg.sender, ids[i]) >= amounts[i], "Insufficient NFT balance");

            unforgedContract.forge(msg.sender, ids[i], amounts[i]);

            if (ids[i] > 0 && ids[i] <= 10) {
                uint256 mintedTokenId = _totalMinted() + 1;

                for (uint256 j = 0; j < amounts[i]; j++) {
                    idToMetadataType[mintedTokenId] = ids[i];
                    mintedTokenId = mintedTokenId + 1;
                }

                _safeMint(msg.sender, amounts[i]); 
                
            }
        }
        
    }

    function forge(uint256 id) external whenNotPaused {
        require(unforgedContract.balanceOf(msg.sender, id) > 0, "Insufficient NFT balance");

        unforgedContract.forge(msg.sender, id, 1);

        if (id > 0 && id <= 10) {
            _safeMint(msg.sender, 1);
            idToMetadataType[_totalMinted()] = id;
        }
    }

    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }

    function setSGContract(address _sg) external onlyOwner {
        unforgedContract = ISG(_sg);
    }

    // metadata
    function setMetadataById(bool byId) external onlyOwner {
        isMetadataById = byId;
    }

    function setURIByMetadataType(
        uint256[] calldata types,
        string[] calldata uris
    ) external onlyOwner {
        for (uint256 i = 0; i < types.length; i++) {
            metadataTypeToURI[types[i]] = uris[i];
        }
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (isMetadataById)
		    return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
        else
            return metadataTypeToURI[idToMetadataType[_tokenId]];
	}

	function contractURI() public view returns (string memory) {
		return _contractBaseURI;
	}

    function setBaseURI(string memory newBaseURI) external onlyOwner {
		_baseTokenURI = newBaseURI;
	}

	function setContractURI(string memory newContractURI) external onlyOwner {
		_contractBaseURI = newContractURI;
	}

    // royalty
    function setRoyaltyReceiver(address _royaltyReceiver) external onlyOwner {
        royaltyReceiver = _royaltyReceiver;
    }

    function setRoyaltyBps(uint256 _royaltyBps) external onlyOwner {
        royaltyBps = _royaltyBps;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC721A, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
        royaltyAmount = (_salePrice / 10000) * royaltyBps;
        return (royaltyReceiver, royaltyAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function burn(uint256 tokenId) public virtual {
        _burn(tokenId, true);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}