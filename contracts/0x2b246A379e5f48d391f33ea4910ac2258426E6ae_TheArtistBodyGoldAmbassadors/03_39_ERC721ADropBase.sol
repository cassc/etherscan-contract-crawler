// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721ABaseWithSupply.sol";
import "./Droppable.sol";

contract ERC721ADropBase is ERC721ABaseWithSupply, Droppable {
    bytes32 public constant DROP_ROLE = keccak256("DROP_ROLE");

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint32 _maxSupply
    )
        ERC721ABaseWithSupply(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _maxSupply
        )
        Droppable()
    {
        _setupRole(DROP_ROLE, msg.sender);
    }

    function _beforeClaim(
        address,
        uint256 _quantity,
        uint256
    ) internal virtual override {
        checkMaxSupply(_quantity);
    }

    function transferTokensOnClaim(
        address _recipient,
        uint32 _quantity
    ) internal override returns (uint256 startTokenId) {
        startTokenId = _startTokenId();
        _mint(_recipient, _quantity);
    }

    function _canSetMintingPhases() internal virtual override returns (bool) {
        return hasRole(DROP_ROLE, msg.sender);
    }

    function _canSetPrimarySaleRecipient()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}