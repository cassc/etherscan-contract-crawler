// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./interface/ITokunPass.sol";

/*
   ______      __                  ____                 
  /_  __/___  / /____  ______     / __ \____ ___________
   / / / __ \/ //_/ / / / __ \   / /_/ / __ `/ ___/ ___/
  / / / /_/ / ,< / /_/ / / / /  / ____/ /_/ (__  |__  ) 
 /_/  \____/_/|_|\__,_/_/ /_/  /_/    \__,_/____/____/  

*/

/// @title ERC721 for @Tokun_App
/// @author ItsCuzzo

contract TokunPass is ITokunPass, Ownable, ERC721AQueryable, PaymentSplitter {
    using ECDSA for bytes32;

    enum SaleStates {
        CLOSED,
        WHITELIST,
        RESERVE,
        PUBLIC
    }

    SaleStates public saleState;

    string private _baseTokenURI;
    address private _signer;

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant TOKEN_PRICE = 0.35 ether;
    uint256 public constant RESERVED_TOKENS = 50;

    modifier stateCheck(SaleStates state) {
        if (msg.sender != tx.origin) revert NonEOA();
        if (state != saleState) revert InvalidSaleState();
        if (msg.value != TOKEN_PRICE) revert InvalidEtherAmount();
        if (_numberMinted(msg.sender) != 0) revert AlreadyMinted();
        if (_totalMinted() + 1 > MAX_SUPPLY) revert SupplyExceeded();

        _;
    }

    constructor(
        address[] memory payees,
        uint256[] memory shares_,
        address receiver
    ) ERC721A("Tokun Pass", "TOKUN") PaymentSplitter(payees, shares_) {
        _mintERC2309(receiver, RESERVED_TOKENS);
    }

    /// @notice Function used to mint a token during the `WHITELIST` sale.
    /// @param signature A signed message digest.
    function whitelistMint(bytes calldata signature)
        external
        payable
        stateCheck(SaleStates.WHITELIST)
    {
        if (!_verifySignature('WHITELIST', signature)) revert InvalidSignature();

        _mint(msg.sender, 1);
    }

    /// @notice Function used to mint a token during the `RESERVE` sale.
    /// @param signature A signed message digest.
    function reserveMint(bytes calldata signature)
        external
        payable
        stateCheck(SaleStates.RESERVE)
    {
        if (!_verifySignature('RESERVE', signature)) revert InvalidSignature();

        _mint(msg.sender, 1);
    }

    /// @notice Function used to mint a token during the `PUBLIC` sale.
    function publicMint()
        external
        payable
        stateCheck(SaleStates.PUBLIC)
    {
        _mint(msg.sender, 1);
    }

    /// @notice Function used to set a new `_signer` value.
    /// @param newSigner The newly intended `_signer` value.
    function setSigner(address newSigner) external onlyOwner {
        _signer = newSigner;
    }

    /// @notice Function used to set a new `saleState` value.
    /// @param newSaleState The newly intended `saleState` value.
    /// @dev 0 = CLOSED, 1 = WHITELIST, 2 = RESERVE, 3 = PUBLIC
    function setSaleState(uint256 newSaleState) external onlyOwner {
        if (newSaleState > uint256(SaleStates.PUBLIC)) revert InvalidSaleState();
        saleState = SaleStates(newSaleState);
    }

    /// @notice Function used to set a new `_baseTokenURI` value.
    /// @param newBaseTokenURI The newly intended `_baseTokenURI` value.
    function setBaseTokenURI(string calldata newBaseTokenURI) external onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    /// @notice Function used to view the current `_signer` value.
    function signer() external view returns (address) {
        return _signer;
    }
    
    /// @notice Function used to release revenue share for `account`.
    /// @param account The desired `account` to release revenue for.
    function release(address payable account) public override {
        if (msg.sender != account) revert AccountMismatch();
        super.release(account);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _verifySignature(
        string memory phase,
        bytes memory signature
    ) internal view returns (bool) {
        return _signer == keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            bytes32(abi.encodePacked(msg.sender, phase))
        )).recover(signature);
    }

}