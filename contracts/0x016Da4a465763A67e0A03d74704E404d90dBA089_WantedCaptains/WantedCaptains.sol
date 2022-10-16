/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.14;






interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract WantedCaptains is Context, Ownable, IERC721Receiver {
    
    IERC721 mainContract;

    mapping(uint256 => bytes32[]) private captainHashes;
    mapping(uint256 => mapping(bytes32 => bool)) private captainValidHashes;

    mapping(uint256 => bool) public claimedCaptains;
    
    constructor() {
        addCaptainHash(1, 0, 0x41b9198408a07af4da06f4203fe5d41c71e6d04e01403fd9232973abcc5eefc2);
        addCaptainHash(1, 0, 0x9da1376487e59f6b8117f706415c72845afe65557f69fff44c906d9dc75b5b22);
        addCaptainHash(1, 0, 0xbd2b97b01ccf39ecd99da996dc4330e41504a4a092e76b7c8d09953beb70fc47);
        addCaptainHash(1, 0, 0xcb8e1f46eb2ccff927776879e30f2753ec27fa17e0c0b452840922459463c14d);
        addCaptainHash(1, 1, 0x7f177d612926e5fad1dd9c0d719208f0b30f25ba2c231c6b8c05f6e8ddc8ba5e);
        addCaptainHash(1, 1, 0x9a0d239a5dcb53ae13d659ede41d53f07e548a4e3a76ad59588f297d10fd263e);
        addCaptainHash(1, 1, 0xddc7eb0f8511a0f63af37f29d2b5cba5e01ab5553430bf61296ddb11d785b0d9);
        addCaptainHash(1, 1, 0xe6c25a21a05950ddb9a85b3fa096e3c62d8e9661390e93b2474c3cdbc3ada027);
        addCaptainHash(2, 0, 0x63714b522068b079399afd4834170032c0a22e62fc1aee8bdad8843f1202c211);
        addCaptainHash(2, 0, 0x6eb0ad6044cf76a87cf25b48993bcd32b53387bd3a63df4ca1dcb29d04d4542c);
        addCaptainHash(2, 0, 0xdce44d2ef1b0e6ffe5467c163507e9d31b7040426f64e0630640c44407e89b28);
        addCaptainHash(2, 0, 0xf095e251041390ce1a2777ea6e160e06094db3222cfa80eddf6366c3c4f3cdde);
        addCaptainHash(2, 1, 0x0929e9ed839303a7aad74e11d8d6575e022d281e188baf219515ef4d290cb056);
        addCaptainHash(2, 1, 0x7ab41805ada096b59e9ac2044d4904c7309bb486975e88853364bc5d8ff58ec9);
        addCaptainHash(2, 1, 0xe77412b393815ab9ca71e1891ad224a2e76841052517811c454b6b29e474de8a);
        addCaptainHash(2, 1, 0xf1addb68281cbe3d83b1a82063f8c161766e6e1a0aed1e35673e39b015953d4a);
        addCaptainHash(3, 0, 0x4bb436f8b08214a70710c515e205a09a00e5d0f29b400aaf064db95d75db8327);
        addCaptainHash(3, 0, 0x574e7cdda9797125a208e2173e0a10dc42bb5fdecd46a7313cecb15ffa8a2117);
        addCaptainHash(3, 0, 0x880cb5f6f34ae8c8d484eba4a133a48997cf576a748290d765a716164dd32508);
        addCaptainHash(3, 0, 0xcc31ae65c0817ca72964cbb8ead8904e30566bb3e54bf4762faf0c2d6b1f67fc);
        addCaptainHash(3, 1, 0x30de01117d37b62acb63e33f11ce609e906d33159e2a3d92c3760a2ff631e803);
        addCaptainHash(3, 1, 0x3dacdef2ea19e108b88e44d32842e62fec7bdacd7f98b86c5d3b99c00b209529);
        addCaptainHash(3, 1, 0x8ef9a0a7d5c221779fe8ae9d6229ca94980f4c322ffa5d8bdeaa88ea86d0528a);
        addCaptainHash(3, 1, 0xd145776e16c6fbcc35ea3d480ebc8e6a58a04a50b0ecfe4462bdc4443c8d2aa8);
        addCaptainHash(4, 0, 0x11974f3df2d90366f2b1560dee71d07a3bdc0c7ff77cbd9b06b9d914106ab65a);
        addCaptainHash(4, 0, 0xbfe4ff7990b075cff56fabd5d8303dbf916875795f8ca98ecfd5653351e72e66);
        addCaptainHash(4, 0, 0xc98a9e30bedae7240c340822c5df6f0e9702e2d5c6e8e816072b90b66b8e201d);
        addCaptainHash(4, 0, 0xcbedb3ccde358fa44d85b0cc32c59157d0bcd7817777c717b2c7cfc4e5d518e5);
        addCaptainHash(4, 1, 0x0c850af2ed44187325d664945e771bb3efe066bac2aa6f89063c4aa81e392292);
        addCaptainHash(4, 1, 0xae94a5926201d863aca033a84206be5496390ec86bbc26078e334a9a71f56232);
        addCaptainHash(4, 1, 0xe70fdeacc2eac206d4f4fab013972fd44acebabc9f819dac48945820207b49a9);
        addCaptainHash(4, 1, 0xfb5c27e47140214de418518ecda1426bf2f5fcd0026ff8cf15fda6c5c47053b5);
        addCaptainHash(5, 0, 0x45ef7b55c04a04d246986cf77c924430970df227bd3168f22236f69fe8847e4a);
        addCaptainHash(5, 0, 0x825b99e1cc0c21aee0bfc2cf7635da7ee1a5684052cf79ee365be888df5d5d38);
        addCaptainHash(5, 0, 0xddecb56ea7e10ef9aa69c029b3435ba9b61740ca18c631e008c75bc5491fa7f0);
        addCaptainHash(5, 0, 0xe09d6cb69d879094c5af9ba3d508644e4dabc444ea00563dc6d4b2f2a17e4b84);
        addCaptainHash(5, 1, 0x0a0982cad8007b35acb29d71dc32fe29a7314ec572a9b2ce5dec21543e1620ec);
        addCaptainHash(5, 1, 0x81a9c1a0362c2f33e5dbb95f7db9ebc22f323891e45fb2836af667c2450bc3cf);
        addCaptainHash(5, 1, 0xa026dcc4b6e60813b77590992846c344a1f211fcf9e03a15c6276b5b319ba66b);
        addCaptainHash(5, 1, 0xbc4106efe2a42daf1bd32897c6896cc55b645a09f221542e2ec6ca450464541d);
        addCaptainHash(6, 0, 0x1f1ca4e0b34dd94dc7167f0478bd3caf81e9c45a94e556bd536eaf6f3a536e03);
        addCaptainHash(6, 0, 0x748d65f80c99b91d117fcc25ef16d96a637ef902b20f8a88b37fe56d16aded3c);
        addCaptainHash(6, 0, 0x9c2de03dea37a58900375303f7999fa8540385f7e74e682a49916a2ccf4b6d19);
        addCaptainHash(6, 0, 0xfc5ca89c6ac1517741874abe7ff324f2b4ed6f7aaa1a0cddd60df0f66eb23daf);
        addCaptainHash(6, 1, 0x830b329f0930a256085276af2385335791fec77eb67c62bd876b02c40a509b42);
        addCaptainHash(6, 1, 0xa088a3c717bfc13f8f74caf5d5283bf1a7763032fe34f3f5ea4f24f69ea87448);
        addCaptainHash(6, 1, 0xad9c73536c378e3e5435a4026464e9be0edcef972fb2b084fc67886a3b4d95be);
        addCaptainHash(6, 1, 0xf099bec5fbba302ed6a6c76b670d89cdb28f4def1e85f40e5c88da1d7f583f01);
        addCaptainHash(7, 0, 0x060fce1231d27447aeb9ef672552547b530d9e4dca4c9ea9886ddff537468636);
        addCaptainHash(7, 0, 0x0f9e73137f3e06f27e41b3543058b0ae7cfa3f58c40040d39aa4ea4793020ea7);
        addCaptainHash(7, 0, 0x336f13867f2a56ceb3bb52e390adc0cd9af4e54ed06728566b58bd89bcf504f7);
        addCaptainHash(7, 0, 0x9ac48b7d145c8c012b86994f0f3e7413f59c23e40ac6d3a56a19320db0f9eade);
        addCaptainHash(7, 1, 0x188a047bb4b638514d685996b7a1d960348f40bab2069cdd3479d8d65ad6311e);
        addCaptainHash(7, 1, 0x47bd5c88b1d41a3594f33db4ad5fd5064df0d9fc45cbe7307b81b5640eb1b7e0);
        addCaptainHash(7, 1, 0x499b863e7349680c3d88985abbbba8e7913cca88b6c7ea2ccbbafdf197713ac4);
        addCaptainHash(7, 1, 0x7c033eb4f59dfbb3e99596e378c92289f496aa2b7508e2001fcf9c29bf2cf23d);
        addCaptainHash(8, 0, 0x1e06f5adeb6e400a18fceedb5d1c8be5950d9b4bac0722862330f369f04d6ddb);
        addCaptainHash(8, 0, 0x2add5e788382e40ec86f6ecbf70f992c4189b7627b1dbed97b3e36ef6d627775);
        addCaptainHash(8, 0, 0x3f064e31b4f641f509d3a85ca25a3f14c710c2c9fae4f44ee773c3a4d5cd79d4);
        addCaptainHash(8, 0, 0x91cef15bdfb7b00415e88eb026ea14189536ed9474ede30b86b1ad7cb143a988);
        addCaptainHash(8, 1, 0x199ee3d925ad5740f423878a176a9fbf5df85d1ed281a7faf7b9e796350e2e30);
        addCaptainHash(8, 1, 0x7465a645837f790e477fa456c8becf89ac4a260a1f33955023c92e2ea114d7f7);
        addCaptainHash(8, 1, 0x9c4e7d4041f3e62927d6beff375ffc221ebd0c114f08cfe844711cd7af1b1786);
        addCaptainHash(8, 1, 0xb943b8e5f184ce3583530dd5b29baab90ef613f724f5dfbd500118446b7ef9ec);
        addCaptainHash(9, 0, 0x315ccf86e8ab84368e40dd6fe320eb4f3f5cd894fce9e4be9e25f09fb3ceaf57);
        addCaptainHash(9, 0, 0x387af437796bcaf0ef6f8d43795722b18d53b113e1555505761b9a8176572c94);
        addCaptainHash(9, 0, 0xe8357c5095db9937b6fa5e115912d18d866fe620430f0a70f0fc6813a92969da);
        addCaptainHash(9, 0, 0xf35822d7cb1623312b971efffe26d6076d4d4ff072bcb6607d2ccd89c783e221);
        addCaptainHash(9, 1, 0x62318debc68a2edf055112cf49b193c28941981673c456f2e7b6de9b07880e9d);
        addCaptainHash(9, 1, 0xd414dbf7b8a7c7cda3f91ae61e3643b106a720d63f0106c89a3a71b6161d32d9);
        addCaptainHash(9, 1, 0xd6c8cb029b338c19aafd7a7c7c4c083ad62514818b04b3ce25ee52f725ce312d);
        addCaptainHash(9, 1, 0xf03b00dd758421a377cd3c6d87501c612c6fe72f802b94571c14eac88c8e7bc4);
        addCaptainHash(10, 0, 0x586b3d414063501cdd2717645b28edcb6bf5acecce41c2f0a889084e16bc7e8a);
        addCaptainHash(10, 0, 0x911b5637ff2800671311565968162cb0b56465b00d216a93a9b7d270cd83bf40);
        addCaptainHash(10, 0, 0xbb5d896b497cbf7a1fbfd44cc0550b0b4f3f78bdbca9845fa43faaae5fa78c6d);
        addCaptainHash(10, 0, 0xf26b6cc2d5030cfd2c8f808e5327e44b327256230f07c41a0d204fdb0b893ef5);
        addCaptainHash(10, 1, 0x1e751197b6d3008746d07ed38ef49f996aa2c9a124e8230a53ff3d671a5ea833);
        addCaptainHash(10, 1, 0x2ed60c891f5e896d59a639644dc998c916a7883f5936d59bdd63837a5278bc68);
        addCaptainHash(10, 1, 0x434868e943d0b4bfa483986e9a57f724274ecf0bbb983c65d8c91531eb998ce4);
        addCaptainHash(10, 1, 0xc50895fd991ab11910232cc0b0fd1bb4c3f860a1a0de4f7ad3c144014a8d3f79);
    }

    function setMainContract(address mainContractAddress) public onlyOwner {
        mainContract = IERC721(mainContractAddress);
    }
    
    function addCaptainHash(uint248 captainId, uint8 groupId, bytes32 hash) private {
        // GroupID should be 0 or 1
        uint256 index = (captainId * 10) + groupId;
        
        captainHashes[index].push(hash);
        captainValidHashes[index][hash] = true;
    }

    function getCaptainHashes(uint248 captainId, uint8 groupId) public view returns (bytes32[] memory) {
        require(groupId < 9, "Group ID should be lower than 10");
        uint256 index = (captainId * 10) + groupId;

        return captainHashes[index];
    }

    function isValidSecret(uint248 captainId, uint8 groupId, uint256 tokenId, bytes32 secret) public view returns (bool) {
        require(groupId < 2, "Group ID should be 0 or 1");
        uint256 index = (captainId * 10) + groupId;

        bytes32 hash = keccak256(abi.encodePacked(tokenId, secret));

        return captainValidHashes[index][hash];
    }

    function claim(uint256 captainId, uint256 tokenId_0, bytes32 secret_0, uint256 tokenId_1, bytes32 secret_1) public {
        require(!claimedCaptains[captainId], "captain already claimed");
        require(mainContract.ownerOf(tokenId_0) == _msgSender(), "no owner of tokenId_0");
        require(mainContract.ownerOf(tokenId_1) == _msgSender(), "no owner of tokenId_1");

        require(isValidSecret(uint248(captainId), 0, tokenId_0, secret_0), "tokenId is not member of group 0 for captainId");
        require(isValidSecret(uint248(captainId), 1, tokenId_1, secret_1), "tokenId is not member of group 1 for captainId");

        // Mark the captain as claimed to avoid reentracies
        claimedCaptains[captainId] = true;

        // Starts captain transfer to claimer
        mainContract.safeTransferFrom(address(this), _msgSender(), captainId);
    }

    // This function is to be able to receive ERC721 tokens
    function onERC721Received(address, address, uint256, bytes calldata) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}