// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}

/*

                    $$$$$$$$$$$$$$$$
              $$$$$$$$$$$$$$$$$$$$$$$$$$$$
           $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
        $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
     $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
   $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$       $$$$$$$$$$$$$$$$$$$$       $$$$
$$$$$$$$$$$$$$$$$         $$$$$$$$$$$$$$$$$$         $$$
$$$$$$$$$$$$$$$$$$       $$$$$$$$$$$$$$$$$$$$       $$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$   $$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$     $$$$$$$$$$$$$$$$$
 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$      $$$$$$$$$$$$$$$$$
  $  $$$$$$$$$$$$$$$$$$$$$$$$$$$   $    $$$$$$$$$$$$$$$$
 $$$$  $$$$$$$$$$$$$$$$$$$$$$$$$   $$    $$$$$$$$$$$$$
  $$$$$$$$      $$$$$$$$$$$$$$$    $$   $$$$$$$$$$
  $$$$$$$$        $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
   $$$$$$$        $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
   $$$$$$$          $$$$$    $$$$$$$$$$$$$$$$$$$$
   $$$$$$$$         $$$$$    $$$$$$$ $$$$$ $$$$$$
   $$$$$$$$$$$                               $$$$
   $$$$$$$$$$$$$$$$$     $$$$$$$$$ $$$$ $$$$$$$$$
   $$$$$$$$$$$$$$$$$$$$  $$$$$$$$$$$$$$$$$$$$$$$$$
     $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
          $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
              $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
                  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$
                        $$$$$$$$$$$$$$$$$$$$$
                               $$$$$$$$$$$

 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
 $          Cyber Bandits ~ By Michael Reeder          $
 $  cyber-bandits.com • michael-reeder.com • 0x420.io  $
 $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

 */
