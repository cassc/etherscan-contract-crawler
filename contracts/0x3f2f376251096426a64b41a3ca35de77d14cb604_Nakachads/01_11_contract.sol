// SPDX-License-Identifier: MIT
/*
 _______      _____   ____  __.  _____  _________   ___ ___    _____  ________    _________
 \      \    /  _  \ |    |/ _| /  _  \ \_   ___ \ /   |   \  /  _  \ \______ \  /   _____/
 /   |   \  /  /_\  \|      <  /  /_\  \/    \  \//    ~    \/  /_\  \ |    |  \ \_____  \ 
/    |    \/    |    \    |  \/    |    \     \___\    Y    /    |    \|    `   \/        \
\____|__  /\____|__  /____|__ \____|__  /\______  /\___|_  /\____|__  /_______  /_______  /
        \/         \/        \/       \/        \/       \/         \/        \/        \/             

by ugalabs
website: nakachads.io
twitter: @nakachads                          
*/
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Nakachads is ERC721A, Ownable, ERC721Royalty {
    using SafeMath for uint256;

    bool public saleIsActive = false;
    string public _baseURIextended;

  
    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant MAX_PUBLIC_MINT = 3;
    uint256 public constant MAX_MINT_PER_WALLET = 3;

    uint256 public PRICE_PER_TOKEN = 0.00 ether; // free mint yeah !!
    address private immutable adminSigner = 0xC8AfBf7DBFD7078944C6D4548F792e748013e996;
    address private immutable royaltyAddress = 0xd5E65f15B563B00cF4e8C4593356F9628890fBc4;
    address private immutable devAddress = 0x30d7454Eb4753AaECB917A85C6D8F0fFcC7a53cE;
    address private immutable creatorAddress = 0xF62C1e37fA90abb0Ec9484F98B5Bad29617D4709;


    constructor() ERC721A("nakachads", "NAKACHADS") {
        _setDefaultRoyalty(royaltyAddress, 440); 
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721A, ERC721Royalty) {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function changeSaleSettings(uint256 price) public onlyOwner {
        PRICE_PER_TOKEN = price;
    }

    function teamMint(
		uint256 numberOfNakachads
	) public onlyOwner {
        uint256 ts = totalSupply();        
        require(ts + (numberOfNakachads * 2) <= MAX_SUPPLY, "Purchase would exceed max tokens");

        _safeMint(creatorAddress, numberOfNakachads);
        _safeMint(devAddress, numberOfNakachads);
	}

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        
        uint256 balanceSubstracedCharity = balance.mul(10).div(100); // every withdaw pulls 10% in royality address
        _widthdraw(royaltyAddress, balanceSubstracedCharity);
        balance = address(this).balance;
        uint256 balanceDivided = balance.mul(50).div(100); // development and marketing gets 30%
        _widthdraw(devAddress, balanceDivided);
        _widthdraw(creatorAddress, address(this).balance); // creator gets rest 40%
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function mint(uint numberOfNakachads) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfNakachads <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfNakachads <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfNakachads <= msg.value, "Ether value sent is not correct");
        require(balanceOf(msg.sender) < MAX_MINT_PER_WALLET, "Max Mint per wallet reached");

        _safeMint(msg.sender, numberOfNakachads);
    }
}