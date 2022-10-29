// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AtlasNavi is IERC20Metadata, Ownable, ERC20Capped {
    struct MintRequest {
        address account;
        uint256 amount;
        uint256 execTimestamp;
    }

    MintRequest[] public requests;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _cap
    ) ERC20(_name, _symbol) ERC20Capped(_cap) {
        _transferOwnership(address(0xc739c5c128AC764C4990113bC94d498b6DDfB17D));
    }

    function initMint(address account, uint256 amount) public onlyOwner {
        MintRequest memory request;

        request.execTimestamp = block.timestamp + 48 hours;
        request.account = account;
        request.amount = amount;
        requests.push(request);

        emit InitMint(request.account, request.amount, request.execTimestamp);
    }

    function cancelMint(uint256 index) public onlyOwner {
        emit CancelMint(
            requests[index].account,
            requests[index].amount,
            requests[index].execTimestamp
        );
        requests[index].execTimestamp = 0;
    }

    function mint(uint256 index) external onlyOwner {
        require(
            requests[index].execTimestamp > 0,
            "No initialization found for this address"
        );
        require(
            requests[index].execTimestamp < block.timestamp,
            "There are less than 48 hrs from initialization."
        );
        _mint(requests[index].account, requests[index].amount);
        requests[index].execTimestamp = 0;
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    event InitMint(address account, uint256 amount, uint256 timestamp);
    event CancelMint(address account, uint256 amount, uint256 timestamp);
}