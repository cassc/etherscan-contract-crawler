// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./Guardian/Erc721LockRegistryDummy.sol";
import "./OPR/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
// import "./interfaces/IBreedingInfoV2.sol";
// import "./interfaces/IRelic.sol";
import "./interfaces/IERC6551Registry.sol";
import "./interfaces/IERC6551Account.sol";

// import "hardhat/console.sol";

contract Traitz is ERC721xDummy, DefaultOperatorFiltererUpgradeable {
    using ERC165Checker for address;

    string public baseTokenURI;
    string public tokenURISuffix;
    string public tokenURIOverride;

    IERC721 public kubzContract;
    IERC721 public kzgContract;
    address public signerAlt;

    mapping(string => bool) public itemIdMinted;

    IERC6551Registry public erc6551Registry;
    address public erc6551AccountImplementation;

    // useless vvv
    mapping(uint256 => bool) public traitLocked;
    // useless ^^^
    mapping(address => mapping(uint256 => uint256)) public tokenKWRLockedUntil;
    uint256 public transferLockSeconds;
    mapping(address => mapping(address => bool)) isSwapping; // owner => operator => bool

    event TraitItemMint(string itemId, uint256 tokenId);

    uint256 public MINT_PRICE_PER_ITEM; // directly to sender

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function initialize(
        string memory baseURI,
        address signerAltAddress,
        address _kzgContract,
        address _kubzContract,
        address _erc6551AccountImplementation,
        address _erc6551Registry
    ) public initializer {
        ERC721xDummy.__ERC721x_init("Traitz", "Traitz");
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
        baseTokenURI = baseURI;
        setAddresses(signerAltAddress, _kzgContract, _kubzContract);
        setupERC6551(_erc6551AccountImplementation, _erc6551Registry);
    }

    function setupTransferLockSeconds(uint256 secs) external onlyOwner {
        transferLockSeconds = secs;
    }

    function setupERC6551(
        address _erc6551AccountImplementation,
        address _erc6551Registry
    ) public onlyOwner {
        erc6551AccountImplementation = _erc6551AccountImplementation;
        erc6551Registry = IERC6551Registry(_erc6551Registry);
    }

    function setAddresses(
        address signerAltAddress,
        address _kzgContract,
        address _kubzContract
    ) public onlyOwner {
        signerAlt = signerAltAddress;
        kzgContract = IERC721(_kzgContract);
        kubzContract = IERC721(_kubzContract);
    }

    function setMintPricePerItem(uint256 mintPrice) external onlyOwner {
        MINT_PRICE_PER_ITEM = mintPrice;
    }

    function safeMint(address receiver, uint256 quantity) internal {
        _mint(receiver, quantity);
    }

    function airdropListWithAmounts(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; i++) {
            safeMint(receivers[i], amounts[i]);
        }
    }

    function checkValidityAlt(
        bytes calldata signature,
        string memory action
    ) public view returns (bool) {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(msg.sender, action))
                ),
                signature
            ) == signerAlt,
            "invalid signature"
        );
        return true;
    }

    function join(
        string[] calldata strs
    ) internal pure returns (string memory) {
        string memory buffer = "";
        for (uint256 i = 0; i < strs.length; ) {
            buffer = string.concat(buffer, strs[i], ",");
            unchecked {
                i++;
            }
        }
        return buffer;
    }

    function isApprovedForAll(
        address owner,
        address operator
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (bool)
    {
        if (isSwapping[owner][operator]) return true;
        return super.isApprovedForAll(owner, operator);
    }

    function equipUnequipKWRs(
        uint256[] calldata outKWRIds,
        uint256[] calldata inKWRIds,
        uint256 collection, // 1 = kzg, 2 = kubz
        uint256 collectionTokenId
    ) external {
        IERC721 collectionContract = collection == 1
            ? kzgContract
            : kubzContract;
        require(
            collectionContract.ownerOf(collectionTokenId) == msg.sender,
            "Not owner of collection token"
        );
        address tba = erc6551Registry.account(
            erc6551AccountImplementation,
            block.chainid,
            address(collectionContract),
            collectionTokenId,
            0
        );

        if (outKWRIds.length > 0) {
            tokenKWRLockedUntil[address(collectionContract)][
                collectionTokenId
            ] = block.timestamp + transferLockSeconds;

            isSwapping[tba][msg.sender] = true;
            for (uint256 i = 0; i < outKWRIds.length; ) {
                uint256 outKWRId = outKWRIds[i];
                require(ownerOf(outKWRId) == tba, "outKWR not owned by TBA");
                super.transferFrom(tba, msg.sender, outKWRId);
                unchecked {
                    i++;
                }
            }
            isSwapping[tba][msg.sender] = false;
        }

        for (uint256 i = 0; i < inKWRIds.length; ) {
            uint256 inKWRId = inKWRIds[i];
            super.transferFrom(msg.sender, tba, inKWRId);
            unchecked {
                i++;
            }
        }
    }

    function mintMultiMulti(
        string[][] calldata itemIdsArray,
        uint256[] calldata collectionArray, // 1 = kzg, 2 = kubz
        uint256[] calldata collectionTokenIdArray,
        bytes[] calldata signatureArray
    ) external {
        for (uint256 i = 0; i < itemIdsArray.length; ) {
            mintMulti(
                itemIdsArray[i],
                collectionArray[i],
                collectionTokenIdArray[i],
                signatureArray[i]
            );
            unchecked {
                i++;
            }
        }
    }

    function withdrawSales() public onlyOwner {
        uint256 balance = address(this).balance;
        _withdraw(owner(), balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "cant withdraw");
    }

    function mintToSenderMulti(
        string[] calldata itemIds,
        bytes calldata signature
    ) external payable {
        require(
            MINT_PRICE_PER_ITEM * itemIds.length == msg.value,
            "msg.value does not match MINT_PRICE_PER_ITEM * itemIds.length"
        );

        string memory action = string.concat(
            "kwr-mint-sender-multi/",
            join(itemIds)
        );
        // console.log("contract");
        // console.log(action);
        checkValidityAlt(signature, action);

        uint256 nti = _nextTokenId();
        safeMint(msg.sender, itemIds.length);
        for (uint256 i = 0; i < itemIds.length; ) {
            uint256 kwrId = nti + i;
            string calldata itemId = itemIds[i];
            require(!itemIdMinted[itemId], "itemId is already minted");
            itemIdMinted[itemId] = true;
            emit TraitItemMint(itemId, kwrId);
            unchecked {
                i++;
            }
        }
    }

    function mintMulti(
        string[] calldata itemIds,
        uint256 collection, // 1 = kzg, 2 = kubz
        uint256 collectionTokenId,
        bytes calldata signature
    ) public {
        require(collection == 1 || collection == 2, "unsupported collection");

        string memory action = string.concat(
            "kwr-mint-multi/",
            Strings.toString(collection),
            "/",
            Strings.toString(collectionTokenId),
            "/",
            join(itemIds)
        );
        // console.log("contract");
        // console.log(action);
        checkValidityAlt(signature, action);

        IERC721 collectionContract = collection == 1
            ? kzgContract
            : kubzContract;
        require(
            collectionContract.ownerOf(collectionTokenId) == msg.sender,
            "Not owner of collection token"
        );
        address tba = erc6551Registry.account(
            erc6551AccountImplementation,
            block.chainid,
            address(collectionContract),
            collectionTokenId,
            0
        );

        uint256 nti = _nextTokenId();
        safeMint(tba, itemIds.length);
        for (uint256 i = 0; i < itemIds.length; ) {
            uint256 kwrId = nti + i;
            string calldata itemId = itemIds[i];
            require(!itemIdMinted[itemId], "itemId is already minted");
            itemIdMinted[itemId] = true;
            emit TraitItemMint(itemId, kwrId);
            unchecked {
                i++;
            }
        }
    }

    function mint(
        string calldata itemId,
        uint256 collection, // 1 = kzg, 2 = kubz
        uint256 collectionTokenId,
        bytes calldata signature
    ) external {
        require(!itemIdMinted[itemId], "itemId is already minted");
        require(collection == 1 || collection == 2, "unsupported collection");

        string memory action = string.concat(
            "kwr-mint/",
            Strings.toString(collection),
            "/",
            Strings.toString(collectionTokenId),
            "/",
            itemId
        );
        checkValidityAlt(signature, action);

        IERC721 collectionContract = collection == 1
            ? kzgContract
            : kubzContract;
        require(
            collectionContract.ownerOf(collectionTokenId) == msg.sender,
            "Not owner of collection token"
        );
        address tba = erc6551Registry.account(
            erc6551AccountImplementation,
            block.chainid,
            address(collectionContract),
            collectionTokenId,
            0
        );
        uint256 tokenId = _nextTokenId();
        itemIdMinted[itemId] = true;
        safeMint(tba, 1);
        emit TraitItemMint(itemId, tokenId);
    }

    function createAccounts(
        uint256 collection, // 1 = kzg, 2 = kubz
        uint256[] calldata collectionTokenIds,
        bytes calldata initData
    ) external {
        require(collection == 1 || collection == 2, "unsupported collection");
        address contractAddress = address(
            collection == 1 ? kzgContract : kubzContract
        );
        for (uint256 i = 0; i < collectionTokenIds.length; ) {
            erc6551Registry.createAccount(
                erc6551AccountImplementation,
                block.chainid,
                contractAddress,
                collectionTokenIds[i],
                0,
                initData
            );
            unchecked {
                i++;
            }
        }
    }

    // =============== Transfer & Locking ===============

    function preTransfer(uint256 _tokenId) internal {
        address owner = ownerOf(_tokenId);
        // IERC6551Account: the ERC-165 identifier for this interface is `0x400a0398`
        if (owner.supportsInterface(0x400a0398)) {
            (
                uint256 chainId,
                address tokenContract,
                uint256 tokenId
            ) = IERC6551Account(owner).token();
            // tell kzg/kubz to block transfer for X hours
            tokenKWRLockedUntil[tokenContract][tokenId] =
                block.timestamp +
                transferLockSeconds;
        }
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    )
        public
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(_from)
    {
        preTransfer(_tokenId);
        super.safeTransferFrom(_from, _to, _tokenId, data);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(_from)
    {
        preTransfer(_tokenId);
        super.transferFrom(_from, _to, _tokenId);
    }

    // =============== BASE URI ===============

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    // =============== Multi helpers ===============

    function getKWRLockStatusSimple(
        address contractAddress,
        uint256 collectionTokenId
    ) external view returns (uint256) {
        return tokenKWRLockedUntil[contractAddress][collectionTokenId];
    }

    function resetKWRLockStatus(
        address contractAddress,
        uint256 collectionTokenId
    ) external returns (uint256) {
        require(
            msg.sender == address(kubzContract) ||
                msg.sender == address(kzgContract)
        );
        tokenKWRLockedUntil[contractAddress][collectionTokenId] = 0;
    }

    function resetKWRLocksStatus(
        address contractAddress, // 1 = kzg, 2 = kubz
        uint256[] calldata collectionTokenIds
    ) external onlyOwner returns (uint256) {
        for (uint256 i = 0; i < collectionTokenIds.length; ) {
            tokenKWRLockedUntil[contractAddress][collectionTokenIds[i]] = 0;
            unchecked {
                i++;
            }
        }
    }

    function getKWRLockStatus(
        uint256 collection, // 1 = kzg, 2 = kubz
        uint256[] calldata collectionTokenIds
    ) external view returns (uint256[] memory) {
        require(collection == 1 || collection == 2, "unsupported collection");
        uint256[] memory part = new uint256[](collectionTokenIds.length);
        address contractAddress = address(
            collection == 1 ? kzgContract : kubzContract
        );
        for (uint256 i = 0; i < collectionTokenIds.length; ) {
            part[i] = tokenKWRLockedUntil[contractAddress][
                collectionTokenIds[i]
            ];
            unchecked {
                i++;
            }
        }
        return part;
    }

    function getTBAs(
        uint256 collection, // 1 = kzg, 2 = kubz
        uint256[] calldata collectionTokenIds
    ) public view returns (address[] memory) {
        require(collection == 1 || collection == 2, "unsupported collection");
        address[] memory part = new address[](collectionTokenIds.length);
        address contractAddress = address(
            collection == 1 ? kzgContract : kubzContract
        );
        for (uint256 i = 0; i < collectionTokenIds.length; ) {
            part[i] = erc6551Registry.account(
                erc6551AccountImplementation,
                block.chainid,
                contractAddress,
                collectionTokenIds[i],
                0
            );
            unchecked {
                i++;
            }
        }
        return part;
    }

    // // input: collection+collectionTokenIds
    // function tokensOfCollectionTokensMultiple(
    //     uint256 collection, // 1 = kzg, 2 = kubz
    //     uint256[] calldata collectionTokenIds,
    //     uint256 start,
    //     uint256 stop
    // ) external view returns (uint256[][] memory) {
    //     address[] memory tbas = getTBAs(collection, collectionTokenIds);
    //     uint256[][] memory part = new uint256[][](tbas.length);
    //     for (uint256 i = 0; i < tbas.length; i++) {
    //         part[i] = tokensOfOwnerIn(tbas[i], start, stop);
    //     }
    //     return part;
    // }

    struct TokenInfo {
        uint256 chainId;
        address tokenContract;
        uint256 tokenId;
    }

    function tbasToTokenInfo(
        address[] calldata tbas
    ) external view returns (TokenInfo[] memory) {
        TokenInfo[] memory part = new TokenInfo[](tbas.length);
        for (uint256 i = 0; i < tbas.length; i++) {
            (
                uint256 chainId,
                address tokenContract,
                uint256 tokenId
            ) = IERC6551Account(tbas[i]).token();
            part[i] = TokenInfo(chainId, tokenContract, tokenId);
        }
        return part;
    }

    // =============== IERC721xHelper ===============
    function ownerOfMultiple(
        uint256[] calldata tokenIds
    ) external view returns (address[] memory) {
        address[] memory part = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = ownerOf(tokenIds[i]);
        }
        return part;
    }
}