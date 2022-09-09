//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../external/IERC677Receiver.sol";
import "../external/IERC677Token.sol";
import "../lib/Utils.sol";
import "./MintableToken.sol";

/// @notice Contract that manages minting/burning of MintableTokens.
/// Owner can directly mint tokens into accounts, everyone can burn their own tokens.
/// Minting rights can also be transferred as ERC20's. This enables bridging
/// tokens by bridging minter rights as ERC20 instead of the token, decoupling the
/// canonical/root token from bridging.
contract TheMint is ImmutableOwnable, GitCommitHash {
    using SafeERC20 for IERC20;

    MintableToken public immutable token;

    // A non-zero cap means address is valid bridge
    mapping(address => bool) isBridge;

    event BridgeChanged(address bridge, bool isBridge);
    event TokenMinted(address requester, uint256 amount);
    event TokenBurned(address requester, uint256 amount);

    constructor(address _token, address _owner) ImmutableOwnable(_owner) {
        token = MintableToken(_token);
    }

    function transferTokenOwnership(address newOwner) external onlyOwner {
        token.transferOwnership(newOwner);
    }

    function bridgeMint(address account, uint256 amount) external {
        require(isBridge[msg.sender], "Not a valid bridge");
        emit TokenMinted(account, amount);
        token.mint(account, amount);
    }

    function bridgeBurn(address account, uint256 amount) external {
        require(isBridge[msg.sender], "Not a valid bridge");
        emit TokenBurned(account, amount);
        burnTokenInternal(account, amount);
    }

    function setBridge(address bridge, bool _isBridge) external onlyOwner {
        require(isBridge[bridge] != _isBridge, "Value doesn't change");
        isBridge[bridge] = _isBridge;
        emit BridgeChanged(bridge, _isBridge);
    }

    function mintTo(address account, uint256 amount) external onlyOwner {
        token.mint(account, amount);
    }

    function burnTokenInternal(address account, uint256 amount) internal virtual {
        token.burn(account, amount);
    }
}

interface ILegacyFST {
    function mint(address to, uint256 amount) external returns (bool);

    function burnFromAccount(address to, uint256 amount) external;
}

/// @notice Adds support for legacy FST to TheMint.
contract TheMintLegacyFST is TheMint {
    using SafeERC20 for IERC20;

    constructor(address _token, address _owner) TheMint(_token, _owner) {}

    function burnTokenInternal(address account, uint256 amount) internal override {
        ILegacyFST(address(token)).burnFromAccount(account, amount);
    }
}