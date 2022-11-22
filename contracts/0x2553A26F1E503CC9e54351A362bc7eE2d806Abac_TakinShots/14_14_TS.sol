// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// @author Not Ur Hero#4094 

contract TakinShots is ERC721, Pausable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    uint256 public max_supply = 444;
    string public uriPrefix = "ipfs://bafybeicjhn77zfyzdvkum4pbjroveoh5f24zhzp3n6ig3eqspsbi4hc2z4/";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    bool public revealed = false;

    bool public ogMintOpen = false;
    bool public wlMintOpen = false;
    bool public alMintOpen = false;

    mapping(address => bool) public OG_LIST;
    mapping(address => bool) public WL_LIST;
    mapping(address => bool) public AL_LIST;

    constructor() ERC721("Takin Shots", "TKS") {
        setHiddenMetadataUri("ipfs://bafybeicjhn77zfyzdvkum4pbjroveoh5f24zhzp3n6ig3eqspsbi4hc2z4/hidden.json");
    }
    
    function mintCycle() public {
        require(ogMintOpen || wlMintOpen || alMintOpen, "Not time to mint yet!");
        if(ogMintOpen) {
            mintOg();
        }
        else if (wlMintOpen) {
            mintWl();
        }
        else if (alMintOpen) {
            mintAl();
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function openMintWindow(bool _ogMintOpen, bool _wlMintOpen, bool _alMintOpen) external onlyOwner {
        ogMintOpen = _ogMintOpen;
        wlMintOpen = _wlMintOpen;
        alMintOpen = _alMintOpen;
    }

    function mintOg() internal {
        require(ogMintOpen, "OG is not available.");
        require(OG_LIST[msg.sender], "Sorry, you are not OG.");
        require(balanceOf(msg.sender) < 1, "Limit reached.");
        mint();
    }

    function mintWl() internal {
        require(wlMintOpen, "WL is not available.");
        require(WL_LIST[msg.sender], "Sorry, you are not WL.");
        require(balanceOf(msg.sender) < 1, "Limit reached.");
        mint();
    }

    function mintAl() internal {
        require(alMintOpen, "AL is not available.");
        require(AL_LIST[msg.sender], "Sorry, you are not AL.");
        require(balanceOf(msg.sender) < 1, "Limit reached.");
        mint();
    }

    function adminMint(uint256 qty) public onlyOwner {
        require(balanceOf(msg.sender) < 25, "Limit reached.");
        for(uint i = 0; i < qty; i++) {
            mint();
        }
    }

    function mint() internal {
        supply.increment();
        _safeMint(msg.sender, supply.current());
    }

    function addOgList(address[] calldata _OG_LIST) external onlyOwner {
        for (uint256 i = 0; i < _OG_LIST.length; i++) {
            OG_LIST[_OG_LIST[i]] = true;
        }
    }

    function addWhiteList(address[] calldata _WL_LIST) external onlyOwner {
        for(uint256 i = 0; i < _WL_LIST.length; i++) {
            WL_LIST[_WL_LIST[i]] = true;
        }
    }

    function addAllowList(address[] calldata _AL_LIST) external onlyOwner {
        for(uint256 i = 0; i < _AL_LIST.length; i++) {
            AL_LIST[_AL_LIST[i]] = true;
        }
    }

    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
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

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
    
    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= max_supply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}