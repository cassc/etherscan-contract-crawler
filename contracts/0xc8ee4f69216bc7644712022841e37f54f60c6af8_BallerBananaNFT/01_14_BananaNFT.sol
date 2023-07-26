import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "hardhat/console.sol";

/**
 *Submitted for verification at Etherscan.io on 2022-01-14
 */

// SPDX-License-Identifier: MIT

// Amended by Laurence Creates(Laurence#0001)

pragma solidity ^0.8.0;

contract BallerBananaNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";

    uint256 public cost = 0.06 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 3;

    address payoutAddress = 0xE854CCCb01E68a986023a1839179469Ca33f23CC;
    uint256 public currentRoundInndex = 0;
    uint256[] public roundLimits = [400, 2600, 3000, 3500];

    bool public locked = true;
    uint256 public revealTokenId = 0;

    mapping(address => uint256) public whitelistedUsers;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //public
    function mint(uint256 _mintAmount) public payable {
        require(!locked, "Contract is locked");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "MintAmount must be above 0");
        require(
            _mintAmount <= maxMintAmount,
            "MintAmount must be below or equal to maxMintAmount"
        );
        require(
            supply + _mintAmount <= maxSupply,
            "MintAmount is more then the MaxSupply"
        );

        if (msg.sender != owner()) {
            if (currentRoundInndex == 0) {
                require(
                    supply + _mintAmount <= roundLimits[currentRoundInndex],
                    "MintAmount must be less then preSale supply"
                );
                require(
                    whitelistedUsers[msg.sender] > 0,
                    "User is not whitelisted"
                );
                require(
                    whitelistedUsers[msg.sender] >= _mintAmount,
                    "Whitelisted user mint amount exceed"
                );
            } else if (currentRoundInndex < roundLimits.length) {
                require(
                    supply + _mintAmount <= roundLimits[currentRoundInndex],
                    "MintAmount must be less then current round supply"
                );
            } else {
                require(
                    supply + _mintAmount <= maxSupply,
                    "MintAmount must be less then total supply"
                );
            }
            require(msg.value >= cost * _mintAmount, "Not enough ETH");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            if (whitelistedUsers[msg.sender] > 0) {
                whitelistedUsers[msg.sender] -= 1;
            }
            _safeMint(msg.sender, supply + i);
        }
        if (supply + _mintAmount >= roundLimits[currentRoundInndex]) {
            currentRoundInndex += 1;
            locked = true;
        }
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

        if (tokenId >= revealTokenId) {
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

    //only owner

    /* Generate NFTS in mass for giveaways. */
    function mintForGiveaway(address _to, uint256 _mintAmount)
        public
        onlyOwner
    {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply);
        if (msg.sender == owner()) {
            for (uint256 i = 1; i <= _mintAmount; i++) {
                _safeMint(_to, supply + i);
            }
        }
    }

    function addUsersToWhitelist(address[] calldata _addresses)
        public
        onlyOwner
    {
        require(_addresses.length > 0, "No white list address given");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistedUsers[_addresses[i]] = 1;
        }
    }

    function setRevealTokenId(uint256 _revealTokenId) public onlyOwner {
        revealTokenId = _revealTokenId;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setCurrentRound(uint256 _currentRoundIndex) public onlyOwner {
        currentRoundInndex = _currentRoundIndex;
    }

    function setRoundLimit(uint256 _roundLimit, uint256 _roundIndex)
        public
        onlyOwner
    {
        require(
            _roundIndex < roundLimits.length,
            "Round index should < rounds size"
        );
        roundLimits[_roundIndex] = _roundLimit;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
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

    function Lock() public onlyOwner {
        locked = true;
    }

    function Unlock() public onlyOwner {
        locked = false;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(payoutAddress).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}