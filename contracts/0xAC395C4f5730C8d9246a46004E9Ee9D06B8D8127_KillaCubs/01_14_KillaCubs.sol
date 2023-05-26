// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "./KillaCubs/KillaCubsRestrictor.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IURIManager {
    function getTokenURI(
        uint256 id,
        Token memory token
    ) external view returns (string memory);
}

contract KillaCubs is KillaCubsRestrictor, IURIManager {
    using Strings for uint256;
    using Strings for uint16;

    IURIManager public uriManager;

    string public baseURI;
    string public baseURIFinalized;
    uint256 public finalizedGeneration;

    constructor(
        address bitsAddress,
        address gearAddress,
        address superOwner
    ) KillaCubsRestrictor(bitsAddress, gearAddress, superOwner) {
        uriManager = IURIManager(this);
    }

    function mint(
        address owner,
        uint256[] calldata ids,
        bool staked
    ) public onlyAuthority {
        _mint(owner, ids, staked);
    }

    function mint(address owner, uint16 n, bool staked) external onlyAuthority {
        _mint(owner, n, staked);
        if (counters.batched > 5555) revert Overflow();
    }

    function mintRedeemed(
        address owner,
        uint16 n,
        bool staked
    ) external onlyAuthority {
        _mint(owner, n, staked);
        counters.redeems += n;
        wallets[owner].redeems += n;
        if (counters.batched > 5555) revert Overflow();
    }

    function useAllowance(
        address sender,
        address main,
        uint256 n,
        bool holders,
        uint256 allowance
    ) external onlyAuthority {
        wallets[sender].allowlistMints += uint16(n);

        Wallet storage w = wallets[main];
        if (holders) {
            w.holderMints += uint16(n);
            if (w.holderMints > allowance) revert Overflow();
        } else {
            w.privateMints += uint16(n);
            if (w.privateMints > allowance) revert Overflow();
        }
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        Token memory token = resolveToken(id);
        return uriManager.getTokenURI(id, token);
    }

    function getTokenURI(
        uint256 id,
        Token memory token
    ) public view returns (string memory) {
        bool staked = token.stakeTimestamp > 0;
        uint256 phase = _getIncubationPhase(token);
        uint256 gen = token.generation;
        if (laterGenerations[id] != 0) gen = laterGenerations[id];

        if (staked) {
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        gen == 0 ? "initial-" : "remix-",
                        id.toString(),
                        "-",
                        phase.toString(),
                        "-",
                        token.bit.toString()
                    )
                );
        }

        string storage base = gen < finalizedGeneration
            ? baseURI
            : baseURIFinalized;

        return
            string(
                abi.encodePacked(
                    base,
                    gen == 0 ? "cubryo-" : "cub-",
                    id.toString(),
                    "-",
                    phase.toString()
                )
            );
    }

    // Admin

    function configureRoyalties(
        address royaltyReceiver,
        uint96 royaltyAmount
    ) external onlyOwner {
        _setDefaultRoyalty(royaltyReceiver, royaltyAmount);
    }

    function toggleRestricted(bool restricted_) external onlyOwner {
        restricted = restricted_;
    }

    function configureStakingWindows(
        uint256 initialLength,
        uint256 remixLength
    ) external onlyOwner {
        initialIncubationLength = initialLength;
        remixIncubationLength = remixLength;
    }

    function setIncubator(address addr) external onlyOwner {
        incubator = IIncubator(addr);
    }

    function startNexGeneration() external onlyOwner {
        activeGeneration++;
    }

    function finalizeGeneration(
        uint256 gen,
        string calldata uri
    ) external onlyOwner {
        finalizedGeneration = gen;
        baseURIFinalized = uri;
    }

    function setURIManager(address addr) external onlyOwner {
        uriManager = IURIManager(addr);
    }

    function setBaseUri(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function withdraw(address to) external onlyOwner {
        if (to == address(0)) revert NotAllowed();
        payable(to).transfer(address(this).balance);
    }
}