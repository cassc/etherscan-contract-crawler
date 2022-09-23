//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "erc721a/contracts/ERC721A.sol";
import "./MultisigOwnable.sol";

contract ClickChicken is ERC721A, Ownable {
    using Strings for uint256;

    enum Step {
        Before,
        Sale,
        After
    }

    Step public sellingStep;

    bytes32 public _merkleRoot; // OG + WL
    bytes32 public _merkleRootOG; // OG
    string public baseURI;
    string public blindURI;

    uint public MAX_SUPPLY = 4444;
    uint public price; // require
    uint public ALLOW_QUANTITY = 2; // require

    uint public saleStartTime = 1663952400; // 09.23.2022
    uint public saleTimeFrame = 1440 minutes; // 1 day

    address public verifyAccount;

    constructor(
        uint __price,
        bytes32 __merkelRoot,
        bytes32 __merkelRootOG,
        string memory __blindURI,
        address __verifyAccount
    ) ERC721A("Click", "CC") {
        price = __price;
        _merkleRoot = __merkelRoot;
        _merkleRootOG = __merkelRootOG;
        blindURI = __blindURI;
        verifyAccount = __verifyAccount;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    uint public totalClaimedQuantity;
    mapping(address => uint) public claimedQuantity;

    function whitelistMint(uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        require(currentTime() >= saleStartTime, "Whitelist Sale has not started yet");
        require(currentTime() < saleStartTime + saleTimeFrame, "Whitelist Sale is finished");
        require(sellingStep == Step.Sale, "Whitelist sale is not activated");
        require(_quantity > 0, "Not allow quantity 0"); 
        require(isWhiteListed(msg.sender, _proof) || isOGListed(msg.sender, _proof), "Not whitelisted");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(claimedQuantity[msg.sender] + _quantity <= ALLOW_QUANTITY, "You can only purchase 2 NFTs on Minting.");

        uint256 lessAmount;
        if (isOGListed(msg.sender, _proof) && claimedQuantity[msg.sender] < 1) {
            uint seedVal = price * (_quantity - 1);
            require(msg.value >= seedVal, "Not enought funds");
            lessAmount = msg.value - seedVal;
        } else {
            require(msg.value >= price * _quantity, "Not enought funds");
            lessAmount = msg.value - (price * _quantity);
        }
        
        if (lessAmount > 0) payable(msg.sender).transfer(lessAmount);
        payable(verifyAccount).transfer(msg.value - lessAmount);

        claimedQuantity[msg.sender] += _quantity;
        totalClaimedQuantity += _quantity;

        _safeMint(msg.sender, _quantity);
    }

    mapping(address => uint) public publicClaimedQuantity;

    function publicSaleMint(uint _quantity) external payable callerIsUser {
        uint publicStartTime = saleStartTime + saleTimeFrame;

        require(price != 0, "Price is 0"); 
        require(currentTime() >= publicStartTime, "Public Sale has not started yet");
        require(currentTime() < publicStartTime + saleTimeFrame,"Public Sale is finished");
        require(sellingStep == Step.Sale, "Public sale is not activated");
        require(_quantity > 0, "Not allow quantity 0"); 
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(publicClaimedQuantity[msg.sender] + _quantity <= ALLOW_QUANTITY, "You can only purchase 2 NFTs on Minting.");
        require(msg.value >= price * _quantity, "Not enought funds");

        uint256 lessAmount = msg.value - (price * _quantity);
        if (lessAmount > 0) payable(msg.sender).transfer(lessAmount);
        payable(verifyAccount).transfer(price * _quantity);

        publicClaimedQuantity[msg.sender] += _quantity;

        _safeMint(msg.sender, _quantity);
    }

    function promotionMint(address _to, uint _quantity) external payable onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max Supply");
        _safeMint(_to, _quantity);
    }

    function setMaxSupply(uint __newMaxSupply) external onlyOwner {
        MAX_SUPPLY = __newMaxSupply;
    }

    function setSaleStartTime(uint _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        require(sellingStep == Step.After, "Whitelist sale is not activated");
        baseURI = _baseURI;
    }

    function setBlindUri(string memory _blindURI) external onlyOwner {
        blindURI = _blindURI;
    }

    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    //Whitelist
    function setMerkleRoot(bytes32 __merkleRoot) external onlyOwner {
        _merkleRoot = __merkleRoot;
    }

    //OGlist
    function setMerkleRootOG(bytes32 __merkleRootOG) external onlyOwner {
        _merkleRootOG = __merkleRootOG;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : blindURI;
    }

    function currentTime() internal view returns (uint) {
        return block.timestamp;
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof) internal view returns (bool) {
        return _verify(leaf(_account), _proof);
    }

    function isOGListed(address _account, bytes32[] calldata _proof) internal view returns (bool) {
        return _verifyOG(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, _merkleRoot, _leaf);
    }

    function _verifyOG(bytes32 _leaf, bytes32[] memory _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, _merkleRootOG, _leaf);
    }


    //******************************************************//
    //                      Burn                            //
    //******************************************************//
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    function burn(uint256 _tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not owner nor approved");
        _burn(_tokenId);
    }
}