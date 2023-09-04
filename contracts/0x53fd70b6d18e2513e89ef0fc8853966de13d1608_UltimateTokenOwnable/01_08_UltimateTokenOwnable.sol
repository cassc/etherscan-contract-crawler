// SPDX-License-Identifier: MIT
// Factory: CreateMyToken
pragma solidity ^0.8.19;

import "./core/ERC20.sol";
import "./core/Initializable.sol";
import "./core/Ownable.sol";
import "./core/Pausable.sol";

contract UltimateTokenOwnable is Initializable, ERC20, Pausable, Ownable {
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        uint256 _maxSupply
    ) external initializer {
        _transferOwnership(_owner);

        ERC20.init(
            _name,
            _symbol,
            _decimals,
            _maxSupply == type(uint256).max ? type(uint256).max : _maxSupply * 10 ** _decimals
        );

        _mint(_owner, _initialSupply * 10 ** _decimals);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// Create your own token at https://www.createmytoken.com/