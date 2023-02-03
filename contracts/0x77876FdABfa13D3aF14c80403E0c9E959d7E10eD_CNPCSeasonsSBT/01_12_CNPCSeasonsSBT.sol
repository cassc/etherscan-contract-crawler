// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
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

contract CNPCSeasonsSBT is ERC721AQueryable, Ownable, AccessControl {
    using Strings for uint256;
    bytes32 public ADMIN = "ADMIN";
    string baseURI;
    string public baseExtension = ".json";
    uint256 public maxMintAmount = 5;
    uint256 public maxSupply = 99999999;
    bool public paused = false;
    uint256 public cost = 0.0045 ether;
    uint256 public discountCost = 0.00225 ether;
    uint256 public discountBorderAmount = 2;
    uint256 public canBuyBorderAmount = 1;
    bool public isCnpcSale = true;
    address withdrawAddress = 0xd3005389DfEfe5CabBa55149cFB9e8017809B0D6;
    ITokenURI public tokenuri;
    ICNPC public cnpc;
    

    constructor() ERC721A("CNPC Seasons SBT", "CNPCS") {
        // baseURI;
        _setRoleAdmin(ADMIN, DEFAULT_ADMIN_ROLE);
        grantRole(ADMIN, msg.sender);
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
        require(supply + _mintAmount <= maxSupply);        
        if(address(cnpc)!=address(0)){
            require(cnpc.balanceOf(_msgSender()) >= canBuyBorderAmount, "not enough CNPC amount");
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
    function setMaxMintAmount(uint256 _newmaxMintAmount) external onlyRole(ADMIN) {
        maxMintAmount = _newmaxMintAmount;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory _newBaseURI) external onlyRole(ADMIN) {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) external onlyRole(ADMIN) {
        paused = _state;
    }

    function setCost(uint256 _newCost) external onlyRole(ADMIN) {
        cost = _newCost;
    }

    function setDiscountCost(uint256 _newDiscountCost) external onlyRole(ADMIN) {
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

    //Role
    function grantRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _revokeRole(role, account);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721A)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    //Full on chain
    function setTokenURI(ITokenURI _tokenuri) external onlyOwner {
        tokenuri = _tokenuri;
    }

    //start token id
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //withdraw
    function withdraw() external onlyOwner {
        _withdraw();
    }

    function setWithdrawAddress(address _newAddress) external onlyOwner {
        withdrawAddress = _newAddress;
    }

    function _withdraw() internal virtual {
        require(
            withdrawAddress != address(0),
            "withdraw address is 0 address."
        );
        (bool os, ) = withdrawAddress.call{value: address(this).balance}("");
        require(os);
    }
}