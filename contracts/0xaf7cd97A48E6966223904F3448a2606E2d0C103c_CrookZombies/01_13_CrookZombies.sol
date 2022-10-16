// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

// this contract is deliberately not using ERC721a as we need to mint in a non-sequential order
contract CrookZombies is ERC721, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    address private _signer;

    string public baseURI;
    bool public mintEnabled = false;

    constructor()
    ERC721("CrookZombies", "CRKZB"){}

	function _baseURI() internal view virtual override returns (string memory) {
	    return baseURI;
	}

    function setURI(string memory _newBaseURI) public onlyOwner {
	    baseURI = _newBaseURI;
	}


    // using ECDSA signatures generated off-chain for managing approved minters
    function updateSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    function _hash(address _address, uint16[] memory crookz) internal view returns (bytes32){
        return keccak256(abi.encode(address(this), _address, crookz));
    }

    function _verify(bytes32 hash, uint8 v, bytes32 r, bytes32 s, address signer) internal view returns (bool){
        return (ecrecover(hash, v, r, s) == signer);
    }

    // enable / disable minting
    function setMintState(bool _mintEnabled) public onlyOwner {
        mintEnabled = _mintEnabled;
    }

    // mint function
    function mint(uint8 v, bytes32 r, bytes32 s, uint16[] memory crookz) external payable {
        require(mintEnabled, "CONTRACT ERROR: minting has not been enabled");
        require(_verify(_hash(msg.sender, crookz), v, r, s, _signer), "CONTRACT ERROR: Invalid signature");
        for(uint16 i=0; i < crookz.length;) {
            _safeMint(msg.sender, crookz[i]);
            unchecked {++i;}
        }
    }
}