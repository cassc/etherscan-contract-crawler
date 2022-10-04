// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/erc721extendable/contracts/extensions/base/mint/MintLogic.sol";
import "@violetprotocol/erc721extendable/contracts/extensions/metadata/setTokenURI/IBasicSetTokenURILogic.sol";
import "@violetprotocol/erc721extendable/contracts/extensions/metadata/getter/MetadataGetterLogic.sol";
import { HumanboundPermissionState, HumanboundPermissionStorage } from "../../storage/HumanboundPermissionStorage.sol";
import { ContractMetadataState, ContractMetadataStorage } from "../../storage/ContractMetadataStorage.sol";
import "../EAT/AccessTokenConsumerExtension.sol";
import "./IContractMetadata.sol";

contract HumanboundTokenURILogic is MetadataGetterLogic, BasicSetTokenURIExtension, ContractMetadataExtension {
    event BaseURISet(string newBaseURI);
    event TokenURISet(uint256 tokenId, string newTokenURI);
    event ContractURISet(string newContractURI);

    modifier onlyOperator() virtual {
        HumanboundPermissionState storage state = HumanboundPermissionStorage._getState();
        require(
            _lastExternalCaller() == state.operator || _lastCaller() == state.operator,
            "HumanboundTokenURILogic: unauthorised"
        );
        _;
    }

    function contractURI() public virtual override(IContractMetadata) returns (string memory) {
        ContractMetadataState storage state = ContractMetadataStorage._getState();
        return state.contractURI;
    }

    function setContractURI(string memory uri) public virtual override(IContractMetadata) onlyOperator {
        ContractMetadataState storage state = ContractMetadataStorage._getState();
        state.contractURI = uri;

        emit ContractURISet(uri);
    }

    function tokenURI(uint256 tokenId) public virtual override(MetadataGetterLogic) returns (string memory) {
        // See {IERC721URIStorage-tokenURI}
        require(IGetterLogic(address(this))._exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        TokenURIState storage state = TokenURIStorage._getState();

        string memory _tokenURI = state._tokenURIs[tokenId];
        // If tokenURI is set, return it
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        string memory base = _baseURI();
        // If there is no token URI, return the base URI as a generic shared resource
        if (bytes(base).length > 0) {
            return _baseURI();
        }

        // If neither are set, return blank
        return "";
    }

    function setBaseURI(string memory baseURI) public override onlyOperator {
        ISetTokenURILogic(address(this))._setBaseURI(baseURI);
        emit BaseURISet(baseURI);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public override onlyOperator {
        ISetTokenURILogic(address(this))._setTokenURI(tokenId, _tokenURI);
        emit TokenURISet(tokenId, _tokenURI);
    }

    function getSolidityInterface()
        public
        pure
        virtual
        override(BasicSetTokenURIExtension, MetadataGetterExtension, ContractMetadataExtension)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    BasicSetTokenURIExtension.getSolidityInterface(),
                    MetadataGetterExtension.getSolidityInterface(),
                    ContractMetadataExtension.getSolidityInterface()
                )
            );
    }

    function getInterface()
        public
        virtual
        override(BasicSetTokenURIExtension, MetadataGetterExtension, ContractMetadataExtension)
        returns (Interface[] memory interfaces)
    {
        interfaces = new Interface[](4);

        interfaces[0] = BasicSetTokenURIExtension.getInterface()[0];
        interfaces[1] = BasicSetTokenURIExtension.getInterface()[1];
        interfaces[2] = MetadataGetterExtension.getInterface()[0];
        interfaces[3] = ContractMetadataExtension.getInterface()[0];
    }
}