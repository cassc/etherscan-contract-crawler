// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A/contracts/extensions/ERC721AQueryable.sol";

contract OutSad is ERC721AQueryable, Ownable, ReentrancyGuard {

    enum Status {Pending, PreSale, PublicSale, Finished, PAUSE}

    Status private status;

    uint256 private priceWhite = 0.1 ether;
    uint256 private maxMintWhite = 2;

    uint256 private maxMintSuperWhite = 10;

    uint256 private pricePublic = 0.15 ether;
    uint256 private maxMintPublic = 2;

    string private _uri;
    bytes32 private merkleRoot;
    bytes32 private superMerkleRoot;

    uint256 private maxTotalSupply = 5000;
    uint256 private stageTotalSupply = 1500;


    event PaymentReleased(address to, uint256 amount);

    constructor(string memory _tokenName, string memory _tokenSymbol) ERC721A(_tokenName, _tokenSymbol) {}


    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return _uri;
    }

    function setURI(string memory _newUri) public virtual onlyOwner {
        _uri = _newUri;
    }

    function mint(uint256 amount) external payable {
        require(status == Status.PublicSale, "SUM006");
        require(maxMintPublic >= amount, "SUM001");
        require(_numberMinted(msg.sender) + amount <= maxMintPublic, "SUM008");

        _verifiedPublicFee(amount);
        _verifiedSupply(amount);

        _safeMint(msg.sender, amount);
    }

    function preSaleMint(uint256 amount, bytes32[] calldata _merkleProof) external payable {
        require(status == Status.PreSale, "SUM006");
        require(verifyMerkle(_merkleProof), 'Invalid proof!');
        require(maxMintWhite >= amount, "SUM001");
        require(_numberMinted(msg.sender) + amount <= maxMintWhite, "SUM008");

        _verifiedWhiteFee(amount);
        _verifiedSupply(amount);

        _safeMint(msg.sender, amount);
    }

    function superPreSaleMint(uint256 amount, bytes32[] calldata _merkleProof) external payable {
        require(status == Status.PreSale, "SUM006");
        require(verifySuperMerkle(_merkleProof), 'Invalid proof!');
        require(maxMintSuperWhite >= amount, "SUM001");
        require(_numberMinted(msg.sender) + amount <= maxMintSuperWhite, "SUM008");

        _verifiedWhiteFee(amount);
        _verifiedSupply(amount);

        _safeMint(msg.sender, amount);
    }


    function _verifiedWhiteFee(uint256 num) private {
        require(num > 0, 'SUM011');
        require(msg.value >= priceWhite * num, 'SUM002');
        if (msg.value > priceWhite * num) {
            payable(msg.sender).transfer(msg.value - priceWhite * num);
        }
    }

    function _verifiedPublicFee(uint256 num) private {
        require(num > 0, 'SUM011');
        require(msg.value >= pricePublic * num, 'SUM002');
        if (msg.value > pricePublic * num) {
            payable(msg.sender).transfer(msg.value - pricePublic * num);
        }
    }

    function _verifiedSupply(uint256 num) private view {
        require(totalSupply() + num <= maxTotalSupply, "SUM003");
        require(totalSupply() + num <= stageTotalSupply, "SUM012");
//        require(tx.origin == msg.sender, "SUM007");
    }

    function withdraw() public virtual nonReentrant onlyOwner {
        require(address(this).balance > 0, "SUM005");
        Address.sendValue(payable(owner()), address(this).balance);
        emit PaymentReleased(owner(), address(this).balance);
    }


    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setSuperMerkleRoot(bytes32 _superMerkleRoot) public onlyOwner {
        superMerkleRoot = _superMerkleRoot;
    }

    function verifyMerkle(bytes32[] calldata _merkleProof) public view returns (bool){
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function verifySuperMerkle(bytes32[] calldata _superMerkleProof) public view returns (bool){
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        return MerkleProof.verify(_superMerkleProof, superMerkleRoot, leaf);
    }

    function setStatus(Status _status, uint256 _amount, uint256 _price, uint256 _stageTotalSupply, uint256 _maxMintSuperWhite) public onlyOwner {
        status = _status;

        if (status == Status.PreSale) {
            priceWhite = _price;
            maxMintWhite = _amount;

            stageTotalSupply = _stageTotalSupply;
            maxMintSuperWhite = _maxMintSuperWhite;
        } else if (status == Status.PublicSale) {
            pricePublic = _price;
            maxMintPublic = _amount;

            stageTotalSupply = _stageTotalSupply;
        }
    }


    function getStatus() public view returns (Status _status, uint256 _price, uint256 _amount, uint256 _stageTotalSupply, uint256 _maxTotalSupply, uint256 _maxMintSuperWhite) {
        if (status == Status.PreSale) {
            return (status, priceWhite, maxMintWhite, stageTotalSupply, maxTotalSupply, maxMintSuperWhite);
        } else {
            return (status, pricePublic, maxMintPublic, stageTotalSupply, maxTotalSupply, maxMintSuperWhite);
        }
    }

    address private partnerProxyAddress;
    uint256 private partnerLimit;
    uint256 private partnerPrice;

    function setPartner(address partner, uint256 limit, uint256 price) external onlyOwner {
        partnerProxyAddress = partner;
        partnerLimit = limit;
        partnerPrice = price;
    }

    function partnerSale(address receiver, uint256 amount) external payable {
        require(msg.sender == partnerProxyAddress, 'not partner');
        require(_numberMinted(msg.sender) + amount <= partnerLimit, 'reach limit');
        require(msg.value >= partnerPrice * amount, 'SUM002');
        _verifiedSupply(amount);

        _safeMint(receiver, amount);
    }

    function devMint() external onlyOwner {
        _verifiedSupply(1);
        _safeMint(msg.sender, 1);
    }

    function teamMint(address toAddress, uint256 amount) external onlyOwner {
        _safeMint(toAddress, amount);
    }

    function minted() external view returns (uint256) {
        return _numberMinted(msg.sender);
    }
}