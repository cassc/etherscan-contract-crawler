pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";
import "../utils/OwnablePausable.sol";
import "../utils/delegationRegistry/IDelegationRegistry.sol";

interface MPL {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract MarsUBIBridge is FxBaseRootTunnel, OwnablePausable {
    address public mpl;
    IDelegationRegistry public dc; // Delegation contract
    uint256 public limit = 120;
    uint256 public claimId = 42069;

    event Bridged(uint256[] tokenIds, address recipient, uint256 claimId);

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _mpl,
        address _marsUBI,
        address _dc
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        mpl = _mpl;
        dc = IDelegationRegistry(_dc);
        setFxChildTunnel(_marsUBI);
    }

    function safeClaimUBI(uint256[] calldata tokenIds, address vault) public {
        require(
            msg.sender.code.length == 0,
            "Safe: contract may not exist on child chain"
        );
        claimUBI(tokenIds, msg.sender, vault);
    }

    function setLimit(uint256 _limit) public onlyOwner {
        limit = _limit;
    }

    // @notice helper min function
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function claimUBI(
        uint256[] calldata tokenIds,
        address recipient,
        address vault
    ) public whenNotPaused {
        address requester = msg.sender;

        if (vault != address(0)) {
            bool isDelegateValid = dc.checkDelegateForContract(
                msg.sender,
                vault,
                address(mpl)
            );
            require(isDelegateValid, "invalid delegate-vault pairing");
            requester = vault;
        }

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                MPL(mpl).ownerOf(tokenIds[i]) == requester,
                "ERC721: Not token owner"
            );
        }

        uint256 start;
        while (start < tokenIds.length) {
            uint256 end = min(start + limit, tokenIds.length);
            _sendMessageToChild(
                abi.encode(tokenIds[start:end], recipient, claimId)
            );
            start += limit;
        }

        emit Bridged(tokenIds, recipient, claimId);
        claimId = claimId + 1;
    }

    function _processMessageFromChild(bytes memory message)
        internal
        virtual
        override
    {}
}