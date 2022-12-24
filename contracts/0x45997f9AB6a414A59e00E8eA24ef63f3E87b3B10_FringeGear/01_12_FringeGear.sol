//SPDX-License-Identifier: MIT
//Fringe Drifter Scenes From The Fringe Contract Created by Swifty.eth
//POLYGON VERSION
//legal: https://fringedrifters.com/terms

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);

    function balanceOf(address _from) external returns (uint256);
}

//errors
error NotWithdrawAddress();
error FailedToWithdraw();
error NotMinting();
error NotEnoughEth();
error PastBoundsOfBatchLimit();
error PastSupply();
error AlreadyMinted();
error AuthenticationFailed();
error DoesNotExist();

contract FringeGear is ERC1155, Ownable {
    string public name = "Gear - Fringe Drifters";
    string public symbol = "GFD";

    address private withdrawAccount =
        0x8ff8657929a02c0E15aCE37aAC76f47d1F5fbfC6;

    string internal _baseURI;

    //modifiers.
    modifier withdrawAddressCheck() {
        if (msg.sender != withdrawAccount) revert NotWithdrawAddress();
        _;
    }

    constructor(string memory baseURI) ERC1155("") {
        _baseURI = baseURI;
    }

    //gifts cards in bulk, with specified card.
    function gift(uint256 cardId, address[] calldata receivers)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], cardId, 1, "");
        } //bulk mints.
    }

    function totalBalance() external view returns (uint256) {
        //gets total balance in account.
        return payable(address(this)).balance;
    }

    //changes withdraw address if needed.
    function changeWithdrawer(address newAddress)
        external
        withdrawAddressCheck
    {
        withdrawAccount = newAddress;
    }

    //withdraws all eth funds.
    function withdrawFunds() external withdrawAddressCheck {
        (bool success, bytes memory _data) = payable(msg.sender).call{
            value: this.totalBalance()
        }("");
        if (!success) revert FailedToWithdraw();
    }

    //withdraws ERC20 tokens.
    function withdrawERC20(IERC20 erc20Token) external withdrawAddressCheck {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    //sets new baseURI
    function setURI(string calldata URI) external onlyOwner {
        _baseURI = URI;
    }

    function setName(string calldata newName) external onlyOwner {
        name = newName;
    }

    function uri(uint256 tokenId)
        public
        view
        override(ERC1155)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseURI,
                    Strings.toString(tokenId),
                    string(".json")
                )
            );
    }
}