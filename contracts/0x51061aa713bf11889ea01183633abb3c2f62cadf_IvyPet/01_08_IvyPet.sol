// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/IERC721A.sol";

contract IvyPet is ERC721A, ERC721AQueryable, Ownable {
    address public distributor;
    string public baseURI;
    string public preRevealedURI;
    bool public isRevealed;

    mapping(uint256 => bool) superUpgrade;
    mapping(uint256 => bool) megaUpgrade;
    mapping(uint256 => bool) nonUpgradable;

    uint8 public SUPER_SERUM_COUNT = 1;
    uint8 public MEGA_SERUM_COUNT = 5;

    error InvalidSerumCount(uint8 _count);

    enum UpgradeType {
        SUPER,
        MEGA
    }

    event Upgrade(
        address indexed _contract,
        uint256 indexed _tokenId,
        address _burner,
        uint8 _serumCount
    );

    constructor(string memory _token, string memory _tokenName)
        ERC721A(_token, _tokenName)
    {}

    // ==== MINT ====

    function teamMint(uint256 quantity) external onlyOwner {
        _mint(msg.sender, quantity);
    }

    function mint(uint256 _quantity, address _minter) external onlyDistributor {
        _mint(_minter, _quantity);
    }

    // ==== UPGRADE ====

    function upgrade(uint256[] calldata _tokenIds, uint8 _serumCount)
        external
        onlyDistributor
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(ownerOf(tokenId) == tx.origin, "You do not own this token");
            require(!nonUpgradable[tokenId], "Token is non-upgradable");
            if (_serumCount == SUPER_SERUM_COUNT) {
                require(!superUpgrade[tokenId], "Already upgraded to super");
            } else if (_serumCount == MEGA_SERUM_COUNT) {
                require(!megaUpgrade[tokenId], "Already upgraded to mega");
            } else {
                revert InvalidSerumCount(_serumCount);
            }
            emit Upgrade(address(this), tokenId, tx.origin, _serumCount);
        }
    }

    // ==== SETTERS ====

    function setPrerevealedURI(string calldata _uri) public onlyOwner {
        preRevealedURI = _uri;
    }

    function setDistributor(address _address) public onlyOwner {
        distributor = _address;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setNonUpgradable(
        uint256[] calldata _nonUpgradable,
        bool[] calldata _values
    ) external onlyOwner {
        for (uint256 i = 0; i < _nonUpgradable.length; i++) {
            nonUpgradable[_nonUpgradable[i]] = _values[i];
        }
    }

    function setIsRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    function setSerumBurnCost(uint8 _super, uint8 _mega) external onlyOwner {
        SUPER_SERUM_COUNT = _super;
        MEGA_SERUM_COUNT = _mega;
    }

    // ===== UTILS =====

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        if (!isRevealed) return preRevealedURI;

        return
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")
            );
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    modifier onlyDistributor() {
        require(msg.sender == distributor, "Only can be called by distributor");
        _;
    }
}