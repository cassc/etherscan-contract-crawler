// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./StaticNFT.sol";

interface ICrystals {
    function mint(address recipient, uint256[] calldata tiers) external;
}

contract KillaLabsRewards is Ownable, ReentrancyGuard, StaticNFT {
    using ECDSA for bytes32;
    using Strings for uint256;

    address public signer;
    address public immutable killaLabsAddress;
    ICrystals public crystalsContract;

    mapping(address => uint256) public claimCounters;

    error NotAllowed();
    error InvalidSignature();
    error WrongArraySize();

    constructor(address killaLabs)
        StaticNFT("KillaLabsRewards", "KillaLabsRewards")
    {
        killaLabsAddress = killaLabs;
    }

    /// @dev Called by the KillaLabs contract to distribute rewards
    function reward(
        address recipient,
        uint256[] calldata bears,
        uint256[] calldata tiers,
        bytes calldata signature
    ) external nonReentrant {
        if (msg.sender != killaLabsAddress) revert NotAllowed();
        if (tiers.length > 4) revert WrongArraySize();
        checkSignature(bears, tiers, signature);

        uint256 packedCounters = claimCounters[recipient];

        if (packedCounters == 0) {
            emit Transfer(address(0), recipient, uint160(recipient));
        }

        for (uint256 i = 0; i < 3; i++) {
            uint256 inc = tiers[i];
            if (inc == 0) continue;
            packedCounters += inc << (12 * i);
        }

        claimCounters[recipient] = packedCounters;

        crystalsContract.mint(recipient, tiers);
    }

    /// @notice Burn a soulbound token
    function burn() external {
        if (claimCounters[msg.sender] == 0) revert NotAllowed();
        delete claimCounters[msg.sender];
        emit Transfer(msg.sender, address(0), uint160(msg.sender));
    }

    /// @notice Sets the crystals contract
    function setCrystalsContract(address addr) external onlyOwner {
        crystalsContract = ICrystals(addr);
    }

    /// @notice Sets the signer wallet address
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /// @notice Sets the base URI
    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    /// @dev Check if a signature is valid
    function checkSignature(
        uint256[] calldata bears,
        uint256[] calldata rewardIds,
        bytes calldata signature
    ) private view {
        if (
            signer !=
            ECDSA
                .toEthSignedMessageHash(
                    abi.encodePacked(bears.length, bears, rewardIds)
                )
                .recover(signature)
        ) revert InvalidSignature();
    }

    /// @dev used by StaticNFT base contract
    function getBalance(address _addr)
        internal
        view
        override
        returns (uint256)
    {
        return claimCounters[_addr] == 0 ? 0 : 1;
    }

    /// @dev used by StaticNFT base contract
    function getOwner(uint256 tokenId)
        internal
        view
        override
        returns (address)
    {
        address addr = address(uint160(tokenId));
        if (claimCounters[addr] == 0) return address(0);
        return addr;
    }

    /// @dev URI is different based on the claim counter and tier
    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        address owner = address(uint160(tokenId));
        uint256 packedCounters = claimCounters[owner];
        if (packedCounters == 0) {
            return bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "burned"))
                : "";
        }

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        (packedCounters & 0xfff).toString(),
                        "/",
                        ((packedCounters >> (12 * 1)) & 0xfff).toString(),
                        "/",
                        ((packedCounters >> (12 * 2)) & 0xfff).toString()
                    )
                )
                : "";
    }
}