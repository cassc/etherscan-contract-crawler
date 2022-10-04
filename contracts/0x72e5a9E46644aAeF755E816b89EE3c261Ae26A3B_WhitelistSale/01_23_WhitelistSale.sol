// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "./BaseSale.sol";
import "./interfaces/IWhitelist.sol";
import "./interfaces/IWhitelistMerkleTree.sol";

contract WhitelistSale is BaseSale {
    struct ConstructorArgs {
        address nft;
        uint256 price;
        uint256 allocation;
        uint256 maxTokenPurchase;
        uint256 premintReserved;
        address whitelist;
        address whitelistMT;
        address payable treasury;
    }

    // @dev WL status.
    bool public isWLEnabled;

    uint256 public immutable premintReserved;
    uint256 public preminted;
    uint256 public allocation;

    // @dev Merkle tree whitelist.
    address public whitelistMT;

    mapping(address => uint256) internal bought;

    event WhitelistMTSet(address);

    constructor(ConstructorArgs memory _data)
        BaseSale(_data.nft)
    {
        _defaultPrice = _data.price;
        allocation = _data.allocation;
        maxTokenPurchase = _data.maxTokenPurchase;
        premintReserved = _data.premintReserved;
        whitelist = _data.whitelist;
        whitelistMT = _data.whitelistMT;
        treasury = _data.treasury;

        isWLEnabled = true;
    }

    function buy(uint256 _amount, bytes32[] calldata _proof, bytes32 _root)
        external
        payable
        checkStatus
        onlyAfterPremint
    {
        if (isWLEnabled) {
            if (_proof.length == 0 && _root == bytes32("")) {
                require(
                    IWhitelist(whitelist).isWhitelisted(msg.sender),
                    "Not whitelisted"
                );
            } else {
                require(
                    IWhitelistMerkleTree(whitelistMT).isRootExists(_root),
                    "Unverified root"
                );
                require(
                    IWhitelistMerkleTree(whitelistMT)
                    .isWhitelisted(
                        _proof,
                        _root,
                        keccak256(abi.encodePacked(msg.sender))
                    ),
                    "Not whitelisted"
                );
            }
        }

        require(_amount != 0, "ZERO_BUY");
        require(allocation != 0, "SOLD");
        require(_amount <= allocation, "LOW_ALLOCATION");
        require(
            bought[msg.sender] + _amount <= maxTokenPurchase,
            "ACCOUNT_BUY_LIMIT"
        );

        allocation -= _amount;
        bought[msg.sender] += _amount;
        _buy(msg.sender, _amount, msg.value);
    }

    function premint(address _to, uint256 _amount)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(preminted + _amount <= premintReserved, "PREMINT_OVERFLOW");

        preminted += _amount;
        _mint(_to, _amount);
    }

    // todo: add setters for whitelist

    function setWhitelistMT(address _whitelistMT) external onlyRole(ADMIN_ROLE) {
        whitelistMT = _whitelistMT;
        emit WhitelistMTSet(_whitelistMT);
    }

    modifier onlyAfterPremint() {
        require(preminted == premintReserved, "PENDING_PREMINT");
        _;
    }
}