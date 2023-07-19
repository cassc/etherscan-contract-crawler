/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../interfaces/IReliquary.sol";
import "../interfaces/IBatchProver.sol";

abstract contract BatchProver is ERC165, IBatchProver {
    IReliquary immutable reliquary;

    constructor(IReliquary _reliquary) {
        reliquary = _reliquary;
    }

    // Signaling event for off-chain indexers, does not contain data in order
    // to save gas
    event FactsProven();

    // must implemented by each prover
    function _prove(bytes calldata proof) internal view virtual returns (Fact[] memory);

    // can optionally be overridden by each prover
    function _afterStore(Fact memory fact, bool alreadyStored) internal virtual {}

    /**
     * @notice proves a fact ephemerally and returns the fact information
     * @param proof the encoded proof for this prover
     * @param store whether to store the fact in the reqliquary
     */
    function proveBatch(bytes calldata proof, bool store)
        public
        payable
        returns (Fact[] memory facts)
    {
        reliquary.checkProveFactFee{value: msg.value}(msg.sender);
        facts = _prove(proof);
        emit FactsProven();
        for (uint256 i = 0; i < facts.length; i++) {
            Fact memory fact = facts[i];
            if (store) {
                (bool alreadyStored, , ) = reliquary.getFact(fact.account, fact.sig);
                reliquary.setFact(fact.account, fact.sig, fact.data);
                _afterStore(fact, alreadyStored);
            }
        }
    }

    /**
     * @inheritdoc IERC165
     * @dev Supported interfaces: IProver
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return (interfaceId == type(IBatchProver).interfaceId ||
            super.supportsInterface(interfaceId));
    }
}