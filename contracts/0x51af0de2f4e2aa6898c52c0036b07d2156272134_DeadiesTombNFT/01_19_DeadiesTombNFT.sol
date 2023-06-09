// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "ERC721AOwnersExplicit.sol";
import "ERC721APausable.sol";
import "ERC721AQueryable.sol";
import "ReentrancyGuard.sol";

contract DeadiesTombNFT is
    Ownable,
    ERC721AOwnersExplicit,
    ERC721APausable,
    ERC721AQueryable,
    ReentrancyGuard
{
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    string public defaultURI;
    uint256 public revealedProgress = 0;
    uint256 public generalCost = 0.005 ether;
    uint256 public maxFreeSupply = 3000;
    uint256 public maxSupply = 10000;
    uint256 public mintPerAddressLimit = 3;
    uint256 public reserved = 200;

    address public owner1 = 0x5E2448CE7bfAebE840e6E6dd2600c0aa9D88f4F7;
    address public owner2 = 0xAE175b64cE7C4Df5cf3e07bb28Bcbaea847F3683;
    address public owner3 = 0xEE1899fa49A8B7924C1129c3bF5F421Af4097691;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setDefaultURI(_initNotRevealedUri);

        _safeMint(owner1, 1);
        _safeMint(owner2, 1);
        _safeMint(owner3, 1);
    }

    function _beforeTokenTransfers( address from, address to, uint256 tokenId, uint256 quantity) internal override(ERC721A, ERC721APausable) {
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function GeneralMint(uint256 _amount) public payable whenNotPaused nonReentrant {
        require(_amount > 0, "need to mint at least 1 NFT");

        uint256 supply = totalSupply();
        require(supply + _amount <= maxSupply - reserved, "max supply exceeded");

        uint256 mintedCount = numberMinted(msg.sender);
        //check if there's a mint per address limit
        require(mintedCount + _amount <= mintPerAddressLimit, "max mint per address exceeded");
        if(mintedCount == 0 && supply <= maxFreeSupply)
        {
            require(msg.value >= generalCost * (_amount - 1), "insufficient funds");
        }
        else
        {
            require(msg.value >= generalCost * _amount, "insufficient funds");
        }

        _safeMint(msg.sender, _amount);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function getOwnershipData(uint256 tokenId) public view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        if (bytes(currentBaseURI).length > 0 && tokenId <= revealedProgress) {
            return string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)); 
        } else {
            return string(abi.encodePacked(defaultURI, tokenId.toString(), baseExtension)); 
        }
    }

    //ONLY OWNER
    function burn(uint256 tokenId) public virtual onlyOwner{
        _burn(tokenId, true);
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    //mint _amount amount of LIFE for to an address
    function giveAway(address _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "need to mint at least 1 NFT");
        require(_amount <= reserved, "Exceeds reserved supply");

        uint256 supply = totalSupply();
        _safeMint(_to, _amount);
        reserved -= _amount;
    }

    function givewayForAll(address[] memory _to) external onlyOwner {
        require(_to.length > 0, "need to mint at least 1 NFT");
        require(_to.length <= reserved, "Exceeds reserved supply");

        uint256 supply = totalSupply();
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], 1);
        }
        reserved -= _to.length;
    }

    function setRevealedProgress(uint256 _set) public onlyOwner {
        revealedProgress = _set;
    }

    function setMaxSupply(uint256 _set) public onlyOwner {
        maxSupply = _set;
    }

    function setMaxFreeSupply(uint256 _set) public onlyOwner {
        maxFreeSupply = _set;
    }

    function setCost(uint256 _set) public onlyOwner {
        generalCost = _set;
    }

    function setBaseURI(string memory _set) public onlyOwner {
        baseURI = _set;
    }

    function setBaseExtension(string memory _set) public onlyOwner {
        baseExtension = _set;
    }

    function setDefaultURI(string memory _set) public onlyOwner {
        defaultURI = _set;
    }

    function setMintPerAddressLimit(uint256 _limit) public onlyOwner {
        mintPerAddressLimit = _limit;
    }

    function withdrawAll() external onlyOwner {
        uint256 amount = address(this).balance / 3;
        require(amount > 0);
        _widthdraw(owner1, amount);
        _widthdraw(owner2, amount);
        _widthdraw(owner3, amount);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function setDeadiesTombOwner(address _set1, address _set2, address _set3) public onlyOwner {
        owner1 = _set1;
        owner2 = _set2;
        owner3 = _set3;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner {
        _setOwnersExplicit(quantity);
    }
}