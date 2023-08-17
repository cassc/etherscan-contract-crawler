// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MintDeposit is ERC721, ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using ECDSA for bytes;

    bytes32 public constant ISSUE_REFUND_ROLE = keccak256("ISSUE_REFUND_ROLE");
    bytes32 public constant MANAGE_ALLOWANCES_ROLE =
        keccak256("MANAGE_ALLOWANCES_ROLE");
    bytes32 public constant START_STOP_DEPOSITS_ROLE =
        keccak256("START_STOP_DEPOSITS_ROLE");
    bytes32 public constant VOUCHING_ROLE =
        keccak256("VOUCHING_ROLE");

    IERC20 public usdc;

    uint public depositPriceUSDC;
    bool public canDeposit = true;
    bool public wasRefunded = false;

    Counters.Counter private _tokenIdCounter;
    mapping(uint => bool) private _isRefunded;
    string private _uri;

    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        address owner,
        address vouchingAddress,
        uint depositPriceUSDC_,
        IERC20 usdc_
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(ISSUE_REFUND_ROLE, owner);
        _grantRole(MANAGE_ALLOWANCES_ROLE, owner);
        _grantRole(START_STOP_DEPOSITS_ROLE, owner);
        _grantRole(VOUCHING_ROLE, vouchingAddress);
        
        _uri = uri;
        depositPriceUSDC = depositPriceUSDC_;
        usdc = usdc_;

        usdc.approve(owner, type(uint256).max);
    }

    function openDeposits() external onlyRole(START_STOP_DEPOSITS_ROLE) {
        require(!wasRefunded, "Cannot reopen deposits after refunds");
        canDeposit = true;
    }

    function stopDeposits() external onlyRole(START_STOP_DEPOSITS_ROLE) {
        canDeposit = false;
    }

    function approveAllowance(
        address spender,
        uint amount
    ) external onlyRole(MANAGE_ALLOWANCES_ROLE) {
        usdc.approve(spender, amount);
    }

    function refundDeposits(
        uint amountEachUSDC,
        uint startIndexInclusive,
        uint endIndexExclusive
    ) external onlyRole(ISSUE_REFUND_ROLE) {
        require(
            canDeposit == false,
            "Cannot start refund while deposits are open"
        );
        require(amountEachUSDC > 0, "Refunded amount must be greater than 0");
        require(
            usdc.balanceOf(address(this)) >=
                amountEachUSDC * (endIndexExclusive - startIndexInclusive),
            "Insufficent funds to refund"
        );
        wasRefunded = true;

        for (uint i = startIndexInclusive; i < endIndexExclusive; i++) {
            uint tokenId = tokenByIndex(i);
            if (_isRefunded[tokenId]) continue;

            _isRefunded[tokenId] = true;
            usdc.transfer(ownerOf(tokenId), amountEachUSDC);
        }
    }

    function mintDeposit(
        address to,
        uint quantity,
        uint64 timestamp,
        bytes memory signature
    ) public {
        require(canDeposit == true, "Deposits are closed");
        require(
            block.timestamp < timestamp + 1 hours,
            "Voucher expired"
        );
        require(
            _verifySignature(
                abi.encodePacked(timestamp, to),
                signature
            ),
            "Invalid voucher"
        );
        usdc.transferFrom(
            msg.sender,
            address(this),
            quantity * depositPriceUSDC
        );

        for (uint i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }

    function isRefunded(uint tokenId) public view returns (bool) {
        return _isRefunded[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _uri;
    }

    function _verifySignature(
        bytes memory data,
        bytes memory signature
    ) internal view returns (bool) {
        address recovered = data.toEthSignedMessageHash().recover(signature);
        return hasRole(VOUCHING_ROLE, recovered);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}