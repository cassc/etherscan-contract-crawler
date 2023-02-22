// SPDX-License-Identifier: MIT
/**
.     .       .  .   . .   .   . .    +  .
  .     .  :     .    .. :. .___---------___.
       .  .   .    .  :.:. _".^ .^ ^.  '.. :"-_. .
    .  :       .  .  .:../:            . .^  :.:\.
        .   . :: +. :.:/: .   .    .        . . .:\
 .  :    .     . _ :::/:               .  ^ .  . .:\
  .. . .   . - : :.:./.                        .  .:\
  .      .     . :..|:                    .  .  ^. .:|
    .       . : : ..||        .                . . !:|
  .     . . . ::. ::\(                           . :)/
 .   .     : . : .:.|. ######              .#######::|
  :.. .  :-  : .:  ::|.#######           ..########:|
 .  .  .  ..  .  .. :\ ########          :######## :/
  .        .+ :: : -.:\ ########       . ########.:/
    .  .+   . . . . :.:\. #######       #######..:/
      :: . . . . ::.:..:.\           .   .   ..:/
   .   .   .  .. :  -::::.\.       | |     . .:/
      .  :  .  .  .-:.":.::.\             ..:/
 .      -.   . . . .: .:::.:.\.           .:/
.   .   .  :      : ....::_:..:\   ___.  :/
   .   .  .   .:. .. .  .: :.:.:\       :/
     +   .   .   : . ::. :.:. .:.|\  .:/|
     .         +   .  .  ...:: ..|  --.:|
.      . . .   .  .  . ... :..:.."(  ..)"
 .   .       .      :  .   .: ::/  .  .::\
*/

/** 
    Project: Ugliens Genesis NFT
    Website: UgliensTown.wtf

    by RetroBoy (RetroBoy.dev)
*/

pragma solidity >=0.7.0 <0.9.0;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";

contract UgliensGenesisNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    mapping(address => uint256) public preSaleSpots;

    string baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";

    uint256 public cost = 0.1 ether;
    uint256 public maxSupply = 666;

    bool public preSale = true;
    bool public paused = true;
    bool public revealed = true;

    address public dev; // 35%
    address public cm; // 15%

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        address payable _dev,
        address payable _cm
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        dev = _dev;
        cm = _cm;
    }

    // internal

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public

    function mint(uint256 _amount) public payable nonReentrant {
        uint256 supply = totalSupply();
        require(!paused, "Sale is paused");
        require(_amount > 0, "Invalid mint amount");
        require(supply + _amount <= maxSupply, "Max supply exceeded");
        require(msg.value >= cost * _amount, "Not enough funds");

        if (preSale == true) {
            isEligibleForPreSale(msg.sender, _amount);
        }

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mintFor(address _to, uint256 _amount) public payable nonReentrant {
        uint256 supply = totalSupply();
        require(!paused, "Sale is paused");
        require(_amount > 0, "Invalid mint amount");
        require(supply + _amount <= maxSupply, "Max supply exceeded");
        require(msg.value >= cost * _amount, "Not enough funds");

        if (preSale == true) {
            isEligibleForPreSale(_to, _amount);
        }

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

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
    }

    //only owner

    function airDrop(address _to, uint256 _amount) public onlyOwner {
        uint256 supply = totalSupply();
        require(_amount > 0);
        require(supply + _amount <= maxSupply);

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    // PreSale functions

    function enablePreSale() public onlyOwner {
        preSale = true;
        cost = 0.1 ether;
    }

    function enablePublicSale() public onlyOwner {
        preSale = false;
        cost = 0.125 ether;
    }

    function addPreSaleSpots(address to, uint256 _amount) external onlyOwner {
        preSaleSpots[to] += _amount;
    }

    function addPreSaleSpotsMultiple(
        address[] memory to,
        uint256[] memory _amounts
    ) external onlyOwner {
        require(
            to.length == _amounts.length,
            "Different amount of addresses and spots"
        );
        uint256 total = 0;

        for (uint256 i = 0; i < to.length; ++i) {
            preSaleSpots[to[i]] += _amounts[i];
            total += _amounts[i];
        }
    }

    function isEligibleForPreSale(address user, uint256 _amount) internal {
        require(preSaleSpots[user] >= _amount, "Exceeds pre-sale spots");
        preSaleSpots[user] -= _amount;
    }

    // Withdraws and Wallets

    function updateDevWallet(address _newDev) public {
      require(
            owner() == msg.sender ||
                cm == msg.sender,
            "Not authorized"
        );
        dev = _newDev;
    }

    function updateCMWallet(address _newCM) public {
      require(
            owner() == msg.sender ||
                cm == msg.sender,
            "Not authorized"
        );
        cm = _newCM;
    }

    function withdraw() external nonReentrant {
        require(
            owner() == msg.sender ||
                dev == msg.sender ||
                cm == msg.sender,
            "Not authorized"
        );
        uint256 balance = address(this).balance;
        payable(owner()).transfer((balance * 50) / 100); // 50%
        payable(dev).transfer((balance * 35) / 100); // 35%
        payable(cm).transfer((balance * 15) / 100); // 15%
    }
}