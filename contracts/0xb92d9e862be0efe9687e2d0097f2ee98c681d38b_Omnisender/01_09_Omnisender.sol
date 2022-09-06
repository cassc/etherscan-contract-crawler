// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title Omnisender
 *
 * @notice allows for distribution of any standard tokens to multiple addresses
 */
contract Omnisender is OwnableUpgradeable {

    // flag for discounts
    bool private discountEnabled;
    // fee charged in native token
    uint256 public fee;
    // counter for number of times an address has used Omnisender
    mapping(address => uint256) public uses;

    constructor() {}

    /**
     @dev initialize the fee
     @param _fee the fee in wei
     */
    function initialize(
        uint256 _fee
    ) external initializer {
        __Ownable_init();
        fee = _fee;
        discountEnabled = false;
    }

    /**
     @notice distributes the native token to recipients
     @param recipients the addresses receiving the tokens
     @param amounts the amounts each address should receive
     */
    function distributeETH(
        address[] calldata recipients, 
        uint256[] calldata amounts
    ) external payable incrementUses {
        require(recipients.length == amounts.length, "Mismatched input lengths");
        uint256 total = calculateFee();
        for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(amounts[i]);
            total += amounts[i];
        }
        require(total == msg.value, "Invalid fee amount");
    }

    /**
     @notice distributes ERC20 tokens to the recipients
     @param recipients the addresses receiving the tokens
     @param amounts the amounts each address should receive
     */
    function distributeERC20(
        address token, 
        address[] calldata recipients, 
        uint256[] calldata amounts
    ) external payable incrementUses{
        require(msg.value == calculateFee(), "Invalid fee amount");
        IERC20 erc20 = IERC20(token);
        require(recipients.length == amounts.length, "Mismatched input lengths");
        for (uint256 i = 0; i < recipients.length; i++) {
            erc20.transferFrom(msg.sender, recipients[i], amounts[i]);
        }
    }

    /**
     @notice distributes ERC1155 tokens to the recipients
     @param recipients the addresses receiving the tokens
     @param ids the ID of each token to send to each address
     @param amounts the amounts each address should receive of the corresponding token ID
     */
    function distributeERC1155(
        address token, 
        address[] calldata recipients, 
        uint256[] calldata ids, 
        uint256[] calldata amounts
    ) external payable incrementUses {
        require(msg.value == calculateFee(), "Invalid fee amount");        
        IERC1155 erc1155 = IERC1155(token);
        require(recipients.length == amounts.length, "Mismatched input lengths");
        require(recipients.length == ids.length, "Mismatched input lengths");
        for (uint256 i = 0; i < recipients.length; i++) {
            erc1155.safeTransferFrom(msg.sender, recipients[i], ids[i], amounts[i], "");
        }
    }

    /**
     @notice distributes ERC721 tokens to the recipients
     @param recipients the addresses receiving the tokens
     @param ids the ID of each token to send to the corresponding address
     */
    function distributeERC721(
        address token, 
        address[] calldata recipients, 
        uint256[] calldata ids
    ) external payable incrementUses {
        require(msg.value == calculateFee(), "Invalid fee amount");
        IERC721 erc721 = IERC721(token);
        require(recipients.length == ids.length, "Mismatched input lengths");
        for (uint256 i = 0; i < recipients.length; i++) {
            erc721.transferFrom(msg.sender, recipients[i], ids[i]);
        }
    }

    /**
     @dev updates the fee
     @param _fee the new fee in wei
     */
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    /**
     @dev enables / disables the discount feature
     @param _enabled whether or not it should be enabled
     */
    function setDiscountEnabled(bool _enabled) external onlyOwner {
        discountEnabled = _enabled;
    }

    /**
     @dev withdraws fees to the contract owner
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     @dev calculates the fee based on whether the discount is enabled
     * 10% discount for each use
     */
    function calculateFee() internal view returns(uint256) {
        if (!discountEnabled) return fee;
        uint256 use = uses[msg.sender] > 8 ? 8 : uses[msg.sender];
        return fee - (use * fee / 10);
    }

    /**
     @dev tracks the number of times an address has used the contract
     */
    modifier incrementUses() {
        _;
        uses[msg.sender] += 1;
    }
}