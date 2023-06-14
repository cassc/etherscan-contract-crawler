// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * Ser, you want to woodify your NFTs?
 * This extension allows you to mint WNFTs (wood NFTs) from your NFTs.
 */
abstract contract ERC721Woodable {
	// Wood tokens list, pointing to their tokens
	mapping (uint256 => uint256) private _woodTokens;
	// Current number of wood tokens having been minted
	uint256 private _woodTokensCount = 0;

	/**
	 * A WNFT (wood NFT) is created from a NFT.
	 */
	event WoodMint(uint256 woodTokenId, uint256 tokenId, address initialOwner);

	/**
	 * Mint a WNFT (wood NFT) from an NFT.
	 * Ser, for safe mint, plz follow safety regulations of your wood machinery.
	 * Requirement : You need to check tokenId exists.
	 * initialOwner is optional and is if you want to record the initial owner
	 */
	function _safeWoodMint(uint256 tokenId, address initialOwner) internal virtual {
		// Starting at id 1
		_woodTokensCount++;
		_woodTokens[_woodTokensCount] = tokenId;

		emit WoodMint(_woodTokensCount, tokenId, initialOwner);
	}

	/** 
	 * Get the token which was used to mint the wood token.
	 */
	function tokenOfWoodToken(uint256 woodTokenId) public view returns (uint256) {
		return _woodTokens[woodTokenId];
	}

	/**
	 * Get the total amount of WNFTs in the wild.
	 */
	function totalWoodTokenSupply() public view returns (uint256) {
		return _woodTokensCount;
	}

	/**
	 * The URI for the metadata of this WNTF.
	 */
    function woodTokenURI(uint256 woodTokenId) public view virtual returns (string memory) {
        require(woodTokenId <= _woodTokensCount, "Wood Token does not exist");

        string memory baseURI = _woodBaseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, uint2str(woodTokenId))) : '';
    }

    function _woodBaseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * Uint to string, credits to
     * https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
     */
	function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}