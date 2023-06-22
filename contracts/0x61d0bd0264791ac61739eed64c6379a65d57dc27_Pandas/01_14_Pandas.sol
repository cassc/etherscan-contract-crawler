// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Pandas is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    address proxyRegistryAddress;
    uint256 public constant MAXPANDAS = 3333;
    uint256 public maxPandasPurchase = 20;
    uint256 public reservedPandasCustom = 33;
    uint256 public _price = 0.01 ether;
    uint256 public tokenCounter = 0;

    string public _baseTokenURI;
    bool public isSaleActive;

    mapping (uint256 => string) private _tokenURIs;

    constructor(address _proxyRegistryAddress, string memory baseURI) ERC721("32px Pandas", "PANDAS") {
        setBaseURI(baseURI);
        isSaleActive = false;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function mintPanda(uint256 numberOfPandas) public payable {
        require(isSaleActive, "Sale is not active!");
        require(numberOfPandas >= 0 && numberOfPandas <= maxPandasPurchase,
            "You can only mint 20 Pandas at a time!");
        require(totalSupply().add(numberOfPandas) <= MAXPANDAS - reservedPandasCustom,
            "Hold up! You would buy more Pandas than available...");
        require(msg.value >= _price.mul(numberOfPandas),
            "Not enough ETH for this purchase!");

        for (uint256 i = 0; i < numberOfPandas; i++){
            //uint256 tokenNr = totalSupply();
            if (totalSupply() < MAXPANDAS - reservedPandasCustom) {
                _safeMint(msg.sender, tokenCounter+1);
                tokenCounter++;
            }
        }
    }

    function pandasOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory tokensId = new uint256[](tokenCount);
            for (uint256 i = 0; i < tokenCount; i++){
                tokensId[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return tokensId;
        }
    }

    function setPandaPrice(uint256 newPrice) public onlyOwner {
        _price = newPrice;
    }

    function setMaxPandasPurchase(uint256 _maxPandasPurchase) public onlyOwner {
      maxPandasPurchase = _maxPandasPurchase;
    }

    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function isApprovedForAll(address owner, address operator) override public view returns(bool){
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require(totalSupply().add(_amount) <= MAXPANDAS - reservedPandasCustom,
            "Hold up! You would give-away more Pandas than available...");

        for(uint256 i = 0; i < _amount; i++){
            if (totalSupply() < MAXPANDAS - reservedPandasCustom) {
                _safeMint(_to, tokenCounter + 1);
                tokenCounter++;
            }
        }
    }

    function giveAwayCustom(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= reservedPandasCustom, "Exceeds reserved Panda supply" );
        require(totalSupply().add(_amount) <= MAXPANDAS,
            "Hold up! You would give-away more Pandas than available...");
        for(uint256 i = 0; i < _amount; i++){
            _safeMint(_to, MAXPANDAS - reservedPandasCustom + 1 + i);
        }
        reservedPandasCustom -= _amount;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(msg.sender).send(balance),
            "Withdraw did not work...");
    }

    function withdraw(uint256 _amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(_amount < balance, "Amount is larger than balance");
        require(payable(msg.sender).send(_amount),
            "Withdraw did not work...");
    }

    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        uint256 tokenId = 0;
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

}