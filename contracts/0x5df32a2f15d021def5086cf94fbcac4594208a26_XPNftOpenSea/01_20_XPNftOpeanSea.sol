// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "./BridgeNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {DefaultOperatorFilterer} from "../lib/opensea-filter/src/DefaultOperatorFilterer.sol";

contract XPNftOpenSea is Ownable, ERC721Enumerable, BridgeNFT, ERC2981, DefaultOperatorFilterer {
	struct SetRoyalty {
		address receiver;
		uint96 feeNumerator; // 10000 == 100%
	}

    string public baseUri;

    // WARN: baseURI_ MUST be "/" suffixed
	constructor(
		string memory name_,
		string memory symbol_,
		string memory baseURI_,
		SetRoyalty memory setRoyaltyInfo
	) ERC721(name_, symbol_) {
        baseUri = baseURI_;
		if (setRoyaltyInfo.receiver != address(0)) {
			_setDefaultRoyalty(setRoyaltyInfo.receiver, setRoyaltyInfo.feeNumerator);
		}
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

	function mint(address to, uint256 id, bytes calldata rawInfo) override external onlyOwner {
		if (rawInfo.length != 0) {
			SetRoyalty memory setRoyaltyInfo = abi.decode(rawInfo, (SetRoyalty));
			if (setRoyaltyInfo.receiver != address(0)) {
				_setTokenRoyalty(id, setRoyaltyInfo.receiver, setRoyaltyInfo.feeNumerator);
			}
		}


		_safeMint(to, id);
	}

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

	function burnFor(address from, uint256 id) override external onlyOwner {
        require(ownerOf(id) == from, "You don't own this nft!");
		_burn(id);
	}

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function baseURI() override external view returns (string memory)  {
        return string(abi.encodePacked(baseUri, "{id}"));
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}