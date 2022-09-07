pragma solidity 0.8.6;

interface IJellyFactory {

    function deployContract(
        bytes32 _templateId,
        address payable _integratorFeeAccount,
        bytes calldata _data
    )
        external payable returns (address newContract);
    function deploy2Contract(
        bytes32 _templateId,
        address payable _integratorFeeAccount,
        bytes calldata _data
    )
        external payable returns (address newContract);
    function getContracts() external view returns (address[] memory);
    function getContractsByTemplateId(bytes32 _templateId) external view returns (address[] memory);
    function getContractTemplate(bytes32 _templateId) external view returns (address);

}