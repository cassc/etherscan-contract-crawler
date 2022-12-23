// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BFacetOwner} from "../facets/base/BFacetOwner.sol";
import {
    _addExecutorSigner,
    _removeExecutorSigner,
    _isExecutorSigner,
    _numberOfExecutorSigners,
    _executorSigners,
    _addCheckerSigner,
    _removeCheckerSigner,
    _isCheckerSigner,
    _numberOfCheckerSigners,
    _checkerSigners
} from "./storage/SignerStorage.sol";
import {LibDiamond} from "../libraries/diamond/standard/LibDiamond.sol";

contract SignerFacet is BFacetOwner {
    using LibDiamond for address;

    // EXECUTOR SIGNERS
    // ################ Callable by Gov ################
    function addExecutorSigners(address[] calldata executorSigners_)
        external
        onlyOwner
    {
        for (uint256 i; i < executorSigners_.length; i++)
            require(
                _addExecutorSigner(executorSigners_[i]),
                "SignerFacet.addExecutorSigners"
            );
    }

    function removeExecutorSigners(address[] calldata executorSigners_)
        external
        onlyOwner
    {
        for (uint256 i; i < executorSigners_.length; i++) {
            require(
                msg.sender == executorSigners_[i] ||
                    msg.sender.isContractOwner(),
                "SignerFacet.removeExecutorSigners: msg.sender ! executorSigner || owner"
            );
            require(
                _removeExecutorSigner(executorSigners_[i]),
                "SignerFacet.removeExecutorSigners"
            );
        }
    }

    function isExecutorSigner(address _executorSigner)
        external
        view
        returns (bool)
    {
        return _isExecutorSigner(_executorSigner);
    }

    function numberOfExecutorSigners() external view returns (uint256) {
        return _numberOfExecutorSigners();
    }

    function executorSigners() external view returns (address[] memory) {
        return _executorSigners();
    }

    // CHECKER SIGNERS
    function addCheckerSigners(address[] calldata checkerSigners_)
        external
        onlyOwner
    {
        for (uint256 i; i < checkerSigners_.length; i++)
            require(
                _addCheckerSigner(checkerSigners_[i]),
                "SignerFacet.addCheckerSigners"
            );
    }

    function removeCheckerSigners(address[] calldata checkerSigners_) external {
        for (uint256 i; i < checkerSigners_.length; i++) {
            require(
                msg.sender == checkerSigners_[i] ||
                    msg.sender.isContractOwner(),
                "SignerFacet.removeCheckerSigners: msg.sender ! checkerSigner || owner"
            );
            require(
                _removeCheckerSigner(checkerSigners_[i]),
                "SignerFacet.removeCheckerSigners"
            );
        }
    }

    function isCheckerSigner(address checkerSigner_)
        external
        view
        returns (bool)
    {
        return _isCheckerSigner(checkerSigner_);
    }

    function numberOfCheckerSigners() external view returns (uint256) {
        return _numberOfCheckerSigners();
    }

    function checkerSigners() external view returns (address[] memory) {
        return _checkerSigners();
    }
}