// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract I_AM_UKRAINIAN is ERC721, Ownable {
    using Strings for uint256;

    string private baseURI =
        "ipfs://QmS5m6LEM12to2DgFFEYtfNBWTfhyVeAdFyBJ2YoQutAcw/";
    string private baseContractURI =
        "ipfs://QmQLEudADKJhY48C7aR31JtE9neVuiYmbSSh9Wxs2PvcWB";
    uint256 internal currentIndex;
    uint256 internal maxSupply = 10000;
    uint256 public price = 0.01 ether;

    enum Status {
        PAUSE,
        PREMINT,
        MINT
    }
    Status public status;

    mapping(address => bool) whitelist;

    constructor() ERC721("I AM UKRAINIAN", "IAMU") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function changeBaseURI(string calldata newURI) public onlyOwner {
        baseURI = newURI;
    }

    function changeBaseContractURI(string calldata newURI) public onlyOwner {
        baseContractURI = newURI;
    }

    function totalSupply() public view virtual returns (uint256) {
        return currentIndex;
    }

    function safeMint(address to, uint256 quantity) external payable virtual {
        require(status != Status.PAUSE, "Mint paused");
        require(msg.value == price * quantity, "Wrong amount");
        require(currentIndex + quantity <= maxSupply, "No tokens left");

        if (status == Status.PREMINT) {
            require(isWhitelisted(to), "Not whitelisted");
        }

        _mint(to, quantity, "");
    }

    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 updatedIndex = currentIndex;
        require(to != address(0), "mint to the zero address");
        require(quantity != 0, "quantity must be greater than 0");

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if currentIndex + quantity > 1.56e77 (2**256) - 1
        unchecked {
            _balances[to] += quantity;

            require(
                _checkOnERC721Received(address(0), to, updatedIndex, _data),
                "ERC721A: transfer to non ERC721Receiver implementer"
            );

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                _owners[updatedIndex] = to;

                updatedIndex++;
            }

            currentIndex = updatedIndex;
        }
    }

    function changePrice(uint256 _price) external onlyOwner {
        require(_price > 0, "Incorrect price");
        price = _price;
    }

    function addToWhitelist(address[] calldata _users) external onlyOwner {
        require(_users.length > 0, "No one to add");
        uint256 len = _users.length;

        for (uint256 i = 0; i < len; ) {
            whitelist[_users[i]] = true;

            unchecked {
                i++;
            }
        }
    }

    function removeFromWhitelist(address[] calldata _users) external onlyOwner {
        require(_users.length > 0, "No one to remove");
        uint256 len = _users.length;

        for (uint256 i = 0; i < len; ) {
            whitelist[_users[i]] = false;

            unchecked {
                i++;
            }
        }
    }

    function isWhitelisted(address _user) public view returns (bool) {
        return whitelist[_user];
    }

    function changeStatus(Status _status) external onlyOwner {
        status = _status;
    }

    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        _requireMinted(tokenId);
        uint256 _tokenId = tokenId + 1;

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, _tokenId.toString(), ".json")
                )
                : "";
    }

    function withdraw() external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}