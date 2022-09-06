// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "../interfaces/IInterestRateModel.sol";
import "../interfaces/ISilo.sol";
import "../lib/Ping.sol";
import "../SiloLens.sol";

contract InterestRateDataResolver {
    ISiloRepository immutable public siloRepository;
    SiloLens public immutable lens;

    error InvalidSiloLens();
    error InvalidSiloRepository();
    error EmptySilos();

    struct AssetData {
        address asset;
        IInterestRateModel.Config modelConfig;
        uint256 currentInterestRate;
        uint256 siloUtilization;
        uint256 totalDepositsWithInterest;
    }

    struct SiloAssetsData {
        ISilo silo;
        AssetData[] assetData;
    }

    constructor (ISiloRepository _siloRepo, SiloLens _lens) {
        if (!Ping.pong(_siloRepo.siloRepositoryPing)) revert InvalidSiloRepository();
        if (!Ping.pong(_lens.lensPing)) revert InvalidSiloLens();

        siloRepository = _siloRepo;
        lens = _lens;
    }

    /// @dev batch method for `getData()`
    function getDataBatch(ISilo[] calldata _silos)
        external
        view
        returns (SiloAssetsData[] memory siloAssetsData, uint256 timestamp)
    {
        if (_silos.length == 0) revert EmptySilos();

        siloAssetsData = new SiloAssetsData[](_silos.length);

        unchecked {
            for(uint256 i; i < _silos.length; i++) {
                address[] memory assets = _silos[i].getAssets();

                siloAssetsData[i].silo = _silos[i];
                siloAssetsData[i].assetData = new AssetData[](assets.length);

                for (uint256 j; j < assets.length; j++) {
                    (siloAssetsData[i].assetData[j],) = getData(_silos[i], assets[j]);
                }
            }
        }

        timestamp = block.timestamp;
    }

    function getModel(ISilo _silo, address _asset) public view returns (IInterestRateModel) {
        return IInterestRateModel(siloRepository.getInterestRateModel(address(_silo), _asset));
    }

    /// @dev pulls all data required for bot that collect interest rate model data for researchers
    function getData(ISilo _silo, address _asset)
        public
        view
        returns (AssetData memory assetData, uint256 timestamp)
    {
        IInterestRateModel model = getModel(_silo, _asset);

        assetData.asset = _asset;
        assetData.modelConfig = model.getConfig(address(_silo), _asset);
        assetData.currentInterestRate = model.getCurrentInterestRate(address(_silo), _asset, block.timestamp);
        assetData.siloUtilization = lens.getUtilization(_silo, _asset);
        assetData.totalDepositsWithInterest = lens.totalDepositsWithInterest(_silo, _asset);

        timestamp = block.timestamp;
    }
}