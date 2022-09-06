// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-0.8/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-0.8/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts-0.8/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/utils/Strings.sol";

contract MarketPlaceERC1155 is IERC1155Receiver, Ownable, ReentrancyGuard {
    IERC1155 private immutable _ierc1155;
    mapping(uint256 => uint256) private _unitPrice;
    address payable private _recipient;
    bool private _redirect;
    bool private _allowSell;

    constructor(
        IERC1155 ierc1155,
        uint256[] memory tokenIds,
        uint256[] memory unitPriceInETH,
        address payable recipient
    ) {
        _ierc1155 = ierc1155;
        _setUnitPrice(tokenIds, unitPriceInETH);
        _recipient = recipient;
        _redirect = true;
        _allowSell = false;
    }

    function _setUnitPrice(uint256[] memory tokenIds, uint256[] memory unitPriceInETH) internal {
        require(tokenIds.length == unitPriceInETH.length, "TokenIds and unitPriceInETH should have same length.");
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _unitPrice[tokenIds[i]] = unitPriceInETH[i];
        }
    }

    event MarketPlaceERC1155Recipient(address payable _recipient);
    event MarketPlaceERC1155UnitPrice(uint256[] _unitPrice);
    event MarketPlaceERC1155Retrieved(address _receiver, uint256[] _amountsRetrived);
    event MarketPlaceERC1155Buy(address _receiver, uint256[] _tokenIds, uint256[] _amounts, uint256[] _unitPrice, uint256 _priceInETH);

    /// @notice Buy IERC1155 tokens with ether.
    /// @param tokenIds The ids of the IERC1155 token
    /// @param amounts The amounts of the IERC1155 token to buy
    function buy(uint256[] calldata tokenIds, uint256[] calldata amounts) external nonReentrant payable {
        uint256 amountPayed = msg.value;
        require(amountPayed > 0, "You must send some ether.");

        uint256[] memory unitPrices = _getUnitPrice(tokenIds);
        uint256[] memory _tokenBalances = _balances(address(this),tokenIds);
        uint256 sellAmount = 0;
        for (uint256 i = 0; i < unitPrices.length; ++i) {
            require(_tokenBalances[i] >= amounts[i], string(abi.encodePacked("There are not enough tokens ", Strings.toString(tokenIds[i]), " for sale: ", Strings.toString(_tokenBalances[i]))));
            sellAmount = sellAmount + unitPrices[i] * amounts[i];
        } 
        require(amountPayed == sellAmount, string(abi.encodePacked("sell amount: ", Strings.toString(sellAmount), " does not match payment: ", Strings.toString(amountPayed))));
        if(_redirect){
            (bool success, ) = payable(_recipient).call{value: amountPayed}("");
            require(success, string(abi.encodePacked("Tranfer to ", _recipient, " Failed. ")));
        }

        _ierc1155.safeBatchTransferFrom(
            address(this),
            _msgSender(),
            tokenIds,
            amounts,
            ""
        );

        emit MarketPlaceERC1155Buy(_msgSender(), tokenIds, amounts, unitPrices, sellAmount);
    }

    /// @notice retrieve all IERC1155 tokens from contract to an address.
    /// @param recipient The address that will receive all IERC1155 tokens.
    /// @param tokenIds The token ids to receive.
    function retrieveAt(address recipient, uint256[] calldata tokenIds) external nonReentrant onlyOwner {
        uint256[] memory marketPlaceBalance = _balances(address(this), tokenIds);
        _ierc1155.safeBatchTransferFrom(
            address(this),
            recipient,
            tokenIds,
            marketPlaceBalance,
            ""
        );
        emit MarketPlaceERC1155Retrieved(recipient, marketPlaceBalance);
    }

    /// @notice retrieve all IERC1155 tokens from contract to msg.sender address.
    /// @param tokenIds The token ids to receive.
    function retrieve(uint256[] calldata tokenIds) external nonReentrant onlyOwner {
        uint256[] memory marketPlaceBalance = _balances(address(this), tokenIds);
        _ierc1155.safeBatchTransferFrom(
            address(this),
            _msgSender(),
            tokenIds,
            marketPlaceBalance,
            ""
        );
        emit MarketPlaceERC1155Retrieved(_msgSender(), marketPlaceBalance);
    }

    /// @notice return the IERC1155 amount price in wei.
    function getPrice(uint256[] calldata tokenIds, uint256[] calldata amounts) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](tokenIds.length);
        require(tokenIds.length == amounts.length, "TokenIds and amounts should have same length.");
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require(_unitPrice[tokenIds[i]] != 0, string(abi.encodePacked("Tokens are not sold on this market place: ", Strings.toString(tokenIds[i]))));
            prices[i] = amounts[i] * _unitPrice[tokenIds[i]];
        }
        return prices;
    }

    /// @notice return the IERC1155 token address.
    function getERC1155Address() external view returns (address) {
        return address(_ierc1155);
    }

    /// @notice set the market place address
    /// @param recipient address of the market place
    function setRecipient(address payable recipient) external nonReentrant onlyOwner {
        require(recipient != address(0), "receiving market place address cannot be zero address");
        _recipient = recipient;
        emit MarketPlaceERC1155Recipient(recipient);
    }

    /// @notice return the market place address.
    function getRecipient() public view returns (address) {
        return _recipient;
    }

    /// @notice set the IERC1155 unit prices in wei.
    function setUnitPrice(uint256[] calldata tokenIds, uint256[] calldata unitPriceInETH) external nonReentrant onlyOwner {
        _setUnitPrice(tokenIds, unitPriceInETH);
    }

    /// @notice return true if automatic eth flow redirection is set.
    function getRedirect() external view returns (bool) {
        return _redirect;
    }

    /// @notice set automatic eth flow redirection.
    /// @param redirect automatic eth flow redirection
    function setRedirect(bool redirect) external nonReentrant onlyOwner {
        _redirect = redirect;
    }

    /// @notice return true if sell is allowed.
    function getAllowSell() external view returns (bool) {
        return _allowSell;
    }

    /// @notice set sell authorization.
    /// @param allowSell allow sell
    function setAllowSell(bool allowSell) external nonReentrant onlyOwner {
        _allowSell = allowSell;
    }

    /// @notice get eth amount on contract.
    function getBalance() external view returns (uint256){
        return address(this).balance;
    }

    /// @notice Transfer all funds to one address.
    function transfer() external nonReentrant onlyOwner {
        uint256 ethBalance = address(this).balance;
        (bool success, ) = payable(_recipient).call{value: ethBalance}("");
        require(success, string(abi.encodePacked("Tranfer to ", _recipient, " Failed. ")));
    }

    /// @notice Transfer funds to one address.
    /// @param recipient The address to which the funds are transferred
    /// @param amount The amount of funds to be transferred
    function transferAt(address payable recipient, uint256 amount) external nonReentrant onlyOwner {
        require(recipient != address(0), "recipient address cannot be zero address");
        require(address(this).balance >= amount, string(abi.encodePacked("There are not enough ethers on contract, required: ", Strings.toString(amount), " available: ", Strings.toString(address(this).balance))));
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, string(abi.encodePacked("Tranfer to ", recipient, " Failed. ")));
    }

    /// @notice return the IERC1155 unit prices in wei.
    /// @param tokenIds The ids of the IERC1155 token
    function _getUnitPrice(uint256[] calldata tokenIds) internal view returns (uint256[] memory) {
        uint[] memory unitPrices = new uint[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require(_unitPrice[tokenIds[i]] != 0, string(abi.encodePacked("Tokens are not sold on this market place: ", Strings.toString(tokenIds[i]))));
            unitPrices[i] = _unitPrice[tokenIds[i]];
        }
        return unitPrices;
    }

    /// @notice return the IERC1155 unit prices in wei.
    /// @param tokenIds The ids of the IERC1155 token
    function getUnitPrice(uint256[] calldata tokenIds) external view returns (uint256[] memory) {
        return _getUnitPrice(tokenIds);
    }

    /// @notice return the current IERC1155 id token balance for the contract.
    /// @param tokenId The id of the IERC1155 token
    function balanceOf(uint256 tokenId) external view returns (uint256) {
        return _ierc1155.balanceOf(address(this), tokenId);
    }

    /// @notice Returns the current balance of IERC1155 token for the contract.
    /// @param account The address of the account
    /// @param tokenIds The ids of the IERC1155 token
    function _balances(address account, uint256[] calldata tokenIds) internal view returns (uint256[] memory) {
        uint256[] memory _tokenBalances = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _tokenBalances[i] = _ierc1155.balanceOf(account, tokenIds[i]);
        }
        return _tokenBalances;
    }

    /// @notice Returns the current balance of IERC1155 token for the contract.
    /// @param tokenIds The ids of the IERC1155 token
    function balances(uint256[] calldata tokenIds) external view returns (uint256[] memory) {
        return _balances(address(this),tokenIds);
    }

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4){
        require(_msgSender() == address(_ierc1155),"Bad sender");
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4){
        require(_msgSender() == address(_ierc1155),"Bad sender");
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(Ownable).interfaceId;
    }
}