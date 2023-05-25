// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./extensions/NFTPledge.sol";
import "./utils/IAtticNFT.sol";

contract AtticNFT is IAtticNFT, ERC721A, AccessControlEnumerable, EIP712, ERC2981 {
    using MerkleProof for bytes32[];

    // The contract can be Mint 2500 at most.
    uint256 public constant _mintMax = 25000;

    //Administrator Identity Group
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    //Mint Signature Identity Group
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    //ipns hash
    bytes32 public _novelRouter = 0xd89c027daba96b047d79a3d98264532c4ebaae08cbe9a2650961b587e14fc425;
    //baseURI
    string private _baseTokenURI;

    //Total FreeMint
    uint256 public _totalFreeMint;

    //The maximum number of Mint allowed at this stage
    uint256 public _tokenIdLimit = 2500;

    //Mint price
    uint256 public _mintPrice = 0.02 ether;

    //Mint quantity for single long
    uint256 public _mintLimit = 30;

    //Purchase switch
    bool public _purchase = false;

    //freeMintAllowList
    bytes32 public freeMintMerkleRoot;
    bytes32 public freeMintAllowList;

    //publicMintAllowList
    bytes32 public publicMintMerkleRoot;
    bytes32 public publicMintAllowList;

    //Pledge the contract to obtain points
    NFTPledge public pledge;

    //Prohibit the target address of Approve
    mapping(address => bool) _approveBlacklist;

    constructor(
        address _devAddress,
        address _signAddress,
        address royltyAddress
    ) ERC721A("AtticNFT", "Attic") EIP712("AtticNFT", "1") {
        _baseTokenURI = "https://api.atticnovelnft.io/token/";
        _setupRole(DEFAULT_ADMIN_ROLE, _devAddress);
        _setupRole(MINTER_ROLE, _devAddress);
        _setupRole(ADMIN_ROLE, _devAddress);

        _grantRole(MINTER_ROLE, _signAddress);

        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        _setDefaultRoyalty(royltyAddress, 500);

        pledge = new NFTPledge();
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(!_approveBlacklist[operator], "Invalid Marketplace");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public payable virtual override {
        require(!_approveBlacklist[to], "Invalid Marketplace");
        super.approve(to, tokenId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _mint(address to, uint256 quantity) internal virtual override {
        require(totalSupply() + quantity <= _tokenIdLimit, "max Mint");
        super._mint(to, quantity);
    }

    function manySafeTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIds
    ) external {
        uint256 length = _tokenIds.length;
        for (uint i = 0; i < length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function adminMint(address to, uint8 quantity) external {
        require(hasRole(ADMIN_ROLE, msg.sender) || hasRole(MINTER_ROLE, msg.sender), "ADMIN_ROLE or MINTER_ROLE");
        _mint(to, quantity);
        _setAux(msg.sender, uint64(_getAux(msg.sender) + quantity));

        emit MekleMint(to, uint64(quantity));
    }

    function getNonces(address[] calldata owners) external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](owners.length);
        for (uint i = 0; i < owners.length; i++) {
            res[i] = _numberMinted(owners[i]);
        }
        return res;
    }

    function mekleMint(
        uint8 quantity,
        uint32 startTime,
        uint32 endTime,
        uint32 nonce,
        bytes32[] calldata proof
    ) external {
        require(nonce == _numberMinted(msg.sender), "nonce update");
        require(proof.verify(freeMintMerkleRoot, keccak256(abi.encodePacked(msg.sender, quantity, startTime, endTime, nonce))), "Allow list validation failed");
        uint64 aux = _getAux(msg.sender);
        require(quantity - aux <= _mintLimit, "max");
        _mint(msg.sender, quantity - aux);
        _setAux(msg.sender, uint64(aux + quantity));
        _totalFreeMint += quantity;

        emit AdminMint(msg.sender, quantity);
    }

    function freeMintPermit(
        uint8 quantity,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signature
    ) external {
        require(_getAux(msg.sender) == nonce, "nonce update");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(keccak256("freeMintPermit(address to,uint256 quantity,uint256 nonce,uint256 deadline)"), msg.sender, quantity, nonce, deadline))
        );

        address signer = ECDSA.recover(digest, signature);

        require(hasRole(MINTER_ROLE, signer), "signature MINTER_ROLE");

        _mint(msg.sender, quantity - _getAux(msg.sender));
        _setAux(msg.sender, uint64(_getAux(msg.sender) + quantity));
        _totalFreeMint += quantity;

        emit FreeMintPermit(msg.sender, quantity);
    }

    function scoreMint(uint8 quantity) external payable {
        require(_purchase && balanceOf(msg.sender) > 0, "only NFT owner and purchase");
        require(msg.value >= (_mintPrice * quantity), "Insufficient Ether sent");
        pledge.subScore(msg.sender, quantity * 10);
        _mint(msg.sender, quantity);

        emit ScoreMint(msg.sender, quantity);
    }

    function publicMint(
        uint8 quantity,
        uint32 startTime,
        uint32 endTime,
        uint32 nonce,
        bytes32[] calldata proof
    ) external payable {
        require(nonce == _numberMinted(msg.sender), "nonce update");
        require(proof.verify(publicMintMerkleRoot, keccak256(abi.encodePacked(msg.sender, quantity, startTime, endTime, nonce))), "Allow list validation failed");
        require(_purchase, "purchase");
        uint256 count = msg.value / _mintPrice;
        require(count <= quantity, "Insufficient Ether sent");
        _mint(msg.sender, count);

        emit PublicMint(msg.sender, uint8(count));
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function numberFreeMinted(address owner) external view returns (uint64) {
        return _getAux(owner);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function numberCanMint(address owner) external view returns (uint256) {
        return _mintLimit - _numberMinted(owner);
    }

    function mintTimestamp(uint256 tokenId) external view returns (uint64) {
        return _ownershipOf(tokenId).startTimestamp;
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), _toString(tokenId), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721A, ERC2981) returns (bool) {
        return AccessControlEnumerable.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function stringToUint(string memory s) internal pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint i = 0; i < b.length; i++) {
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                result = result * 10 + (uint8(b[i]) - 48);
            }
        }
        return result;
    }

    function setFreeMintMerkleRoot(bytes32 _root, bytes32 _list) external onlyRole(ADMIN_ROLE) {
        freeMintMerkleRoot = _root;
        freeMintAllowList = _list;
        emit SetFreeMintMerkleRoot(_root, _list);
    }

    function setPublicMintMerkleRoot(bytes32 _root, bytes32 _list) external onlyRole(ADMIN_ROLE) {
        publicMintMerkleRoot = _root;
        publicMintAllowList = _list;
        emit SetPublicMintMerkleRoot(_root, _list);
    }

    function setMintLimit(uint256 _count) external onlyRole(ADMIN_ROLE) {
        require(_count >= 1, "mix count 1");
        _mintLimit = _count;
    }

    function setMintPrice(uint256 _price) external onlyRole(ADMIN_ROLE) {
        require(_price <= 0.02 ether, "max price 0.02 ether");
        _mintPrice = _price;
    }

    function setBaseUri(string memory _URI) external onlyRole(ADMIN_ROLE) {
        _baseTokenURI = _URI;
    }

    function setTokenIdLimit(uint256 _limit) external onlyRole(ADMIN_ROLE) {
        require(_limit >= totalSupply() && _limit <= _mintMax);
        _tokenIdLimit = _limit;
    }

    function setPurchase(bool _can) external onlyRole(ADMIN_ROLE) {
        require(_purchase != _can);
        _purchase = _can;
    }

    function setBlackList(address[] memory _list, bool _isBlack) external onlyRole(ADMIN_ROLE) {
        uint256 length = _list.length;
        for (uint i = 0; i < length; i++) {
            _approveBlacklist[_list[i]] = _isBlack;
        }
    }

    function SendERC721(
        address addr,
        address to,
        uint256 tokenId
    ) external onlyRole(ADMIN_ROLE) {
        IERC721A token = IERC721A(addr);
        token.transferFrom(address(this), to, tokenId);
    }

    function SendERC20(
        address addr,
        address to,
        uint256 amount
    ) external onlyRole(ADMIN_ROLE) {
        IERC20 token = IERC20(addr);
        if (amount == 0) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(to, amount);
    }

    function SendETH(address payable to, uint256 amount) external onlyRole(ADMIN_ROLE) {
        if (amount == 0) {
            amount = payable(address(this)).balance;
        }
        to.transfer(amount);
    }

    function setRoyaltyReceiver(address receiver, uint96 feeNumerator) external onlyRole(ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setNovelRouter(bytes32 _hash) external onlyRole(ADMIN_ROLE) {
        _novelRouter = _hash;
    }

    receive() external payable {}

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4) {
        emit ERC721Received(msg.sender, _operator, _from, _tokenId, _data);
        return this.onERC721Received.selector;
    }

    /**
     * ERC721AQueryable.
     *
     * ERC721A subclass with convenience query functions.
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) public view returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] calldata tokenIds) external view returns (TokenOwnership[] memory) {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}