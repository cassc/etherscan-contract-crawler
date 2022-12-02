pragma solidity 0.8.6;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title UUPSProxy Proxy Contract
/// @notice This contract serves as the UUPS proxy for upgrading and
///  initializing the UUPSProxy implementation contract.
contract UUPSProxy is ERC1967Proxy {
    constructor(address logic, bytes memory data) ERC1967Proxy(logic, data) {}
}