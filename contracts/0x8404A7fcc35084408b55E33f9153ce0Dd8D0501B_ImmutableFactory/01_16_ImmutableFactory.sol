// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ImmutableNftToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ImmutableFactory is Ownable {
    ImmutableType[] public collectionAddressByIndex;
    address public immutableAdmin = 0x518593679b0c0D91aF42f163Bc1253e5A2903B89;

    modifier onlyOwnerOrAdmin() {
        require(
            msg.sender == immutableAdmin || msg.sender == owner(),
            "ImmutableType: Only Admin/Dev allowed."
        );
        _;
    }

    event NftTokenCreated(ImmutableType newNftToken);

    constructor() {}

    function createCollection(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _contractURI,
        uint _cost,
        uint _maxSupply,
        uint _freeMints,
        uint _startDate,
        uint _endDate,
        uint _maxPerWallet,
        uint96 _royaltyFeesInBips
    ) external onlyOwnerOrAdmin {
        ImmutableType NftTokenCollection = new ImmutableType(
            _name,
            _symbol,
            _initBaseURI,
            _contractURI,
            _cost,
            _maxSupply,
            _freeMints,
            _startDate,
            _endDate,
            _maxPerWallet,
            _royaltyFeesInBips
        );
        collectionAddressByIndex.push(NftTokenCollection);
        emit NftTokenCreated(NftTokenCollection);
    }
}