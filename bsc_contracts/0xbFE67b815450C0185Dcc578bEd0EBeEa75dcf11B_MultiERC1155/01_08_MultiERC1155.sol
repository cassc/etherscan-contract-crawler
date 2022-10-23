pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicensed

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IXswapRouter.sol";

contract MultiERC1155 is Ownable {

//    address public paymentToken = 0x17476dc3eda45aD916cEAdDeA325B240A7FB259D;
//    IXswapRouter02 public router = IXswapRouter02(0x3F11A24EB45d3c3737365b97A996949dA6c2EdDf); //todo apothem
//    IXswapRouter02 public router = IXswapRouter02(0xf9c5E4f6E627201aB2d6FB6391239738Cf4bDcf9); //mainnet


    address public paymentToken = address(0x48c516e7c9f4c67cF82c1dDF06c2D5c25658AfFb);//todo bsc test
    IXswapRouter02 public router = IXswapRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //todo bsc test

    uint256 public feeDiscount = 10;

    bool paused;
    mapping(address => uint256) public freeAccessBy;

    uint256 public fee = 100 ether;

    event SendOneEqually(uint256 operationAmount, IERC1155 erc1155Contract);
    event SendOneDifferent(uint256 operationAmount, IERC1155 erc1155Contract);
    event SendManyEqually(uint256[] tokenIds, uint256 operationAmount, IERC1155 erc1155Contract);
    event SendManyDifferent(uint256[] tokenIds, uint256 operationAmount, IERC1155 erc1155Contract);
    event Paused(bool status);
    event SetFee(uint256 amount);
    event addFreeDrop(address account,uint256 amounts);
    event UpdateDiscount(uint256 oldDiscount, uint256 newDiscount);
    event PaymentTokenUpdated(address oldToken, address newToken);
    event addFreeAccess(address account,uint256 amounts);


    modifier checkFee(bool _forTokens) {
        if (freeAccessBy[msg.sender] > 0){
            freeAccessBy[msg.sender] -= 1;
        } else {
            if (_forTokens) {
                require(IERC20(paymentToken).transferFrom(msg.sender,address(this),feeInTokens()));
            } else {
                require(msg.value >= fee, "Insufficient payable amount");
            }
        }
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract paused");
        _;
    }

    function pause(bool status) external onlyOwner {
        paused = status;
        emit Paused(status);
    }

    function addFreeAccessAccount(address account,uint256 amounts) external onlyOwner {
        freeAccessBy[account] += amounts;
        emit addFreeAccess(account, amounts);
    }

    function setFee(uint256 amount) external onlyOwner {
        fee = amount;
        emit SetFee(amount);
    }

    function sendOneEqually(
        IERC1155 erc1155Contract,
        uint256 tokenId,
        uint256 amount,
        address[] calldata receivers,
        bool _forTokens
    ) external payable notPaused checkFee(_forTokens) {
        uint256 operation;
        for (uint256 i; i < receivers.length; i++) {
            try erc1155Contract.safeTransferFrom(msg.sender, receivers[i], tokenId, amount, "") {
                operation++;
            } catch {}
        }
        emit SendOneEqually(operation, erc1155Contract);
    }

    function sendOneDifferent(
        IERC1155 erc1155Contract,
        uint256 tokenId,
        uint256[] calldata amounts,
        address[] calldata receivers,
        bool _forTokens
    ) external payable notPaused checkFee(_forTokens) {
        uint256 operation;
        for (uint256 i; i < receivers.length; i++) {
            try erc1155Contract.safeTransferFrom(msg.sender, receivers[i], tokenId, amounts[i], "") {
                operation++;
            } catch {}
        }
        emit SendOneDifferent(operation, erc1155Contract);
    }

    function sendManyEqually(
        IERC1155 erc1155Contract,
        uint256[] calldata tokenIds,
        uint256 amount,
        address[] calldata receivers,
        bool _forTokens
    ) external payable notPaused checkFee(_forTokens) {
        uint256 operation;
        for (uint256 i; i < receivers.length; i++) {
            try erc1155Contract.safeTransferFrom(msg.sender, receivers[i], tokenIds[i], amount, "") {
                operation++;
            } catch {}
        }
        emit SendManyEqually(tokenIds, operation, erc1155Contract);
    }

    function sendManyDifferent(
        IERC1155 erc1155Contract,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        address[] calldata receivers,
        bool _forTokens
    ) external payable notPaused checkFee(_forTokens)  {
        uint256 operation;
        for (uint256 i; i < receivers.length; i++) {
            try erc1155Contract.safeTransferFrom(msg.sender, receivers[i], tokenIds[i], amounts[i], "") {
                operation++;
            } catch {}
        }
        emit SendManyDifferent(tokenIds, operation, erc1155Contract);
    }

    function feeInTokens() public view returns(uint256) {
        address[] memory path = new address[](2);
//        path[0] = router.WXDC();
        path[0] = router.WETH(); //todo bst testnet
        path[1] = paymentToken;
        uint256[] memory res = router.getAmountsOut(fee, path);
        return res[1] * (100 - feeDiscount) / 100;
    }

    function updatePaymentToken(address tokenAddress) external onlyOwner {
        emit PaymentTokenUpdated(paymentToken,tokenAddress);
        paymentToken = tokenAddress;
    }

    function updateDiscount(uint256 _newDiscount) external onlyOwner {
        emit UpdateDiscount(feeDiscount, _newDiscount);
        feeDiscount = _newDiscount;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}