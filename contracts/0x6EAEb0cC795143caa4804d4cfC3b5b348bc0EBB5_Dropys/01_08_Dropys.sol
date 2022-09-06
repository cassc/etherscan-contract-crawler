// SPDX-License-Identifier: UNLICENSED

/*
 ___    ___    _____  ___    _     _  ___
(  _`\ |  _`\ (  _  )(  _`\ ( )   ( )(  _`\
| | ) || (_) )| ( ) || |_) )`\`\_/'/'| (_(_)
| | | )| ,  / | | | || ,__/'  `\ /'  `\__ \
| |_) || |\ \ | (_) || |       | |   ( )_) |
(____/'(_) (_)(_____)(_)       (_)   `\____)

Start your airdrop: https://dropys.com/

*/
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Dropys is Ownable {
    using SafeMath for uint256;

    uint256 public rate;
    uint256 public dropUnitPrice;
    uint256 public commission;

    mapping (string => uint256) public airdropFeeDiscount;

    event RateChanged(uint256 from, uint256 to);

    event TokenAirdrop(address indexed by, address indexed tokenAddress, uint256 totalTransfers);
    event EthAirdrop(address indexed by, uint256 totalTransfers, uint256 ethValue);
    event NFTAirdrop(address indexed by, address indexed tokenAddress, uint256 totalTransfers);

    event CommissionChanged(uint256 oldValue, uint256 newValue);
    event CommissionPaid(address indexed to, uint256 value);

    event ERC20TokensWithdrawn(address token, address sentTo, uint256 value);

    constructor() {
        rate = 50000000000000000;
        dropUnitPrice = 1e14;
        commission = 3;
    }

    /**
     * Allows for the distribution of Ether to be transferred to multiple recipients at
     * a time. This function only facilitates batch transfers of constant values (i.e., all recipients
     * will receive the same amount of tokens).
     *
     * @param _recipients The list of addresses which will receive tokens.
     * @param _value The amount of tokens all addresses will receive.
     * @param _affiliateAddress The affiliate address that is paid a commission.affiliated with a partner, they will provide this code so that
     * the parter is paid commission.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function dropysAirdropNativeTokenS(address[] memory _recipients, uint256 _value, address _affiliateAddress, string memory _discountCode) public payable returns(bool) {
        uint256 price = _recipients.length.mul(dropUnitPrice);
        uint256 totalCost = _value.mul(_recipients.length).add(price);

        require(
            msg.value >= totalCost,
            "Not enough ETH sent with transaction!"
        );

        distributeCommission(_recipients.length, _affiliateAddress, _discountCode);

        giveChange(totalCost);

        for(uint i=0; i<_recipients.length; i++) {
            if (_recipients[i] != address(0)) {
                payable(_recipients[i]).transfer(_value);
            }
        }

        emit EthAirdrop(msg.sender, _recipients.length, _value.mul(_recipients.length));

        return true;
    }

    function _getTotalEthValue(uint256[] memory _values) internal pure returns(uint256) {
        uint256 totalVal = 0;

        for(uint i = 0; i < _values.length; i++) {
            totalVal = totalVal.add(_values[i]);
        }

        return totalVal;
    }

    /**
     * Allows for the distribution of Ether to be transferred to multiple recipients at
     * a time.
     *
     * @param _recipients The list of addresses which will receive tokens.
     * @param _values The corresponding amounts that the recipients will receive
     * @param _affiliateAddress The affiliate address that is paid a commission.affiliated with a partner, they will provide this code so that
     * the parter is paid commission.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function dropysAirdropNativeToken(address[] memory _recipients, uint256[] memory _values, address _affiliateAddress, string memory _discountCode) public payable returns(bool) {
        require(_recipients.length == _values.length, "Total number of recipients and values are not equal");

        uint256 totalEthValue = _getTotalEthValue(_values);
        uint256 price = _recipients.length.mul(dropUnitPrice);
        uint256 totalCost = totalEthValue.add(price);

        require(
            msg.value >= totalCost,
            "Not enough ETH sent with transaction!"
        );

        distributeCommission(_recipients.length, _affiliateAddress, _discountCode);

        giveChange(totalCost);

        for(uint i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0) && _values[i] > 0) {
                payable(_recipients[i]).transfer(_values[i]);
            }
        }

        emit EthAirdrop(msg.sender, _recipients.length, totalEthValue);

        return true;
    }


    /**
     * Allows for the distribution of an ERC20 token to be transferred to multiple recipients at
     * a time. This function only facilitates batch transfers of constant values (i.e., all recipients
     * will receive the same amount of tokens).
     *
     * @param _addressOfToken The contract address of an ERC20 token.
     * @param _recipients The list of addresses which will receive tokens.
     * @param _value The amount of tokens all addresses will receive.
     * @param _affiliateAddress The affiliate address that is paid a commission.affiliated with a partner, they will provide this code so that
     * the parter is paid commission.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function dropysAirdropTokenS(address _addressOfToken,  address[] memory _recipients, uint256 _value, address _affiliateAddress, string memory _discountCode) public payable returns(bool) {
        IERC20 token = IERC20(_addressOfToken);

        uint256 price = _recipients.length.mul(dropUnitPrice);

        require(
            msg.value >= price,
            "Not enough ETH sent with transaction!"
        );

        giveChange(price);

        for(uint i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0)) {
                token.transferFrom(msg.sender, _recipients[i], _value);
            }
        }

        distributeCommission(_recipients.length, _affiliateAddress, _discountCode);

        emit TokenAirdrop(msg.sender, _addressOfToken, _recipients.length);

        return true;
    }


    /**
     * Allows for the distribution of an ERC20 token to be transferred to multiple recipients at
     * a time. This function facilitates batch transfers of differing values (i.e., all recipients
     * can receive different amounts of tokens).
     *
     * @param _addressOfToken The contract address of an ERC20 token.
     * @param _recipients The list of addresses which will receive tokens.
     * @param _values The corresponding values of tokens which each address will receive.
     * @param _affiliateAddress The affiliate address that is paid a commission.affiliated with a partner, they will provide this code so that
     * the parter is paid commission.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function dropysAirdropToken(address _addressOfToken,  address[] memory _recipients, uint256[] memory _values, address _affiliateAddress, string memory _discountCode) public payable returns(bool) {
        IERC20 token = IERC20(_addressOfToken);
        require(_recipients.length == _values.length, "Total number of recipients and values are not equal");

        uint256 price = _recipients.length.mul(dropUnitPrice);

        require(
            msg.value >= price,
            "Not enough ETH sent with transaction!"
        );

        giveChange(price);

        for(uint i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0) && _values[i] > 0) {
                token.transferFrom(msg.sender, _recipients[i], _values[i]);
            }
        }

        distributeCommission(_recipients.length, _affiliateAddress, _discountCode);

        emit TokenAirdrop(msg.sender, _addressOfToken, _recipients.length);

        return true;
    }

    /**
     * Allows for the distribution of an ERC721 token to be transferred to multiple recipients at
     * a time.
     *
     * @param _recipients The list of addresses which will receive tokens.
     * @param _nftContract The NFT collection contract where tokens are sent from.
     * @param _startingTokenId The starting token id to begin incrementing from
     * @param _affiliateAddress The affiliate address that is paid a commission.affiliated with a partner, they will provide this code so that
     * the parter is paid commission.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function dropysAirdropNftI(address[] memory _recipients, address _nftContract, uint256 _startingTokenId, address _affiliateAddress, string memory _discountCode) public payable returns(bool) {
        uint256 price = _recipients.length.mul(dropUnitPrice);

        require(
            msg.value >= price,
            "Not enough ETH sent with transaction!"
        );

        giveChange(price);

        for(uint i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0)) {
                IERC721(_nftContract).safeTransferFrom(msg.sender, _recipients[i], _startingTokenId + i);
            }
        }

        distributeCommission(_recipients.length, _affiliateAddress, _discountCode);

        emit NFTAirdrop(msg.sender, _nftContract, _recipients.length);
        return true;
    }

    /**
     * Allows for the distribution of an ERC721 token to be transferred to multiple recipients at
     * a time.
     *
     * @param _recipients The list of addresses which will receive tokens.
     * @param _nftContract The NFT collection contract where tokens are sent from.
     * @param _tokenIds The list of ids being sent.
     * @param _affiliateAddress The affiliate address that is paid a commission.affiliated with a partner, they will provide this code so that
     * the parter is paid commission.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function dropysAirdropNft(address[] memory _recipients, address _nftContract, uint256[] memory _tokenIds, address _affiliateAddress, string memory _discountCode) public payable returns(bool) {
        uint256 price = _recipients.length.mul(dropUnitPrice);

        require(
            msg.value >= price,
            "Not enough ETH sent with transaction!"
        );

        giveChange(price);

        for(uint i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0)) {
                IERC721(_nftContract).safeTransferFrom(msg.sender, _recipients[i], _tokenIds[i]);
            }
        }

        distributeCommission(_recipients.length, _affiliateAddress, _discountCode);

        emit NFTAirdrop(msg.sender, _nftContract, _recipients.length);
        return true;
    }

    /**
     * Allows for the distribution of an ERC721 token to be transferred to multiple recipients at
     * a time.
     *
     * @param _recipients The list of addresses which will receive tokens.
     * @param _nftContract The NFT collection contract where tokens are sent from.
     * @param _tokenId The id being sent.
     * @param _amount The amount being sent.
     * @param _affiliateAddress The affiliate address that is paid a commission.affiliated with a partner, they will provide this code so that
     * the parter is paid commission.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function dropysAirdropNftsS(address[] memory _recipients, address _nftContract, uint256 _tokenId, uint256 _amount, address _affiliateAddress, string memory _discountCode) public payable returns(bool) {
        uint256 price = _recipients.length.mul(dropUnitPrice);

        require(
            msg.value >= price,
            "Not enough ETH sent with transaction!"
        );

        giveChange(price);

        for(uint i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0)) {
                IERC1155(_nftContract).safeTransferFrom(msg.sender, _recipients[i], _tokenId, _amount, "");
            }
        }

        distributeCommission(_recipients.length, _affiliateAddress, _discountCode);

        emit NFTAirdrop(msg.sender, _nftContract, _recipients.length);
        return true;
    }

    /**
     * Allows for the distribution of an ERC721 token to be transferred to multiple recipients at
     * a time.
     *
     * @param _recipients The list of addresses which will receive tokens.
     * @param _nftContract The NFT collection contract where tokens are sent from.
     * @param _tokenIds The list of ids being sent.
     * @param _amounts The amounts being sent.
     * @param _affiliateAddress The affiliate address that is paid a commission.affiliated with a partner, they will provide this code so that
     * the parter is paid commission.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function dropysAirdropNfts(address[] memory _recipients, address _nftContract, uint256[] memory _tokenIds, uint256[] memory _amounts, address _affiliateAddress, string memory _discountCode) public payable returns(bool) {
        uint256 price = _recipients.length.mul(dropUnitPrice);

        if (!stringsAreEqual(_discountCode, "") && airdropFeeDiscount[_discountCode] > 0) {
            price = price * airdropFeeDiscount[_discountCode] / 100;
        }

        require(
            msg.value >= price,
            "Not enough ETH sent with transaction!"
        );

        giveChange(price);

        for(uint i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0)) {
                IERC1155(_nftContract).safeTransferFrom(msg.sender, _recipients[i], _tokenIds[i], _amounts[i], "");
            }
        }

        distributeCommission(_recipients.length, _affiliateAddress, _discountCode);

        emit NFTAirdrop(msg.sender, _nftContract, _recipients.length);
        return true;
    }

    /**
     * Allows for the price of drops to be changed by the owner of the contract. Any attempt made by
     * any other account to invoke the function will result in a loss of gas and the price will remain
     * untampered.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function setRate(uint256 _newRate) public onlyOwner returns(bool) {
        require(
            _newRate != rate
            && _newRate > 0
        );

        emit RateChanged(rate, _newRate);

        rate = _newRate;
        uint256 eth = 1 ether;
        dropUnitPrice = eth.div(rate);

        return true;
    }

    /**
     * Allows users to query the discount for a code. This is useful to verify that a discount has been set.
     *
     * @param _discountCode The code associated with the discount.
     *
     * @return fee The discount for the code.
     * */
    function getDiscountForCode(string memory _discountCode) public view returns(uint256 fee) {
        if (airdropFeeDiscount[_discountCode] > 0) {
            return airdropFeeDiscount[_discountCode];
        }
        return 0;
    }

    /**
     * Allows the owner of the contract to set a discount for a specified address.
     *
     * @param _discountCode The code that will receive the discount.
     * @param _discount The discount that will be applied.
     *
     * @return success True if function executes successfully, false otherwise.
     * */
    function setAirdropFeeDiscount(string memory _discountCode, uint256 _discount) public onlyOwner returns(bool success) {
        airdropFeeDiscount[_discountCode] = _discount;
        return true;
    }

    /**
    * Send the owner and affiliates commissions.
    **/
    function distributeCommission(uint256 _drops, address _affiliateAddress, string memory _discountCode) internal {
        uint256 price = dropUnitPrice;

        if (!stringsAreEqual(_discountCode, "") && airdropFeeDiscount[_discountCode] > 0) {
            price = price * airdropFeeDiscount[_discountCode] / 100;
        }

        if (_affiliateAddress != address(0) && _affiliateAddress != msg.sender) {
            uint256 profitSplit = _drops.mul(price).div(commission);
            uint256 remaining = _drops.mul(price).sub(profitSplit);

            payable(owner()).transfer(remaining);
            payable(_affiliateAddress).transfer(profitSplit);

            emit CommissionPaid(_affiliateAddress, profitSplit);
        } else {
            payable(owner()).transfer(_drops.mul(price));
        }
    }

    /**
     * Allows for any ERC20 tokens which have been mistakenly  sent to this contract to be returned
     * to the original sender by the owner of the contract. Any attempt made by any other account
     * to invoke the function will result in a loss of gas and no tokens will be transferred out.
     *
     * @param _addressOfToken The contract address of an ERC20 token.
     * @param _recipient The address which will receive tokens.
     * @param _value The amount of tokens to refund.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function withdrawERC20Tokens(address _addressOfToken,  address _recipient, uint256 _value) public onlyOwner returns(bool){
        require(
            _addressOfToken != address(0)
            && _recipient != address(0)
            && _value > 0
        );

        IERC20 token = IERC20(_addressOfToken);
        token.transfer(_recipient, _value);

        emit ERC20TokensWithdrawn(_addressOfToken, _recipient, _value);

        return true;
    }

    /**
    * Used to give change to users who accidentally send too much ETH to payable functions.
    *
    * @param _price The service fee the user has to pay for function execution.
    **/
    function giveChange(uint256 _price) internal {
        if (msg.value > _price) {
            uint256 change = msg.value.sub(_price);
            payable(msg.sender).transfer(change);
        }
    }

    /**
     * Allows for the affiliate commission to be changed by the owner of the contract. Any attempt made by
     * any other account to invoke the function will result in a loss of gas and the price will remain
     * untampered.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function setCommission(uint256 _newCommission) public onlyOwner returns(bool) {
        require(
            _newCommission != commission
        );

        emit CommissionChanged(commission, _newCommission);

        commission = _newCommission;

        return true;
    }

    /**
     * Allows for the allowance of a token from its owner to this contract to be queried.
     *
     * As part of the ERC20 standard all tokens which fall under this category have an allowance
     * function which enables owners of tokens to allow (or give permission) to another address
     * to spend tokens on behalf of the owner. This contract uses this as part of its protocol.
     * Users must first give permission to the contract to transfer tokens on their behalf, however,
     * this does not mean that the tokens will ever be transferrable without the permission of the
     * owner. This is a security feature which was implemented on this contract. It is not possible
     * for the owner of this contract or anyone else to transfer the tokens which belong to others.
     *
     * @param _addr The address of the token's owner.
     * @param _addressOfToken The contract address of the ERC20 token.
     *
     * @return The ERC20 token allowance from token owner to this contract.
     * */
    function getTokenAllowance(address _addr, address _addressOfToken) public view returns(uint256) {
        IERC20 token = IERC20(_addressOfToken);
        return token.allowance(_addr, address(this));
    }

    /**
    * Checks if two strings are the same.
    *
    * @param _a String 1
    * @param _b String 2
    *
    * @return True if both strings are the same. False otherwise.
    **/
    function stringsAreEqual(string memory _a, string memory _b) internal pure returns(bool) {
        bytes32 hashA = keccak256(abi.encodePacked(_a));
        bytes32 hashB = keccak256(abi.encodePacked(_b));
        return hashA == hashB;
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }
}