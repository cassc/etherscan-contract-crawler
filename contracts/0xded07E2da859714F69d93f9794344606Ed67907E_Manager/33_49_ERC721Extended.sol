// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./ERC721.sol";
import "../../interfaces/common/IERC1271.sol";
import "../../interfaces/common/IERC721Descriptor.sol";
import "../../interfaces/manager/IERC721Extended.sol";

abstract contract ERC721Extended is IERC721Extended, ERC721 {
    address public tokenDescriptor;
    address public tokenDescriptorSetter;

    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 private immutable nameHash;
    mapping(uint256 => uint256) public nonces;

    uint128 internal minted;
    uint128 internal burned;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        nameHash = keccak256(bytes(name_));
        tokenDescriptorSetter = msg.sender;
    }

    /*=====================================================================
     *                             TOKEN URI
     *====================================================================*/

    function tokenURI(uint256 tokenId) public view override(IERC721Metadata, ERC721) returns (string memory) {
        require(_exists(tokenId), "token not exist");
        return tokenDescriptor != address(0) ? IERC721Descriptor(tokenDescriptor).tokenURI(address(this), tokenId) : "";
    }

    function setTokenDescriptor(address descriptor) external {
        require(msg.sender == tokenDescriptorSetter);
        tokenDescriptor = descriptor;
    }

    function setTokenDescriptorSetter(address setter) external {
        require(msg.sender == tokenDescriptorSetter);
        tokenDescriptorSetter = setter;
    }

    /*=====================================================================
     *                              PERMIT
     *====================================================================*/

    function DOMAIN_SEPARATOR() public view returns (bytes32 domainSeperator) {
        domainSeperator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                nameHash,
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        require(deadline >= block.timestamp, "Permit Expired");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonces[tokenId]++, deadline))
            )
        );
        address owner = ownerOf(tokenId);
        if (Address.isContract(owner)) {
            require(IERC1271(owner).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e, "Unauthorized");
        } else {
            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0), "Invalid signature");
            require(recoveredAddress == owner, "Unauthorized");
        }
        _approve(spender, tokenId);
    }

    /*=====================================================================
     *                      TOKEN ID & TOTAL SUPPLY
     *====================================================================*/

    function totalSupply() public view virtual returns (uint256) {
        return minted - burned;
    }

    function _mintNext(address to) internal virtual returns (uint256 tokenId) {
        tokenId = minted + 1; // skip zero token id
        _mint(to, tokenId);
    }

    function latestTokenId() public view virtual returns (uint256 tokenId) {
        return minted;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from == address(0)) minted++;
        if (to == address(0)) burned++;
    }
}