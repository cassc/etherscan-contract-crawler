// SPDX-License-Identifier: MIT
/*
 ___       __   ________  _____ ______   _______   ________           ________  ________      _____ ______       ___    ___ ________  _________  _______   ________      ___    ___ 
|\  \     |\  \|\   __  \|\   _ \  _   \|\  ___ \ |\   ___  \        |\   __  \|\  _____\    |\   _ \  _   \    |\  \  /  /|\   ____\|\___   ___\\  ___ \ |\   __  \    |\  \  /  /|
\ \  \    \ \  \ \  \|\  \ \  \\\__\ \  \ \   __/|\ \  \\ \  \       \ \  \|\  \ \  \__/     \ \  \\\__\ \  \   \ \  \/  / | \  \___|\|___ \  \_\ \   __/|\ \  \|\  \   \ \  \/  / /
 \ \  \  __\ \  \ \  \\\  \ \  \\|__| \  \ \  \_|/_\ \  \\ \  \       \ \  \\\  \ \   __\     \ \  \\|__| \  \   \ \    / / \ \_____  \   \ \  \ \ \  \_|/_\ \   _  _\   \ \    / / 
  \ \  \|\__\_\  \ \  \\\  \ \  \    \ \  \ \  \_|\ \ \  \\ \  \       \ \  \\\  \ \  \_|      \ \  \    \ \  \   \/  /  /   \|____|\  \   \ \  \ \ \  \_|\ \ \  \\  \|   \/  /  /  
   \ \____________\ \_______\ \__\    \ \__\ \_______\ \__\\ \__\       \ \_______\ \__\        \ \__\    \ \__\__/  / /       ____\_\  \   \ \__\ \ \_______\ \__\\ _\ __/  / /    
    \|____________|\|_______|\|__|     \|__|\|_______|\|__| \|__|        \|_______|\|__|         \|__|     \|__|\___/ /       |\_________\   \|__|  \|_______|\|__|\|__|\___/ /                                                                                                             \|___|/        \|_________|                             \|___|/                                                                                                                                                                                      
 */

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity >=0.8.0 < 0.9.0;

/// @title  Women Of Mystery Writer Pass Smart Contract
/// @author
contract WomWriterPass is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost;
    uint256 public maxMintAmount;
    bool public isPaused = false;

    // tracks number of mints each mintTo address has
    mapping(address => uint256) private _userNumOfMints;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _cost,
        uint256 _maxMintAmount,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        cost = _cost;
        maxMintAmount = _maxMintAmount;
        setBaseURI(_initBaseURI);
    }

    /// internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mintTo(address recipient, uint256 _mintAmount) public payable nonReentrant {
        address sender = msg.sender;
        uint256 supply = totalSupply();

        require(_mintAmount > 0, "You need to mint at least 1 NFT");

        if (sender != owner()) {
            require(_mintAmount <= maxMintAmount, "Max mint amount exceeded");
            require(_mintAmount <= maxMintAmount - _userNumOfMints[recipient], "Insufficient Mints Left for Recipient");
            require(!isPaused, "Error: Minting has been stopped");
            require(msg.value >= cost * _mintAmount, "Not enough funds provided");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(recipient, supply + i);
        }
        
        _userNumOfMints[recipient] += _mintAmount;

    }


    function userNumOfMints(address addr) public view returns (uint256) {
        return _userNumOfMints[addr];
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
            "URI query for nonexistent token"
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

    // Only Owner Functions
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
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

    function setIsPaused(bool _state) public onlyOwner {
        isPaused = _state;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}