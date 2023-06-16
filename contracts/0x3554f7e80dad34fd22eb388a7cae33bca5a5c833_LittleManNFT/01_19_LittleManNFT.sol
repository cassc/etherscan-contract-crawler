// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "ERC721AOwnersExplicit.sol";
import "ERC721APausable.sol";
import "ERC721AQueryable.sol";
import "ReentrancyGuard.sol";

contract LittleManNFT is
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
    uint256 public generalCost = 0.0077 ether;
    uint256 public maxSupply = 7777;
    uint256 public mintPerAddressLimit = 10;
    bool public startMint = false;

    address public ownerAddress = 0x005605A37c4F1d594504F8d00Af68EDA6bc3019b;
    address public owner2Address = 0xd673f2888623f912a7Bbe8a3df83572e63BDfD65;
    address public vaultAddress = 0x21678c25EFF5E95daCfaF74614Fa22e6b25897F1;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setDefaultURI(_initNotRevealedUri);
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
        require(startMint == true, "not started yet");
        require(_amount > 0, "need to mint at least 1 NFT");

        uint256 supply = totalSupply();
        require(supply + _amount <= maxSupply, "max supply exceeded");

        uint256 mintedCount = numberMinted(msg.sender);
        //check if there's a mint per address limit
        require(mintedCount + _amount <= mintPerAddressLimit, "max mint per address exceeded");
        if(mintedCount == 0)
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

    function setStartMint() external onlyOwner {
        require(startMint == false, "already started");
        startMint = true;
        _safeMint(ownerAddress, 10);
        _safeMint(owner2Address, 10);
    }
    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function setRevealedProgress(uint256 _set) public onlyOwner {
        revealedProgress = _set;
    }

    function setMaxSupply(uint256 _set) public onlyOwner {
        maxSupply = _set;
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
        uint256 amount = address(this).balance / 4;
        require(amount > 0);
        _widthdraw(ownerAddress, amount);
        _widthdraw(owner2Address, amount);
        _widthdraw(vaultAddress, amount * 2); //50% initial sales to vault
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function setLittleManNFTOwner(address _set1, address _set2, address _set3) public onlyOwner {
        ownerAddress = _set1;
        owner2Address = _set2;
        vaultAddress = _set3;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner {
        _setOwnersExplicit(quantity);
    }
}