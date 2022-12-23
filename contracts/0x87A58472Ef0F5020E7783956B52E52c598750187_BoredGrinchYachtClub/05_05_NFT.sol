// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./libraries/ERC721A.sol";
import "./libraries/Strings.sol";

contract BoredGrinchYachtClub is ERC721A {
    using Strings for uint256;

    string private baseURI;

    uint256 public price = 0.0033 ether;

    uint256 public maxPerTx = 10;

    uint256 public maxFreePerWallet = 1;

    uint256 public totalFree = 10000;

    uint256 public maxSupply = 10000;

    bool public mintEnabled = false;

    bool public whitelistSaleEnabled = false;

    address public owner;

    mapping(address => uint256) private _mintedFreeAmount;
    mapping(address => bool) public whitelistUsers;

    constructor(address owner_) ERC721A("Bored Grinch Yacht Club", "BGYC") {
        owner = msg.sender;
        _safeMint(owner_, 5);
        setBaseURI("ipfs://QmaSzQAsQWzswVGp4kZWXQNWCWjZD5uTkTV1WLyR5pbyBC/");
        owner = owner_;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function mint(uint256 count) external payable {
        uint256 cost = price;
        bool isFree = ((totalSupply() + count < totalFree + 1) &&
            (_mintedFreeAmount[msg.sender] + count <= maxFreePerWallet));

        if (isFree) {
            cost = 0;
        }

        require(msg.value >= count * cost, "Please send the exact amount.");
        require(totalSupply() + count < maxSupply + 1, "No more");
        require(mintEnabled, "Minting is not live yet");
        require(count < maxPerTx + 1, "Max per TX reached.");

        if (isFree) {
            _mintedFreeAmount[msg.sender] += count;
        }

        if(whitelistSaleEnabled) {
            require(whitelistUsers[msg.sender] == true, "You are not on the whitelist");
            _safeMint(msg.sender, count);
        } else {
            _safeMint(msg.sender, count);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function userOnWhitelist(address _user) public view returns (bool) {
        return whitelistUsers[_user];
    }

    function addWhitelist(address[] memory _users) external onlyOwner { 
        for(uint256 i = 0; i < _users.length; i++) {
            whitelistUsers[_users[i]] = true;
        }
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        totalFree = amount;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function startWhitelistSale() external onlyOwner {
        whitelistSaleEnabled = !whitelistSaleEnabled;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}