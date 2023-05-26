pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

import "./HasSecondarySaleFees.sol";
import "./ERC1155Metadata_URI.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../../libs/Ownable.sol";
import "../HasContractURI.sol";

abstract contract ERC1155Base is HasSecondarySaleFees, Ownable, ERC1155Metadata_URI, HasContractURI, ERC1155 {

    struct Fee {
        address payable recipient;
        uint256 value;
    }

    // id => creator
    mapping (uint256 => address) public creators;
    // id => fees
    mapping (uint256 => Fee[]) public fees;

    // Max count of fees
    uint256 maxFeesCount = 100;

    constructor(string memory contractURI, string memory tokenURIPrefix, string memory uri) HasContractURI(contractURI) ERC1155Metadata_URI(tokenURIPrefix) ERC1155(uri) public {

    }

    function getFeeRecipients(uint256 id) public override view returns (address payable[] memory) {
        Fee[] memory _fees = fees[id];
        address payable[] memory result = new address payable[](_fees.length);
        for (uint i = 0; i < _fees.length; i++) {
            result[i] = _fees[i].recipient;
        }
        return result;
    }

    function getFeeBps(uint256 id) public override view returns (uint[] memory) {
        Fee[] memory _fees = fees[id];
        uint[] memory result = new uint[](_fees.length);
        for (uint i = 0; i < _fees.length; i++) {
            result[i] = _fees[i].value;
        }
        return result;
    }

    // Creates a new token type and assings _initialSupply to minter
    function _mint(uint256 _id, Fee[] memory _fees, uint256 _supply, string memory _uri) internal {
        require(
            _fees.length <= maxFeesCount,
            "Amount of fee recipients can't exceed 100"
        );

        uint256 sumFeeBps = 0;
        for (uint256 i = 0; i < _fees.length; i++) {
            sumFeeBps = sumFeeBps.add(_fees[i].value);
        }

        require(
            sumFeeBps <= 10000,
            "Total fee bps should not exceed 10000"
        );

        require(creators[_id] == address(0x0), "Token is already minted");
        require(_supply != 0, "Supply should be positive");
        require(bytes(_uri).length > 0, "uri should be set");

        creators[_id] = msg.sender;
        address[] memory recipients = new address[](_fees.length);
        uint[] memory bps = new uint[](_fees.length);
        for (uint i = 0; i < _fees.length; i++) {
            require(_fees[i].recipient != address(0x0), "Recipient should be present");
            require(_fees[i].value != 0, "Fee value should be positive");
            fees[_id].push(_fees[i]);
            recipients[i] = _fees[i].recipient;
            bps[i] = _fees[i].value;
        }
        if (_fees.length > 0) {
            emit SecondarySaleFees(_id, recipients, bps);
        }
        _mint(msg.sender, _id, _supply, "");
        //balanceOf(msg.sender, _id) = _supply;
        _setTokenURI(_id, _uri);

        // Transfer event with mint semantic
        emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, _supply);
        emit URI(_uri, _id);
    }

    function burn(address _owner, uint256 _id, uint256 _value) external {

        require(_owner == msg.sender || isApprovedForAll(_owner, msg.sender) == true, "Need operator approval for 3rd party burns.");

        _burn(_owner, _id, _value);
        // SafeMath will throw with insuficient funds _owner
        // or if _id is not valid (balance will be 0)
        // balanceOf(_owner, _id) = balanceOf( _owner, _id).sub(_value);

        // MUST emit event
        // emit TransferSingle(msg.sender, _owner, address(0x0), _id, _value);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) override virtual internal {
        require(creators[tokenId] != address(0x0), "_setTokenURI: Token should exist");
        super._setTokenURI(tokenId, uri);
    }

    function setTokenURIPrefix(string memory tokenURIPrefix) public onlyOwner {
        _setTokenURIPrefix(tokenURIPrefix);
    }

    function setContractURI(string memory contractURI) public onlyOwner {
        _setContractURI(contractURI);
    }

    function uri(uint256 _id) override(ERC1155Metadata_URI, ERC1155) external view returns (string memory) {
        return _tokenURI(_id);
    }
}