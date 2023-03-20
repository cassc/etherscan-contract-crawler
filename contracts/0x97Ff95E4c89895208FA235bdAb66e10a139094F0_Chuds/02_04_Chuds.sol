// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ERC721A.sol";
import "solmate/auth/Owned.sol";

error NoSale();
error MaxSupplyReached();
error ChudLimitReached();

contract Chuds is ERC721A, Owned {
    string private baseURI;
    uint256 public constant maxChuds = 2222;
    uint256 public chudLimit = 2;
    bool public power;

    mapping(address => uint256) public chudsToAddress;

    constructor() ERC721A("Chuds", "CHUDS") Owned(msg.sender) {}

    function skim() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function powerChuds() external onlyOwner {
        power = !power;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function setChudLimit(uint256 limit) external onlyOwner {
        chudLimit = limit;
    }

    function assembleChud() external {
        if (!power) revert NoSale();
        if (_totalMinted() >= maxChuds) revert MaxSupplyReached();
        if (chudsToAddress[msg.sender] >= chudLimit) revert ChudLimitReached();

        ++chudsToAddress[msg.sender];

        _mint(msg.sender, 1);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}