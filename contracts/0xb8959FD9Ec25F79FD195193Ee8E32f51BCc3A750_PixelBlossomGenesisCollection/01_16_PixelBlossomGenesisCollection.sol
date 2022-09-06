// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./PixelBlossomCollection.sol";
import "./PixelBlossomSimpleReveal.sol";

contract PixelBlossomGenesisCollection is PixelBlossomCollection, PixelBlossomSimpleReveal {
    using ECDSA for bytes32;

    uint public constant PRICE = 0.4 ether;
    uint public constant DEV_PERCENT = 15;

    address payable private _devAddress;
    address private _signer;

    mapping(bytes32 => bool) public nonces;

    constructor(
        string memory _name,
        string memory _symbol,
        uint _maxSupply,
        string memory _baseURI,
        string memory _ipfsBaseURI,
        address[] memory _artists,
        uint _revealInterval,
        uint _revealStates,
        address payable __devAddress,
        address __signer
    )
    PixelBlossomCollection(_name, _symbol, _maxSupply, _baseURI, _ipfsBaseURI, _artists)
    PixelBlossomSimpleReveal(_revealInterval, _revealStates) {
        _devAddress = __devAddress;
        _signer = __signer;
    }

    function mint(uint qty, bytes32 hash, bytes memory signature, bytes32 nonce) external payable {
        require(_matchAddressSigner(hash, signature), "PixelBlossomGenesisCollection: Direct minting is not allowed");
        require(_hashTransaction(msg.sender, qty, nonce) == hash, "PixelBlossomGenesisCollection: Hash mismatch");
        require(!nonces[nonce], "PixelBlossomGenesisCollection: Nonce was already used");
        require(qty * PRICE == msg.value, "PixelBlossomGenesisCollection: Ether value mismatch");

        nonces[nonce] = true;

        _mintNFTs(msg.sender, qty);
    }

    function setSigner(address __signer) external onlyOwner {
        _signer = __signer;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;

        uint artistCut = balance * (100 - DEV_PERCENT) / 100 / artists.length;

        for (uint i = 0; i < artists.length; i++) {
            payable(artists[i]).transfer(artistCut);
            balance -= artistCut;
        }

        _devAddress.transfer(balance);
    }

    function _hashTransaction(address sender, uint qty, bytes32 nonce) private pure returns(bytes32) {
        return keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender, qty, nonce)))
        );
    }

    function _matchAddressSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signer == hash.recover(signature);
    }
}