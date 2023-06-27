// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC852 is
    ERC1155,
    EIP712,
    Ownable,
    Pausable,
    ERC1155Supply,
    ERC1155Burnable
{
    string public name = "852Merch";
    string public symbol = "Merch";
    string public baseURI = "https://852web3.io/metadata/merch/";
    address public signerAddress = 0xc13336Ca37bCAcd2071863c08301282089DcCb29;

    mapping(uint256 => uint256) public price;
    mapping(uint256 => uint256) public capacity;
    mapping(uint256 => bool) public onSale;
    mapping(uint256 => bool) public isTransferable;
    mapping(address => uint256[]) public hasClaimed;

    constructor() ERC1155("") EIP712("852WEB3", "1") {
        price[1] = 0 ether;
        capacity[1] = 852;
        onSale[1] = true;
        isTransferable[1] = true;
    }

    function claim(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _signature
    ) public payable {
        require(onSale[_id], "Not on sale");
        require(
            totalSupply(_id) < capacity[_id] + _quantity,
            "Reached max capacity"
        );
        require(msg.value * _quantity >= price[_id], "Insufficient ether");

        for (uint256 i = 0; i < hasClaimed[_to].length; i++) {
            require(hasClaimed[_to][i] != _id, "Already claimed");
        }

        require(
            check(_to, _id, _quantity, _signature) == signerAddress,
            "Invalid signature"
        );

        hasClaimed[_to].push(_id);
        _mint(_to, _id, _quantity, "");
    }

    function airdrop(
        address[] memory _addresses,
        uint256 _id,
        uint256 _quantity
    ) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], _id, _quantity, "");
        }
    }

    function check(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("Struct(address to,uint256 id,uint256 quantity)"),
                    _to,
                    _id,
                    _quantity
                )
            )
        );
        address _signerAddress = ECDSA.recover(digest, _signature);
        return _signerAddress;
    }

    function issueMerch(
        uint256 _capacity,
        uint256 _price,
        uint256 _id,
        bool _onSale,
        bool _isTransferable
    ) public onlyOwner {
        price[_id] = _price;
        capacity[_id] = _capacity;
        onSale[_id] = _onSale;
        isTransferable[_id] = _isTransferable;
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        payable(msg.sender).transfer(_amount);
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

    function setSignerAddress(address _address) public onlyOwner {
        signerAddress = _address;
    }

    function setPrice(uint256 _id, uint256 _price) public onlyOwner {
        price[_id] = _price;
    }

    function setCapacity(uint256 _id, uint256 _capacity) public onlyOwner {
        capacity[_id] = _capacity;
    }

    function setOnSale(uint256 _id, bool _onSale) public onlyOwner {
        onSale[_id] = _onSale;
    }

    function setIsTransferable(
        uint256 _id,
        bool _isTransferable
    ) public onlyOwner {
        isTransferable[_id] = _isTransferable;
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
        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                require(
                    isTransferable[ids[i]] == true,
                    "Non-transferable merch"
                );
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}