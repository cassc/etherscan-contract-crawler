// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./interfaces/IBasicMint.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Single1155 is ERC1155, Ownable, IBasicMint {
    uint256 private _totalSupply;
    uint256 public constant TOKEN_ID = 0;
    uint256 public immutable mintPrice;
    uint256 public immutable mintLimit;
    uint256 public maxSupply;
    bool public frozen;
    bool public mintActivated;
    mapping(address => uint256) public mintedByAccount;
    address private treasury;
    event TreasuryUpdated(address oldTreasury, address newTreasury);

    constructor(
        string memory tokenURI,
        uint256 _mp,
        uint256 _ml,
        uint256 _ms
    ) ERC1155(tokenURI) {
        treasury = _msgSender();
        if (_ms == 0) _ms = type(uint256).max;
        if (_ml == 0) _ml = _ms;
        mintPrice = _mp;
        mintLimit = _ml;
        maxSupply = _ms;
    }

    receive() external payable {
        revert("Accidental send prevented");
    }

    function mintActive() public view returns (bool) {
        return mintActivated && (_totalSupply < maxSupply);
    }

    function mintData()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (mintPrice, mintLimit, maxSupply);
    }

    function totalSupply(uint256 id) external view returns (uint256) {
        require(TOKEN_ID == id, "Invalid TOKEN_ID");
        return _totalSupply;
    }

    // Mint function
    function mint(uint256 quantity) external payable {
        require(mintActive(), "Sale is not active");
        require(msg.value >= mintPrice * quantity, "Not enough money");
        require(quantity + _totalSupply <= maxSupply, "Maximum supply reached");
        mintedByAccount[_msgSender()] += quantity;
        require(
            mintedByAccount[_msgSender()] <= mintLimit,
            "Exceeds mint limit per account"
        );
        _mint(_msgSender(), TOKEN_ID, quantity, "");
    }

    function sweepToTreasury() external {
        require(address(this).balance != 0, "Nothing to withdraw");
        // solhint-disable avoid-low-level-calls
        (bool success, ) = treasury.call{value: (address(this).balance)}("");
        require(success, "Transfer failed.");
    }

    function burn(
        address account,
        uint256 id,
        uint256 quantity
    ) external {
        require(id == TOKEN_ID, "Invalid TOKEN_ID");
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "Caller is not owner nor approved"
        );
        _burn(account, id, quantity);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory quantities,
        bytes memory data
    ) internal virtual override {
        if (from == address(0)) {
            _totalSupply += quantities[0];
        }
        if (to == address(0)) {
            _totalSupply -= quantities[0];
            maxSupply -= quantities[0];
        }
    }

    // Admin
    function toggleActive() external onlyOwner {
        mintActivated = !mintActivated;
    }

    function setURI(string memory _uri) external onlyOwner {
        require(!frozen, "Metadata is frozen");
        _setURI(_uri);
    }

    function freezeURI() external onlyOwner {
        frozen = true;
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != treasury, "Same treasury address");
        require(newTreasury != address(0), "Treasury cannot be zero address");
        emit TreasuryUpdated(treasury, newTreasury);
        treasury = newTreasury;
    }

    function adminMint(uint256 quantity, address target) external onlyOwner {
        require(quantity + _totalSupply <= maxSupply, "Maximum supply reached");
        _mint(target, TOKEN_ID, quantity, "");
    }
}