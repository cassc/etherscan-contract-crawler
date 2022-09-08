// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./strings.sol";
import "./base64.sol";
import "./EthboxStructs.sol";

abstract contract EthboxMetadata {
    function buildMetadata(
        address owner,
        EthboxStructs.UnpackedMessage[] memory messages,
        uint256 ethboxSize,
        uint256 ethboxDrip
    ) public view virtual returns (string memory data);
}

contract EthboxV2 is ERC165, IERC721, IERC721Metadata, Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using Strings for uint256;
    using strings for *;

    //--ERC721 Variables--//

    string private _name;
    string private _symbol;
    EthboxMetadata public metadata;

    /// @notice Mapping to keep track of whether an address has minted an ethbox.
    /// @dev Using a bool rather than number because an address can only mint one.
    mapping(address => bool) public minted;

    //--Messaging Variables--//

    /// @notice The default size an ethbox is set to at mint
    /// @dev This size can be increased for a fee, see { expandEthboxSize }
    uint256 public constant defaultEthboxSize = 3;

    /// @notice The default time it will take for a message to "expire". For example,
    /// someone sends a 1 ETH message, in four weeks all that ETH, minus our fee
    /// will be claimable by the ethbox owner.
    /// @dev This can be changed by ethbox owners, when their ethbox is empty.
    /// This change only affects their ethbox. See { changeEthboxDurationTime }
    uint256 public constant defaultDripTime = 4 weeks;

    /// @notice Max message length somebody can send, this will not change.
    uint256 public constant maxMessageLen = 141;

    /// @notice The initial cost of increasing ethbox size.
    /// @dev Settable by contract owner here { setSizeIncreaseFee }
    uint256 public sizeIncreaseFee;

    /// @notice The BPS increase in fee depending on how many slots the user
    /// already has
    /// @dev Settable by contract owner here { setSizeIncreaseFeeBPS }
    uint256 public sizeIncreaseFeeBPS;

    /// @notice The BPS fee charged by contract owner per message.
    /// @dev Settable by contract owner here { setMessageFeeBPS }
    uint256 public messageFeeBPS;

    /// @notice The recipient of these fees.
    /// @dev Settable by contract owner here { setMessageFeeRecipient }
    address public messageFeeRecipient;

    /// @notice Mapping to keep track of an address' messages.
    /// @dev See { EthboxStructs.Message }
    /// Note: address does not have to mint ethbox to recieve messages.
    /// An unminted ethbox with messages will claim all value upong minting.
    mapping(address => EthboxStructs.Message[]) public ethboxMessages;

    /// @notice Stores ethbox specific information in an address => uint256 mapping
    /// @dev Bits Layout:
    /// - [0..159]   `payoutRecipient`
    /// - [160..223] `drip (timestamp)`
    /// - [224]      `isLocked`
    /// - [225 - 232]  `size`
    /// - [233..255] Currently unused
    /// See { packEthboxInfo } and { unpackEthboxInfo } for implementation.
    mapping(address => uint256) packedEthboxInfo;

    /// @notice Mapping to keep track of remaining eth to be claimed from bumped messages
    /// An unminted ethbox with messages will claim all value upong minting.
    mapping(address => uint256) public bumpedClaimValue;

    //--Packing Constants--//

    /// @dev Bit position of drip timestamp in { packedEthboxInfo }
    /// see { unpackEthboxDrip }
    uint256 private constant BITPOS_ETHBOX_DRIP_TIMESTAMP = 160;

    /// @dev Bit position of ethbox locked boolean in { packedEthboxInfo }
    /// see { unpackEthboxLocked }
    uint256 private constant BITPOS_ETHBOX_LOCKED = 224;

    /// @dev Bit position of ethbox size in { packedEthboxInfo }
    /// see { unpackEthboxSize }
    uint256 private constant BITPOS_ETHBOX_SIZE = 225;

    // Packed message data bit positions. See { EthboxStructs.Message.data }
    // See { packMessageData } and { unpackMessageData } for implementation.

    /// @dev Bit position of timestamp sent in EthboxStructs.Message.data
    /// See { unpackMessageTimestamp }
    uint256 private constant BITPOS_MESSAGE_TIMESTAMP = 160;

    /// @dev Bit position of message index in EthboxStructs.Message.data
    /// See { unpackMessageIndex }
    uint256 private constant BITPOS_MESSAGE_INDEX = 224;

    /// @dev Bit position of message fee BPS in EthboxStructs.Message.data
    /// See { unpackMessageFeeBPS }
    uint256 private constant BITPOS_MESSAGE_FEEBPS = 232;

    /// TODO: Currently not being used.
    uint256 private constant BITMASK_RECIPIENT = (1 << 160) - 1;


    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        _name = "Ethbox";
        _symbol = "ETHBOX";
        sizeIncreaseFee = 0.05 ether;
        sizeIncreaseFeeBPS = 2500;
        messageFeeBPS = 250;
        messageFeeRecipient = 0x40543d76fb35c60ff578b648d723E14CcAb8b390;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    ////////////////////////////////////////
    // ERC721 functions //
    ////////////////////////////////////////

    /// @dev See {ERC721-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Returns ethbox balance.
    /// @dev Can only be 1 or 0. As ethboxes are soulbound, if the address
    /// has minted, we know their balance is 1.
    /// @param _owner The address to query.
    /// @return _balance uint256
    function balanceOf(address _owner) public view override returns (uint256) {
        if (minted[_owner]) return 1;
        return 0;
    }

    /// @notice Returns owner of an ethox tokenId.
    /// @dev TokenId is a uint256 casting of an address, so is unique to that address.
    /// Here we re-cast the uint256 to an address to get the owner if minted.
    /// @param _tokenId the tokenId to query.
    function ownerOf(uint256 _tokenId) public view override returns (address) {
        address owner = address(uint160(_tokenId));
        require(minted[owner], "ERC721: invalid token ID");
        return owner;
    }

    /// @notice Returns the ethbox tokenId associated with a given address.
    /// @dev Like { ownerOf } only returns if minted.
    /// We cast the address to a uint256 to generate a unique tokenId.
    /// @param _owner the address to query.
    function ethboxOf(address _owner) public view returns (uint256) {
        require(minted[_owner], "address has not minted their ethbox");
        return uint256(uint160(_owner));
    }

    /// @dev See { ERC721-name }.
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @dev See { ERC721-symbol }.
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// @notice Overridden version of { ERC721-tokenURI }.
    /// @dev First checks if the tokenId has been minted, then gets the owner's
    /// messages ordered by value and inbox size. Metadata contract uses these
    /// ordered messages and size to generate the SVG. See { EthboxMetadata }.
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(minted[address(uint160(_tokenId))]);
        address owner = address(uint160(_tokenId));
        EthboxStructs.UnpackedMessage[] memory messages = getOrderedMessages(
            owner
        );
        uint256 eSize = unpackEthboxSize(owner);
        uint256 eDrip = unpackEthboxDrip(owner);
        return metadata.buildMetadata(owner, messages, eSize, eDrip);
    }

    /// @dev See { ERC721-getApproved }.
    function getApproved(uint256 _tokenId)
        public
        view
        override
        returns (address)
    {
        require(minted[address(uint160(_tokenId))]);
        return address(0);
    }

    /// @dev Always returns false as transferring is disabled.
    function isApprovedForAll(address, address)
        public
        pure
        override
        returns (bool)
    {
        return false;
    }

    /// @dev All the following functions are disabled to make ethboxes soulbound.

    function approve(address, uint256) public pure override {
        revert("disabled");
    }

    function setApprovalForAll(address, bool) public pure override {
        revert("disabled");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("disabled");
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("disabled");
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override {
        revert("disabled");
    }

    ////////////////////////////////////
    // Minting function //
    ////////////////////////////////////

    /// @notice Function to mint an ethbox to a given address.
    /// Only one per address, no max supply.
    /// @dev We pack the default ethbox info into the { packedEthboxInfo } mapping.
    /// This saves a lot of gas having to set these values in a struct, or various
    /// different mappings.
    function mintMyEthbox() external onlyProxy {
        address sender = msg.sender;
        require(!minted[sender], "ethbox already minted");
        minted[sender] = true;

        packedEthboxInfo[sender] = packEthboxInfo(
            sender,
            defaultDripTime,
            defaultEthboxSize,
            false
        );

        emit Transfer(address(0), sender, uint256(uint160(sender)));
        if (ethboxMessages[sender].length > 0) {
            claimAll();
        }
    }

    //////////////////////////////////////
    // Messaging Functions //
    //////////////////////////////////////

    // @notice Set the base cost of increasing ethbox size.
    /// @param _sizeIncreaseFee The new base increase fee.
    function setSizeIncreaseFee(uint256 _sizeIncreaseFee) external onlyOwner {
        sizeIncreaseFee = _sizeIncreaseFee;
    }

    /// @notice Set the BPS increase in cost of increasing ethbox size depending
    /// on how many slots the ethbox has already bought.
    /// @param _sizeIncreaseFeeBPS The new BPS.
    function setSizeIncreaseFeeBPS(uint256 _sizeIncreaseFeeBPS) external onlyOwner {
        sizeIncreaseFeeBPS = _sizeIncreaseFeeBPS;
    }

    /// @notice Sets message fee in BPS taken by the messageFeeRecipient.
    /// @param _messageFeeBPS the new BPS.
    function setMessageFeeBPS(uint256 _messageFeeBPS) external onlyOwner {
        messageFeeBPS = _messageFeeBPS;
    }

    /// @notice Sets the recipient of the above fees.
    /// @param _messageFeeRecipient the new recipient.
    function setMessageFeeRecipient(address _messageFeeRecipient) external onlyOwner {
        messageFeeRecipient = _messageFeeRecipient;
    }

    /// @notice Sets the metadata contract that { tokenURI } points to.
    /// @dev We want this to be updatable for any future SVG changes or bugfixes.
    function setMetadataContract(address _metadata) external onlyOwner {
        metadata = EthboxMetadata(_metadata);
    }

    /// @notice Gets the claimable value of a message.
    /// @dev Using the timestamp the message was sent at, combined with the
    /// block.timestamp, we calculate how many seconds have elapesed since the
    /// message was sent. From there we can divide the elapsed seconds by the
    /// ethbox's duration (given elapsed seconds are smaller) to calculate the BPS.
    /// Finally we deduct fees from the orignal message value and multiply by BPS
    /// to get the claimable value of that message.
    /// @param _message The message struct to calculate value from.
    /// @param _drip The drip timestamp of the ethbox.
    function getClaimableValue(
        EthboxStructs.Message memory _message,
        uint256 _drip
    ) public view returns (uint256 _claimableValue) {
        uint256 elapsedSeconds = block.timestamp -
            unpackMessageTimestamp(_message.data);

        if (elapsedSeconds < 1) return 0;
        if (elapsedSeconds > _drip) return getRemainingOriginalValue(_message);
        uint256 bps = (elapsedSeconds * 100) / _drip;
        uint256 subValue = (getOriginalValueMinusFees(_message) * bps) / 100;
        return (subValue - _message.claimedValue);
    }

    /// @notice Deducts fees from the original message value.
    /// @dev Used in { getClaimableValue } and { getRemainingOriginalValue }
    /// @param _message The message struct to calculate value from.
    function getOriginalValueMinusFees(EthboxStructs.Message memory _message)
        private
        pure
        returns (uint256)
    {
        return ((_message.originalValue *
            (10000 - unpackMessageFeeBPS(_message.data))) / 10000);
    }

    /// @notice Used to refund message sender any remaining eth in their message
    /// if their message gets bumped out the inbox.
    /// @dev Used in { _refundSender }
    /// @param _message The message struct to calculate value from.
    function getRemainingOriginalValue(EthboxStructs.Message memory _message)
        private
        pure
        returns (uint256)
    {
        return (getOriginalValueMinusFees(_message) - _message.claimedValue);
    }

    /// @notice Function to send a message to an ethbox.
    /// @dev If the message has a high enough value, we bump out the lowest value
    /// message in the ethbox and replace it. But if the ethbox is not full, we
    /// just insert it.
    /// When bumping a message out of an ethbox, if that message has ETH left,
    /// we refund that ETH to the sender.
    /// @param _to The ethbox to send the message to.
    /// @param _message The message content.
    /// @param _drip The ethbox drip.
    function sendMessage(address _to, string calldata _message, uint256 _drip) public payable nonReentrant onlyProxy {
        require(bytes(_message).length < maxMessageLen, "message too long");

        EthboxStructs.EthboxInfo memory ethboxInfo = unpackEthboxInfo(_to);
        uint256 compBoxSize = defaultEthboxSize;
        uint256 compDrip = defaultDripTime;
        if (ethboxInfo.size != 0) {
            compBoxSize = ethboxInfo.size;
            compDrip = ethboxInfo.drip;
        }
        require(!ethboxInfo.locked, "ethbox is locked");
        require(msg.value > 10000 || msg.value == 0, "message value incorrect");
        require(compDrip == _drip, "message drip incorrect");

        EthboxStructs.Message[] memory toMessages = ethboxMessages[_to];

        uint256 dynamicBoxSize = toMessages.length;

        if (dynamicBoxSize < compBoxSize) {
            _pushMessage(
                _to,
                msg.sender,
                _message,
                msg.value,
                dynamicBoxSize
            );
        } else {
            (bool qualifies, uint256 indexToRemove) = _getIndexToReplace(
                toMessages,
                dynamicBoxSize,
                msg.value
            );
            if (qualifies) {
                EthboxStructs.Message memory droppedMessage = toMessages[
                    indexToRemove
                ];

                /// V2 
                /// instead of always adding the current claimValue to the bumpedClaim mapping,
                /// we instead only do that step if the ethbox is minted (and thus has a potentially active owner)
                /// this prevents eth being locked forever (and adding eth to a claimValue mapping) of non-
                /// active owners
                /// if the ethbox is not minted, the time spent in ethbox of messages is "virtually" free, unless an 
                /// owner mints (which could still happen at any time.)
                /// this change also gives more of an incentive for owners to mint/claim when messages are in their box
                /// 
                if (ethboxInfo.size != 0) {
                    uint256 claimValue = getClaimableValue(droppedMessage, compDrip);
                    droppedMessage.claimedValue += claimValue;
                    bumpedClaimValue[_to] += claimValue;
                }
                /// V2
                _refundSender(droppedMessage);
                _insertMessage(
                    _to,
                    msg.sender,
                    _message,
                    msg.value,
                    indexToRemove
                );
            } else {
                revert("message value too low");
            }
        }
        _payFees(msg.value);
    }

    /// @notice Finds the index to replace with a new message.
    /// @dev Used in { sendMessage }.
    /// Also checks if the message even qualifies for replacement - meaning, is
    /// the value of the message larger than at least one of the existing messages.
    /// @param _toMessages The existing messages in the ethbox.
    /// @param _boxSize The size of the ethbox. Used to iterate through.
    /// @param _value The value of the new message.
    /// @return qualifies Does the message qualifiy for replacement.
    /// @return indexToRemove The index to remove and insert the new message into.
    function _getIndexToReplace(
        EthboxStructs.Message[] memory _toMessages,
        uint256 _boxSize,
        uint256 _value
    ) private pure returns (bool qualifies, uint256 indexToRemove) {
        uint256 lowIndex;
        uint256 lowValue = _toMessages[0].originalValue;
        uint256 dripedValue;
        for (uint256 i = 0; i < _boxSize; i++) {
            dripedValue = _toMessages[i].originalValue;
            if (dripedValue < lowValue) {
                lowIndex = i;
                lowValue = dripedValue;
            }
            if (qualifies == false && _value > dripedValue) {
                qualifies = true;
            }
        }
        return (qualifies, lowIndex);
    }

    /// @notice Pushes a message into an ethbox. Used if an ethbox is not full.
    /// @dev Used in { sendMessage }.
    /// Packs message data into a "data" field in the Message struct using
    /// { packMessageData }
    /// @param _to The ethbox the message is being sent to.
    /// @param _from The address sending the message.
    /// @param _message The message content.
    /// @param _value The value of the message.
    /// @param _index The index of the message in the ethbox.
    function _pushMessage(
        address _to,
        address _from,
        string calldata _message,
        uint256 _value,
        uint256 _index
    ) private {
        EthboxStructs.Message memory message;

        message.data = packMessageData(
            _from,
            block.timestamp,
            _index,
            messageFeeBPS
        );

        message.message = _message;
        message.originalValue = _value;
        message.claimedValue = 0;

        ethboxMessages[_to].push(message);
    }

    /// @notice Inserts a message into an ethbox. Used if the ethbox is full.
    /// @dev Used in { sendMessage }.
    /// Packs message data just like { _pushMessage }.
    /// Instead of pushing, we insert the message at a given index.
    // @param _to The ethbox the message is being sent to.
    /// @param _from The address sending the message.
    /// @param _message The message content.
    /// @param _value The value of the message.
    /// @param _index The index to insert the message at and set in Message.data.
    function _insertMessage(
        address _to,
        address _from,
        string calldata _message,
        uint256 _value,
        uint256 _index
    ) private {
        EthboxStructs.Message memory message;

        message.data = packMessageData(
            _from,
            block.timestamp,
            _index,
            messageFeeBPS
        );

        message.message = _message;
        message.originalValue = _value;
        message.claimedValue = 0;

        ethboxMessages[_to][_index] = message;
    }

    /// @notice Removes a message from an ethbox.
    /// @dev Used in { removeOne }
    /// Sets the message to remove to the end of the array and pops it.
    /// Updates the index of the message that assumes the old index of the message
    /// we are deleting. We have to unpack and pack here to do this.
    /// @param _to The ethbox to remove a message from.
    /// @param _index The index to remove.
    function _removeMessage(address _to, uint256 _index) private {
        EthboxStructs.Message[] memory messages = ethboxMessages[_to];

        ethboxMessages[_to][_index] = messages[messages.length - 1];

        EthboxStructs.MessageData memory messageData = unpackMessageData(
            ethboxMessages[_to][_index].data
        );

        ethboxMessages[_to][_index].data = packMessageData(
            messageData.from,
            messageData.timestamp,
            _index,
            messageData.feeBPS
        );

        ethboxMessages[_to].pop();
    }

    /// @notice Removes multiple messages from an ethbox.
    /// @dev Used in { claimAll }
    /// Operates the same as { _removeMessage } but in a for loop.
    /// @param _to The ethbox to remove messages from.
    /// @param _indexes The indexes to remove.
    function _removeMessages(address _to, uint256[] memory _indexes) private {
        EthboxStructs.Message[] memory messages = ethboxMessages[_to];

        for (uint256 i = _indexes.length; i > 0; i--) {
            if (i != messages.length) {
                EthboxStructs.MessageData
                    memory messageData = unpackMessageData(messages[i].data);

                ethboxMessages[_to][_indexes[i - 1]] = messages[
                    messages.length - 1
                ];
                ethboxMessages[_to][_indexes[i - 1]].data = packMessageData(
                    messageData.from,
                    messageData.timestamp,
                    _indexes[i - 1],
                    messageData.feeBPS
                );
            }
            ethboxMessages[_to].pop();
        }
    }

    /// @notice Pays fees to the messageFeeRecipient.
    /// @dev Used in { sendMessage }.
    /// We take the value of the message and multiply by fee BPS to get the
    /// fee owed to the messageFeeRecipient.
    /// @param _value The value of the message.
    function _payFees(uint256 _value) private{
        (bool successFees, ) = messageFeeRecipient.call{
            value: (_value * messageFeeBPS) / 10000
        }("");
        require(successFees, "could not pay fees");
    }

    /// @notice Pays an ethbox owner some value.
    /// @dev Used in { claimOne }, { claimAll }, { removeOne } and { removeAll }.
    /// We need to unpack the fee recipient of the ethbox.
    /// Sends the value to that recipient.
    /// @param _value The value of the message.
    /// @param _to The ethbox owner.
    function _payRecipient(address _to, uint256 _value) private{
        address recipient = unpackEthboxAddress(_to);
        (bool successRecipient, ) = recipient.call{value: _value}("");
        require(successRecipient, "could not pay recipient");
    }

    /// @notice Refunds the sender of a message that has been bumped or removed.
    /// @dev Used in { removeAll }, { removeOne } and { sendMessage }.
    /// Need to unpack who sent the message from Message.data.
    /// @param _message The message used to calculate refundable value and who
    /// to send value to.
    function _refundSender(EthboxStructs.Message memory _message) private {
        uint256 refundValue = getRemainingOriginalValue(_message);
        address from = unpackMessageFrom(_message.data);
        (bool successRefund, ) = from.call{value: refundValue}("");
        require(successRefund);
    }

    /// @notice Orders the messages in an ethbox by value.
    /// @dev Only used in { tokenURI } for metadata purposes.
    /// Unpacks the messages into an UnpackedMessage struct.
    /// See { EthboxStructs.UnpackedMessage }.
    /// @param _to Ethbox owner to query.
    /// @return _messages Ordered messages.
    function getOrderedMessages(address _to)
        public
        view
        returns (EthboxStructs.UnpackedMessage[] memory)
    {
        EthboxStructs.Message[] memory messages = ethboxMessages[_to];

        for (uint256 i = 1; i < messages.length; i++) {
            for (uint256 j = 0; j < i; j++) {
                if (messages[i].originalValue > messages[j].originalValue) {
                    EthboxStructs.Message memory x = messages[i];
                    messages[i] = messages[j];
                    messages[j] = x;
                }
            }
        }
        EthboxStructs.UnpackedMessage[]
            memory unpackedMessages = new EthboxStructs.UnpackedMessage[](
                messages.length
            );
        EthboxStructs.MessageData memory unpackedData;
        for (uint256 k = 0; k < messages.length; k++) {
            EthboxStructs.UnpackedMessage memory newMessage;
            unpackedData = unpackMessageData(messages[k].data);
            newMessage.message = messages[k].message;
            newMessage.originalValue = messages[k].originalValue;
            newMessage.claimedValue = messages[k].claimedValue;
            newMessage.from = unpackedData.from;
            newMessage.timestamp = unpackedData.timestamp;
            newMessage.index = unpackedData.index;
            newMessage.feeBPS = unpackedData.feeBPS;
            unpackedMessages[k] = newMessage;
        }
        return unpackedMessages;
    }

    /// @dev Mimics { getOrderedMessages } without unpacking.
    function getOrderedPackedMessages(address _to)
        public
        view
        returns (EthboxStructs.Message[] memory)
    {
        EthboxStructs.Message[] memory messages = ethboxMessages[_to];

        for (uint256 i = 1; i < messages.length; i++) {
            for (uint256 j = 0; j < i; j++) {
                if (messages[i].originalValue > messages[j].originalValue) {
                    EthboxStructs.Message memory x = messages[i];
                    messages[i] = messages[j];
                    messages[j] = x;
                }
            }
        }
        return messages;
    }

    /// @notice Sets the locked state of an ethbox. If an ethbox is locked it
    /// cannot recieve messages.
    /// @dev We unpack and repack the sender's ethbox info with the new value.
    /// @param _isLocked The locked value to set their ethbox to.
    function changeEthboxLocked(bool _isLocked) external {
        EthboxStructs.EthboxInfo memory ethboxInfo = unpackEthboxInfo(
            msg.sender
        );
        require(ethboxInfo.size != 0, "ethbox needs to be minted");

        packedEthboxInfo[msg.sender] = packEthboxInfo(
            ethboxInfo.recipient,
            ethboxInfo.drip,
            ethboxInfo.size,
            _isLocked
        );
    }

    /// @notice Sets the payout recipient of the ethbox. Allows people to have
    /// their ethbox in cold storage, but get paid into a hot wallet.
    /// @dev We unpack and repack the sender's ethbox info with the new value.
    /// @param _recipient The new recipient of ethbox funds.
    function changeEthboxPayoutRecipient(address _recipient) external {
        EthboxStructs.EthboxInfo memory ethboxInfo = unpackEthboxInfo(
            msg.sender
        );
        require(ethboxInfo.size != 0, "ethbox needs to be minted");

        packedEthboxInfo[msg.sender] = packEthboxInfo(
            _recipient,
            ethboxInfo.drip,
            ethboxInfo.size,
            ethboxInfo.locked
        );
    }

    /// @notice Sets the drip time in an ethbox. This can only be done when the
    /// ethbox is locked and empty.
    /// @dev We unpack and repack the sender's ethbox info with the new value.
    /// @param _dripTime The new drip time of the ethbox's messages.
    function changeEthboxDripTime(uint256 _dripTime) external {
        EthboxStructs.EthboxInfo memory ethboxInfo = unpackEthboxInfo(
            msg.sender
        );
        require(ethboxInfo.size != 0, "ethbox needs to be minted");
        require(
            ethboxMessages[msg.sender].length == 0,
            "ethbox needs to be empty"
        );

        packedEthboxInfo[msg.sender] = packEthboxInfo(
            ethboxInfo.recipient,
            _dripTime,
            ethboxInfo.size,
            ethboxInfo.locked
        );
    }

    /// @notice Expands the ethbox size of the sender.
    /// @dev Sender must have minted.
    /// See { calculateSizeIncreaseCost } for how size increase is calculated.
    /// @param _size New ethbox size.
    function changeEthboxSize(uint256 _size) external payable {
        EthboxStructs.EthboxInfo memory ethboxInfo = unpackEthboxInfo(
            msg.sender
        );
        require(ethboxInfo.size != 0, "ethbox needs to be minted");
        uint256 total = calculateSizeIncreaseCost(_size, ethboxInfo.size);
        require(total == msg.value, total.toString());

        packedEthboxInfo[msg.sender] = packEthboxInfo(
            ethboxInfo.recipient,
            ethboxInfo.drip,
            _size,
            ethboxInfo.locked
        );
        (bool successFees, ) = messageFeeRecipient.call{value: msg.value}("");
        require(successFees);
    }

    /// @notice Calculates the cost of increasing ethbox size to a given value.
    /// @dev Used in { expandEthboxSize }.
    /// Uses { sizeIncreaseFee } and { sizeIncreaseFeeBPS } in calculation.
    /// @param _size The desired ethbox size.
    /// @param _currentSize The current size of the ethbox.
    /// @return total Cost of increasing inbox to desired size.
    function calculateSizeIncreaseCost(uint256 _size, uint256 _currentSize)
        public
        view
        returns (uint256 total)
    {
        require(_size > _currentSize, "new size should be larger");
        total = 0;
        for (uint256 i = _currentSize; i < _size; i++) {
            if (i == defaultEthboxSize) {
                total += sizeIncreaseFee;
            } else {
                total +=
                    (sizeIncreaseFee *
                        ((sizeIncreaseFeeBPS + 10000) **
                            (i - defaultEthboxSize))) /
                    (10000**(i - defaultEthboxSize));
            }
        }
        return total;
    }

    /// @notice Removes all messages from an ethbox.
    /// @dev An ethbox owner may call this so they can change the drip of their
    /// box. This calculates how much each message sender is owed and refunds them.
    /// The ethbox owner claims the remaining ETH.
    function removeAll() external nonReentrant {
        require(minted[msg.sender], "ethbox needs to be minted");
        uint256 claimValue = 0;
        uint256 totalValue = 0;

        EthboxStructs.Message[] memory messages = ethboxMessages[msg.sender];
        uint256 boxSize = messages.length;

        for (uint256 i = 0; i < boxSize; i++) {
            claimValue = getClaimableValue(
                messages[i],
                unpackEthboxDrip(msg.sender)
            );

            totalValue += claimValue;
            ethboxMessages[msg.sender][i].claimedValue += claimValue;
            _refundSender(ethboxMessages[msg.sender][i]);
        }
        delete ethboxMessages[msg.sender];
        _payRecipient(msg.sender, totalValue);
    }

    /// @notice Removes one of the messages in the ethbox.
    /// @dev An ethbox owner may not like a message they have recieved, they can
    /// use this to delete it. Like { removeAll } this calculates how much they
    /// can claim, and how much must be refunded.
    /// We are using the combination of these 3 parameters to guarantee that the ethbox
    /// owner will remove only the message they really intend to, without running the 
    /// risk of being front-run by a sendMessage transaction.
    /// @param _index The index of the message to delete.
    /// @param _messageValue the original value of the message to delete
    /// @param _from the sender of the message to delete
    function removeOne(uint256 _index, uint256 _messageValue, address _from) external nonReentrant {
        require(minted[msg.sender], "ethbox needs to be minted");

        EthboxStructs.Message memory message = ethboxMessages[msg.sender][_index];
        require(_messageValue == message.originalValue, "message at index does not match value");

        EthboxStructs.MessageData memory messageData = unpackMessageData(message.data);
        require(_from == messageData.from, "message at index does not match sender address");

        uint256 claimValue = getClaimableValue(
            message,
            unpackEthboxDrip(msg.sender)
        );

        message.claimedValue += claimValue;
        ethboxMessages[msg.sender][_index] = message;
        _removeMessage(msg.sender, _index);
        _refundSender(message);
        _payRecipient(msg.sender, claimValue);
    }

    /// @notice Function to claim all of the ETH owed to the sender's ethbox.
    /// @dev Calculates how much they are owed for each message and the claims
    /// the ETH. We update the claimed value of the message in the Message struct
    /// so that the owner cannot double claim.
    function claimAll() public nonReentrant {
        require(minted[msg.sender], "ethbox needs to be minted");
        uint256 claimValue = 0;
        uint256 totalValue = 0;

        EthboxStructs.Message[] memory messages = ethboxMessages[msg.sender];
        uint256 boxSize = messages.length;

        uint256[] memory removalIndexes = new uint256[](boxSize);
        uint256 removalCount = 0;

        uint256 dripTime = unpackEthboxDrip(msg.sender);

        for (uint256 i = 0; i < boxSize; i++) {
            EthboxStructs.Message memory message = messages[i];

            claimValue = getClaimableValue(message, dripTime);
            totalValue += claimValue;

            ethboxMessages[msg.sender][i].claimedValue += claimValue;

            if (
                (unpackMessageTimestamp(message.data) + dripTime) <
                block.timestamp
            ) {
                removalIndexes[removalCount] = i;
                removalCount++;
            }
        }

        uint256[] memory trimmedIndexes = new uint256[](removalCount);
        for (uint256 j = 0; j < trimmedIndexes.length; j++) {
            trimmedIndexes[j] = removalIndexes[j];
        }
        totalValue += bumpedClaimValue[msg.sender];
        bumpedClaimValue[msg.sender] = 0;
        _removeMessages(msg.sender, trimmedIndexes);
        _payRecipient(msg.sender, totalValue);
    }

    /// @notice Allows sender to claim ETH from one of their messages.
    /// @dev Uses { getClaimable value } on the message struct with the ethbox's
    /// drip to calculate.
    ///
    /// We are using the combination of these 3 parameters to guarantee that the ethbox
    /// owner will clalim only the message they really intend to, without running the 
    /// risk of being front-run by a sendMessage transaction.
    /// @param _index Index to claim ETH on.
    /// @param _messageValue the original value of the message to delete
    /// @param _from the sender of the message to delete
    function claimOne(uint256 _index, uint256 _messageValue, address _from) external nonReentrant {
        EthboxStructs.EthboxInfo memory ethboxInfo = unpackEthboxInfo(msg.sender);
        require(ethboxInfo.size != 0, "ethbox needs to be minted");

        EthboxStructs.Message memory message = ethboxMessages[msg.sender][_index];
        require(_messageValue == message.originalValue, "message at index does not match value");

        EthboxStructs.MessageData memory messageData = unpackMessageData(message.data);
        require(_from == messageData.from, "message at index does not match sender address");

        uint256 claimValue = getClaimableValue(
            message,
            unpackEthboxDrip(msg.sender)
        );
        if (messageData.timestamp + ethboxInfo.drip < block.timestamp){
            _removeMessage(msg.sender, messageData.index);
        }else {
            ethboxMessages[msg.sender][_index].claimedValue += claimValue;
        }
        _payRecipient(msg.sender, claimValue);
    }

    /// @notice A view function for external use in app or elsewhere.
    /// @dev Mimics how { claimAll } works, without making any payments.
    /// @param _ethboxAddress The ethbox address to query.
    /// @return value The claimable value of the ethbox.
    function getClaimableValueOfEthbox(address _ethboxAddress)
        public
        view
        returns (uint256)
    {
        EthboxStructs.Message[] memory messages = ethboxMessages[
            _ethboxAddress
        ];

        EthboxStructs.EthboxInfo memory ethboxInfo = unpackEthboxInfo(_ethboxAddress);

        uint256 boxSize = messages.length;
        uint256 claimValue = 0;
        uint256 totalValue = 0;
        uint256 realDrip = ethboxInfo.size == 0 ? defaultDripTime : ethboxInfo.drip;

        for (uint256 i = 0; i < boxSize; i++) {
            claimValue = getClaimableValue(
                messages[i],
                realDrip
            );
            totalValue += claimValue;
        }
        totalValue += bumpedClaimValue[_ethboxAddress];
        return totalValue;
    }

    //////////////////////////////////////
    //////////////////////////////////////
    // Packing & Unpacking Functions //
    //////////////////////////////////////
    //////////////////////////////////////

    /// @dev Unpacks the recipient in the packedEthboxInfo uint256.
    /// Used in { _payRecipient }
    /// @param _address The ethbox to query.
    /// @return recipient The payout recipient of the ethbox.
    function unpackEthboxAddress(address _address)
        private
        view
        returns (address)
    {
        return address(uint160(packedEthboxInfo[_address]));
    }

    /// @dev Unpacks the drip in the packedEthboxInfo uint256.
    /// Used in { claimOne }, { getClaimableValueOfEthbox }, { claimAll },
    /// { removeOne } and { removeAll }
    /// @param _address The ethbox to query.
    /// @return timestamp The drip timestamp of the ethbox.
    function unpackEthboxDrip(address _address) private view returns (uint64) {
        return
            uint64(packedEthboxInfo[_address] >> BITPOS_ETHBOX_DRIP_TIMESTAMP);
    }

    /// @dev Unpacks the size in the packedEthboxInfo uint256.
    /// Used in { tokenURI }
    /// @param _address The ethbox to query.
    /// @return size The size of the ethbox.
    function unpackEthboxSize(address _address) private view returns (uint8) {
        return uint8(packedEthboxInfo[_address] >> BITPOS_ETHBOX_SIZE);
    }

    /// @dev Unpacks the locked state in the packedEthboxInfo uint256.
    /// Not being used currently.
    /// @param _address The ethbox to query.
    /// @return isLocked Boolean reflecting whether the ethbox is locked or not.
    function unpackEthboxLocked(address _address) private view returns (bool) {
        uint256 flag = (packedEthboxInfo[_address] >> BITPOS_ETHBOX_LOCKED) &
            uint256(1);
        return flag != 0;
    }

    /// @dev Unpacks the entire packedEthboxInfo uint256 into an EthboxInfo struct.
    /// See { EthboxStructs.EthboxInfo }.
    /// Used in { expandEthboxSize }, { changeEthboxDurationTime },
    /// { changeEthboxPayoutRecipient }, { setEthboxIsLocked } and { sendMessage }.
    /// @param _address Address to unpack the ethbox of.
    /// @return ethbox The ethbox's info.
    function unpackEthboxInfo(address _address)
        public
        view
        returns (EthboxStructs.EthboxInfo memory ethbox)
    {
        uint256 packedEthbox = packedEthboxInfo[_address];
        ethbox.recipient = address(uint160(packedEthbox));
        ethbox.drip = uint64(packedEthbox >> BITPOS_ETHBOX_DRIP_TIMESTAMP);
        ethbox.size = uint8(packedEthbox >> BITPOS_ETHBOX_SIZE);
        ethbox.locked =
            ((packedEthbox >> BITPOS_ETHBOX_LOCKED) & uint256(1)) != 0;
    }

    /// @dev Packs an ethbox's info.
    /// Does this by casting each input to a specific part of a uint256.
    /// Used in all the same functions as { unpackEthboxInfo } and used by
    /// { mintMyEthbox }.
    /// @param _recipient Payout recipient of the ethbox.
    /// @param _drip Drip timestamp of the ethbox.
    /// @param _size Size of the ethbox.
    /// @param _locked Locked state of the ethbox.
    /// @return packed The packed ethbox info.
    function packEthboxInfo(
        address _recipient,
        uint256 _drip,
        uint256 _size,
        bool _locked
    ) private pure returns (uint256) {
        uint256 packedEthbox = uint256(uint160(_recipient));
        packedEthbox |=
            (_drip << BITPOS_ETHBOX_DRIP_TIMESTAMP) |
            (boolToUint(_locked) << BITPOS_ETHBOX_LOCKED) |
            (_size << BITPOS_ETHBOX_SIZE);
        return packedEthbox;
    }

    /// @dev Casts a boolean value to a uint256. True -> 1, False -> 0.
    /// Helper used in { packEthboxInfo }
    function boolToUint(bool _b) private pure returns (uint256) {
        uint256 _bInt;
        assembly {
            // SAFETY: Simple bool-to-int cast.
            _bInt := _b
        }
        return _bInt;
    }

    /// @dev Packs part of the Message struct into a "data" field.
    /// Used in { _removeMessage/s }, { _insertMessage } and { _pushMessage }.
    /// Using the same method as { packEthboxInfo }, we cast each input to a
    /// specific part of the uint256 we return.
    /// @param _from The from address of the message.
    /// @param _timestamp The timestamp the message was sent at.
    /// @param _index The index of the message in the ethbox.
    /// @param _feeBPS The global feeBPS at the time of the message being sent.
    /// @return packed The packed message data.
    function packMessageData(
        address _from,
        uint256 _timestamp,
        uint256 _index,
        uint256 _feeBPS
    ) private pure returns (uint256) {
        uint256 packedEthbox = uint256(uint160(_from));
        packedEthbox |=
            (_timestamp << BITPOS_MESSAGE_TIMESTAMP) |
            (_index << BITPOS_MESSAGE_INDEX) |
            (_feeBPS << BITPOS_MESSAGE_FEEBPS);
        return packedEthbox;
    }

    /// @dev Unpacks the message data into a MessageData stuct.
    /// See { EthboxStructs.MessageData }.
    /// Used in { _removeMessage/s }.
    /// Using the same method as { unpackEthboxInfo } we shift bits back to
    /// where they once were, and apply appropriate data types.
    /// @param _data Message data to unpack.
    /// @return messageData Unpacked message data.
    function unpackMessageData(uint256 _data)
        private
        pure
        returns (EthboxStructs.MessageData memory messageData)
    {
        messageData.from = address(uint160(_data));
        messageData.timestamp = uint64(_data >> BITPOS_MESSAGE_TIMESTAMP);
        messageData.index = uint8(_data >> BITPOS_MESSAGE_INDEX);
        messageData.feeBPS = uint24(_data >> BITPOS_MESSAGE_FEEBPS);
    }

    /// @dev Unpacks the sent timestamp in packed message data.
    /// Used in { claimAll } and { getClaimableValue }.
    /// @param _data Data to unpack.
    /// @return timestamp Timestamp the message was sent at.
    function unpackMessageTimestamp(uint256 _data)
        private
        pure
        returns (uint64)
    {
        return uint64(_data >> BITPOS_MESSAGE_TIMESTAMP);
    }

    /// @dev Unpacks the feeBPS in packed message data.
    /// Used in { getOriginalValueMinusFees }
    /// @param _data Data to unpack.
    /// @return feeBPS FeeBPS when the message was sent.
    function unpackMessageFeeBPS(uint256 _data) private pure returns (uint24) {
        return uint24(_data >> BITPOS_MESSAGE_FEEBPS);
    }

    /// @dev Unpacks the index in packed message data.
    /// Currently not being used.
    /// @param _data Data to unpack.
    /// @return index Index of the message in the ethbox.
    function unpackMessageIndex(uint256 _data) private pure returns (uint8) {
        return uint8(_data >> BITPOS_MESSAGE_INDEX);
    }

    /// @dev Unpacks the message sender in packed message data.
    /// Used in { _refundSender }
    /// @param _data Data to unpack.
    /// @return sender Sender of the message.
    function unpackMessageFrom(uint256 _data) private pure returns (address) {
        return address(uint160(_data));
    }

    //--External Unpacking Functions for Use In App and Elsewhere--//

    /// @dev These do the same as the above functions, but are just external.
    /// Please refer back to the documentation for { unpackEthboxInfo }.

    function ethboxDripTime(address _owner) external view returns (uint256) {
        if (minted[_owner]) return unpackEthboxInfo(_owner).drip;
        return defaultDripTime;
    }

    function ethboxPayoutRecipient(address _owner) external view returns (address) {
        if (minted[_owner]) return unpackEthboxInfo(_owner).recipient;
        return _owner;
        
    }

    function ethboxSize(address _owner) external view returns (uint256) {
        if (minted[_owner]) return unpackEthboxInfo(_owner).size;
        return defaultEthboxSize;
    }

    function ethboxLocked(address _owner) external view returns (bool) {
        if (minted[_owner]) return unpackEthboxInfo(_owner).locked;
        return false;
    }

    /// @dev Refunds the value of a message if the owner didn't mint
    /// V2
    /// @param _index The index of the message to delete and refund
    /// @param _messageValue the original value of the message to delete and refund
    /// @param _to the address of the targeted ethbox
    function getRefundForMessage(uint256 _index, uint256 _messageValue, address _to) external nonReentrant {
        require(!minted[_to], "ethbox needs to be not minted");

        EthboxStructs.Message memory message = ethboxMessages[_to][_index];
        require(_messageValue == message.originalValue, "message at index does not match value");

        EthboxStructs.MessageData memory messageData = unpackMessageData(message.data);
        require(msg.sender == messageData.from, "message at index does not match your address");

        uint256 elapsedSeconds = block.timestamp - messageData.timestamp;
        require(elapsedSeconds > defaultDripTime, "message needs to be expired");

        _removeMessage(_to, _index);
        _refundSender(message);
    }
}