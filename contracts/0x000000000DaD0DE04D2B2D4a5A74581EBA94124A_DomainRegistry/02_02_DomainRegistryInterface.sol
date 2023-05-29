pragma solidity ^0.8.17;

interface DomainRegistryInterface {
    function setDomain(string calldata domain) external returns (bytes4 tag);

    function getDomains(bytes4 tag)
        external
        view
        returns (string[] memory domains);

    function getNumberOfDomains(bytes4 tag)
        external
        view
        returns (uint256 totalDomains);

    function getDomain(bytes4 tag, uint256 index)
        external
        view
        returns (string memory domain);

    event DomainRegistered(string domain, bytes4 tag, uint256 index);

    error DomainAlreadyRegistered(string domain);

    error DomainIndexOutOfRange(
        bytes4 tag,
        uint256 maxIndex,
        uint256 suppliedIndex
    );
}