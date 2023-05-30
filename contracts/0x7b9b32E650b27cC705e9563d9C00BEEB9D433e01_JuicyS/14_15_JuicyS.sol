// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ERC721A} from "erc721a/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/extensions/ERC721AQueryable.sol";
import {MintRound} from "./MintRound.sol";

contract JuicyS is Ownable, Pausable, ERC721A, ERC721AQueryable, MintRound {
    event BaseTokenURIUpdated(string uri);
    event Withdraw(address account, uint256 amount);

    uint256 public constant MAX_SUPPLY = 3999;
    string public baseTokenURI;

    constructor(string memory name_, string memory symbol_)
        ERC721A(name_, symbol_)
        EIP712(name_, "1")
        MintRound(MAX_SUPPLY)
    {}

    function setBaseTokenURI(string calldata uri) external onlyOwner {
        baseTokenURI = uri;
        emit BaseTokenURIUpdated(uri);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        emit Withdraw(_msgSender(), balance);
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to withdraw funds");
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        require(!paused(), "Token transfer while paused");
    }
}