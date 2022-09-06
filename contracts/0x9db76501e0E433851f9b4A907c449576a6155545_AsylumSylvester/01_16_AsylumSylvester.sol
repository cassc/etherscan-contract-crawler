// SPDX-License-Identifier: MIT

/*
________       ______                  _____             
__  ___/____  ____  /__   _______________  /_____________
_____ \__  / / /_  /__ | / /  _ \_  ___/  __/  _ \_  ___/
____/ /_  /_/ /_  / __ |/ //  __/(__  )/ /_ /  __/  /    
/____/ _\__, / /_/  _____/ \___//____/ \__/ \___//_/     
       /____/   

*/

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IASM {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address ownerAddress) external view returns (uint256);
}
interface IHP {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address ownerAddress) external view returns (uint256);
}

contract AsylumSylvester is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    //proxy info
    address public purgatory = 0x000000000000000000000000000000000000dEaD;
    address public asm = 0x8513Db429F5fB564f473fD2e5c523fae33331Aa5;
    address public hp = 0xe8e9D211f9AA4B139b6A0Ad59B6694be509f148d;
    IASM private iasm = IASM(asm);
    IHP private ihp = IHP(hp);
    
    //collection settings
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    
    //sale settings
    uint256 public maxSupply = 1800;
    uint256 public maxMintAmountPerTx = 1;
    
    //contract control variables
    bool public paused = true;
    bool public revealed = false;

    constructor(string memory _hiddenMetadataUri) 
        ERC721A("Sylvester", "CS") {
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    function mint(uint256 _mintAmount, uint256 _asmburnTokenId, uint256 _hpburnTokenId) public mintCompliance(_mintAmount) {
        require(!paused, "The contract is paused!");
        address asmownerNftMatch = iasm.ownerOf(_asmburnTokenId);
        address hpownerNftMatch = ihp.ownerOf(_hpburnTokenId);
        uint256 asmownerAmount = iasm.balanceOf(_msgSender());
        uint256 hpownerAmount = ihp.balanceOf(_msgSender());

        require(asmownerAmount >= 1 && hpownerAmount >= 1, "must at least own 1 asylum resident and 1 hall pass");
        require(asmownerNftMatch == _msgSender(), "Our patient records indicate IDENTITY FRAUD ! ... (not your nft)");
        require(hpownerNftMatch == _msgSender(), "Our patient records indicate IDENTITY FRAUD ! ... (not your nft)");

        iasm.safeTransferFrom(_msgSender(),purgatory,_asmburnTokenId);
        ihp.safeTransferFrom(_msgSender(),purgatory,_hpburnTokenId);
        _safeMint(_msgSender(), _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function airdrop(address[] calldata addresses, uint256[] calldata count) external onlyOwner {
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

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}