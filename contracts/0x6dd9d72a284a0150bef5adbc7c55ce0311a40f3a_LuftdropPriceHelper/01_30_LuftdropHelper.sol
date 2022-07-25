// SPDX-License-Identifier: MIT
// ERC721AirdropTarget Contracts v4.0.0
// Creator: Chance Santana-Wees

pragma solidity ^0.8.11;

import './IERC721AirdropTarget.sol';
import './ERC20Spendable.sol';
import './Luftballons.sol';
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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

contract ERC721Wrapper is IERC721, Ownable {
    address immutable public luft_ballons;
    IERC721 immutable public base_collection;
    uint256 immutable public wrapped_token;
    LuftdropPriceHelper immutable public wrapper_vault;

    constructor(address luftballons, IERC721 collection, uint256 tokenID) {
        luft_ballons = luftballons;
        base_collection = collection;
        wrapped_token = tokenID;
        wrapper_vault = LuftdropPriceHelper(msg.sender);


        IERC721Receiver(luft_ballons).onERC721Received(msg.sender, address(0), tokenID, "");
        emit Transfer(address(0), luft_ballons, tokenID);
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        if(owner == luft_ballons) return 1;
        return 0;
    }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        require(tokenId == wrapped_token, "Not the Wrapped Token");
        return luft_ballons;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata
    ) external {
        safeTransferFrom(from,to,tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        transferFrom(from,to,tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(msg.sender == luft_ballons && from == luft_ballons && tokenId == wrapped_token);
        unwrap(to);
    }

    function unwrap(address recipient) internal {
        wrapper_vault.unwrap(recipient);
        emit Transfer(luft_ballons, address(0), wrapped_token);
        selfdestruct(payable(recipient));
    }

    function approve(address to, uint256 tokenId) external {}

    function setApprovalForAll(address operator, bool _approved) external {}

    function getApproved(uint256 tokenId) external view returns (address operator) {}

    function isApprovedForAll(address owner, address operator) external view returns (bool) {}

    function name() public view returns (string memory) {
        return string.concat("LuftWrapped ", IERC721Metadata(address(base_collection)).name());
    }

    function symbol() public view returns (string memory) {
        return string.concat("LUFT", IERC721Metadata(address(base_collection)).symbol());
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(tokenId == wrapped_token);
        return IERC721Metadata(address(base_collection)).tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f;   // ERC165 interface ID for ERC721Metadata.
    }
}

contract ERC1155Wrapper is IERC1155, Ownable {
    address immutable public luft_ballons;
    IERC1155 immutable public base_collection;
    uint256 immutable public wrapped_token;
    LuftdropPriceHelper immutable public wrapper_vault;

    uint256 balance;

    constructor(address luftballons, IERC1155 collection, uint256 tokenID, uint quantity) {
        luft_ballons = luftballons;
        base_collection = collection;
        wrapped_token = tokenID;
        wrapper_vault = LuftdropPriceHelper(msg.sender);
        balance = quantity;

        IERC1155Receiver(luft_ballons).onERC1155Received(msg.sender, address(0), tokenID, quantity, "");
        emit TransferSingle(address(this), address(0), luft_ballons, tokenID, quantity);
    }

    function balanceOf(address owner, uint256 id) external view returns (uint256) {
        if(owner == luft_ballons && id == wrapped_token) return balance;
        return 0;
    }

    function balanceOfBatch(address[] calldata, uint256[] calldata)
        external
        pure
        returns (uint256[] memory) {
            require(false, "NA");
            return new uint256[](0);
        }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        require(tokenId == wrapped_token, "Not the Wrapped Token");
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
        require(msg.sender == luft_ballons && from == luft_ballons && tokenId == wrapped_token && balance == quantity);
        unwrap(to, quantity);
        emit TransferSingle(address(this), luft_ballons, address(0), tokenId, quantity);
    }

    function safeBatchTransferFrom(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure {
        require(false,"NA");
    }

    function unwrap(address recipient, uint256 quantity) internal {
        balance -= quantity;
        wrapper_vault.unwrap1155(recipient, quantity);
        if(balance == 0) selfdestruct(payable(recipient));
    }

    function approve(address to, uint256 tokenId) external {}

    function setApprovalForAll(address operator, bool _approved) external {}

    function getApproved(uint256 tokenId) external view returns (address operator) {}

    function isApprovedForAll(address owner, address operator) external view returns (bool) {}

    function name() public view returns (string memory) {
        return string.concat("LuftWrapped ", IERC721Metadata(address(base_collection)).name());
    }

    function symbol() public view returns (string memory) {
        return string.concat("LUFT", IERC721Metadata(address(base_collection)).symbol());
    }

    function uri(uint256 tokenId) public view returns (string memory) {
        require(tokenId == wrapped_token);
        return IERC1155MetadataURI(address(base_collection)).uri(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == type(IERC1155).interfaceId || 
            interfaceId == type(IERC1155MetadataURI).interfaceId;
    }
}

contract LuftdropPriceHelper is Ownable, ERC165, IERC1155Receiver, IERC721Receiver {
    address immutable public luft_ballons;
    mapping(address => bool) wrappedERC721s;
    mapping(address => uint) wrappedERC1155s;
    mapping(address => mapping(uint => address)) tokenToWrapper;

    event token_wrapped(address wrapper, address collection, uint256 tokenID, uint256 burnCost, address from);
    event token_wrapped_1155(address wrapper, address collection, uint256 tokenID, uint256 quantity, uint256 burnCost, address from);

    uint256 public burn_cost;

    constructor(address luftballons, uint256 burn) {
        burn_cost = burn * 10**18;
        luft_ballons = luftballons;
    }

    function sliceUint(bytes memory bs, uint start)
        internal pure
        returns (uint)
    {
        require(bs.length >= start + 2, "slicing out of range");
        uint x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }
        return x;
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) public returns (bytes4) {
        createWrapperCollection(msg.sender, tokenId, burn_cost, from);
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(address, address from, uint256 tokenId, uint256 quantity, bytes calldata) public returns (bytes4) {
        createWrapperCollection1155(msg.sender, tokenId, quantity, burn_cost, from);
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) public pure returns (bytes4) {
        require(false, "Not Supported");
        return bytes4(0);
    }

    function createWrapperCollection(address collection, uint256 tokenID, uint256 burnCost, address from) internal {
        require(tokenToWrapper[collection][tokenID] == address(0), "Already Wrapped");
        ERC721Wrapper wrapper = new ERC721Wrapper(luft_ballons, IERC721(collection), tokenID);
        ILuftballons(luft_ballons).setCustomNFTPrice(address(wrapper), burnCost);
        wrapper.transferOwnership(from);
        wrappedERC721s[address(wrapper)] = true;
        tokenToWrapper[collection][tokenID] = address(wrapper);
        emit token_wrapped(address(wrapper), collection, tokenID, burnCost, from);
    }

    function createWrapperCollection1155(address collection, uint256 tokenID, uint256 quantity, uint256 burnCost, address from) internal {
        require(tokenToWrapper[collection][tokenID] == address(0), "Already Wrapped");
        ERC1155Wrapper wrapper = new ERC1155Wrapper(luft_ballons, IERC1155(collection), tokenID, quantity);
        ILuftballons(luft_ballons).setCustomNFTPrice(address(wrapper), burnCost);
        wrapper.transferOwnership(from);
        wrappedERC1155s[address(wrapper)] = quantity;
        tokenToWrapper[collection][tokenID] = address(wrapper);
        emit token_wrapped_1155(address(wrapper), collection, tokenID, quantity, burnCost, from);
    }

    function noticeERC721(address collection, uint256 tokenID) external {
        require(tokenToWrapper[collection][tokenID] == address(0), "Already Wrapped");
        require(IERC721(collection).ownerOf(tokenID) == address(this), "Not Mine");
        createWrapperCollection(collection, tokenID, burn_cost, msg.sender);
    }

    function noticeERC1155(address collection, uint256 tokenID) external {
        require(tokenToWrapper[collection][tokenID] == address(0), "Already Wrapped");
        uint256 balance = IERC1155(collection).balanceOf(address(this), tokenID);
        require(balance > 0, "Not Mine");
        createWrapperCollection1155(collection, tokenID, balance, burn_cost, msg.sender);
    }

    function unwrap(address recipient) external {
        require(wrappedERC721s[msg.sender], "Not a Wrapped Token");
        ERC721Wrapper wrapper = ERC721Wrapper(msg.sender);
        wrapper.base_collection().safeTransferFrom(address(this), recipient, wrapper.wrapped_token());
        tokenToWrapper[address(wrapper.base_collection())][wrapper.wrapped_token()] = address(0);
        wrappedERC721s[msg.sender] = false;
    }

    function unwrap1155(address recipient, uint256 quantity) external {
        require(wrappedERC1155s[msg.sender] > 0, "Not a Wrapped Token");
        ERC1155Wrapper wrapper = ERC1155Wrapper(msg.sender);
        wrapper.base_collection().safeTransferFrom(address(this), recipient, wrapper.wrapped_token(), quantity, "");
        wrappedERC1155s[msg.sender] -= quantity;
        if(wrappedERC1155s[msg.sender] == 0) tokenToWrapper[address(wrapper.base_collection())][wrapper.wrapped_token()] = address(0);
    }

    function rescueLockedTokens(IToken token_) external onlyOwner {
        token_.approve(owner(), type(uint256).max);
    }
}

interface IToken {
    function approve(address spender, uint256 amount) external returns (bool);
}