//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./AbstractNekoMeka.sol";

/**
 * @dev Contracat contains hard coded constructor for AbstractNekoMeka.
 */
contract NekoMeka is AbstractNekoMeka {
    /**
     * @notice The traits provenance hash is to prove the immutability of each NEKOMEKA's metadata attribute array, i.e.
     * to prove Gary and DW cannot change any attributes of any NEKOMEKA once the contract is deployed.
     * @dev This is a root hash of all 11,000 NEKOMEKA attributes hash, using the SHA-256 algorithm, concatenated in
     * sequential order of their token ids.
     */
    string public constant TRAITS_PROVENANCE_HASH =
        "696e2beb0c27691de6c27d55d08347577f7fb4aaf23a1147a8bcf63527cc11bd";

    /**
     * @notice The assets provenance hash is to prove the immutability of each NEKOMEKA's attached assets, including
     * the image files and model files. This is immutable once being set, and will be set before the reveal day.
     */
    string public ASSETS_PROVENANCE_HASH;

    constructor()
        AbstractNekoMeka(
            "NEKOMEKA",
            "NEKOMEKA",
            11000,
            1000,
            address(0x0A8EB54B0123778291a3CDDD2074c9CE8B2cFAE5),
            0.35 ether,
            0
        )
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function setAssetsHash(string calldata _assetsHash) external onlyOwner {
        require(bytes(ASSETS_PROVENANCE_HASH).length == 0, "MEKA: assets hash must be immutable");
        ASSETS_PROVENANCE_HASH = _assetsHash;
    }
}

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@   @@@@@@@@@@@ @@@@@@@@@@@
// @@@@@@@@@@@@@ @@@@         @ @@@@@@@@@@@
// @@@@@@@@@@@@@ @@@@@@@@@@@@@@ @@@@@@@@@@@
// @@@@@@@@@@@@@@ @@@@@@@@@@@@@ @@@@@@@@@@@
// @@@@@@@@@@@@@ @@@@@@   @@@@ @ @@@@@@@@@@
// @@@@@@@@@@@@@ @@@@@@@@@@@##@@ @@@@@@@@@@
// @@@@@@@@@@@@@@@  @@@@@@@ @@@ @@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@ @@@@    @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@  @@@@@@@@@@@ @@@@@@@@@@@
// @@@@@  @@@  @    @@@@@@@@@@@  @@@@@@@@@@
// @@@@ @@ @@  @@@  @@@@@@@@@@@ @@@ @@@@@@@
// @@@@ @@@    @@@@@ @@@@%@@@@ @@@@ @@@@@@@
// @@@@@@@       @@@ @@@@ @@@@ @ @@@@@@@@@@
// @@@@@@@@@@@@@@[email protected]@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@