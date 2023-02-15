// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./StaticNFT.sol";

/* ------------
    Interfaces
   ------------ */

interface IKillaChronicles {
    function mint(uint256 tokenId, address recipient, uint256 qty) external;
}

/* ----------
    Contract
   ---------- */

contract KillaChroniclesSBT is
    Ownable,
    StaticNFT("KillaChronicles Burn Card", "KCBC")
{
    using Strings for uint256;

    IKillaChronicles immutable chroniclesContract;

    uint256[] public volumeIds;
    mapping(uint256 => uint256) thresholds;
    mapping(uint256 => uint256) bonusIds;
    mapping(address => bool) public authorities;

    mapping(address => mapping(uint256 => uint256)) public balances;
    mapping(address => mapping(uint256 => bool)) public hidden;

    error NotAllowed();
    error VolumeNotFound();

    constructor(address chronicles) {
        chroniclesContract = IKillaChronicles(chronicles);
    }

    modifier onlyAuthority() {
        if (!authorities[msg.sender]) revert NotAllowed();
        _;
    }

    /// @dev Tracks new burns for a given volume, mints tokens if needed
    function increaseBalance(
        address recipient,
        uint256 volumeId,
        uint256 qty
    ) external onlyAuthority {
        uint256 threshold = thresholds[volumeId];
        if (threshold == 0) revert VolumeNotFound();
        if (qty == 0) revert NotAllowed();

        uint256 oldBalance = balances[recipient][volumeId];
        uint256 newBalance = oldBalance + qty;

        balances[recipient][volumeId] = newBalance;

        if (oldBalance == 0) {
            emit Transfer(
                address(0),
                recipient,
                getTokenId(recipient, volumeId)
            );
        }

        uint256 goalpost = oldBalance + threshold - (oldBalance % threshold);
        while (newBalance >= goalpost) {
            chroniclesContract.mint(bonusIds[volumeId], recipient, 1);
            goalpost += threshold;
        }
    }

    /// @notice Sends a tracker token to null address. Tracking functionality will still work.
    function hide(uint256 volumeId) external {
        if (balances[msg.sender][volumeId] == 0) revert NotAllowed();
        if (hidden[msg.sender][volumeId]) revert NotAllowed();
        hidden[msg.sender][volumeId] = true;
        emit Transfer(msg.sender, address(0), getTokenId(msg.sender, volumeId));
    }

    /// @notice Sends a tracker token back from the null address
    function unhide(uint256 volumeId) external {
        if (balances[msg.sender][volumeId] == 0) revert NotAllowed();
        if (!hidden[msg.sender][volumeId]) revert NotAllowed();
        hidden[msg.sender][volumeId] = false;
        emit Transfer(address(0), msg.sender, getTokenId(msg.sender, volumeId));
    }

    /// @dev Gets a token ID
    function getTokenId(
        address owner,
        uint256 volumeId
    ) public pure returns (uint256) {
        return (volumeId << 160) | uint160(owner);
    }

    /* -------
        Admin
       ------- */

    /// @notice Toggles an authority contract on or off
    function toggleAuthority(address addr, bool enabled) external onlyOwner {
        authorities[addr] = enabled;
    }

    /// @notice Adds or updates a volume
    function setupVolume(
        uint256 volumeId,
        uint256 threshold,
        uint256 bonusId
    ) external onlyOwner {
        thresholds[volumeId] = threshold;
        bonusIds[volumeId] = bonusId;

        bool found = false;
        for (uint256 i = 0; i < volumeIds.length; i++) {
            if (volumeIds[i] == volumeId) {
                found = true;
                break;
            }
        }
        if (!found) volumeIds.push(volumeId);
    }

    /// @notice Sets the base URI
    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    /* --------
        Others
       -------- */

    /// @dev used by StaticNFT base contract
    function getBalance(address addr) internal view override returns (uint256) {
        uint256 amount = 0;
        for (uint256 i = 0; i < volumeIds.length; i++) {
            uint256 volumeId = volumeIds[i];
            if (balances[addr][volumeId] > 0 && !hidden[addr][volumeId])
                amount++;
        }
        return amount;
    }

    /// @dev used by StaticNFT base contract
    function getOwner(
        uint256 tokenId
    ) internal view override returns (address) {
        address owner = address(uint160(tokenId & ((2 ** 160) - 1)));
        uint256 volumeId = tokenId >> 160;
        if (hidden[owner][volumeId]) revert NonExistentToken();
        uint256 balance = balances[owner][volumeId];
        if (balance == 0) revert NonExistentToken();
        return owner;
    }

    /// @dev Gets the URI for a given token
    function tokenURI(
        uint256 tokenId
    ) external view override returns (string memory) {
        address owner = address(uint160(tokenId & ((2 ** 160) - 1)));
        uint256 volumeId = (tokenId >> 160);

        uint256 balance = balances[owner][volumeId];

        if (hidden[owner][volumeId]) {
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            string(baseURI),
                            volumeId.toString(),
                            "/",
                            balance.toString(),
                            "/hidden"
                        )
                    )
                    : "";
        }
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        string(baseURI),
                        volumeId.toString(),
                        "/",
                        balance.toString()
                    )
                )
                : "";
    }
}