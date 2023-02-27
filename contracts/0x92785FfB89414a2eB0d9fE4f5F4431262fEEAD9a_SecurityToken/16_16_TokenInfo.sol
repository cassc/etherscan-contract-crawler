//SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.17;

import "oz-upgradeable/contracts/proxy/utils/Initializable.sol";

/* Implements document Management - ERC1643 */
/* Partly borrowed from Consensys/UniversalToken */
abstract contract SecurityTokenInfoUpgradeable is Initializable {
    struct Doc {
        string docURI;
        bytes32 docHash;
        uint256 timestamp;
    }

    /* Terms */
    string private termsURI;
    bytes32 private termsHash;
    //increments monotonically
    uint256 private termsVersion;
    //documents
    mapping(bytes32 => Doc) internal _documents;
    mapping(bytes32 => uint256) internal _indexOfDocHashes;
    bytes32[] internal _docHashes;

    /* Events */
    event TermsSet(
        string indexed newTerms,
        bytes32 indexed newTermsHash,
        uint256 termsVersion,
        string oldTerms,
        bytes32 oldTermsHash
    );
    event DocumentRemoved(
        bytes32 indexed name,
        string uri,
        bytes32 documentHash
    );
    event DocumentUpdated(
        bytes32 indexed name,
        string uri,
        bytes32 documentHash
    );

    function __SecurityTokenInfo_init() internal onlyInitializing {
        //terms will be set later, as we need to deploy the contract, before hashing the terms
    }

    /**
     * @dev Returns the token terms URI, hash and version.
     */
    function getTerms()
        external
        view
        returns (
            string memory,
            bytes32,
            uint256
        )
    {
        return (termsURI, termsHash, termsVersion);
    }

    /**
     * @dev Sets the terms of the token.
     * @param termsURI_ URI of the token terms
     * @param termsHash_ SHA-256 hash of the token terms
     */
    function _setTerms(string calldata termsURI_, bytes32 termsHash_)
        internal
        virtual
    {
        string memory oldTermsURI = termsURI;
        bytes32 oldTermsHash = termsHash;
        termsURI = termsURI_;
        termsHash = termsHash_;
        termsVersion++;
        emit TermsSet(
            termsURI_,
            termsHash_,
            termsVersion,
            oldTermsURI,
            oldTermsHash
        );
    }

    /**
     * @dev Associate a document with the token.
     * @dev Override in child contracts to add access control.
     * @param documentName Short name (represented as a bytes32) associated to the document.
     * @param uri Document content.
     * @param documentHash Hash of the document [optional parameter].
     */
    function _setDocument(
        bytes32 documentName,
        string calldata uri,
        bytes32 documentHash
    ) internal virtual {
        _documents[documentName] = Doc({
            docURI: uri,
            docHash: documentHash,
            timestamp: block.timestamp
        });

        if (_indexOfDocHashes[documentHash] == 0) {
            _docHashes.push(documentHash);
            _indexOfDocHashes[documentHash] = _docHashes.length;
        }

        emit DocumentUpdated(documentName, uri, documentHash);
    }

    /**
     * @dev Remove a document associated with the token.
     * @dev Override in child contracts to add access control.
     * @param documentName Short name (represented as a bytes32) associated to the document.
     */
    function _removeDocument(bytes32 documentName) internal virtual {
        require(
            bytes(_documents[documentName].docURI).length != 0,
            "Document doesnt exist"
        ); // Action Blocked - Empty document

        Doc memory data = _documents[documentName];

        uint256 index1 = _indexOfDocHashes[data.docHash];
        require(index1 > 0, "Invalid index"); //Indexing starts at 1, 0 is not allowed

        // move the last item into the index being vacated
        bytes32 lastValue = _docHashes[_docHashes.length - 1];
        _docHashes[index1 - 1] = lastValue; // adjust for 1-based indexing
        _indexOfDocHashes[lastValue] = index1;

        //_totalPartitions.length -= 1;
        _docHashes.pop();
        _indexOfDocHashes[data.docHash] = 0;

        delete _documents[documentName];

        emit DocumentRemoved(documentName, data.docURI, data.docHash);
    }

    /**
     * @dev Access a document associated with the token.
     * @param documentName Short name (represented as a bytes32) associated to the document.
     * @return Requested document + document hash + document timestamp.
     */
    function getDocument(bytes32 documentName)
        external
        view
        returns (
            string memory,
            bytes32,
            uint256
        )
    {
        require(bytes(_documents[documentName].docURI).length != 0); // Action Blocked - Empty document
        return (
            _documents[documentName].docURI,
            _documents[documentName].docHash,
            _documents[documentName].timestamp
        );
    }

    function getAllDocuments() external view returns (bytes32[] memory) {
        return _docHashes;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}