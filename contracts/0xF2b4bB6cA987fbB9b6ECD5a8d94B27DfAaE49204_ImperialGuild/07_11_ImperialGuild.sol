// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IERC1155TokenReceiver.sol";
import "./interfaces/IImperialGuild.sol";
import "./interfaces/IEON.sol";
import "./interfaces/IRAW.sol";
import "./ERC1155.sol";
import "./EON.sol";

contract ImperialGuild is
    IImperialGuild,
    IERC1155TokenReceiver,
    ERC1155,
    Pausable
{
    using Strings for uint256;

    // struct to store each trait's data for metadata and rendering
    struct Image {
        string name;
        string png;
    }

    struct TypeInfo {
        uint16 mints;
        uint16 burns;
        uint16 maxSupply;
        uint256 eonExAmt;
        uint256 secExAmt;
    }
    struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }

    // hardcoded tax % to the Imperial guild, collected from shard and onosia purchases
    // to be used in game at a later time
    uint256 public constant ImperialGuildTax = 20;

    // multiplier for eon exchange amount

    uint256 public constant multiplier = 10**18;

    // payments for shards and onosia will collect in this contract until
    // an owner withdraws, at which point the tax % above will be sent to the
    // treasury and the remainder will be burnt *see withdraw
    address private ImperialGuildTreasury;

    address public auth;

    // Tracks the last block and timestamp that a caller has written to state.
    // Disallow some access to functions if they occur while a change is being written.
    mapping(address => LastWrite) private lastWrite;

    mapping(uint256 => TypeInfo) private typeInfo;
    // storage of each image data
    mapping(uint256 => Image) public traitData;

    // address => allowedToCallFunctions
    mapping(address => bool) private admins;

    IEON public eon;

    // reference to the raw contract for processing payments in raw eon or other
    // raw materials
    IRAW public raw;

    EON public eonToken;

    constructor() {
        auth = msg.sender;
        admins[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    /** CRITICAL TO SETUP */

    modifier requireContractsSet() {
        require(address(eon) != address(0), "Contracts not set");
        _;
    }

    function setContracts(address _eon, address _raw) external onlyOwner {
        eon = IEON(_eon);
        raw = IRAW(_raw);
        eonToken = EON(_eon);
    }

    /**
     * Mint a token - any payment / game logic should be handled in the DenOfAlgol contract.
     * ATENTION- PaymentId "0" is reserved for EON only!!
     * All other paymentIds point to the RAW contract ID
     */
    function mint(
        uint256 typeId,
        uint256 paymentId,
        uint16 qty,
        address recipient
    ) external override whenNotPaused {
        require(admins[msg.sender], "Only admins can call this");
        require(
            typeInfo[typeId].mints + qty <= typeInfo[typeId].maxSupply,
            "All tokens minted"
        );
        // all payments will be transferred to this contract
        //this allows the hardcoded ImperialGuild tax that will be used in future additions to shatteredEON to be withdrawn. At the time of withdaw the balance of this contract will be burnt - the tax amount.
        if (paymentId == 0) {
            eon.transferFrom(
                tx.origin,
                address(this),
                typeInfo[typeId].eonExAmt * qty
            );
        } else {
            raw.safeTransferFrom(
                tx.origin,
                address(this),
                paymentId,
                typeInfo[typeId].secExAmt * qty,
                ""
            );
        }
        typeInfo[typeId].mints += qty;
        _mint(recipient, typeId, qty, "");
    }

    /**
     * Burn a token - any payment / game logic should be handled in the game contract.
     */
    function burn(
        uint256 typeId,
        uint16 qty,
        address burnFrom
    ) external override whenNotPaused {
        require(admins[msg.sender], "Only admins can call this");

        typeInfo[typeId].burns += qty;
        _burn(burnFrom, typeId, qty);
    }

    function handlePayment(uint256 amount) external override whenNotPaused {
        require(admins[msg.sender], "Only admins can call this");
        eon.transferFrom(tx.origin, address(this), amount);
    }

    // used to create new erc1155 typs from the Imperial guild
    // ATTENTION - Type zero is reserved to not cause conflicts
    function setType(uint256 typeId, uint16 maxSupply) external onlyOwner {
        require(typeInfo[typeId].mints <= maxSupply, "max supply too low");
        typeInfo[typeId].maxSupply = maxSupply;
    }

    // store exchange rates for new erc1155s for both EON and/or
    // any raw resource
    function setExchangeAmt(
        uint256 typeId,
        uint256 exchangeAmt,
        uint256 secExchangeAmt
    ) external onlyOwner {
        require(
            typeInfo[typeId].maxSupply > 0,
            "this type has not been set up"
        );
        typeInfo[typeId].eonExAmt = exchangeAmt;
        typeInfo[typeId].secExAmt = secExchangeAmt;
    }

    /**
     * enables an address to mint / burn
     * @param addr the address to enable
     */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    /**
     * disables an address from minting / burning
     * @param addr the address to disbale
     */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

    function setPaused(bool _paused) external onlyOwner requireContractsSet {
        if (_paused) _pause();
        else _unpause();
    }

    // owner call to withdraw this contracts EON balance * 20%
    // to the Imperial guild treasury, the remainder is then burned
    function withdrawEonAndBurn() external onlyOwner {
        uint256 guildAmt = eonToken.balanceOf(address(this)) *
            (ImperialGuildTax / 100);
        uint256 amtToBurn = eonToken.balanceOf(address(this)) - guildAmt;
        eonToken.transferFrom(address(this), ImperialGuildTreasury, guildAmt);
        eonToken.burn(address(this), amtToBurn);
    }

    // owner function to withdraw this contracts raw resource balance * 20%
    // to the Imperial guild treasury, the remainder is then burned
    function withdrawRawAndBurn(uint16 id) external onlyOwner {
        uint256 rawBalance = raw.getBalance(address(this), id);
        uint256 guildAmt = rawBalance * (ImperialGuildTax / 100);
        uint256 amtToBurn = rawBalance - guildAmt;
        raw.safeTransferFrom(
            address(this),
            ImperialGuildTreasury,
            id,
            guildAmt,
            ""
        );
        raw.burn(id, amtToBurn, address(this));
    }

    // owner function to set the Imperial guild treasury address
    function setTreasuries(address _treasury) external onlyOwner {
        ImperialGuildTreasury = _treasury;
    }

    // external function to recieve information on a given
    // ERC1155 from the ImperialGuild
    function getInfoForType(uint256 typeId)
        external
        view
        returns (TypeInfo memory)
    {
        require(typeInfo[typeId].maxSupply > 0, "invalid type");
        return typeInfo[typeId];
    }

    // ERC1155 token uri  and renders for the on chain metadata

    function uri(uint256 typeId) public view override returns (string memory) {
        require(typeInfo[typeId].maxSupply > 0, "invalid type");
        Image memory img = traitData[typeId];
        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                img.name,
                '", "description": "The Guild Lords of Pytheas are feared for their ruthless cunning and enterprising technological advancements. They alone have harnessed the power of a dying star to power a man made planet that processes EON. Rumor has it that they also dabble in the shadows as a black market dealer of hard to find artifacts and might entertain your offer for the right price, but be sure to tread lightly as they control every aspect of the economy in this star system. You would be a fool to arrive empty handed in any negotiation with them. All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. Just the Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
                base64(bytes(drawSVG(typeId))),
                '", "attributes": []',
                "}"
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64(bytes(metadata))
                )
            );
    }

    function uploadImage(uint256 typeId, Image calldata image)
        external
        onlyOwner
    {
        traitData[typeId] = Image(image.name, image.png);
    }

    function drawImage(Image memory image)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<image x="0" y="0" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    image.png,
                    '"/>'
                )
            );
    }

    function drawSVG(uint256 typeId) internal view returns (string memory) {
        string memory svgString = string(
            abi.encodePacked(drawImage(traitData[typeId]))
        );

        return
            string(
                abi.encodePacked(
                    '<svg id="ImperialGuild" width="100%" height="100%" version="1.1" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    svgString,
                    "</svg>"
                )
            );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override(ERC1155, IImperialGuild) {
        // allow admin contracts to send without approval
        if (!admins[msg.sender]) {
            require(
                msg.sender == from || isApprovedForAll[from][msg.sender],
                "NOT_AUTHORIZED"
            );
        }
        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155, IImperialGuild) {
        // allow admin contracts to send without approval
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        // allow admin contracts to send without approval
        if (!admins[msg.sender]) {
            require(
                msg.sender == from || isApprovedForAll[from][msg.sender],
                "NOT_AUTHORIZED"
            );
        }

        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }
        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function getBalance(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        return ERC1155(address(this)).balanceOf(account, id);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155TokenReceiver.onERC1155Received.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /** BASE 64 - Written by Brech Devos */

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    // For OpenSeas
    function owner() public view virtual returns (address) {
        return auth;
    }
}