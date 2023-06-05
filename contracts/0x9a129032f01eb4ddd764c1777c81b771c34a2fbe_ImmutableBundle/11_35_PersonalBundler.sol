// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "./NftfiBundler.sol";

/**
 * @title PersonalBundler
 * @author NFTfi
 * @dev ERC998 Top-Down Composable Non-Fungible Token that supports ERC721 children.
 */
contract PersonalBundler is NftfiBundler, Initializable, IERC1155Receiver {
    using SafeERC20 for IERC20;

    uint8 public constant bundleId = 1;
    address public lastBundleOwner;

    event Initialized(address owner);

    /**
     * @dev only runs when the master copy is deplyoed, when cloned then initializer is ran
     * @param _admin admin address capable of setting URI-s and pausing
     * @param _permittedNfts permitted nft-s contract of the loan system
     * @param _airdropFlashLoan airdrop flashloan contract deplyoed alongside
     */
    constructor(
        address _admin,
        address _permittedNfts,
        address _airdropFlashLoan
    ) NftfiBundler(_admin, "", "", "", _permittedNfts, _airdropFlashLoan) {
        //original implementation rendering it unusable
        safeMint(_admin);
    }

    /** @dev function enforcing that the caller is the bundle token owner */
    function onlyBundleOwner() internal view {
        require(ownerOf(bundleId) == msg.sender, "Only bundle owner");
    }

    /**
     * @dev sets up initial parameters after cloning
     *
     * @param _admin admin address capable of setting URI-s and pausing
     * @param _owner of the personal bundler
     * @param _customBaseURI - Base URI
     */
    function initialize(
        address _admin,
        address _owner,
        string memory _customBaseURI
    ) external initializer nonReentrant {
        _setOwner(_admin);
        _setBaseURI(_customBaseURI);
        safeMint(_owner);
        emit Initialized(_owner);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     * have to override, because cloning doesn't work for it
     */
    function name() public view virtual override returns (string memory) {
        return "NFTFi Personal Bundle";
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     * have to override, because cloning doesn't work for it
     */
    function symbol() public view virtual override returns (string memory) {
        return "PBNFI";
    }

    function safeMint(address _to) public override returns (uint256) {
        require(lastBundleOwner == address(0) || lastBundleOwner == msg.sender, "only last bundle owner");
        require(tokenCount == 0, "only 1 bundle");

        return super.safeMint(_to);
    }

    function burn() public {
        onlyBundleOwner();
        lastBundleOwner = msg.sender;
        require(totalChildContracts(bundleId) == 0, "bundle has to be empty");
        tokenCount -= 1;
        _burn(bundleId);
    }

    /**
     * @notice disabled here
     */
    function sendElementsToPersonalBundler(uint256, address) external virtual override {
        revert("already personal bundler");
    }

    /**
     * @dev Validates the data from a child transfer and receives it
     * @param _from The owner of the child token
     * @param _childContract The ERC721 contract of the child token
     * @param _childTokenId The token that is being transferred to the parent
     * @param _data Up to the first 32 bytes contains an integer which is the receiving parent tokenId
     */
    function _validateAndReceiveChild(
        address _from,
        address _childContract,
        uint256 _childTokenId,
        bytes memory _data
    ) internal virtual override {
        //CHECK DISABLED require(_data.length > 0, "data must contain tokenId to transfer the child token to");
        // if no data: airdrop
        if (_data.length > 0) {
            // convert up to 32 bytes of _data to uint256, owner nft tokenId passed as uint in bytes
            uint256 tokenId = _parseTokenId(_data);
            // 1 is the only existing valid token id, so all other data is an airdrop
            if (tokenId == bundleId) {
                _receiveChild(_from, tokenId, _childContract, _childTokenId);
            }
        }
    }

    /**
     * @notice used by the owner account to be able to drain ERC721 tokens received as airdrops
     * for the locked  collateral NFT-s
     * @param _tokenAddress - address of the token contract for the token to be sent out
     * @param _tokenId - id token to be sent out
     * @param _receiver - receiver of the token
     */
    function drainERC721Airdrop(
        address _tokenAddress,
        uint256 _tokenId,
        address _receiver
    ) external {
        onlyBundleOwner();
        IERC721 tokenContract = IERC721(_tokenAddress);
        require(childTokenOwner[_tokenAddress][_tokenId] == 0, "token is in bundle");
        require(tokenContract.ownerOf(_tokenId) == address(this), "nft not owned");
        tokenContract.safeTransferFrom(address(this), _receiver, _tokenId);
    }

    /**
     * @notice used by the owner account to be able to drain ERC1155 tokens received as airdrops
     * for the locked  collateral NFT-s
     * @param _tokenAddress - address of the token contract for the token to be sent out
     * @param _tokenId - id token to be sent out
     * @param _receiver - receiver of the token
     */
    function drainERC1155Airdrop(
        address _tokenAddress,
        uint256 _tokenId,
        address _receiver
    ) external {
        onlyBundleOwner();
        IERC1155 tokenContract = IERC1155(_tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this), _tokenId);
        require(amount > 0, "no nfts owned");
        tokenContract.safeTransferFrom(address(this), _receiver, _tokenId, amount, "");
    }

    /**
     * @notice used by the owner account to be able to drain ERC20 tokens received as airdrops
     * for the locked  collateral NFT-s
     * @param _tokenAddress - address of the token contract for the token to be sent out
     * @param _receiver - receiver of the token
     */
    function drainERC20Airdrop(address _tokenAddress, address _receiver) external {
        onlyBundleOwner();
        IERC20 tokenContract = IERC20(_tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        require(amount > 0, "no tokens owned");
        tokenContract.safeTransfer(_receiver, amount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(IERC165, NftfiBundler) returns (bool) {
        return _interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(_interfaceId);
    }

    /**
     *  @dev Handles the receipt of a single ERC1155 token type. This function is called at the end of a
     * `safeTransferFrom` after the balance has been updated.
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if allowed
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     *  @dev Handles the receipt of a multiple ERC1155 token types. This function is called at the end of a
     * `safeBatchTransferFrom` after the balances have been updated.
     *  @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if allowed
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}