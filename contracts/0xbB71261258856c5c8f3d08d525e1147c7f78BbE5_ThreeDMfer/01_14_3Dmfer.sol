// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//3D mfers by RaulPM & destruction.eth

contract ThreeDMfer is Ownable, ERC721Enumerable {

    //METADATA
    bool public tokenURIFrozen = false;
    string public baseTokenURI;
    string public contractURI;

    //MINT
    uint256 public idTracker = 10021;

    //SALE
    uint256 public startDateHolder;
    uint256 public startDatePublic;
    uint256 public holderPrice = 0.0069 ether;
    uint256 public publicPrice = 0.0096 ether;
    
    //ERRORS
    error URIFrozen();
    error AlreadyMinted();
    error MferNotOwned();
    error SoldOut();
    error HolderSaleNotStarted();
    error PublicSaleNotStarted();
    error ZeroMint();
    error BadPrice();
    error TransferFail();
    error NoBalance();

    //CONTRACTS
    ERC721Enumerable public mfer_C;

    //EVENT
    event MintEvent(address indexed minter, uint256 id, uint256 time, uint256 supply); 

    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        string memory c_uri,
        uint256 _startDateHolder,
        uint256 _startDatePublic,
        address mfer_A
    ) ERC721(name, symbol) {
        baseTokenURI = uri;
        contractURI = c_uri;
        mfer_C = ERC721Enumerable(mfer_A);
        startDateHolder = _startDateHolder;
        startDatePublic = _startDatePublic;
    }
    
    //MINT
    function mint(uint256 amount) external payable {
        if (block.timestamp < startDatePublic) revert PublicSaleNotStarted();

        uint256 totalPrice = publicPrice * amount;
        if (msg.value != totalPrice) revert BadPrice();
        if (amount == 0) revert ZeroMint();

        for (uint256 i = 0; i < amount; i++) {
            _mintNextAvailable(_msgSender());
        }
    }

    function adminMint(uint256 amount) external onlyOwner {
        if (block.timestamp < startDatePublic) revert PublicSaleNotStarted();
        
        if (amount == 0) revert ZeroMint();

        for (uint256 i = 0; i < amount; i++) {
            _mintNextAvailable(_msgSender());
        }
    }

     function _mintNextAvailable(address to) private returns (uint256) {
        uint256 next = nextId();
        idTracker = next;
        _safeMint(to, next);
        emit MintEvent(to, next, block.timestamp, totalSupply());
        return next;
    }
    
    function holderMint(uint256[] calldata mferIds) external payable {
        if (block.timestamp < startDateHolder) revert HolderSaleNotStarted();

        if (mferIds.length == 0) revert ZeroMint();

        uint256 totalPrice = holderPrice * mferIds.length;
        if (msg.value != totalPrice) revert BadPrice();

        for (uint256 i = 0; i < mferIds.length; i++) {
            uint256 mferId = mferIds[i];

            bool mferOwned = (_msgSender() == mfer_C.ownerOf(mferId));
            if (!mferOwned) revert MferNotOwned();

            if (_exists(mferId)) revert AlreadyMinted();

            _safeMint(_msgSender(), mferId);
            emit MintEvent(_msgSender(), mferId, block.timestamp, totalSupply());
        }
    }

    //ADMIN
    function setPublicPrice(uint256 _price) external onlyOwner{
        publicPrice = _price;
    }

    function setHolderPrice(uint256 _price) external onlyOwner{
        holderPrice = _price;
    }
    
    function setStartDatePublic(uint256 stamp) public onlyOwner{
        startDatePublic = stamp;
    }

    function setStartDateHolder(uint256 stamp) public onlyOwner{
        startDateHolder = stamp;
    }

    function withdraw(uint256 amount, address receiver) public onlyOwner {
        (bool ok, ) = payable(receiver).call{value: amount}("");
        if(!ok) revert TransferFail();
    } 

    function setContractURI(string memory uri) public onlyOwner {
        contractURI = uri;
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        if(tokenURIFrozen) revert URIFrozen();
        baseTokenURI = uri;
    }

    function freezeBaseURI() public onlyOwner {
        tokenURIFrozen = true;
    }

    //VIEW
    function validMfers(address add) public view returns(uint256[] memory){
        uint256 ownerTokenCount = mfer_C.balanceOf(add);

        uint256[] memory tempArray = new uint256[](ownerTokenCount);
        uint256 validCount = 0;

        for (uint256 i = 0; i < ownerTokenCount; i++) {
            uint256 id = mfer_C.tokenOfOwnerByIndex(add, i);
            if (!_exists(id)) {
                tempArray[validCount] = id;
                validCount++;
            }
        }

        uint256[] memory validArray = new uint256[](validCount);
        for (uint256 i = 0; i < validCount; i++) {
            validArray[i] = tempArray[i];
        }

        return validArray;
    }

    function nextId() public view returns(uint256){
        if (idTracker < 1) revert SoldOut();

        uint256 next = idTracker - 1; // Changed to decrement the ID
        
        while(_exists(next)){
            next--;
        }

        return next;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
}