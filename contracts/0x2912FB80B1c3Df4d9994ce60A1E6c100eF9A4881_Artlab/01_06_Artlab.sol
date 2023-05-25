// SPDX-License-Identifier: MIT
//      _   ____________  ______   
//     / | / / ____/ __ \/ ____/   
//    /  |/ / __/ / / / / /        
//   / /|  / /___/ /_/ / /___   
//  /_/ |_/_____/\____/\____/   

pragma solidity ^0.8.4;
import "contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Artlab is ERC721A, Ownable {    
    using ECDSA for bytes32;
    uint256 public cost;
    uint256 public maxMintAmount = 3;
    uint256 public maxTxMintAmount = 3;
    uint256 public maxSupply = 50000;
    bool public isSaleActive = false;
    string public uriPrefix;
    address payable public wallet;
    address private ehSignerAddress;
    // new artlab experiment has new artlabId 
    uint256 public artlabId = 100;
    mapping(address => uint256) public expMintedCounter; 

    constructor( 
        string memory _uriPrefix,
        address _ehSignerAddress,
        address payable _wallet
    ) ERC721A("Artlab", "ALAB") {        
        setUriPrefix(_uriPrefix);
        setSignerAddresses(_ehSignerAddress);
        setWallet(_wallet);
        setCost(0.05 ether);
    }
   
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setArtlabId(uint256 _artlabId) public onlyOwner {
        artlabId = _artlabId;
    }

    function setSignerAddresses(address _ehSignerAddress) public onlyOwner {
        ehSignerAddress = _ehSignerAddress;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setMaxTXMintAmount(uint256 _newmaxTxMintAmount) public onlyOwner {
        maxTxMintAmount = _newmaxTxMintAmount;
    }
    
    function setWallet(address payable _wallet) public onlyOwner {
        wallet = _wallet;
    }

    function setSaleActive(bool _state) public onlyOwner {
        isSaleActive = _state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function alreadyExpMinted(address addr) public view returns(uint256) {
        uint256 amount = 0;
        if(expMintedCounter[addr] > artlabId) {
            amount = expMintedCounter[addr] - artlabId;
        }
        return amount;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function whitelistMint(uint256 _mintAmount, uint _maxfree, uint256 _id, bytes memory _sig) public payable {
        uint256 expMinted = alreadyExpMinted(msg.sender);     
        require(isSaleActive, "Sale is not active");     
        require(_mintAmount <= maxTxMintAmount, "Exceeds maximum tokens you can purchase in a single transaction!");
        require(_mintAmount > 0 && totalSupply() + _mintAmount <= maxSupply, "Invalid mint amount!");
        require(expMinted + _mintAmount <=  maxMintAmount, "Max mint amount exceeded!");
        require(keccak256(abi.encodePacked(msg.sender, _maxfree, _id))
                .toEthSignedMessageHash()
                .recover(_sig) == ehSignerAddress, "Signature is not valid!");        
        int _priceMultiplier = int(_mintAmount);
        if(expMinted < _maxfree) {  
            _priceMultiplier = int(expMinted) + int(_mintAmount) - int(_maxfree);
        }
        if(_priceMultiplier > 0) {
            uint priceMultiplier = uint(_priceMultiplier);
            require(msg.value >= cost * priceMultiplier, "Ether value sent is not correct!");
        }       
        _safeMint(msg.sender, _mintAmount);
        if(expMinted == 0) {
            expMintedCounter[msg.sender] = artlabId + _mintAmount;
        } else {
            expMintedCounter[msg.sender] += _mintAmount;
        }
        wallet.transfer(address(this).balance);
    }
    
    function ownerMint(address _to, uint256 _mintAmount) public onlyOwner {                                    
        require(_mintAmount > 0 && totalSupply() + _mintAmount <= maxSupply, "Invalid mint amount!");
        _safeMint(_to, _mintAmount);
    }
}