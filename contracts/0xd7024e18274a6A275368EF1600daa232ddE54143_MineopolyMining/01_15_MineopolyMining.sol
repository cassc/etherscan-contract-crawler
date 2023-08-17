// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MineopolyMining is ERC721, Ownable {
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;

    using Counters for Counters.Counter;
    Counters.Counter public  _tokenIds;
   
    bool public RevealedActive = true;

    address adminWallet = 0x356C1079CBC1bA83BCE70798207Ab3E1B476E183;

    IERC20 public USDToken;
    IERC721 public MemberNFT;

    uint256 public currentTranche = 1;
    uint256 public maxTranche = 5;
    uint256 public maxTrancheSupply = 2250;
    uint256 public trancheDuration = 21 days;
    uint256 public trancheStartTimestamp;
    
    uint256[] public Price = [420e6, 440e6, 460e6, 480e6, 500e6];

    constructor(string memory _BaseURI)
        ERC721("Mineopoly Mining", "MPLY")
    {
        USDToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        MemberNFT = IERC721(0xe8ce4D45e8876aeba2e6d0Dff96a56f1C4c181eF);
        setURIBase(_BaseURI);
        trancheStartTimestamp = block.timestamp;
    }

    function mintNFT(uint256 amount) public {
        require( MemberNFT.balanceOf(msg.sender) >= 1, "You arent member");
        require( block.timestamp <= trancheStartTimestamp + trancheDuration, "Tranche is closed");
        require( USDToken.transferFrom(msg.sender, adminWallet, Price[currentTranche-1] * amount), "Failed to transfer Admin fee" );
        require( _tokenIds._value + amount <= currentTranche * maxTrancheSupply, "Minting exceeds tranche limit");

        for (uint256 i = 0; i < amount; i++) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        }
    }

    function CrossmintNFT(address _to, uint256 amount) public payable {
        require( MemberNFT.balanceOf(_to) >= 1, "You arent member");
        require( block.timestamp <= trancheStartTimestamp + trancheDuration, "Tranche is closed");
        require( _tokenIds._value + amount <= currentTranche * maxTrancheSupply, "Minting exceeds tranche limit");
        require( USDToken.transferFrom(msg.sender, adminWallet, Price[currentTranche-1] * amount), "Failed to transfer Admin fee" );

        for (uint256 i = 0; i < amount; i++) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(_to, newItemId);
        }
    }

    function adminMint(address _to, uint256 amount) public onlyOwner {
        for (uint256 i = 0; i < amount; i++) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(_to, newItemId);
        }
    }

    function advanceTranche() external onlyOwner {
        require(block.timestamp >= trancheStartTimestamp + trancheDuration, "Tranche is still open");
        require( currentTranche < maxTranche, "All tranches have been completed");
        _tokenIds._value = currentTranche * 2250;
        currentTranche++;
        trancheStartTimestamp = block.timestamp;
    }

    function advanceTranche1() external onlyOwner {
        require(currentTranche == 1);
        _tokenIds._value = currentTranche * 2250;
        currentTranche++;
        trancheStartTimestamp = block.timestamp;
    }

    function updatePrice(uint256 index, uint256 newPrice) public onlyOwner {
        require(index < Price.length, "Invalid index");
        Price[index] = newPrice;
    }

    function updateTrancheDuration(uint256 newDuration) public onlyOwner {
        trancheDuration = newDuration;
    }

    function timeUntilNextTranche() public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 elapsedTime = currentTime - trancheStartTimestamp;

        if (elapsedTime >= trancheDuration) {
            return 0;
        } else {
            return trancheDuration - elapsedTime;
        }
    
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "");
        if (RevealedActive == false) {
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

    function setURIBase(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setAdmin (address _newadminWallet) public onlyOwner {
        adminWallet = _newadminWallet;
    }

     function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function Reveal() public onlyOwner {
        RevealedActive = true;
    }
}