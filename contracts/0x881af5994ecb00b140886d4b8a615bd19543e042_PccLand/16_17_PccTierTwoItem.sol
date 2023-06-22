// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "solmate/tokens/ERC1155.sol";
import "src/PccToken.sol";
import "src/PccTierTwo.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./PccTierTwo.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";




contract PccTierTwoItem is ERC1155, Ownable {
    using Strings for uint256;
    PccToken public TokenContract;
    PccTierTwo public TierTwo;

    string public symbol = "PTTI";
    string public name = "PCC Tier Two Item";

    uint256[6] public ItemPrice;
    string public BaseUri;

    bool[6] public IsForSale;

    constructor(PccTierTwo _tierTwo) {

        TierTwo = _tierTwo;
    }

    function purchaseTierTwo(uint256 _ticketId, uint256 _quantity) public {
        require(
            balanceOf[msg.sender][_ticketId] >= _quantity,
            "not enough tickets"
        );
        require(IsForSale[_ticketId], "not for sale currently");

        _burn(msg.sender, _ticketId, _quantity);
        TierTwo.mint(_ticketId, _quantity, msg.sender);
    }

    function purchaseTicket(uint256 _ticketId, uint256 _quantity) public {
        uint256 price = ItemPrice[_ticketId];
        require(price > 0, "sale not open for this item");

        TokenContract.payForTierTwoItem(msg.sender, price * _quantity);
        _mint(msg.sender, _ticketId, _quantity, "");
    }

    function uri(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(BaseUri, id.toString()));
    }

    function setPricePerTicket(uint256 _ticketId, uint256 _price)
        external
        onlyOwner
    {
        ItemPrice[_ticketId] = _price * 1 ether;
    }

    function setTokenContract(PccToken _token) external onlyOwner {
        TokenContract = _token;
    }

    function setUri(string calldata _baseUri) external onlyOwner {
        BaseUri = _baseUri;
    }

    function setIsForSale(bool _isForSale, uint256 _ticketId)
        external
        onlyOwner
    {
        IsForSale[_ticketId] = _isForSale;
    }

    	function withdrawTokens(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}

}