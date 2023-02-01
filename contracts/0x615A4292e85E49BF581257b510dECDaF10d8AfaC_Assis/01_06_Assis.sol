// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Assis is ERC721A, Ownable {
    using Strings for uint256;
    string baseURI;
    string revealUri;
    string public baseExtension = ".json";
    uint256 public cost = 0.01 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 500;
    uint256 public daysBeforeReveal;
    bool public paused = true;
    uint256 lastRun;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initRevealURI,
        uint256 _daysBeforeReveal
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setRevealURI(_initRevealURI);
        setDaysBeforeReveal(_daysBeforeReveal);
    }

    // Events
    event Mint(address indexed to, uint256 indexed quantity);
    event RevealDayIsToday();

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //external
    function count() external {
        require(block.timestamp - lastRun > 1 days, "Need to wait 1 day");
        if (daysBeforeReveal != 1) {
            daysBeforeReveal = daysBeforeReveal - 1;
        } else if (daysBeforeReveal == 1) {
            daysBeforeReveal = 0;
            emit RevealDayIsToday();
        }
        lastRun = block.timestamp;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused, "Minting is paused");
        require(_mintAmount > 0, "Mint amount should be bigger than 0");
        require(_mintAmount <= maxMintAmount, "Too big nft amount requested");
        require(
            supply + _mintAmount <= maxSupply,
            "Requested nft amount is bigger than left to reach max supply"
        );

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount);
        }

        _safeMint(msg.sender, _mintAmount);

        emit Mint(msg.sender, _mintAmount);

        supply = totalSupply();
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

        // if today is a reveal day
        if (daysBeforeReveal == 0) {
            return
                string(
                    abi.encodePacked(
                        revealUri,
                        tokenId.toString(),
                        baseExtension
                    )
                );
        }

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

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setRevealURI(string memory _newRevealURI) public onlyOwner {
        revealUri = _newRevealURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setDaysBeforeReveal(uint256 _daysBeforeReveal) public onlyOwner {
        daysBeforeReveal = _daysBeforeReveal;
    }

    function withdraw(uint256 _amount) public payable onlyOwner {
        payable(msg.sender).transfer(_amount);
    }
}