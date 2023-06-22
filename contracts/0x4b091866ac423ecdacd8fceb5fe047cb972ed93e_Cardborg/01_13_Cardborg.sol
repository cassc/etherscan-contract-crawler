//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Cardborg is Ownable, ERC721A {
    uint256 constant public maxSupply = 9900;
    address public minter;

    event SetMinter(address minter);

    constructor() ERC721A("SNW Cardborg", "SNW-CB", 9900, 9900) {
    }

    function mint(address user, uint256 quantity) external onlyMinter {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(totalSupply() + quantity <= maxSupply, "Over Max Supply");
        _safeMint(user, quantity);
    }

        // ====== Minter ======
    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "Invalid minter");
        minter = _minter;
        emit SetMinter(_minter);
    }

    modifier onlyMinter() {
        require(minter == msg.sender, "Only minter");
        _;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _baseURI = uri;
    }
    

}