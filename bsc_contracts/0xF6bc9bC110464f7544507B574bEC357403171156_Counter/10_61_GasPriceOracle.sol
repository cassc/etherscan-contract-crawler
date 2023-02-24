// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./interfaces/IOracle.sol";
import "./interfaces/ITransmitManager.sol";
import "./utils/AccessControl.sol";
import "./libraries/RescueFundsLib.sol";

contract GasPriceOracle is IOracle, Ownable {
    ITransmitManager public transmitManager__;

    // plugs/switchboards/transmitter can use it to ensure prices are updated
    mapping(uint256 => uint256) public updatedAt;
    // chain slug => relative gas price
    mapping(uint256 => uint256) public override relativeGasPrice;

    // gas price of source chain
    uint256 public override sourceGasPrice;
    uint256 public immutable chainSlug;

    event GasPriceUpdated(uint256 dstChainSlug, uint256 relativeGasPrice);
    event TransmitManagerUpdated(address transmitManager);
    event SourceGasPriceUpdated(uint256 sourceGasPrice);

    error TransmitterNotFound();

    constructor(address owner_, uint256 chainSlug_) Ownable(owner_) {
        chainSlug = chainSlug_;
    }

    /**
     * @notice update the sourceGasPrice which is to be used in various computations
     * @param sourceGasPrice_ gas price of source chain
     */
    function setSourceGasPrice(uint256 sourceGasPrice_) external {
        if (!transmitManager__.isTransmitter(msg.sender, chainSlug))
            revert TransmitterNotFound();

        sourceGasPrice = sourceGasPrice_;
        emit SourceGasPriceUpdated(sourceGasPrice);
    }

    /**
     * @dev the relative prices are calculated as:
     * relativeGasPrice = (dstGasPrice * dstGasUSDPrice)/srcGasUSDPrice
     * It is assumed that precision of relative gas price will be same as src native tokens
     * So that when it is multiplied with gas limits at other contracts, we get correct values.
     */
    function setRelativeGasPrice(
        uint256 dstChainSlug_,
        uint256 relativeGasPrice_
    ) external {
        if (!transmitManager__.isTransmitter(msg.sender, dstChainSlug_))
            revert TransmitterNotFound();

        relativeGasPrice[dstChainSlug_] = relativeGasPrice_;
        updatedAt[dstChainSlug_] = block.timestamp;

        emit GasPriceUpdated(dstChainSlug_, relativeGasPrice_);
    }

    function getGasPrices(
        uint256 dstChainSlug_
    ) external view override returns (uint256, uint256) {
        return (sourceGasPrice, relativeGasPrice[dstChainSlug_]);
    }

    function setTransmitManager(
        ITransmitManager transmitManager_
    ) external onlyOwner {
        transmitManager__ = transmitManager_;
        emit TransmitManagerUpdated(address(transmitManager_));
    }

    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) external onlyOwner {
        RescueFundsLib.rescueFunds(token_, userAddress_, amount_);
    }
}