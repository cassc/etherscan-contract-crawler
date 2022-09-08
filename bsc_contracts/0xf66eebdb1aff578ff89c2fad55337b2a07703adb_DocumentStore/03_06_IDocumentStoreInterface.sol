// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.5;

interface IDocumentStoreInterface {
    function getName() external view returns(string memory);
        
    function getEmail() external view returns(string memory);

    function getLegalReference() external view returns(string memory);

    function getIntentDeclaration() external view returns(string memory);

    function getHost() external returns(string memory);
    
    function getExpiredTime() external returns(uint256);

    function setOwnerOfContract(address _oldOwner, address _newOwner, string memory _name) external;

    function setName(address _contract, string memory _name) external;
        
    function setEmail(address _contract, string memory _email) external;

    function setLegalReference(address _contract, string memory _legalReference) external;

    function setIntentDeclaration(address _contract, string memory _intentDeclaration) external;

    function setHost(address _contract, string memory _host) external;

    function setExpiredTime(address _contract, uint256 _time) external;

}