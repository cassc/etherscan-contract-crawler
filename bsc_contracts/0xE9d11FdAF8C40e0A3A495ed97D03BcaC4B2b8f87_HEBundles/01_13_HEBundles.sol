// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
interface BlackList { 
	function getTokenId(address _token, uint256 tokenId) external view returns(uint256);
}
contract HEBundles is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => bool) public paymentTokens;
    mapping(bytes => bool) public usedSignatures;
   
    address public blacklist;
    address payable public feeToAddress;
    uint256 public transactionFee;
    uint256 public period;
    // Events
    event MatchTransaction(
        address seller,
        address buyer,
        string bundleId,
        uint256[] tokenId,
        address paymentToken,
        address contractAddress           
    );
    event Cancel(
        string IdBundle,
        address contractAddress, 
        uint256 timeCancel
    );
    function setBlackList(address _blacklist) public onlyOwner {
        blacklist = _blacklist;
    }
    function setPeriod(uint256 _period) public onlyOwner {
        period = _period;
    }   
    function setFeeToAddress(address payable _feeToAddress) public onlyOwner {
        feeToAddress = _feeToAddress;
    }

    function setTransactionFee(uint256 _transactionFee) public onlyOwner {
        transactionFee = _transactionFee;
    }

    function setPaymentTokens(address[] calldata _paymentTokens)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _paymentTokens.length; i++) {
            if (paymentTokens[_paymentTokens[i]] == true) {
                continue;
            }

            paymentTokens[_paymentTokens[i]] = true;
        }
    }

    function removePaymentTokens(address[] calldata _removedPaymentTokens)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _removedPaymentTokens.length; i++) {
            paymentTokens[_removedPaymentTokens[i]] = false;
        }
    }
    function matchTransaction(
        address[3] calldata addresses,
        uint256[2] calldata values,
        uint256[] memory tokenId,
        string memory IdBundle,
        bytes calldata signature
    ) external payable returns (bool) {
        require(
            paymentTokens[addresses[2]] == true,
            "Marketplace: invalid payment method"
        );
        require(
            tokenId.length <= 50, 
            "exceed list"
        );

        require(
            !usedSignatures[signature],
            "Marketplace: signature used."
        );
   
        bytes32 criteriaMessageHash = getMessageHash(
            addresses[1],
            IdBundle,
            tokenId,
            addresses[2],
            values[0],
            values[1]
        );

        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(
            criteriaMessageHash
        );

        require(
            ECDSA.recover(ethSignedMessageHash, signature) == addresses[0],
            "Marketplace: invalid seller signature"
        );

        require( 
            values[1].add(period) > block.timestamp && values[1] < block.timestamp,
            "Marketplace: item sold out"
        );
        // check current ownership
        IERC721 nft = IERC721(addresses[1]);

        // transfer multi tokenId
        BlackList list = BlackList(blacklist);
        for(uint256 i =0; i < tokenId.length; i++){
            require(
            nft.ownerOf(tokenId[i]) == addresses[0],
            "Marketplace: seller is not owner of this item now"
            );
            require(list.getTokenId(addresses[1],tokenId[i]) < block.timestamp, "TokenId in blacklist");
            // transfer item to buyer
            nft.safeTransferFrom(addresses[0], _msgSender(), tokenId[i]);
        }
        IERC20 paymentContract = IERC20(addresses[2]);
        require(
            paymentContract.balanceOf(_msgSender()) >= values[0],
            "Marketplace: buyer doesn't have enough token to buy this item"
        );
        require(
            paymentContract.allowance(_msgSender(), address(this)) >= values[0],
            "Marketplace: buyer doesn't approve marketplace to spend payment amount"
        );
        usedSignatures[signature] = true;
        Payment(values[0],addresses[0],paymentContract);
        // emit sale event
        emitEvent(addresses, tokenId, IdBundle);

        return true;
    }
    function emitEvent(
        address[3] calldata addresses,
        uint256[] memory tokenId,
        string memory IdBundle
    ) internal {
        emit MatchTransaction(
            addresses[0],
            _msgSender(),
            IdBundle,
            tokenId,
            addresses[2],
            addresses[1]
        );
    }
    function Payment(uint256 amount, address receiver, IERC20 paymentContract) internal {
         // We divide by 10000 to support decimal value such as 5% => 50 / 1000
        uint256 fee = transactionFee.mul(amount).div(1000);
        uint256 payToSellerAmount = amount.sub(fee);
        // payable(addresses[0]).transfer(payToSellerAmount);
        paymentContract.safeTransferFrom(_msgSender(), receiver, payToSellerAmount);
        // transfer fee to address
        if (fee > 0) {
            paymentContract.safeTransferFrom(_msgSender(), feeToAddress, fee);
            // feeToAddress.transfer(fee);
        }
    }

    function cancelListing(
        address[3] calldata addresses,
        uint256[2] calldata values,
        uint256[] memory tokenId,
        string memory IdBundle,
        bytes calldata signature
    ) external returns (bool) { 
        require(
            paymentTokens[addresses[2]] == true,
            "Marketplace: invalid payment method"
        );
        bytes32 criteriaMessageHash = getMessageHash(
            addresses[1],
            IdBundle,
            tokenId,
            addresses[2],
            values[0],
            values[1]
        ); 
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(
            criteriaMessageHash
        );
        require(
            ECDSA.recover(ethSignedMessageHash, signature) == msg.sender,
            "Marketplace: invalid seller signature"
        );
        usedSignatures[signature] = true;
        emit Cancel(
            IdBundle,
            addresses[1],
            block.timestamp
        );
        return true;
    } 

    function getMessageHash(
        address _nftAddress,
        string memory _IdBundle,
        uint256[] memory _tokenId,
        address _paymentErc20,
        uint256 _price, 
        uint256 _saltNonce
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _nftAddress,
                    _IdBundle,
                    _tokenId,
                    address(this),
                    _paymentErc20,
                    _price,
                    _saltNonce 
                )
            );
    }
}