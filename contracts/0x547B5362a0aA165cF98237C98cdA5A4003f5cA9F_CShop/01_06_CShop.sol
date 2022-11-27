// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";
import "./SafeMath.sol";

contract CShop is ERC20 {

    using SafeMath for uint256;

    address public minter;

    uint256 public mintingAllowedAfter;

    uint32 public constant minimumTimeBetweenMints = 1 days * 365;

    uint8 public constant mintCap = 16;

    event MinterChanged(address minter, address newMinter);

    modifier onlyMinter {
        require(_msgSender() == minter);
        _;
    }

    constructor(address _account, address _minter, uint256 _mintingAllowedAfter) ERC20("CipherShop", "CSHOP", _account) {
        require(_mintingAllowedAfter >= block.timestamp);
        minter = _minter;
        emit MinterChanged(address(0), minter);
        mintingAllowedAfter = _mintingAllowedAfter;
    }

    function mint(address account, uint256 amount) external onlyMinter {
        require(block.timestamp >= mintingAllowedAfter, "CSHOP: minting not allowed yet");
        require(account != address(0));
        require(amount <= SafeMath.div(SafeMath.mul(totalSupply(), mintCap), 1000));
        mintingAllowedAfter = SafeMath.add(block.timestamp, minimumTimeBetweenMints);
        _mint(account, amount);
    }

    function setMinter(address _address) external onlyMinter {
        require(address(0) != _address);
        emit MinterChanged(minter, _address);
        minter = _address;
    }

    function multiTransfer(address[] memory addresses, uint256[] memory quantities) external {
        require(addresses.length > 0);
        require(quantities.length > 0);
        require(addresses.length == quantities.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            transfer(addresses[i], quantities[i]);
        }
    }
}