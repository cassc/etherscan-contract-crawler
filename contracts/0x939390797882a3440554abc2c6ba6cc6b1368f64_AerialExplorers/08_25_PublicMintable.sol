// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import "./Mintable.sol";
import "../utils/Timing.sol";

abstract contract PublicMintable is Mintable {
    using Timing for uint256;

    struct Config {
        bool enabled;
        uint256 mintPrice; // 0 = free
        uint256 startTime; // 0 = disabled
        uint256 endTime; // 0 = disabled
        uint256 maxPerWallet; // 0 = unlimited
    }

    Config public publicMinting;

    modifier publicMintAllowed(address _to, uint256 _count) {
        (bool canMint, string memory reason) = _canPublicMint(_to, _count);
        require(canMint, reason);
        _;
    }

    constructor(Config memory _publicConfig) {
        publicMinting = _publicConfig;
    }

    /**
     * @dev Public minting without signature.
     */
    function publicMint(address _to, uint256 _count)
        public
        payable
        publicMintAllowed(_to, _count)
    {
        require(
            msg.value >= publicMinting.mintPrice * _count,
            "Insufficient Payment"
        );

        _mint(_to, _count);
    }

    /**
     * @dev can the address mint?
     */
    function canPublicMint(address _to, uint256 _count)
        external
        view
        returns (bool)
    {
        (bool _canMint, ) = _canPublicMint(_to, _count);
        return _canMint;
    }

    function _canPublicMint(address _to, uint256 _count)
        internal
        view
        returns (bool, string memory)
    {
        // enabled check
        if (!publicMinting.enabled) {
            return (false, "Minting Disabled");
        }

        // startTime check
        if (
            publicMinting.startTime != 0 &&
            block.timestamp.isBefore(publicMinting.startTime)
        ) {
            return (false, "Mint Not Started");
        }

        // endTime check
        if (
            publicMinting.endTime != 0 &&
            block.timestamp.isAfter(publicMinting.endTime)
        ) {
            return (false, "Mint Completed");
        }

        // maxPerWallet check
        if (
            publicMinting.maxPerWallet != 0 &&
            // @dev - is this right? Should we check total # of mints or just mints for this signature.
            // Perhaps this is where the definitions differ. maxPerWallet = global #, mintsPerSig = # of mints per sig
            (_mintCount(_to) + _count) > publicMinting.maxPerWallet
        ) {
            return (false, "Exceeds Max Per Wallet");
        }

        return (true, "");
    }

    /**
     * @dev Change the mintPrice
     */
    function _setPublicMintEnabled(bool _enabled) internal {
        publicMinting.enabled = _enabled;
    }

    /**
     * @dev Change the mintPrice
     */
    function _setPublicMintPrice(uint256 _mintPrice) internal {
        publicMinting.mintPrice = _mintPrice;
    }

    /**
     * @dev Change the startTime
     */
    function _setPublicStartTime(uint256 _startTime) internal {
        publicMinting.startTime = _startTime;
    }

    /**
     * @dev Change the startTime
     */
    function _setPublicEndTime(uint256 _endTime) internal {
        publicMinting.endTime = _endTime;
    }

    /**
     * @dev Change the maxPerWallet
     */
    function _setPublicMaxPerWallet(uint256 _maxPerWallet) internal {
        publicMinting.maxPerWallet = _maxPerWallet;
    }

    /**
     * @dev Change the public mint config
     */
    function _setPublicMintConfig(Config memory _publicConfig) internal {
        publicMinting = _publicConfig;
    }
}