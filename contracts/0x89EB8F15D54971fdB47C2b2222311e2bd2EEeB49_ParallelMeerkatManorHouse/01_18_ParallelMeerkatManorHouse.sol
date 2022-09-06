// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IParallelMeerkatManorHouse.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@parallelmarkets/token/contracts/IParallelID.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

contract ParallelMeerkatManorHouse is IParallelMeerkatManorHouse, ERC721AQueryableUpgradeable, OwnableUpgradeable {
    address PID_CONTRACT;

    // Take note of the initializer modifiers.
    // - `initializerERC721A` for `ERC721AUpgradeable`.
    // - `initializer` for OpenZeppelin's `OwnableUpgradeable`.
    function initialize() public initializerERC721A initializer {
        __ERC721A_init("ParallelMeerkatManorHouse", "PMMH");
        __Ownable_init();

        // rinkeby: 0x0F2255E8aD232c5740879e3B495EA858D93C3016
        // mainnet: 0x9ec6232742b6068ce733645AF16BA277Fa412B0A
        PID_CONTRACT = 0x9ec6232742b6068ce733645AF16BA277Fa412B0A;
    }

    function ownerMint(uint256 quantity) external onlyOwner {
        _mint(msg.sender, quantity);
    }

    function ownerGift(address to, uint256 tokenId) external onlyOwner {
        // Allow initial, gratis transfer to any address.
        super.transferFrom(msg.sender, to, tokenId);
    }

    function transferFrom(address from,  address to,  uint256 tokenId) public virtual override {
        // Forbid "normal" transfer to an address not known to be sanctions safe.
        if (!hasAnySanctionsSafeIdentityToken(to)) revert TransferToNonPIDTokenHolder();

        super.transferFrom(from, to, tokenId);
    }

    function _baseURI() internal view virtual override(ERC721AUpgradeable) returns (string memory) {
        return "https://parallelmeerkats.com/data/";
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721AUpgradeable) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
    }

    function contractURI() public pure returns (string memory) {
        return "https://parallelmeerkats.com/contract.json";
    }

    function hasAnySanctionsSafeIdentityToken(address subject) internal view returns (bool) {
        IParallelID pid = IParallelID(PID_CONTRACT);

        for (uint256 i = 0; i < pid.balanceOf(subject); i++) {
            uint256 tokenId = pid.tokenOfOwnerByIndex(subject, i);
            if (pid.isSanctionsSafe(tokenId)) return true;
        }
        return false;
    }
}