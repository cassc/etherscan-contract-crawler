// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Bridge.sol";

contract BridgeFactory {
    enum PROJECTSTATUS {
        APPROVED,
        PENDING,
        REJECTED
    }

    struct Company {
        uint256 id;
        address wallet;
        address admin;
        string ipfsHash;
    }

    struct Project {
        uint256 projectId;
        uint256 companyId;
        address projectAddress;
        PROJECTSTATUS status;
        string detailsHash;
    }

    uint256 public companyNumber = 1;
    uint256 public projectNumber = 1;
    address public feeWalletAddress;
    address public tokenAddress;

    event CompanyCreated(uint256 companyId, address wallet, address admin, string ipfsHash);
    event ProjectApproved(address projAddress, address owner, uint256 projectId, uint256 feewalletPercentage);
    event ProjectSubmited(uint256 companyId, uint256 projectId, string detailHash);
    event ProjectRejected(uint256 projectId);
    event FeeWalletUpdated(address oldWallet, address newWallet);
    event CompanyDetailUpdated(uint256 companyId, PARAMETER parameter, address value);
    event ProjectHashUpdated(uint256 projectId, string detailHash);
    event AddedAdmin(address newAdmin);
    event RemovedAdmin(address oldAdmin);

    mapping(uint256 => Company) public companies;
    mapping(address => uint256) public companyOwner;
    mapping(uint256 => Project) public projects;
    mapping(address => bool) public isAdmin;

    enum PARAMETER {
        WALLET,
        ADMIN
    }

    constructor(address _feeWalletAddress, address _tokenAddress) {
        isAdmin[msg.sender] = true;
        feeWalletAddress = _feeWalletAddress;
        tokenAddress = _tokenAddress;

        emit FeeWalletUpdated(address(0), _feeWalletAddress);
        emit AddedAdmin(msg.sender);
    }

    function approveProject(
        uint256 _projectId,
        //Position 0 - is pre sale; Position 1 - is easy transfer
        bool[] memory _booleans,
        //Position 0 - token name; Position 1 - token symbol; Position 2 - token uri; Position 3 - ipfsHash;
        string[] memory _tokenDetails,
        //Position 0 - max supply; Position 1 - max per wallet; Position 2 - NFT Price; Position 3 - max pre sale;
        uint256[] memory _quantities,
        bytes32 _merkleRoot,
        uint256[] memory _discountQuantites,
        uint256[] memory _discountPercentages,
        address[] memory _mintingDistributionRecipients,
        uint256[] memory _recipientsMintingPercentage,
        address _newOwner
    ) public isBridgeAdmin {
        Project storage projectStruct = projects[_projectId];
        projectStruct.status = PROJECTSTATUS.APPROVED;
        require(_discountQuantites.length == _discountPercentages.length, "INVALID DISCOUNT INPUTS");
        require(
            _mintingDistributionRecipients.length == _recipientsMintingPercentage.length,
            "INVALID DISTRIBUTION INPUTS"
        );
        uint256 totalPercentage;
        for (uint256 i = 0; i < _recipientsMintingPercentage.length; i++) {
            totalPercentage += _recipientsMintingPercentage[i];
        }
        require(totalPercentage == 100, "INVALID DISTRIBUTION PERCENTAGES");

        Bridge project = new Bridge(
            projectStruct.projectId,
            tokenAddress,
            _booleans,
            _tokenDetails,
            _quantities,
            _merkleRoot,
            _discountQuantites,
            _discountPercentages,
            _mintingDistributionRecipients,
            _recipientsMintingPercentage,
            _newOwner
        );

        projectStruct.projectAddress = address(project);
        uint256 feeWalletAddressPercentage = 0;

        projectStruct.detailsHash = _tokenDetails[3];

        for (uint256 i = 0; i < _recipientsMintingPercentage.length; i++) {
            if (_mintingDistributionRecipients[i] == feeWalletAddress) {
                feeWalletAddressPercentage = _recipientsMintingPercentage[i];
            }
        }

        emit ProjectApproved(address(project), _newOwner, projectStruct.projectId, feeWalletAddressPercentage);
    }

    function submitProject(uint256 _companyId, string memory _ipfsHash) public {
        Company storage company = companies[_companyId];
        require(msg.sender == company.admin, "Not company admin");

        projects[projectNumber] = Project({
            projectId: projectNumber,
            companyId: _companyId,
            projectAddress: address(0),
            status: PROJECTSTATUS.PENDING,
            detailsHash: _ipfsHash
        });

        emit ProjectSubmited(_companyId, projectNumber, _ipfsHash);
        projectNumber++;
    }

    function createCompany(
        address _wallet,
        address _admin,
        string memory _ipfsHash
    ) public isBridgeAdmin {
        require(companyOwner[_admin] == 0, "WALLET REGISTERED A COMPANY");
        require(_wallet != address(0), "zero address");
        require(_admin != address(0), "zero address");

        companyOwner[_admin] = companyNumber;
        companies[companyNumber] = Company({id: companyNumber, wallet: _wallet, admin: _admin, ipfsHash: _ipfsHash});
        emit CompanyCreated(companyNumber, _wallet, _admin, _ipfsHash);

        companyNumber++;
    }

    function rejectProject(uint256 _projectId) public isBridgeAdmin {
        require(_projectId <= projectNumber, "Invalid project id");
        Project storage project = projects[_projectId];
        require(project.status == PROJECTSTATUS.PENDING, "PROJECT NOT PENDING");
        project.status = PROJECTSTATUS.REJECTED;
        emit ProjectRejected(_projectId);
    }

    function updateCompanyDetail(
        uint256 _companyId,
        PARAMETER _parameter,
        address value
    ) public {
        require(_companyId < companyNumber, "COMPANY NON EXISTANT");
        require(value != address(0), "zero address");

        Company storage company = companies[_companyId];
        require(msg.sender == company.admin, "Not company admin");

        if (_parameter == PARAMETER.WALLET) {
            company.wallet = value;
        } else if (_parameter == PARAMETER.ADMIN) {
            company.admin = value;
            companyOwner[value] = _companyId;
            delete companyOwner[msg.sender];
        }

        emit CompanyDetailUpdated(_companyId, _parameter, value);
    }

    function updateFeeWalletAddress(address _wallet) public isBridgeAdmin {
        require(_wallet != address(0), "zero address");
        address oldWallet = feeWalletAddress;
        feeWalletAddress = _wallet;
        emit FeeWalletUpdated(oldWallet, _wallet);
    }

    function updateProjectHash(uint256 _projectId, string memory _newHash) public isBridgeAdmin {
        projects[_projectId].detailsHash = _newHash;

        emit ProjectHashUpdated(_projectId, _newHash);
    }

    function getProjectAddress(uint256 _id) public view returns (address) {
        require(_id <= projectNumber, "COMPANY NON EXISTANT");
        return projects[_id].projectAddress;
    }

    function addAdmin(address _newAdmin) public isBridgeAdmin {
        require(_newAdmin != address(0), "Cannot add zero address");
        isAdmin[_newAdmin] = true;
        emit AddedAdmin(_newAdmin);
    }

    function removeAdmin(address _oldAdmin) public isBridgeAdmin {
        require(isAdmin[_oldAdmin] == true, "Address not an admin");
        isAdmin[_oldAdmin] = false;
        emit RemovedAdmin(_oldAdmin);
    }

    function _verifyAdmin(address sender) internal view {
        require(isAdmin[sender] == true, "Not bridge admin");
    }

    modifier isBridgeAdmin() {
        _verifyAdmin(msg.sender);
        _;
    }
}