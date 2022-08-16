// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "./../token/GToken.sol";
import "./IGTokenFactory.sol";
import "./../interfaces/IERC20Extras.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract GTokenFactory is OwnableUpgradeable, IGTokenFactory {
    
    address public protocolRegistry;

    function initialize() external initializer {
        __Ownable_init();
    }

    event GTokenDeployed(address GToken, address SPToken);

    /// @dev configure protocol registry contract for calling the deployGtoken
    /// @param _protocolRegistry address of the Gov Protocol Registry contract call by the onlyOwner
    function configureProtocolRegistry(address _protocolRegistry)
        external
        onlyOwner
    {
        require(_protocolRegistry != address(0), "GTokenFactory: null address");
        protocolRegistry = _protocolRegistry;
    }

    /// @dev calling this function externally in the protocol registry contract for the deployment of sythetic Gov Token
    /// @param _spToken the token being approved as an VIP token
    /// @param _liquidator address used for transferring the contract ownership to the liqudator contract...
    /// @dev for default approval of synthetic tokens for burning on the time of payback and liqudiation of collaterals
    function deployGToken(
        address _spToken,
        address _liquidator,
        address _tokenMarket,
        address _govAdminRegistry
    ) external override returns (address _gToken) {
        require(protocolRegistry != address(0), "set protocolRegistry");
        require(
            msg.sender == protocolRegistry,
            "Only Protocol Registry Can Deploy"
        );
        IERC20Extras spToken = IERC20Extras(_spToken);
        string memory gTokenName = string(
            abi.encodePacked("gov", spToken.name())
        );
        string memory gTokenSymbol = string(
            abi.encodePacked("gov", spToken.symbol())
        );
        _gToken = address(
            new GToken(
                gTokenName,
                gTokenSymbol,
                _spToken,
                _liquidator,
                _tokenMarket,
                _govAdminRegistry
            )
        );
        GToken(_gToken).transferOwnership(_liquidator);

        emit GTokenDeployed(_gToken, _spToken);
        return _gToken;
    }
}