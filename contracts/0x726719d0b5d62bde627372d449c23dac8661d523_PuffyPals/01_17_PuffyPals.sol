// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';


contract PuffyPals is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {
    using ECDSA for bytes32;

    // public vars
    uint256 public maxSupply = 10000;
    string public baseURI;
    bool public mintingEnabled = true;
    mapping(address => uint) public claimedTokens;

    // private vars
    address private _signer;

    constructor(
        string memory _initBaseURI,
        address[] memory _sharesAddresses,
        uint[] memory _sharesEquity,
        address signer
    )
    ERC721A("PuffyPals", "PP")
        PaymentSplitter(_sharesAddresses, _sharesEquity){
        setURI(_initBaseURI);
        _signer = signer;
    }

    // read metadata
	function _baseURI() internal view virtual override returns (string memory) {
	    return baseURI;
	}

    // set metadata
    function setURI(string memory _newBaseURI) public onlyOwner {
	    baseURI = _newBaseURI;
	}

    // using signer technique for managing approved minters
    function updateSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    function _hash(address _address, uint amount, uint allowedAmount, uint cost) internal view returns (bytes32){
        return keccak256(abi.encode(address(this), _address, amount, allowedAmount, cost));
    }

    function _verify(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view returns (bool){
        return (ecrecover(hash, v, r, s) == _signer);
    }

    // enable / disable minting
    function setMintState(bool _mintingEnabled) public onlyOwner {
        mintingEnabled = _mintingEnabled;
    }

    // minting function
    function mint(uint8 v, bytes32 r, bytes32 s, uint256 amount, uint256 allowedAmount) public payable {
        require(mintingEnabled, "CONTRACT ERROR: minting has not been enabled");
        require(claimedTokens[msg.sender] + amount <= allowedAmount, "CONTRACT ERROR: Address has already claimed max amount");
        require(totalSupply() + amount <= maxSupply, "CONTRACT ERROR: not enough remaining in supply to support desired mint amount");
        require(_verify(_hash(msg.sender, amount, allowedAmount, msg.value), v, r, s), 'CONTRACT ERROR: Invalid signature');
        _safeMint(msg.sender, amount);
        claimedTokens[msg.sender] += amount;
    }

}