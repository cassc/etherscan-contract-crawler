// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC1155.sol";
import "./interfaces/IRAW.sol";
import "./interfaces/IRAWoriginal.sol";
import "./interfaces/IEON.sol";

contract RAW is IRAW, ERC1155, Pausable {
    using Strings for uint256;

    struct LastWrite {
        uint64 time;
        uint64 blockNum;
    }

    // struct to store each trait's data for metadata and rendering
    struct Image {
        string name;
        string png;
    }

    struct TypeInfo {
        uint256 mints;
        uint256 burns;
        uint256 maxSupply;
        uint256 eonExchangeAmt;
    }

    mapping(uint256 => TypeInfo) private typeInfo;
    // storage of each image data
    mapping(uint256 => Image) public traitData;

    // address => allowedToCallFunctions
    mapping(address => bool) private admins;

    // Tracks the last block and timestamp that a caller has written to state.
    // Disallow some access to functions if they occur while a change is being written.
    mapping(address => LastWrite) private lastWriteAddress;

    event UpdateMintBurns(uint256 typeId, uint256 mintQty, uint256 burnQty);

    // reference to the $EON contract for exchange rate if accepted
    IEON public eon;

    // reference to the original Raw contract
    IRAWoriginal public originalRaw;

    address public auth;

    uint256 public migrated;

    constructor() {
        _pause();
        auth = msg.sender;
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

    modifier blockIfChangingAddress() {
        require(
            admins[msg.sender] ||
                lastWriteAddress[tx.origin].blockNum < block.number,
            "Your trying the cheat"
        );
        _;
    }

    function setContracts(address _eon, address _originalRaw)
        external
        onlyOwner
    {
        eon = IEON(_eon);
        originalRaw = IRAWoriginal(_originalRaw);
    }

    /**
     * Mint a token - any payment / game logic should be handled in the game contract.
     */
    function mint(
        uint256 typeId,
        uint256 qty,
        address recipient
    ) external override whenNotPaused {
        require(admins[msg.sender],  "Only admins");
        require(
            (typeInfo[typeId].mints + qty) <= typeInfo[typeId].maxSupply,
            "MaxSupply Minted"
        );
        typeInfo[typeId].mints += qty;
        _mint(recipient, typeId, qty, "");
    }

    /**
     * Burn a token - any payment / game logic should be handled in the game contract.
     */
    function burn(
        uint256 typeId,
        uint256 qty,
        address burnFrom
    ) external override whenNotPaused {
        require(admins[msg.sender], "Only admins");
        typeInfo[typeId].burns += qty;
        _burn(burnFrom, typeId, qty);
    }

    function setType(uint256 typeId, uint256 maxSupply) external onlyOwner {
        require(typeId != 0, "TypeId cannot be 0");
        require(typeInfo[typeId].mints <= maxSupply, "max supply too low");
        typeInfo[typeId].maxSupply = maxSupply;
    }

    // a function to update the mint and burn amounts
    // to save gas costs of doing both a mint and then
    // burn when cost is paid from an amount owed
    function updateMintBurns(
        uint256 typeId,
        uint256 mintQty,
        uint256 burnQty
    ) external {
        require(admins[msg.sender], "Only Admins");
        typeInfo[typeId].mints += mintQty;
        typeInfo[typeId].burns += burnQty;

        emit UpdateMintBurns(typeId, mintQty, burnQty);
    }

    function setExchangeAmt(uint256 typeId, uint256 exchangeAmt)
        external
        onlyOwner
    {
        require(
            typeInfo[typeId].maxSupply > 0,
            "this type has not been set up"
        );
        typeInfo[typeId].eonExchangeAmt = exchangeAmt;
    }

    function balanceOf(address tokenOwner, uint256 typeId)
        public
        view
        blockIfChangingAddress
        returns (uint256)
    {
        //Prevent chencking balance in the same block it's being modified..
        require(
            admins[msg.sender] ||
                lastWriteAddress[tokenOwner].blockNum < block.number,
            "no checking balance in the same block it's being modified"
        );
        uint256 balance = _balanceOf[tokenOwner][typeId];
        return balance;
    }
  function updateOriginAccess(address user) external override {
        require(admins[_msgSender()], "Only admins can call this");
        uint64 blockNum = uint64(block.number);
        uint64 time = uint64(block.timestamp);
        lastWriteAddress[user] = LastWrite(time, blockNum);
  }
    /**
     * creates identical tokens in the new contract
     * and burns any original tokens
     * @param typeId the type of the tokens to migrate
     */
    function migrate(uint256 typeId) external whenNotPaused {
        uint256 amount = originalRaw.getBalance(msg.sender, typeId);
        require(amount > 0, "no tokens to migrate");
        originalRaw.burn(typeId, amount, msg.sender);
        _mint(msg.sender, typeId, amount, "");
        migrated += amount;
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

    function transferOwnership(address newOwner) external onlyOwner {
        auth = newOwner;
    }

    function getInfoForType(uint256 typeId)
        external
        view
        returns (TypeInfo memory)
    {
        require(typeInfo[typeId].maxSupply > 0, "invalid type");
        return typeInfo[typeId];
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        require(typeInfo[typeId].maxSupply > 0, "invalid type");
        Image memory img = traitData[typeId];
        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                img.name,
                '", "description": "Raw Pytheas resources - All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. Just the Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
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
                    '<svg id="rawResources" width="100%" height="100%" version="1.1" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
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
    ) public virtual override(ERC1155, IRAW) {
        require(lastWriteAddress[from].blockNum < block.number, "no overwriting");
        // allow admin contracts to send without approval
        if (!admins[msg.sender]) {
            require(
                msg.sender == from || isApprovedForAll[from][msg.sender],
                "NOT_AUTHORIZED"
            );
        }
        _balanceOf[from][id] -= amount;
        _balanceOf[to][id] += amount;

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
    ) public virtual override(ERC1155, IRAW) {
         require(lastWriteAddress[from].blockNum < block.number, "no overwriting");
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

            _balanceOf[from][id] -= amount;
            _balanceOf[to][id] += amount;

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