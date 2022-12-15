// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Rekters is ERC721A, Ownable {
    // This variable is not actually used, it's here just for reference.
    uint256 public maxSupply = 2000;

    string private storedBaseURI =
        "ipfs://QmTpQ65C884LsKBeFYs3e6vvh78p7KKUm1YwmoLXBCmsKN/";

    bool public isSaleActive = false;

    address public operator;

    constructor(
        string memory name_,
        string memory symbol_,
        address _operator
    ) ERC721A(name_, symbol_) {
        operator = _operator;
    }

    function setBaseURI(string memory _storedBaseURI) external onlyOwner {
        storedBaseURI = _storedBaseURI;
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function _baseURI() internal view override returns (string memory) {
        return storedBaseURI;
    }

    function operatorMint(address receiver, uint256 quantity) external {
        _mint(receiver, quantity);
    }

    // we create a function that receives two arrays,
    // the first array contains addresses and the second array contains the amount of tokens to mint for each address
    function operatorMintBatch(
        address[] memory receivers,
        uint256[] memory quantities
    ) external {
        require(
            receivers.length == quantities.length,
            "Rekters: receivers and quantities length mismatch"
        );

        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], quantities[i]);
        }
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
}

// sha256(id + id + id + id + id + all initials)
// 053f31e38a3e582a17368d7455778cd1705480c7bfff4a405340499b491148e8