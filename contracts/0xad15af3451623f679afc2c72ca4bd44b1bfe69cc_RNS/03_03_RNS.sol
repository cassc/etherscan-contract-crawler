pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED

import "./Owned.sol";
import "./ERC20.sol";

contract RNS is ERC20, Owned {

    event Whitelisted(address indexed target, bool toggle);
    event Initialized();
    error Not_Initialized();

    bool public initialized;
    mapping(address => bool) public whitelist;

    constructor(
        uint256 _totalSuply,
        address _owner
    ) Owned(_owner) {
        whitelist[_owner] = true;
        /// only time _mint is called
        _mint(_owner, _totalSuply);
    }


    function toggleWhitelist(address target, bool toggle) external onlyOwner {
        whitelist[target] = toggle;
        emit Whitelisted(target, toggle);
    }

    /*//////////////////////////////////////////////////////////////
                             ERC20 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @notice Name of the token.
    function name() public pure override returns (string memory) {
        return "RNS";
    }

    /// @notice Symbol of the token.
    function symbol() public pure override returns (string memory) {
        return "RNS";
    }

    function initialize() external onlyOwner {
        initialized = true;
        emit Initialized();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view override {
        if(!initialized && !whitelist[from] && !whitelist[to]) {
            revert Not_Initialized();
        }
    }
}
