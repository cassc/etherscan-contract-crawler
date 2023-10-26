pragma solidity ^0.8.0;

import '../LayerZero/LayerZeroERC721.sol';

contract Omnicats is LayerZeroERC721 {
    constructor(
        string memory _name,
        string memory _token,
        uint256 _nextTokenId,
        uint256 _maxMint,
        uint256 _mintPerWallet,
        string memory baseURI_,
        address _layerZeroEndpoint,
        uint256 _startTimestamp
    )
        LayerZeroERC721(
            _name,
            _token,
            _nextTokenId,
            _maxMint,
            _mintPerWallet,
            baseURI_,
            _layerZeroEndpoint,
            _startTimestamp
        )
    {}

    function reserveMints(uint256 quantity) public onlyOwner {
        _safeMint(msg.sender, quantity);
    }
}