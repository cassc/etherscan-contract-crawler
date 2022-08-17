// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract SimpleErc721 is ERC721, Ownable, ReentrancyGuard {

    // Add the library methods
    using EnumerableSet for EnumerableSet.AddressSet;

    // Declare a set state variable
    EnumerableSet.AddressSet private addressSet;

    uint256 public _mintPrice;

    uint256 private _countMax;
    uint256 private _countMint;

    string internal constant INVALID_QUANTITY = "SimpleErc721: invalid quantity";
    
    constructor() ERC721("Simple", "ERC721") {
        _countMint = 1;
        _countMax = 10;
        _mintPrice = 50000000000000000; //0.05 ETH
    }

    function withdraw(address recipient, uint256 valueInWei) external onlyOwner nonReentrant {
        (bool success,) = payable(recipient).call{value: valueInWei}("");
        require(success, "SimpleErc721: value transfer unsuccessful");
    }

    function withdraw20(address tokenContract, address recipient, uint256 amount) external onlyOwner nonReentrant {
        (bool success, bytes memory data) = address(tokenContract).call(abi.encodeWithSelector(0xa9059cbb, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function withdraw721(address tokenContract, address recipient, uint256 tokenId) external onlyOwner nonReentrant {
        ERC721(tokenContract).safeTransferFrom(address(this), recipient, tokenId);
    }

    /**
     * 
     */
    function mint(uint256 quantity) external payable {
        require(quantity > 0, INVALID_QUANTITY);
        require(quantity <= _countMax, INVALID_QUANTITY);

        require(_mintPrice * quantity <= msg.value, "SimpleErc721: insufficient msg.value");

        address to = msg.sender;
        require(to == tx.origin, "SimpleErc721: minting from smart contracts is disallowed");

        require(addressSet.length() < 100, "SimpleErc721: max owner threshold exceeded");
        if(!addressSet.contains(to)) {
            addressSet.add(to);
        }

        uint256 tokenIdStart = _countMint;
        uint256 tokenIdBound = tokenIdStart + quantity;

        for (uint256 tokenId = tokenIdStart; tokenId < tokenIdBound; tokenId++) {
            _owners[tokenId] = to;
            emit Transfer(address(0), to, tokenId);
        }

        _countMint += quantity;
        _balances[to] += quantity;
    }

    
}