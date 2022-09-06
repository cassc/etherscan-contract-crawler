pragma solidity 0.8.6;

interface IJellyDocuments {
    function setDocument(
        address _contractAddr,
        string calldata _name,
        string calldata _data
    ) external;

    function setDocuments(
        address _contractAddr,
        string[] calldata _name,
        string[] calldata _data
    ) external;

    function removeDocument(address _contractAddr, string calldata _name)
        external;
}