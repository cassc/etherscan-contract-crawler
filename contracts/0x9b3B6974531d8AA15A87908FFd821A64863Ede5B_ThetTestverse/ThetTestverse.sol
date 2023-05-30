/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

/*

    
       ▄▄▄▄▀ ▄  █ ▄███▄          ▄▄▄▄▀ █▄▄▄▄ ▄█     ▄   ▄███▄   █▄▄▄▄   ▄▄▄▄▄   ▄███▄   
    ▀▀▀ █   █   █ █▀   ▀      ▀▀▀ █    █  ▄▀ ██      █  █▀   ▀  █  ▄▀  █     ▀▄ █▀   ▀  
        █   ██▀▀█ ██▄▄            █    █▀▀▌  ██ █     █ ██▄▄    █▀▀▌ ▄  ▀▀▀▀▄   ██▄▄    
       █    █   █ █▄   ▄▀        █     █  █  ▐█  █    █ █▄   ▄▀ █  █  ▀▄▄▄▄▀    █▄   ▄▀ 
      ▀        █  ▀███▀         ▀        █    ▐   █  █  ▀███▀     █             ▀███▀   
              ▀                         ▀          █▐            ▀                      
                                                   ▐                                    

*/


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library MerkleProof {

    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}


abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
  
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}


