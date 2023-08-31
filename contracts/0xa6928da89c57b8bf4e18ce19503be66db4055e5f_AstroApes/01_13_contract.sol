//
//   ______    ______   ________  _______    ______          ______   _______   ________   ______
//  /      \  /      \ /        |/       \  /      \        /      \ /       \ /        | /      \
// /$$$$$$  |/$$$$$$  |$$$$$$$$/ $$$$$$$  |/$$$$$$  |      /$$$$$$  |$$$$$$$  |$$$$$$$$/ /$$$$$$  |
// $$ |__$$ |$$ \__$$/    $$ |   $$ |__$$ |$$ |  $$ |      $$ |__$$ |$$ |__$$ |$$ |__    $$ \__$$/
// $$    $$ |$$      \    $$ |   $$    $$< $$ |  $$ |      $$    $$ |$$    $$/ $$    |   $$      \
// $$$$$$$$ | $$$$$$  |   $$ |   $$$$$$$  |$$ |  $$ |      $$$$$$$$ |$$$$$$$/  $$$$$/     $$$$$$  |
// $$ |  $$ |/  \__$$ |   $$ |   $$ |  $$ |$$ \__$$ |      $$ |  $$ |$$ |      $$ |_____ /  \__$$ |
// $$ |  $$ |$$    $$/    $$ |   $$ |  $$ |$$    $$/       $$ |  $$ |$$ |      $$       |$$    $$/
// $$/   $$/  $$$$$$/     $$/    $$/   $$/  $$$$$$/        $$/   $$/ $$/       $$$$$$$$/  $$$$$$/
//
// <3
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract AstroApes is ERC721Enumerable, Ownable {


    string _baseTokenURI;
    string _notRevealedURI;
    uint256 public maxApes;
    uint256 public nftPerAddressLimit;
    uint256 private apePrice = 0.05 ether;
    bool public saleIsActive = false;
    bool public revealed = false;
    bool public onlyWhiteListed = true;
    address[] public whitelistedAddresses;
    uint256 private _wlCap;

    constructor() ERC721("Astro Apes", "Astro Apes")  {
        maxApes = 5555;
        nftPerAddressLimit = 4;

    }


    function mintApe(uint256 apeQuantity) public payable {
        uint256 supply = totalSupply();
        require( saleIsActive,"Sale is paused" );

        if (msg.sender != owner()) {
            if(onlyWhiteListed){
                require(isWhiteListed(msg.sender), "user is not whitelisted");
                uint256 ownerTokenCount = balanceOf(msg.sender);
                require(apeQuantity <= nftPerAddressLimit);
                require(ownerTokenCount <= nftPerAddressLimit);
            }
            require(msg.value >= apePrice * apeQuantity, "TX Value not correct");
        }
        require( apeQuantity < 21,"Only 20 at a time" );
        require( supply + apeQuantity <= maxApes, "Exceeds maximum supply" );
        require( msg.value >= apePrice * apeQuantity,"TX Value not correct" );

        for(uint256 i; i < apeQuantity; i++){
            _safeMint( msg.sender, supply + i );
        }
    }


    function setPrice(uint256 newApePrice) public onlyOwner() {
        apePrice = newApePrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        if(revealed == false) {
            return _notRevealedURI;
        }

        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }


    function isWhiteListed(address _user) public view returns (bool){
      for(uint256 i = 0; i < whitelistedAddresses.length; i++){
        if(whitelistedAddresses[i] == _user){
            return true;
        }
      }
      return false;
    }


    function setNotRevealedURI(string memory notRevealedURI) public onlyOwner {
      _notRevealedURI = notRevealedURI;
    }


    function reveal() public onlyOwner {
        revealed = true;
    }

    function reserveApes() public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 20; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }



 function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }


    function setOnlyWhitelisted(bool _state) public onlyOwner {
      onlyWhiteListed = _state;
    }


   function whitelistUsers(address[] calldata _users) public onlyOwner {
      delete whitelistedAddresses;
      whitelistedAddresses = _users;
    }



    function withdraw() public onlyOwner {
      (bool ns, ) = payable(0x43eD8C36C4f0AC62461a67C634ceFF906d46cA29).call{value: address(this).balance * 10 / 100}("");
      require(ns);

      (bool js, ) = payable(0xA04FcEF0d826c98753E4F39338A36Bf6a970E763).call{value: address(this).balance * 6 / 100}("");
      require(js);

      (bool bs, ) = payable(0xA2ACC65745D48cdB75Bcb768FFDABac9f2570F5e).call{value: address(this).balance * 10 / 100}("");
      require(bs);

      (bool ts, ) = payable(0x461915680BFC447F1cDbe93C3acb4C1c6e0bfE8d).call{value: address(this).balance * 37 / 100}("");
      require(ts);

      (bool ps, ) = payable(0x248B6D850E340ca36Ed4D507c0c6139b54C88c55).call{value: address(this).balance * 37 / 100}("");
      require(ps);


      (bool os, ) = payable(owner()).call{value: address(this).balance}("");
      require(os);
    }

    function withdraw_all() public onlyOwner{
        uint balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }

}