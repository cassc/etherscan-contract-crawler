// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC2981, IERC165} from "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {PaddedString} from "draup-utils/src/PaddedString.sol";
import {IRenderer} from "./IRenderer.sol";
import {IDelegationRegistry} from "delegation-registry/src/IDelegationRegistry.sol";

contract DraupMembershipERC721 is ERC721, Ownable, DefaultOperatorFilterer {
    uint256 public immutable MAX_SUPPLY;
    uint256 public constant ROYALTY = 750;
    address constant DELEGATION_REGISTRY = 0x00000000000076A84feF008CDAbe6409d2FE638B;
    bool public transfersAllowed = false;
    IRenderer public renderer;
    string public baseTokenURI;
    uint256 public nextTokenId;
    bytes32 public merkleRoot;

    // Mapping to track who used their allowlist spot
    mapping(address => bool) private _claimed;

    constructor(uint256 maxSupply, string memory baseURI) ERC721("DRAUP SEAL", "$EAL") {
        MAX_SUPPLY = maxSupply;
        baseTokenURI = baseURI;
    }

    error InvalidDelegate();
    error InvalidProof();
    error AlreadyClaimed();
    error MaxSupplyReached();
    error TransfersNotAllowed();

    function mintingAllowed(bytes32[] calldata merkleProof, address vault) public view returns (address) {
        address requester = msg.sender;
        if (vault != address(0)) {
            IDelegationRegistry delegateCash = IDelegationRegistry(DELEGATION_REGISTRY);
            bool isDelegateValid = delegateCash.checkDelegateForContract(msg.sender, vault, address(this));
            if (!isDelegateValid) {
                revert InvalidDelegate();
            }
            requester = vault;
        }
        if (nextTokenId >= MAX_SUPPLY) {
            revert MaxSupplyReached();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(requester, 1))));
        if (!MerkleProof.verify(merkleProof, merkleRoot, leaf)) {
            revert InvalidProof();
        }
        if (_claimed[requester]) {
            revert AlreadyClaimed();
        }
        return requester;
    }


    function mint(bytes32[] calldata merkleProof, address vault) public {
        address allowedMinter = mintingAllowed(merkleProof, vault);
        _claimed[allowedMinter] = true;
        nextTokenId++;
        _mint(allowedMinter, nextTokenId - 1);
    }

    // token trading is disabled initially but will be enabled by the owner
    function _beforeTokenTransfer(
        address from,
        address,
        uint256,
        uint256
    ) internal virtual override {
        if (!transfersAllowed && from != address(0)) {
            revert TransfersNotAllowed();
        }
    }

    // on-chain royalty enforcement integration
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // upgradeable token renderer based on web3-scaffold example by frolic.eth
    // https://github.com/holic/web3-scaffold/blob/main/packages/contracts/src/IRenderer.sol
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        if (address(renderer) != address(0)) {
            return renderer.tokenURI(tokenId);
        }
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    PaddedString.digitsToString(tokenId, 3),
                    ".json"
                )
            );
    }

    // Royalty info provided via EIP-2981
    // https://eips.ethereum.org/EIPS/eip-2981
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            _interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address, uint256)
    {
        return (address(this), (salePrice * ROYALTY) / 10000);
    }

    // Admin actions
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function enableTransfers() external onlyOwner {
        transfersAllowed = true;
    }

    function setRenderer(IRenderer _renderer) external onlyOwner {
        renderer = _renderer;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function withdrawAll() external {
        require(address(this).balance > 0, "Zero balance");
        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "Failed to withdraw");
    }

    function withdrawAllERC20(IERC20 token) external {
        token.transfer(owner(), token.balanceOf(address(this)));
    }
}