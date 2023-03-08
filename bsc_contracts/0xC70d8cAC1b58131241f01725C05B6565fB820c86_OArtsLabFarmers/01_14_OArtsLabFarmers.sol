// SPDX-License-Identifier: MIT

/**

                            +&-
                           _.-^-._    .--.
                        .-'   _   '-. |__|
                       /     |_|     \|  |
                      /               \  |
                     /|     _____     |\ |
                      |    |==|==|    |  |
  |---|---|---|---|---|    |--|--|    |  |
  |---|---|---|---|---|    |==|==|    |  |
 ^OArtsLab^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

*/

/** 
    Project: OArtsLab Farmers
    Website: www.oarts.it

    by RetroBoy (RetroBoy.dev)
*/

pragma solidity >=0.7.0 <0.9.0;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";

contract OArtsLabFarmers is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";

    uint256 public cost = 0.01 ether;
    uint256 public maxSupply = 5602;

    bool public paused = true;
    bool public revealed = true;

    address public adv; // 15%
    address public dev; // 10%

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        address payable _adv,
        address payable _dev
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        adv = _adv;
        dev = _dev;
    }

    // internal

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public

    function mint(uint256 _amount) public payable nonReentrant {
        uint256 supply = totalSupply();
        require(!paused, "Sale is paused");
        require(_amount > 0, "Invalid mint amount");
        require(supply + _amount <= maxSupply, "Max supply exceeded");
        require(msg.value >= cost * _amount, "Not enough funds");

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mintFor(address _to, uint256 _amount) public payable nonReentrant {
        uint256 supply = totalSupply();
        require(!paused, "Sale is paused");
        require(_amount > 0, "Invalid mint amount");
        require(supply + _amount <= maxSupply, "Max supply exceeded");
        require(msg.value >= cost * _amount, "Not enough funds");

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(_to, supply + i);
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

        if (revealed == false) {
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

    function airDrop(address _to, uint256 _amount) public onlyOwner {
        uint256 supply = totalSupply();
        require(_amount > 0);
        require(supply + _amount <= maxSupply);

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
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

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    // Withdraws and Wallets

    function updateAdvWallet(address _newAdv) public {
        require(owner() == msg.sender || adv == msg.sender, "Not authorized");
        adv = _newAdv;
    }

    function updateDevWallet(address _newDev) public {
        require(dev == msg.sender, "Not authorized");
        dev = _newDev;
    }

    function withdraw() external nonReentrant {
        require(
            owner() == msg.sender ||
                adv == msg.sender ||
                dev == msg.sender,
                "Not authorized"
        );
        uint256 balance = address(this).balance;
        payable(owner()).transfer((balance * 75) / 100); // 75%
        payable(adv).transfer((balance * 15) / 100); // 15%
        payable(dev).transfer((balance * 10) / 100); // 10%
    }
}