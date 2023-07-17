// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./RegistryBase.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../interfaces/IService.sol";
import "../interfaces/IPool.sol";
import "../interfaces/registry/ICompaniesRegistry.sol";

/**
 *@title Companies Registry Contract
 *@notice This contract is a section of the Registry contract designed for storing and manipulating companies listed for sale.
 *@dev With the help of this contract, one can find out the number of companies available for purchase in a specific jurisdiction and their corresponding prices. Here, an isolated but still dependent role-based model based on Access Control from OZ is implemented, with the contract Service playing a crucial role.
 */
abstract contract CompaniesRegistry is RegistryBase, ICompaniesRegistry {
    // CONSTANTS

    /**
    * @notice Hash code for the COMPANIES_MANAGER role in the OpenZeppelin (OZ) Access Control model.
    * @dev This role is intended for working with the showcase of companies available for purchase and can also add and modify the link to the organization's charter. It operates only within the Registry contract through a separate AccessControl model from OpenZeppelin with standard methods: grantRole, revokeRole, setRole.
    Methods:
    - CompaniesRegistry.sol:createCompany(CompanyInfo calldata info) - creating a company with specified immutable data and its price in ETH, deploying the contract with a temporary owner in the form of the Registry contract proxy address. After calling such a method, the company immediately becomes available for purchase.
    - CompaniesRegistry.sol:deleteCompany(uint256 jurisdiction, uint256 entityType, uint256 id) - deleting a company record (removing it from sale without the possibility of recovery).
    - CompaniesRegistry.sol:updateCompanyFee(uint256 jurisdiction, uint256 entityType, uint256 id, uint256 fee) - changing the price of an unsold company (prices are set in ETH).
    - Pool.sol:setOAUrl(string memory _uri) - changing the link to the pool's operating agreement.
    Storage, assignment, and revocation of the role are carried out using the standard methods of the AccessControl model from OpenZeppelin: grantRole, revokeRole, setRole. The holder of the standard ADMIN_ROLE of this contract can manage this role (by default - the address that deployed the contract).
    */
    bytes32 public constant COMPANIES_MANAGER_ROLE =
        keccak256("COMPANIES_MANAGER");

    // STORAGE

    /// @dev The embedded mappings form a construction, when accessed using two keys at once [jurisdiction][EntityType], you can get lists of ordinal numbers of company records added by managers. These serial numbers can be used when contacting mapping companies to obtain public legal information about the company awaiting purchase by the client.
    mapping(uint256 => mapping(uint256 => uint256[])) public queue;

    /// @dev In this mapping, public legal information is stored about companies that are ready to be acquired by the client and start working as a DAO. The appeal takes place according to the serial number - the key. A list of keys for each type of company and each jurisdiction can be obtained in the queue mapping.
    mapping(uint256 => CompanyInfo) public companies;

    /// @dev The last sequential number of the last record created by managers in the queue with company data is stored here.
    uint256 public lastCompanyIndex;

    /// @dev Status of combination of (jurisdiction, entityType, EIN) existing
    mapping(bytes32 => uint256) public companyIndex;

    // EVENTS

    /**
     * @dev An event emitted when a manager creates a new company. After this event, the company immediately becomes available for purchase.
     * @param index Company list index.
     * @param poolAddress The contract pool address computed based on the bytecode and initial arguments.
     */
    event CompanyCreated(uint256 index, address poolAddress);

    /**
     * @dev An event emitted when a company is delisted from sale. This is one of the mechanisms to modify legal information regarding the company.
     * @param metadataIndex Company metadata index.
     */
    event CompanyDeleted(uint256 metadataIndex);

    /**
     * @dev The event is issued when the manager changes the price of an already created company ready for purchase by the client.
     * @param jurisdiction The digital code of the jurisdiction.
     * @param entityType The digital code of the organization type.
     * @param id Queue index
     * @param fee Fee for createPool
     */
    event CompanyFeeUpdated(
        uint256 jurisdiction,
        uint256 entityType,
        uint256 id,
        uint256 fee
    );

    // PUBLIC FUNCTIONS

    /**
     * @dev Create company record - A method for creating a new company record, including its legal data and the sale price.
     * @param info Company Info
     */
    function createCompany(
        CompanyInfo calldata info
    ) public onlyRole(COMPANIES_MANAGER_ROLE) {
        // Check that company data is valid
        require(
            info.jurisdiction > 0 &&
                bytes(info.ein).length != 0 &&
                bytes(info.dateOfIncorporation).length != 0 &&
                info.entityType > 0,
            ExceptionsLibrary.VALUE_ZERO
        );

        // Check that such company does not exist yet and mark it as existing
        bytes32 companyHash = keccak256(
            abi.encodePacked(info.jurisdiction, info.entityType, info.ein)
        );
        require(companyIndex[companyHash] == 0, ExceptionsLibrary.INVALID_EIN);
        uint256 index = ++lastCompanyIndex;
        companyIndex[companyHash] = index;

        // Add record to list
        companies[index] = info;

        // Add record to queue
        queue[info.jurisdiction][info.entityType].push(index);

        // Emit event
        emit CompanyCreated(index, IService(service).getPoolAddress(info));

        //Create PoolContract
        IService(service).createPool(info);

        IRegistry(address(this)).log(
            msg.sender,
            address(this),
            0,
            abi.encodeWithSelector(
                ICompaniesRegistry.createCompany.selector,
                info
            )
        );
    }

    /**
     * @notice Lock company record
     * @dev Booking the company for the buyer. During the acquisition of a company, this method searches for a free company at the request of the client (jurisdiction and type of organization), if such exist in the company’s storage reserve, then the method selects the last of the added companies, extracts its record data and sends it as a response for further work of the Service contract, removes its record from the Registry.
     * @param jurisdiction Цифровой код юрисдикции
     * @param entityType Цифровой код типа организакции
     * @return info Company info
     */
    function lockCompany(
        uint256 jurisdiction,
        uint256 entityType
    ) external onlyService returns (CompanyInfo memory info) {
        // Check that company is available
        uint256 queueLength = queue[jurisdiction][entityType].length;
        require(queueLength > 0, ExceptionsLibrary.NO_COMPANY);

        // Get index and pop queue
        uint256 index = queue[jurisdiction][entityType][queueLength - 1];
        queue[jurisdiction][entityType].pop();

        // Get company info and remove it from list
        info = companies[index];
        delete companies[index];
    }

    /**
     * @dev This method removes a record from the queue of created companies.
     * @param jurisdiction The digital code of the jurisdiction.
     * @param entityType The digital code of the organization type.
     * @param id Queue index.
     */
    function deleteCompany(
        uint256 jurisdiction,
        uint256 entityType,
        uint256 id
    ) external onlyRole(COMPANIES_MANAGER_ROLE) {
        // Get index and pop queue
        uint256 index = queue[jurisdiction][entityType][id];
        uint256 lastId = queue[jurisdiction][entityType].length - 1;
        queue[jurisdiction][entityType][id] = queue[jurisdiction][entityType][
            lastId
        ];
        queue[jurisdiction][entityType].pop();

        // Remove company from list
        string memory ein = companies[index].ein;
        delete companies[index];

        // Mark company as not existing
        bytes32 companyHash = keccak256(
            abi.encodePacked(jurisdiction, entityType, ein)
        );
        companyIndex[companyHash] = 0;

        // Emit event
        emit CompanyDeleted(id);
    }

    /**
     * @dev The method that the manager uses to change the value of the company already added earlier in the Registry.
     * @param jurisdiction The digital code of the jurisdiction.
     * @param entityType The digital code of the organization type.
     * @param id Queue index.
     *@ param fee Fee to update.
     */
    function updateCompanyFee(
        uint256 jurisdiction,
        uint256 entityType,
        uint256 id,
        uint256 fee
    ) external onlyRole(COMPANIES_MANAGER_ROLE) {
        // Update fee
        uint256 index = queue[jurisdiction][entityType][id];
        companies[index].fee = fee;

        // Emit event
        emit CompanyFeeUpdated(jurisdiction, entityType, id, fee);
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev This view method is designed to find out whether there is at least one company available for purchase for the jurisdiction and type of organization selected by the user.
     * @param jurisdiction The digital code of the jurisdiction.
     * @param entityType The digital code of the organization type.
     * @return "True" if at least one company is available
     */
    function companyAvailable(
        uint256 jurisdiction,
        uint256 entityType
    ) external view returns (bool) {
        return queue[jurisdiction][entityType].length > 0;
    }

    /**
     * @dev Get company pool address by metadata
     * @param jurisdiction Jurisdiction
     * @param entityType Entity type
     * @param id Queue id
     * @return Future company's pool address
     */
    function getCompanyPoolAddress(
        uint256 jurisdiction,
        uint256 entityType,
        uint256 id
    ) public view returns (address) {
        uint256 index = queue[jurisdiction][entityType][id];
        return IService(service).getPoolAddress(companies[index]);
    }

    /**
     * @dev This method allows obtaining all the data of a company, including its legal data, that is still available for sale.
     * @param jurisdiction The digital code of the jurisdiction.
     * @param entityType The digital code of the organization type.
     * @param ein The government registration number.
     * @return CompanyInfo The company data.
     */
    function getCompany(
        uint256 jurisdiction,
        uint256 entityType,
        string calldata ein
    ) external view returns (CompanyInfo memory) {
        bytes32 companyHash = keccak256(
            abi.encodePacked(jurisdiction, entityType, ein)
        );
        return companies[companyIndex[companyHash]];
    }

    /**
     * @dev This method allows obtaining the contract address of a company that is available for sale and meets the conditions based on its jurisdiction and entity type.
     * @param jurisdiction The digital code of the jurisdiction.
     * @param entityType The digital code of the organization type.
     * @return address The contract pool address.
     */
    function getAvailableCompanyAddress(
        uint256 jurisdiction,
        uint256 entityType
    ) external view returns (address) {
        // Check that company is available
        uint256 queueLength = queue[jurisdiction][entityType].length;
        require(queueLength > 0, ExceptionsLibrary.NO_COMPANY);

        // Get index
        uint256 index = queue[jurisdiction][entityType][queueLength - 1];

        address companyAddress = IService(service).getPoolAddress(
            companies[index]
        );

        return companyAddress;
    }

    /**
     * @notice Method for replacing the reference to the Operating Agreement and legal data of a company in the contract's memory.
     * @dev This is a special method for the manager to service contracts of already acquired companies. To correct data in a company that has not been acquired yet, the record should be deleted and a new one created.
     * @param pool The contract pool address.
     * @param _jurisdiction The digital code of the jurisdiction.
     * @param _entityType The digital code of the organization type.
     * @param _ein The government registration number.
     * @param _dateOfIncorporation The date of incorporation.
     * @param _OAuri Operating Agreement URL.
     */
    function setCompanyInfoForPool(
        IPool pool,
        uint256 _jurisdiction,
        uint256 _entityType,
        string memory _ein,
        string memory _dateOfIncorporation,
        string memory _OAuri
    ) external onlyRole(COMPANIES_MANAGER_ROLE) {
        pool.setCompanyInfo(
            _jurisdiction,
            _entityType,
            _ein,
            _dateOfIncorporation,
            _OAuri
        );
    }
}