/// @title Bandit Stolen Goods
/// @notice Cyber Bandit Stolen Goods Contract
/// @custom:website https://cyber-bandits.com
contract BanditStolenGoods is
    ERC1155Supply,
    Ownable,
    ERC2981,
    RevokableDefaultOperatorFilterer
{
    error TokenNotFound();
    error ExceedsMaximum();
    error PaymentRequired();
    error TokenBalanceRequired();
    error MintNotStarted();
    error MintEnded();
    error BurnDisabled();
    error ExceedsMaxPerWallet();

    string public constant name = "Bandit Stolen Goods";
    string public constant symbol = "BSG";

    struct TokenData {
        uint64 maxSupply;
        uint16 price; // in Finney (1/1000th of an Ether) Max value of 65 Ether, min value of 0.001 Ether
        uint32 startDate;
        uint32 endDate;
        uint16 maxPerWallet;
        uint16 balanceRequired;
        bool requiresOtherTokenBalance;
        address otherToken;
        bool burnable;
        string uri;
    }

    TokenData[] public tokenData;

    constructor() ERC1155("") {
        _setDefaultRoyalty(address(this), 500);
    }

    /// @notice Creates a new token
    /// @param _maxSupply The maximum supply of the token
    /// @param _price The price of the token in Finney (1/1000th of an Ether)
    /// @param _startDate The start date of the token minting
    /// @param _endDate The end date of the token minting
    /// @param _maxPerWallet The maximum allowed per wallet
    /// @param _requiresOtherTokenBalance Whether or not the user must have a balance of another token to mint
    /// @param _balanceRequired The balance of the other token required to mint
    /// @param _otherToken The address of the other token
    /// @param _burnable Whether or not the token is burnable
    /// @param _uri The URI of the token
    function createToken(
        uint64 _maxSupply,
        uint16 _price,
        uint32 _startDate,
        uint32 _endDate,
        uint16 _maxPerWallet,
        bool _requiresOtherTokenBalance,
        uint16 _balanceRequired,
        address _otherToken,
        bool _burnable,
        string memory _uri
    ) external onlyOwner {
        tokenData.push(
            TokenData({
                maxSupply: _maxSupply,
                price: _price,
                startDate: _startDate,
                endDate: _endDate,
                maxPerWallet: _maxPerWallet,
                balanceRequired: _balanceRequired,
                requiresOtherTokenBalance: _requiresOtherTokenBalance,
                otherToken: _otherToken,
                burnable: _burnable,
                uri: _uri
            })
        );
    }

    /// @notice Updates the token data
    /// @param id The ID of the token to update
    /// @param _maxSupply The maximum supply of the token
    /// @param _price The price of the token in Finney (1/1000th of an Ether)
    /// @param _startDate The start date of the token minting
    /// @param _endDate The end date of the token minting
    /// @param _maxPerWallet The maximum allowed per wallet
    /// @param _requiresOtherTokenBalance Whether or not the user must have a balance of another token to mint
    /// @param _balanceRequired The balance of the other token required to mint
    /// @param _otherToken The address of the other token
    /// @param _burnable Whether or not the token is burnable
    /// @param _uri The URI of the token
    function updateToken(
        uint256 id,
        uint64 _maxSupply,
        uint16 _price,
        uint32 _startDate,
        uint32 _endDate,
        uint16 _maxPerWallet,
        bool _requiresOtherTokenBalance,
        uint16 _balanceRequired,
        address _otherToken,
        bool _burnable,
        string memory _uri
    ) external onlyOwner {
        tokenData[id - 1] = TokenData({
            maxSupply: _maxSupply,
            price: _price,
            startDate: _startDate,
            endDate: _endDate,
            maxPerWallet: _maxPerWallet,
            balanceRequired: _balanceRequired,
            requiresOtherTokenBalance: _requiresOtherTokenBalance,
            otherToken: _otherToken,
            burnable: _burnable,
            uri: _uri
        });
    }

    /// @notice Updates the URI of a token
    /// @param id The ID of the token to update
    /// @param _uri  The new URI
    function updateTokenUri(uint256 id, string memory _uri) external onlyOwner {
        tokenData[id - 1].uri = _uri;
    }

    /// @notice Mints a token to the caller
    /// @param id The ID of the token to mint
    function mint(uint256 id) public payable tokenExists(id) {
        TokenData memory data = tokenData[id - 1];
        if (data.maxSupply > 0 && (totalSupply(id) + 1) >= data.maxSupply)
            revert ExceedsMaximum();
        if (data.startDate > 0 && block.timestamp < data.startDate)
            revert MintNotStarted();
        if (data.endDate > 0 && block.timestamp > data.endDate)
            revert MintEnded();
        if (
            data.maxPerWallet > 0 &&
            balanceOf(msg.sender, id) + 1 > data.maxPerWallet
        ) revert ExceedsMaxPerWallet();
        if (data.requiresOtherTokenBalance) {
            if (
                IERC721(data.otherToken).balanceOf(msg.sender) <
                data.balanceRequired
            ) revert TokenBalanceRequired();
        }
        if (msg.value < uint256(data.price) * (10 ** 15))
            revert PaymentRequired();
        _mint(msg.sender, id, 1, "");
    }

    function ownerMintBatch(
        address[] memory to,
        uint256[] memory ids,
        uint256[] memory amount
    ) external onlyOwner {
        for (uint i; i < to.length; i++) {
            _mintBatch(to[i], ids, amount, "");
        }
    }

    function uri(
        uint256 id
    ) public view virtual override tokenExists(id) returns (string memory) {
        return tokenData[id - 1].uri;
    }

    function tokenURI(uint256 id) public view returns (string memory) {
        return uri(id);
    }

    modifier tokenExists(uint256 id) {
        if (id < 1 || id > tokenData.length) revert TokenNotFound();
        _;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawERC20(IERC20 token) public onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /*//////////////////////////////////////////////////////////////
                              BURNABLE
    //////////////////////////////////////////////////////////////*/

    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        TokenData memory data = tokenData[id - 1];
        if (!data.burnable) revert BurnDisabled();
        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            TokenData memory data = tokenData[ids[i] - 1];
            if (!data.burnable) revert BurnDisabled();
        }
        _burnBatch(account, ids, values);
    }

    /*//////////////////////////////////////////////////////////////
                              ROYALTIES
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the default royalty values for the collection
    /// @param receiver The receiver of the royalties
    /// @param feeNumerator The royalty amount
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice Removes default royalty information.
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /// @notice Sets the royalty information for a specific token id, overriding the global default.
    /// @param tokenId The specific token id
    /// @param receiver The receiver of the royalties
    /// @param feeNumerator The royalty amount
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /// @notice Resets royalty information for the token id back to the global default.
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                            OPERATOR FILTER
    //////////////////////////////////////////////////////////////*/
    function owner()
        public
        view
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}