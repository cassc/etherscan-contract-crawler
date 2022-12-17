// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../alt-layer/token/ERC721Settleable.sol";

abstract contract EvolvERC721Settleable is ERC721Settleable {

    //actual levels of the NFTs
    mapping (uint256 => uint256) private _levels;

    string private _URI;
    string private _extension;

    event NFTLeveledUp(uint256 tokenId, uint256 newLevel);

    constructor(address bridgeAddress) ERC721Settleable(bridgeAddress) {}

    // Evolv functions
    function setBaseURI(string memory URI, string memory ext) internal virtual{
        _URI = URI;
        _extension = ext;
    }

    function _baseURI() internal virtual override view returns (string memory) {
        return _URI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        string memory baseWithTokenID = super.tokenURI(tokenId);
        return bytes(baseWithTokenID).length > 0 ? string(abi.encodePacked(baseWithTokenID , _extension)) : "";
    }

    /// @dev It's called by {settle} in Settleable.sol.
    function _settle(KeyValuePair[] memory pairs, bytes32)
        internal
        virtual
        override
    {
        // Use a local variable to hold the loop computation result.
        uint256 curBurnCount = 0;
        for (uint256 i = 0; i < pairs.length; i++) {
            uint256 tokenId = abi.decode(pairs[i].key, (uint256));
            (address account, uint256 level) = abi.decode(pairs[i].value, (address, uint256));

            if (account == address(0)) {
                curBurnCount += 1;
            } else {
                _mint(account, tokenId);
                setLevel(tokenId, level);
            }
        }
        _incrementTotalMinted(pairs.length);
        _incrementTotalBurned(curBurnCount);
    }

    function setLevel(uint256 tokenId, uint256 level) internal virtual {
        require(_exists(tokenId), "Evolv: Level Set of nonexistent token");
        _levels[tokenId] = level;

        emit NFTLeveledUp(tokenId, level);
    }

    function levelOf(uint256 tokenId) public view virtual returns (uint256) {
        require(_exists(tokenId), "Evolv: Level of nonexistent token");

        return _levels[tokenId];
    }
}