// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.4;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import 'erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "./library/AddressString.sol";


contract ArtisantVerseOrigin is OwnableUpgradeable, ERC721AUpgradeable, ERC721AQueryableUpgradeable, ReentrancyGuardUpgradeable {
    struct MintClass {
        uint32 whitelistAt;
        uint32 publicAt;
        uint256 price;
        uint64 nextId;
        uint64 maxId;
        uint64 maxPerAddress;
        string baseURI;
        uint256 classId;
    }
    uint8 public nextClassId;
    mapping(uint256=>MintClass) public classes;
    mapping(uint256=>uint256[]) public tokensByPackedOwner;
    mapping(uint256=>uint256) packedMintedPerAddr;

    function initialize(string memory name_, string memory symbol_)
    initializerERC721A
    initializer
    public
    {
        __ERC721A_init(name_, symbol_);
        __ReentrancyGuard_init();
        __ERC721AQueryable_init();
        __Ownable_init();
        // collectionSize = 20;
        // priceWei = 0.1 ether;
        // _safeMint(address(this), collectionSize);
    }

	function weakRandomInClass(uint8 classId)
    public
    view
    returns (uint8)
    {
		uint b = block.number;
		uint timestamp = block.timestamp;
        uint left = availableInClass(classId).length;
        require(left > 0, "Abnormal call");
		return uint8(uint256(keccak256(abi.encodePacked(blockhash(b), timestamp))) % left);
	}

	function weakRandom(uint256 max)
    public
    view
    returns (uint256)
    {
		uint b = block.number;
		uint timestamp = block.timestamp;
        uint left = balanceOf(address(this));
        if (left > max) {
            left = max;
        }
        require(left > 0, "Abnormal call");
		return uint8(uint256(keccak256(abi.encodePacked(blockhash(b), timestamp))) % left);
	}

    modifier callerIsUser()
    {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function version()
    public 
    pure 
    returns (string memory)
    {
        return "1.2.0";
    }

    function availableInClass(uint8 classId)
    internal
    view
    returns (uint256[] memory)
    {
        return tokensOfInClass(classId, address(this));
    }

    function tokensOfInClass(uint8 classId, address owner)
    public
    view
    returns (uint256[] memory tokenIds)
    {
        tokenIds = tokensByPackedOwner[(uint256(classId) << 20) + uint160(owner)];
    }

    function appendToTokensByPackedOwner(uint256 classId, address owner, uint256 tokenId)
    internal 
    {
        uint256[] storage tokenIds = tokensByPackedOwner[(uint256(classId) << 20) + uint160(owner)];
        tokenIds.push(tokenId);
    }

    function removeFromTokensByPackedOwner(uint256 classId, address owner, uint256 tokenId)
    internal 
    {
        uint256[] storage tokenIds = tokensByPackedOwner[(uint256(classId) << 20) + uint160(owner)];
        uint256 id = 0;
        while (tokenIds.length > id) {
            if(tokenIds[id] == tokenId) {
                if(tokenIds.length > 1) {
                    tokenIds[id] = tokenIds[tokenIds.length - 1];
                }
                tokenIds.pop();
                break;
            }
            id++;
        }
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    )
    override
    internal
    {
        while (quantity > 0) {
            TokenOwnership memory _ownership = _ownershipOf(tokenId);
            uint256 classId = uint256(_ownership.extraData >> 16);
            MintClass memory class = classes[classId];
            require(class.maxId>0, "ERR_CLASS");
            removeFromTokensByPackedOwner(classId, from, tokenId);
            appendToTokensByPackedOwner(classId, to, tokenId);
            tokenId++;
            quantity--;
        }
    }

    function sudoUpdateClassId(
        uint8 classId,
        uint32 whitelistAt,
        uint32 publicAt,
        uint256 price,
        uint64 maxId,
        uint64 maxPerAddress,
        string memory baseURI
    )
    onlyOwner
    public
    {
        MintClass memory class = classes[classId];
        require(class.maxId > 0, "ERR_CLASS");
        require(nextClassId<=255, "ERR_OVERFLOW");
        require(publicAt > 0, "ERR_PUBLIC");
        require(maxId > 0 && maxId < (2**16 - 1), "ERR_MAX_ID");
        require(maxPerAddress < (2**16 - 1), "ERR_MAX_PER_ADDR");
        require(bytes(baseURI).length > 0, "ERR_BASE_URI");
        class.whitelistAt = whitelistAt;
        class.publicAt = publicAt;
        class.price = price;
        class.maxId = maxId;
        class.maxPerAddress = maxPerAddress;
        class.baseURI = baseURI;
        classes[classId] = class;
    }

    function sudoInitClassId(
        uint32 whitelistAt,
        uint32 publicAt,
        uint256 price,
        uint64 maxId,
        uint64 maxPerAddress,
        string memory baseURI
    )
    onlyOwner
    public
    {
        require(nextClassId<255, "ERR_OVERFLOW");
        require(publicAt > 0, "ERR_PUBLIC");
        require(maxId > 0 && maxId < (2**16 - 1), "ERR_MAX_ID");
        require(maxPerAddress < (2**16 - 1), "ERR_MAX_PER_ADDR");
        require(bytes(baseURI).length > 0, "ERR_BASE_URI");
        classes[nextClassId] = MintClass({
            whitelistAt: whitelistAt,
            publicAt: publicAt,
            price: price,
            maxId: maxId,
            nextId: 1,
            maxPerAddress: maxPerAddress,
            classId: nextClassId,
            baseURI: baseURI
        });
        nextClassId+=1;
    }


    function reserve(
        uint8 classId,
        address[] memory to,
        uint256[] memory quantities
    )
    external
    onlyOwner
    {
        MintClass memory class = classes[classId];
        require(class.maxId>0, "ERR_CLASS");

        require(to.length == quantities.length,
                "To length is not equal to quantities");

        for(uint256 idx=0; idx < to.length; idx++) {
            uint256 quantity = quantities[idx];
            address receiver = to[idx];
            require(
                class.nextId + quantity - 1 <= class.maxId,
                "not enough remaining reserved for sale to support desired mint amount"
            );

            require(
                numberMintedOfClass(receiver, uint8(classId)) + quantity <= class.maxPerAddress,
                "can not mint this many"
            );

            for(uint256 idx2 = 0; idx2 < quantity; idx2++) {
                uint256 tokenId = _nextTokenId();
                _safeMint(receiver, 1);
                _setExtraDataAt(tokenId, (uint24(classId) << 16) + uint24(class.nextId++));
            }
            _incrementMintedOfClass(receiver, classId, quantity);
        }
        classes[classId] = class;
    }

    function mint(
        uint256 quantity,
        uint8 classId
    )
    external
    payable
    callerIsUser
    {
        MintClass memory class = classes[classId];
        require(class.maxId>0, "ERR_CLASS");
        uint256 price = uint256(class.price);

        require(
            isSaleOn(price, class.publicAt),
            "public sale has not begun yet"
        );

        require(
            class.nextId + quantity - 1 <= class.maxId,
            "not enough remaining reserved for sale to support desired mint amount"
        );

        require(
            numberMintedOfClass(msg.sender, uint8(classId)) + quantity <= class.maxPerAddress,
            "can not mint this many"
        );

        for(uint256 idx = 0; idx < quantity; idx++) {
            uint256 tokenId = _nextTokenId();
            _safeMint(msg.sender, 1);
            _setExtraDataAt(tokenId, (uint24(classId) << 16) + uint24(class.nextId++));
        }
        _incrementMintedOfClass(msg.sender, classId, quantity);
        refundIfOver(price * quantity);
        classes[classId] = class;
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    )
    external
    pure
    returns (bytes4)
    {
        if(from == address(0x0)) {
            return this.onERC721Received.selector;
        }
    }

    function buyRandom(
        uint256 quantity
    )
     external
     payable
     callerIsUser
     {
         require(balanceOf(address(this)) >= quantity, "reached max supply");
         uint256 totalPrice = 0;
         for(uint256 tbMinted=quantity; tbMinted > 0; tbMinted--) {
             uint256 tokenId = this.tokensOfOwner(address(this), 20)[weakRandom(20)];
             TokenOwnership memory _ownership = _ownershipOf(tokenId);
             uint256 classId = uint256(_ownership.extraData >> 16);
             MintClass memory class = classes[classId];
             totalPrice = totalPrice + class.price;
             ERC721AStorage.layout()._tokenApprovals[tokenId] = msg.sender;
             safeTransferFrom(address(this), msg.sender, tokenId);
         }
         refundIfOver(totalPrice);
     }

    function buyRandom(
        uint256 quantity,
        uint8 classId
    )
     external
     payable
     callerIsUser
     {
        MintClass memory class = classes[classId];
        require(class.maxId>0, "ERR_CLASS");
        uint256 price = uint256(class.price);

        require(
            isSaleOn(price, class.publicAt),
            "public sale has not begun yet"
        );
 
        require(availableInClass(classId).length >= quantity, "reached max supply");
        for(uint256 tbMinted=quantity; tbMinted > 0; tbMinted--) {
            uint256 tokenId = availableInClass(classId)[weakRandomInClass(classId)];
            ERC721AStorage.layout()._tokenApprovals[tokenId] = msg.sender;
            safeTransferFrom(address(this), msg.sender, tokenId);
        }
        refundIfOver(price * quantity);
     }

    function refundIfOver(uint256 price)
    private
    {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function isSaleOn(uint256 _price, uint256 _startTime)
    public
    view
    returns (bool)
    {
        return _price != 0 && _startTime != 0 && block.timestamp >= _startTime;
    }

    function withdrawNFT(uint256 tokenId)
    public
    onlyOwner
    nonReentrant
    {
        require(ownerOf(tokenId) == address(this));
        ERC721AStorage.layout()._tokenApprovals[tokenId] = msg.sender;
        safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function withdraw()
    external
    onlyOwner
    nonReentrant
    {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // URI

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override (ERC721AUpgradeable, IERC721AUpgradeable) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        TokenOwnership memory _ownership = _ownershipOf(tokenId);
        uint256 classId = uint256(_ownership.extraData >> 16);
        MintClass memory class = classes[classId];
        require(class.maxId>0, "ERR_CLASS");
        uint256 fileId = uint256(_ownership.extraData - (uint24(classId << 16)));

        string memory baseURI = class.baseURI;
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(fileId), ".json")) : '';
    }

    // TokenID

    function startTokenId()
    public
    view
    returns (uint256)
    {
        return _startTokenId();
    }

    function _startTokenId()
    internal
    override
    view
    virtual
    returns (uint256)
    {
        return 1;
    }

    // Misc

    function tokensOfOwner(address owner, uint256 first)
    external 
    view 
    returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            if (tokenIdsLength > first) {
                tokenIdsLength = first;
            }
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

    function _incrementFreeMintedOfClass(address owner, uint8 classId, uint256 freeMinted)
    internal
    {
        uint256 new_packed = uint256(numberMintedOfClass(owner, classId)) + 
                             (uint256(numberFreeMintedOfClass(owner, classId) + freeMinted) << 32);
        packedMintedPerAddr[(uint256(classId) << 20) + uint160(owner)] = new_packed;
    }

    function _incrementMintedOfClass(address owner, uint8 classId, uint256 quantity)
    internal
    {
        uint256 new_packed = uint256(numberMintedOfClass(owner, classId) + quantity) + 
                             (uint256(numberFreeMintedOfClass(owner, classId)) << 32);
        packedMintedPerAddr[(uint256(classId) << 20) + uint160(owner)] = new_packed;
    }

    function numberFreeMintedOfClass(address owner, uint8 classId)
    public
    view
    returns (uint32)
    {
        return uint32(packedMintedPerAddr[(uint256(classId) << 20) + uint160(owner)] >> 32);
    }

    function numberMintedOfClass(address owner, uint8 classId)
    public
    view
    returns (uint32)
    {
        uint256 packed = packedMintedPerAddr[(uint256(classId) << 20) + uint160(owner)];
        return uint32(packed - ((packed >> 32) << 32));
    }

    function numberMinted(address owner)
    public
    view
    returns (uint256)
    {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function totalMinted()
    public
    view
    returns (uint256)
    {
        return _totalMinted();
    }
}