library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Address {
  
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


interface IERC721 is IERC165 {
   
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Enumerable is IERC721 {
  
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Metadata is IERC721 {
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
   
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
      
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

error lengthMismatch();
error Paused();
error PublicMintStopped();
error FreeMintNftSold();
error AllSold();
error PrivateMintStopped();
error WrongProof();
error InvalidPrice();
error MaxWLMintExceeded();
error FreeMintStopped();
error MaxMinted();
error MaxLimitExceeded();

contract ThetTestverse is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {

    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter internal supply;

    uint32 public MAXIMUM_SUPPLY = 3897; //3897;   //3600 public & private  -- 297 free mint
    uint32 FREEMINT = 297; //297;
    uint32 PPMINT = 3600; //3600;

    uint256 public Max_Public_Limit = 5;

    bytes32 merkleRoot_oneNft;
    bytes32 merkleRoot_twoNft;
    bytes32 merkleRoot_threeNft;
    bytes32 merkleRoot_FreeNft;
    bytes32 merkleRoot_FreeLimit;

    //Price will be 0.05 Eth for all in start 
    uint128 public PUBLIC_MINT_COST = 0.049 ether; 
    uint128 public ONE_MINT_COST = 0.039 ether;
    uint128 public TWO_MINT_COST = 0.039 ether;
    uint128 public THREE_MINT_COST = 0.039 ether;

    mapping (address => uint32) public WL_DB;

    uint8 public paused = 2;
    uint8 public privateMintpauser = 2;
    uint8 public freeMintpauser = 2;
    uint8 public publicMintpauser = 2;

    bool public isRevealed = false;

    string public baseURI;
    string public notRevealedUri = 'ipfs://QmbbDZrimBs5q2xafEvNPmFUKVBPxfTsaXueSrGSK6gYMY/';

    uint16 public counterFeeMint;
    uint16 public counterPPMint;

    string uriPrefix = "";
    string public uriSuffix = ".json";

    uint96 royalityFeeInBips;
    string contractUri = 'https://gateway.pinata.cloud/ipfs/QmVtE213rJGXx4pQa8Ay1rUabpDNnTes3F23V65KXrYvBs/';
    address RoyalityReciever;

    constructor() ERC721("The Triverse", "TRV") {
        royalityFeeInBips = 630;
        RoyalityReciever = 0x0E75B9BC6018CEd3F04986E80D3689797E39EF8F;
    }

    function publicMint(uint _amount) public payable nonReentrant() {
        
        pauser();   
        MaxLimit(_amount);
        PublicMintChecker();
        maxlimitchecker(_amount);

        if(counterPPMint + _amount > PPMINT) {
            revert AllSold();
        }
        
        uint256 value = msg.value;
        uint256 subtotal = PUBLIC_MINT_COST * _amount;

        if(value != subtotal) {
            revert InvalidPrice();
        }
        
        for(uint i = 0; i < _amount; i++) {
            supply.increment();
            _safeMint(msg.sender, supply.current());
            counterPPMint++;
        }
    }

    function privateMint(bytes32[] calldata _merkleProof) public payable nonReentrant() {
        
        pauser();   
        PrivateMintChecker();
        maxlimitchecker(1);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        
        if(counterPPMint + 1 > PPMINT) {
            revert AllSold();
        }

        uint256 value = msg.value;
        
        if(MerkleProof.verify(_merkleProof, merkleRoot_oneNft, leaf)) {   //1
            if(value != ONE_MINT_COST) {
                revert InvalidPrice();
            }
            if(WL_DB[msg.sender] == 1) {
                revert MaxWLMintExceeded();
            }
            supply.increment();
            _safeMint(msg.sender, supply.current());
            WL_DB[msg.sender]++;  
            counterPPMint++;
        }
        else if(MerkleProof.verify(_merkleProof, merkleRoot_twoNft, leaf)) {  //2
            if(value != TWO_MINT_COST) {
                revert InvalidPrice();
            }
            if(WL_DB[msg.sender] == 2) {
                revert MaxWLMintExceeded();
            }
            supply.increment();
            _safeMint(msg.sender, supply.current());
            WL_DB[msg.sender]++;
            counterPPMint++;
        }
        else if(MerkleProof.verify(_merkleProof, merkleRoot_threeNft, leaf)) { //3
            if(value != THREE_MINT_COST) {
                revert InvalidPrice();
            }
            if(WL_DB[msg.sender] == 3) {
                revert MaxWLMintExceeded();
            }
            supply.increment();
            _safeMint(msg.sender, supply.current());
            WL_DB[msg.sender]++;
            counterPPMint++;
        }
        else {
            revert WrongProof();
        }
        
    }

    //ask mint user total

    function freeMint(bytes32[] calldata _merkleProof) public nonReentrant() {
        
        pauser();   
        FreeMintChecker();
        maxlimitchecker(1);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if(counterFeeMint + 1 > FREEMINT){
            revert FreeMintNftSold();
        }
        
        
        if(MerkleProof.verify(_merkleProof, merkleRoot_FreeNft, leaf)) {  //4
            if(WL_DB[msg.sender] == 1) {
                revert MaxWLMintExceeded();
            }
            supply.increment();
            _safeMint(msg.sender, supply.current());
            WL_DB[msg.sender]++;
            counterFeeMint++;
        }
        else if (MerkleProof.verify(_merkleProof, merkleRoot_FreeLimit, leaf)) {
            supply.increment();
            _safeMint(msg.sender, supply.current());
            counterFeeMint++;
        }
        else {
            revert WrongProof();
        }
        
    }

    function gift(address addresses) public onlyOwner {
        maxlimitchecker(1);
        supply.increment();
        _safeMint(addresses, supply.current());
    }

    //ERROR HANDLING

    function FreeMintChecker() internal view {
        if(freeMintpauser == 1) {
            revert FreeMintStopped(); 
        }
    }

    function PrivateMintChecker() internal view {
        if(privateMintpauser == 1) {
            revert PrivateMintStopped(); 
        }
    }

    function maxlimitchecker(uint256 _amount) internal view {
        if(totalSupply() + _amount > MAXIMUM_SUPPLY) {
            revert MaxMinted();
        }
    }

    function pauser() internal view {
        if(paused == 1) {
            revert Paused();
        }
    }

    function PublicMintChecker() internal view {
        if(publicMintpauser == 1) {
            revert PublicMintStopped();
        }
    }

    function MaxLimit(uint256 _amount) internal view {
        if(_amount > Max_Public_Limit) {
            revert MaxLimitExceeded();
        }
    }

    //Setters

    function setPauser(uint8 _val) public onlyOwner {
        paused = _val;    //1 -> true , 2 -> false
    }

    function enablePrivateMint(uint8 _val) public onlyOwner {
        privateMintpauser = _val;    //1 -> true , 2 -> false
    }

    function enableFreeMint(uint8 _val) public onlyOwner {
        freeMintpauser = _val;    //1 -> true , 2 -> false
    }    

    function enablePublicMint(uint8 _val) public onlyOwner {
        publicMintpauser = _val;
    }

    function setPublicCost(uint128 _value) public onlyOwner {
        PUBLIC_MINT_COST = _value;
    }

    function changePublicLimit(uint256 _val) public onlyOwner {
        Max_Public_Limit = _val;
    }

    function setOneMintCost(uint128 _value) public onlyOwner {
        ONE_MINT_COST = _value;
    }

    function setTwoMintCost(uint128 _value) public onlyOwner {
        TWO_MINT_COST = _value;
    }
    
    function setThreeMintCost(uint128 _value) public onlyOwner {
        THREE_MINT_COST = _value;
    }

    function hasWhitelist(bytes32[] calldata _merkleProof,address account) public view returns (bool , uint) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        if(MerkleProof.verify(_merkleProof, merkleRoot_oneNft, leaf)) {
            return (true,1);
        }
        else if(MerkleProof.verify(_merkleProof, merkleRoot_twoNft, leaf)) {
            return (true,2);
        }
        else if(MerkleProof.verify(_merkleProof, merkleRoot_threeNft, leaf)) {
            return (true,3);
        }
        else if(MerkleProof.verify(_merkleProof, merkleRoot_FreeNft, leaf)) {
            return (true,4);
        }
        else if (MerkleProof.verify(_merkleProof, merkleRoot_FreeLimit, leaf)) {
            return (true,5);
        }        
        else {
            return (false,0);
        }
    }
    

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAXIMUM_SUPPLY) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function setRoots(bytes32[] calldata _roots) public {
        if(_roots.length < 4) revert lengthMismatch();
        merkleRoot_oneNft = _roots[0];
        merkleRoot_twoNft = _roots[1];
        merkleRoot_threeNft = _roots[2];
        merkleRoot_FreeNft = _roots[3];
        merkleRoot_FreeLimit = _roots[4];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        if (isRevealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), uriSuffix)) : "";
    }

    function reveal() public onlyOwner {
        isRevealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        uriPrefix = _newBaseURI;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        if(_tokenId>=0){}
        return (RoyalityReciever , calculateRoyality(_salePrice));
    }

    function calculateRoyality(uint256 _salePrice) internal view returns (uint256){
        return (_salePrice / 10000) * royalityFeeInBips; 
    }

    function setRoyalityInfo(address _Reciever, uint96 _royalityFeeInBips) public onlyOwner {
        royalityFeeInBips = _royalityFeeInBips;
        RoyalityReciever = _Reciever;
    }

    function setContractUri(string calldata _contrctURI) public onlyOwner {
        contractUri = _contrctURI;
    } 

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public 
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    } 

    receive() external payable {}

}