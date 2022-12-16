//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

contract MongenCollection is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ERC721AUpgradeable,
    ERC721ABurnableUpgradeable
{
    using StringsUpgradeable for uint256;

    string private _baseTokenURI;
    string private _contractURI;
    mapping(address => bool) public isMinter;

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory contractUri
    ) public initializerERC721A initializer {
        _baseTokenURI = baseTokenURI;
        _contractURI = contractUri;
        isMinter[msg.sender] = true;
        _mint(msg.sender, 1);
        __ERC721A_init(name, symbol);
        __ERC721ABurnable_init();
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    modifier onlyMinter() {
        require(isMinter[msg.sender], "no-minter-permission");
        _;
    }

    function contractURI() view public returns (string memory) {
        return _contractURI;
    }

    function updateBaseURI(string calldata _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    function updateContractURI(string calldata _uri) external onlyOwner {
        _contractURI = _uri;
    }

    function updateMinter(address _address, bool _status)
        external
        onlyOwner
    {
        isMinter[_address] = _status;
    }

    function mint(address _address, uint256 _quantity) external onlyMinter {
        _mint(_address, _quantity);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721: invalid token ID");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, _tokenId.toString(), ".json")
                )
                : "";
    }
}