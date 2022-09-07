// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./AlbumFactory.sol";
import "./FactorySafeHelper.sol";

contract FactoryPredictionHelper {
    function getEnsSubnode(AlbumFactory factory, string memory name)
        internal
        view
        returns (bytes32 subnode)
    {
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        subnode = keccak256(
            abi.encodePacked(factory.BASE_ENS_NODE(), nameHash)
        );
    }

    function predictSafeAddress(AlbumFactory factory, string memory name)
        public
        view
        returns (address predicted)
    {
        FactorySafeHelper safeHelper = FactorySafeHelper(
            address(factory.FACTORY_SAFE_HELPER())
        );
        bytes32 salt = keccak256(
            abi.encode(
                getEnsSubnode(factory, name),
                address(factory),
                address(safeHelper)
            )
        );
        salt = keccak256(abi.encodePacked(keccak256(""), salt));
        bytes memory bytecode = abi.encodePacked(
            safeHelper.GNOSIS_SAFE_PROXY_FACTORY().proxyCreationCode(),
            uint256(uint160(safeHelper.GNOSIS_SAFE_TEMPLATE_ADDRESS()))
        );
        predicted = Create2.computeAddress(
            salt,
            keccak256(bytecode),
            address(safeHelper.GNOSIS_SAFE_PROXY_FACTORY())
        );
    }

    function predictRealityModuleAddress(
        AlbumFactory factory,
        string memory name
    ) public view returns (address predicted) {
        FactorySafeHelper safeHelper = FactorySafeHelper(
            address(factory.FACTORY_SAFE_HELPER())
        );
        address safeAddress = predictSafeAddress(factory, name);
        bytes memory initializer = abi.encodeWithSignature(
            "setUp(bytes)",
            abi.encode(
                safeAddress,
                safeAddress,
                safeAddress,
                safeHelper.ORACLE(),
                safeHelper.DAO_MODULE_TIMEOUT(),
                0, // cooldown, hard-coded to 0
                safeHelper.DAO_MODULE_EXPIRATION(),
                safeHelper.DAO_MODULE_BOND(),
                safeHelper.REALITIO_TEMPLATE_ID(),
                safeHelper.SZNS_DAO()
            )
        );
        bytes32 salt = keccak256(
            abi.encodePacked(keccak256(initializer), type(uint256).min)
        );
        bytes memory bytecode = abi.encodePacked(
            hex"602d8060093d393df3363d3d373d3d3d363d73",
            safeHelper.REALITY_MODULE_TEMPLATE_ADDRESS(),
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        predicted = Create2.computeAddress(
            salt,
            keccak256(bytecode),
            address(safeHelper.GNOSIS_SAFE_MODULE_PROXY_FACTORY())
        );
    }

    function predictTokenAddress(
        AlbumFactory factory,
        string memory name,
        string memory symbol
    ) public pure returns (address predicted) {
        bytes memory bytecode = abi.encodePacked(
            type(ERC20PresetMinterPauser).creationCode,
            abi.encode(name, symbol)
        );
        predicted = Create2.computeAddress(
            "",
            keccak256(bytecode),
            address(factory)
        );
    }

    function predictTokenSaleAddress(AlbumFactory factory, string memory name)
        public
        view
        returns (address predicted)
    {
        predicted = Clones.predictDeterministicAddress(
            factory.TOKEN_SALE_MASTER_COPY(),
            getEnsSubnode(factory, name),
            address(factory)
        );
    }
}