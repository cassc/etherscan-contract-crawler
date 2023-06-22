// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ShitPlungerRenderer.sol";

interface IRenderer {
    function render() external view returns (string memory);
}

contract ShitPlunger is ERC1155, ERC2981, Ownable {
    uint32 public constant MAX_SUPPLY = 8888;

    address public _renderer;
    uint32 public _minted = 0;
    address public _allowedMinter;
    address public _burner;

    constructor(address renderer) ERC1155("") {
        _renderer = renderer;
        setFeeNumerator(750);
    }

    function mint(address to, uint32 amount) external {
        require(_allowedMinter == msg.sender, "ShitPlunger: ?");
        require(amount + _minted <= MAX_SUPPLY, "ShitPlunger: Exceed max supply");

        _minted += amount;
        _mint(to, 0, amount, "");
    }

    function airdrop(address[] memory tos, uint32[] memory amounts) external onlyOwner {
        require(tos.length == amounts.length);
        for (uint256 i = 0; i < amounts.length; i++) {
            _minted += amounts[i];
            require(_minted <= MAX_SUPPLY, "ShitPlunger: Exceed max supply");

            _mint(tos[i], 0, amounts[i], "");
        }
    }

    function burn(address who, uint32 amount) external {
        require(msg.sender == _burner, "ShitPlunger: ?");

        _burn(who, 0, amount);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return IRenderer(_renderer).render();
    }

    function setMinter(address minter) external onlyOwner {
        _allowedMinter = minter;
    }

    function setBurner(address burner) external onlyOwner {
        _burner = burner;
    }

    function setRenderer(address renderer) external onlyOwner {
        _renderer = renderer;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC1155) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }
}