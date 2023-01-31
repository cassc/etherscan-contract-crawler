// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title Zeitls Devil's Treasuary
 * Contract for project funds accumulation from sales (direct or aftermarket).
 * Contains affiliates' addresses for the following rewards distribution.
 */
contract ZtlDevilsTreasury is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

    event Reward(address indexed payee, uint256 amount);

    uint256 private constant SCALE = 1000; // support decimals (e.g. 2.5%)

    // Income stream from marketplaces as creators fee
    uint public royalty;

    // Income from direct sells on the website
    uint public income;

    // Organization's address for project maintenance coverage
    address public maintainer;

    // Total shares percentage for affiliates
    uint public shares;

    // Addresses of project success affiliated individuals
    EnumerableMapUpgradeable.AddressToUintMap private affiliates;

    function initialize(address _maintainer) public initializer {
        __Ownable_init();
        royalty = 0;
        income = 0;

        maintainer = _maintainer;
    }

    /**
     * @notice Collects creators fee from marketplaces
     */
    receive() external payable {
        royalty += msg.value;
    }

    /**
     * @notice Collects funds received from the auction house.
     */
    function keep() external payable {
        income += msg.value;
    }

    /**
     * @notice Distribute income between maintainer and affiliates according to the shares.
     */
    function distribute() external onlyOwner nonReentrant {
        uint total = income + royalty;

        // 20% from direct sells must be kept for the project maintenance
        uint reserve = total * 200 / SCALE;
        uint avail = total - reserve;

        // distribute rewards to affiliates
        uint sent = 0;
        for (uint8 i = 0; i < affiliates.length(); i++) {
            (address affiliate, uint256 share) = affiliates.at(i);
            uint amount = avail * share / SCALE;
            _safeTransferETH(affiliate, amount);
            sent += amount;
            emit Reward(affiliate, amount);
        }

        uint reward = total - sent;
        _safeTransferETH(maintainer, reward);
        emit Reward(maintainer, reward);

        if (total != (sent + reward)) {
            revert("Wrong share distribution");
        }

        income = 0;
        royalty = 0;
    }

    function isAffiliate(address addr) view external returns (bool) {
       return affiliates.contains(addr);
    }

    function addAffiliates(address[] calldata _affiliates, uint256[] calldata _shares) external onlyOwner {
        require(_affiliates.length == _shares.length, "Wrong array sizes");

        for (uint i = 0; i < _affiliates.length; i++) {
            bool present = affiliates.set(_affiliates[i], _shares[i]);
            shares += _shares[i];

            if (!present) {
                revert("Share overwrite is forbidden");
            }

            if (shares > SCALE) {
                revert("Shares total amount for affiliates limit exceeded");
            }
        }
    }

    function removeAffiliates(address[] calldata _affiliates) external onlyOwner {
        for (uint i = 0; i < _affiliates.length; i++) {
            (bool has, uint share) = affiliates.tryGet(_affiliates[i]);

            if (has) {
                affiliates.remove(_affiliates[i]);
                shares -= share;
            }
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }
}