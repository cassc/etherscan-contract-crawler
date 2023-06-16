// SPDX-License-Identifier: MIT
// Recommended Royalty Fee 2,5 %

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@1001-digital/erc721-extensions/contracts/RandomlyAssigned.sol";


contract lilshidz is 
    ERC721, 
    Ownable, 
    ReentrancyGuard, 
    RandomlyAssigned,
    PaymentSplitter 
{
    using Strings for uint256;

    address proxyRegistryAddress;
    string public baseURI; 
    string public baseExtension = ".json";
    bool public paused = false;

    uint256 private constant maxMintsPerAddress = 10;
    uint256 public price = 0; // free to mint  

    uint256[] private _teamShares = [50, 50]; // 2 PEOPLE IN THE TEAM
    address[] private _team = [
        0xE8F7Ba5ac1f4C564B0cfEA13dF78828e020E3058, // 50% Account 1
        0xDC93eF183cc57D877c954514093f984e6ba05a88 // 50% Account 2
    ];

    constructor(string memory uri, address _proxyRegistryAddress,uint256 maxSupply, uint256 startFrom)
        ERC721("lilshidz", "SHID")
        PaymentSplitter(_team, _teamShares) 
        ReentrancyGuard()
        RandomlyAssigned(maxSupply,startFrom)
    {
        proxyRegistryAddress = _proxyRegistryAddress;
        setBaseURI(uri);
    }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function mint(uint256 amount) 
    external ensureAvailabilityFor(amount)
    payable
    {
        require(!paused, "lilshidz: Contract is paused");
        require(amount > 0, "lilshidz: Amount needs to be greater than 0");
        require(msg.sender == tx.origin, "lilshidz: Can't mint through another contract");
        require(amount <= maxMintsPerAddress, "lilshidz: Can't mint more than 10 tokens");
        require(
            price * amount <= msg.value,
            "lilshidz: Not enough ethers sent"
        );
        
        for (uint256 index = 0; index < amount; index++) {
            mintInternal();
        }
    }

    function mintInternal() internal nonReentrant {
        _safeMint(msg.sender, nextToken());
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

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}



/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy {}

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}