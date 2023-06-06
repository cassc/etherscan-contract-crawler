// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity ^0.8.0;

// @author: aerois.dev
// dsc array#0007

contract CouncilStone is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    address private signerAddress = 0xDC90586e77086E3A236ad5145df7B4bd7F628067;

    Counters.Counter private _tokenIds;

    uint256 public MAX_SUPPLY = 340;

    string public baseURI;

    bool public freeMintActivated = false;

    mapping(address => bool) public stoneClaimed;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    /// PUBLIC FUNCTIONS

    /**
    @dev Base URI setter
     */
    function _setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
    @dev Returns token URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory base = _baseURI();
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, tokenId.toString()))
                : "";
    }

    /// EXTERNAL FUNCTIONS

    /**
    @dev Active or deactivate whitelist sale
     */
    function flipFreeMintStatus() external onlyOwner {
        freeMintActivated = !freeMintActivated;
    }

    /**
    @dev Change signer address
     */
    function setSignerAddress(address _newAddress) external onlyOwner {
        require(
            _newAddress != address(0),
            "CouncilStone: The void is not your friend."
        );
        signerAddress = _newAddress;
    }

    /**
    @dev Free mint
     */
    function freeMint(bytes calldata signature) external nonReentrant {
        require(freeMintActivated, "CouncilStone: Mint not activated.");
        require(
            totalSupply() + 1 <= MAX_SUPPLY,
            "CouncilStone: No more stones left."
        );
        require(
            !stoneClaimed[msg.sender],
            "CouncilStone: Stone already claimed."
        );
        bytes32 messageHash = hashMessage(msg.sender);
        require(
            verifyAddressSigner(messageHash, signature),
            "CouncilStone: Invalid signature."
        );

        _mint(msg.sender);
        stoneClaimed[msg.sender] = true;
    }

    /**
    @dev Mint for giveways
     */
    function givewayMint(address _to, uint256 _nb) external onlyOwner {
        require(
            totalSupply() + _nb <= MAX_SUPPLY,
            "CouncilStone: No more stones left."
        );

        for (uint32 i = 0; i < _nb; i++) {
            _mint(_to);
        }
    }

    /// PRIVATE FUNCTIONS
    function verifyAddressSigner(bytes32 messageHash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return
            signerAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    function hashMessage(address sender) private pure returns (bytes32) {
        return keccak256(abi.encode(sender));
    }

    /// INTERNAL FUNCTIONS

    /**
    @dev Returns base token URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _mint(address _to) internal returns (uint256) {
        _tokenIds.increment();
        uint256 _tokenId = _tokenIds.current();
        _safeMint(_to, _tokenId);
        return _tokenId;
    }
}