// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FpxMetaverse is ERC721A, Ownable, Pausable {
    enum FpxMintStatus {
        NOTACTIVE,
        ALLOWLIST_MINT,
        PUBLIC_MINT,
        CLOSED
    }

    FpxMintStatus public mintStatus;
    string public baseTokenURI;
    string public defaultTokenURI;
    uint256 public maxSupply = 2019;
    uint256 public publicSalePrice;
    uint256 public allowlistSalePrice;
    bytes32 private _merkleRoot;
    address payable public payment;

    mapping(address => bool) public allowlistSaleResult;
    mapping(address => bool) public publicSaleResult;

    constructor(
        string memory _baseTokenURI,
        string memory _defaultTokenURI,
        uint256 _publicSalePrice,
        uint256 _allowListSalePrice,
        bytes32 _MerkleRoot,
        address _paymentAddress
    ) ERC721A("FpxMetaverse", "FPX") {
        baseTokenURI = _baseTokenURI;
        defaultTokenURI = _defaultTokenURI;
        _merkleRoot = _MerkleRoot;
        publicSalePrice = _publicSalePrice;
        allowlistSalePrice = _allowListSalePrice;
        payment = payable(_paymentAddress);
        _pause();
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function mint() external payable callerIsUser whenNotPaused {
        require(mintStatus == FpxMintStatus.PUBLIC_MINT, "Public sale closed");
        require(totalSupply() + 1 <= maxSupply, "Exceed supply");
        require(msg.value >= publicSalePrice, "Value not enough");
        require(
            !publicSaleResult[msg.sender],
            "This address has finished public mint"
        );
        publicSaleResult[msg.sender] = true;
        _safeMint(msg.sender, 1);

        uint256 refundamount = msg.value - publicSalePrice;
        if (refundamount > 0) {
            refundIfOver(refundamount);
        }
    }

    function allowListMint(bytes32[] calldata merkleProof)
        external
        payable
        callerIsUser
        whenNotPaused
    {
        require(
            mintStatus == FpxMintStatus.ALLOWLIST_MINT,
            "Allowlist sale closed"
        );
        require(totalSupply() + 1 <= maxSupply, "Exceed supply");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, _merkleRoot, leaf),
            "Invalid merkle proof"
        );
        require(msg.value >= allowlistSalePrice, "Value not enough");
        require(
            !allowlistSaleResult[msg.sender],
            "This address has finished allowlisted mint"
        );
        allowlistSaleResult[msg.sender] = true;
        _safeMint(msg.sender, 1);

        uint256 refundamount = msg.value - allowlistSalePrice;
        if (refundamount > 0) {
            refundIfOver(refundamount);
        }
    }

    function setPublicMintStatus(uint256 status) external onlyOwner {
        require(FpxMintStatus(status) > mintStatus, "Invalid Status");
        mintStatus = FpxMintStatus(status);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : defaultTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function openMint() public onlyOwner {
        _unpause();
    }

    function closeMint() public onlyOwner {
        _pause();
    }

    function refundIfOver(uint256 refundamount) private {
        (bool success, ) = msg.sender.call{value: refundamount}("");
        require(success, "Transfer failed.");
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payment.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}