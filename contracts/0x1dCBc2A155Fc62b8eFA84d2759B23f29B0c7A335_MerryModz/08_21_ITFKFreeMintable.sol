// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Contracts
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Interfaces
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IImpactTheoryFoundersKey.sol";
import "./IITFKPeer.sol";
import "./IITFKFreeMintable.sol";

abstract contract ITFKFreeMintable is ERC165, ERC721 {
    IImpactTheoryFoundersKey public itfk;
    IITFKPeer public itfkPeer;

    constructor(address _itfkContractAddress, address _itfkPeerContractAddress)
    {
        itfk = IImpactTheoryFoundersKey(_itfkContractAddress);
        itfkPeer = IITFKPeer(_itfkPeerContractAddress);
    }

    function fkMint(
        uint256[] memory _fkPresaleTokenIds,
        uint256[] memory _fkFreeMintTokenIds,
        uint32 _amount,
        string memory _nonce,
        bytes memory _signature
    ) external payable virtual;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IITFKFreeMintable).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}