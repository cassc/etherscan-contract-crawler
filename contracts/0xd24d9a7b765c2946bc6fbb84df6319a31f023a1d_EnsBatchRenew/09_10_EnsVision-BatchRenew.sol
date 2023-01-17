// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IEnsRenewer.sol";
import "ens-contracts/ethregistrar/IBaseRegistrar.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EnsBatchRenew is Ownable {
    IEnsRenewer public immutable ens;
    IBaseRegistrar public immutable baseRegistrar;

    constructor(IEnsRenewer _ens, IBaseRegistrar _baseRegistrar) {
        ens = _ens;
        baseRegistrar = _baseRegistrar;
    }

    /**
     * Function called "batchRenew" that allows the caller to renew multiple ENS names in a single transaction
     * @param _names: an array of strings representing the ENS names to be renewed
     * @param _durations: an array of uint256 values representing the number of seconds for which each corresponding ENS name in "names" should be renewed
     */
    function batchRenew(
        string[] calldata _names,
        uint256[] calldata _durations
    ) external payable {
        //no price check in here. but ENS will revert if the price is not correct
        for (uint256 i; i < _names.length; ) {
            ens.renew{value: ens.rentPrice(_names[i], _durations[i])}(
                _names[i],
                _durations[i]
            );
            unchecked {
                ++i;
            }
        }

        //return any excess funds to the caller if any
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    // withdraw any tokens that may be sent to this contract
    function withdrawTokens(address _token) public onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /**
     * @notice Function called "getPrice" that allows the caller to calculate the total price for renewing a list of ENS names for specified durations
     * @param _names: an array of strings representing the ENS names to be renewed
     * @param _durations: an array of uint256 values representing the number of seconds for which each corresponding ENS name in "names" should be renewed
     * @return _price the total price for renewing all the names in "names" for the corresponding durations in "durations"
     */
    function getPrice(
        string[] calldata _names,
        uint256[] memory _durations
    ) public view returns (uint256 _price) {
        require(_names.length == _durations.length, "length mismatch");

        for (uint256 i; i < _names.length; ) {
            //you can overflow it if you want.. not going to achive much though.
            unchecked {
                _price += ens.rentPrice(_names[i], _durations[i]);
                ++i;
            }
        }
    }

    /**
     * @notice
     * This function retrieves the expiry time for each name in the given array.
     *
     * @param _names An array of names to get the expiry time for.
     * @return _expiries An array of expiry times for the given names.
     */
    function getExpiryArrayFromLabels(
        string[] calldata _names
    ) public view returns (uint256[] memory _expiries) {
        // Initialize the array to hold the expiry times to the same length as the names array.
        _expiries = new uint256[](_names.length);

        // Loop through each name in the array.
        for (uint256 i; i < _names.length; ) {
            // Get the expiry time for the name by hashing the name and looking up the expiry time using the hash as the ID.
            _expiries[i] = baseRegistrar.nameExpires(
                uint256(keccak256(abi.encodePacked(_names[i])))
            );

            // Increment the counter without checking for integer overflow.
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice
     * This function retrieves the price for aggregated renewals.
     *
     * @param _names An array of names to get the expiry time for.
     * @return _price A sum of the prices for each name.
     */
    function getSyncPriceFromLabels(
        string[] calldata _names,
        uint256 _syncdate
    ) external view returns (uint256 _price) {
        uint256[] memory durations = getSyncArrayFromLabels(_names, _syncdate);
        _price = getPrice(_names, durations);
    }

    function visionRenew(
        string[] calldata _names,
        uint256 _duration
    ) external payable {
        for (uint256 i; i < _names.length; ) {
            ens.renew{value: ens.rentPrice(_names[i], _duration)}(
                _names[i],
                _duration
            );
            unchecked {
                ++i;
            }
        }

        //return any excess funds to the caller if any
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function syncExpirations(
        string[] calldata _names,
        uint256 _syncdate
    ) external payable {
        uint256[] memory durations = getSyncArrayFromLabels(_names, _syncdate);

        for (uint256 i; i < _names.length; ) {
            ens.renew{value: ens.rentPrice(_names[i], durations[i])}(
                _names[i],
                durations[i]
            );
            unchecked {
                ++i;
            }
        }

        //return any excess funds to the caller if any
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    /**
     * @notice
     * This function retrieves the expiry time for each ID in the given array.
     *
     * @param _ids An array of IDs to get the expiry time for.
     * @return _expiries An array of expiry times for the given IDs.
     */
    function getExpiryArray(
        uint256[] calldata _ids
    ) external view returns (uint256[] memory _expiries) {
        // Initialize the array to hold the expiry times to the same length as the ID array.
        _expiries = new uint256[](_ids.length);

        // Loop through each ID in the array.
        for (uint256 i; i < _ids.length; ) {
            // Get the expiry time for the ID.
            _expiries[i] = baseRegistrar.nameExpires(_ids[i]);

            // Increment the counter without checking for integer overflow.
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice
     * This function calculates the duration between a new expiry time and the current expiry time for each ID in the given array.
     * If the new expiry time is earlier than the current expiry time, the duration will be set to 0.
     *
     * @param _ids An array of IDs to calculate the duration for.
     * @param _newExpiry The new expiry time to use for the calculation.
     */
    function getSyncArray(
        uint256[] calldata _ids,
        uint256 _newExpiry
    ) external view returns (uint256[] memory _durations) {
        // Initialize the array to hold the durations to the same length as the ID array.
        _durations = new uint256[](_ids.length);

        // Loop through each ID in the array.
        for (uint256 i; i < _ids.length; ) {
            // Get the current expiry time for the ID.
            uint256 expiry = baseRegistrar.nameExpires(_ids[i]);

            // If the new expiry time is later than the current expiry time, set the duration to the difference between the two.
            // Otherwise, set the duration to 0.
            _durations[i] = _newExpiry > expiry ? _newExpiry - expiry : 0;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice
     * This function calculates the duration between a new expiry time and the current expiry time for each label in the given array.
     * If the new expiry time is earlier than the current expiry time, the duration will be set to 0.
     *
     * @param _labels An array of labels to calculate the duration for.
     * @param _newExpiry The new expiry time to use for the calculation.
     */
    function getSyncArrayFromLabels(
        string[] calldata _labels,
        uint256 _newExpiry
    ) public view returns (uint256[] memory _durations) {
        // Initialize the array to hold the durations to the same length as the label array.
        _durations = new uint256[](_labels.length);

        // Loop through each label in the array.
        for (uint256 i; i < _labels.length; ) {
            // Get the current expiry time for the label by hashing the label and looking up the expiry time using the hash as the ID.
            uint256 expiry = baseRegistrar.nameExpires(
                uint256(keccak256(abi.encodePacked(_labels[i])))
            );

            // If the new expiry time is later than the current expiry time, set the duration to the difference between the two.
            // Otherwise, set the duration to 0.
            _durations[i] = _newExpiry > expiry ? _newExpiry - expiry : 0;
            unchecked {
                ++i;
            }
        }
    }
}