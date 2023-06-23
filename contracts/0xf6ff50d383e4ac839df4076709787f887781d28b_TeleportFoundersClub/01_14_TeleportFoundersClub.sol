// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";

contract TeleportFoundersClub is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Address for address;

    uint256 public price;
    uint256 public immutable maxSupply;
    uint256 public supplyCap;
    bool public mintingEnabled;
    bool public whitelistEnabled = true;
    uint256 public buyLimit;
    uint256 public walletLimit;
    mapping(address => bool) public whitelist;

    string private _baseURIPrefix;
    address payable immutable dev;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _supplyCap,
        uint256 _price,
        uint256 _buyLimit,
        uint256 _walletLimit,
        string memory _uri,
        address payable _dev
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        supplyCap = _supplyCap;
        price = _price;
        buyLimit = _buyLimit;
        walletLimit = _walletLimit;
        _baseURIPrefix = _uri;
        dev = _dev;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function setBaseURI(string memory newUri) external onlyOwner {
        _baseURIPrefix = newUri;
    }

    function toggleWhitelist() external onlyOwner {
        whitelistEnabled = !whitelistEnabled;
    }

    function setWhitelist(address[] calldata newAddresses) external onlyOwner {
        for (uint256 i = 0; i < newAddresses.length; i++)
            whitelist[newAddresses[i]] = true;
    }

    function removeWhitelist(address[] calldata currentAddresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < currentAddresses.length; i++)
            delete whitelist[currentAddresses[i]];
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setBuyLimit(uint256 newBuyLimit) external onlyOwner {
        buyLimit = newBuyLimit;
    }

    function setWalletLimit(uint256 newWalletLimit) external onlyOwner {
        walletLimit = newWalletLimit;
    }

    function setSupplyCap(uint256 newSupplyCap) external onlyOwner {
        supplyCap = newSupplyCap;
    }

    function toggleMinting() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function mintNFTs(uint256 quantity) external payable {
        require(
            totalSupply().add(quantity) <= maxSupply,
            "Max supply exceeded"
        );
        require(
            totalSupply().add(quantity) <= supplyCap,
            "Supply cap exceeded"
        );
        if (_msgSender() != owner()) {
            require(mintingEnabled, "Minting has not been enabled");

            if (whitelistEnabled)
                require(whitelist[_msgSender()], "Not whitelisted");

            require(quantity <= buyLimit, "Buy limit exceeded");
            require(
                balanceOf(_msgSender()).add(quantity) <= walletLimit,
                "Wallet limit exceeded"
            );
        }
        require(quantity > 0, "Invalid quantity");
        require(price.mul(quantity) == msg.value, "Incorrect ETH value");
        require(!_msgSender().isContract(), "Contracts are not allowed");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(_msgSender(), totalSupply().add(1));
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 devFee = balance.div(100);
        uint256 amount = balance.sub(devFee);

        dev.transfer(devFee);
        payable(owner()).transfer(amount);
    }
}