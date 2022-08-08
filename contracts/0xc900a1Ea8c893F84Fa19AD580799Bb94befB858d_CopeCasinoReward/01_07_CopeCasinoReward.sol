// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CopeCasinoReward is ERC721A, Ownable, ReentrancyGuard {
    bool hopeSpinLive = false;
    bool copeSpinLive = false;

    uint256 maxTotalSupply = 500;
    string public baseURI;

    address public copeTokenContractAddress;
    address public hopeTokenContractAddress;

    uint256 public hopeWinChanceFix = 1;
    uint256 public hopeWinChance = 10;

    uint256 public hopeLoseChanceFix = 1;
    uint256 public hopeLoseChance = 2;

    uint256 public copeWinChanceFix = 1;
    uint256 public copeWinChance = 5;

    uint256 public copeLoseChanceFix = 1;
    uint256 public copeLoseChance = 3;

    uint256 public copePrice = 420000000000000000000;
    uint256 public hopePrice = 420000000000000000000;

    constructor(
        string memory name,
        string memory symbol,
        address _copeTokenContractAddress,
        address _hopeTokenContractAddress
    ) ERC721A(name, symbol) {
        copeTokenContractAddress = _copeTokenContractAddress;
        hopeTokenContractAddress = _hopeTokenContractAddress;
    }

    function rollWithHope() external nonReentrant {
        require(hopeSpinLive, 'Not live');
        require(totalSupply() + 1 <= maxTotalSupply, "Exceeds total supply");
        require(IERC20(hopeTokenContractAddress).allowance(_msgSender(), address(this)) >= hopePrice, "Not enough $HOPE allowance");

        bool rolledNft = false;
        if ((uint256(keccak256(abi.encodePacked(
                tx.origin,
                blockhash(block.number - 1),
                block.timestamp,
                _msgSender(),
                totalSupply()
            ))) & 0xFFFF) * hopeWinChanceFix % hopeWinChance == 0) {
            rolledNft = true;
            _safeMint(_msgSender(), 1);
        }

        if (rolledNft || (uint256(keccak256(abi.encodePacked(
                tx.origin,
                blockhash(block.number - 1),
                block.timestamp,
                _msgSender(),
                totalSupply()
            ))) & 0xFFFF) * hopeLoseChanceFix % hopeLoseChance == 0) {
            IERC20(hopeTokenContractAddress).transferFrom(_msgSender(), address(this), hopePrice);
        }
    }

    function rollWithCope() external nonReentrant {
        require(copeSpinLive, 'Not live');
        require(totalSupply() + 1 <= maxTotalSupply, "Exceeds total supply");
        require(IERC20(copeTokenContractAddress).allowance(_msgSender(), address(this)) >= copePrice, "Not enough $COPE allowance");

        bool rolledNft = false;
        if ((uint256(keccak256(abi.encodePacked(
                tx.origin,
                blockhash(block.number - 1),
                block.timestamp,
                _msgSender(),
                totalSupply()
            ))) & 0xFFFF) * copeWinChanceFix % copeWinChance == 0) {
            rolledNft = true;
            _safeMint(_msgSender(), 1);
        }

        if (rolledNft || (uint256(keccak256(abi.encodePacked(
                tx.origin,
                blockhash(block.number - 1),
                block.timestamp,
                _msgSender(),
                totalSupply()
            ))) & 0xFFFF) * copeLoseChanceFix % copeLoseChance == 0) {
            IERC20(copeTokenContractAddress).transferFrom(_msgSender(), address(this), copePrice);
        }
    }

    function mintPrivate(address _receiver, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= maxTotalSupply, "Exceeds total supply");
        _safeMint(_receiver, _amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setHopeLoseChance(uint256 _chance) external onlyOwner {
        hopeLoseChance = _chance;
    }

    function setHopeWinChance(uint256 _chance) external onlyOwner {
        hopeWinChance = _chance;
    }

    function setCopeLoseChance(uint256 _chance) external onlyOwner {
        copeLoseChance = _chance;
    }

    function setCopeWinChance(uint256 _chance) external onlyOwner {
        copeWinChance = _chance;
    }

    function setHopeLoseChanceFix(uint256 _chanceFix) external onlyOwner {
        hopeLoseChanceFix = _chanceFix;
    }

    function setHopeWinChanceFix(uint256 _chanceFix) external onlyOwner {
        hopeWinChanceFix = _chanceFix;
    }

    function setCopeLoseChanceFix(uint256 _chanceFix) external onlyOwner {
        copeLoseChanceFix = _chanceFix;
    }

    function setCopeWinChanceFix(uint256 _chanceFix) external onlyOwner {
        copeWinChanceFix = _chanceFix;
    }

    function setHopePrice(uint256 _price) external onlyOwner {
        hopePrice = _price;
    }

    function setCopePrice(uint256 _price) external onlyOwner {
        copePrice = _price;
    }

    function setHopeSpinLive(bool _live) external onlyOwner {
        hopeSpinLive = _live;
    }

    function setCopeSpinLive(bool _live) external onlyOwner {
        copeSpinLive = _live;
    }

    function setMaxTotalSupply(uint256 _supply) external onlyOwner {
        maxTotalSupply = _supply;
    }
}