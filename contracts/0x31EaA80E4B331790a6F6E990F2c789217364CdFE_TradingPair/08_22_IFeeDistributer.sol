pragma solidity ^0.8.17;
import 'contracts/interfaces/assets/IAsset.sol';

interface IFeeDistributer {
    function ownerAsset() external returns (IAsset);

    function outputAsset() external returns (IAsset);
}