// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../utils/CopyrightInfo.sol";
import "../interfaces/IExternalRegister.sol";
import "hardhat/console.sol";

error CopyrightRegistry_Is_Not_Policy_Info();
error CopyrightRegistry_Fail_To_Add_Holder();
error CopyrightRegistry_Fail_To_Add_Or_Update_Holder();
error CopyrightRegistry_Fail_To_Update_Holder();
error CopyrightRegistry_Fail_To_Remove_Holder();

abstract contract CopyrightRegistry {
    /**
     * ==================================================
     * Structs
     * ==================================================
     * @dev Need to handle structs in CopyrightInfo with methods in CopyrightInfo
     */
    using CopyrightInfo for CopyrightInfo.CopyrightHolderSet;
    using CopyrightInfo for CopyrightInfo.CopyrightHolder;
    using CopyrightInfo for CopyrightInfo.CopyrightRegistry;

    /**
     * ==================================================
     * Storages
     * ==================================================
     */

    /**
     * @dev available policy lists represented as ID
     * @dev mapping from ID to version number
     * @notice it uses 0 as default
     */
    mapping(uint16 => uint256) public policyList;

    /// @dev short string for copyright summary
    mapping(uint16 => string) public policySummary;

    /// @dev IPFS hash where policy document for copyright detail exists
    mapping(uint16 => string) public policyDocument;

    struct Policy {
        uint256 policyVersion;
        string policySummary;
        string policyDocument;
    }
    /**
     * @dev policy registered for token or contract with priority
     * [Priority]
     * 1. If contract has external policty, another policy below would be ignored
     * 2. If token has policy, default policy below would be ignored
     * 3. If contract has policy, another policy below would be ignored
     * 4. If there is no policy, default policy would be applied
     *
     * @dev do not register contract to tokenExceptionRegister
     * @dev do not register token to contractExternalRegister
     */

    mapping(bytes32 => CopyrightInfo.CopyrightRegistry) private policyRegistry;
    mapping(bytes32 => CopyrightInfo.CopyrightHolderSet)
        private copyrightHolders;

    /**
     * ==================================================
     * Policy Management Functions
     * ==================================================
     */

    /**
     * @notice It is a function that shows the policy corresponding to a specific id
     * @param id The policy id that want to know
     * @return policy The policy informations for the policy id
     */
    function getPolicyFromId(uint16 id)
        public
        view
        returns (Policy memory policy)
    {
        policy.policyVersion = policyList[id];
        policy.policySummary = policySummary[id];
        policy.policyDocument = policyDocument[id];
    }

    /**
     * @dev This is the internal function that registers the policy
     */
    function _registerPolicy(
        uint16 id,
        string memory summary,
        string memory IPFSHash
    ) internal {
        policyList[id]++;
        policySummary[id] = summary;
        policyDocument[id] = IPFSHash;
    }

    /**
     * @dev This is the internal function that deprecates the policy
     */
    function _deprecatePolicy(uint16 id) internal {
        delete policyList[id];
        delete policySummary[id];
        delete policyDocument[id];
    }

    /**
     * ==================================================
     * CopyrightInfo Registry Functions
     * ==================================================
     */

    /**
     * @notice It is a function that shows the policy corresponding to a specific id or contract
     * @notice If the tokenId is 0, It correspond to a contract
     * @param contractAddress The contractAddress of token
     * @return id The policy id
     * @return version The version of policy
     * @return summary THe summary of policy
     * @return ipfsHash The ipfsHash of policy
     */
    function getPolicyInfo(address contractAddress)
        public
        view
        returns (
            uint16 id,
            uint256 version,
            string memory summary,
            string memory ipfsHash
        )
    {
        bytes32 hash = _getContractHash(contractAddress);
        id = policyRegistry[hash].policy;
        version = policyList[id];
        if (version == 0) {
            revert CopyrightRegistry_Is_Not_Policy_Info();
        }
        summary = policySummary[id];
        ipfsHash = policyDocument[id];
    }

    /**
     * @notice It is a function that get the policy holders corresponding to a specific id
     * @param contractAddress The contractAddress of token
     * @return holders The holders of policy
     */
    function getPolicyHolders(address contractAddress)
        public
        view
        returns (CopyrightInfo.CopyrightHolder[] memory)
    {
        bytes32 hash;
        CopyrightInfo.CopyrightRegistry memory registry;

        hash = _getContractHash(contractAddress);
        registry = policyRegistry[hash];

        return CopyrightInfo.values(copyrightHolders[hash]);
    }

    /**
     * @notice It is a function that allows you to know the copyright registration information registered in the contract
     */
    function getContractPolicy(address contractAddress)
        public
        view
        returns (CopyrightInfo.CopyrightRegistry memory)
    {
        bytes32 hash = _getContractHash(contractAddress);
        return policyRegistry[hash];
    }

    /**
     * @dev It is an internal function that can get policy registration information with hash
     */
    function _getPolicyWithHash(bytes32 hash)
        internal
        view
        returns (CopyrightInfo.CopyrightRegistry memory)
    {
        return policyRegistry[hash];
    }

    /**
     * @dev  It is an internal function that can set policy registration information with hash
     */
    function _setPolicyWithHash(
        bytes32 hash,
        uint40 lockup,
        uint40 appliedAt,
        uint16 policy
    ) internal {
        if (policyList[policy] == 0) {
            revert CopyrightRegistry_Is_Not_Policy_Info();
        }
        CopyrightInfo.CopyrightRegistry memory registry = policyRegistry[hash];

        registry.lockup = lockup;
        registry.appliedAt = appliedAt;
        registry.policy = policy;
        policyRegistry[hash] = registry;
    }

    /**
     * @dev  It is an internal function that remove the policy of contract through contract address
     */
    function _removeContractPolicy(address contractAddress) internal {
        bytes32 hash = _getContractHash(contractAddress);
        _removePolicyWithHash(hash);
    }

    /**
     * @dev  It is an internal function that remove the policy of contract or token through hash
     */
    function _removePolicyWithHash(bytes32 hash) internal {
        delete policyRegistry[hash];
        delete copyrightHolders[hash];
    }

    /**
     * ==================================================
     * CopyrightHolder Functions
     * ==================================================
     */

    /**
     * @notice It is a function that shows the copyright holders corresponding to a specific id or contract
     * @notice If the tokenId is 0, It correspond to a contract
     * @param contractAddress s
     * @param holder The holder of contract of token or contract
     * @return account The holder of contract of token or contract
     * @return manageFlag The manage flag
     * @return grantFlag The grant flag
     * @return excuteFlag The excute flag
     * @return customFlag The custom flag
     * @return reservedFlag The reserved flag
     */
    function getCopyrightHolderAtAddress(
        address contractAddress,
        address holder
    )
        public
        view
        returns (
            address account,
            uint24 manageFlag,
            uint24 grantFlag,
            uint24 excuteFlag,
            uint16 customFlag,
            uint8 reservedFlag
        )
    {
        CopyrightInfo.CopyrightHolder memory _copyrightHolder = CopyrightInfo
            .valueAtAddress(
                copyrightHolders[_getContractHash(contractAddress)],
                holder
            );

        (
            account,
            manageFlag,
            grantFlag,
            excuteFlag,
            customFlag,
            reservedFlag
        ) = CopyrightInfo.resolveCopyrightHolder(_copyrightHolder);
    }

    /**
     * @dev Its's internal function that get holder with hash and account
     */
    function _getHolderAtAddressWithHash(bytes32 hash, address account)
        internal
        view
        returns (CopyrightInfo.CopyrightHolder memory)
    {
        return CopyrightInfo.valueAtAddress(copyrightHolders[hash], account);
    }

    /**
     * @dev Its's internal function that add holder with hash
     */
    function _addCopyrightHolderWithHash(
        bytes32 hash,
        CopyrightInfo.CopyrightHolder memory holder
    ) internal {
        /// It will return true if success to add
        if (!CopyrightInfo.add(copyrightHolders[hash], holder)) {
            revert CopyrightRegistry_Fail_To_Add_Holder();
        }
    }

    /**
     * @dev Its's internal function that add holder with holder set
     */
    function _addHolderWithHolderSet(
        CopyrightInfo.CopyrightHolderSet storage holderSet,
        CopyrightInfo.CopyrightHolder memory holder
    ) internal {
        /// It will return true if success to add
        if (!CopyrightInfo.add(holderSet, holder)) {
            revert CopyrightRegistry_Fail_To_Add_Holder();
        }
    }

    /**
     * @dev Its's internal function that add or update holder with hash
     */
    function _addOrUpdateHolderWithHash(
        bytes32 hash,
        CopyrightInfo.CopyrightHolder memory holder
    ) internal {
        /// It will return true if success to add
        if (!CopyrightInfo.addOrUpdate(copyrightHolders[hash], holder)) {
            revert CopyrightRegistry_Fail_To_Add_Or_Update_Holder();
        }
    }

    /**
     * @dev Its's internal function that add of update holer with holder set
     */
    function _addOrUpdateHolderWithHolderSet(
        CopyrightInfo.CopyrightHolderSet storage holderSet,
        CopyrightInfo.CopyrightHolder memory holder
    ) internal {
        /// It will return true if success to add
        if (!CopyrightInfo.addOrUpdate(holderSet, holder)) {
            revert CopyrightRegistry_Fail_To_Add_Or_Update_Holder();
        }
    }

    /**
     * @dev Its's internal function that update holer with hash
     */
    function _updateHolderWithHash(
        bytes32 hash,
        CopyrightInfo.CopyrightHolder memory holder
    ) internal {
        /// It will return true if success to add
        if (!CopyrightInfo.update(copyrightHolders[hash], holder)) {
            revert CopyrightRegistry_Fail_To_Update_Holder();
        }
    }

    /**
     * @dev Its's internal function that update holer with holder set
     */
    function _updateHolderWithHolderSet(
        CopyrightInfo.CopyrightHolderSet storage holderSet,
        CopyrightInfo.CopyrightHolder memory holder
    ) internal {
        /// It will return true if success to add
        if (!CopyrightInfo.update(holderSet, holder)) {
            revert CopyrightRegistry_Fail_To_Update_Holder();
        }
    }

    /**
     * @dev Its's internal function that remove holer with hash
     */
    function _removeHolderWithHash(bytes32 hash, address account) internal {
        /// @dev remove method find value only with user address
        /// @dev so param with 0 value fields could not be a bug
        /// it will return true if removed succesfully
        if (!CopyrightInfo.remove(copyrightHolders[hash], account)) {
            revert CopyrightRegistry_Fail_To_Remove_Holder();
        }
    }

    /**
     * @dev Its's internal function that remove holer with holder set
     */
    function _removeHolderWithHolderSet(
        CopyrightInfo.CopyrightHolderSet storage holderSet,
        address account
    ) internal {
        /// @dev remove method find value only with user address
        /// @dev so param with 0 value fields could not be a bug
        /// it will return true if removed succesfully
        if (!CopyrightInfo.remove(holderSet, account)) {
            revert CopyrightRegistry_Fail_To_Remove_Holder();
        }
    }

    /**
     * ==================================================
     * Hash Utils
     * ==================================================
     */

    /**
     * @dev It.s internal function that get contract hash from contract address
     */
    function _getContractHash(address contractAddress)
        internal
        pure
        returns (bytes32 hash)
    {
        hash = keccak256(abi.encodePacked(uint256(uint160(contractAddress))));
    }
}