// SPDX-License-Identifier: MIT
/*
███████╗██████╗░███████╗███╗░░██╗███████╗██╗░░░██╗  ███████╗░█████╗░██╗░░██╗  ░█████╗░██╗░░░░░██╗░░░██╗██████╗░
██╔════╝██╔══██╗██╔════╝████╗░██║╚════██║╚██╗░██╔╝  ██╔════╝██╔══██╗╚██╗██╔╝  ██╔══██╗██║░░░░░██║░░░██║██╔══██╗
█████╗░░██████╔╝█████╗░░██╔██╗██║░░███╔═╝░╚████╔╝░  █████╗░░██║░░██║░╚███╔╝░  ██║░░╚═╝██║░░░░░██║░░░██║██████╦╝
██╔══╝░░██╔══██╗██╔══╝░░██║╚████║██╔══╝░░░░╚██╔╝░░  ██╔══╝░░██║░░██║░██╔██╗░  ██║░░██╗██║░░░░░██║░░░██║██╔══██╗
██║░░░░░██║░░██║███████╗██║░╚███║███████╗░░░██║░░░  ██║░░░░░╚█████╔╝██╔╝╚██╗  ╚█████╔╝███████╗╚██████╔╝██████╦╝
╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚══╝╚══════╝░░░╚═╝░░░  ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝  ░╚════╝░╚══════╝░╚═════╝░╚═════╝░
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

pragma solidity >=0.8.0 <0.9.0;

/// @title Frenzy Fox Club Smart Contract
/// @author
contract FrenzyFoxClub is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmount;
    bool public isPaused = false;
    // we want nft revealed on Mint so we set it to true
    bool public isRevealed = true;

    mapping(address => uint256) private _userNumOfMints;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmount,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {

        cost = _cost;
        maxSupply = _maxSupply;
        maxMintAmount = _maxMintAmount;

        setBaseURI(_initBaseURI);
    }

    /// internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable nonReentrant {
        address sender = msg.sender;

        require(_mintAmount <= maxMintAmount - _userNumOfMints[sender], "Insufficient Mints Left");

        uint256 supply = totalSupply();
        require(!isPaused, "Error: Minting is pause");
        require(_mintAmount > 0, "You need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmount, "Max mint amount exceeded");
        require(supply + _mintAmount <= maxSupply, "Request exceeded availble mints");

        if (sender != owner()) {
            require(msg.value >= cost * _mintAmount, "Not enough funds provided");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(sender, supply + i);
        }
        
        _userNumOfMints[sender] += _mintAmount;

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