// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721.sol";

contract BIGHEAD is ERC721, Ownable {
    using Strings for uint256;

    string private baseURI =
        "https://turquoise-far-hamster-713.mypinata.cloud/ipfs/QmQ6DUVPUB6Rz6ueWZAnmZJ3CgpH5d6qChZmyhSb2yuCfb/";
    string private baseContractURI =
        "https://turquoise-far-hamster-713.mypinata.cloud/ipfs/QmNbScXuYVwrfkdeH1PY4fBDTCVVbFu3ih2iLPFPWkdWvJ";
    uint256 internal _totalSupply;
    uint256 internal constant maxSupply = 5005;
    uint256 public price = 0.001 ether;

    uint256[maxSupply] internal indices;

    enum Status {
        PAUSE,
        PREMINT,
        MINT
    }
    Status public status;

    mapping(address => bool) whitelist;

    constructor() ERC721("BIGHEAD", "BH") {}

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function safeMint(address to, uint256 quantity) external payable {
        _safeMint(to, quantity);
    }

    function _safeMint(address to, uint256 quantity) internal override {
        require(status != Status.PAUSE, "Mint paused");
        require(to != address(0), "ERC721: mint to the zero address");
        require(msg.value >= price * quantity, "Wrong amount");
        require(_totalSupply + quantity <= maxSupply, "No tokens left");
        require(quantity != 0, "quantity must be greater than 0");

        if (status == Status.PREMINT) {
            require(isWhitelisted(to), "Not whitelisted");
        }

        _mint(to, quantity);

        require(
            _checkOnERC721Received(address(0), to, _totalSupply, ""),
            "ERC721: transfer to non ERC721Receiver implementer"
        );

        if (msg.value > price * quantity) {
            payable(msg.sender).transfer(msg.value - price * quantity);
        }
    }

    function _mint(address to, uint256 quantity) internal override {
        for (uint256 i; i < quantity; i++) {
            uint256 _id = _generateRandomId(i);
            require(!_exists(_id), "ERC721: token already minted");

            _owners[_id] = to;
            emit Transfer(address(0), to, _id);
        }

        unchecked {
            _balances[to] += quantity;
            _totalSupply += quantity;
        }
    }

    function _generateRandomId(uint256 i) private returns (uint256) {
        uint256 totalSupply_ = _totalSupply;
        uint256 totalSize = maxSupply - (totalSupply_ + i);
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    totalSupply_ + i,
                    msg.sender,
                    block.prevrandao,
                    block.timestamp
                )
            )
        ) % totalSize;
        uint256 value = 0;

        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            indices[index] = totalSize - 1; // Array position not initialized, so use position
        } else {
            indices[index] = indices[totalSize - 1]; // Array position holds a value so use that
        }
        // Don't allow a zero index, start counting at 1
        return value + 1;
    }

    function changePrice(uint256 _price) external onlyOwner {
        require(_price > 0, "Incorrect price");
        price = _price;
    }

    function changeBaseURI(string calldata newURI) public onlyOwner {
        baseURI = newURI;
    }

    function changeBaseContractURI(string calldata newURI) public onlyOwner {
        baseContractURI = newURI;
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

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        _requireMinted(tokenId);

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function withdraw() external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}