/*

██████╗░██████╗░██╗███╗░░░███╗███████╗██████╗░░█████╗░░█████╗░
██╔══██╗██╔══██╗██║████╗░████║██╔════╝██╔══██╗██╔══██╗██╔══██╗
██████╔╝██████╔╝██║██╔████╔██║█████╗░░██║░░██║███████║██║░░██║
██╔═══╝░██╔══██╗██║██║╚██╔╝██║██╔══╝░░██║░░██║██╔══██║██║░░██║
██║░░░░░██║░░██║██║██║░╚═╝░██║███████╗██████╔╝██║░░██║╚█████╔╝
╚═╝░░░░░╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░

*/

// SPDX-License-Identifier: GPL-3.0
// PrimeDAO Seed Factory contract. Enable PrimeDAO governance to create new Seed contracts.
// Copyright (C) 2021 PrimeDao

// solium-disable linebreak-style
/* solhint-disable space-after-comma */

pragma solidity 0.8.9;

import "openzeppelin-contracts-sol8/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-sol8/access/Ownable.sol";
import "./Seed.sol";
import "../utils/CloneFactory.sol";

/**
 * @title PrimeDAO Seed Factory
 * @dev   Enable PrimeDAO governance to create new Seed contracts.
 */
contract SeedFactory is CloneFactory, Ownable {
    Seed public masterCopy;

    event SeedCreated(address indexed newSeed, address indexed admin);

    /**
     * @dev               Set Seed contract which works as a base for clones.
     * @param _masterCopy The address of the new Seed basis.
     */
    function setMasterCopy(Seed _masterCopy) external onlyOwner {
        require(
            address(_masterCopy) != address(0),
            "SeedFactory: new mastercopy cannot be zero address"
        );
        masterCopy = _masterCopy;
    }

    /**
      * @dev                                Deploys Seed contract.
      * @param _beneficiary                 The address that recieves fees.
      * @param _admin                       The address of the admin of this contract. Funds contract
                                            and has permissions to whitelist users, pause and close contract.
      * @param _tokens                      Array containing two params:
                                                - The address of the seed token being distributed.
      *                                         - The address of the funding token being exchanged for seed token.
      * @param _softHardThresholds          Array containing two params:
                                                - the minimum funding token collection threshold in wei denomination.
                                                - the highest possible funding token amount to be raised in wei denomination.
      * @param _price                       price of a SeedToken, expressed in fundingTokens, with precision of 10**18
      * @param _startTime                   Distribution start time in unix timecode.
      * @param _endTime                     Distribution end time in unix timecode.
      * @param _vestingDurationAndCliff       Array containing two params:
                                                - Vesting period duration in days.
                                                - Cliff duration in days.
      * @param _permissionedSeed      Set to true if only whitelisted adresses are allowed to participate.
      * @param _fee                   Success fee expressed as a % (e.g. 10**18 = 100% fee, 10**16 = 1%)
      * @param _metadata              Seed contract metadata, that is IPFS URI
    */
    function deploySeed(
        address _beneficiary,
        address _admin,
        address[] memory _tokens,
        uint256[] memory _softHardThresholds,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint32[] memory _vestingDurationAndCliff,
        bool _permissionedSeed,
        uint256 _fee,
        bytes memory _metadata
    ) external onlyOwner returns (address) {
        {
            require(
                address(masterCopy) != address(0),
                "SeedFactory: mastercopy cannot be zero address"
            );
            require(
                _vestingDurationAndCliff.length == 2,
                "SeedFactory: Hasn't provided both vesting duration and cliff"
            );
        }

        // deploy clone
        address _newSeed = createClone(address(masterCopy));

        Seed(_newSeed).updateMetadata(_metadata);

        // initialize
        Seed(_newSeed).initialize(
            _beneficiary,
            _admin,
            _tokens,
            _softHardThresholds,
            _price,
            _startTime,
            _endTime,
            _vestingDurationAndCliff[0],
            _vestingDurationAndCliff[1],
            _permissionedSeed,
            _fee
        );

        emit SeedCreated(address(_newSeed), _admin);

        return _newSeed;
    }
}