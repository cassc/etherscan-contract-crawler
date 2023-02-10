// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./standards/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IGaiaProtocolGods.sol";

contract GaiaProtocolGods is IGaiaProtocolGods, Pausable, Ownable, ERC721A {
    string internal __baseURI;
    bool public airdropCompleted;

    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721A(name_, symbol_) {
        __baseURI = baseURI_;
    }

    //view functions
    function totalSupply() public view override(ERC721A, IERC721A) returns (uint256) {
        return _totalMinted();
    }

    function exists(uint256 tokenId) external view virtual returns (bool) {
        return _exists(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    //operational functions
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        __baseURI = baseURI_;
        emit SetBaseURI(baseURI_);
    }

    function completeAirdrop() external onlyOwner {
        airdropCompleted = true;
        emit CompleteAirdrop();
    }

    function setPause(bool status) external onlyOwner {
        if (status) _pause();
        else _unpause();
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        if (paused()) _revert(PausedNow.selector);
    }

    function airdrop(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(!airdropCompleted);
        uint256 length = recipients.length;
        require(length == amounts.length);

        for (uint256 i; i < length; ) {
            address r = recipients[i];
            uint256 amount = amounts[i];
            _mint(r, amount);
            unchecked {
                i++;
            }
        }
    }

    function batchTransferFrom(address from, address to, uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; ) {
            uint256 id = tokenIds[i];
            transferFrom(from, to, id);
            unchecked {
                i++;
            }
        }
    }
}