// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {ERC1155} from "../token/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

///@notice Ownable extension of ERC1155 that incldues name, symbol, and uri methods
contract ERC1155Metadata is ERC1155, Ownable {
    string public name;
    string public symbol;
    string internal uri_;
    bool public isMetadataFrozen;

    error MetadataIsFrozen();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) {
        name = _name;
        symbol = _symbol;
        uri_ = _uri;
    }

    //////////////////////
    // Metadata methods //
    //////////////////////

    ///@notice gets the URI for a tokenId
    ///@dev this implementation always returns configured uri regardless of tokenId
    ///@return string uri
    function uri(uint256) public view virtual override returns (string memory) {
        return uri_;
    }

    ///@notice set contract base URI if isMetadataFrozen is false. OnlyOwner
    ///@param _uri new base URI
    function setUri(string calldata _uri) external onlyOwner {
        if (isMetadataFrozen) {
            revert MetadataIsFrozen();
        }
        uri_ = _uri;
    }

    ///@notice Irreversibly prevent base URI from being updated in the future. OnlyOwner
    function freezeMetadata() external onlyOwner {
        isMetadataFrozen = true;
    }
}