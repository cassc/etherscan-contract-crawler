//SPDX-License-Identifier: MIT
//Fringe Drifters Lykenrot Contract Created by Swifty.eth
//Legal: https://fringedrifters.com/terms

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
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
error NoScene();

contract LykenrotShootoutDrifter is ERC1155, Ownable {
    string public name = "Shootout at Lykenrot - Fringe Drifters";
    string public symbol = "SALFD";

    uint256 internal maxUint = type(uint256).max;

    address private withdrawAccount =
        0x8ff8657929a02c0E15aCE37aAC76f47d1F5fbfC6;

    mapping(string => uint256) public AllCards;

    string internal _baseURI;

    //modifiers.
    modifier withdrawAddressCheck() {
        if (msg.sender != withdrawAccount) revert NotWithdrawAddress();
        _;
    }

    constructor(string memory baseURI) ERC1155("") {
        _baseURI = baseURI;
    }

    function gift(uint256 sceneId, address[] calldata receivers)
        external
        onlyOwner
    {
        //bulk mints.
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], sceneId, 1, "");
        }
    }

    function redeem() external {
        uint256 lowestBalance = maxUint;

        for (uint256 i = 0; i < 4; i++) {
            uint256 sceneBalance = balanceOf(msg.sender, i);
            if (sceneBalance > 0) {
                if (lowestBalance > sceneBalance) {
                    lowestBalance = sceneBalance;
                }
            } else {
                revert NoScene();
            }
        }

        uint256[] memory burnAmounts = new uint256[](4);
        uint256[] memory burnIds = new uint256[](4);

        //to allow the contract to utilize the batch burning logic.
        for (uint256 i = 0; i < 4; i++) {
            burnAmounts[i] = lowestBalance;
            burnIds[i] = i;
        }

        _burnBatch(msg.sender, burnIds, burnAmounts);

        _mint(msg.sender, 4, lowestBalance, "");
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
        (bool success, bytes memory __) = payable(msg.sender).call{
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