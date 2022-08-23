// SPDX-License-Identifier: Unlicense
// moved from https://github.com/museum-of-war/auction
pragma solidity 0.8.16;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC1155.sol";
import "IERC1155Receiver.sol";
import "Ownable.sol";
import "IWithBalance.sol";

/// @title A Seller Contract for selling single or multiple ERC721 or ERC1155 tokens (modified version of NFTSeller)
/// @notice This contract can be used for selling any ERC721 and ERC1155 tokens
contract NFTSellerV2 is Ownable, IERC721Receiver, IERC1155Receiver {
    address[] public whitelistedPassCollections; //Only owners of tokens from any of these collections can buy if is onlyWhitelisted
    mapping(address => Sale) public nftContractSales;
    mapping(address => uint256) failedTransferCredits;
    //Each Sale is unique to each collection (smart contract).
    struct Sale {
        //map contract address to
        uint64 saleStart;
        uint64 saleEnd;
        uint128 price;
        address feeRecipient;
        bool onlyWhitelisted; // if true, than only owners of whitelistedPassCollections can buy tokens
        bool isERC1155;
    }

    /*╔═════════════════════════════╗
      ║           EVENTS            ║
      ╚═════════════════════════════╝*/

    event NftSaleCreated(
        address indexed nftContractAddress,
        uint128 price,
        uint64 saleStart,
        uint64 saleEnd,
        address feeRecipient,
        bool onlyWhitelisted,
        bool isERC1155
    );

    event NftSaleTokenAdded(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        uint256 amount
    );

    event TokenTransferredAndSellerPaid(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        uint256 amount,
        uint128 value,
        address buyer
    );

    event TokenSaleWithdrawn(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        uint256 amount
    );

    event TokensSaleClosed(
        address indexed nftContractAddress
    );
    /**********************************/
    /*╔═════════════════════════════╗
      ║             END             ║
      ║            EVENTS           ║
      ╚═════════════════════════════╝*/
    /**********************************/
    /*╔═════════════════════════════╗
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/

    modifier needWhitelistedToken(address _nftContractAddress) {
        if (nftContractSales[_nftContractAddress].onlyWhitelisted) {
            bool isWhitelisted;
            for (uint256 i = 0; i < whitelistedPassCollections.length; i++) {
                if(IWithBalance(whitelistedPassCollections[i]).balanceOf(msg.sender) > 0) {
                    isWhitelisted = true;
                    break;
                }
            }
            require(isWhitelisted, "Sender has no whitelisted NFTs");
        }
        _;
    }

    modifier saleExists(address _nftContractAddress) {
        address _feeRecipient = nftContractSales[_nftContractAddress].feeRecipient;
        require(_feeRecipient != address(0), "Sale does not exist");
        _;
    }

    modifier saleOngoing(address _nftContractAddress) {
        require(
            _isSaleStarted(_nftContractAddress),
            "Sale has not started"
        );
        require(
            _isSaleOngoing(_nftContractAddress),
            "Sale has ended"
        );
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Cannot specify 0 address");
        _;
    }

    /**********************************/
    /*╔═════════════════════════════╗
      ║             END             ║
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/
    /**********************************/
    // constructor
    constructor(address[] memory _whitelistedPassCollectionsAddresses) {
        uint256 collectionsCount = _whitelistedPassCollectionsAddresses.length;
        for (uint256 i = 0; i < collectionsCount; i++) {
            whitelistedPassCollections.push(_whitelistedPassCollectionsAddresses[i]);
        }
    }
    /**********************************/
    /*╔══════════════════════════════╗
      ║     RECEIVERS FUNCTIONS      ║
      ╚══════════════════════════════╝*/
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual saleExists(msg.sender) returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual saleExists(msg.sender) returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual saleExists(msg.sender) returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return
        interfaceId == type(IERC1155Receiver).interfaceId ||
        interfaceId == type(IERC721Receiver).interfaceId;
    }
    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║     RECEIVERS FUNCTIONS      ║
      ╚══════════════════════════════╝*/
    /**********************************/
    /*╔══════════════════════════════╗
      ║     WHITELIST FUNCTIONS      ║
      ╚══════════════════════════════╝*/
    /*
     * Add whitelisted pass collection.
     */
    function addWhitelistedCollection(address _collectionContractAddress)
    external
    onlyOwner
    {
        whitelistedPassCollections.push(_collectionContractAddress);
    }

    /*
     * Remove whitelisted pass collection by index.
     */
    function removeWhitelistedCollection(uint256 index)
    external
    onlyOwner
    {
        whitelistedPassCollections[index] = whitelistedPassCollections[whitelistedPassCollections.length - 1];
        whitelistedPassCollections.pop();
    }
    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║     WHITELIST FUNCTIONS      ║
      ╚══════════════════════════════╝*/
    /**********************************/
    /*╔══════════════════════════════╗
      ║     SALE CHECK FUNCTIONS     ║
      ╚══════════════════════════════╝*/
    function _isSaleStarted(address _nftContractAddress)
    internal
    view
    returns (bool)
    {
        return (block.timestamp >= nftContractSales[_nftContractAddress].saleStart);
    }

    function _isSaleOngoing(address _nftContractAddress)
    internal
    view
    returns (bool)
    {
        uint64 saleEndTimestamp = nftContractSales[_nftContractAddress].saleEnd;
        //if the saleEnd is set to 0, the sale is on-going and doesn't have specified end.
        return (saleEndTimestamp == 0 || block.timestamp < saleEndTimestamp);
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║     SALE CHECK FUNCTIONS     ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║         SALE CREATION        ║
      ╚══════════════════════════════╝*/

    function _createNewSale(
        address _nftContractAddress,
        uint64 _saleStart,
        uint64 _saleEnd,
        uint128 _price,
        address _feeRecipient,
        bool _onlyWhitelisted,
        bool _isERC1155
    )
    internal
    notZeroAddress(_feeRecipient)
    {
        require(_saleEnd >= _saleStart || _saleEnd == 0, "Sale end must be after the start");
        require(
            nftContractSales[_nftContractAddress].feeRecipient == address(0),
            "Sale is already created"
        );

        Sale memory sale; // creating the sale
        sale.saleStart = _saleStart;
        sale.saleEnd = _saleEnd;
        sale.price = _price;
        sale.feeRecipient = _feeRecipient;
        sale.onlyWhitelisted = _onlyWhitelisted;
        sale.isERC1155 = _isERC1155;

        nftContractSales[_nftContractAddress] = sale;

        emit NftSaleCreated(
            _nftContractAddress,
            _price,
            _saleStart,
            _saleEnd,
            _feeRecipient,
            _onlyWhitelisted,
            _isERC1155
        );
    }

    function createNewERC721Sales(
        address _nftContractAddress,
        uint256[] memory _tokenIds,
        uint64 _saleStart,
        uint64 _saleEnd,
        uint128 _price,
        address _feeRecipient,
        bool _onlyWhitelisted
    )
    external
    onlyOwner
    {
        _createNewSale(_nftContractAddress, _saleStart, _saleEnd, _price, _feeRecipient, _onlyWhitelisted, false);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            // Sending the NFT to this contract
            if (IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender) {
                IERC721(_nftContractAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _tokenId
                );

                emit NftSaleTokenAdded(
                    _nftContractAddress,
                    _tokenId,
                    1
                );
            }
            require(
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "NFT transfer failed"
            );
        }
    }

    function createNewERC1155Sales(
        address _nftContractAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _tokenAmounts,
        uint64 _saleStart,
        uint64 _saleEnd,
        uint128 _price,
        address _feeRecipient,
        bool _onlyWhitelisted
    )
    external
    onlyOwner
    {
        _createNewSale(_nftContractAddress, _saleStart, _saleEnd, _price, _feeRecipient, _onlyWhitelisted, true);

        IERC1155(_nftContractAddress).safeBatchTransferFrom(
            msg.sender,
            address(this),
            _tokenIds,
            _tokenAmounts,
            ""
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            uint256 _amount = _tokenAmounts[i];
            emit NftSaleTokenAdded(
                _nftContractAddress,
                _tokenId,
                _amount
            );
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║         SALE CREATION        ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔═════════════════════════════╗
      ║        BUY FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    /*
    * Buy tokens with ETH.
    */
    function buyTokens(
        address _nftContractAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    )
    external
    payable
    saleExists(_nftContractAddress)
    saleOngoing(_nftContractAddress)
    needWhitelistedToken(_nftContractAddress)
    {
        address _feeRecipient = nftContractSales[_nftContractAddress].feeRecipient;
        // attempt to send the funds to the recipient
        (bool success, ) = payable(_feeRecipient).call{ value: msg.value, gas: 20000 }("");
        // if it failed, update their credit balance so they can pull it later
        if (!success) failedTransferCredits[_feeRecipient] = failedTransferCredits[_feeRecipient] + msg.value;

        uint128 price = nftContractSales[_nftContractAddress].price;

        if (nftContractSales[_nftContractAddress].isERC1155) {
            uint128[] memory values = new uint128[](_amounts.length);
            uint256 totalAmount = 0;
            for (uint256 i = 0; i < _amounts.length; i++) {
                totalAmount += _amounts[i];
                values[i] = uint128(_amounts[i] * price);
            }
            require(msg.value >= totalAmount * price, "Not enough funds to buy tokens");
            IERC1155(_nftContractAddress).safeBatchTransferFrom(address(this), msg.sender, _tokenIds, _amounts, "");
            for (uint256 i = 0; i < _amounts.length; i++) {
                emit TokenTransferredAndSellerPaid(_nftContractAddress, _tokenIds[i], _amounts[i], values[i], msg.sender);
            }
        } else {
            require(_amounts.length == 0, "ERC721 tokens cannot have amount");
            require(msg.value >= _tokenIds.length * price, "Not enough funds to buy tokens");
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                uint256 _tokenId = _tokenIds[i];
                IERC721(_nftContractAddress).safeTransferFrom(address(this), msg.sender, _tokenId);

                emit TokenTransferredAndSellerPaid(_nftContractAddress, _tokenId, 1, price, msg.sender);
            }
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║        BUY FUNCTIONS         ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║           WITHDRAW           ║
      ╚══════════════════════════════╝*/
    function withdrawSales(address _nftContractAddress, uint256[] memory _tokenIds, uint256[] memory _amounts)
    external
    onlyOwner
    {
        if (nftContractSales[_nftContractAddress].isERC1155) {
            IERC1155(_nftContractAddress).safeBatchTransferFrom(address(this), owner(), _tokenIds, _amounts, "");
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                emit TokenSaleWithdrawn(_nftContractAddress, _tokenIds[i], _amounts[i]);
            }
        } else {
            require(_amounts.length == 0, "ERC721 tokens cannot have amount");
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                uint256 _tokenId = _tokenIds[i];
                IERC721(_nftContractAddress).transferFrom(address(this), owner(), _tokenId);
                emit TokenSaleWithdrawn(_nftContractAddress, _tokenId, 1);
            }
        }
    }

    function closeSales(address _nftContractAddress)
    external
    onlyOwner
    {
        delete nftContractSales[_nftContractAddress];
        emit TokensSaleClosed(_nftContractAddress);
    }

    /*
     * If the transfer of a bid has failed, allow to reclaim amount later.
     */
    function withdrawAllFailedCreditsOf(address recipient) external {
        uint256 amount = failedTransferCredits[recipient];

        require(amount != 0, "no credits to withdraw");

        failedTransferCredits[recipient] = 0;

        (bool successfulWithdraw, ) = recipient.call{
        value: amount,
        gas: 20000
        }("");
        require(successfulWithdraw, "withdraw failed");
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║           WITHDRAW           ║
      ╚══════════════════════════════╝*/
    /**********************************/
}