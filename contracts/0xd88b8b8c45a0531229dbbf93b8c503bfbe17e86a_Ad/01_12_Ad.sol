// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**************************************************************************************************

                                                           ##     ## ## ##
                                                         ##:: ## ##:::::: ##
                                     ##                 ##:::: ##:::::::::: ##
                                   ##:: ##             ##:::::::::::::::::- ##
                                 ##:::::: ##           ##:::::::::: ##:::::- ##
                                 ##:::::: ##           ##:::::::: ##   ##:::- ##
                               ##:::::::::: ##         ##:::::: ##     ##:::- ##
                               ##:::::::::: ##         ##:::::: ##     ##:::- ##
                             ##:::::::::::::: ##       ##:::::: ##     ##:::: ##
                             ##:::::: ##:::::: ##       ##:::::: ##     ##:: ##
                             ##:::::: ##:::::: ##       ##:::::: ##   ##:::- ##
                             ##:::::: ##:::::: ##       ##:::::: ## ##:::::: ##
                           ##:::::::: ##:::::: ##       ##:::::: ## ##:::: ##
                           ##:::::: ## ##:::::::: ##     ##:::::: ##:::::: ##
                           ##:::::: ##:::::::::: ##     ##:::::::::::: ##
                           ##:::::::::::::::::: ##     ##:::::::::::: ##
                         ##:::::::::::::::::::: ##     ##:::::::::: ##
                         ##:::::::::: ## ##:::::: ##     ##:::::::: ##
                         ##:::::: ## ##     ##:::: ##       ##:::: ##
                         ##:::::- ##       ##:: ##         ##:: ##
                         ##:::::: ##         ##             ##
                         ##:::: ##
                         ##:::: ##
                         ##:: ##
                         ##:- ##
                         ##:: ##
                           ##

***************************************************************************************************/


