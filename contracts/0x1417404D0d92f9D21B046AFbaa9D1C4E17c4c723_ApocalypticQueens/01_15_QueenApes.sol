// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./ERC721A/contracts/mocks/ERC721ABurnableMock.sol";
import "./ERC721A/contracts/mocks/StartTokenIdHelper.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "hardhat/console.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract ApocalypticQueens is StartTokenIdHelper, ERC721A, ERC721ABurnable {
    event MintQueens(address indexed summoner, uint256 times);

    struct SaleDetails {
        bytes1 phase;
        uint8 maxBatch;
        uint16 totalCount;
    }

    string public baseURI;

    string name_ = "Apocalyptic Queens";
    string symbol_ = "AAQUEENS";
    string baseURI_ = "ipfs://QmbgQnyiFXqyqZtw4ZdFrAg4h1sE6RDgAC8DT5tzKcfpFR";

    uint256 startTokenId_ = 1;
    uint256 public price = 6 * 10**16; // 0.07 eth; use "7 * 10**16" in JS
    uint256 public pricePublic = 8 * 10**16; // 0.07 eth; use "7 * 10**16" in JS

    address payable public owner;
    address payable public treasury;
    IERC721Enumerable public apocalyptic = IERC721Enumerable(address(0));

    SaleDetails public saleDetails = SaleDetails({
        phase: 0,    // 0x00 = not started, 0x01 = ape holders / whitelist sale, 0x02 = public sale
        maxBatch: 10,
        totalCount: 8888
    });

    // mapping(address => uint8) public walletBuys;
    mapping(address => bytes1) public manualWhitelist;

    mapping(uint256 => bool) public minted;


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor()
        StartTokenIdHelper(startTokenId_)
        ERC721A(name_, symbol_)
    {
        owner = payable(msg.sender);
        treasury = payable(msg.sender);
    }
    
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function checkQueens() public view returns(uint256 toMint){
        uint256 apesOwned = apocalyptic.balanceOf(msg.sender);
        uint256 tokenID;

        for (uint256 i = 0; i < apesOwned; i++) {
            tokenID = apocalyptic.tokenOfOwnerByIndex(msg.sender, i);
            if (!minted[tokenID]) {
                toMint++;
            }
        }
    }

    function safeMintBatch(address to, uint256 _amount) public onlyOwner {
        require(_amount + totalSupply() <= saleDetails.totalCount, "All queens minted!");
        _safeMint(to, _amount);
    }
    
    function safeMint(address to, uint256 _amount) public onlyOwner {
        require(_amount + totalSupply() <= saleDetails.totalCount, "All queens minted!");
        _safeMint(to, _amount);
    }

    function getOwnershipAt(uint256 index) public view returns (TokenOwnership memory) {
        return _ownerships[index];
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function _startTokenId() internal view override returns (uint256) {
        return startTokenId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setApocalypticApes(address _newAddress) public onlyOwner {
        apocalyptic = IERC721Enumerable(_newAddress);
    }


    function mintQueens(uint256 _amount) public payable returns(uint256){
        require(saleDetails.phase != 0, "Sale has not started");
        uint256 apesOwned = apocalyptic.balanceOf(msg.sender);
        uint256 tokenID;
        uint256 _price;
        uint256 toMint;

        uint8 maxBatch = saleDetails.maxBatch;

        if (saleDetails.phase == 0x02) {
            toMint = _amount;
            _price = pricePublic;
        } else if(manualWhitelist[msg.sender] == 0x01){
            toMint = 1;
            manualWhitelist[msg.sender] = 0;
            _price = price;
            require(_amount == 1, "Only one mint per whitelisting");
        }
        else {
            for (uint256 i = 0; i < apesOwned; i++) {
                tokenID = apocalyptic.tokenOfOwnerByIndex(msg.sender, i);
                if (!minted[tokenID] && toMint < _amount) {
                    toMint++;
                    minted[tokenID] = true;
                }
            }
            _price = price;
            maxBatch = 255;
            require(toMint > 0, "No queens mintable");
        }

        require(toMint <= maxBatch, "Batch purchase limit exceeded");
        
            
        require(toMint + totalSupply() <= saleDetails.totalCount, "All queens minted!");
        require(msg.value == toMint * _price, "Incorrect ETH amount");

        _safeMint(msg.sender, toMint);

        emit MintQueens(msg.sender, toMint);

        return toMint;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }    
    function changePricePublic(uint256 _pricePublic) public onlyOwner {
        pricePublic = _pricePublic;
    }    

    function setMaxBatch(uint8 _maxBatch) public onlyOwner {
        saleDetails.maxBatch = _maxBatch;
    }

    // 0x00 = not started, 0x01 = ape holders / whitelist sale, 0x02 = public sale
    function setPhase(bytes1 _phase) public onlyOwner {
        saleDetails.phase = _phase;
    }

    //  0x01 == whitelisted
    function whitelist(address _user, bytes1 _status) public onlyOwner {
        manualWhitelist[_user] = _status;
    }
    
    function whitelistBatch(address[] memory _user, bytes1 _status) public onlyOwner {
        for (uint256 i = 0; i < _user.length; i++) {
            manualWhitelist[_user[i]] = _status;
        }
    }

    function withdrawAll() public payable onlyOwner {
        uint256 contract_balance = address(this).balance;
        require(payable(owner).send(contract_balance));
    }

    function withdrawAmount(address _recipient, uint256 _amount) public payable onlyOwner {
        require(payable(_recipient).send(_amount));
    }

    function rescueTokens(
        address recipient,
        address token,
        uint256 amount
    ) public onlyOwner {
        IERC20(token).transfer(recipient, amount);
    }

    function changeOwner(address payable _newowner) external onlyOwner {
        owner = _newowner;
    }

    function changeTreasury(address payable _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function distributeFunds() public payable onlyOwner {
        require(payable(treasury).send(address(this).balance), "Distribution reverted");     
    }
}