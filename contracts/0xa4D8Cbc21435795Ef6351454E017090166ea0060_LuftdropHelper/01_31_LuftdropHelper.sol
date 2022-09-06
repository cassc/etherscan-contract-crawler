// SPDX-License-Identifier: MIT
// ERC721AirdropTarget Contracts v4.0.0
// Creator: Chance Santana-Wees

pragma solidity ^0.8.11;

import './IERC721AirdropTarget.sol';
import './ERC20Spendable.sol';
import './Luftballons.sol';
import './strings.sol';
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface ILuftballons {
    function setCustomNFTPrice(address collection, uint256 tokenPrice) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC1155MetadataURI is IERC1155 {
    function uri(uint256 id) external view returns (string memory);
}

contract LuftdropHelper is IERC1155, Ownable, IERC1155Receiver, IERC721Receiver {
    using strings for *;
    address immutable public luft_ballons;
    uint256 immutable public burn_cost;

    mapping(uint256 => address) public base_collection;
    mapping(uint256 => uint256) public wrapped_token;
    mapping(uint256 => uint256) public wrapped_quantity;
    mapping(address => mapping(uint256 => uint256)) public token_to_wrapper;

    uint256 public total_quantity;
    uint256 currentTokenID = 1;

    event token_wrapped_721(address collection, uint256 tokenID);
    event token_wrapped_1155(address collection, uint256 tokenID, uint256 quantity);

    constructor(address luftballons, uint256 burn) {
        luft_ballons = luftballons;
        burn_cost = burn;
        //transferOwnership(address(this));
        //ILuftballons(luft_ballons).setCustomNFTPrice(address(this), burn_cost);
    }

    /*function owner() public view override returns (address) {
        return address(this);
    }*/

    function onERC721Received(address, address, uint256 tokenId, bytes calldata) public returns (bytes4) {
        require(IERC165(msg.sender).supportsInterface(type(IERC721).interfaceId), "Sender not valid ERC721 Collection");
        wrapToken(msg.sender, tokenId, 1);
        emit token_wrapped_721(msg.sender, tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256 tokenId, uint256 quantity, bytes calldata) public returns (bytes4) {
        require(IERC165(msg.sender).supportsInterface(type(IERC1155).interfaceId), "Sender not valid ERC1155 Collection");
        wrapToken(msg.sender, tokenId, quantity);
        emit token_wrapped_1155(msg.sender, tokenId, quantity);
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) public pure returns (bytes4) {
        require(false, "Not Supported");
        return bytes4(0);
    }

    function noticeERC721(address collection, uint256 tokenID) external {
        uint256 wrapper = token_to_wrapper[collection][tokenID];
        require(wrapper == 0 || wrapped_quantity[wrapper] == 0, "Already Wrapped");
        require(IERC721(collection).ownerOf(tokenID) == address(this), "Not Mine");

        wrapToken(collection, tokenID, 1);
        emit token_wrapped_721(collection, tokenID);
    }

    function noticeERC1155(address collection, uint256 tokenID) external {
        uint256 wrapper = token_to_wrapper[collection][tokenID];
        uint256 hidden_balance = IERC1155(collection).balanceOf(address(this), tokenID) - wrapped_quantity[wrapper];
        require(wrapper == 0 || hidden_balance > 0, "Nothing to Wrap");
        
        wrapToken(collection, tokenID, hidden_balance);
        emit token_wrapped_1155(collection, tokenID, hidden_balance);
    }

    function wrapToken(address collection, uint256 tokenID, uint256 quantity) internal returns (uint256 wrapper_id) {
        if(token_to_wrapper[collection][tokenID] == 0) {
            wrapper_id = currentTokenID;
            currentTokenID++;

            token_to_wrapper[collection][tokenID] = wrapper_id;
            base_collection[wrapper_id] = collection;
            wrapped_token[wrapper_id] = tokenID;
        } else {
            wrapper_id = token_to_wrapper[collection][tokenID];
        }

        emit TransferSingle(address(this), address(collection), luft_ballons, wrapper_id, quantity);
        emit URI(uri(wrapper_id), wrapper_id);
        IERC1155Receiver(luft_ballons).onERC1155Received(collection, collection, wrapper_id, quantity, "");
        wrapped_quantity[wrapper_id] += quantity;
        total_quantity+=quantity;
    }

    function balanceOf(address owner, uint256 wrapper_id) public view returns (uint256 balance) {
        if(owner == luft_ballons) return wrapped_quantity[wrapper_id];
        return 0;
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] memory tokens) external view returns (uint256[] memory balance) {
        for(uint i = 0; i < accounts.length; i++) {
            tokens[i] = balanceOf(accounts[i], tokens[i]);
        }
        return tokens;
    }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        if(wrapped_quantity[tokenId] == 0) return address(0);
        return luft_ballons;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity,
        bytes calldata
    ) external {
        safeTransferFrom(from,to,tokenId,quantity);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) public {
        transferFrom(from,to,tokenId,quantity);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) public {
        require(msg.sender == luft_ballons && from == luft_ballons && wrapped_quantity[tokenId] > 0);
        unwrap(to, tokenId, quantity);
    }

    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes calldata
    ) external pure {
        require(false, "Not Supported");
    }

    function unwrap(address recipient, uint256 wrapper_id, uint256 quantity) internal {
        if(IERC165(base_collection[wrapper_id]).supportsInterface(type(IERC1155).interfaceId)) {
            IERC1155(base_collection[wrapper_id]).safeTransferFrom(address(this), recipient, wrapped_token[wrapper_id], quantity, "");
        } else {
            IERC721(base_collection[wrapper_id]).safeTransferFrom(address(this), recipient, wrapped_token[wrapper_id], "");
        }

        wrapped_quantity[wrapper_id]--;
        total_quantity--;

        emit TransferSingle(address(this), luft_ballons, address(0), wrapper_id, quantity);
    }

    function approve(address to, uint256 tokenId) external {}

    function setApprovalForAll(address operator, bool _approved) external {}

    function getApproved(uint256 tokenId) external view returns (address operator) {}

    function isApprovedForAll(address owner, address operator) external view returns (bool) {}

    function name() public view returns (string memory) {
        return string.concat("LuftWrapped NFTs - ", Strings.toString(burn_cost/10**18), " $LUFT");
    }

    function symbol() public view returns (string memory) {
        return string.concat("LFTWRP_",Strings.toString(burn_cost/10**18));
    }

    function uri(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        address collection = base_collection[tokenId];
        require(collection != address(0));
        uint256 wrappedTokenID = wrapped_token[tokenId];
        
        if(IERC165(collection).supportsInterface(type(IERC1155).interfaceId)) {
            strings.slice memory metadata = IERC1155MetadataURI(collection).uri(wrappedTokenID).toSlice();
            strings.slice memory id_mark = "{id}".toSlice();
            if(metadata.contains(id_mark)) {
                strings.slice memory pre = metadata.split(id_mark);
                return string.concat(pre.toString(),toPaddedHexID(wrappedTokenID),metadata.toString());
            }
            return metadata.toString();
        } else {
            return IERC721Metadata(collection).tokenURI(wrappedTokenID);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == type(IERC1155).interfaceId || // ERC165 interface ID for ERC721.
            interfaceId == type(IERC1155MetadataURI).interfaceId || // ERC165 interface ID for ERC721Metadata.
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId;
    }

    function forwardAirdroppedTokens(IToken token_) external {
        uint256 balance = token_.balanceOf(address(this));
        require(balance > 0, "No Tokens Detected");
        require(token_.transfer(luft_ballons, balance), "Failed Transfer");
        IERC721AirdropTarget(luft_ballons).noticeAirdrop(address(token_));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation left padded with 0s to 64 bit length without 0x prefix 
     */
    function toPaddedHexID(uint256 value) internal pure returns (string memory) {
        strings.slice memory baseString = Strings.toHexString(value).toSlice();
        baseString = baseString.beyond("0x".toSlice());
        string memory zeros = string(new bytes(128 - baseString.len()*2));
        return string.concat(zeros, baseString.toString());
    }
}

interface IToken {
    function transfer(address spender, uint256 amount) external returns (bool);
    function balanceOf(address spender) external returns (uint256);
}