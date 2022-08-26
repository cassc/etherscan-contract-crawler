pragma solidity 0.8.6;

interface IMerkleList {
    function tokensClaimable(uint256 _index, address _account, uint256 _amount, bytes32[] calldata _merkleProof ) external view returns (bool);
    function tokensClaimable(bytes32 _merkleRoot, uint256 _index, address _account, uint256 _amount, bytes32[] calldata _merkleProof ) external view returns (uint256);
    function currentMerkleRoot() external view returns (bytes32);
    function currentMerkleURI() external view returns (string memory);
    function initMerkleList(address accessControl) external ;
    function addProof(bytes32 _merkleRoot, string memory _merkleURI) external;
    function updateProof(bytes32 _merkleRoot, string memory _merkleURI) external;
}