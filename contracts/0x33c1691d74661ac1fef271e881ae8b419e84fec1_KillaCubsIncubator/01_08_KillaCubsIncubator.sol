// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./StaticNFT.sol";

struct Wallet {
    uint16 balance;
    uint16 stakes;
    uint16 mints;
    uint16 privateMints;
    uint16 holderMints;
}

struct Token {
    address owner;
    uint16 linkedNext;
    uint16 linkedPrev;
    uint32 stakeTimestamp;
    uint8 generation;
    uint8 incubationPhase;
    uint16 bit;
}

interface IKillaCubs {
    function ownerOf(uint256) external view returns (address);

    function rightfulOwnerOf(uint256) external view returns (address);

    function getIncubationPhase(uint256 id) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function resolveToken(uint256 id) external view returns (Token memory);

    function wallets(address) external view returns (Wallet memory);
}

interface IURIManager {
    function getTokenURI(
        uint256 id,
        Token memory token
    ) external view returns (string memory);
}

contract KillaCubsIncubator is
    Ownable,
    StaticNFT("Incubator", "Incubator")
{
    using Strings for uint256;
    using Strings for uint16;
    IKillaCubs public killacubsContract;

    constructor(address killacubs) {
        killacubsContract = IKillaCubs(killacubs);
    }

    modifier onlyCubs() {
        require(msg.sender == address(killacubsContract), "Not Allowed");
        _;
    }

    function add(address owner, uint256[] calldata ids) external onlyCubs {
        for (uint256 i = 0; i < ids.length; i++) {
            emit Transfer(address(0), owner, ids[i]);
        }
    }

    function add(
        address owner,
        uint256 start,
        uint256 count
    ) external onlyCubs {
        uint256 end = start + count;
        for (uint256 id = start; id <= end - 1; id++) {
            emit Transfer(address(0), owner, id);
        }
    }

    function remove(address owner, uint256[] calldata ids) external onlyCubs {
        for (uint256 i = 0; i < ids.length; i++) {
            emit Transfer(owner, address(0), ids[i]);
        }
    }

    function remove(
        address owner,
        uint256 start,
        uint256 count
    ) external onlyCubs {
        uint256 end = start + count;
        for (uint256 id = start; id < end; id++) {
            emit Transfer(owner, address(0), id);
        }
    }

    function getBalance(
        address owner
    ) internal view override returns (uint256) {
        return uint256(killacubsContract.wallets(owner).stakes);
    }

    function getOwner(uint256 token) internal view override returns (address) {
        address owner = killacubsContract.ownerOf(token);
        if (owner == address(killacubsContract))
            return killacubsContract.rightfulOwnerOf(token);
        return address(0);
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function totalSupply() public view returns (uint256) {
        return killacubsContract.balanceOf(address(killacubsContract));
    }

    function tokenURI(
        uint256 id
    ) external view override returns (string memory) {
        if (getOwner(id) == address(0))
            return string(abi.encodePacked(baseURI, "burned"));

        Token memory token = killacubsContract.resolveToken(id);
        uint256 phase = killacubsContract.getIncubationPhase(id);

        return
            string(
                abi.encodePacked(
                    baseURI,
                    id.toString(),
                    "-",
                    phase.toString(),
                    "-",
                    token.bit.toString(),
                    token.generation > 0 ? "-remix" : "-initial"
                )
            );
    }
}