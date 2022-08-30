// SPDX-License-Identifier: MIT

/**

 /$$$$$$$$                  /$$$$$$$                             
| $$_____/                 | $$__  $$                            
| $$    /$$   /$$ /$$$$$$$ | $$  \ $$ /$$$$$$   /$$$$$$$ /$$$$$$$
| $$$$$| $$  | $$| $$__  $$| $$$$$$$/|____  $$ /$$_____//$$_____/
| $$__/| $$  | $$| $$  \ $$| $$____/  /$$$$$$$|  $$$$$$|  $$$$$$ 
| $$   | $$  | $$| $$  | $$| $$      /$$__  $$ \____  $$\____  $$
| $$   |  $$$$$$/| $$  | $$| $$     |  $$$$$$$ /$$$$$$$//$$$$$$$/
|__/    \______/ |__/  |__/|__/      \_______/|_______/|_______/ 

*/

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract FunPass is ERC1155, Ownable, ERC1155Supply, ReentrancyGuard {
    string public name = "FunPass Alpha";
    string public symbol = "FPA";
    uint256 public salePrice = 0.035 ether;
    uint256 public presalePrice = 0.035 ether;
    uint16 public maxSupply = 605;
    uint16 public supply = 605;
    uint8 public reservedSupply = 50;
    uint8 public passIndex = 0;
    bool public presaleActive;
    bool public saleActive;
    mapping (address => bool) public _presaleMinted;
    mapping (address => bool) public _saleMinted;
    bytes32 public whitelistMerkle = 0xd123e96d873846822ddd324d405551956c68044b0542bec7b48b2868c8e29332;

    constructor() ERC1155("ipfs://QmWbGqFXz1xuGD6uTPnddYswLNo6NXW96V7GKEd9xcWYxs") {
        _mint(msg.sender, passIndex, reservedSupply, "");
        supply -= reservedSupply;
    }

    function mint(bytes32[] calldata _merkleProof) public payable nonReentrant {
        require(presaleActive || saleActive, "FunPass: Sale is not live.");

        if (saleActive) { 
            require(msg.value >= salePrice, "FunPass: Insufficient tx value.");
            require(!_saleMinted[msg.sender], "FunPass: You cannot mint more than 1 in the public sale.");
            require(supply > 0, "FunPass: Exceeds available supply.");
            _mint(msg.sender, passIndex, 1, "");
            _saleMinted[msg.sender] = true;
            supply -= 1;
        } else if (presaleActive) {
            require(msg.value >= presalePrice, "FunPass: Insufficient tx value.");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(!_presaleMinted[msg.sender], "FunPass: You cannot mint more than 1 in the presale.");
            require(MerkleProof.verify(_merkleProof, whitelistMerkle, leaf), "FunPass: Invalid proof (not on whitelist?).");
            require(supply > 0, "FunPass: Exceeds available supply.");
            _mint(msg.sender, passIndex, 1, "");
            _presaleMinted[msg.sender] = true;
            supply -= 1;
        }
    }

    function setPresaleStatus(bool _presaleActive) public onlyOwner {
        presaleActive = _presaleActive;
    }

    function setSaleStatus(bool _saleActive) public onlyOwner {
        saleActive = _saleActive;
    }

    function setSalePrice(uint256 _price) public onlyOwner {
        salePrice = _price;
    }

    function setPresalePrice(uint256 _price) public onlyOwner {
        presalePrice = _price;
    }

    function setWhitelistMerkle(bytes32 _merkleRoot) public onlyOwner {
        whitelistMerkle = _merkleRoot;
    }

    function changeSupplyLeft(uint16 newSupply) public onlyOwner {
        supply = newSupply;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function withdraw() public onlyOwner {
        (bool FunPassVault,) = 0x387e664a41C146ba42DAeE0466aaF75Cda017BE5.call{
        value : address(this).balance
        }("");

        require(
            FunPassVault,
            "funds were not sent properly"
        );
    }


    function hasToken(address account) public view returns (bool) {
        return balanceOf(account, passIndex) > 0;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function totalSupply() external view returns (uint256) {
        return totalSupply(passIndex);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}