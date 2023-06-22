// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC852 is ERC1155, EIP712, Ownable, Pausable, ERC1155Supply, ERC1155Burnable {
    string public name;
    string public symbol;
    string public contractURI;
    string public baseURI;

    mapping(uint256 => uint256) public price;
    mapping(uint256 => uint256) public capacity;
    mapping(uint256 => bool) public forSale;
    mapping(address => uint256[]) public hasClaimed;

    address public signerAddress;
    address public immutable revenueAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        string memory _baseURI,
        address _signerAddress,
        address _revenueAddress,
        uint256 _capacity,
        uint256 _price
    ) ERC1155("") EIP712("852WEB3", "1") {
        name = _name;
        symbol = _symbol;
        contractURI = _contractURI;
        baseURI = _baseURI;
        signerAddress = _signerAddress;
        revenueAddress = _revenueAddress;
        price[1] = _price;
        capacity[1] = _capacity;
        forSale[1] = true;
    }

    function claim(uint256 _id, uint256 _quantity, address _address, bytes memory _signature) public payable {
        require(forSale[_id], "Not for sale");
        require(totalSupply(_id) < capacity[_id] + _quantity, "Reached max capacity");
        require(msg.value * _quantity >= price[_id], "Insufficient tokens");

        for (uint256 i = 0; i < hasClaimed[_address].length; i++) {
            require(hasClaimed[_address][i] != _id, "Already claimed");
        }

        require(check(_address, _id, _quantity, _signature) == signerAddress, "Invalid signature");

        hasClaimed[_address].push(_id);
        _mint(_address, _id, _quantity, "");

        // Send revenue to revenueAddress
        (bool success, ) = payable(revenueAddress).call{
            value: price[_id]
        }("");
        require(success, "Failed to send revenue");

        // Refund excess ether
        if (msg.value > price[_id]) {
            (success, ) = payable(msg.sender).call{
                value: msg.value - price[_id]
            }("");
            require(success, "Failed to refund");
        }
    }

    function airdrop(
        uint256 _id,
        address[] memory _addresses,
        uint256[] memory _quantity
    ) public onlyOwner {
        // !: does not check for capacity or if the is for sale
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], _id, _quantity[i], "");
        }
    }

    function check(address _to, uint256 _id, uint256 _quantity, bytes memory _signature) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Struct(address to,uint256 id,uint256 quantity)"),
            _to,
            _id,
            _quantity
        )));
        address _signerAddress = ECDSA.recover(digest, _signature);
        return _signerAddress;
    }

    function setPrice(uint256 _id, uint256 _price) public onlyOwner {
        price[_id] = _price;
    }

    function setCapacity(uint256 _id, uint256 _capacity) public onlyOwner {
        capacity[_id] = _capacity;
    }

    function setForSale(uint256 _id, bool _forSale) public onlyOwner {
        forSale[_id] = _forSale;
    }

    function issueNFT(
        uint256 _capacity,
        uint256 _price,
        uint256 _id
    ) public onlyOwner {
        price[_id] = _price;
        capacity[_id] = _capacity;
        forSale[_id] = true;
    }

    function uri(
        uint256 _tokenid
    ) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(_tokenid), ".json")
            );
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}