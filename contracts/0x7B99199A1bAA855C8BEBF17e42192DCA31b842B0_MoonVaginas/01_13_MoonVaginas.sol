// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MoonVaginas is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;

    address proxyRegistryAddress;

    //69 + 10 reserved tokens
    uint256 public teamTokens = 79;
    uint256 public teamTokensMinted = 0;

    uint256 public maxSupply = 6969;

    string public baseURI;
    string public baseExtension = ".json";

    bool public paused = false;
    bool public publicM = false;

    bool public autoEnd = true;

    uint256 public _price = 69690000000000000; // 0.06969 ETH

    Counters.Counter private _tokenIds;

    constructor(string memory uri, address _proxyRegistryAddress)
        ERC721("MoonVaginas", "MVAGI")
        ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
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

    modifier onlyAccounts() {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function togglePublicSale() public onlyOwner {
        publicM = !publicM;
    }

    function toggleAutoEnd() public onlyOwner {
        autoEnd = !autoEnd;
    }

    /// Reserve tokens for the team
    /// @dev Mints the number of tokens passed in as _amount to the _teamAddress
    /// @param _amount The number of tokens to mint
    function teamReservedTokensMint(uint256 _amount)
        external
        payable
        onlyOwner
    {
        require(_amount > 0, "MoonVaginas: zero amount");

        uint256 current = _tokenIds.current();

        require(
            teamTokens - teamTokensMinted - _amount <= maxSupply - current,
            "MoonVaginas: Max supply (team + public) exceeded"
        );

        require(
            _amount <= teamTokens - teamTokensMinted,
            "MoonVaginas: No team tokens left to mint"
        );

        for (uint256 i = 0; i < _amount; i++) {
            mintInternal();
        }

        teamTokensMinted += _amount;
    }

    function publicSaleMint(uint256 _amount) external payable onlyAccounts {
        require(publicM, "MoonVaginas: PublicSale is OFF");
        require(!paused, "MoonVaginas: Contract is paused");
        require(_amount > 0, "MoonVaginas: zero amount");

        uint256 current = _tokenIds.current();

        require(
            teamTokens - teamTokensMinted + current + _amount <= maxSupply,
            "MoonVaginas: Max supply (team + public) exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "MoonVaginas: Not enough ethers sent"
        );

        for (uint256 i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function mintInternal() internal nonReentrant {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);

        //sold out!
        if (autoEnd) {
            if (tokenId == maxSupply) {
                publicM = false;
            }
        }
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

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// Adjust the mint price
    /// @dev modifies the state of the `mintPrice` variable
    /// @notice sets the price for minting a token
    /// @param newPrice_ The new price for minting
    function adjustMintPriceInWei(uint256 newPrice_) external onlyOwner {
        _price = newPrice_;
    }
}

/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy {

}

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}