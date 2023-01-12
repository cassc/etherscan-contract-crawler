/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2018-2023 THE TOKEN BUNQ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.6.12;

import { Ownable } from "../v1/Ownable.sol";

/**
 * @title Issuance Tracker
 * @dev Storage of USDK issuance evidences by the "issuance archiver" role
 */
contract EvidenceArchive is Ownable {
    // The evidences archived here are valid only for the following proxy address
    bool internal initialized;
    address public eurkAddress;

    address public issuanceArchiver;
    uint256 public issuanceCounter;
    struct Evidence {
        string issuanceTxId;
        string issuanceFileHash;
        string issuanceFileURL;
        string issuanceIPFS;
    }
    mapping(uint256 => Evidence) public evidences;
    event NewIssuanceEvidence(
        string _newEvidenceMessage,
        string _newEvidenceTxId,
        string _newEvidenceFileHash,
        string _newEvidenceFileURL,
        string _newEvidenceIPFS
    );
    event IssuanceArchiverChanged(address indexed newIssuanceArchiver);

    /**
     * @dev Throws if called by any account other than the issuance archiver role
     */
    modifier onlyIssuanceArchiver() {
        require(
            msg.sender == issuanceArchiver,
            "EvidenceArchive: caller is not the issuance archiver"
        );
        _;
    }

    /**
     * @notice Issuance evidence storage.
     *
     */
    function setIssuanceEvidence(
        string memory _issuanceTxId,
        string memory _issuanceFileHash,
        string memory _issuanceFileURL,
        string memory _issuanceIPFS
    ) public onlyIssuanceArchiver {
        Evidence storage evidence = evidences[issuanceCounter];

        evidence.issuanceTxId = _issuanceTxId;
        evidence.issuanceFileHash = _issuanceFileHash;
        evidence.issuanceFileURL = _issuanceFileURL;
        evidence.issuanceIPFS = _issuanceIPFS;

        issuanceCounter++;
        emit NewIssuanceEvidence(
            "New evidence registered for:",
            evidence.issuanceTxId,
            evidence.issuanceFileHash,
            evidence.issuanceFileURL,
            evidence.issuanceIPFS
        );
    }

    function initialize(address newEurkAddress) public {
        require(
            !initialized,
            "EvidenceArchive: contract is already initialized"
        );

        require(
            newEurkAddress != address(0),
            "EvidenceArchive: new owner is the zero address"
        );

        eurkAddress = newEurkAddress;
        initialized = true;
    }

    function updateIssuanceArchiver(address _newIssuanceArchiver)
        external
        onlyOwner
    {
        require(
            _newIssuanceArchiver != address(0),
            "EvidenceArchive: new issuance archiver is the zero address"
        );
        issuanceArchiver = _newIssuanceArchiver;
        emit IssuanceArchiverChanged(issuanceArchiver);
    }

    function countEvidences() public view returns (uint256) {
        return issuanceCounter;
    }

    function evidencesValidFor() public view returns (string memory, address) {
        return (
            "Minting evidences are valid for EURK contract at:",
            eurkAddress
        );
    }
}