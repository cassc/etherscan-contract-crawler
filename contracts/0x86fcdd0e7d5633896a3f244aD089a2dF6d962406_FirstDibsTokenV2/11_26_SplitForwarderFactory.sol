//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.7;
import '@openzeppelin/contracts/proxy/Clones.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import './ISplitForwarder.sol';
import './ISplitForwarderFactory.sol';

contract SplitForwarderFactory is ISplitForwarderFactory, Ownable {
    using Clones for address;
    using Address for address;
    /**
     * ========================
     * #Public state variables
     * ========================
     */
    address public override splitForwarder;
    address public override splitPool;

    /**
     * ========================
     * constructor
     * ========================
     * @param _splitForwarder address for split forwarder implementation contract
     * @param _splitPool address for split pool contract
     */
    constructor(address _splitForwarder, address _splitPool) {
        splitForwarder = _splitForwarder;
        splitPool = _splitPool;
    }

    /**
     * @dev setter for split forwarder address
     * @param _splitForwarder address for the split forwarder contract
     */
    function setSplitForwarder(address _splitForwarder) external onlyOwner {
        require(_splitForwarder != address(0), 'cannot be zero address');
        splitForwarder = _splitForwarder;
    }

    /**
     * @dev setter for split pool address
     * @param _splitPool address for the split forwarder contract
     */
    function setSplitPool(address _splitPool) external onlyOwner {
        require(_splitPool != address(0), 'cannot be zero address');
        splitPool = _splitPool;
    }

    /**
     * @dev return the predicted/existing split forwarder address for a given merkle root
     * @param _merkleRoot merkle root to lookup the address for
     */
    function getSplitForwarderAddress(bytes32 _merkleRoot)
        external
        view
        override
        returns (address)
    {
        require(splitForwarder != address(0), 'splitForwarder must be set');
        return splitForwarder.predictDeterministicAddress(keccak256(abi.encode(_merkleRoot)));
    }

    /**
     * @dev create a SplitForwarder proxy for a given merkle root
     * @param _merkleRoot merkle root which to deploy a split forwarder proxy for
     */
    function createSplitForwarder(bytes32 _merkleRoot) public override returns (address _clone) {
        require(
            splitForwarder != address(0) && splitPool != address(0),
            'splitForwarder & splitPool must be set'
        );
        _clone = splitForwarder.predictDeterministicAddress(keccak256(abi.encode(_merkleRoot)));
        if (!_clone.isContract()) {
            splitForwarder.cloneDeterministic(keccak256(abi.encode(_merkleRoot)));
            ISplitForwarder(_clone).initialize(_merkleRoot, splitPool);
        }
    }
}