// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Supply} from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

struct SingularityItem {
    uint256 id;
    uint256 maxSupply;
    uint256 maxPerWallet;
    uint256 mintStart;
    uint256 price;
    bool honorWhitelist;
    bytes32 passRoot;
}

error MinterNotHuman(address sender, address origin);
error MintNotStarted(uint256 startTime,  uint256 currentTime);
error MaxSupplyReached(uint256 available, uint256 desired);
error MintPerWalletExceeded(uint256 available, uint256 desired);
error InsufficientEther(uint256 needed, uint256 given);
error NotWhitelisted();
error NoPass();

contract SingularityNFT is ERC1155, ERC1155Supply, Ownable {
    bytes32 public whitelistRoot;

    string public constant name = "S I N G U L A R I T Y";
    string public constant symbol = "\u2B58";

    mapping(uint256 => SingularityItem) private _items;
    mapping(address => mapping(uint256 => uint256)) private _mintsPerWallet;

    constructor(string memory uri) ERC1155(uri) {
    }

    function setUri(string memory newUri) external onlyOwner {
        _setURI(newUri);
    }

    function addItem(uint256 id, uint256 maxSupply, uint256 maxPerWallet, uint256 mintStart, uint256 price, bool honorWhitelist, bytes32 passRoot) external onlyOwner {
        _items[id] = SingularityItem(id, maxSupply, maxPerWallet, mintStart, price, honorWhitelist, passRoot);
    }

    function getItem(uint256 id) public view returns(SingularityItem memory) {
        return _items[id];
    }

    function getItems(uint256[] calldata ids) external view returns(SingularityItem[] memory) {
        uint256 idsLength = ids.length;
        SingularityItem[] memory items = new SingularityItem[](idsLength);

        for (uint256 i = 0; i < idsLength; ++i) {
            items[i] = getItem(ids[i]);
        }

        return items;
    }

    function mintsPerWallet(address addr, uint256 id) public view returns(uint256) {
        return _mintsPerWallet[addr][id];
    }

    function mint(uint256 id, uint256 amount, bytes32[] calldata whitelistProof, bytes32[] calldata passProof, bytes32 pass) external payable {
        if (msg.sender != tx.origin) {
            revert MinterNotHuman(msg.sender, tx.origin);
        }

        SingularityItem memory item = _items[id];

        if (item.mintStart > block.timestamp) {
            revert MintNotStarted(item.mintStart, block.timestamp);
        }

        if (totalSupply(id) + amount > item.maxSupply) {
            revert MaxSupplyReached(item.maxSupply - totalSupply(id), amount);
        }

        // If needed, honor the global whitelist
        if (item.honorWhitelist) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            bool verified = MerkleProof.verify(whitelistProof, whitelistRoot, leaf);
            if (!verified) {
                revert NotWhitelisted();
            }
        }

        // If needed, verify holding a pass
        if (item.passRoot != 0) {
            bool verified = MerkleProof.verify(passProof, item.passRoot, pass);
            if (!verified) {
                revert NoPass();
            }
        }

        uint256 mintPerWallet = mintsPerWallet(msg.sender, id);
        if (mintPerWallet + amount > item.maxPerWallet) {
            revert MintPerWalletExceeded(item.maxPerWallet - mintPerWallet, amount);
        }
        _mintsPerWallet[msg.sender][id] = mintPerWallet + amount;

        if (item.price * amount > msg.value) {
            revert InsufficientEther(item.price * amount, msg.value);
        }

        _mint(msg.sender, id, amount, "");
    }

    function setWhitelistRoot(bytes32 newWhitelistRoot) external onlyOwner {
        whitelistRoot = newWhitelistRoot;
    }

    function ownerMint(uint256 id, address[] calldata recipients, uint256 amount) external onlyOwner {
        uint256 recipientsLength = recipients.length;
        require(recipientsLength != 0 && amount != 0);

        SingularityItem memory item = _items[id];

        if (totalSupply(id) + recipientsLength * amount > item.maxSupply) {
            revert MaxSupplyReached(item.maxSupply - totalSupply(id), recipientsLength * amount);
        }

        for (uint256 i = 0; i < recipientsLength; ++i) {
            _mint(recipients[i], id, amount, "");
        }
    }

    function withdraw() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
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
}