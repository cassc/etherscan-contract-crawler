//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Modules is ERC721URIStorage, ERC721Burnable, Ownable, VRFConsumerBase {
    enum ContractStatus {
        AllowListOnly,
        Public, 
        Paused
    }

    // Contract control
    ContractStatus public contractStatus = ContractStatus.Paused;
    bytes32 public addressMerkleRoot;
    bytes32 public quantityMerkleRoot;

    // Tokenization
    uint256 public price;
    string  public baseURI;
    uint256 public totalSupply;

    // Counters
    using Counters for Counters.Counter;
    Counters.Counter private _totalMinted;
    mapping(uint256 => uint256) public remainingSupplyCache;
    mapping(address => uint256) public quantityMinted;

     // Chainlink VRF
    bytes32 internal keyHash; // This is how we specify the oracle to use for VRF
    uint256 internal linkFee; // The fee we pay to chainlink to get the random number
    uint256 private randomResult; // storage location for the random number result

    // Events
    event RandomnessFulfilled(bytes32 requestID);
    event AssignedTokenID(address indexed _for, uint256 _tokenID);
    event MintTokenCalled(address indexed _who, uint256 _quantity);
    event RemainingSupply(uint256 supply); 

    constructor(bytes32 _alMerkleRoot, bytes32 _quantityMerkleRoot, address vrfCoordinator, address linkTokenAddress, bytes32 kHash, string memory contractBaseURI)
    ERC721 ("hausphases", "HAUS")
    VRFConsumerBase(vrfCoordinator, linkTokenAddress) {
        addressMerkleRoot = _alMerkleRoot;
        quantityMerkleRoot = _quantityMerkleRoot;
        baseURI = contractBaseURI;
        totalSupply = 7777;
        price = 0.02 ether;
        keyHash = kHash;
        linkFee = 2 * 10 ** 18;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function getTokenIdFromRandomNumber(uint256 randomNumber) internal returns(uint256) {
        uint256 index = remainingSupplyCache[randomNumber] == 0 ? randomNumber : remainingSupplyCache[randomNumber];

        // grab a number from the tail
        uint256 remainingSupply = totalSupply - _totalMinted.current();
        remainingSupplyCache[randomNumber] = remainingSupplyCache[remainingSupply - 1] == 0 ? remainingSupply - 1 : remainingSupplyCache[remainingSupply - 1];
        delete remainingSupply;

        return index;
    }

    function mint(uint256 quantity, bytes32[] calldata proof) public payable {
        emit MintTokenCalled(msg.sender, quantity);

        require(quantity <= 10, "Max 10 per txn");
        require(_totalMinted.current() + quantity <= totalSupply, "Not enough supply");
        require(contractStatus != ContractStatus.Paused, "Minting currently paused");
        require(msg.value >= price * quantity, "Not enough ETH sent"); 

        if(contractStatus == ContractStatus.AllowListOnly) {
            require(isWhitelist(msg.sender, proof), "Minting currently WL only");
        }

        mintQuantity(quantity);
    }

    function devMint(uint256 quantity, uint256 allowedQuantity, bytes32[] calldata proof) public {
        emit MintTokenCalled(msg.sender, quantity);

        require(quantity <= 10, "Max 10 per txn");
        require(_totalMinted.current() + quantity <= totalSupply, "Not enough supply");
        require(contractStatus != ContractStatus.Paused, "Minting currently paused");
        require(canMint(msg.sender, allowedQuantity, proof), "Requested quantity not approved");
        require(quantityMinted[msg.sender] + quantity <= allowedQuantity, "Exceeds allowed mint quantity");

        mintQuantity(quantity);

        quantityMinted[msg.sender] = quantityMinted[msg.sender] + quantity;
    }

    function mintQuantity(uint256 quantity) private {
        for (uint256 i = 0; i < quantity; i++) {
            uint256 randomValue = uint256(keccak256(abi.encode(randomResult, i))) % (totalSupply - _totalMinted.current());
            uint256 tokenID = getTokenIdFromRandomNumber(randomValue);
            emit AssignedTokenID(msg.sender, tokenID);

            _safeMint(msg.sender, tokenID);
            _setTokenURI(tokenID, Strings.toString(tokenID));

            delete randomValue;
            delete tokenID;

            _totalMinted.increment();
            emit RemainingSupply(totalSupply - _totalMinted.current());
        }
    }

    /** 
    * Requests randomness 
    */
    function loadRandomNumber() public onlyOwner {
        require(LINK.balanceOf(address(this)) >= linkFee, "Not enough LINK in contract");
        requestRandomness(keyHash, linkFee);
    }

    /**
    * Callback function used by VRF Coordinator
    */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        emit RandomnessFulfilled(requestId);
        randomResult = randomness;
    }

    function setContractStatus(ContractStatus status) public onlyOwner {
        contractStatus = status;
    }

    function isWhitelist(address account, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, addressMerkleRoot, generateAddressMerkleLeaf(account));
    }

    function canMint(address account, uint256 allowedQuantity, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, quantityMerkleRoot, generateDevMintMerkleLeaf(account, allowedQuantity));
    }

    function generateAddressMerkleLeaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function generateDevMintMerkleLeaf(address account, uint256 allowedQuantity) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, allowedQuantity));
    }

    function setAddressMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        addressMerkleRoot = _merkleRoot;
    }

    function setQuantityMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        quantityMerkleRoot = _merkleRoot;
    }

    function getQuantityMinted() public view returns (uint256) {
        return _totalMinted.current();
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address haus = payable(0xb386e92aCf9279cebb13389811C22b77cC649Bd6);
        address youngworld = payable(0x433e7F8e28cDd827016f656b25cE9ef46558844A);

        bool success;

        (success, ) = haus.call{value: (sendAmount * 850/1000)}("");
        require(success, "Transaction Unsuccessful");

        (success, ) = youngworld.call{value: (sendAmount * 150/1000)}("");
        require(success, "Transaction Unsuccessful");
    }
}