// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 20;
    uint256[] public tiers = [1500, 5000, 10000];
    uint256[] public prices = [0, 0.003 ether, 0.007 ether];
    uint256[] public maxMints = [1, 7, 15];
    bool public paused = false;
    bool public revealed = false;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    struct CurrentData {
        uint256 currStage;
        uint256 currPrice;
        uint256 currMaxMint;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        CurrentData memory currData = getCurrentData();
        uint256 currBalance = balanceOf(msg.sender);
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            if (currData.currStage == 0) {
            require(
                _mintAmount <= currData.currMaxMint,
                "max mint amount per session exceeded"
            );
        } else {
            require(
                _mintAmount + currBalance <= currData.currMaxMint,
                "max mint amount per Address exceeded"
            );
        }
            require(
                msg.value >= currData.currPrice * _mintAmount,
                "insufficient funds"
            );
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function _extract(address receiver) internal {
        payable(receiver).transfer(address(this).balance);
    }

    function OwnerWalletIndex(address _owner)
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

    function getCurrentStage() public view returns (uint256) {
        uint256 currSupply = totalSupply();
        for (uint256 i; i < tiers.length; i++) {
            uint256 currTier = tiers[i];
            if (currTier > currSupply) {
                return i;
            }
        }
        return 150000;
    }

    function getCurrentPrice() public view returns (uint256) {
        uint256 currStage = getCurrentStage();
        uint256 currPrice = prices[currStage];
        return currPrice;
    }

    function getCurrentMaxMint() public view returns (uint256) {
        uint256 currStage = getCurrentStage();
        uint256 currMaxMint = maxMints[currStage];
        return currMaxMint;
    }

    function getCurrentData() public view returns (CurrentData memory) {
        uint256 currStage = getCurrentStage();
        uint256 currPrice = prices[currStage];
        uint256 currMaxMint = maxMints[currStage];
        CurrentData memory currData = CurrentData(
            currStage,
            currPrice,
            currMaxMint
        );
        return currData;
    }

    function getTxCost(uint256 _amount) public view returns (uint256) {
        uint256 currStage = getCurrentStage();
        uint256 predictedCurrentTier = tiers[currStage];
        uint256 predictedCurrentPrice = prices[currStage];
        uint256 newSupply = totalSupply() + _amount;
        if (newSupply > predictedCurrentTier) {
            uint256 newStage = currStage + 1;
            uint256 newPrice = prices[newStage];
            uint256 totalAtCurrent = tiers[currStage] - totalSupply();
            uint256 totalAtNew = _amount - totalAtCurrent;
            uint256 priceForCurr = predictedCurrentPrice * totalAtCurrent;
            uint256 priceForNew = newPrice * totalAtNew;
            uint256 totalPrice = priceForCurr + priceForNew;
            return totalPrice;
        } else {
            uint256 totalPrice = predictedCurrentPrice * _amount;
            return totalPrice;
        }
    }

    // onlyOwner Functions

    function setTiers(uint256[] calldata newTiers) public onlyOwner {
        delete tiers;
        tiers = newTiers;
    }

    function setPrices(uint256[] calldata newPrices) public onlyOwner {
        delete prices;
        prices = newPrices;
    }

    function setMaxMints(uint256[] calldata _maxMints) public onlyOwner {
        delete maxMints;
        maxMints = _maxMints;
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

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        _extract(msg.sender);
    }
}