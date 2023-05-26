pragma solidity >=0.6.0 <0.8.0;

interface IEulerBeats {
    function reserve() external view returns (uint);
    function totalSupply(uint) external view returns (uint);
    function safeTransferFrom(        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data) external;
    function balanceOf(address, uint256) external view returns (uint256);
    function burnPrint(uint256, uint256) external;
    function mintPrint(uint256) external payable returns (uint256);
    function seedToOwner(uint256) external view returns (address);
    function setEnabled(bool) external;
    function setLocked(bool) external;
    function transferOwnership(address) external;
    function withdraw() external;

    function setURI(string memory) external;
    function resetScriptCount() external;
    function addScript(string memory) external;
    function updateScript(string memory, uint256) external;
}