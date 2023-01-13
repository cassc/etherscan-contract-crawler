// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

interface ITokenURI {
    function tokenURI_future(uint256 _tokenId)
        external
        view
        returns (string memory);
}

interface ICNPC {
    function balanceOf(address _owner)
    external
        view
        returns (uint);
}

contract CNPCEma is ERC721AQueryable, Ownable {
    using Strings for uint256;
    string baseURI;
    string public baseExtension = ".json";
    uint256 public maxMintAmount = 1;
    uint256 public maxSupply = 99999999;
    bool public useMaxSupply = true;
    bool public paused = false;
    uint256 public cost = 0.005 ether;
    uint256 public discountCost = 0.0025 ether;
    uint256 public discountBorderAmount = 2;
    uint256 public canBuyBorderAmount = 1;
    bool public isCnpcSale = true;
    ITokenURI public tokenuri;
    ICNPC public cnpc;
    

    constructor() ERC721A("CNPC Ema", "CNPCE") {
        // baseURI;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // external
    function mint(address recipient, uint256 _mintAmount) external payable {
        uint256 supply = totalSupply();
        require(!paused, "mint is paused!");
        require(tx.origin == msg.sender, "the caller is another controler");
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        if(useMaxSupply) require(supply + _mintAmount <= maxSupply);        
        if(address(cnpc)!=address(0)){
            require(cnpc.balanceOf(_msgSender()) >= canBuyBorderAmount, "not enough NFT amount");
            if(isCnpcSale==true && cnpc.balanceOf(_msgSender()) >= discountBorderAmount){
                    require(msg.value >= discountCost * _mintAmount, "not enough amount");
                    _safeMint(recipient, _mintAmount);
                    return;
            }
        } 
        require(msg.value >= cost * _mintAmount, "not enough amount");
        _safeMint(recipient, _mintAmount);
        
    }

    function burn(uint256 burnTokenId) external {
        require(
            _msgSenderERC721A() == ownerOf(burnTokenId),
            "Only the owner can burn"
        );
        _burn(burnTokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (address(tokenuri) == address(0)) {
        require(
            _exists(tokenId),
            "ERC721AMetadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
        } else {
            return tokenuri.tokenURI_future(tokenId);
        }
    }

    //only owner
    function setMaxMintAmount(uint256 _newmaxMintAmount) external onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setUseMaxSupply(bool _bool) external onlyOwner{
        useMaxSupply = _bool;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }

    function setDiscountCost(uint256 _newDiscountCost) external onlyOwner {
        discountCost = _newDiscountCost;
    }

    function setDiscountBorderAmount(uint256 _newBorderAmount) external onlyOwner {
        discountBorderAmount = _newBorderAmount;
    }

    function setCanBuyBorderAmount(uint256 _newBorderAmount) external onlyOwner {
        canBuyBorderAmount = _newBorderAmount;
    }

    function setIsCnpcSale(bool _bool) external onlyOwner {
        isCnpcSale = _bool;
    }

    function setCnpcUri(ICNPC _cnpc) external onlyOwner {
        cnpc = _cnpc;
    }

    //SBT
    function approve(address, uint256) public payable virtual override {
        require(false, "This token is SBT, so this can not approval.");
    }

    function setApprovalForAll(address, bool) public virtual override {
        require(false, "This token is SBT, so this can not approval.");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public payable virtual override {
        require(false, "This token is SBT, so this can not transfer.");
    }

    //Full on chain
    function setTokenURI(ITokenURI _tokenuri) external onlyOwner {
        tokenuri = _tokenuri;
    }

    //start token id
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}