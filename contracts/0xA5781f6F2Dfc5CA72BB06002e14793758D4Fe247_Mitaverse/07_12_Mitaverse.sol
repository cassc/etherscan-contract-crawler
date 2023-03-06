// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract Mitaverse is ERC721AUpgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;

    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public isReveal;
    string public baseURI;

    event Minted(address indexed to, uint256 indexed tokenId);

    struct MintInfo {
        address to;
        uint256 quantity;
    }

    function initialize(string memory baseURI_)
        public
        initializerERC721A
        initializer
    {
        __ERC721A_init("Mitaverse", "MITA");
        __Ownable_init();
        baseURI = baseURI_;
    }

    function migrationMint(address to, uint256 quantity)
        external
        payable
        onlyOwner
    {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Miterverse: Max supply reached"
        );
        _mint(to, quantity);
        emit Minted(to, quantity);
    }

    function bulkMigrationMint(MintInfo[] memory mintInfos)
        external
        payable
        onlyOwner
    {
        for (uint256 i = 0; i < mintInfos.length; i++) {
            require(
                totalSupply() + mintInfos[i].quantity <= MAX_SUPPLY,
                "Miterverse: Max supply reached"
            );
            _mint(mintInfos[i].to, mintInfos[i].quantity);
            emit Minted(mintInfos[i].to, mintInfos[i].quantity);
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function depositToken() public onlyOwner {
        for (uint256 i = 4545; i < 5001; i++) {
            IERC721AUpgradeable(address(this)).transferFrom(
                address(this),
                msg.sender,
                i
            );
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        super.tokenURI(tokenId);
        if (isReveal == 0) return string(abi.encodePacked(baseURI, "0"));
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function updateBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function reveal() external onlyOwner {
        isReveal = 1;
    }

    uint256[47] private __gap;
}