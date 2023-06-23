// SPDX-License-Identifier: MIT

/*

▄▄▄█████▓ ██░ ██ ▓█████     ▄▄▄        ██████▓██   ██▓ ██▓     █    ██  ███▄ ▄███▓    ██░ ██  ▄▄▄       ██▓     ██▓      ██████ 
▓  ██▒ ▓▒▓██░ ██▒▓█   ▀    ▒████▄    ▒██    ▒ ▒██  ██▒▓██▒     ██  ▓██▒▓██▒▀█▀ ██▒   ▓██░ ██▒▒████▄    ▓██▒    ▓██▒    ▒██    ▒ 
▒ ▓██░ ▒░▒██▀▀██░▒███      ▒██  ▀█▄  ░ ▓██▄    ▒██ ██░▒██░    ▓██  ▒██░▓██    ▓██░   ▒██▀▀██░▒██  ▀█▄  ▒██░    ▒██░    ░ ▓██▄   
░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄    ░██▄▄▄▄██   ▒   ██▒ ░ ▐██▓░▒██░    ▓▓█  ░██░▒██    ▒██    ░▓█ ░██ ░██▄▄▄▄██ ▒██░    ▒██░      ▒   ██▒
  ▒██▒ ░ ░▓█▒░██▓░▒████▒    ▓█   ▓██▒▒██████▒▒ ░ ██▒▓░░██████▒▒▒█████▓ ▒██▒   ░██▒   ░▓█▒░██▓ ▓█   ▓██▒░██████▒░██████▒▒██████▒▒
  ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░    ▒▒   ▓▒█░▒ ▒▓▒ ▒ ░  ██▒▒▒ ░ ▒░▓  ░░▒▓▒ ▒ ▒ ░ ▒░   ░  ░    ▒ ░░▒░▒ ▒▒   ▓▒█░░ ▒░▓  ░░ ▒░▓  ░▒ ▒▓▒ ▒ ░
    ░     ▒ ░▒░ ░ ░ ░  ░     ▒   ▒▒ ░░ ░▒  ░ ░▓██ ░▒░ ░ ░ ▒  ░░░▒░ ░ ░ ░  ░      ░    ▒ ░▒░ ░  ▒   ▒▒ ░░ ░ ▒  ░░ ░ ▒  ░░ ░▒  ░ ░
  ░       ░  ░░ ░   ░        ░   ▒   ░  ░  ░  ▒ ▒ ░░    ░ ░    ░░░ ░ ░ ░      ░       ░  ░░ ░  ░   ▒     ░ ░     ░ ░   ░  ░  ░  
          ░  ░  ░   ░  ░         ░  ░      ░  ░ ░         ░  ░   ░            ░       ░  ░  ░      ░  ░    ░  ░    ░  ░      ░ 

 */

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Asylum is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    //whitelist/public settings
    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    mapping(address => bool) public publicClaimed;

    //collection settings
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    //sale settings
    uint256 public cost = 0 ether;
    uint256 public maxSupply = 6666;
    uint256 public maxMintAmountPerTx;
    uint256 public murderCount;

    //contract control variables
    bool public whitelistMintEnabled = false;
    bool public paused = true;
    bool public revealed = false;
    bool public murderWindowPaused = true;

 
    constructor(uint256 _maxMintAmountPerTx, string memory _hiddenMetadataUri)
        ERC721A("The Asylum Halls", "ASM") {
        maxMintAmountPerTx = _maxMintAmountPerTx;
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,"Invalid mint amount!");
        require(totalSupply() + _mintAmount <= maxSupply,"Max supply exceeded!");
        
        //proof check
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Invalid proof!");

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,"Invalid mint amount!");
        require(totalSupply() + _mintAmount <= maxSupply,"Max supply exceeded!");
        require(!paused, "The contract is paused!");
        require(!publicClaimed[_msgSender()], "Address already claimed!");

        publicClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function redrum(uint256 _tokenId) public {
        require(!murderWindowPaused, "Murder window isn't open redrum!");
        murderCount++;
        _burn(_tokenId);
    }

    function alphaMint(address[] calldata addresses, uint256[] calldata count) external onlyOwner {
        require(addresses.length == count.length, "mismatching lengths!");

        for (uint256 i; i < addresses.length; i++) {
            _safeMint(addresses[i], count[i]);
        }

        require(totalSupply() <= maxSupply, "Exceed MAX_SUPPLY");
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI,_tokenId.toString(),uriSuffix))
                : "";
    }

    function donate() external payable {
        // the asylum grows stronger !
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMurderWindow(bool _state) public onlyOwner {
        murderWindowPaused = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}