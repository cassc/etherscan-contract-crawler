// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BaseZKBridgeErc721 is ERC721 {
    address public bridge;

    bool public isONFT;

    mapping(uint256 => string) private tokenURIs;

    modifier onlyBridge() {
        require(msg.sender == bridge, "caller is not the bridge");
        _;
    }

    constructor(string memory _name, string memory _symbol, address _bridge, bool _isONFT) ERC721(_name, _symbol) {
        bridge = _bridge;
        isONFT = _isONFT;
    }

    function zkBridgeMint(address _to, uint256 _tokenId, string memory tokenURI_) public onlyBridge {
        _mint(_to, _tokenId);
        if (!isONFT) {
            _setTokenURI(_tokenId, tokenURI_);
        }
    }

    function zkBridgeBurn(uint256 _tokenId) public onlyBridge {
        require(_exists(_tokenId), "Burn of nonexistent token");
        _burn(_tokenId);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        if (isONFT) {
            return _tokenURI(_tokenId);
        }
        return tokenURIs[_tokenId];
    }

    function _setTokenURI(uint256 _tokenId, string memory tokenURI_) internal {
        require(_exists(_tokenId), "URI set of nonexistent token");
        tokenURIs[_tokenId] = tokenURI_;
    }

    function _tokenURI(uint256 _tokenId) internal view virtual returns (string memory) {
        return super.tokenURI(_tokenId);
    }

}