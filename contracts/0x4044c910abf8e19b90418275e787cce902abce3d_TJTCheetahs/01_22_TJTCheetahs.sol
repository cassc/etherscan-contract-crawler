//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721Tradable.sol";

contract TJTCheetahs is ERC721Tradable {
    using SafeMath for uint256;
    using MerkleProof for bytes32[];

    bytes32 public root;
    uint32 public nextId = 1;
    uint32 public soldCounter = 0;
    uint8 public currentSaleMode = 0;
    uint32 public WL_SUPPLY_AVAILABLE = 2600;
    uint32 public PUBLIC_SUPPLY_AVAILABLE = 5165;

    mapping(address => uint32) public wlMints;

    uint32 public constant MAX_SUPPLY = 7765;
    uint256 public constant WL_PRICE = 0.2 ether;

    string internal theBaseUri = "";

    constructor(
        address _proxyRegistryAddress,
        bytes32 _root,
        string memory _theBaseUri
    ) ERC721Tradable("TJTCheetahs", "TJTC", _proxyRegistryAddress) {
        root = _root;
        theBaseUri = _theBaseUri;
        _pause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return theBaseUri;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        theBaseUri = _baseTokenURI;
    }

    function setSaleMode(uint8 _saleMode) public onlyOwner {
        if (currentSaleMode == _saleMode) {
            if (paused()) {
                _unpause();
            } else {
                _pause();
            }
        } else {
            if (currentSaleMode == 0) {
                PUBLIC_SUPPLY_AVAILABLE += WL_SUPPLY_AVAILABLE;
                WL_SUPPLY_AVAILABLE = 0;
            }
            if (_saleMode == 4) {
                PUBLIC_SUPPLY_AVAILABLE = 0;
                WL_SUPPLY_AVAILABLE = 0;
            }
            currentSaleMode = _saleMode;
        }
    }

    function buy(bytes32[] memory _proof, uint32 _quantity)
        public
        payable
        whenNotPaused
    {
        _buyTo(msg.sender, _proof, _quantity);
    }

    function _buyTo(
        address _to,
        bytes32[] memory _proof,
        uint32 _quantity
    ) public payable whenNotPaused {
        require(_to != address(0), "A");
        require(_quantity > 0 && _quantity <= 2, "Q");
        require(soldCounter + _quantity <= MAX_SUPPLY, "S");
        require(currentSaleMode != 4, "Z");

        bool isWhitelisted = _proof.verify(
            root,
            keccak256(abi.encodePacked(msg.sender))
        );

        uint256 totalPrice = (WL_PRICE + 0.03 ether) * _quantity;

        if (isWhitelisted) {
            totalPrice = WL_PRICE * _quantity;
        } else if (currentSaleMode == 2) {
            totalPrice = (WL_PRICE + 0.1 ether) * _quantity;
        }

        require(msg.value >= totalPrice, "I");

        uint32 quantity = _quantity;

        if (currentSaleMode == 0 && isWhitelisted) {
            uint32 wlRemainingForSender = 2 - wlMints[_to];
            if (wlRemainingForSender >= quantity) {
                mintWl(_to, quantity);
                return;
            } else if (wlRemainingForSender > 0) {
                mintWl(_to, wlRemainingForSender);
                quantity = quantity - wlRemainingForSender;
            }
        }

        if (currentSaleMode == 3) {
            quantity = MAX_SUPPLY - soldCounter < quantity * 2
                ? MAX_SUPPLY - soldCounter
                : quantity * 2;
        }

        mintNormal(msg.sender, quantity);
    }

    function mintNormal(address _to, uint32 _quantity) private {
        require(PUBLIC_SUPPLY_AVAILABLE - _quantity >= 0, "P");

        for (uint32 i = 0; i < _quantity; i++) {
            _safeMint(_to, nextId);
            nextId++;
        }

        soldCounter += _quantity;
        PUBLIC_SUPPLY_AVAILABLE -= _quantity;
    }

    function mintWl(address _to, uint32 _quantity) private {
        require(WL_SUPPLY_AVAILABLE - _quantity >= 0, "W");
        for (uint32 i = 0; i < _quantity; i++) {
            _safeMint(_to, nextId);
            nextId++;
        }
        soldCounter += _quantity;
        wlMints[_to] += _quantity;
        WL_SUPPLY_AVAILABLE -= _quantity;
    }

    function mintGiveaways() public onlyOwner {
        for (uint32 i = 0; i < 12; i++) {
            _safeMint(msg.sender, nextId);
            nextId++;
        }
        soldCounter += 12;
    }

    function withdrawTo() public onlyOwner {
        // verify withdrawal address is set
        require(msg.sender != address(0), "A");

        // ETH value of contract
        uint256 value = address(this).balance;

        // verify sale balance is positive (non-zero)
        require(value > 0, "ZB");

        // send the sale balance minus the developer fee
        // to the withdrawer
        payable(msg.sender).transfer(value);
    }
}