// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./_old/IERC721Receiver.sol";


contract BrianNFT is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable, IERC721ReceiverUpgradeable {

    using AddressUpgradeable for address;

    string public baseURI;
    string public suffix;

    uint256 public circulatingSupply;
    uint256 public maxSupply;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("Brian Nfts By Braindom", "BRIAN");
        __Ownable_init();
        __UUPSUpgradeable_init();
        suffix = ".json";
        maxSupply = 5000;
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function totalSupply() public view returns (uint256) {
        return circulatingSupply;
    }

    function remainingSupply() public view returns (uint256) {
        return maxSupply - circulatingSupply;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    "/",
                    StringsUpgradeable.toString(tokenId),
                    suffix
                )
            );
    }

    function migrate(address from, address owner, uint256[] calldata tokens) public {

        for (uint256 i = 0; i < tokens.length; i++) {
            bytes memory params = abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", address(owner), address(this), tokens[i]);
            from.functionCall(params);
        }

    }

    function mint(
        uint16 amount,
        address[] calldata to,
        uint256[] calldata tokenIds
    ) external onlyOwner availability(amount) {
        for (uint256 i = 0; i < amount; i++) {
            ++circulatingSupply;
            _safeMint(to[i], tokenIds[i]);
        }
    }

    function safeMint(address to) external onlyOwner availability(1) {
        _safeMint(to, ++circulatingSupply);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setSuffix(string memory extension) external onlyOwner {
        suffix = extension;
    }

    function withdraw() external onlyOwner {
        (bool isTransfered, ) = msg.sender.call{value: address(this).balance}(
            ""
        );
        require(isTransfered, "Transfer failed");
    }

    modifier availability(uint256 amount) {
        require(amount <= remainingSupply(), "Max supply reached");
        _;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override(IERC721ReceiverUpgradeable) returns (bytes4) {
        ++circulatingSupply;
        _safeMint(from, tokenId);
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}