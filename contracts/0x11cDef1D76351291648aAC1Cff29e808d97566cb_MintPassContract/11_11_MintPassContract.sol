// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MintPassContract is ERC1155, Ownable {
    using Strings for uint256;

    struct InitialParameters {
        uint256 launchpassId;
        string name;
        string symbol;
        string uri;
    }
    
    string private baseURI;
    address private burnerContract;
    string public name;
    string public symbol;
    uint256 public launchpassId;
    bool public supplyLock = false;

    mapping(uint256 => bool) public validTypes;

    event SetBaseURI(string indexed _uri);

    constructor(
        address _owner,
        InitialParameters memory initialParameters
    ) ERC1155(initialParameters.uri) {
        launchpassId = initialParameters.launchpassId;
        name = initialParameters.name;
        symbol = initialParameters.symbol;
        baseURI = initialParameters.uri;
        emit SetBaseURI(baseURI);
        transferOwnership(_owner);
    }

    function lockSupply() public onlyOwner {
        supplyLock = true;
    }

    function createType(
        uint256 _id
    ) public onlyOwner {
        require(!supplyLock, "Supply is locked.");
        require(validTypes[_id] == false, "token _id already exists");
        validTypes[_id] = true;
    }

    function setBurnerAddress(address _address)
        external
        onlyOwner
    {
        burnerContract = _address;
    }

    function burnForAddress(uint256 _id, uint256 _quantity, address _address)
        external
    {
        require(msg.sender == burnerContract, "Invalid burner address");
        _burn(_address, _id, _quantity);
    }

    function mintBatch(uint256[] memory _ids, uint256[] memory _quantity)
        external
        onlyOwner
    {
        require(!supplyLock, "Supply is locked.");
        _mintBatch(owner(), _ids, _quantity, "");
    }

    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
        emit SetBaseURI(baseURI);
    }

    function uri(uint256 _id)
        public
        view                
        override
        returns (string memory)
    {
        require(
            validTypes[_id],
            "URI requested for invalid type"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _id.toString()))
                : baseURI;
    }
}