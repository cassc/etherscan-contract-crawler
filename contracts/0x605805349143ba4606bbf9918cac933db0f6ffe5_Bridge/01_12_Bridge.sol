// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./Trustable.sol";

contract Bridge is Trustable {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for ERC20;

    struct Order {
        uint256 id;
        uint16 tokenId;
        address sender;
        string target;
        uint256 amount;
        uint8 decimals;
        uint8 destination;
    }

    struct Token {
        ERC20 token;
        uint16 fee;
        uint256 feeBase;
        address feeTarget;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 dailyLimit;
        uint256 bonus;
        uint8 decimals;
    }

    struct UserStats {
        uint256 transfered;
        uint256 limitFrom;
    }

    event OrderCreated(uint256 indexed id, Order order, uint256 fee);
    event OrderCompleted(uint256 indexed id, uint8 indexed dstFrom);

    uint256 nextOrderId = 0;
    uint16 tokensLength = 0;

    mapping(uint16 => Token) public tokens;
    mapping(uint16 => mapping(address => UserStats)) public stats;
    mapping(uint256 => Order) public orders;
    EnumerableSet.UintSet private orderIds;
    mapping(bytes32 => bool) public completed;
    EnumerableSet.UintSet private destinations;

    function setToken(
        uint16 tokenId,
        ERC20 token,
        uint16 fee,
        uint256 feeBase,
        address feeTarget,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 dailyLimit,
        uint8 inputDecimals
    ) external onlyOwner {
        require(fee <= 10000, "invalid fee");
        tokens[tokenId] = Token(
            token,
            fee,
            convertAmount(token, feeBase, inputDecimals),
            feeTarget,
            convertAmount(token, minAmount, inputDecimals),
            convertAmount(token, maxAmount, inputDecimals),
            convertAmount(token, dailyLimit, inputDecimals),
            0,
            token.decimals()
        );
        if (tokenId + 1 > tokensLength) {
            tokensLength = tokenId + 1;
        }
    }

    function convertAmount(
        ERC20 token,
        uint256 amount,
        uint256 decimals
    ) internal view returns (uint256) {
        return (amount * (10 ** token.decimals())) / (10 ** decimals);
    }

    function setFee(uint16 tokenId, uint16 fee) external onlyOwner {
        require(fee <= 10000, "invalid fee");
        tokens[tokenId].fee = fee;
    }

    function setFeeBase(
        uint16 tokenId,
        uint256 feeBase,
        uint8 inputDecimals
    ) external onlyOwner {
        tokens[tokenId].feeBase = convertAmount(
            tokens[tokenId].token,
            feeBase,
            inputDecimals
        );
    }

    function setFeeTarget(uint16 tokenId, address feeTarget)
    external
    onlyOwner
    {
        tokens[tokenId].feeTarget = feeTarget;
    }

    function setDailyLimit(
        uint16 tokenId,
        uint256 dailyLimit,
        uint8 inputDecimals
    ) external onlyOwner {
        tokens[tokenId].dailyLimit = convertAmount(
            tokens[tokenId].token,
            dailyLimit,
            inputDecimals
        );
    }

    function setMinAmount(
        uint16 tokenId,
        uint256 minAmount,
        uint8 inputDecimals
    ) external onlyOwner {
        tokens[tokenId].minAmount = convertAmount(
            tokens[tokenId].token,
            minAmount,
            inputDecimals
        );
    }

    function setMaxAmount(
        uint16 tokenId,
        uint256 maxAmount,
        uint8 inputDecimals
    ) external onlyOwner {
        tokens[tokenId].maxAmount = convertAmount(
            tokens[tokenId].token,
            maxAmount,
            inputDecimals
        );
    }

    function setBonus(uint16 tokenId, uint256 bonus) external onlyOwner {
        tokens[tokenId].bonus = bonus;
    }

    function addDestinations(uint8[] calldata ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            destinations.add(ids[i]);
        }
    }

    function removeDestinations(uint8[] calldata ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            destinations.remove(ids[i]);
        }
    }

    function create(
        uint16 tokenId,
        uint256 amount,
        uint8 destination,
        string memory target
    ) external {
        require(destinations.contains(destination) == true, "destination not support");
        Token storage tok = tokens[tokenId];
        require(address(tok.token) != address(0), "unknown token");
        require(amount >= tok.minAmount, "amount lower than mininum");
        require(amount <= tok.maxAmount, "amount greater than mininum");

        UserStats storage st = stats[tokenId][msg.sender];

        bool lastIsOld = st.limitFrom + 24 hours < block.timestamp;
        if (lastIsOld) {
            st.limitFrom = block.timestamp;
            st.transfered = 0;
        }
        require(st.transfered + amount <= tok.dailyLimit, "daily limit exceed");
        st.transfered += amount;

        uint256 feeAmount = tok.feeBase + (amount * tok.fee) / 10000;
        if (feeAmount > 0) {
            tok.token.safeTransferFrom(msg.sender, tok.feeTarget, feeAmount);
        }

        amount = amount - feeAmount;
        tok.token.safeTransferFrom(msg.sender, address(this), amount);

        orders[nextOrderId] = Order(
            nextOrderId,
            tokenId,
            msg.sender,
            target,
            amount,
            tok.token.decimals(),
            destination
        );
        orderIds.add(nextOrderId);

        emit OrderCreated(nextOrderId, orders[nextOrderId], feeAmount);
        nextOrderId++;
    }

    function close(uint256 orderId) external onlyTrusted {
        orderIds.remove(orderId);
    }

    function completeOrder(
        uint256 orderId,
        uint8 dstFrom,
        uint16 tokenId,
        address payable to,
        uint256 amount,
        uint256 decimals
    ) external onlyTrusted {
        bytes32 orderHash = keccak256(abi.encodePacked(orderId, dstFrom));
        require(completed[orderHash] == false, "already transfered");

        Token storage tok = tokens[tokenId];
        require(address(tok.token) != address(0), "unknown token");

        tok.token.safeTransfer(to, convertAmount(tok.token, amount, decimals));
        completed[orderHash] = true;

        uint256 bonus = Math.min(tok.bonus, address(this).balance);
        if (bonus > 0) {
            to.transfer(bonus);
        }

        emit OrderCompleted(orderId, dstFrom);
    }

    function withdraw(
        uint16 tokenId,
        address to,
        uint256 amount,
        uint8 inputDecimals
    ) external onlyTrusted {
        Token storage tok = tokens[tokenId];
        tok.token.safeTransfer(
            to,
            convertAmount(tok.token, amount, inputDecimals)
        );
    }

    function isCompleted(uint256 orderId, uint8 dstFrom)
    external
    view
    returns (bool)
    {
        return completed[keccak256(abi.encodePacked(orderId, dstFrom))];
    }

    function listOrders() external view returns (Order[] memory) {
        Order[] memory list = new Order[](orderIds.length());
        for (uint256 i = 0; i < orderIds.length(); i++) {
            list[i] = orders[orderIds.at(i)];
        }

        return list;
    }

    function listTokensNames() external view returns (string[] memory) {
        string[] memory list = new string[](tokensLength);
        for (uint16 i = 0; i < tokensLength; i++) {
            if (address(tokens[i].token) != address(0)) {
                list[i] = tokens[i].token.symbol();
            }
        }

        return list;
    }

    function getTokens() public view returns (Token[] memory) {
        Token[] memory list = new Token[](tokensLength);
        for (uint16 i = 0; i < tokensLength; i++) {
            if (address(tokens[i].token) != address(0)) {
                Token storage lToken = tokens[i];
                list[i] = lToken;
            }
        }

        return list;
    }

    function getDestinations() public view returns (uint8[] memory) {
        uint256 size = destinations.length();
        uint8[] memory list = new uint8[](size);
        for (uint16 i = 0; i < size; i++) {
            list[i] = uint8(destinations.at(i));
        }

        return list;
    }

    receive() external payable {}
}