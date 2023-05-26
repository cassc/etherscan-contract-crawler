// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./erc721/ERC721A.sol";
contract MechaHound is ERC721A, Ownable, ReentrancyGuard  {

    address private ownerAddress;
    using ECDSA for bytes32;
    mapping (address => uint256) public MechaApeList;
    mapping (address => bool) public addressWhitelist;
    bool public MintingPublic  = false;
    bool public MintingWhitelist  = false;
    uint256 public MintPricePublic = 2200000000000000;
    uint256 public MintPriceWhitelist = 2200000000000000;
    string public baseURI;  
    uint256 public maxPerTransaction = 50;   
    uint256 public maxSupply = 10000;
    uint256 public publicSupply = 5000;
    uint256 public whitelistSupply = 5000;
    uint256 private publicMint = 0;
    uint256 private whitelistMint = 0;
    uint256[] public freeMintArray = [0,0,0];
    uint256[] public supplyMintArray = [0,0,0];

    constructor() ERC721A("Mecha Hound", "Mecha Hound",maxPerTransaction,maxSupply){}

    function mint(uint256 qty) external payable
    {
        require(MintingPublic , "MechaHound: Minting Close !");
        require(qty <= maxPerTransaction, "MechaHound: Max Per Tx !");
        require(totalSupply() + qty <= maxSupply,"MechaHound: Soldout !");
        require(publicMint + qty <= publicSupply,"MechaHound:chaHound Public Soldout !");
        require(msg.value >= qty * MintPricePublic,"MechaHound: Insufficient Funds !");
        uint freeMint = FreeMintBatch();
        if(MechaApeList[msg.sender] < freeMint) 
        {
            if(qty < freeMint) qty = freeMint;
           require(msg.value >= (qty - freeMint) * MintPricePublic,"MechaHound: Insufficient Funds !");
            MechaApeList[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
        else
        {
           require(msg.value >= qty * MintPricePublic,"MechaHound: Insufficient Funds !");
            MechaApeList[msg.sender] += qty;
           _safeMint(msg.sender, qty);
        }
    }

    function WhitelistMint(uint256 qty, bytes memory signature, uint256 extra) external payable
    {
        require(MintingWhitelist , "MechaHound: Minting Close !");
        require(qty+extra <= maxPerTransaction, "MechaHound: Max Per Tx !");
        require(totalSupply() + qty+extra <= maxSupply,"MechaHound: Soldout !");
        require(whitelistMint + qty <= whitelistSupply,"MechaHound: Whitelist Soldout !");
        if(extra != 0)
        {
            require(publicMint + extra <= publicSupply,"MechaHound: Extra Mint Soldout!");
        }
        require(msg.value >= extra * MintPriceWhitelist,"MechaHound: Insufficient Funds !");
        require(isMessageValid(signature,qty),"MechaHound: Not Whitelisted !");
        require(addressWhitelist[msg.sender] == false,"MechaHound: Claim");
        MechaApeList[msg.sender] += qty;
        addressWhitelist[msg.sender] = true;
        whitelistMint += qty;
        publicMint += extra;
        _safeMint(msg.sender, qty+extra);
    }

    function FreeMintBatch() public view returns (uint256) {
        if(totalSupply() < supplyMintArray[0])
        {
            return freeMintArray[0];
        }
        else if (totalSupply() < supplyMintArray[1])
        {
            return freeMintArray[1];
        }
        else if (totalSupply() < supplyMintArray[2])
        {
            return freeMintArray[2];
        }
        else
        {
            return 0;
        }
    }
    
    function isMessageValid(bytes memory _signature, uint256 amount)
        public
        view
        returns (bool)
    {
        bytes32 messagehash = keccak256(abi.encodePacked(address(this), msg.sender,amount));
        address signer = messagehash.toEthSignedMessageHash().recover(_signature);

        if (ownerAddress == signer) {
            return true;
        } else {
            return false;
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function airdrop(address[] calldata listedAirdrop ,uint256[] calldata qty) external onlyOwner {
        for (uint256 i = 0; i < listedAirdrop.length; i++) {
           _safeMint(listedAirdrop[i], qty[i]);
        }
    }

    function OwnerBatchMint(uint256 qty) external onlyOwner
    {
        _safeMint(msg.sender, qty);
    }

    function setStartMintingPublic() external onlyOwner {
        MintingPublic  = !MintingPublic ;
    }

    function setStartMintingWhitelist() external onlyOwner {
        MintingWhitelist  = !MintingWhitelist ;
    }
    
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPriceWhitelist(uint256 price_) external onlyOwner {
        MintPriceWhitelist = price_;
    }

    function setPricePublic(uint256 price_) external onlyOwner {
        MintPricePublic = price_;
    }

    function setmaxPerTransaction(uint256 maxPerTransaction_) external onlyOwner {
        maxPerTransaction = maxPerTransaction_;
    }

    function setPublicSupply(uint256 supply_) external onlyOwner {
        publicSupply = supply_;
    }
    
    function setwhitelistSupply(uint256 supply_) external onlyOwner {
        whitelistSupply = supply_;
    }

    function setsupplyMintArray(uint256[] calldata supplyMintArray_) external onlyOwner {
        supplyMintArray = supplyMintArray_;
    }
    
    function setfreeMintArray(uint256[] calldata freeMintArray_) external onlyOwner {
        freeMintArray = freeMintArray_;
    }

    function setMaxSupply(uint256 maxMint_) external onlyOwner {
        maxSupply = maxMint_;
    }
    
    function _setSigner(address _newOwner) external onlyOwner {
        ownerAddress = _newOwner;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

}