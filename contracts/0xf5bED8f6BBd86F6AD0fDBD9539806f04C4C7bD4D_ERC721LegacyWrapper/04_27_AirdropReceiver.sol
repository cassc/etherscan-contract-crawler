// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/INftfiHub.sol";
import "../interfaces/IPermittedNFTs.sol";
import "../interfaces/IPermittedAirdrops.sol";
import "../interfaces/INftWrapper.sol";
import "../utils/ContractKeys.sol";

/**
 * @title AirdropReceiver
 * @author NFTfi
 * @dev
 */
contract AirdropReceiver is ERC721Enumerable, ERC721Holder, ERC1155Holder, Initializable, ReentrancyGuard {
    using Address for address;
    using SafeERC20 for IERC20;

    INftfiHub public immutable hub;

    // in the context of this contract the name of this is a bit confusing, this "wrapper" is the one that
    // knows how to transfer a type of nft
    address public nftTransferWrapper;
    address public beneficiary;
    address public wrappedNft;
    uint256 public wrappedNftId;

    bool private wrapping_;

    event Initialized(uint256 indexed tokenId);

    event NftWrapped(
        address indexed nftCollateralContract,
        uint256 indexed nftCollateralId,
        address indexed from,
        address beneficiary,
        address owner
    );
    event NftUnwrapped(
        address indexed nftCollateralContract,
        uint256 indexed nftCollateralId,
        address indexed to,
        address owner
    );

    modifier onlyOwner() {
        require(ownerOf(getTokenId()) == msg.sender, "Only owner");

        _;
    }

    modifier onlyOwnerOrBeneficiary() {
        require(ownerOf(getTokenId()) == msg.sender || msg.sender == beneficiary, "Only owner or beneficiary");

        _;
    }

    constructor(address _nftfiHub) ERC721("", "") {
        hub = INftfiHub(_nftfiHub);

        // grant ownership of implementation to deployer, this blocks initialization of this implementation
        _safeMint(msg.sender, getTokenId());
    }

    function getTokenId() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(address(this))));
    }

    function initialize(address _to) external initializer nonReentrant returns (uint256) {
        uint256 tokenId = getTokenId();
        _safeMint(_to, tokenId);

        emit Initialized(tokenId);

        return tokenId;
    }

    function wrap(
        address _from,
        address _beneficiary,
        address _nftCollateralContract,
        uint256 _nftCollateralId
    ) external onlyOwner {
        require(wrappedNft == address(0), "already wrapping");
        require(_from != address(0), "from is zero address");
        require(_beneficiary != address(0), "beneficiary is zero address");
        require(_nftCollateralContract != address(0), "nftCollateralContract is zero address");

        wrapping_ = true;

        nftTransferWrapper = IPermittedNFTs(hub.getContract(ContractKeys.PERMITTED_NFTS)).getNFTWrapper(
            _nftCollateralContract
        );

        _transferNFT(nftTransferWrapper, _from, address(this), _nftCollateralContract, _nftCollateralId);

        beneficiary = _beneficiary;
        wrappedNft = _nftCollateralContract;
        wrappedNftId = _nftCollateralId;

        emit NftWrapped(_nftCollateralContract, _nftCollateralId, _from, _beneficiary, msg.sender);

        wrapping_ = false;
    }

    function unwrap(address _receiver) external onlyOwner {
        require(wrappedNft != address(0), "not wrapping");

        _transferNFT(nftTransferWrapper, address(this), _receiver, wrappedNft, wrappedNftId);

        emit NftUnwrapped(wrappedNft, wrappedNftId, _receiver, msg.sender);

        beneficiary = address(0);
        wrappedNft = address(0);
        wrappedNftId = 0;
        nftTransferWrapper = address(0);
    }

    function pullAirdrop(address _target, bytes calldata _data) external nonReentrant onlyOwnerOrBeneficiary {
        require(
            IPermittedAirdrops(hub.getContract(ContractKeys.PERMITTED_AIRDROPS)).isValidAirdrop(
                abi.encode(_target, _getSelector(_data))
            ),
            "Invalid Airdrop"
        );

        _target.functionCall(_data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC1155Receiver)
        returns (bool)
    {
        return _interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(_interfaceId);
    }

    /**
     * @notice used by the owner account to be able to drain ERC20 tokens received as airdrops
     * for the locked  collateral NFT-s
     * @param tokenAddress - address of the token contract for the token to be sent out
     * @param receiver - receiver of the token
     */
    function drainERC20Airdrop(address tokenAddress, address receiver) external onlyOwner {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        require(amount > 0, "no tokens owned");
        tokenContract.safeTransfer(receiver, amount);
    }

    /**
     * @notice used by the owner account to be able to drain ERC721 tokens received as airdrops
     * for the locked  collateral NFT-s
     * @param tokenAddress - address of the token contract for the token to be sent out
     * @param tokenId - id token to be sent out
     * @param receiver - receiver of the token
     */
    function drainERC721Airdrop(
        address tokenAddress,
        uint256 tokenId,
        address receiver
    ) external onlyOwner {
        require(wrappedNft != tokenAddress && tokenId != wrappedNftId, "token is wrapped");
        IERC721 tokenContract = IERC721(tokenAddress);
        tokenContract.safeTransferFrom(address(this), receiver, tokenId);
    }

    /**
     * @notice used by the owner account to be able to drain ERC1155 tokens received as airdrops
     * for the locked  collateral NFT-s
     * @param tokenAddress - address of the token contract for the token to be sent out
     * @param tokenId - id token to be sent out
     * @param receiver - receiver of the token
     */
    function drainERC1155Airdrop(
        address tokenAddress,
        uint256 tokenId,
        address receiver
    ) external onlyOwner {
        require(wrappedNft != tokenAddress && tokenId != wrappedNftId, "token is wrapped");
        IERC1155 tokenContract = IERC1155(tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this), tokenId);
        require(amount > 0, "no nfts owned");
        tokenContract.safeTransferFrom(address(this), receiver, tokenId, amount, "");
    }

    function _transferNFT(
        address _nftTransferWrapper,
        address _sender,
        address _recipient,
        address _nftCollateralContract,
        uint256 _nftCollateralId
    ) internal {
        _nftTransferWrapper.functionDelegateCall(
            abi.encodeWithSelector(
                INftWrapper(_nftTransferWrapper).transferNFT.selector,
                _sender,
                _recipient,
                _nftCollateralContract,
                _nftCollateralId
            ),
            "NFT was not successfully transferred"
        );
    }

    function _getSelector(bytes memory _data) internal pure returns (bytes4 selector) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            selector := mload(add(_data, 32))
        }
    }

    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        // owner can only send with the intention of wrapping
        if (ownerOf(getTokenId()) == _from && !wrapping_) {
            require(wrappedNft == address(0), "already wrapping");

            address _beneficiary = abi.decode(_data, (address));
            require(_beneficiary != address(0), "beneficiary is zero address");

            // sender is the nftCollateral contract
            _receiveAndWrap(_from, _beneficiary, msg.sender, _tokenId);
        }
        // otherwise it is considered an airdrop
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address _from,
        uint256 _id,
        uint256,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        // owner can only send with the intention of wrapping
        if (ownerOf(getTokenId()) == _from && !wrapping_) {
            require(wrappedNft == address(0), "already wrapping");

            address _beneficiary = abi.decode(_data, (address));
            require(_beneficiary != address(0), "beneficiary is zero address");

            // sender is the nftCollateral contract
            _receiveAndWrap(_from, _beneficiary, msg.sender, _id);
        }
        // otherwise it is considered an airdrop

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        // owner can only send with the intention of wrapping
        if (ownerOf(getTokenId()) == _from && !wrapping_) {
            require(wrappedNft == address(0), "already wrapping");
            require(_ids.length > 1, "only 0 allowed");

            address _beneficiary = abi.decode(_data, (address));
            require(_beneficiary != address(0), "beneficiary is zero address");

            // sender is the nftCollateral contract
            _receiveAndWrap(_from, _beneficiary, msg.sender, _ids[0]);
        }
        // otherwise it is considered an airdrop

        return this.onERC1155BatchReceived.selector;
    }

    function _receiveAndWrap(
        address _from,
        address _beneficiary,
        address _nftCollateralContract,
        uint256 _nftCollateralId
    ) internal {
        nftTransferWrapper = IPermittedNFTs(hub.getContract(ContractKeys.PERMITTED_NFTS)).getNFTWrapper(
            _nftCollateralContract
        );

        require(nftTransferWrapper != address(0), "bft not permitted");

        beneficiary = _beneficiary;
        wrappedNft = _nftCollateralContract;
        wrappedNftId = _nftCollateralId;

        emit NftWrapped(_nftCollateralContract, _nftCollateralId, _from, _beneficiary, _from);
    }
}