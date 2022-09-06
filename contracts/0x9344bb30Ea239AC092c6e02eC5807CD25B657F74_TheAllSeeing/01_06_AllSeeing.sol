/*
           _ . - = - . _
       . "  \  \   /  /  " .
     ,  \                 /  .
   . \   _,.--~=~"~=~--.._   / .
  ;  _.-"  / \ !   ! / \  "-._  .
 / ,"     / ,` .---. `, \     ". \
/.'   `~  |   /:::::\   |  ~`   '.\
\`.  `~   |   \:::::/   | ~`  ~ .'/
 \ `.  `~ \ `, `~~~' ,` /   ~`.' /
  .  "-._  \ / !   ! \ /  _.-"  .
   ./    "=~~.._  _..~~=`"    \.
     ,/         ""          \,
       . _/             \_ . 
          " - ./. .\. - "
*/

pragma solidity >=0.6.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TheAllSeeing is ERC721A, Ownable, ReentrancyGuard {

    string public        baseURI;
    uint public          price             = 0.0025 ether;
    uint public          maxPerTx          = 2;
    uint public          maxPerWallet      = 2;
    uint public          maxSupply         = 600;
    bool public          mintLive          = false;

    address[] private _team = [
        0xb1D9a0D41FC14A9a34fD5a7351974AF5658365AD,
        0x74D137D9808Fd27F221e47802addE70D9EAa4F05
    ];

    constructor() 
    ERC721A("The All Seeing", "EYE") {
        _safeMint(_team[0], 1);
    }

    function mint(uint256 amt) external payable
    {
        require(mintLive, "Minting is not live yet");
        require( amt < maxPerTx + 1, "One can only have two eyes");
        require(_numberMinted(_msgSender()) < maxPerWallet, "One can only have two eyes. The eye is watching.");
        require(totalSupply() + amt < maxSupply + 1, "Max supply reached");
        require(msg.value == (amt * price), "Send more ETH.");

        _safeMint(msg.sender, amt);
    }

    function toggleMinting() external onlyOwner {
        mintLive = !mintLive;
    }

    function teamClaim() external {
        _safeMint(_team[0], 24);
        _safeMint(_team[1], 25);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setmaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}