// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./utils/TransferHelper.sol";

contract AssemblyCurated is
    ReentrancyGuard,
    Ownable,
    IERC721Receiver,
    IERC1155Receiver
{
    enum LotStatus {
        Inactive,
        Active,
        Successful,
        Canceled
    }

    struct Lot {
        address token;
        bool is1155; // true - erc1155, false - erc721
        address owner;
        uint256 tokenId;
        uint256 price;
        uint256 lotStart;
        uint256 lotEnd;
        LotStatus status;
        uint256 totalSupply; // 0 - erc721
        uint256 sold;
    }

    event NewLot(
        uint256 indexed lotId,
        uint256 indexed tokenId,
        address indexed token,
        address owner,
        uint256 totalSupply
    );
    event SellLot(
        uint256 indexed lotId,
        uint256 indexed tokenId,
        address indexed token,
        address buyer,
        uint256 amount,
        uint256 price
    );

    event CancelLot(uint256 indexed lotId);
    event DeactivateLot(uint256 indexed lotId);
    event ActivateLot(uint256 indexed lotId);
    event CloseLot(uint256 indexed lotId);
    event UpdateRecipient(address newRecipient);
    event SetAllowedCaller(address caller, bool isAllowed);
    event RescueToken(
        address to,
        address token,
        uint256 tokenId,
        bool is1155,
        uint256 amount
    );

    ///@notice - return when one of parameters is zero address
    error ZeroAddress();
    ///@notice - only allowedCaller
    error OnlyAllowedCaller();
    ///@notice - token is not support ERC721 or ERC1155 interface
    error InvalidToken();
    ///@notice - lot with the same token and tokenID already exists.
    error LotAlreadyExists();
    ///@notice - array lengths do not match
    error WrongArrayLength();
    ///@notice - the lot has an incorrect status, so the operation cannot be performed.
    /// records the actual status of the lot
    error InvalidLotStatus(LotStatus actualStatus);
    ///@notice - not enough eth
    error InvalidValue();
    ///@notice - amount equal to zero or less than the amount of tokens available in the lot
    error InvalidAmount();
    ///@notice - allowedCaller already added or removed
    error AlreadySet();

    address public recipient;
    uint256 public lastLotId;
    uint256 public activeLotCount;

    mapping(uint256 => Lot) public lots;
    mapping(address => mapping(uint256 => uint256[])) public tokenLots;
    mapping(address => bool) public allowedCallers;
    mapping(address => mapping(uint256 => bool)) private existingTokens;
    EnumerableSet.UintSet private activeLots;

    constructor(
        address _recipient,
        address[] memory _allowedCallers,
        address _owner
    ) payable {
        if (_recipient == address(0)) {
            revert ZeroAddress();
        }
        recipient = _recipient;

        uint256 length = _allowedCallers.length;
        for (uint256 i; i < length; ) {
            if (_allowedCallers[i] == address(0)) {
                revert ZeroAddress();
            }

            allowedCallers[_allowedCallers[i]] = true;

            unchecked {
                ++i;
            }
        }

        if (_owner != address(0)) {
            _transferOwnership(_owner);
        }
    }

    modifier onlyAllowedCaller() {
        if (!allowedCallers[msg.sender]) {
            revert OnlyAllowedCaller();
        }
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external pure override returns (bytes4) {
        // return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external pure override returns (bytes4) {
        // return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
        return 0xbc197c81;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        // return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
        return 0x150b7a02;
    }

    /// @notice Transfer token to contract and create new lot
    /// @dev prior approve from owner of token is required.
    /// @param token - address of NFT collection
    /// @param tokenId - target token id
    /// @param owner - current owner of token
    /// @param price - price in wei
    /// @param is1155 - is ERC1155 token?
    /// @param amount - amount of ERC1155 token. For ERC721 can be 0
    /// @return lotId - id of new lot
    function createLot(
        address token,
        uint256 tokenId,
        address owner,
        uint256 price,
        bool is1155,
        uint256 amount
    ) public onlyAllowedCaller returns (uint256) {
        if (!isSupportedToken(token)) {
            revert InvalidToken();
        }
        if (doesLotExist(token, tokenId)) {
            revert LotAlreadyExists();
        }

        if (is1155) {
            if (amount == 0) {
                revert InvalidAmount();
            }
            IERC1155(token).safeTransferFrom(
                owner,
                address(this),
                tokenId,
                amount,
                "0x0"
            );
        } else {
            IERC721(token).safeTransferFrom(owner, address(this), tokenId);
        }

        uint256 lotId = ++lastLotId;

        lots[lotId].tokenId = tokenId;
        lots[lotId].token = token;
        lots[lotId].price = price;
        lots[lotId].lotStart = block.timestamp;
        lots[lotId].owner = owner;
        lots[lotId].status = LotStatus.Active;
        lots[lotId].is1155 = is1155;

        if (is1155) lots[lotId].totalSupply = amount;

        tokenLots[token][tokenId].push(lotId);
        EnumerableSet.add(activeLots, lotId);
        existingTokens[token][tokenId] = true;
        activeLotCount++;

        emit NewLot(lotId, tokenId, token, owner, amount);
        return lotId;
    }

    /// @notice multiple creation of lots
    /// @param tokens - addresses of NFT collection
    /// @param tokenIds - target token ids
    /// @param owners - current owners of tokens
    /// @param prices - prices in wei
    /// @param is1155s - is ERC1155 tokens?
    /// @param amounts - amounts of ERC1155 tokens
    function batchCreateLots(
        address[] calldata tokens,
        uint256[] calldata tokenIds,
        address[] calldata owners,
        uint256[] calldata prices,
        bool[] calldata is1155s,
        uint256[] calldata amounts
    ) external onlyAllowedCaller {
        uint256 length = tokens.length;
        if (
            length != tokenIds.length ||
            length != owners.length ||
            length != prices.length ||
            length != is1155s.length ||
            length != amounts.length
        ) {
            revert WrongArrayLength();
        }

        for (uint256 i; i < length; ) {
            createLot(
                tokens[i],
                tokenIds[i],
                owners[i],
                prices[i],
                is1155s[i],
                amounts[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    ///@notice Buy active lot
    ///@param lotId - id of target lot
    ///@param amount - amount for ERC1155 token
    function buyLot(uint256 lotId, uint256 amount) public payable nonReentrant {
        Lot memory localLot = lots[lotId];

        if (localLot.status != LotStatus.Active) {
            revert InvalidLotStatus(localLot.status);
        }

        if (localLot.is1155) {
            _buyMultipleLot(lotId, localLot, amount);
        } else {
            _buySingleLot(lotId, localLot);
        }
    }

    ///@notice Cancel lot and send token to target recipient
    ///@dev For transfer to primary owner set newRecipient = address(0)
    ///@param lotId - id of target lot
    ///@param newRecipient - address of the recipient of the canceled token
    function cancelLot(uint256 lotId, address newRecipient) public onlyOwner {
        Lot memory localLot = lots[lotId];

        if (
            localLot.status != LotStatus.Active &&
            !(localLot.status == LotStatus.Inactive && localLot.lotStart != 0)
        ) {
            revert InvalidLotStatus(localLot.status);
        }

        address finalRecipient = newRecipient != address(0)
            ? newRecipient
            : localLot.owner;

        if (localLot.is1155) {
            IERC1155(localLot.token).safeTransferFrom(
                address(this),
                finalRecipient,
                localLot.tokenId,
                localLot.totalSupply - localLot.sold,
                "0x0"
            );
        } else {
            IERC721(localLot.token).safeTransferFrom(
                address(this),
                finalRecipient,
                localLot.tokenId
            );
        }

        lots[lotId].status = LotStatus.Canceled;
        lots[lotId].lotEnd = block.timestamp;
        activeLotCount--;
        EnumerableSet.remove(activeLots, lotId);
        existingTokens[localLot.token][localLot.tokenId] = false;
        emit CancelLot(lotId);
    }

    ///@notice multiple canceling of lots
    ///@param lotIds - ids of target lots
    ///@param newRecipients - addresses of the recipients of the canceled tokens
    function batchCancelLots(
        uint256[] calldata lotIds,
        address[] calldata newRecipients
    ) external onlyOwner {
        uint256 length = lotIds.length;
        if (length != newRecipients.length) {
            revert WrongArrayLength();
        }

        for (uint256 i; i < length; ) {
            cancelLot(lotIds[i], newRecipients[i]);

            unchecked {
                ++i;
            }
        }
    }

    ///@notice Deactivate lot, but the token remains
    ///@param lotId - id of target lot
    function deactivateLot(uint256 lotId) public onlyOwner {
        Lot memory localLot = lots[lotId];

        if (localLot.status != LotStatus.Active) {
            revert InvalidLotStatus(localLot.status);
        }

        lots[lotId].status = LotStatus.Inactive;
        activeLotCount--;
        EnumerableSet.remove(activeLots, lotId);
        emit DeactivateLot(lotId);
    }

    /// @notice multiple deactivating of lots
    ///@param lotIds - ids of target lots
    function batchDeactivateLots(uint256[] calldata lotIds) external onlyOwner {
        uint256 length = lotIds.length;
        for (uint256 i; i < length; ) {
            deactivateLot(lotIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    ///@notice Activation of a previously deactivated lot
    ///@param lotId - id of target lot
    function activateLot(uint256 lotId) public onlyOwner {
        Lot memory localLot = lots[lotId];

        if (localLot.status != LotStatus.Inactive && localLot.lotStart != 0) {
            revert InvalidLotStatus(localLot.status);
        }

        lots[lotId].status = LotStatus.Active;
        activeLotCount++;
        EnumerableSet.add(activeLots, lotId);
        emit ActivateLot(lotId);
    }

    ///@notice multiple activating of lots
    ///@param lotIds - ids of target lots
    function batchActivateLots(uint256[] calldata lotIds) external onlyOwner {
        uint256 length = lotIds.length;
        for (uint256 i; i < length; ) {
            activateLot(lotIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    ///@notice Return list of active lots
    ///@dev If count > of active lots count, then will be returned empty Lot structures
    ///@param start - offset
    ///@param count - limit
    function getActiveLots(uint256 start, uint256 count)
        external
        view
        returns (Lot[] memory lotsData)
    {
        uint256 end = EnumerableSet.length(activeLots);
        if (start + count < end) {
            end = start + count;
        }

        Lot memory lot;
        uint256 idx;
        lotsData = new Lot[](count);
        for (uint256 i = start; i < end; ) {
            lot = lots[EnumerableSet.at(activeLots, i)];
            lotsData[idx++] = lot;

            unchecked {
                ++i;
            }
        }
    }

    ///@notice Checks if the token supports the ERC721 or ERC1155 interface
    ///@param token - address of target roken
    function isSupportedToken(address token) public view returns (bool) {
        return
            IERC165(token).supportsInterface(0x80ac58cd) ||
            IERC165(token).supportsInterface(0xd9b67a26);
    }

    ///@notice checking if a lot exists with the specified token
    /// @param token - address of NFT collection
    /// @param tokenId - target token id
    function doesLotExist(address token, uint256 tokenId)
        private
        view
        returns (bool)
    {
        return existingTokens[token][tokenId];
    }

    ///@notice - buy lot with ERC721 token
    ///@param lotId - id of target lot
    ///@param localLot - target lot structure
    function _buySingleLot(uint256 lotId, Lot memory localLot) private {
        if (localLot.price > msg.value) {
            revert InvalidValue();
        }

        IERC721(localLot.token).safeTransferFrom(
            address(this),
            msg.sender,
            localLot.tokenId
        );

        uint256 ownerValue = (localLot.price * 80) / 100;
        TransferHelper.safeTransferETH(localLot.owner, ownerValue);
        TransferHelper.safeTransferETH(recipient, localLot.price - ownerValue);

        // refund dust eth, if any
        if (msg.value > localLot.price)
            TransferHelper.safeTransferETH(
                msg.sender,
                msg.value - localLot.price
            );

        lots[lotId].status = LotStatus.Successful;
        lots[lotId].lotEnd = block.timestamp;
        activeLotCount--;
        EnumerableSet.remove(activeLots, lotId);
        existingTokens[localLot.token][localLot.tokenId] = false;

        emit CloseLot(lotId);
        emit SellLot(
            lotId,
            localLot.tokenId,
            localLot.token,
            msg.sender,
            0,
            localLot.price
        );
    }

    ///@notice - buy lot with ERC1155 token
    ///@param lotId - id of target lot
    ///@param localLot - target lot structure
    function _buyMultipleLot(
        uint256 lotId,
        Lot memory localLot,
        uint256 amount
    ) private {
        if (amount == 0 || amount > localLot.totalSupply - localLot.sold) {
            revert InvalidAmount();
        }

        uint256 totalPrice = amount * localLot.price;
        if (totalPrice > msg.value) {
            revert InvalidValue();
        }

        IERC1155(localLot.token).safeTransferFrom(
            address(this),
            msg.sender,
            localLot.tokenId,
            amount,
            "0x0"
        );

        uint256 ownerValue = (totalPrice * 80) / 100;
        TransferHelper.safeTransferETH(localLot.owner, ownerValue);
        TransferHelper.safeTransferETH(recipient, totalPrice - ownerValue);

        // refund dust eth, if any
        if (msg.value > totalPrice)
            TransferHelper.safeTransferETH(msg.sender, msg.value - totalPrice);

        lots[lotId].sold += amount;

        if (localLot.sold + amount == localLot.totalSupply) {
            lots[lotId].status = LotStatus.Successful;
            lots[lotId].lotEnd = block.timestamp;
            activeLotCount--;
            EnumerableSet.remove(activeLots, lotId);
            existingTokens[localLot.token][localLot.tokenId] = false;
            emit CloseLot(lotId);
        }

        emit SellLot(
            lotId,
            localLot.tokenId,
            localLot.token,
            msg.sender,
            amount,
            localLot.price
        );
    }

    /* --- OWNER --- */

    ///@notice - set new marketplace recipient address
    ///@param newRecipient - recipient address
    function updateRecipient(address newRecipient) external onlyOwner {
        if (newRecipient == address(0)) {
            revert ZeroAddress();
        }
        recipient = newRecipient;
        emit UpdateRecipient(newRecipient);
    }

    ///@notice - adding a new allowedCaller
    ///@param caller - allowedCaller address
    function addAllowedCaller(address caller) external onlyOwner {
        if (caller == address(0)) {
            revert ZeroAddress();
        }
        if (allowedCallers[caller]) {
            revert AlreadySet();
        }
        allowedCallers[caller] = true;
        emit SetAllowedCaller(caller, true);
    }

    ///@notice - removing allowedCaller
    ///@param caller - allowedCaller address
    function removeAllowedCaller(address caller) external onlyOwner {
        if (!allowedCallers[caller]) {
            revert AlreadySet();
        }
        allowedCallers[caller] = false;
        emit SetAllowedCaller(caller, false);
    }

    ///@notice transfer NFT token from contract
    ///@dev Not recommended for use with existing lots as it does not change the status of the lot.
    ///To withdraw a token from an existing lot, use cancelLot
    ///@param to - NFT token recipient
    ///@param token - address of NFT collection
    ///@param tokenId - id of NFT token
    ///@param is1155 - is token ERC115?
    ///@param amount - token amount for ERC1155
    function rescue(
        address to,
        address token,
        uint256 tokenId,
        bool is1155,
        uint256 amount
    ) external onlyOwner {
        if (to == address(0)) {
            revert ZeroAddress();
        }

        if (is1155) {
            if (amount == 0) {
                revert InvalidAmount();
            }
            IERC1155(token).safeTransferFrom(
                address(this),
                to,
                tokenId,
                amount,
                "0x0"
            );
        } else {
            IERC721(token).safeTransferFrom(address(this), to, tokenId);
        }

        emit RescueToken(to, token, tokenId, is1155, amount);
    }
}