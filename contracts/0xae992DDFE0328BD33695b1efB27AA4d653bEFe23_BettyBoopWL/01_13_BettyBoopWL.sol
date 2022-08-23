// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BettyBoopWL is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    uint256 public cost = 0.082 ether;
    uint256 public maxSupply = 1500;
    uint256 public maxMintAmount = 20;
    uint256 public nftPerAddressLimit = 30;
    bool public paused = true;
    bool public onlyWhitelisted = true;
    mapping(address => uint256) public whitelistedAddresses;

    constructor(
        string memory _initBaseURI
    ) ERC721("Boop and Frens Pre-sale", "BFPS") {
        setBaseURI(_initBaseURI);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "max mint amount per session exceeded"
        );
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            if (onlyWhitelisted == true) {
                require(isWhitelisted(msg.sender), "user is not whitelisted");
                uint256 userLimit = whitelistedAddresses[msg.sender];
                require(
                    userLimit >= _mintAmount,
                    "max NFT per address exceeded"
                );
            }
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            whitelistedAddresses[msg.sender]--;
            _safeMint(msg.sender, supply + i);
        }
    }

    function isWhitelisted(address _user) public view returns (bool) {
        return whitelistedAddresses[_user] > 0;
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

        return _baseURI();
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxSupply(uint256 _newmaxSupply) public onlyOwner {
        maxSupply = _newmaxSupply;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            whitelistedAddresses[_users[i]] = 1;
        }
    }

     function SetWhitelistUserLimit(address _users, uint256 limit) public onlyOwner {
            whitelistedAddresses[_users] = limit;
    }

    function withdraw() public payable onlyOwner {
        
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        
    }
}