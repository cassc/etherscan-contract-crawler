// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract HyperMintERC1155 is ERC1155, Ownable, ERC1155Burnable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    string public contractURI;

    uint256[] public prices;
    uint256[] public supplies;
    uint256[] public totalSupplies;
    uint256[] public maxPerAddresses;

    bool public allowBuy;
    uint256 public presaleDate;
    uint256 public publicSaleDate;
    uint256 public saleCloseDate;

    address customerAddress;
    address presaleAddress;
    address purchaseTokenAddress;
    address primaryRoyaltyReceiver;
    address secondaryRoyaltyReceiver;
    uint96 primaryRoyaltyFee;
    uint96 secondaryRoyaltyFee;

    struct TokenInfo {
        uint256[] prices;
        uint256[] supplies;
        uint256[] totalSupplies;
        uint256[] maxPerAddresses;
    }

    constructor (string memory _name, string memory _symbol, string memory _contractMetadataURI, string memory _tokenMetadataURI, bool _allowBuy,
        address _customerAddress, address _presaleAddress) ERC1155("") {
        name = _name;
        symbol = _symbol;
        allowBuy = _allowBuy;
        customerAddress = _customerAddress;
        presaleAddress = _presaleAddress;
        _setURI(_tokenMetadataURI);
        contractURI = _contractMetadataURI;
    }

    function setPurchaseToken(address _purchaseToken) public onlyOwner{
        purchaseTokenAddress = _purchaseToken;
    }

    function getTokenInfo() public view returns (TokenInfo memory){
        return TokenInfo(
            prices, supplies, totalSupplies, maxPerAddresses
        );
    }

    function totalSupply(uint256 tokenId) public view returns (uint256){
        return totalSupplies[tokenId];
    }

    function setNameAndSymbol(string memory _name, string memory _symbol) public onlyOwner {
        name = _name;
        symbol = _symbol;
    }

    function setMetadataURIs(string memory _contractURI, string memory _tokenURI) public onlyOwner {
        contractURI = _contractURI;
        _setURI(_tokenURI);
    }

    function setDates(uint256 _presale, uint256 _publicSale, uint256 _saleClosed) public onlyOwner {
        presaleDate = _presale;
        publicSaleDate = _publicSale;
        saleCloseDate = _saleClosed;
    }

    function setTokenData(uint256 id, uint256 _price, uint256 _supply, uint256 _maxPerAddress) public onlyOwner {
        require(supplies[id] <= _supply, "Supply too low");

        prices[id] = _price;
        totalSupplies[id] = _supply;
        maxPerAddresses[id] = _maxPerAddress;
    }

    function setCustomerAddresses(address _customerAddress, address _presaleAddress) public onlyOwner {
        customerAddress = _customerAddress;
        presaleAddress = _presaleAddress;
    }

    function setAllowBuy(bool _allowBuy) public onlyOwner {
        allowBuy = _allowBuy;
    }

    function mintBatch(address[] memory to, uint256[][] memory ids, uint256[][] memory amounts)
    public
    onlyOwner
    {
        for (uint i = 0; i < to.length; i++) {
            for (uint j = 0; j < ids[i].length; j++) {
                require(supplies[ids[i][j]] + amounts[i][j] <= totalSupplies[ids[i][j]], "Not enough supply");
                supplies[ids[i][j]] += amounts[i][j];
            }

            _mintBatch(to[i], ids[i], amounts[i], "0x");
        }
    }

    function addTokens(uint256[] memory newSupplies, uint256[] memory newPrices, uint256[] memory newMaxPerAddresses) public onlyOwner {
        require(newSupplies.length == newPrices.length, "Array length mismatch");

        for (uint i = 0; i < newSupplies.length; i++) {
            totalSupplies.push(newSupplies[i]);
            supplies.push(0);
            prices.push(newPrices[i]);
            maxPerAddresses.push(newMaxPerAddresses[i]);
        }
    }

    function _buy(uint256 id, uint256 amount) internal {
        if (saleCloseDate != 0) {
            require(block.timestamp < saleCloseDate, "Sale closed");
        }

        require(supplies[id] + amount <= totalSupplies[id], "Not enough supply");

        if (maxPerAddresses[id] != 0) {
            require(balanceOf(msg.sender, id) + amount <= maxPerAddresses[id], "Max per address limit");
        }

        supplies[id] += amount;
        _mint(msg.sender, id, amount, "0x");

        uint256 saleAmount = prices[id] * amount;
        uint256 royaltyAmount = (saleAmount * primaryRoyaltyFee) / 10000;

        if(purchaseTokenAddress == address(0)){
            require(msg.value >= saleAmount, "Insufficient value");
            payable(primaryRoyaltyReceiver).transfer(royaltyAmount);
            payable(customerAddress).transfer(saleAmount - royaltyAmount);
        } else{
            IERC20 token = IERC20(purchaseTokenAddress);
            token.safeTransferFrom(msg.sender, primaryRoyaltyReceiver, royaltyAmount);
            token.safeTransferFrom(msg.sender, customerAddress, saleAmount - royaltyAmount);
        }
    }

    function buy(uint256 id, uint256 amount) nonReentrant external payable {
        require(allowBuy, "Buy disabled");
        require(block.timestamp >= publicSaleDate, "Public sale closed");

        _buy(id, amount);
    }

    function buyPresale(uint256 id, uint256 amount, uint8 _v, bytes32 _r, bytes32 _s) nonReentrant external payable {
        require(allowBuy, "Buy disabled");
        require(block.timestamp >= presaleDate, "Presale closed");
        require(isMessageSignedByPresaleAddress(msg.sender, _v, _r, _s), "Not authorised");

        _buy(id, amount);
    }

    function isMessageSignedByPresaleAddress(address _address, uint8 _v, bytes32 _r, bytes32 _s) view internal returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(address(this), _address));
        return presaleAddress == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), _v, _r, _s);
    }

    function transferContractOwnership() public {
        require(msg.sender == customerAddress, "Not authorised");
        _transferOwnership(customerAddress);
    }

    function setRoyalty(address primaryReceiver, address secondaryReceiver, uint96 primaryFee, uint96 secondaryFee) public onlyOwner {
        primaryRoyaltyReceiver = primaryReceiver;
        secondaryRoyaltyReceiver = secondaryReceiver;
        primaryRoyaltyFee = primaryFee;
        secondaryRoyaltyFee = secondaryFee;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256) {
        uint256 royaltyAmount = (_salePrice * secondaryRoyaltyFee) / 10000;
        return (secondaryRoyaltyReceiver, royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }
}