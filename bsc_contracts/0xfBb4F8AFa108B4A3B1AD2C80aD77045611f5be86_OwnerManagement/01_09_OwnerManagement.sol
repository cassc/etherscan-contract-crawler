// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.5;
pragma experimental ABIEncoderV2;

import "./DocumentStore.sol";
import "./IDocumentStoreInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnerManagement is Ownable {
    address manager;
    address[] private institutions;
    string[] private nameList;

    struct info {
        address contractAddress;
        string name;
        string email;
        string legalReference;
        string intentDeclaration;
        string host;
        uint256 expiredTime;
    }

    mapping(address => info) private instInfo;
    /// Check whether the institution is added or not
    mapping(bytes32 => mapping(address => bool)) private addressWhitelisted;
    /// Check whether the address is whitelisted;
    mapping(address => mapping(uint256 => bool)) private expiredTimeCheck;
    /// Check the registered expired time of the address;
    mapping(address => mapping(bytes32 => address)) private ownerOfContract;
    /// Check if the address owner is the owner the Document Store with given name
    mapping(address => uint256) private institutionIndex;

    event DocumentStoreDeployed(
        address indexed _instance,
        address indexed _creator
    );
    event AddressWhitelisted(address indexed _address, string _name);

    function _addInstitution() internal {
        address _institution = institutions[institutions.length - 1];
        instInfo[_institution].name = IDocumentStoreInterface(_institution)
            .getName();
        instInfo[_institution].email = IDocumentStoreInterface(_institution)
            .getEmail();
        instInfo[_institution].contractAddress = _institution;
        instInfo[_institution].legalReference = IDocumentStoreInterface(
            _institution
        ).getLegalReference();
        instInfo[_institution].intentDeclaration = IDocumentStoreInterface(
            _institution
        ).getIntentDeclaration();
        instInfo[_institution].host = IDocumentStoreInterface(_institution)
            .getHost();
        instInfo[_institution].expiredTime = IDocumentStoreInterface(
            _institution
        ).getExpiredTime();
        nameList.push(instInfo[_institution].name);
    }

    function whitelist(address _address, string memory _name) public onlyOwner {
        require(
            addressWhitelisted[keccak256(abi.encodePacked(_name))][_address] == false,
            "Error: Address has been whitelisted"
        );
        addressWhitelisted[keccak256(abi.encodePacked(_name))][_address] = true;
        emit AddressWhitelisted(_address, _name);
    }

    function deploy(
        string memory _name,
        string memory _email,
        string memory _legalReference,
        string memory _intentDeclaration,
        string memory _host,
        uint256 _time
    ) public onlyWhitelisted(_name) returns (address) {
        DocumentStore instance = new DocumentStore();
        instance.initialize(
            _name,
            _email,
            _legalReference,
            _intentDeclaration,
            _host,
            _time,
            msg.sender,
            address(this)
        );
        institutions.push(address(instance));
        institutionIndex[address(instance)] = institutions.length;
        _addInstitution();
        addressWhitelisted[keccak256(abi.encodePacked(_name))][msg.sender] = false;
        ownerOfContract[msg.sender][keccak256(abi.encodePacked(_name))] = address(instance);
        emit DocumentStoreDeployed(address(instance), msg.sender);
        return address(instance);
    }

    function getAddressByName(string memory _name)
        external
        view
        returns (address institution)
    {
        for (uint256 i; i < institutions.length; i++) {
            if (
                keccak256(abi.encodePacked(instInfo[institutions[i]].name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                institution = institutions[i];
                break;
            }
        }
    }

    function getInstInfo(address instAddress)
        external
        view
        returns (
            address _contractAddress,
            string memory _name,
            string memory _email,
            string memory _legalReference,
            string memory _intentDeclaration,
            string memory _host,
            uint256 _expiredTime
        )
    {
        _contractAddress = instInfo[instAddress].contractAddress;
        _name = instInfo[instAddress].name;
        _email = instInfo[instAddress].email;
        _legalReference = instInfo[instAddress].legalReference;
        _intentDeclaration = instInfo[instAddress].intentDeclaration;
        _host = instInfo[instAddress].host;
        _expiredTime = instInfo[instAddress].expiredTime;
    }

    function getInstitutions() external view returns (string[] memory) {
        return nameList;
    }

    function setName(address _contract, string memory _name)
        external
        institutionChecked(_contract)
    {
        require(
            msg.sender == _contract,
            "Error: Caller is not the institution"
        );
        instInfo[_contract].name = _name;
    }

    function setEmail(address _contract, string memory _email)
        external
        institutionChecked(_contract)
    {
        require(
            msg.sender == _contract,
            "Error: Caller is not the institution"
        );
        instInfo[_contract].email = _email;
    }

    function setLegalReference(address _contract, string memory _legalReference)
        external
        institutionChecked(_contract)
    {
        require(
            msg.sender == _contract,
            "Error: Caller is not the institution"
        );
        instInfo[_contract].legalReference = _legalReference;
    }

    function setIntentDeclaration(
        address _contract,
        string memory _intentDeclaration
    ) external institutionChecked(_contract) {
        require(
            msg.sender == _contract,
            "Error: Caller is not the institution"
        );
        instInfo[_contract].intentDeclaration = _intentDeclaration;
    }

    function setHost(address _contract, string memory _host)
        external
        institutionChecked(_contract)
    {
        require(
            msg.sender == _contract,
            "Error: Caller is not the institution"
        );
        instInfo[_contract].host = _host;
    }

    function setExpiredTime(address _contract, uint256 _time)
        external
        expiredTimeTrue(_contract, _time)
        institutionChecked(_contract)
    {
        require(
            msg.sender == _contract,
            "Error: Caller is not the institution"
        );
        instInfo[_contract].expiredTime = _time;
    }

    function setOwnerOfContract(
        address _oldOwner,
        address _newOwner,
        string memory _name
    ) external {
        require(
            ownerOfContract[_oldOwner][keccak256(abi.encodePacked(_name))] == msg.sender,
            "Error: Contract must exist and Caller must be the owner"
        );
        ownerOfContract[_oldOwner][keccak256(abi.encodePacked(_name))] = address(0);
        ownerOfContract[_newOwner][keccak256(abi.encodePacked(_name))] = msg.sender;
    }

    function approveExpiredTime(address _contract, uint256 _time)
        external
        onlyOwner
    {
        require(
            _time > instInfo[_contract].expiredTime,
            "Error: Expired time has passed"
        );
        expiredTimeCheck[_contract][_time] = true;
    }

    function ownerChecked(address _contractOwner, string memory _name)
        external
        view
        returns (bool _check)
    {
        _check = (ownerOfContract[_contractOwner][keccak256(abi.encodePacked(_name))] != address(0));
    }

    function getAddressByOwner(address _contractOwner, string memory _name)
        external
        view
        returns (address)
    {
        require(
            ownerOfContract[_contractOwner][keccak256(abi.encodePacked(_name))] != address(0),
            "Error: Contract does not exist"
        );
        return ownerOfContract[_contractOwner][keccak256(abi.encodePacked(_name))];
    }

    modifier expiredTimeTrue(address _contract, uint256 _time) {
        require(
            expiredTimeCheck[_contract][_time],
            "Error: New expired time is not registered"
        );
        _;
    }

    modifier onlyWhitelisted(string memory _name) {
        require(
            addressWhitelisted[keccak256(abi.encodePacked(_name))][msg.sender],
            "Error: Address is not whitelisted"
        );
        _;
    }

    modifier institutionChecked(address _contract) {
        require(
            institutionIndex[_contract] > 0,
            "Error: Contract is not an institution"
        );
        _;
    }
}