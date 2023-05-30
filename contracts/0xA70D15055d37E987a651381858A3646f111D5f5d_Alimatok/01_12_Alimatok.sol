// SPDX-License-Identifier: MIT
/*
------------------------------------------+++------------------------------------------
                                   @@@@@@@@@@@@                      
                              @@,[email protected]@                 
                          ,@[email protected]@              
                        @@[email protected]@            
                       @[email protected]           
                      @[email protected]           
                     (@[email protected]          
                     @[email protected]          
                    (@[email protected]           
                    (@[email protected]            
                    (@[email protected]              
                    (@[email protected]@@................./ @               
                    (@[email protected]    (((@@@@@@@@(   @                    
                    (@[email protected]@                                       
                    @[email protected]                                       
                   (@[email protected]                                      
                  [email protected]@@                                    
                  @[email protected]                                   
                 @[email protected]                                 
               (@[email protected]     
------------------------------------------+++------------------------------------------
Web: alimatok.com
Twitter: @AlimatokNFT
*/
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Alimatok is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    string public uriPrefix = "";
    string public uriExt = ".json";
    string public hiddenMetadataURI;

    uint256 public constant cost = 0.016 ether;
    uint256 public matokMaxSupply = 4444; //<-- Alimatok Max Supply Including Free
    uint256 public maxMintPerTx = 10;
    uint256 public matokFreeMaxSupply = 800;
    uint256 public matokFreeCurrentMinted = 0;
    uint256 public freeMaxMintPerTx = 1;
    uint256 public constant reservedForTeam = 88;

    mapping(address => uint256) public freeMinted;
    mapping(address => uint256) public minted;

    bool public mintLive = false;
    bool public revealed = false;

    constructor (
        string memory _uriPrefix,
        string memory _hiddenMetadataURI
    ) ERC721A("Alimatok", "MATOK") {
        setUriPrefix(_uriPrefix);
        setHiddenMetaDataURI(_hiddenMetadataURI);
    }

    function setMintLive(bool _state) public onlyOwner {
        mintLive = _state;
    }

    function freeMint(uint256 _mintAmount) public payable {
        require(mintLive, "Mint is not activated.");
        require(_mintAmount > 0 && _mintAmount <= freeMaxMintPerTx, "Invalid Mint Amount.");
        require(freeMinted[msg.sender] + _mintAmount <= freeMaxMintPerTx, "Transaction limit reached.");
        require(matokFreeCurrentMinted + _mintAmount <= matokFreeMaxSupply, "Lack of free mint supply.");

        freeMinted[msg.sender] += _mintAmount;
        matokFreeCurrentMinted += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable {
        require(mintLive, "Mint is not activated.");
        require(_mintAmount > 0 && _mintAmount <= maxMintPerTx, "Invalid Mint Amount.");
        require(minted[msg.sender] + _mintAmount <= maxMintPerTx, "Mint amount exceeded!");
        require(msg.value == cost * _mintAmount, "Wrong amount of ETH.");
        require(totalSupply() + _mintAmount <= matokMaxSupply, "No available supply to mint.");

        minted[msg.sender] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokensOwned = new uint256[](ownerTokenCount);
        uint256 thisTokenId = _startTokenId();
        uint256 tokensOwnedIndex = 0;
        address latestOwnerAddress;

        while (tokensOwnedIndex < ownerTokenCount && thisTokenId <= matokMaxSupply) {
            TokenOwnership memory ownership = _ownerships[thisTokenId];

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                tokensOwned[tokensOwnedIndex] = thisTokenId;

                tokensOwnedIndex++;
            }
            thisTokenId++;
        }
        return tokensOwned;
    }

    function setHiddenMetaDataURI(string memory _hiddenMetadataURI) public onlyOwner {
        hiddenMetadataURI = _hiddenMetadataURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setUriPrefix(string memory _newUriPrefix) public onlyOwner {
        uriPrefix = _newUriPrefix;
    }

    function setUriExt(string memory _newUriExt) public onlyOwner {
        uriExt = _newUriExt;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token unavailable.");

        if (revealed == false) {
            return string(abi.encodePacked(hiddenMetadataURI, Strings.toString(tokenId), uriExt));
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), uriExt))
            : '';
    }

    function collectReservedForTeam() external onlyOwner {
        require(totalSupply() == 0, "Mint has started and can no longer claim reserved tokens.");
            _safeMint(_msgSender(), reservedForTeam);
    }

    function setRevealedState (bool _status) public onlyOwner {
        revealed = _status;
    }

    function setFreeMaxMintPerTx (uint256 _freeMaxMintPerTx) public onlyOwner {
        freeMaxMintPerTx = _freeMaxMintPerTx;
    }

    function setMatokFreeMaxSupply (uint256 _matokFreeMaxSupply) public onlyOwner {
        matokFreeMaxSupply = _matokFreeMaxSupply;
    }

    function setMaxMintPerTx (uint256 _maxMintPerTx) public onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }

    function setMatokMaxSupply (uint256 _matokMaxSupply) public onlyOwner {
        matokMaxSupply = _matokMaxSupply;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}('');
        require(success, "Withdraw not executed.");
    }
}