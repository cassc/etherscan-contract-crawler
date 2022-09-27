// SPDX-License-Identifier: MIT
// Creator: @casareafer at 1TM.io

pragma solidity ^0.8.17;

import "./openzeppelin/Ownable.sol";
import "./PioneerPassLibrary.sol";

contract PioneerPassStorage is Ownable {
    mapping(address => mapping(uint256 => bool)) internal presaleMinted;
    mapping(address => mapping(uint256 => bool)) internal whitelistMinted;
    mapping(uint256 => Library.Pass) internal passIdToCollectionPass;
    uint256[] internal passIdIndex;

    /**
    *   Retrieve a PioneerPass details
    */

    function getPioneerPassDetails(uint256 _passId) external view returns (Library.Pass memory){
        require(passIdToCollectionPass[_passId].passId != 0, "Invalid Pass");
        return passIdToCollectionPass[_passId];
    }

    /**
    *   Utils - Checks if the wallet address already minted
    */

    function getMinted(uint256 _passId, address _account) external view returns (bool presale, bool whitelist) {
        return (presaleMinted[_account][_passId], whitelistMinted[_account][_passId]);
    }

    /**
    *   Adds a new type of Pioneer Pass
    */

    function addPass(
        uint256 _passId,
        uint16 _maxSupply,
        uint8 _maxMint,
        uint24 _stakingPoints,
        bytes32 _whitelistMerkleRoot,
        uint256 _mintPrice,
        uint256 _whitelistPrice,
        uint256 _hodlersPrice
    ) external onlyOwner {
        require(_passId != 0, "Invalid Id");
        require(passIdToCollectionPass[_passId].passId != _passId, "Pass ID duplicate");
        Library.Pass memory pass = Library.Pass(
            false,
            false,
            _maxSupply,
            0,
            _maxMint,
            _stakingPoints,
            _whitelistMerkleRoot,
            _passId,
            _mintPrice,
            _whitelistPrice,
            _hodlersPrice
        );
        passIdToCollectionPass[_passId] = pass;
        passIdIndex.push(_passId);
    }

    /**
    *   Utils - Modify PioneerPass types
    */

    function updatePass(
        uint256 _passId,
        uint8 _maxMint,
        uint16 _maxSupply,
        uint16 _stackingPoints,
        bytes32 _merkleRoot,
        uint256 _mintPrice,
        uint256 _whitelistPrice,
        uint256 _hodlersPrice
    ) external onlyOwner {
        passIdToCollectionPass[_passId].maxSupply = _maxSupply;
        passIdToCollectionPass[_passId].stakingPoints = _stackingPoints;
        passIdToCollectionPass[_passId].maxMint = _maxMint;
        passIdToCollectionPass[_passId].whitelistMerkleRoot = _merkleRoot;
        passIdToCollectionPass[_passId].mintPrice = _mintPrice;
        passIdToCollectionPass[_passId].whitelistPrice = _whitelistPrice;
        passIdToCollectionPass[_passId].hodlersPrice = _hodlersPrice;
    }

    function setSaleStatus(uint256 _passId, bool _presale, bool _publicSale) external onlyOwner {
        passIdToCollectionPass[_passId].publicSale = _publicSale;
        passIdToCollectionPass[_passId].preSale = _presale;
    }
}