//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ERC721WContract.sol";

contract ERC721WRegistry {

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private wrappedContracts;

    mapping(address=>address) private erc721wAddresses;

    function getERC721wAddressFor(address wrapped) external view returns (address) {
        require(erc721wAddresses[wrapped] != address(0), "provided address is not wrapped");

        return erc721wAddresses[wrapped];
    }

    function createERC721wContract(address wrapped) public {
        require(erc721wAddresses[wrapped] == address(0), "erc721w address exists");

        require(
            (IERC165)(wrapped).supportsInterface(
                type(IERC721).interfaceId
            ),
            "not support IERC721"
        );
        require(
            (IERC165)(wrapped).supportsInterface(
                type(IERC721Metadata).interfaceId
            ),
            "not support IERC721Metadata"
        );

        IERC721Metadata erc721MetadataAddr = (IERC721Metadata)(wrapped);

        ERC721WContract created = new ERC721WContract(concatString("Wrapped ", erc721MetadataAddr.name()),
                                                      concatString("W", erc721MetadataAddr.symbol()),
                                                      wrapped,
                                                      msg.sender);

        wrappedContracts.add(wrapped);
        erc721wAddresses[wrapped] = address(created);
    }

    // !!expensive, should call only when no gas is needed;
    function getWrappedContracts() external view returns (address[] memory) {
        return wrappedContracts.values();
    }

    function concatString(string memory a, string memory b) internal pure returns (string memory) {
        return string(bytes.concat(bytes(a), bytes(b)));
    }
}