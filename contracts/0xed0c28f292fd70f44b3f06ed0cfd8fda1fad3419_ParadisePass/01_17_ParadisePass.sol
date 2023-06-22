// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./ERC1155Tradable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";


/**
 * @title ParadisePass
 * ParadisePass - a contract for the Paradise MintPass
 */

contract ParadisePass is ERC1155Tradable {

    using SafeMath for uint256;
    bool public preSaleIsActive = false;
    bool public saleIsActive = false;
    uint256 public preSalePrice = 0;
    uint256 public pubSalePrice = 0;
    uint256 public maxPerWallet = 1;
    uint256 public maxPerTransaction = 1;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _id,
        uint256 _initialSupply,
        uint256 _maxSupply,
        address _proxyRegistryAddress
    ) ERC1155Tradable(_name, _symbol, _uri, _proxyRegistryAddress) {
        create(msg.sender, _id, _initialSupply, _uri, "");
        supply[_id].supply = _maxSupply;
    }

    struct Supply {
        uint256 supply;
    }
    mapping(uint256 => Supply) public supply;

    function createToken(
        uint256 _id,
        string memory _uri,
        uint256 _initialSupply,
        bytes memory _data) external onlyOwner {
        create(msg.sender, _id, _initialSupply, _uri, _data);
    }

    function setMaxSupply(uint256 _maxSupply, uint256 _id) external onlyOwner {
        supply[_id].supply = _maxSupply;
    }

    function maxSupply(uint256 _id) public view returns (uint256) {
        return supply[_id].supply;
    }

    function setPubSalePrice(uint256 _price) external onlyOwner {
        pubSalePrice = _price;
    }

    function setPreSalePrice(uint256 _price) external onlyOwner {
        preSalePrice = _price;
    }

    function setMaxPerWallet(uint256 _maxToMint) external onlyOwner {
        maxPerWallet = _maxToMint;
    }

    function setMaxPerTransaction(uint256 _maxToMint) external onlyOwner {
        maxPerTransaction = _maxToMint;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function airdrop(address[] memory _addrs, uint256 _quantity, uint256 _id)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addrs.length; i++) {
            _mint(_addrs[i], _id, _quantity, "");
            tokenSupply[_id] = tokenSupply[_id].add(_quantity);
        }
    }

    function mint(uint256 _quantity, uint256 _id) public payable {
        require(saleIsActive, "Sale is not active.");
        require(
            totalSupply(_id).add(_quantity) <= maxSupply(_id),
            "Mint has already ended."
        );
        require(_quantity > 0, "numberOfTokens cannot be 0.");
        require(
                pubSalePrice.mul(_quantity) <= msg.value,
                "ETH sent is incorrect."
            );
        require(
                balanceOf(msg.sender, _id).add(_quantity) <= maxPerWallet,
                "Exceeds limit."
            );
        require(
                _quantity <= maxPerWallet,
                "Exceeds per transaction limit."
            );

        for (uint256 i = 0; i < _quantity; i++) {
            _mint(msg.sender, _id, _quantity, "");
            tokenSupply[_id] = tokenSupply[_id].add(_quantity);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}