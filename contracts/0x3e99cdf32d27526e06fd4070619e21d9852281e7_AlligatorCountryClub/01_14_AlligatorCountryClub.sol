// SPDX-License-Identifier: MIT
/* 
-------------------------------------
ALLIGATOR COUNTRY CLUB NFT COLLECTION 🐊
--------- Created by BradP ----------
   
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AlligatorCountryClub is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_GATORS = 10000;
    uint256 public constant PRICE = 0.07 ether;

    uint256 public constant MAX_PER_MINT = 50;

    uint256 public constant PRESALE_MAX_MINT = 10;

    uint256 public constant MAX_GATORS_MINT = 10;

    uint256 public constant RESERVED_GATORS = 25;

    address public constant treasury =
        0x02840b7558517a880BAF37A33B4FeB1185e9B198;

    uint256 public reservedClaimed;

    uint256 public numGatorsMinted;

    string public baseTokenURI;

    bool public publicSaleStarted;
    bool public presaleStarted;

    mapping(address => bool) private _presaleEligible;
    mapping(address => uint256) private _totalClaimed;

    event BaseURIChanged(string baseURI);
    event PresaleMint(address minter, uint256 amountOfGators);
    event PublicSaleMint(address minter, uint256 amountOfGators);

    modifier whenPresaleStarted() {
        require(presaleStarted, "Presale has not started");
        _;
    }

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Public sale has not started");
        _;
    }

    constructor(string memory baseURI) ERC721("Alligator Country Club", "ACC") {
        baseTokenURI = baseURI;
    }

    function claimReserved(address recipient, uint256 amount)
        external
        onlyOwner
    {
        require(
            reservedClaimed != RESERVED_GATORS,
            "Already have claimed all reserved gators"
        );
        require(
            reservedClaimed + amount <= RESERVED_GATORS,
            "Minting would exceed max reserved gators"
        );
        require(recipient != address(0), "Cannot add null address");
        require(totalSupply() < MAX_GATORS, "All tokens have been minted");
        require(
            totalSupply() + amount <= MAX_GATORS,
            "Minting would exceed max supply"
        );

        uint256 _nextTokenId = numGatorsMinted + 1;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recipient, _nextTokenId + i);
        }
        numGatorsMinted += amount;
        reservedClaimed += amount;
    }

    function addToPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _presaleEligible[addresses[i]] = true;

            _totalClaimed[addresses[i]] > 0 ? _totalClaimed[addresses[i]] : 0;
        }
    }

    function checkPresaleEligiblity(address addr) external view returns (bool) {
        return _presaleEligible[addr];
    }

    function amountClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "Cannot add null address");

        return _totalClaimed[owner];
    }

    function mintPresale(uint256 amountOfGators)
        external
        payable
        whenPresaleStarted
    {
        require(totalSupply() < MAX_GATORS, "All gators have been minted");
        require(
            amountOfGators <= PRESALE_MAX_MINT,
            "Cannot purchase this many gators during presale"
        );
        require(
            totalSupply() + amountOfGators <= MAX_GATORS,
            "Minting would exceed max supply"
        );
        require(
            _totalClaimed[msg.sender] + amountOfGators <= PRESALE_MAX_MINT,
            "Purchase exceeds max allowed"
        );
        require(amountOfGators > 0, "Must mint at least one Gator");
        require(PRICE * amountOfGators <= msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfGators; i++) {
            uint256 tokenId = numGatorsMinted + 1;

            numGatorsMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PresaleMint(msg.sender, amountOfGators);
    }

    function mint(uint256 amountOfGators)
        external
        payable
        whenPublicSaleStarted
    {
        require(totalSupply() < MAX_GATORS, "All gators have been minted");
        require(
            amountOfGators <= MAX_PER_MINT,
            "Cannot purchase this many gators in a transaction"
        );
        require(
            totalSupply() + amountOfGators <= MAX_GATORS,
            "Minting would exceed max supply"
        );
        require(
            _totalClaimed[msg.sender] + amountOfGators <= MAX_GATORS_MINT,
            "Purchase exceeds max allowed per address"
        );
        require(amountOfGators > 0, "Must mint at least one Gator");
        require(PRICE * amountOfGators == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfGators; i++) {
            uint256 tokenId = numGatorsMinted + 1;

            numGatorsMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PublicSaleMint(msg.sender, amountOfGators);
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        emit BaseURIChanged(baseURI);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(treasury, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
}