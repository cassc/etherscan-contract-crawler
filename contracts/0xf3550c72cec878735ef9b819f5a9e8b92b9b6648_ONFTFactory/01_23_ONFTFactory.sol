// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../onft/ONFT721.sol";

contract ONFTFactory {
    event ONFTCreated(address indexed _onft, address indexed _owner);

    address public lzEndpoint;
    uint256 public minGasToTransfer;
    address private _owner;

    constructor(address _lzEndpoint, uint256 _minGasToTransfer) {
        require(_lzEndpoint != address(0), "ONFTFactory: !lzEndpoint");
        require(_minGasToTransfer > 0, "ONFTFactory: !minGasToTransfer");
        lzEndpoint = _lzEndpoint;
        minGasToTransfer = _minGasToTransfer;
        _owner = msg.sender;
    }

    function create(
        string memory _name,
        string memory _symbol,
        string memory _collectionURI,
        string memory _tokensURI,
        uint24 _maxSupply
    ) external {
        ONFT721 onft = new ONFT721(_name, _symbol, _collectionURI, _tokensURI, _maxSupply, msg.sender, minGasToTransfer, lzEndpoint);
        emit ONFTCreated(address(onft), msg.sender);
    }

    function setLzEndpoint(address _lzEndpoint) external {
        require(msg.sender == _owner);
        lzEndpoint = _lzEndpoint;
    }

    function setMinGasToTransfer(uint256 _minGasToTransfer) external {
        require(msg.sender == _owner);
        require(_minGasToTransfer > 0, "ONFTFactory: !minGasToTransfer");
        minGasToTransfer = _minGasToTransfer;
    }
}