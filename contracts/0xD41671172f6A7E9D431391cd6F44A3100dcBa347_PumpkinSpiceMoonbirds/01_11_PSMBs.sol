// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721r.sol";

contract PumpkinSpiceMoonbirds is ERC721r, Ownable {
    using Address for address;

    //#USUAL FARE
    string public baseURI;
    uint256 public treasuryPull = 25;
    uint256 public birdSupply = 10000;

    address multisig_wallet = 0x96909253ddb848ff3Ab6a4c39D67EBbC0115BF07;

    
    //#FLAGS
    bool public allowlistActive;
    bool public publicSaleActive;
    

    //#AMOUNTS
    uint256 public allowlistMintAmount = 2;
    uint256 public publicMintAmt = 1;

    //let's be real, it's not a latte.
    uint256 public birdPrice = 0.0069 ether;

    mapping(address => uint256) private presaleBirds;
    mapping(address => uint256) private mintCount;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //#MODIFIERS FOR LIVE SALES
    modifier allowListSaleIsActive() {
        require(allowlistActive, "allow list sale not live");
        _;
    }
    modifier publicSaleIsLive() {
        require(publicSaleActive, "mint not live");
        _;
    }

    constructor() ERC721r("PumpkinSpiceMoonbirds", "PSMBs", 10_000) {
    }

    function isAllowlisted(address _address) public view returns (uint256){
        return presaleBirds[_address];
    }

    // Minting functions
    function publicMint(uint256 _mintAmount) external payable publicSaleIsLive {
        address _to = msg.sender;
        uint256 minted = mintCount[_to];
        require(msg.sender == tx.origin,"message being sent doesn't not match origin");
        require(minted + _mintAmount <= publicMintAmt, "mint over max");
        require(totalSupply() + _mintAmount <= birdSupply, "mint over supply");
        require(msg.value >= birdPrice * _mintAmount, "insufficient funds");
        mintCount[_to] = minted + _mintAmount;
        _mintRandom(msg.sender,_mintAmount);
    }

    function allowListMint(uint256 _mintAmount) external payable allowListSaleIsActive {
        address _to = msg.sender;
        
        uint256 reserved = presaleBirds[_to];
        uint256 minted = mintCount[_to];

        
        require(msg.sender == tx.origin,"message being sent doesn't not match origin");
        require(presaleBirds[_to] >= 0, "not whitelisted");
        require(reserved > 0,                                       "No tokens reserved for this address");
        require(_mintAmount <= reserved,                          "Can't mint more than reserved");
        require(minted + _mintAmount <= allowlistMintAmount, "mint over max");
        require(totalSupply() + _mintAmount <= birdSupply, "mint over supply");
        require(msg.value >= birdPrice * _mintAmount, "insufficient funds");
        
        presaleBirds[msg.sender] = reserved - _mintAmount;

        mintCount[_to] = minted + _mintAmount;
        _mintRandom(msg.sender, _mintAmount);
    }

    // Only Owner executable functions
    function mintByOwner(address _to, uint256 _mintAmount) external onlyOwner {
        require(totalSupply() + _mintAmount <= birdSupply, "mint over supply");
        _mintRandom(_to, _mintAmount);

    }

    function addToAllowlist(address[] calldata _addresses, uint256 _mintAllowance) external onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            presaleBirds[_addresses[i]] = _mintAllowance;
        }
    } 


    //#SALES TOGGLE


    function togglePublicSaleActive() external onlyOwner {
        if (publicSaleActive) {
            publicSaleActive = false;
            return;
        }
        publicSaleActive = true;
    }

    function toggleCommunitySaleActive() external onlyOwner {
        if (allowlistActive) {
            allowlistActive = false;
            return;
        }
        allowlistActive = true;
    }


    
    //#SETTERS
    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function setPayoutAddress(address _newPayout) external onlyOwner {
        multisig_wallet = _newPayout;
    }    

    function setPrice(uint256 _price) external onlyOwner {
        birdPrice = _price;
    }

    function setPublicMintAmount(uint256 _amt) external onlyOwner {
        publicMintAmt = _amt;
    }

    //hoothoot
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(multisig_wallet).transfer(balance);
    }    


}