// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                             ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

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
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        uint256 ownersLength = owners.length; // Saves MLOADs.

        require(ownersLength == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ownersLength; i++) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

contract Interleave is ERC1155, Ownable {

    // NFT name
    string public name;
    // NFT symbol
    string public symbol;
    // NFT uri per ID
    mapping(uint256 => string) private _uri;

    // Addresses that can mint new NFTs
    mapping(address => bool) public minters;

    // Mapping from token ID to token existence
    mapping(uint256 => bool) private exists;

    // Mapping from token ID to boolean indicating if minting for that ID has been stopped
    mapping(uint256 => bool) private unmintable;

    // Mapping from token ID to boolean indicating if uri is frozen
    mapping(uint256 => bool) private uriFrozen;

    // Mapping from token ID to token supply
    mapping(uint256 => uint256) private tokenSupply;

    // Emitted when allowances of a minter is changed
    event SetMinter(address minter, bool enabled);

    // Emitted when a new NFT type is added
    event Add(uint256 id);

    // Emitted when minting of a NFT is stopped
    event MintingStopped(uint256 id);

    // Emitted when the URI of an ID is updated
    event updateUri(string uri, uint256 indexed id);

    // Emitted when the URI of an ID is frozen
    event PermanentURI(string uri, uint256 indexed id);

    constructor(
        string memory _name,
        string memory _symbol
        //string memory _baseUri
    ) ERC1155() {
        name = _name;
        symbol = _symbol;
        //_setURI(_baseUri);
    }

    function setMinterAccess(address minter, bool enabled) public onlyOwner {
        minters[minter] = enabled;
        emit SetMinter(minter, enabled);
    }

    function mint(address to, uint256 id, uint256 amount) external {
        require(minters[msg.sender], "Not a minter");
        require(exists[id], "ID does not exist");

        _mint(to, id, amount, "");
    }

    /**
     * @dev Internal override function for minting an NFT including totalSupply update
     */
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal override {
        super._mint(to, id, amount, data);

        tokenSupply[id] += amount;
    }

    function batchMint(address to, uint256[] calldata ids, uint256[] calldata amounts) external {
        require(minters[msg.sender], "Not a minter");
        
        for (uint256 i = 0; i < ids.length; i++) {
            require(exists[ids[i]], "ID does not exist");
        }

        _batchMint(to, ids, amounts, "");
    }

    /**
     * @dev Internal override function for batch minting an NFT including totalSupply update
     */
    function _batchMint(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override {
        super._batchMint(to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            tokenSupply[ids[i]] += amounts[i];
        }
    }

     function burn(uint256 id, uint256 amount) external {
        require(exists[id], "ID does not exist");
        require(balanceOf[msg.sender][id] >= amount, "burn amount exceeds balance");

        _burn(msg.sender, id, amount);
    }

    /**
     * @dev Internal override function for minting an NFT including totalSupply update
     */
    function _burn(address from, uint256 id, uint256 amount) internal override {
        super._burn(from, id, amount);

        tokenSupply[id] -= amount;
    }

    function batchBurn(uint256[] calldata ids, uint256[] calldata amounts) external {
        
        for (uint256 i = 0; i < ids.length; i++) {
            require(exists[ids[i]], "ID does not exist");
            require(balanceOf[msg.sender][ids[i]] >= amounts[i], "burn amount exceeds balance");
        }

        _batchBurn(msg.sender, ids, amounts);
    }

    /**
     * @dev Internal override function for batch minting an NFT including totalSupply update
     */
    function _batchBurn(address from, uint256[] memory ids, uint256[] memory amounts) internal override {
        super._batchBurn(from, ids, amounts);

        for (uint256 i = 0; i < ids.length; i++) {
            tokenSupply[ids[i]] -= amounts[i];
        }
    }       

    /**
     * @dev Adds new collection IDs with their corresponding URI
     */
    function add(uint256[] calldata ids, string[] calldata uris) external onlyOwner {
        require(ids.length == uris.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 newId = ids[i];
            require(!exists[newId], "ID already exists");
            exists[newId] = true;
            _uri[newId] = uris[i];
            emit Add(newId);
        }
    }

    function stopMinting(uint256[] calldata ids) external onlyOwner {

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            require(exists[id], "ID does not exist");
            unmintable[id] = true;
            emit MintingStopped(id);
        }
    }

    function _setUri(uint256 id, string memory newUri) internal virtual {
        _uri[id] = newUri;
    }

    /**
     * @dev Function to set the URI for all NFT IDs
     */
    function setUri(uint256 id, string calldata newUri) external onlyOwner {
        require(!uriFrozen[id], 'This URI is frozen!');
        require(exists[id], "ID does not exist");
        _setUri(id, newUri);

        emit updateUri(newUri, id);
    }

    /**
     * @dev Returns the URI of a token given its ID
     * @param id ID of the token to query
     * @return uri of the token or an empty string if it does not exist
     */
    function uri(uint256 id) public view override returns (string memory) {
        require(exists[id], "URI query for nonexistent token");

        return _uri[id];
    }

    /**
     * @dev Freezes the metadata for a collection
     * @param id ID of the token collection
     */
    function freezeUri(uint256 id) public onlyOwner {
        require(exists[id]);

        uriFrozen[id] = true;

        emit PermanentURI(_uri[id], id);
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param id ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 id) external view returns (uint256) {
        return tokenSupply[id];
    }


}