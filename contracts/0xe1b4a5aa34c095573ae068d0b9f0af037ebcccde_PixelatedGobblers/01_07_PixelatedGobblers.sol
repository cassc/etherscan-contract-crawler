// SPDX-License-Identifier: MIT

// ###    ###    #   #  ####   #        #    #####  ####   ###            ##     ##    ####   ####   #      ####   ###     ##
// #  #    #      # #   #      #       # #     #    #      #  #          #  #   #  #   #   #  #   #  #      #      #  #   #  #
// #  #    #       #    ###    #      #   #    #    ###    #  #          #      #  #   ####   ####   #      ###    #  #    #
// ###     #      # #   #      #      #####    #    #      #  #          # ##   #  #   #   #  #   #  #      #      ###      #
// #       #      # #   #      #      #   #    #    #      #  #          #  #   #  #   #   #  #   #  #      #      #  #   #  #
// #      ###    #   #  ####   ####   #   #    #    ####   ###            ##     ##    ####   ####   ####   ####   #  #    ##
// 0xDev

pragma solidity ^0.8.14;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract PixelatedGobblers is ERC721A, Ownable, ReentrancyGuard {

    uint256 public maxGoos = 6666;
    uint256 public gooLimitPerTxn = 10;
    uint256 public freeGooPerWallet = 1;
    uint256 public gooPrice = 0.003 ether;

    bool canCollectGoo = false;

    mapping(address => bool) private accountFreeMinted;

    bool revealed = false;
    string private baseURI = "https://nftstorage.link/ipfs/bafkreief7rrqoog2y27ynikfh5zdyimdrnrxkfml2w7c36fniqx3yxspf4";

    address public constant DEV_ADDRESS = 0x5bA812C3d5Be98e77CeB3174a310639AEb1C7Cd1;  // 57.5 
    address public constant PROJECT_ADDRESS = 0x3De71EdB08BAA8F5f5D79561D73946829EF0B2f3; // 42.5
  
    constructor() ERC721A("PixelatedGobblers", "PXLGOO") {}

    // COLLECTING GOO FUNCTIONS
    function collectGoo(uint256 _goos) external payable {
        require(tx.origin == msg.sender,"Contracts Not Allowed to Mint.");
        require(canCollectGoo, "Can't collect Goo yet.");
        
        require(_goos > 0,"Collect atleast 1 Goo");
        require(_goos <= gooLimitPerTxn, "Can't collect more than 10 Goo at once.");
        require(totalSupply() + _goos <= maxGoos, "No more Goo.");
        
        if (!accountFreeMinted[msg.sender]) {
            require(msg.value >= gooPrice * (_goos - freeGooPerWallet), "Add more ETH to your transaction.");
            accountFreeMinted[msg.sender] = true;
        } else {
            require(msg.value >= gooPrice * _goos, "Add more ETH to your transaction.");
        }

        _safeMint(msg.sender, _goos);
    }

    function collectFreeGoo() external payable {
        require(tx.origin == msg.sender,"Contracts Not Allowed to Mint.");
        require(canCollectGoo, "Can't collect Goo yet.");
        require(totalSupply() + freeGooPerWallet <= maxGoos, "No more Goo.");
        
        require(!accountFreeMinted[msg.sender], "Can only collect 1 free Goo.");
        accountFreeMinted[msg.sender] = true;
        _safeMint(msg.sender, freeGooPerWallet);
    }


    // READ ONLY FUNCTIONS
    function isGooCollectingLive() public view returns (bool) {
        return canCollectGoo;
    }

    function getGooCost() public view returns (uint256) {
        return gooPrice;
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (revealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        } else {
            return string(abi.encodePacked(baseURI));
        }
    }

    // ADMIN ONLY FUNCTIONS
    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function showGoo(bool _revealed, string calldata _baseURI) public onlyOwner {
        revealed = _revealed;
        baseURI = _baseURI;
    }

    function startCollectingGoo() external onlyOwner {
        canCollectGoo = !canCollectGoo;
    }
        
    function setMaxGooPerTxn(uint256 _gooLimit) external onlyOwner {
        gooLimitPerTxn = _gooLimit;
    }

    function setFreeGooPerWallet(uint256 _freeGooPerWallet) external onlyOwner {
        freeGooPerWallet = _freeGooPerWallet;
    }

    function setGooPrice(uint256 _price) external onlyOwner {
        gooPrice = _price;
    }

    function setMaxGoos(uint256 _maxGoos) external onlyOwner {
        maxGoos = _maxGoos;
    }

    function collectGooForTeam(uint256 _numberOfTokens) external onlyOwner {
        _safeMint(msg.sender, _numberOfTokens);
    }

    function batchCollectGoo(address[] calldata addresses, uint[] calldata amounts) external onlyOwner {
        require(addresses.length == amounts.length, "Addresses and amounts length dont match");
        for (uint i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amounts[i]);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        uint256 acc_a = (balance * 4250) / 10000;
        payable(PROJECT_ADDRESS).transfer(acc_a);
        payable(DEV_ADDRESS).transfer(address(this).balance);
    }
}