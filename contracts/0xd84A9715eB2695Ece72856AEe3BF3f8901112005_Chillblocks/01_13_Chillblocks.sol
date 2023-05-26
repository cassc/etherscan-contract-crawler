// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Chillblocks is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant COST_ONE = 0.05 ether;
    uint256 public constant COST_FIVE = 0.04 ether;
    uint256 public constant COST_TEN = 0.03 ether;

    uint256 public constant MAX_MINT = 10;
    uint256 public constant MAX_PRIVATE_SUPPLY = 100;
    uint256 public constant MAX_PUBLIC_SUPPLY = 9900;
    uint256 public constant MAX_SUPPLY = MAX_PRIVATE_SUPPLY + MAX_PUBLIC_SUPPLY;
    
    address constant ADDRESS_1 = 0xD7cc2856E994d992C8c26f9777BB22670cEEFb1D;
    address constant ADDRESS_2 = 0x0826987F35FcA738B388f5d96f503456C478dB61;

    uint256 public whitelistCost = 0.0 ether;
    uint256 public whitelistMaxMint = 1;

    bool public isActive = false;
    bool public isFreeActive = false;
    bool public isWhitelistActive = false;

    uint256 public totalPrivateSupply;
    uint256 public totalPublicSupply;

    string private _contractURI;
    string private _baseTokenURI = "https://chillblocks.com/";
    mapping(address => uint256) private _claimed;
    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _whitelistClaimed;

    constructor(
        string memory __baseURI,
        string memory __contractURI
    ) ERC721("ChillBlocks", "CHILL") {
        setBaseURI(__baseURI);
        setContractURI(__contractURI);
    }

    function setContractURI(string memory contractURI_) 
        public 
        onlyOwner 
    {
        _contractURI = contractURI_;
    }

    function contractURI() 
        public 
        view 
        returns (string memory) 
    {
        return _contractURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = true;
        }
    }

    function claimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "Zero address not claimable");

        return _claimed[owner];
    }

    function freeMint() external payable {
        require(isFreeActive, "Free minting is not active");
        require(_claimed[msg.sender] == 0, "Free token already claimed");
        require(totalSupply() < MAX_SUPPLY, "All tokens minted");
        require(totalPublicSupply < MAX_PUBLIC_SUPPLY, "Over max public limit");

        totalPublicSupply += 1;
        _claimed[msg.sender] += 1;
        _safeMint(msg.sender, MAX_PRIVATE_SUPPLY + totalPublicSupply);
    }

    function getCost(uint256 num) public pure returns (uint256) {
        if (num < 5) {
            return COST_ONE * num;
        } else if (num > 4 && num < 10) {
            return COST_FIVE * num;
        }
        return COST_TEN * num;
    }

    function gift(address to, uint256 num) external onlyOwner {
        require(totalSupply() < MAX_SUPPLY + 1, "All tokens minted");
        require(
            totalPrivateSupply + num < MAX_PRIVATE_SUPPLY + 1,
            "Exceeds private supply"
        );

        for (uint256 i; i < num; i++) {
            totalPrivateSupply += 1;
            _safeMint(to, totalPrivateSupply);
        }
    }

    function mint(uint256 num) external payable {
        require(isActive, "Contract is inactive");
        require(num < MAX_MINT + 1, "Over max limit");
        require(totalSupply() < MAX_SUPPLY, "All tokens minted");
        require(totalPublicSupply < MAX_PUBLIC_SUPPLY, "Over max public limit");
        require(msg.value >= getCost(num), "ETH sent is not correct");

        for (uint256 i; i < num; i++) {
            if (totalPublicSupply < MAX_PUBLIC_SUPPLY) {
                totalPublicSupply += 1;
                _safeMint(msg.sender, MAX_PRIVATE_SUPPLY + totalPublicSupply);
            }
        }
    }

    function isOnWhitelist(address addr) external view returns (bool) {
        return _whitelist[addr];
    }

    function removeFromWhitelist(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(
                addresses[i] != address(0),
                "Can't remove the null address"
            );

            _whitelist[addresses[i]] = false;
        }
    }

    function setActive(bool val) external onlyOwner {
        require(
            bytes(_baseTokenURI).length != 0,
            "Set Base URI before activating"
        );
        isActive = val;
    }

    function setBaseURI(string memory val) public onlyOwner {
        _baseTokenURI = val;
    }

    function setFreeActive(bool val) external onlyOwner {
        isFreeActive = val;
    }

    function setWhitelistActive(bool val) external onlyOwner {
        isWhitelistActive = val;
    }

    function setWhitelistMaxMint(uint256 val) external onlyOwner {
        whitelistMaxMint = val;
    }

    function setWhitelistPrice(uint256 val) external onlyOwner {
        whitelistCost = val;
    }

    function whitelistClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "Zero address not claimable");

        return _whitelistClaimed[owner];
    }

    function whitelistMint(uint256 num) external payable {
        require(isWhitelistActive, "Whitelist is not active");
        require(_whitelist[msg.sender], "You are not on the Whitelist");
        require(num < whitelistMaxMint + 1, "Over max limit");
        require(
            _whitelistClaimed[msg.sender] + num < whitelistMaxMint + 1,
            "Whitelist tokens already claimed"
        );
        require(totalSupply() < MAX_SUPPLY, "All tokens minted");
        require(totalPublicSupply < MAX_PUBLIC_SUPPLY, "Over max public limit");
        require(whitelistCost * num <= msg.value, "ETH amount is not correct");

        for (uint256 i = 0; i < num; i++) {
            totalPublicSupply += 1;
            if (whitelistCost == 0) {
                _claimed[msg.sender] += 1;
            }
            _whitelistClaimed[msg.sender] += 1;
            _safeMint(msg.sender, MAX_PRIVATE_SUPPLY + totalPublicSupply);
        }
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 split = (balance / 2);
        require(payable(ADDRESS_1).send(split));
        require(payable(ADDRESS_2).send(split));
    }
}