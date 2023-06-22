// SPDX-License-Identifier: MIT

/* 

██████╗ ███████╗ ██████╗ 
╚════██╗██╔════╝██╔════╝ 
 █████╔╝███████╗███████╗ 
██╔═══╝ ╚════██║██╔═══██╗
███████╗███████║╚██████╔╝
╚══════╝╚══════╝ ╚═════╝ 

Using this contract? 
A shout out to @Mint256Art is appreciated!
 */

pragma solidity ^0.8.19;

import "./helpers/SSTORE2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RoyaltySplitter.sol";

contract TwoFiveSixFactoryRoyaltySplitterV1 is Ownable {
    address payable private _twoFiveSixAddress;

    address payable public masterRoyaltySplitter;

    /* Percentage multiplied by 100 */
    uint96 public twoFiveSixShareSecondary;

    event Deployed(address a);

    /**
     * @notice Creates a new instance of the RoyaltySplitter contract with the given artist address.
     * @dev The `masterRoyaltySplitter` is used as the contract implementation.
     * @param _artist The address of the artist who will receive the royalties.
     * @param _thirdParty The address of a potential third party who will receive a part of the royalties.
     * @param _thirdPartyShare The share of royalties the third party should receive (percentage * 100).
     */
    function createRoyaltySplitter(
        address payable _artist,
        address payable _thirdParty,
        uint96 _thirdPartyShare
    ) public {
        require(
            twoFiveSixShareSecondary + _thirdPartyShare <= 10000,
            "Third party share too high"
        );
        address payable a = clonePayable(masterRoyaltySplitter);
        RoyaltySplitter r = RoyaltySplitter(a);
        r.initRoyaltySplitter(
            _twoFiveSixAddress,
            twoFiveSixShareSecondary,
            _thirdParty,
            _thirdPartyShare,
            _artist
        );
        emit Deployed(a);
    }

    /**
     * @notice Clones a payable contract using the provided implementation address
     * @param implementation The address of the contract implementation
     */
    function clonePayable(
        address payable implementation
    ) internal returns (address payable instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Set the 256 address
     * @notice Only the contract owner can call this function
     * @param newAddress The new 256 contract address
     */
    function setTwoFiveSixAddress(address payable newAddress) public onlyOwner {
        _twoFiveSixAddress = newAddress;
    }

    /**
     * @dev Set the master royalty splitter address
     * @notice Only the contract owner can call this function
     * @param _masterRoyaltySplitter Address of the new master royalty splitter contract
     */
    function setMasterRoyaltySplitter(
        address payable _masterRoyaltySplitter
    ) public onlyOwner {
        masterRoyaltySplitter = _masterRoyaltySplitter;
    }

    /**
     * @dev Set the secondary 256 share
     * @notice Only the contract owner can call this function
     * @param newShare The new secondary 256 share
     */
    function setTwoFiveSixShareSecondary(uint96 newShare) public onlyOwner {
        twoFiveSixShareSecondary = newShare;
    }
}