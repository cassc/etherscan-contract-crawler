// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//   ███    ███  ██████  ██    ██ ██ ███████ ███████ ██   ██  ██████  ████████ ███████   //
//   ████  ████ ██    ██ ██    ██ ██ ██      ██      ██   ██ ██    ██    ██    ██        //
//   ██ ████ ██ ██    ██ ██    ██ ██ █████   ███████ ███████ ██    ██    ██    ███████   //
//   ██  ██  ██ ██    ██  ██  ██  ██ ██           ██ ██   ██ ██    ██    ██         ██   //
//   ██      ██  ██████    ████   ██ ███████ ███████ ██   ██  ██████     ██    ███████   //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////

contract TitleSequenceFramesLR98 is ERC721A, IERC2981, Ownable {
    uint256 public immutable maxSupply;
    bool public isClaimActive;
    address public adminMinter;
    address public royaltyAddress;
    uint256 public royaltyShare10000;
    bytes32 public merkleRoot;
    mapping(address => bool) public tokenClaimed;

    string private baseTokenUri;
    string private baseExtension;

    constructor(
        string memory _baseUri,
        string memory _baseExtension,
        uint256 _maxSupply,
        address _owner,
        address _adminMinter,
        address _royaltyReceiver,
        uint256 _royaltyShare
    ) ERC721A("MovieShots - LR98 Title Sequence Frames", "LR98-FRAMES") {
        transferOwnership(_owner);
        baseTokenUri = _baseUri;
        baseExtension = _baseExtension;
        maxSupply = _maxSupply;
        adminMinter = _adminMinter;
        royaltyAddress = _royaltyReceiver;
        royaltyShare10000 = _royaltyShare;
    }

    modifier claimActive() {
        require(isClaimActive, "Claim not active");
        _;
    }

    modifier onlyAdminMinter() {
        require(adminMinter == msg.sender, "Caller is not the admin minter");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

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
        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(
                        baseTokenUri,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setBaseUriExtension(string memory _baseExtension)
        external
        onlyOwner
    {
        baseExtension = _baseExtension;
    }

    function setAdminMinter(address _adminMinter) external onlyOwner {
        adminMinter = _adminMinter;
    }

    function setClaimActive(bool _isClaimActive) external onlyOwner {
        isClaimActive = _isClaimActive;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setRoyaltyReceiver(address royaltyReceiver) external onlyOwner {
        royaltyAddress = royaltyReceiver;
    }

    function setRoyaltyShare(uint256 royaltyShare) external onlyOwner {
        royaltyShare10000 = royaltyShare;
    }

    function claim(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        claimActive
    {
        require(totalSupply() + _amount <= maxSupply, "Max supply exceeded");
        require((!tokenClaimed[msg.sender]), "Tokens already claimed");

        bytes32 node = keccak256(abi.encodePacked(msg.sender, _amount));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, node),
            "Invalid proof"
        );

        tokenClaimed[msg.sender] = true;
        _mint(msg.sender, _amount);
    }

    function adminMint(address recipient, uint256 quantity)
        external
        onlyAdminMinter
    {
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        _mint(recipient, quantity);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Non-existent token");
        return (royaltyAddress, (salePrice * royaltyShare10000) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }
}