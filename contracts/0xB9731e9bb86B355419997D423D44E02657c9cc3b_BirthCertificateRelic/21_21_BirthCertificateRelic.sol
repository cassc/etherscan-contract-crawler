/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../RelicTokenConfigurable.sol";
import "../Reliquary.sol";

/**
 * @title Birth Certificate Relic Token
 * @author Theori, Inc.
 * @notice Configurable soul-bound tokens issued to show an account's
 *         birth certificate
 */
contract BirthCertificateRelic is RelicTokenConfigurable {
    Reliquary immutable reliquary;
    FactSignature immutable BIRTH_CERTIFICATE_SIG;

    constructor(Reliquary _reliquary) RelicToken() Ownable() {
        BIRTH_CERTIFICATE_SIG = Facts.toFactSignature(Facts.NO_FEE, abi.encode("BirthCertificate"));
        reliquary = _reliquary;
    }

    /**
     * @inheritdoc RelicToken
     * @dev Do not validate data as it may contain URI provider information
     */
    function hasToken(
        address who,
        uint96 /* data */
    ) internal view override returns (bool result) {
        (result, ) = reliquary.verifyFactVersionNoFee(who, BIRTH_CERTIFICATE_SIG);
    }

    /// @inheritdoc IERC721Metadata
    function name() external pure override returns (string memory) {
        return "Birth Certificate Relic";
    }

    /// @inheritdoc IERC721Metadata
    function symbol() external pure override returns (string memory) {
        return "BCR";
    }
}