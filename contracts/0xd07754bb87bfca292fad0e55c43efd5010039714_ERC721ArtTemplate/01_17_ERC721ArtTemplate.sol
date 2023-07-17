// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ERC721ArtTemplate is Ownable, ERC721Enumerable, ERC2981 {
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    uint256 public immutable MAX_SUPPLY;
    bool public saleIsActive;
    uint8 public currentPhase;
    struct PhaseInfo{
        uint256 price;
        uint256 supply;
        uint256 minted;
        bool isMintPublic;
        uint256 perMintMax;
        mapping(address=>uint256) whiteMinted; 
        mapping(address=>bool) whiteList; 
    }

    mapping(uint256=>PhaseInfo) public phaseInfo;
    string private _baseURIExtended;
    mapping (uint256 => string) _tokenURIs;

    constructor(string memory _name, string memory _symbol, string memory baseURI, uint256 maxSupply, address royaltyReceiver, uint96 royatyFeeNumerator) ERC721(_name,_symbol){
        _setDefaultRoyalty(royaltyReceiver, royatyFeeNumerator);
        _baseURIExtended = baseURI;
        MAX_SUPPLY = maxSupply;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981,ERC721Enumerable) returns (bool) {
        return ERC2981.supportsInterface(interfaceId) || ERC721Enumerable.supportsInterface(interfaceId);
    }

    function mint(uint count) external payable {
        require(saleIsActive, "Sale is not active at the moment");
        PhaseInfo storage phaseInfoi = phaseInfo[currentPhase];
        require(phaseInfoi.minted.add(count) <= phaseInfoi.supply && totalSupply().add(count) <= MAX_SUPPLY, "supply was exceeded");
        require((phaseInfoi.price * count) == msg.value, "incorrect value");
        address user = msg.sender;
        if(!phaseInfoi.isMintPublic) {
            require(isMinter(currentPhase,user), "caller is not the minter");
            if(phaseInfoi.perMintMax>0 ) {
                require(phaseInfoi.whiteMinted[user].add(count) <= phaseInfoi.perMintMax,"mint limit reached");
            }
        }
        phaseInfoi.minted = phaseInfoi.minted.add(count);
        phaseInfoi.whiteMinted[user] = phaseInfoi.whiteMinted[user].add(count);
        for (uint i = 0; i < count; i++) {
            _safeMint(user, totalSupply().add(1));
        }
        
    }

    function whiteMinted(uint256 phase,address user) view public returns(uint256) {
        return phaseInfo[phase].whiteMinted[user];
    }

    function mintByOwner(address user,uint256 count) external onlyOwner{
        require(totalSupply().add(count) <= MAX_SUPPLY, "max supply was exceeded");
        for (uint i; i < count; i++) {
            _safeMint(user, totalSupply().add(1));
        }
    }
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setCurrentPhase(uint8 _currentPhase) public onlyOwner {
        currentPhase = _currentPhase;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function setPhaseInfo(uint256 phase, uint256 _price, uint256 _supply, bool _isMintPublic,uint256 _mintLimit) external onlyOwner {
        PhaseInfo storage phaseInfoI = phaseInfo[phase];
        phaseInfoI.price = _price;
        phaseInfoI.supply = _supply;
        phaseInfoI.isMintPublic = _isMintPublic;
        phaseInfoI.perMintMax = _mintLimit;
    }

    function setPhasePrice(uint256 phase, uint256 _price) external onlyOwner {
        phaseInfo[phase].price = _price;
    }

    function setPhaseSupply(uint256 phase, uint256 _supply) external onlyOwner {
        phaseInfo[phase].supply = _supply;
    }

    function setIsMintPublic(uint256 phase) external onlyOwner {
        phaseInfo[phase].isMintPublic = !phaseInfo[phase].isMintPublic;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function withdraw() public {
        payable(owner()).transfer(address(this).balance);
    }

    
    function isMinter(uint256 phase, address account) public view returns (bool) {
        return phaseInfo[phase].whiteList[account];
    }

    function mintPrice() public view returns (uint256) {
        PhaseInfo storage phaseInfoi = phaseInfo[currentPhase];
        return phaseInfoi.price;
    }
    
    function addMinter(uint256 phase, address[] calldata _addMinter) public onlyOwner {
        for(uint8 i=0;i<_addMinter.length;i++) {
            if(!phaseInfo[phase].whiteList[_addMinter[i]])
                phaseInfo[phase].whiteList[_addMinter[i]] = true;
        }
    }

    function delMinter(uint256 phase, address[] calldata _delMinter) public onlyOwner {
        for(uint8 i=0;i<_delMinter.length;i++) {
            if(phaseInfo[phase].whiteList[_delMinter[i]])
                delete phaseInfo[phase].whiteList[_delMinter[i]];
        }
    }

}