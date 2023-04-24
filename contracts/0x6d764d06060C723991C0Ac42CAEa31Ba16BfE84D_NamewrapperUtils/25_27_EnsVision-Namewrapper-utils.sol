// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "ens-contracts/wrapper/NameWrapper.sol";
import "ens-contracts/ethregistrar/IBaseRegistrar.sol";
import "src/structs/WrappedDomainData.sol";
import "src/structs/DomainInfo.sol";

contract NamewrapperUtils {
    NameWrapper public immutable nameWrapper;
    IBaseRegistrar public immutable baseRegistrar;

    bytes32 private constant ETH_NODE =
        0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    constructor(NameWrapper _nameWrapper, IBaseRegistrar _baseRegistrar) {
        nameWrapper = _nameWrapper;
        baseRegistrar = _baseRegistrar;
    }

    /**
     * @notice getMultipleDomainExpiry
     * @dev Gets the expiry date of domains based
     * @dev on the heirarchy of nodes.
     * @param _names Array of array of domain names. ['hodl', 'pcc'] << hodl.pcc.eth
     */
    function getMultipleDomainExpiry(
        string[][] calldata _names
    ) external view returns (DomainInfo[] memory) {
        DomainInfo[] memory info = new DomainInfo[](_names.length);

        for (uint256 i = 0; i < _names.length; ) {
            unchecked {
                info[i] = getDomainExpiry(_names[i]);
                ++i;
            }
        }

        return info;
    }

    function getDomainExpiry(
        string[] calldata _names
    ) public view returns (DomainInfo memory) {
        DomainInfo memory info;
        bytes32[] memory nodes = getFamilyNodes(_names);

        for (uint256 i = nodes.length; i > 0; ) {
            unchecked {
                --i;
            }
            (info.owner, info.fuses, info.expiry) = nameWrapper.getData(
                uint256(nodes[i])
            );

            if (info.fuses & PARENT_CANNOT_CONTROL != 0) {
                info.node = nodes[i];
                return info;
            }
        }
    }

    // gets a heirarchy of nodes for a given domain
    function getFamilyNodes(
        string[] calldata _names
    ) public view returns (bytes32[] memory) {
        bytes32[] memory nodes = new bytes32[](_names.length);
        bytes32 node = ETH_NODE;
        for (uint256 i = _names.length; i > 0; ) {
            unchecked {
                --i;
            }
            node = keccak256(
                abi.encodePacked(node, keccak256(abi.encodePacked(_names[i])))
            );
            nodes[_names.length - i - 1] = node;
        }
        return nodes;
    }

    /**
     * batchTransferToWrap function performs a batch transfer of labels to the name wrapper contract.
     *
     * @param _ids Array of uint256 containing ids of the ENS tokens.
     * @param _data Array of bytes containing function data of the ENS being wrapped.
     */
    function batchTransferToWrap(
        uint256[] calldata _ids,
        bytes[] calldata _data
    ) external {
        address wrapper = address(nameWrapper);

        // Iterate through the labels
        for (uint i = 0; i < _ids.length; ) {
            unchecked {
                // Transfer label to the name wrapper contract
                baseRegistrar.safeTransferFrom(
                    msg.sender,
                    wrapper,
                    _ids[i],
                    _data[i]
                );

                // Increment counter
                ++i;
            }
        }
    }

    // helper function to get namehash / id for wrapped and none wrapped domains
    function getDomainHash(
        string calldata _label
    ) external pure returns (bytes32 namewrapperHash, bytes32 ensNamehash) {
        string[] memory domainArray = new string[](2);

        domainArray[0] = _label;
        domainArray[1] = "eth";
        namewrapperHash = 0x0;

        for (uint256 i = domainArray.length; i > 0; ) {
            unchecked {
                --i;
            }
            namewrapperHash = keccak256(
                abi.encodePacked(
                    namewrapperHash,
                    keccak256(abi.encodePacked(domainArray[i]))
                )
            );
        }

        ensNamehash = keccak256(abi.encodePacked(_label));
    }

    // helper function to get namehash for subdomains.
    function getSubdomainHash(
        bytes32 _wrapperNode,
        string calldata _subdomain
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _wrapperNode,
                    keccak256(abi.encodePacked(_subdomain))
                )
            );
    }

    /**
     * Batch queries the owner of a list of wrapped domain names.
     * @param _ids The list of wrapped domain names to query.
     * @return _owners The list of owners for the given wrapped domain names.
     *              If the domain is not wrapped then the owner will be the zero address.
     */
    function batchQueryWrappedDomains(
        uint256[] calldata _ids // The list of wrapped domain names to query.
    ) external view returns (address[] memory _owners) {
        // The list of owners for the given wrapped domain names.
        _owners = new address[](_ids.length); // Initialize the list of owners to the same length as the list of wrapped domain names.

        // Iterate through each wrapped domain name in the list.
        for (uint i = 0; i < _ids.length; ) {
            // Call the `getData` function of the `nameWrapper` contract, passing in the current wrapped domain name id.
            // The function returns a tuple containing the owner of the wrapped domain name, as well as other data.
            // We only care about the owner.
            unchecked {
                // Assign the owner of the current wrapped domain name to the corresponding position in the list of owners.
                (_owners[i], , ) = nameWrapper.getData(_ids[i]);
                // Increment the loop counter.
                ++i;
            }
        }
    }

    /**
     * getData function retrieves data for the given labels.
     *
     * @param _labelArray Array of labels for which data needs to be retrieved.
     * @param _owner The owner of the ENS token.
     * @param _ownerControlledFuses Fuses to be applied to all the Namewrapper.
     * @param _resolver The resolver chosen resolver for the labels.
     * @return _data Array of bytes containing function data for Namewrapper.
     * @return _ids Array of uint256 ens token ids for the given labels.
     */
    function getDataArrays(
        string[] calldata _labelArray,
        address _owner,
        uint16 _ownerControlledFuses,
        address _resolver
    ) external pure returns (bytes[] memory _data, uint256[] memory _ids) {
        // Initialize arrays to store data and ids
        _ids = new uint256[](_labelArray.length);
        _data = new bytes[](_labelArray.length);

        // Iterate through the labels
        for (uint256 i; i < _labelArray.length; i++) {
            // Calculate id for the label
            _ids[i] = uint256(keccak256(abi.encodePacked(_labelArray[i])));

            // Encode data for the label
            _data[i] = getData(
                _labelArray[i],
                _owner,
                _ownerControlledFuses,
                _resolver
            );
        }
    }

    function getData(
        string calldata _label,
        address _owner,
        uint16 _ownerControlledFuses,
        address _resolver
    ) public pure returns (bytes memory _data) {
        _data = abi.encode(_label, _owner, _ownerControlledFuses, _resolver);
    }

    function getWrappedDomainsData(
        uint256[] calldata _ids
    ) public view returns (WrappedDomainData[] memory) {
        WrappedDomainData[] memory data = new WrappedDomainData[](_ids.length);
        for (uint i = 0; i < _ids.length; ) {
            (data[i].owner, data[i].fuses, data[i].expiry) = nameWrapper
                .getData(_ids[i]);

            unchecked {
                ++i;
            }
        }
        return data;
    }
}