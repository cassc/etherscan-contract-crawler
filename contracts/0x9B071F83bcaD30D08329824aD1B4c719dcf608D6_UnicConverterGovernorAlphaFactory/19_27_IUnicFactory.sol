pragma solidity >=0.5.0;

interface IUnicFactory {
    event TokenCreated(address indexed caller, address indexed uToken);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function converterImplementation() external view returns (address);

    function getUToken(address uToken) external view returns (uint);
    function uTokens(uint) external view returns (address);
    function uTokensLength() external view returns (uint);
    function getGovernorAlpha(address uToken) external view returns (address);
    function feeDivisor() external view returns (uint);
    function auctionHandler() external view returns (address);
    function uTokenSupply() external view returns (uint);
    function airdropAmount() external view returns (uint);
    function airdropEnabled() external view returns (bool);
    function unic() external view returns (address);
    function isAirdropCollection(address collection) external view returns (bool);
    function receivedAirdrop(address user) external view returns (bool);
    function owner() external view returns (address);
    function proxyTransactionFactory() external view returns (address);

    function createUToken(
        string calldata name,
        string calldata symbol,
        bool enableProxyTransactions
    ) external returns (address, address);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setConverterImplementation(address) external;
    function setFeeDivisor(uint) external;
    function setAuctionHandler(address) external;
    function setSupply(uint) external;
    function setProxyTransactionFactory(address _proxyTransactionFactory) external;
    function setAirdropCollections(address[] calldata, bool) external;
    function setAirdropReceived(address) external;
    function toggleAirdrop() external;
}