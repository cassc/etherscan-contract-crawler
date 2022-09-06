// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./utils/ShareCollateralToken.sol";
import "./utils/ShareDebtToken.sol";
import "./interfaces/ITokensFactory.sol";

/// @title TokensFactory
/// @notice Deploys debt and collateral tokens for each Silo
/// @custom:security-contact [email protected]
contract TokensFactory is ITokensFactory {
    ISiloRepository public siloRepository;

    event InitSiloRepository();

    error OnlySilo();
    error SiloRepositoryAlreadySet();

    modifier onlySilo() {
        if (!siloRepository.isSilo(msg.sender)) revert OnlySilo();
        _;
    }

    /// @inheritdoc ITokensFactory
    function initRepository(address _repository) external {
        // We don't perform a ping to the repository because this is meant to be called in its constructor
        if (address(siloRepository) != address(0)) revert SiloRepositoryAlreadySet();

        siloRepository = ISiloRepository(_repository);
        emit InitSiloRepository();
    }

    /// @inheritdoc ITokensFactory
    function createShareCollateralToken(
        string memory _name,
        string memory _symbol,
        address _asset
    )
        external
        override
        onlySilo
        returns (IShareToken token)
    {
        token = new ShareCollateralToken(_name, _symbol, msg.sender, _asset);
        emit NewShareCollateralTokenCreated(address(token));
    }

    /// @inheritdoc ITokensFactory
    function createShareDebtToken(
        string memory _name,
        string memory _symbol,
        address _asset
    )
        external
        override
        onlySilo
        returns (IShareToken token)
    {
        token = new ShareDebtToken(_name, _symbol, msg.sender, _asset);
        emit NewShareDebtTokenCreated(address(token));
    }

    function tokensFactoryPing() external pure override returns (bytes4) {
        return this.tokensFactoryPing.selector;
    }
}