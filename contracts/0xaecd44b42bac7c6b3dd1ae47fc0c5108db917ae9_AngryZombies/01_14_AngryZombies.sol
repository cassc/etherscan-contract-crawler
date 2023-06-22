// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AngryZombies is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    string public NotRevealedUri;

    uint256 public constant MAX_ZOMBIES = 10000;
    uint256 public constant PRICE = 0.04 ether;
    uint256 public constant MAX_PER_MINT = 20;
    uint256 public constant PRESALE_MAX_MINT = 10;
    uint256 public constant MAX_ZOMBIES_MINT = 1000;
    uint256 public constant RESERVED_ZOMBIES = 100;

    address public constant founderAddress = 0x7Ee59B62Ce752e6D26b534802d65c3097A7eE7da;
    address public constant devAddress = 0xE32Ea19595BF809c23A3af20772f6AD9CE4672b6;
    address public constant whodaAddress = 0x1b678D4790A2832859C0684e3EAAAb4dcaE02d83;
    address public constant artistAddress = 0x7a582050d378631E1A22BcE761b3A51559F5507D;

    uint256 public reservedClaimed;
    uint256 public numZombiesMinted;

    bool public publicSaleStarted;
    bool public revealed = false;
    bool public paused = false;

    mapping(address => bool) private whitelisted;
    mapping(address => uint256) private _totalClaimed;

    event BaseURIChanged(string baseURI);
    event PresaleMint(address minter, uint256 amountOfZombies);
    event PublicSaleMint(address minter, uint256 amountOfZombies);

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Crypto Benjis Public Sale Has Not Begun");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function claimReserved(address recipient, uint256 amount) external onlyOwner {
        require(reservedClaimed != RESERVED_ZOMBIES, "All reserved Zombies are already claimed");
        require(reservedClaimed + amount <= RESERVED_ZOMBIES, "Minting would exceed max Zombies reserved");
        require(recipient != address(0), "Cannot add null address");
        require(totalSupply() < MAX_ZOMBIES, "Too late fuckers, Go to Opensea Fuckhead!");
        require(totalSupply() + amount <= MAX_ZOMBIES, "Max Supply reached!");

        uint256 _nextTokenId = numZombiesMinted + 1;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recipient, _nextTokenId + i);
        }

        numZombiesMinted += amount;
        reservedClaimed += amount;
    }

    function checkPresaleEligiblity(address addr) external view returns (bool) {
        return whitelisted[addr];
    }

    function amountClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "Cannot add null address");

        return _totalClaimed[owner];
    }


    function mint(uint256 amountOfZombies) external payable whenPublicSaleStarted {
        require(totalSupply() < MAX_ZOMBIES, "All Zombies have been minted");
        require(amountOfZombies <= MAX_PER_MINT, "Amount requested is higher than the amount allowed.");
        require(totalSupply() + amountOfZombies <= MAX_ZOMBIES, "Minting would exceed max supply");
        require(
            _totalClaimed[msg.sender] + amountOfZombies <= MAX_ZOMBIES_MINT,
            "Purchase exceeds max allowed per address"
        );
        require(amountOfZombies > 0, "Must mint at least one Zombie");
        require(PRICE * amountOfZombies == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfZombies; i++) {
            uint256 tokenId = numZombiesMinted + 1;

            numZombiesMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PublicSaleMint(msg.sender, amountOfZombies);
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return NotRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string memory _initBaseURI) public onlyOwner {
        baseURI = _initBaseURI;
    }

    function setNotRevealedURI(string memory _NotRevealedURI) public onlyOwner {
        NotRevealedUri = _NotRevealedURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function whitelistUser(address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");
            whitelisted[addresses[i]] = true;
            _totalClaimed[addresses[i]] > 0 ? _totalClaimed[addresses[i]] : 0;
        }
    }

    function removeWhitelistUser(address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");
            whitelisted[addresses[i]] = false;
        }
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(artistAddress, ((balance * 20) / 100));
        _widthdraw(devAddress, ((balance * 20) / 100));
        _widthdraw(whodaAddress, ((balance * 30) / 100));
        _widthdraw(founderAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }
}