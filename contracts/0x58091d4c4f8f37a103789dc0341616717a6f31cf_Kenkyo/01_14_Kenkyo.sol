// contracts/Kenkyo.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./merkle/MerkleProof.sol";

contract Kenkyo is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // bool
    bool public _isPresaleRequired = false;
    bool public _isReserveListRequired = false;

    // addresses
    address _owner;

    // integers
    uint256 public totalPublicSupply;
    uint256 public totalGiftSupply;

    uint256 public MAX_GIFT_SUPPLY = 13;
    uint256 public MAX_PUBLIC_SUPPLY = 764;

    uint256 public PRICE = 0.149 ether;

    // bytes
    bytes32 presaleMerkleRoot;
    bytes32 reserveMerkleRoot;

    string private _tokenBaseURI = 'ipfs://bafkreicjjoozqbjmy7e3ppgfmxaedqtddzmjflpzazlhjtfsv3b2rmuf5u';
    string private _tokenRevealedBaseURI = '';

    constructor(bytes32 _presaleMerkleRoot, bytes32 _reserveMerkleRoot) ERC721A("Kenkyo", "KENKYO") {
        _owner = msg.sender;
        presaleMerkleRoot = _presaleMerkleRoot;
        reserveMerkleRoot = _reserveMerkleRoot;
    }

    function setPresaleRequired() external onlyOwner {
        _isPresaleRequired = !_isPresaleRequired;
    }

    function setReserveListRequired() external onlyOwner {
        _isReserveListRequired = !_isReserveListRequired;
    }

    function setBaseUri(string memory tokenBaseUri) external onlyOwner {
        _tokenBaseURI = tokenBaseUri;
    }

    function setRevealedBaseUri(string memory tokenRevealedBaseUri) external onlyOwner {
        _tokenRevealedBaseURI = tokenRevealedBaseUri;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        PRICE = newPrice;
    }

    function setPresaleRoot(bytes32 newPresaleRoot) external onlyOwner {
        presaleMerkleRoot = newPresaleRoot;
    }

    function setReserveRoot(bytes32 newReserveRoot) external onlyOwner {
        reserveMerkleRoot = newReserveRoot;
    }

    /*
    MINTING FUNCTIONS
    */

    /**
     * @dev Public mint function
     */
    function mint(bytes32[] calldata proof) nonReentrant payable external {
        require(msg.sender == tx.origin);
        require(_isPresaleRequired || _isReserveListRequired, "Minting is not available");
        require(
            totalPublicSupply < MAX_PUBLIC_SUPPLY,
            "Tokens have all been minted"
        );

        require(
            _numberMinted(msg.sender) == 0,
            "This address already minted"
        );
        
        // check allowlists
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            (_isPresaleRequired && MerkleProof.verify(proof, presaleMerkleRoot, leaf)) ||
            (_isReserveListRequired && MerkleProof.verify(proof, reserveMerkleRoot, leaf))            
        , 'Proof is invalid');

        require(msg.value == PRICE, "Wrong amount of ether");

        totalPublicSupply += 1;

        _safeMint(msg.sender, 1);
    }

    /**
     * @dev Mint gift tokens for the contract owner
     */
    function mintGifts(uint256 _times) external onlyOwner {
        require(
            totalGiftSupply + _times <= MAX_GIFT_SUPPLY,
            "Must mint fewer than the maximum number of gifted tokens"
        );

        for(uint256 i=0; i<_times; i++) {
            totalGiftSupply += 1;
            _safeMint(msg.sender, 1);
        }
    }

    // Read functions
    function getClaimed(address _address) public view returns (bool hasClaimed) {
        hasClaimed = !(_numberMinted(_address) == 0);
        return hasClaimed;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');

        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return bytes(revealedBaseURI).length > 0 ?
            string(abi.encodePacked(revealedBaseURI, tokenId.toString(), '.json')) :
            _tokenBaseURI;
    }

    function addressIsAllowedPresale(address _address, bytes32[] calldata proof) public view returns (bool isAllowlisted) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        isAllowlisted = MerkleProof.verify(proof, presaleMerkleRoot, leaf);
        return isAllowlisted;
    }

    function addressIsAllowedReserve(address _address, bytes32[] calldata proof) public view returns (bool isAllowlisted) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        isAllowlisted = MerkleProof.verify(proof, reserveMerkleRoot, leaf);
        return isAllowlisted;
    }

    /**
     * @dev Withdraw ETH to owner
     */
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

}