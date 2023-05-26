// SPDX-License-Identifier: MIT

// █▀▀ █▀█ █▀█ █▀▄   █▀▄▀█ █▀█ █▄░█ █▄▀ █▀▀ █▄█ ▀█
// █▄█ █▄█ █▄█ █▄▀   █░▀░█ █▄█ █░▀█ █░█ ██▄ ░█░ █▄
// ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄
// ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░

pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface GMLTDEDITIONS {
    function burnToken(address, uint256 id) external; 
}

contract GoodMonkeyz is ERC721A, Ownable {
    address public GMEditionsAddress = 0x66722f13F6e5dcEB94c5F2aB8e6A2028039e8393;
    uint256 public MINT_PASS_ID = 1;
    uint256 public BOOSTER_PACK_ID = 2;
    uint256 public GENERAL_SUPPLY = 9000;
    uint256 public ALLOW_MAX = 8000;
    uint256 public MINTPASS_MAX = 250;
    uint256 public BOOSTER_MAX = 250;
    uint256 public publicMintMax = 2;
    uint256 public allowMintMax = 2;
    uint256 public price = 0.077 ether;
    uint256 public doublePrice = 0.1337 ether;
    uint256 public mintPassUsed;
    uint256 public boosterPacksOpened;
    string public provenanceHash;
    string public prizeListHash;
    uint256 public startingIndex;
    uint256 public prizeIndex;
    bool public povenanceSet = false;
    bool public indexSet = false;
    bool public PUBLIC = false;
    bool public ALLOW = false;
    bool public MINTPASS = false;
    bool public BOOSTER = false;
    string private baseURI = 'ipfs://QmUuz2qxTVWuCpxyjUVZtkNshfkKHcCug4Qhx9uhJCc4tM/';
    string private _contractURI = 'ipfs://QmcGBEcv4phdTBswX5NwNmq1rq7ux8Xiy5QefyLLkynmM1';

    mapping(address => uint256) public mintList;

    event GMMinted(address sender, uint256 tokenId, uint256 amount);

    event AllowStatus(bool status);
    event PublicStatus(bool status);
    event MintPassStatus(bool status);
    event BoostStatus(bool status);

    constructor() ERC721A("GoodMonkeyz", "GM") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory newURI) external onlyOwner () {
        baseURI = newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setMerchAddress(address _GMEditionsAddress) public onlyOwner {
        GMEditionsAddress = _GMEditionsAddress;
    }
    
    function setProvenance(string memory _provenanceHash, string memory _prizeListHash) external onlyOwner {
        require(povenanceSet == false , "PROVENANCE CANNOT BE RESET");
        provenanceHash = _provenanceHash;
        prizeListHash = _prizeListHash;
        povenanceSet = true;
    }

    function setNewPrice(uint256 _price, uint256 _doublePrice) external onlyOwner {
        price = _price;
        doublePrice = _doublePrice;
    }
    
    function setNewPublicMax(uint256 _max) external onlyOwner {
        publicMintMax = _max;
    }

    function setNewAllowMax(uint256 _max) external onlyOwner {
        allowMintMax = _max;
    }

    function flipPublicState() external onlyOwner {
        PUBLIC = !PUBLIC;
        emit PublicStatus(PUBLIC);
    }

    function flipAllowState() external onlyOwner {
        ALLOW = !ALLOW;
        emit AllowStatus(ALLOW);
    }

    function flipPassState() external onlyOwner {
        MINTPASS = !MINTPASS;
        emit MintPassStatus(MINTPASS);
    }

    function flipBoosterState() external onlyOwner {
        BOOSTER = !BOOSTER;
        emit BoostStatus(BOOSTER);
    }

    function genStartingIndex() external onlyOwner {
        require(povenanceSet, "PROVENANCE MUST BE SET FIRST");
        require(indexSet == false, "INDEX CANNOT BE RESET");
        startingIndex = uint(blockhash(block.number - 1)) % 10000;
        prizeIndex = uint(blockhash(block.number - 1)) % 8000;
        indexSet = true;
    }

    function mint(uint256 _amount) external payable{
        require(PUBLIC , "MINTING - NOT OPEN");
        require(_amount <= publicMintMax , "ABOVE MAX MONKEYZ PER TX");
        require(msg.value >= price * _amount, "Not enough ETH sent");
        require(totalSupply() + _amount <= publicAllocation(), "Public Allocation Sold out");
        require(msg.sender == tx.origin, "no bots"); 

        emit GMMinted(msg.sender, _currentIndex, _amount);
        _safeMint( msg.sender, _amount);
    }

    function recoverSigner(address _address, bytes memory signature) public pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_address))
            )
        );
        return ECDSA.recover(messageDigest, signature);
    }

    function mintAllow(uint256 _amount, bytes memory signature) external payable {
        require(ALLOW , "MINTING ALLOW LIST - NOT OPEN");
        require(msg.value >= calcPrice(_amount), "Not enough ETH sent");
        require(totalSupply() + _amount <= ALLOW_MAX + mintPassUsed , "ALLOW list Sold out");
        require(recoverSigner(msg.sender, signature) == owner(), "Address is not allowlisted");
        require(mintList[msg.sender] + _amount <= allowMintMax, "ABOVE MAX MINTS RESERVED");

        emit GMMinted(msg.sender, _currentIndex, _amount);
        _safeMint( msg.sender, _amount);
        mintList[msg.sender] += _amount ;
    }

    function calcPrice(uint256 _amount) internal view returns (uint256){
        if(_amount == 2){
            return doublePrice;
        } else {
            return _amount * price;
        }
    }

    function mintWithPass() external {
        require(MINTPASS , "MINTING WITH PASS - NOT OPEN");
        require(mintPassUsed < MINTPASS_MAX, "MINT PASS ALLOCATION USED");
        
        GMLTDEDITIONS(GMEditionsAddress).burnToken(msg.sender, MINT_PASS_ID);

        emit GMMinted(msg.sender, _currentIndex, 1);
        ++mintPassUsed;
        _safeMint( msg.sender, 1);
    }

    function mintWithBoosterPack() external {
        require(BOOSTER , "MINTING WITH BOOSTER PACK - NOT OPEN");
        require(boosterPacksOpened < BOOSTER_MAX, "BOOSTER PACK ALLOCATION USED");
        
        GMLTDEDITIONS(GMEditionsAddress).burnToken(msg.sender, BOOSTER_PACK_ID);

        emit GMMinted(msg.sender, _currentIndex, 3);
        ++boosterPacksOpened;
        _safeMint( msg.sender, 3);
    }

    function publicAllocation() internal view returns (uint256){
        return GENERAL_SUPPLY + mintPassUsed + boosterPacksOpened*3;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    function withdraw() public onlyOwner() {
        uint256 balance = address(this).balance;
        (bool success, ) = (msg.sender).call{ value: balance }("");
        require(success, "Failed to widthdraw Ether");
    }
}