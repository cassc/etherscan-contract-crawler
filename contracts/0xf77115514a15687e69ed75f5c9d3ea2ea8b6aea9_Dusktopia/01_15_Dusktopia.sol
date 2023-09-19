// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./interfaces/IDusktopia.sol";

/*
    ____             __   __              _      
   / __ \__  _______/ /__/ /_____  ____  (_)___ _
  / / / / / / / ___/ //_/ __/ __ \/ __ \/ / __ `/
 / /_/ / /_/ (__  ) ,< / /_/ /_/ / /_/ / / /_/ / 
/_____/\__,_/____/_/|_|\__/\____/ .___/_/\__,_/  
                               /_/               
*/

/// @author ItsCuzzo
/// @title ERC721 for Dusktopia

contract Dusktopia is IDusktopia, Ownable, ERC721AQueryable, PaymentSplitter {

    using ECDSA for bytes32;

    enum SaleStates {
        PAUSED,
        GOVERNOR,
        DUSKLIST,
        RESERVE,
        PUBLIC
    }

    SaleStates public saleState;

    string private _baseTokenURI;
    address private _signer;

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant PUBLIC_SUPPLY = 5500;
    uint256 public constant GOVERNOR_SUPPLY = 1000;
    uint256 public constant RESERVED_TOKENS = 55;

    uint256 public dusklistSupply = 4000;
    uint256 public tokenCost = 0.15 ether;
    uint256 public dusklistLimit = 2;
    uint256 public reserveLimit = 1;
    uint256 public publicLimit = 1;

    event Minted(address indexed receiver, uint256 quantity);

    constructor(
        address[] memory payees,
        uint256[] memory shares_
    ) ERC721A("Dusktopia", "DUSK") PaymentSplitter(payees, shares_) {}

    /// @notice Function used to mint a token during the `GOVERNOR` mint.
    function governorMint(bytes calldata signature) external payable {
        if (msg.sender != tx.origin) revert NonEOA();
        if (saleState != SaleStates.GOVERNOR) revert InvalidSaleState();
        if (_totalMinted() + 1 > GOVERNOR_SUPPLY) revert GovSupplyExceeded();
        if (msg.value != tokenCost) revert InvalidEtherAmount();
        if (_numberMinted(msg.sender) != 0) revert AlreadyClaimed();
        if (!_verifySignature(signature, 'GOVERNOR')) revert InvalidSignature();

        _mint(msg.sender, 1);

        emit Minted(msg.sender, 1);
    }

    /// @notice Function used to mint tokens during the `DUSKLIST` mint.
    function dusklistMint(uint256 quantity, bytes calldata signature) external payable {
        if (msg.sender != tx.origin) revert NonEOA();
        if (saleState != SaleStates.DUSKLIST) revert InvalidSaleState();
        if (_totalMinted() + quantity > dusklistSupply) revert DuskSupplyExceeded();
        if (msg.value != quantity * tokenCost) revert InvalidEtherAmount();
        if (_numberMinted(msg.sender) + quantity > dusklistLimit) revert OverWalletLimit();
        if (!_verifySignature(signature, 'DUSKLIST')) revert InvalidSignature();

        _mint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }

    /// @notice Function used to mint a token during the `RESERVE` mint.
    function reserveMint(uint256 quantity, bytes calldata signature) external payable {
        if (msg.sender != tx.origin) revert NonEOA();
        if (saleState != SaleStates.RESERVE) revert InvalidSaleState();
        if (quantity > reserveLimit) revert OverTokenTxnLimit();
        if (_totalMinted() + quantity > dusklistSupply) revert DuskSupplyExceeded();
        if (msg.value != quantity * tokenCost) revert InvalidEtherAmount();
        if (_numberMinted(msg.sender) != 0) revert AlreadyMinted();
        if (!_verifySignature(signature, 'RESERVE')) revert InvalidSignature();

        _mint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }

    /// @notice Function used to mint tokens during the `PUBLIC` mint.
    function publicMint(uint256 quantity, bytes calldata signature) external payable {
        if (msg.sender != tx.origin) revert NonEOA();
        if (saleState != SaleStates.PUBLIC) revert InvalidSaleState();
        if (quantity > publicLimit) revert OverTokenTxnLimit();
        if (_totalMinted() + quantity > PUBLIC_SUPPLY) revert PublicSupplyExceeded();
        if (msg.value != quantity * tokenCost) revert InvalidEtherAmount();
        if (!_verifySignature(signature, 'PUBLIC')) revert InvalidSignature();

        _mint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }

    /// @notice Function used to mint tokens free of charge to receiver.
    /// @param receiver Receiving address of the minted tokens.
    function teamMint(address receiver, uint256 quantity) external onlyOwner {
        if (_totalMinted() + quantity > MAX_SUPPLY) revert MaxSupplyExceeded();
        _mint(receiver, quantity);
    }

    /// @notice Function used to set a new sale state.
    /// @param newSaleState The new sale state value.
    function setSaleState(uint256 newSaleState) external onlyOwner {
        if (newSaleState > uint256(SaleStates.PUBLIC)) revert InvalidSaleState();
        saleState = SaleStates(newSaleState);
    }

    /// @notice Function used to set a new token URI.
    /// @param newBaseTokenURI The new URI to be used for token URI computation.
    function setBaseTokenURI(string memory newBaseTokenURI) external onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    /// @notice Function used to set a new `_signer` value.
    /// @param newSigner The new signer address.
    function setSigner(address newSigner) external onlyOwner {
        _signer = newSigner;
    }

    /// @notice Function used to set a new token cost.
    /// @param newTokenCost The new token amount in wei.
    /// @dev *pssst* https://eth-converter.com/
    function setTokenCost(uint256 newTokenCost) external onlyOwner {
        tokenCost = newTokenCost;
    }

    /// @notice Function used to set a new Dusklist token limit.
    function setDusklistLimit(uint256 newDusklistLimit) external onlyOwner {
        if (newDusklistLimit < 1) revert InvalidTokenAmount();
        dusklistLimit = newDusklistLimit;
    }

    /// @notice Function used to set a new reserve token limit.
    function setReserveLimit(uint256 newReserveLimit) external onlyOwner {
        if (newReserveLimit < 1) revert InvalidTokenAmount();
        reserveLimit = newReserveLimit;   
    }

    /// @notice Function used to set a new public token limit.
    function setPublicLimit(uint256 newPublicLimit) external onlyOwner {
        if (newPublicLimit < 1) revert InvalidTokenAmount();
        publicLimit = newPublicLimit;   
    }

    /// @notice Function used to modify the dusklist supply.
    function setDusklistSupply(uint256 newDusklistSupply) external onlyOwner {
        if (newDusklistSupply <= _totalMinted()) revert InvalidSupply();
        dusklistSupply = newDusklistSupply;
    }

    /// @notice Function used to get the current signer address.
    /// @return The current _signer value.
    function signer() external view returns (address) {
        return _signer;
    }

    /// @notice Function used to claim share revenue.
    /// @param account The account withdraw payment for.
    function release(address payable account) public override {
        if (msg.sender != account) revert WithdrawMismatch();
        super.release(account);
    }

    /// @notice Function used to override starting token ID.
    /// @return The starting token ID number.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Function used to override the baseURI return.
    /// @return The current _baseTokenURI value.
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Function used to verify a signature.
    /// @return Returns `true` if the signature is valid, `false` otherwise.
    function _verifySignature(
        bytes calldata signature,
        string memory phase
    ) internal view returns (bool) {
        return _signer == keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            bytes32(abi.encodePacked(msg.sender, phase))
        )).recover(signature);
    }

}