// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract RascalProxy is TransparentUpgradeableProxy {
    constructor (
        address _logic_,
        address _admin_,
        bytes32 _merkleRoot,
        address _multiSig,
        address _royaltyDest,
        uint256 _mintCostWL,
        uint256 _mintCostPub,
        string memory _hiddenMetadataUri,
        string memory _contractMetaURI,
        uint80 _start
    ) TransparentUpgradeableProxy(_logic_, _admin_, generateData(
        _merkleRoot,
        _multiSig,
        _royaltyDest,
        _mintCostWL,
        _mintCostPub,
        _hiddenMetadataUri,
        _contractMetaURI,
        _start,
        _start
        )) {}

    function generateData(
        bytes32 merkleRoot_,
        address multiSig_,
        address royaltyDest_,
        uint256 mintCostWL_,
        uint256 mintCostPub_,
        string memory hiddenMetadataUri_,
        string memory contractMetaURI_,
        uint80 wlStart_,
        uint80 pubStart_
    ) internal pure returns (bytes memory data) {
        data = abi.encodeWithSignature(
            "initialize(bytes32,address,address,uint256,uint256,string,string,uint80,uint80)",
            merkleRoot_,
            multiSig_,
            royaltyDest_,
            mintCostWL_,
            mintCostPub_,
            hiddenMetadataUri_,
            contractMetaURI_,
            wlStart_,
            pubStart_
        );
    }
}