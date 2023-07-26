// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

contract ClickCreatePrepay is Ownable {
    
    error NoErroneousPayments();
    error IncorrectPrePayAmount();
    error TooFewMints();
    error NoPassOwned();
    error PaymentFailed();

    event MintDone(uint256 timestamp);
    event PrepayPriceChanged(uint256 oldPrepayPrice, uint256 newPrepayPrice, uint256 timestamp);
    event PrepayCreated(address indexed prepayUser, uint256 indexed prepayAmount, address indexed passContract, uint256 passTokenId, uint256 prepayPrice, uint256 timestamp);

    address payable public prepayBeneficiary;
    uint256 public prepayPrice;
    uint256 public prepayMinMints = 1;

    IERC1155 public passContract;
    uint256 public passTokenId;

    constructor(address _prepayBeneficiary, uint256 _prepayPrice, address _passContract, uint256 _passTokenId) {
        prepayBeneficiary = payable(_prepayBeneficiary);
        prepayPrice = _prepayPrice;
        passContract = IERC1155(_passContract);
        passTokenId = _passTokenId;
    }

    function createPrepay(address prepayUser, uint256 prepayAmount) external payable {
        if (prepayAmount < prepayMinMints) {
            revert TooFewMints();
        }
        if (msg.value != prepayPrice * prepayAmount || msg.value == 0) {
            revert IncorrectPrePayAmount();
        }
        if (passContract.balanceOf(prepayUser, passTokenId) == 0) {
            revert NoPassOwned();
        }

        (bool success, ) = prepayBeneficiary.call{value: msg.value}("");
        if (!success) {
            revert PaymentFailed();
        }

        emit PrepayCreated(prepayUser, prepayAmount, address(passContract), passTokenId, prepayPrice, block.timestamp);
    }

    function userMintComplete(uint256 timestamp) external onlyOwner {
        emit MintDone(timestamp);
    }

    receive() external payable {
        revert NoErroneousPayments();
    }

    fallback() external payable {
        revert NoErroneousPayments();
    }

    function getInfo(address user) external view returns (
      uint256 balance,
      bool hasPass,
      address _prepayBeneficiary,
      uint256 _prepayPrice,
      uint256 _prepayMinMints,
      address _owner
    ) {
        balance = user.balance;
        hasPass = passContract.balanceOf(user, passTokenId) > 0;
        _prepayBeneficiary = prepayBeneficiary;
        _prepayPrice = prepayPrice;
        _prepayMinMints = prepayMinMints;
        _owner = owner();
    }

    function setPrepayBeneficiary(address payable _prepayBeneficiary) public onlyOwner {
        prepayBeneficiary = _prepayBeneficiary;
    }

    function setPrepayPrice(uint256 _prepayPrice) public onlyOwner {
        prepayPrice = _prepayPrice;
        emit PrepayPriceChanged(prepayPrice, _prepayPrice, block.timestamp);
    }

    function setPrepayMinMints(uint256 _prepayMinMints) public onlyOwner {
        prepayMinMints = _prepayMinMints;
    }

    function setPassContract(address _passContract) public onlyOwner {
        passContract = IERC1155(_passContract);
    }

    function setPassTokenId(uint256 _passTokenId) public onlyOwner {
        passTokenId = _passTokenId;
    }

}