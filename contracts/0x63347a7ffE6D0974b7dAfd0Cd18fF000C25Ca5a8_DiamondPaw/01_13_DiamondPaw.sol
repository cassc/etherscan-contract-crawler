// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DiamondPaw contract
 */
contract DiamondPaw is ERC721Enumerable, Ownable {

    string private baseURI;
    bool public mintIsActive;
    bool public transferAllowed;
    uint256 public mintIndex;
    mapping(address => bool) public minted;
    mapping(uint256 => uint256) public phase;

    address private admin = 0xC2A3b684Df069d75Cc531fB043C897A651F52d2a;

    string public constant CONTRACT_NAME = "Diamond Paw";
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant MINT_TYPEHASH = keccak256("Mint(address user,uint256 phaseIndex)");

    constructor() ERC721("DiamondPaw", "DiamondPaw") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * Get the array of token for owner.
     */
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function setTransferAllowed() external onlyOwner {
        transferAllowed = !transferAllowed;
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    /**
     * Mint Token by owner
     */
    function reserveByOwner(address _to, uint256 phaseIndex) external onlyOwner {
        require(_to != address(0), "Invalid address to reserve.");
        require(phaseIndex > 0, "Invalid index");

        phase[mintIndex] = phaseIndex;
        _safeMint(_to, mintIndex++);
    }

    /**
    * Mints tokens
    */
    function mint(address user, uint256 phaseIndex, uint8 v, bytes32 r, bytes32 s) external {
        require(mintIsActive, "Not active");
        require(!minted[user], "Already minted");
        require(phaseIndex > 0, "Invalid index");

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(CONTRACT_NAME)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(MINT_TYPEHASH, user, phaseIndex));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        minted[user] = true;
        phase[mintIndex] = phaseIndex;
        _safeMint(user, mintIndex++);
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(transferAllowed, "DiamondPaw: transfer is not allowed");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(transferAllowed, "DiamondPaw: transfer is not allowed");
        super.safeTransferFrom(from, to, tokenId, _data);
    }
}