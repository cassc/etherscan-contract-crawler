// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import "ERC721A/ERC721A.sol";

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

contract NFTSensei is Ownable, ERC721A, ReentrancyGuard {
    enum SalesPhase {
        CLOSED,
        PARTNER_LIST,
        SENSEI_LIST,
        PREFERRED_LIST,
        PUBLIC
    }

    SalesPhase public _phase = SalesPhase.CLOSED;
    bytes32 public _merkleRoot;
    uint256 public _maxSupply;
    uint256 public _mintPrice;
    uint256 public _devSupplyRemaining;
    string private _baseUri;

    mapping(address => mapping(SalesPhase => bool)) public _salesPhaseMinted;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(
        uint256 devSupply,
        uint256 publicSupply,
        uint256 mintPrice
    ) ERC721A("NFT Sensei", "SENSEI") {
        _devSupplyRemaining = devSupply;
        _maxSupply = publicSupply + devSupply;
        _mintPrice = mintPrice;
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(_devSupplyRemaining >= quantity, "Supply exceeded");
        _devSupplyRemaining -= quantity;
        _mint(msg.sender, quantity);
    }

    function setSalesPhase(SalesPhase phase, bytes32 merkleRoot)
        external
        onlyOwner
    {
        _phase = phase;
        _merkleRoot = merkleRoot;
    }

    function _verifyMerkleProof(bytes32[] calldata proof) internal view {
        require(_merkleRoot != 0, "No merkle root set");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(proof, _merkleRoot, leaf),
            "Invalid merkle proof"
        );
    }

    function privateMintStarted() public view returns (bool) {
        return
            _phase == SalesPhase.PREFERRED_LIST ||
            _phase == SalesPhase.SENSEI_LIST ||
            _phase == SalesPhase.PARTNER_LIST;
    }

    function _senderCanMintPhase() private view returns (bool) {
        return
            _phase == SalesPhase.PUBLIC ||
            !_salesPhaseMinted[msg.sender][_phase];
    }

    function _registerPrivateMint() private {
        _salesPhaseMinted[msg.sender][_phase] = true;
    }
 
    function publicMint(uint192 quantity) external payable callerIsUser nonReentrant {
        require(quantity > 0, "Must set a positive quantity");
        require(_phase == SalesPhase.PUBLIC, "Public mint not started");
        require(totalSupply() + quantity <= _maxSupply, "Supply exhausted");
        require(msg.value >= _mintPrice * quantity, "Need to send more ETH.");

        _mint(msg.sender, quantity);
    }

    function privateMint(bytes32[] calldata proof)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(privateMintStarted(), "Private minting not open");
        require(totalSupply() < _maxSupply, "Supply exhausted");
        require(_senderCanMintPhase(), "Can't mint any more in this phase");
        require(msg.value >= _mintPrice, "Need to send more ETH.");

        _verifyMerkleProof(proof);
        _registerPrivateMint();
        _mint(msg.sender, 1);
    }

    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        _maxSupply = maxSupply;
    }

    function setMintPrice(uint256 mintPrice) external onlyOwner {
        _mintPrice = mintPrice;
    }

    // Metadata
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawEther() external onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}