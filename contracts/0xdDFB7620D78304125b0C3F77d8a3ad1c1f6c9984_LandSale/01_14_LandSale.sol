// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface/ILSale.sol";

contract LandSale is ReentrancyGuard, Pausable {
    using Strings for uint256;

    address public owner;
    address public land;

    bytes32 public root;

    mapping(address => bool) isBlacklisted;

    modifier isBlacklist(address _user) {
        require(!isBlacklisted[_user], "Blacklisted");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not a owner");
        _;
    }

    event Blacklisted(address account, bool value);
    event ChangeOwner(address oldOwner, address newOwner);
    event UpdateLandContract(address newLand);
    event BuyLand(
        address _beneficiary,
        uint256 x,
        uint256 y,
        uint256 _categories,
        string _uri
    );
    event Withdraw(address to, uint256 amount);

    constructor(
        address _land,
        address _owner,
        bytes32 _root
    ) {
        land = _land;
        owner = _owner;
        root = _root;
    }

    function setOwner(address _owner) external onlyOwner nonReentrant {
        owner = _owner;
        emit ChangeOwner(msg.sender, _owner);
    }
    
    function updateLandContract(address _land) external onlyOwner nonReentrant {
        land = _land;
        emit UpdateLandContract(land);
    }

    function blacklistMalicious(address account, bool value)
        external
        onlyOwner
        nonReentrant
    {
        isBlacklisted[account] = value;
        emit Blacklisted(account, value);
    }

    function pause() external onlyOwner nonReentrant {
        _pause();
    }

    function unpaused() external onlyOwner nonReentrant {
        _unpause();
    }

    function setRoot(bytes32 _root) external onlyOwner nonReentrant
    {
        root = _root;
    }

    function buyLand(
        address _beneficiary,
        bytes32[] calldata _merkleProof,
        uint256 x,
        uint256 y,
        uint256 _categories,
        string memory _uri
    ) external payable nonReentrant whenNotPaused isBlacklist(_beneficiary) {
        bytes32 leafToCheck = keccak256(
            abi.encodePacked(
                x.toString(),
                ",",
                y.toString(),
                ",",
                msg.value.toString(),
                ",",
                _categories.toString(),
                ",",
                _uri
            )
        );
        require(
            MerkleProof.verify(_merkleProof, root, leafToCheck),
            "Incorrect proof"
        );

        ILSale(land).createLand(_beneficiary, x, y, _categories,_uri);

        emit BuyLand(_beneficiary, x, y, _categories,_uri);
    }

    function withdraw(address _address, uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        transferCoin(_address, _amount);
        emit Withdraw(_address, _amount);
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function transferCoin(address _address, uint256 _value) internal {
        (bool success, ) = _address.call{value: _value}("");
        require(success, "refund failed");
    }

    receive() external payable {}
}