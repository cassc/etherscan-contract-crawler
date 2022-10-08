// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IBoundRegistrarController.sol";
import "../interfaces/IBulkRegistrarController.sol";
import "../interfaces/IRegistry.sol";
import "../interfaces/IRegistrar.sol";
import "../interfaces/IRegistrarController.sol";
import "../interfaces/IResolver.sol";
import "../interfaces/IPriceOracle.sol";

contract BulkRegistrarController is IBulkRegistrarController {
    address public constant NATIVE_TOKEN_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IRegistry public immutable registry;

    constructor(IRegistry _registry) {
        registry = _registry;
    }

    function getController(IRegistrar registrar)
        internal
        view
        returns (IRegistrarController)
    {
        IResolver r = IResolver(registry.resolver(registrar.baseNode()));
        return
            IRegistrarController(
                r.interfaceImplementer(
                    registrar.baseNode(),
                    type(IRegistrarController).interfaceId
                )
            );
    }

    function nameRecords(
        address registrar,
        bytes32 node,
        string[] calldata keys
    ) external view override returns (address payable, string[] memory) {
        string[] memory values = new string[](keys.length);
        IResolver r = IResolver(
            registry.resolver(IRegistrar(registrar).baseNode())
        );
        for (uint256 i = 0; i < keys.length; i++) {
            values[i] = r.text(node, keys[i]);
        }
        return (r.addr(node), values);
    }

    function available(address[] calldata registrars, string[] calldata names)
        external
        view
        override
        returns (bool[] memory, uint256[] memory)
    {
        require(
            registrars.length == names.length,
            "registrars and names lengths do not match"
        );
        bool[] memory unregistered = new bool[](names.length);
        uint256[] memory expires = new uint256[](names.length);
        for (uint256 i = 0; i < names.length; i++) {
            uint256 labelId = uint256(keccak256(bytes(names[i])));
            IRegistrar registrar = IRegistrar(registrars[i]);
            if (!registrar.available(labelId)) {
                unregistered[i] = false;
                expires[i] = registrar.nameExpires(labelId);
            } else {
                unregistered[i] = true;
                expires[i] = 0;
            }
        }
        return (unregistered, expires);
    }

    function rentPrice(
        address[] calldata registrars,
        string[] calldata names,
        uint256[] calldata durations
    ) external view override returns (RentPrice[] memory) {
        require(
            registrars.length == names.length,
            "registrars and names lengths do not match"
        );
        require(
            names.length == durations.length,
            "names and durations lengths do not match"
        );

        RentPrice[] memory prices = new RentPrice[](names.length);
        for (uint256 i = 0; i < names.length; i++) {
            IRegistrarController controller = getController(
                IRegistrar(registrars[i])
            );
            IPriceOracle.Price memory price = controller.rentPrice(
                registrars[i],
                names[i],
                durations[i]
            );
            prices[i] = RentPrice(price.currency, price.base + price.premium);
        }
        return prices;
    }

    function bulkRenew(
        address[] calldata registrars,
        string[] calldata names,
        uint256[] calldata durations
    ) external payable override {
        require(
            registrars.length == names.length &&
                names.length == durations.length,
            "arrays lengths do not match"
        );

        for (uint256 i = 0; i < names.length; i++) {
            IRegistrarController controller = getController(
                IRegistrar(registrars[i])
            );
            IPriceOracle.Price memory price = controller.rentPrice(
                registrars[i],
                names[i],
                durations[i]
            );

            if (price.currency == NATIVE_TOKEN_ADDRESS) {
                controller.renew{value: price.base + price.premium}(
                    registrars[i],
                    names[i],
                    durations[i]
                );
            } else {
                controller.renew(registrars[i], names[i], durations[i]);
            }
        }
        if (address(this).balance > 0) {
            // Send any excess funds back
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function controllerInterfaceId() public pure returns (bytes4) {
        return type(IRegistrarController).interfaceId;
    }

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool)
    {
        return
            interfaceID == type(IERC165).interfaceId ||
            interfaceID == type(IBulkRegistrarController).interfaceId;
    }
}