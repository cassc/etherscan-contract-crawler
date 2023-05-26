// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

/**
 * @title BrkfstWorld contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract BrkfstWorld is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    string public BRKFSTWORLD_PROVENANCE = "";
    uint256 public constant SndwchPrice = 55000000000000000; //0.055 ETH
    uint public constant maxSndwchPurchase = 3; //Max Mint Per Transaction: 3
    uint public constant maxReservationPurchase = 2; //Max Reservation Mint: 2
    uint256 public MAX_SNDWCH = 6970;
    uint public sndwchReserve = 55; // TOTAL BRKFST CLUB MEMBERS
    bool public saleIsActive = false;
    bool public isAllowListActive = false;
    string _baseTokenURI;

    mapping(address => uint8) private _allowList;

    constructor(string memory baseURI) ERC721("Brkfst World", "BRKFST") {
        _baseTokenURI = baseURI;
    }
    
/*
* Reservation List Sale
*/
    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }
    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr]; 
    }

    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(balanceOf(msg.sender) <= 2, 'Prevent Multiple Mints'); 
        require(numberOfTokens <= maxReservationPurchase, "Can only mint 2 tokens at a time");
        require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
        require(ts + numberOfTokens <= MAX_SNDWCH, "Purchase would exceed max tokens");
        require(SndwchPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _allowList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

/*
* Set provenance once it's calculated
*/
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        BRKFSTWORLD_PROVENANCE = provenanceHash;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

/*
* Pause sale if active, make active if paused
*/
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

/**
* Mint SndWchs
*/
    function mintSndwch(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Brkfst Sndwch");
        require(numberOfTokens <= maxSndwchPurchase, "Can only mint 3 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_SNDWCH, "Purchase would exceed max supply of Sndwchs");
        require(SndwchPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_SNDWCH) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function reserveSndwchs(address [] memory _to) public onlyOwner {        
        uint supply = totalSupply();
        require(_to.length > 0 && _to.length <= sndwchReserve, "Not enough reserve left for team");
        for (uint i = 0; i < _to.length; i++) {
            _safeMint(_to[i], supply + i);
        }
        sndwchReserve = sndwchReserve.sub(_to.length);
    }

/*
* Withdraw Contract Balance
*/
    // withdraw addresses
    address t1 = 0xDb94Daa8bF1b6F45B122F442F922a2C4DD2F7aDe; //BrkfstSndwch
    address t2 = 0x2206168CdE2b3652E2488d9a1283531A4d200aea; //Kev
    address t3 = 0x6a38D9c83bF780aCF34E90047D44e692221C6Aa7; //Sifu

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _brkfst = address(this).balance * 50/100;
        uint256 _kevy = address(this).balance * 30/100;
        uint256 _sifu = address(this).balance * 20/100;
        require(payable(t1).send(_brkfst));
        require(payable(t2).send(_kevy));
        require(payable(t3).send(_sifu));
    }
}