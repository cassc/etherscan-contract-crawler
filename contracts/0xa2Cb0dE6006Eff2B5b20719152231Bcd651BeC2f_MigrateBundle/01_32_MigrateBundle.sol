// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./NftfiBundler.sol";
import "./ImmutableBundle.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract MigrateBundle is IERC721Receiver {
    event BundleMigrated(uint256 newBundleId);
    event ImmutableMigrated(uint256 newImmutableId);
    event BundleBurned(uint256 bundleId);

    /**
     * @dev Migrates a bundle between 2 NftfiBundler contracts,
     * this contract needs to have approval for the bundle token first
     * @param _oldBundleContract address of the old NftfiBundler contract
     * @param _newBundleContract address of the new NftfiBundler contract
     * @param _oldBundleId the id of the bundle to be migrated
     */
    function migrateBundle(
        address _oldBundleContract,
        address _newBundleContract,
        uint256 _oldBundleId
    ) public returns (uint256) {
        // bundle has to be transferred to this contract for the migration (approval needed first)
        IERC721(_oldBundleContract).transferFrom(msg.sender, address(this), _oldBundleId);
        // actual migration happening in the internal contract
        uint256 newBundleId = _migrateBundle(_oldBundleContract, _newBundleContract, _oldBundleId, msg.sender);
        _burnBundle(_oldBundleContract, _oldBundleId);
        return newBundleId;
    }

    /**
     * @dev Migrates a bundle between 2 ImmutableBundle contracts,
     * this contract needs to have approval for the bundle token first
     * @param _oldImmutableContract address of the old ImmutableBundle contract
     * @param _newImmutableContract address of the new ImmutableBundle contract
     * @param _oldImmutableId the id of the immutable bundle to be migrated
     */
    function migrateImmutable(
        address _oldImmutableContract,
        address _newImmutableContract,
        uint256 _oldImmutableId
    ) external returns (uint256) {
        // immutable has to be transferred to this contract for the migration (approval needed first)
        IERC721(_oldImmutableContract).transferFrom(msg.sender, address(this), _oldImmutableId);
        address oldBundleContract = address(ImmutableBundle(_oldImmutableContract).bundler());
        address newBundleContract = address(ImmutableBundle(_newImmutableContract).bundler());
        uint256 oldBundleId = ImmutableBundle(_oldImmutableContract).bundleOfImmutable(_oldImmutableId);
        // withdrawing old Immutable to this address, meaning we get a regular bundle in the old NftfiBundler
        ImmutableBundle(_oldImmutableContract).withdraw(_oldImmutableId, address(this));
        // migrating from old NftfiBundler to new
        uint256 newBundleId = _migrateBundle(oldBundleContract, newBundleContract, oldBundleId, address(this));
        // burn old bundle
        _burnBundle(oldBundleContract, oldBundleId);
        // sending the new NftfiBundler to the new Immutable to wrap
        IERC721(newBundleContract).safeTransferFrom(address(this), _newImmutableContract, newBundleId);
        uint256 newImmutabelId = ImmutableBundle(_newImmutableContract).tokenCount();
        // sending new immutable to user
        IERC721(_newImmutableContract).safeTransferFrom(address(this), msg.sender, newImmutabelId);
        emit ImmutableMigrated(newImmutabelId);
        return ImmutableBundle(_newImmutableContract).tokenCount();
    }

    /**
     * @dev same as decomposeBundle, but burning empty bundle token afterwards
     * @param _bundleContract address of the NftfiBundler contract
     * @param _bundleId the id of the bundle to be decomposed and burned
     * @param _receiver address receiving the contents of the bundle
     */
    function decomposeAndBurnBundle(
        address _bundleContract,
        uint256 _bundleId,
        address _receiver
    ) external {
        // immutable has to be transferred to this contract for the migration (approval needed first)
        IERC721(_bundleContract).transferFrom(msg.sender, address(this), _bundleId);
        _decomposeAndBurnBundle(_bundleContract, _bundleId, _receiver);
    }

    /**
     * @dev same as withdraw immutable and decomposeBundle, but burning empty bundle token afterwards
     * @param _immutableContract address of the ImmutableBundle contract
     * @param _immutableId the id of the immutable bundle to be decomposed and burned
     * @param _receiver address receiving the contents of the immutable bundle
     */
    function decomposeAndBurnImmutable(
        address _immutableContract,
        uint256 _immutableId,
        address _receiver
    ) external {
        // immutable has to be transferred to this contract for the migration (approval needed first)
        IERC721(_immutableContract).transferFrom(msg.sender, address(this), _immutableId);
        _decomposeAndBurnImmutable(_immutableContract, _immutableId, _receiver);
    }

    /**
     * @dev same as decomposeBundle, but burning empty bundle token afterwards
     * @param _bundleContract address of the NftfiBundler contract
     * @param _bundleId the id of the bundle to be decomposed and burned
     * @param _receiver address receiving the contents of the bundle
     */
    function _decomposeAndBurnBundle(
        address _bundleContract,
        uint256 _bundleId,
        address _receiver
    ) internal {
        NftfiBundler(_bundleContract).decomposeBundle(_bundleId, _receiver);
        _burnBundle(_bundleContract, _bundleId);
    }

    /**
     * @dev same as withdraw immutable and decomposeBundle, but burning empty bundle token afterwards
     * @param _immutableContract address of the ImmutableBundle contract
     * @param _immutableId the id of the immutable bundle to be decomposed and burned
     * @param _receiver address receiving the contents of the immutable bundle
     */
    function _decomposeAndBurnImmutable(
        address _immutableContract,
        uint256 _immutableId,
        address _receiver
    ) internal {
        uint256 bundleId = ImmutableBundle(_immutableContract).bundleOfImmutable(_immutableId);
        ImmutableBundle(_immutableContract).withdraw(_immutableId, address(this));
        address bundleContract = address(ImmutableBundle(_immutableContract).bundler());
        _decomposeAndBurnBundle(bundleContract, bundleId, _receiver);
    }

    /**
     * @dev internal function for the migration 2 NftfiBundler contracts,
     * since it is both used in the public migrateBundle function and in migrateImmutable
     * @param _oldBundleContract address of the old NftfiBundler contract
     * @param _newBundleContract address of the new NftfiBundler contract
     * @param _oldBundleId the id of the bundle to be migrated
     * @param _owner owner address of the new bundle that gets created (needs to be different fo the 2 caller functions)
     */
    function _migrateBundle(
        address _oldBundleContract,
        address _newBundleContract,
        uint256 _oldBundleId,
        address _owner
    ) internal returns (uint256) {
        // minting the new bundle on the new contract
        // in case of migrateBundle owner is the user
        // in case of migrateImmutable owner is this contract, to be able to send it to the new immutable in next step
        uint256 newBundleId = NftfiBundler(_newBundleContract).safeMint(_owner);
        // iterating over all the various collections in the bundle
        while (NftfiBundler(_oldBundleContract).totalChildContracts(_oldBundleId) > 0) {
            // getting the collection's contract address of a given collection in the bundle
            address childContract = NftfiBundler(_oldBundleContract).childContractByIndex(_oldBundleId, 0);
            // iterating over all the items of a given collection in the bundle
            while (NftfiBundler(_oldBundleContract).totalChildTokens(_oldBundleId, childContract) > 0) {
                // getting the actual item id stored in the bundle
                uint256 childId = NftfiBundler(_oldBundleContract).childTokenByIndex(_oldBundleId, childContract, 0);
                try
                    // sending over the item into the newly minted bundle in the newBundleContract
                    // in a try block, since if the item is legacy safeTransferChild with a 5th data parameter
                    // (adressing the new bundle id) will fail
                    NftfiBundler(_oldBundleContract).safeTransferChild(
                        _oldBundleId,
                        _newBundleContract,
                        childContract,
                        childId,
                        abi.encodePacked(newBundleId)
                    )
                {
                    // solhint-disable-previous-line no-empty-blocks
                } catch {
                    // legacy way of trasferring with approval and getChild
                    // 3 tx-s instead of 1 in the case of safeTransferChild :(
                    NftfiBundler(_oldBundleContract).transferChild(_oldBundleId, address(this), childContract, childId);
                    IERC721(childContract).approve(_newBundleContract, childId);
                    NftfiBundler(_newBundleContract).getChild(address(this), newBundleId, childContract, childId);
                }
            }
        }
        emit BundleMigrated(newBundleId);
        return newBundleId;
    }

    /**
     * @dev burn bundle by sending it to '0x000000000000000000000000000000000000dEaD' burn
     * address (sending to address(0) is prevented by a require in ERC721 _transfer)
     * @param _bundleContract address of the NftfiBundler contract
     * @param _bundleId the id of the bundle to be burned
     */
    function _burnBundle(address _bundleContract, uint256 _bundleId) internal {
        IERC721(_bundleContract).transferFrom(
            address(this),
            address(0x000000000000000000000000000000000000dEaD),
            _bundleId
        );
    }

    /**
     * @dev needed to be able to receive safeTransferFrom of immutable withdrawal
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}