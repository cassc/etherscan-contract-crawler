pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Hooliganz is ERC721AQueryable, Ownable, Pausable, ReentrancyGuard {
    uint256 public cost;   
    uint256 public maxSupply;
    uint256 public maxMintAmount;
    address private withdrawWallet;
    string baseURI;
    string public baseExtension;    
    bool public presale;
    uint256 public maxFreeMintAmount;

    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isFreeMinter;
    mapping(address => uint256) public freeMintAllocations;

    constructor() ERC721A("Hooliganz", "HOOLZ") {
        presale = false;
        cost = 0.013 ether;
        maxSupply = 1313;
        maxMintAmount = 13;
        maxFreeMintAmount = 1;
        baseExtension = "";
        baseURI = "";
        withdrawWallet = address(msg.sender);
        _pause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPresale(bool _presale) public onlyOwner {
        presale = _presale;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxMintAmount(uint256 _newMax) public onlyOwner {
        maxMintAmount = _newMax;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWithdrawWallet(address wallet) public onlyOwner {
        withdrawWallet = wallet;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool os, ) = payable(withdrawWallet).call{value: address(this).balance}("");
        require(os);
    }
    
    function addWhitelist(bool isFree, address[] calldata _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            if (isFree) {
                isFreeMinter[_addresses[i]] = true;
                isWhitelisted[_addresses[i]] = true;
            } else {
                isWhitelisted[_addresses[i]] = true;
            }
            
        }
    }
   
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function adminMint(address to, uint256 _mintAmount) public onlyOwner {
        _mint(to, _mintAmount);
    }

    function mint(uint256 _mintAmount) external payable {
        if (presale) {
            require(isWhitelisted[msg.sender] == true);
        }
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(totalSupply() + _mintAmount <= maxSupply);
        require(balanceOf(msg.sender) + _mintAmount <= maxMintAmount);

        if (msg.sender != owner()) {
            if (isFreeMinter[msg.sender]) {
                require(msg.value >= cost * (_mintAmount - (maxFreeMintAmount - freeMintAllocations[msg.sender])));
                freeMintAllocations[msg.sender] += (maxFreeMintAmount - freeMintAllocations[msg.sender]);
            } else {
                require(msg.value >= cost * _mintAmount);
            }
        }

        _mint(msg.sender, _mintAmount);
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal whenNotPaused virtual override(ERC721A) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}