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

contract MergeCoin is ERC721A, Ownable {    
    using ECDSA for bytes32;
    uint256 public maxSupply = 1000;
    bool public isSaleActive = false;
    string public uriPrefix;
    address private eSignerAddress;
    address private pSignerAddress;    
    mapping(address => bool) public alreadyMinted; 

    constructor( 
        string memory _uriPrefix,
        address _eSignerAddress,
        address _pSignerAddress
    ) ERC721A("MergeCoin", "NMC") {        
        setUriPrefix(_uriPrefix);
        setSignerAddresses(_pSignerAddress, _eSignerAddress);
    }
   
    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setSignerAddresses(address _pSignerAddress, address _eSignerAddress) public onlyOwner {
        pSignerAddress = _pSignerAddress;
        eSignerAddress = _eSignerAddress;
    }

    function setSaleActive(bool _state) public onlyOwner {
        isSaleActive = _state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function freeMint(bool publicsale, uint256 _salt, bytes memory _sig) public {     
        address signerAddress = eSignerAddress;
        if(publicsale) {
            signerAddress = pSignerAddress;
        }
        require(isSaleActive, "Sale is not active");     
        require(!alreadyMinted[msg.sender], "Max mint amount exceeded!");
        require(totalSupply() + 1 <= maxSupply, "Invalid mint amount, sold out!");        
        require(keccak256(abi.encodePacked(msg.sender, _salt))
                .toEthSignedMessageHash()
                .recover(_sig) == signerAddress, "Signature is not valid!");
        _safeMint(msg.sender, 1);
        alreadyMinted[msg.sender] = true;
    }
    
    function ownerMint(address _to, uint256 _mintAmount) public onlyOwner {                                    
        require(_mintAmount > 0 && totalSupply() + _mintAmount <= maxSupply, "Invalid mint amount!");
        _safeMint(_to, _mintAmount);
    }
}