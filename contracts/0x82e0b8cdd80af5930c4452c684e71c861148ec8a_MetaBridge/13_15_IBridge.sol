pragma solidity ^0.8.0;

interface IBridge {
    event AdapterSet(
        string adapterId,
        address addr
    );

    event AdapterRemoved(string adapterId);

    function setAdapter(string calldata adapterId, address adapterAddress) external;

    function removeAdapter(string calldata adapterId) external;

    function bridge(
        string calldata adapterId,
        address tokenFrom,
        uint256 amount,
        bytes calldata data
    ) external payable;
}