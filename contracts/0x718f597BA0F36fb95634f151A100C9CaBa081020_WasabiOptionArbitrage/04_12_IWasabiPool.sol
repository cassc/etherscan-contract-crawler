// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./lib/WasabiStructs.sol";

/**
 * @dev Required interface of an WasabiPool compliant contract.
 */
interface IWasabiPool is IERC165, IERC721Receiver {
    
    /**
     * @dev Emitted when `admin` is changed.
     */
    event AdminChanged(address admin);

    /**
     * @dev Emitted when an order is cancelled.
     */
    event OrderCancelled(uint256 id);

    /**
     * @dev Emitted when a pool bid is taken
     */
    event PoolBidTaken(uint256 id);

    /**
     * @dev Emitted when an ERC721 is received
     */
    event ERC721Received(uint256 tokenId);

    /**
     * @dev Emitted when ETH is received
     */
    event ETHReceived(uint amount);

    /**
     * @dev Emitted when ERC20 is received
     */
    event ERC20Received(uint amount);

    /**
     * @dev Emitted when an ERC721 is withdrawn
     */
    event ERC721Withdrawn(uint256 tokenId);

    /**
     * @dev Emitted when ERC20 is withdrawn
     */
    event ERC20Withdrawn(uint amount);

    /**
     * @dev Emitted when ETH is withdrawn
     */
    event ETHWithdrawn(uint amount);

    /**
     * @dev Emitted when an option is executed.
     */
    event OptionExecuted(uint256 optionId);

    /**
     * @dev Emitted when an option is issued
     */
    event OptionIssued(uint256 optionId, uint256 price);

    /**
     * @dev Emitted when an option is issued
     */
    event OptionIssued(uint256 optionId, uint256 price, uint256 poolAskId);

    /**
     * @dev Emitted when the pool settings are edited
     */
    event PoolSettingsChanged();

    /**
     * @dev Returns the address of the nft
     */
    function getNftAddress() external view returns(address);

    /**
     * @dev Returns the address of the nft
     */
    function getLiquidityAddress() external view returns(address);

    /**
     * @dev Writes an option for the given ask.
     */
    function writeOption(
        WasabiStructs.PoolAsk calldata _request, bytes calldata _signature
    ) external payable returns (uint256);

    /**
     * @dev Writes an option for the given rule and buyer.
     */
    function writeOptionTo(
        WasabiStructs.PoolAsk calldata _request, bytes calldata _signature, address _receiver
    ) external payable returns (uint256);

    /**
     * @dev Executes the option for the given id.
     */
    function executeOption(uint256 _optionId) external payable;

    /**
     * @dev Executes the option for the given id.
     */
    function executeOptionWithSell(uint256 _optionId, uint256 _tokenId) external payable;

    /**
     * @dev Cancels the order for the given _orderId.
     */
    function cancelOrder(uint256 _orderId) external;

    /**
     * @dev Withdraws ERC721 tokens from the pool.
     */
    function withdrawERC721(IERC721 _nft, uint256[] calldata _tokenIds) external;

    /**
     * @dev Deposits ERC721 tokens to the pool.
     */
    function depositERC721(IERC721 _nft, uint256[] calldata _tokenIds) external;

    /**
     * @dev Withdraws ETH from this pool
     */
    function withdrawETH(uint256 _amount) external payable;

    /**
     * @dev Withdraws ERC20 tokens from this pool
     */
    function withdrawERC20(IERC20 _token, uint256 _amount) external;

    /**
     * @dev Sets the admin of this pool.
     */
    function setAdmin(address _admin) external;

    /**
     * @dev Removes the admin from this pool.
     */
    function removeAdmin() external;

    /**
     * @dev Returns the address of the current admin.
     */
    function getAdmin() external view returns (address);

    /**
     * @dev Returns the address of the factory managing this pool
     */
    function getFactory() external view returns (address);

    /**
     * @dev Returns the available balance this pool contains that can be withdrawn or collateralized
     */
    function availableBalance() view external returns(uint256);

    /**
     * @dev Returns an array of ids of all outstanding (issued or expired) options
     */
    function getOptionIds() external view returns(uint256[] memory);

    /**
     * @dev Returns the id of the option that locked the given token id, reverts if there is none
     */
    function getOptionIdForToken(uint256 _tokenId) external view returns(uint256);

    /**
     * @dev Returns the option data for the given option id
     */
    function getOptionData(uint256 _optionId) external view returns(WasabiStructs.OptionData memory);

    /**
     * @dev Returns 'true' if the option for the given id is valid and active, 'false' otherwise
     */
    function isValid(uint256 _optionId) view external returns(bool);

    /**
     * @dev Checks if _tokenId unlocked
     */
    function isAvailableTokenId(uint256 _tokenId) external view returns(bool);

    /**
     * @dev Clears the expired options from the pool
     */
    function clearExpiredOptions(uint256[] memory _optionIds) external;

    /**
     * @dev accepts the bid for LPs with _tokenId. If its a put option, _tokenId can be 0
     */
    function acceptBid(WasabiStructs.Bid calldata _bid, bytes calldata _signature, uint256 _tokenId) external returns(uint256);

    /**
     * @dev accepts the ask for LPs
     */
    function acceptAsk(WasabiStructs.Ask calldata _ask, bytes calldata _signature) external;

    /**
     * @dev accepts a bid created for this pool
     */
    function acceptPoolBid(WasabiStructs.PoolBid calldata _poolBid, bytes calldata _signature) external payable;
}