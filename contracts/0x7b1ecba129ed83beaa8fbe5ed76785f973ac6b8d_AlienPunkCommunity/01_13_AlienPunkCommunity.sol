// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';

abstract contract DROOL {
    function balanceOf(address account) public view virtual returns (uint256);
    function burnFrom(address _from, uint256 _amount) external virtual;
}

contract AlienPunkCommunity is ERC1155Supply, ERC1155Burnable, Ownable {
    uint256 private tokensAvailableToMint = 68;
    uint256 private mintStart = 0;
    uint256 private txnLimit = 10 + 1;
    string private _name;
    string private _symbol;
    string private _baseURI;

    string public baseURI = "";
    uint256 public price = 200 ether;
    DROOL public immutable drool;
    uint256 public totalMints = 500 + 1;
    uint256 public totalMinted = 0;

    constructor(address _drool)
        ERC1155("") {
        _symbol = "APC";
        _name = "Alien Punk Community";
        drool = DROOL(_drool);
    }

    function mintSingle() external {
        require(tx.origin == msg.sender, "No contracts");
        require(totalMinted + 1 < totalMints, "Exceeds supply");

        drool.burnFrom(msg.sender, price);
        totalMinted += 1;

        uint tokenId = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, totalMinted))) % tokensAvailableToMint;

        _mint(msg.sender, tokenId, 1, "");
    }

    function mint(uint quantity) external {
        require(tx.origin == msg.sender, "No contracts");
        require(quantity < txnLimit, "Over transaction limit");
        require(totalMinted + quantity < totalMints, "Exceeds supply");

        drool.burnFrom(msg.sender, quantity * price);
        totalMinted += quantity;

        uint[] memory tokenIds = new uint[](quantity);
        uint[] memory quantities = new uint[](quantity);

        for(uint i; i < quantity; i++) {
            tokenIds[i] = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, i, totalMinted))) % tokensAvailableToMint;
            if(mintStart > 0) {
                tokenIds[i] += mintStart;
            }
            quantities[i] = 1;
        }

        _mintBatch(msg.sender, tokenIds, quantities, "");
    }

    function adminMint(address addr, uint[] calldata tokenIds, uint[] calldata quantities) external onlyOwner {
        uint totalQuantity = 0;
        for(uint x = 0; x < quantities.length; x++) {
            totalQuantity += quantities[x];
        }
        require(totalMinted + totalQuantity < totalMints, "Exceeds supply");
        _mintBatch(addr, tokenIds, quantities, "");
    }

    function setTokensAvailableToMint(uint256 total) external onlyOwner {
        tokensAvailableToMint = total;
    }
    
    function setMintStart(uint256 start) external onlyOwner {
        mintStart = start;
    }

    function setTotalMints(uint256 total) external onlyOwner {
        totalMints = total;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function mintsRemaining() public view returns (uint) {
        return totalMints - totalMinted - 1;
    }

    function setBaseURI(string memory uri_) external onlyOwner {
        _baseURI = uri_;
    }
    
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        require(exists(_tokenId), "Token does not exist.");
        return bytes(_baseURI).length > 0 ? string(
            abi.encodePacked(
                _baseURI,
                Strings.toString(_tokenId),
                ".json"
            )
        ) : "";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Supply, ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}