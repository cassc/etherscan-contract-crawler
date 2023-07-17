// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';


contract OctoronRiftGenesis is ERC1155, Ownable, PaymentSplitter, ReentrancyGuard {
    using ECDSA for bytes32;

    // public vars
    uint256 public maxSupplyPerToken = 296; // 3 ids = 888 total tokens
    mapping (uint256 => uint256) public tokenSupply;
    string private _contractUri = "";
    string public name = "OctoronRiftGenesis";
    string public symbol = "ORG";
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
    ERC1155(_initBaseURI)
        PaymentSplitter(_sharesAddresses, _sharesEquity){
        _signer = signer;
    }

    // get total supply per id
    function totalSupply(uint256 id) public view returns (uint256) {
        return tokenSupply[id];
    }

    // metadata
    function setBaseUri(string calldata newUri) public onlyOwner {
        _setURI(newUri);
    }

    function setContractUri(string calldata newUri) public onlyOwner {
        _contractUri = newUri;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    // using signer technique for managing approved minters
    function updateSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    function _hash(address _address, uint amount, uint allowedAmount, uint256 id, uint cost) internal view returns (bytes32){
        return keccak256(abi.encode(address(this), _address, amount, allowedAmount, id, cost));
    }

    function _verify(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view returns (bool){
        return (ecrecover(hash, v, r, s) == _signer);
    }

    // enable / disable minting
    function setMintState(bool _mintingEnabled) public onlyOwner {
        mintingEnabled = _mintingEnabled;
    }

    // minting function
    function mint(uint8 v, bytes32 r, bytes32 s, uint256 amount, uint256 allowedAmount, uint256 id) public payable {
        require(mintingEnabled, "CONTRACT ERROR: minting has not been enabled");
        require(claimedTokens[msg.sender] + amount <= allowedAmount, "CONTRACT ERROR: Address has already claimed max amount");
        require(totalSupply(id) + amount <= maxSupplyPerToken, "CONTRACT ERROR: not enough remaining in supply to support desired mint amount");
        require(_verify(_hash(msg.sender, amount, allowedAmount, id, msg.value), v, r, s), "CONTRACT ERROR: Invalid signature");
        _mint(msg.sender, id, amount, "");
        claimedTokens[msg.sender] += amount;
        tokenSupply[id] += amount;
    }

}