import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Ad is ERC721AQueryable, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    enum Status {
        Pending, //0
        PreSale, //1
        PublicSale, //2
        Finished, //3
        PubPreSale //4
    }

    Status private status;

    uint256 private priceWhite = 0.001 ether;
    uint256 private maxMintWhite = 1;

    uint256 private pricePublic = 0.001 ether;
    uint256 private maxMintPublic = 1;

    string private _uri;
    bytes32 private merkleRoot;

    uint256 private maxTotalSupply = 5555;
    uint256 private stageTotalSupply = 444;


    uint256 private curStageSupply = 444; // just view

    address private pubPureSaleSigner;
    mapping(address => uint256) mintStage1Counter;
    mapping(address => uint256) mintStage2Counter;
    mapping(address => uint256) mintStage3Counter;


    event PaymentReleased(address to, uint256 amount);

    constructor(string memory _tokenName, string memory _tokenSymbol) ERC721A(_tokenName, _tokenSymbol) {}


    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return _uri;
    }

    function setURI(string memory _newUri) public virtual onlyOwner {
        _uri = _newUri;
    }

    function mint(uint256 amount) external payable {
        require(status == Status.PublicSale, "ADE006");
        require(maxMintPublic >= amount, "ADE001");
        require(mintStage3Counter[msg.sender] + amount <= maxMintPublic, "ADE008");

        _verifiedPublicFee(amount);
        _verifiedSupply(amount);

        _safeMint(msg.sender, amount);
        mintStage3Counter[msg.sender] = mintStage3Counter[msg.sender] + amount;
    }

    function preSaleMint(uint256 amount, bytes32[] calldata _merkleProof) external payable {
        require(status == Status.PreSale, "ADE006");
        require(verifyMerkle(_merkleProof), 'Invalid proof!');
        require(maxMintWhite >= amount, "ADE001");
        require(mintStage2Counter[msg.sender] + amount <= maxMintWhite, "ADE008");

        _verifiedWhiteFee(amount);
        _verifiedSupply(amount);

        _safeMint(msg.sender, amount);
        mintStage2Counter[msg.sender] = mintStage2Counter[msg.sender] + amount;
    }

    function testSinger(string memory salt, bytes calldata signString) public view returns (address){
        bytes32 hash = keccak256(abi.encode(salt, "cx", msg.sender));
        address signerAddress = hash.toEthSignedMessageHash().recover(signString);
        return signerAddress;
    }

    function _verifySinger(string memory salt, bytes calldata signString) private view returns (bool){
        bytes32 hash = keccak256(abi.encode(salt, "cx", msg.sender));
        address signerAddress = hash.toEthSignedMessageHash().recover(signString);
        return signerAddress == pubPureSaleSigner;
    }

    function prePublicMint(uint256 amount, string calldata salt, bytes calldata signString) external payable {
        uint8 maxMint = 1;
        require(status == Status.PubPreSale, "ADE006");
        require(_verifySinger(salt, signString), "Invalid proof!");
        require(maxMint >= amount, "ADE001");
        require(mintStage1Counter[msg.sender] + amount <= maxMint, "ADE008");

        _safeMint(msg.sender, amount);
        mintStage1Counter[msg.sender] = mintStage1Counter[msg.sender] + amount;
    }

    function setPrePubSigner(address pubPreSigner) external onlyOwner {
        pubPureSaleSigner = pubPreSigner;
    }

    function _verifiedWhiteFee(uint256 num) private {
        require(num > 0, 'ADE011');
        require(msg.value >= priceWhite * num, 'ADE002');
        if (msg.value > priceWhite * num) {
            payable(msg.sender).transfer(msg.value - priceWhite * num);
        }
    }

    function _verifiedPublicFee(uint256 num) private {
        require(num > 0, 'ADE011');
        require(msg.value >= pricePublic * num, 'ADE002');
        if (msg.value > pricePublic * num) {
            payable(msg.sender).transfer(msg.value - pricePublic * num);
        }
    }

    function _verifiedSupply(uint256 num) private view {
        require(totalSupply() + num <= maxTotalSupply, "ADE003");
        require(totalSupply() + num <= stageTotalSupply, "ADE012");
        //        require(tx.origin == msg.sender, "ADE007");
    }

    function withdraw() public virtual nonReentrant onlyOwner {
        require(address(this).balance > 0, "ADE005");
        Address.sendValue(payable(owner()), address(this).balance);
        emit PaymentReleased(owner(), address(this).balance);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function verifyMerkle(bytes32[] calldata _merkleProof) public view returns (bool){
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function setStatus(Status _status, uint256 _amount, uint256 _price, uint256 _stageTotalSupply, uint256 _stageSupply) public onlyOwner {
        status = _status;
        stageTotalSupply = _stageTotalSupply;

        if (status == Status.PreSale) {
            priceWhite = _price;
            maxMintWhite = _amount;
        } else {
            pricePublic = _price;
            maxMintPublic = _amount;
        }
        curStageSupply = _stageSupply;
    }


    function getStatus() public view returns (Status _status, uint256 _price, uint256 _amount, uint256 _stageTotalSupply, uint256 _maxTotalSupply, uint256 stageSupply) {
        if (status == Status.PreSale) {
            return (status, priceWhite, maxMintWhite, stageTotalSupply, maxTotalSupply, curStageSupply);
        } else {
            return (status, pricePublic, maxMintPublic, stageTotalSupply, maxTotalSupply, curStageSupply);
        }
    }

    function devMint() external onlyOwner {
        _verifiedSupply(1);
        _safeMint(msg.sender, 1);
    }

    function mintedStage() external view returns (uint256) {
        if (status == Status.PubPreSale) {
            return mintStage1Counter[msg.sender];
        } else if (status == Status.PreSale) {
            return mintStage2Counter[msg.sender];
        } else if (status == Status.PublicSale) {
            return mintStage3Counter[msg.sender];
        } else {
            return _numberMinted(msg.sender);
        }
    }

    function mintedAll() external view returns (uint256) {
        return _numberMinted(msg.sender);
    }
}