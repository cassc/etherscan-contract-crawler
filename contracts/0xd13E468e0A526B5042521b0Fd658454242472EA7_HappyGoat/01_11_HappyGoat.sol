// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract HappyGoat is ERC721A, Ownable {
    using Address for address;

    //#USUAL FARE
    string public baseURI;
    uint256 public treasuryPull = 120;
    uint256 public maxSupply = 4242;

    address hg_wallet = 0x46Ad3F990c37E68E0C0fA22706fd1e0f7Fd2339C;

    
    //#FLAGS
    bool public goatListSaleActive;
    bool public communitySaleActive;
    bool public publicSaleActive;
    

    //#AMOUNTS
    uint256 public goatListMintAmount = 5;
    uint256 public communityMintAmt = 3;
    uint256 public publicMintAmt = 2;

    
    uint256 public goatListPrice = 0.05 ether;
    uint256 public communityPrice = 0.07 ether;
    uint256 public publicPrice = 0.1 ether;

    mapping(address => uint256) private presaleGoats;
    mapping(address => uint256) private mintCount;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //#MODIFIERS FOR LIVE SALES
    modifier goatSaleIsLive() {
        require(goatListSaleActive, "preSale not live");
        _;
    }

    modifier communitySaleIsLive() {
        require(communitySaleActive, "mint not live");
        _;
    }

    modifier publicSaleIsLive() {
        require(publicSaleActive, "mint not live");
        _;
    }

    constructor() ERC721A("HappyGoat", "HG") {
    }

    function isWhiteListed(address _address) public view returns (uint256){
        return presaleGoats[_address];
    }

    // Minting functions
    function publicMint(uint256 _mintAmount) external payable publicSaleIsLive {
        address _to = msg.sender;
        uint256 minted = mintCount[_to];
        require(msg.sender == tx.origin,"message being sent doesn't not match origin");
        require(minted + _mintAmount <= publicMintAmt, "mint over max");
        require(totalSupply() + _mintAmount <= maxSupply, "mint over supply");
        require(msg.value >= publicPrice * _mintAmount, "insufficient funds");
        mintCount[_to] = minted + _mintAmount;
        _safeMint(msg.sender,_mintAmount);
    }

    function communityMint(uint256 _mintAmount) external payable communitySaleIsLive {
        address _to = msg.sender;
        uint256 minted = mintCount[_to];
        require(msg.sender == tx.origin,"message being sent doesn't not match origin");
        require(minted + _mintAmount <= communityMintAmt, "mint over max");
        require(totalSupply() + _mintAmount <= maxSupply, "mint over supply");
        require(msg.value >= communityPrice * _mintAmount, "insufficient funds");
        mintCount[_to] = minted + _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function goatListMint(uint256 _mintAmount) external payable goatSaleIsLive {
        address _to = msg.sender;
        
        uint256 reserved = presaleGoats[_to];
        uint256 minted = mintCount[_to];

        
        require(msg.sender == tx.origin,"message being sent doesn't not match origin");
        require(presaleGoats[_to] >= 0, "not whitelisted");
        require(reserved > 0,                                       "No tokens reserved for this address");
        require(_mintAmount <= reserved,                          "Can't mint more than reserved");
        require(minted + _mintAmount <= goatListMintAmount, "mint over max");
        require(totalSupply() + _mintAmount <= maxSupply, "mint over supply");
        require(msg.value >= goatListPrice * _mintAmount, "insufficient funds");
        
        presaleGoats[msg.sender] = reserved - _mintAmount;

        mintCount[_to] = minted + _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    // Only Owner executable functions
    function mintByOwner(address _to, uint256 _mintAmount) external onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, "mint over supply");
        if (_mintAmount <= treasuryPull) {
            _safeMint(_to, _mintAmount);
            return;
        }
        
        uint256 leftToMint = _mintAmount;
        while (leftToMint > 0) {
            if (leftToMint <= treasuryPull) {
                _safeMint(_to, leftToMint);
                return;
            }
            _safeMint(_to, treasuryPull);
            leftToMint = leftToMint - treasuryPull;
        }
    }

    function addToGoatList(address[] calldata _addresses) external onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            presaleGoats[_addresses[i]] = goatListMintAmount;
        }
    } 


    //#SALES TOGGLE
    function toggleGoatListSaleActive() external onlyOwner {
        if (goatListSaleActive) {
            goatListSaleActive = false;
            return;
        }
        goatListSaleActive = true;
    }

    function togglePublicSaleActive() external onlyOwner {
        if (publicSaleActive) {
            publicSaleActive = false;
            return;
        }
        publicSaleActive = true;
    }

    function toggleCommunitySaleActive() external onlyOwner {
        if (communitySaleActive) {
            communitySaleActive = false;
            return;
        }
        communitySaleActive = true;
    }


    
    //#SETTERS
    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function setPayoutAddress(address _newPayout) external onlyOwner {
        hg_wallet = _newPayout;
    }    

    function setPrice(uint256 price_) external onlyOwner {
        publicPrice = price_;
    }

    //lfgoat
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(hg_wallet).transfer(balance);
    }    


}