// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PawnShop is Ownable, IERC721Receiver {
    using SafeMath for uint256;

    enum LoanState {
        OPEN,
        CLOSED,
        FORCE_CLOSED
    }

    struct Loan {
        uint256 id;
        address owner;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        uint256 contractEndTimestamp;
        LoanState state;
    }

    address signerAddress = 0x2aBe359A40ccC9A51CE76B29ceFfE16EBBF5a3FA;

    address usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint256 monthlyFee = 525; // 5.25%
    uint256 originFee = 300; // 3%

    uint256 MONTH_SECONDS = 2592000;

    mapping(uint256 => Loan) public loans;
    uint256 public totalCnt;

    constructor() {}

    function adminChangeMonthlyFee(uint256 _fee) public onlyOwner {
        monthlyFee = _fee;
    }

    function adminChangeOriginFee(uint256 _fee) public onlyOwner {
        originFee = _fee;
    }

    function adminForceClose(uint256 _id) public onlyOwner {
        ERC721(loans[_id].tokenAddress).transferFrom(
            address(this),
            msg.sender,
            loans[_id].tokenId
        );
        loans[_id].state = LoanState.FORCE_CLOSED;
    }

    function adminWithdrawUSDT(uint256 _amount) public onlyOwner {
        ERC20(usdtAddress).transferFrom(address(this), msg.sender, _amount);
    }

    function adminSetUSDTAddress(address _addr) public onlyOwner {
        usdtAddress = _addr;
    }

    function adminSetSignerAddress(address _addr) public onlyOwner {
        signerAddress = _addr;
    }

    function getSigner(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(_tokenAddress, _tokenId, _amount)
        );
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address signer = ECDSA.recover(message, signature);
        return signer;
    }

    function openALoan(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _message
    ) public returns (uint256) {
        address signer = getSigner(_tokenAddress, _tokenId, _amount, _message);
        require(signer == signerAddress, "Permission denied.");

        ERC721(_tokenAddress).transferFrom(msg.sender, address(this), _tokenId);
        ERC20(usdtAddress).transfer(msg.sender, _amount * 10**ERC20(usdtAddress).decimals());
        totalCnt++;
        loans[totalCnt] = Loan(
            totalCnt,
            msg.sender,
            _tokenAddress,
            _tokenId,
            _amount * 10**ERC20(usdtAddress).decimals(),
            block.timestamp + MONTH_SECONDS,
            LoanState.OPEN
        );

        return totalCnt;
    }

    function updateContractDate(uint256 _id) public {
        require(
            msg.sender == loans[_id].owner,
            "You are not the owner of the contract."
        );
        uint256 fee = (loans[_id].price * monthlyFee) / 10000;
        ERC20(usdtAddress).transferFrom(msg.sender, address(this), fee);
        loans[_id].contractEndTimestamp += MONTH_SECONDS;
    }

    function endLoan(uint256 _id) public {
        require(
            msg.sender == loans[_id].owner,
            "You are not the owner of the contract."
        );
        uint256 fee = (loans[_id].price * (monthlyFee + originFee)) / 10000 + loans[_id].price;
        ERC20(usdtAddress).transferFrom(msg.sender, address(this), fee);
        ERC721(loans[_id].tokenAddress).transferFrom(
            address(this),
            loans[_id].owner,
            loans[_id].tokenId
        );
        loans[_id].state = LoanState.CLOSED;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}