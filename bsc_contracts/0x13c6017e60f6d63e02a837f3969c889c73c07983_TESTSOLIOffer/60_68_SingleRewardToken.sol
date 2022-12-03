/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SingleRewardToken is ERC20, Ownable {
    /**
     * @dev
     * @notice Mapa de pagamentos
     */
    mapping(address => bool) internal mapPayments;

    bool private bLocked;

    constructor(string memory _tokenName, string memory _tokenSymbol)
        public
        ERC20(_tokenName, _tokenSymbol)
    {
    }

    function awardToken(address _account) public onlyOwner {
        require(!mapPayments[_account], "User already awarded token");

        _mint(_account, 1 ether);

        mapPayments[_account] = true;
    }

    function lockToken() public onlyOwner {
        require(!bLocked, "Already locked");
        bLocked = true;
    }

    function returnToken() public {
        uint256 balance = balanceOf(_msgSender());
        require(balance == 1 ether, "No token to return");

        transfer(owner(), 1 ether);
    }

    function returnTokenAny(address _investor) public {
        uint256 balance = balanceOf(_investor);
        require(balance == 1 ether, "No token to return");

        _transfer(_investor, owner(), 1 ether);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!bLocked, "Contract locked");

        if (from != address(0)) {
            require(to == owner(), "Only return token to owner");
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}