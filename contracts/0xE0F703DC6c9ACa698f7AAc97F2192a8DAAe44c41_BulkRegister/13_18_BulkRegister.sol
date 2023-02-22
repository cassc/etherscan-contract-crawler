// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./universal/UniversalRegistrar.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BulkRegister is Ownable {
    bytes32 public FOREVER_NAMEHASH = 0xcb1580becfbebb600331fa1f2d359c4cbd0e27d5e4b970c35e5351a749ff9824;
    bytes32 public ETH_NAMEHASH = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    UniversalRegistrar public registrar;

    struct RegisterRequest {
        bytes32 tldNameHash;
        address controller;
        bytes32 secret;
        uint duration;
        address resolver;
        address addr;
        uint256 targetCost;
        string label;
    }

    constructor(UniversalRegistrar _registrar) {
        registrar = _registrar;
    }

    function commit(address[] calldata controllers, bytes32[] calldata commitments) external {
        require(controllers.length == commitments.length, "BulkRegister: length mismatch");
        for (uint i = 0; i < controllers.length; i++) {
            ICommitment(controllers[i]).commit(commitments[i]);
        }
    }

    function mint(RegisterRequest[] calldata requests, address owner, bool thirdParty) external payable {
        uint256 totalPaid = 0;

        for (uint256 i = 0; i < requests.length; i++) {
            if (requests[i].tldNameHash == ETH_NAMEHASH) {
                totalPaid += _mintETH(requests[i], owner, totalPaid);
                continue;
            }

            if (requests[i].tldNameHash == FOREVER_NAMEHASH) {
                totalPaid += _mintForever(requests[i], owner, totalPaid);
                continue;
            }

            totalPaid += _mintImpervious(requests[i], owner, totalPaid);
        }

        // Send excess funds back to the user except for third party callers
        if (msg.value > totalPaid && !thirdParty) {
            payable(msg.sender).transfer(msg.value - totalPaid);
        }
    }

    function verifyRegisterParams(RegisterRequest[] calldata requests, uint256 paymentAmount) external view returns (string memory) {
        uint256 totalCost = 0;

        for (uint i = 0; i < requests.length; i++) {
            if (requests[i].tldNameHash == FOREVER_NAMEHASH) {
                (string memory foreverError, uint256 cost) = _verifyForever(requests[i]);
                if (bytes(foreverError).length > 0) {
                    return foreverError;
                }
                totalCost += cost;
            } else if (requests[i].tldNameHash == ETH_NAMEHASH) {
                (string memory ethError, uint256 cost) = _verifyETH(requests[i]);
                if (bytes(ethError).length > 0) {
                    return ethError;
                }
                totalCost += cost;
            } else {
                (string memory imperviousError, uint256 cost) = _verifyImpervious(requests[i]);
                if (bytes(imperviousError).length > 0) {
                    return imperviousError;
                }
                totalCost += cost;
            }
        }

        if (totalCost > paymentAmount) {
            return "Insufficient funds";
        }

        return "";
    }

    function _mintForever(RegisterRequest calldata request, address owner, uint256 totalPaid) internal returns (uint256) {
        uint cost = IForeverController(request.controller).price(request.label);
        require(msg.value - totalPaid >= cost, "BulkRegister: insufficient funds");

        IForeverController(request.controller).registerWithConfig{value : cost}(
            request.label,
            owner,
            request.secret,
            request.resolver,
            request.addr
        );

        return cost;
    }

    function _mintETH(RegisterRequest calldata request, address owner, uint256 totalPaid) internal returns (uint256) {
        uint cost = IETHController(request.controller).rentPrice(request.label, request.duration);
        uint duration = request.duration;

        // The mint price has changed since the request was made
        // (happens due to fluctuations in the USD oracle)
        if (request.targetCost != cost) {
            require(request.targetCost != 0 && cost != 0, "BulkRegister: invalid price");

            // If price has increased more than 5% of the target cost for this name, revert.
            // This guarantees that the duration is not reduced by more than 5% which can be unexpected.
            require((request.targetCost * 10500) / 10000 >= cost, "BulkRegister: price changed by more than 5%");

            // Adjust duration to match target cost
            duration = (request.targetCost * duration) / cost;
            cost = request.targetCost;
        }

        require(msg.value - totalPaid >= cost, "BulkRegister: insufficient funds");

        IETHController(request.controller).registerWithConfig{value : cost}(
            request.label,
            owner,
            duration,
            request.secret,
            request.resolver,
            request.addr
        );

        return cost;
    }

    function _mintImpervious(RegisterRequest calldata request, address owner, uint256 totalPaid) internal returns (uint256) {
        uint cost = IImperviousController(request.controller).rentPrice(request.tldNameHash, request.label, request.duration);
        uint duration = request.duration;

        // The mint price has changed since the request was made
        // (happens due to fluctuations in the USD oracle)
        if (request.targetCost != cost) {
            require(request.targetCost != 0 && cost != 0, "BulkRegister: invalid price");

            // If price has increased more than 5% of the target cost for this name, revert.
            // This guarantees that the duration is not reduced by more than 5% which can be unexpected.
            require((request.targetCost * 10500) / 10000 >= cost, "BulkRegister: price changed by more than 5%");

            // Adjust duration to match target cost
            duration = (request.targetCost * duration) / cost;
            cost = request.targetCost;
        }

        require(msg.value - totalPaid >= cost, "BulkRegister: insufficient funds");

        if (request.secret == 0) {
            IImperviousRegisterNowController(request.controller).registerNow{value : cost}(
                request.tldNameHash,
                request.label,
                owner,
                duration,
                request.resolver,
                request.addr
            );
            return cost;
        }

        IImperviousController(request.controller).registerWithConfig{value : cost}(
            request.tldNameHash,
            request.label,
            owner,
            duration,
            request.secret,
            request.resolver,
            request.addr
        );

        return cost;
    }

    function _verifyForever(RegisterRequest calldata request) internal view returns (string memory, uint256) {
        IForeverController controller = IForeverController(request.controller);
        if (!controller.available(request.label)) {
            return ("Name not available", 0);
        }

        return ("", controller.price(request.label));
    }

    function _verifyImpervious(RegisterRequest calldata request) internal view returns (string memory, uint256) {
        if (!registrar.controllers(request.tldNameHash, request.controller)) {
            return ("Controllers have been updated please try again", 0);
        }

        if (request.secret == 0 &&
            IImperviousRegisterNowController(request.controller).requireCommitReveal(request.tldNameHash)) {
            return ("Some names require a commitment", 0);
        }

        IImperviousController controller = IImperviousController(request.controller);
        if (!controller.available(request.tldNameHash, request.label)) {
            return ("Name not available", 0);
        }

        uint256 cost = controller.rentPrice(request.tldNameHash, request.label, request.duration);
        if (cost != request.targetCost && (request.targetCost * 10500) / 10000 < cost) {
            return ("Prices have changed please try again", 0);
        }

        if (cost < request.targetCost)
            return ("", cost);

        // Duration will be adjusted to match target cost
        return ("", request.targetCost);
    }

    function _verifyETH(RegisterRequest calldata request) internal view returns (string memory, uint256) {
        IETHController controller = IETHController(request.controller);
        if (!controller.available(request.label)) {
            return ("Name not available", 0);
        }

        uint256 cost = controller.rentPrice(request.label, request.duration);
        if (cost != request.targetCost && ((request.targetCost * 10500) / 10000) < cost) {
            return ("Prices have changed please try again", 0);
        }

        if (cost < request.targetCost)
            return ("", cost);

        // Duration will be adjusted to match target cost
        return ("", request.targetCost);
    }

    function withdraw() external {
        payable(owner()).transfer(address(this).balance);
    }
}

abstract contract ICommitment {
    function commit(bytes32 commitment) public virtual;
}

abstract contract IImperviousController {
    function rentPrice(bytes32 node, string memory name, uint duration) view public virtual returns (uint);

    function available(bytes32 node, string memory name) public view virtual returns (bool);

    function registerWithConfig(bytes32 node, string memory label, address owner,
        uint duration, bytes32 secret, address resolver, address addr) public virtual payable;
}

abstract contract IImperviousRegisterNowController {
    function requireCommitReveal(bytes32 node) public virtual view returns (bool);

    function registerNow(bytes32 node, string memory name, address owner,
        uint duration, address resolver, address addr) public virtual payable;
}

abstract contract IForeverController {
    function price(string memory label) view public virtual returns (uint);

    function available(string memory label) view public virtual returns (bool);

    function registerWithConfig(string memory label, address owner,
        bytes32 secret, address resolver, address addr) public virtual payable;
}

abstract contract IETHController {
    function rentPrice(string memory name, uint duration) view public virtual returns (uint);

    function available(string memory name) public view virtual returns (bool);

    function registerWithConfig(string memory label, address owner,
        uint duration, bytes32 secret, address resolver, address addr) public virtual payable;
}