// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/extensions/ERC721AQueryable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.2/contracts/token/common/ERC2981.sol";

enum SalePhase {
    CLOSED,
    FREE,
    PAID,
    OPEN
}

error HashAlreadyUsed(bytes32 messageHash);
error HashDoesNotMatch(bytes32 messageHash);
error InsufficientPayment(uint256 weiSent, uint256 weiRequired, uint256 quantity);
error MaxSupplyReached();
error RejectZeroAddress();
error SaleNotActive(SalePhase salePhase, SalePhase attemptedPhase);
error SignerDoesNotMatchServer();
error InvalidQuantity(uint256 quantity);

contract DBYClubPass is ERC2981, ERC721AQueryable, Ownable {
    uint16 public constant MAX_SUPPLY = 15000;
    uint256 public constant RESERVED_SUPPLY = 2200;

    string public constant TOKEN_NAME = "DBY Club Pass";
    string public constant TOKEN_SYMBOL = "DBYPASS";

    string private tokenBaseURI;
    address private serverAddress;
    address private withdrawalAddress;

    mapping(bytes32 => bool) public usedHashes;

    SalePhase public salePhase = SalePhase.CLOSED;
    uint256 public mintPrice = 0.025 ether;

    // Require externally-owned accounts
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Not externally owned account");
        _;
    }

    constructor(string memory tokenBaseURI_, address serverAddress_, address withdrawalAddress_)
        ERC721A(TOKEN_NAME, TOKEN_SYMBOL)
    {
        tokenBaseURI = tokenBaseURI_;
        serverAddress = serverAddress_;
        withdrawalAddress = withdrawalAddress_;

        _mintERC2309(withdrawalAddress_, RESERVED_SUPPLY);
        _setDefaultRoyalty(withdrawalAddress_, 500);
    }

    /// @notice Set the token URI
    /// @param newTokenBaseURI New URI
    function setTokenBaseURI(string memory newTokenBaseURI) external onlyOwner {
        tokenBaseURI = newTokenBaseURI;
    }

    /// @dev View function used in ERC721A's 'tokenURI()' function
    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }

    /// @notice Set the current sale phase
    /// @param phase New sale phase
    function setSalePhase(SalePhase phase) external onlyOwner {
        salePhase = phase;
    }

    /// @notice Set the fee numerator for default royalty
    /// @param feeNumerator New fee numerator
    function setDefaultRoyalty(uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(withdrawalAddress, feeNumerator);
    }

    /// @notice Set new royalties
    /// @param price New mint price in wei
    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    /// @notice Get whether or not address has minted
    /// @param owner Address to check
    function hasMinted(address owner) external view returns (bool) {
        return _numberMinted(owner) > 0;
    }

    function batchMint(uint256 quantity) external onlyOwner {
        _safeMint(msg.sender, quantity);
    }

    /// @notice Free mint
    /// @param v Parity of the y-coordinate of r
    /// @param r X-coordinate of r
    /// @param s S value of the signature
    /// @param msgLen Length of the unhashed message
    function freeMint(bytes32 messageHash, uint8 v, bytes32 r, bytes32 s, uint256 msgLen)
        external
        onlyEOA
    {
        if (salePhase != SalePhase.FREE && salePhase != SalePhase.OPEN) {
            revert SaleNotActive(salePhase, SalePhase.FREE);
        }
        if (totalSupply() + 1 > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }
        if (!verifySignature(messageHash, v, r, s, msgLen, true)) {
            revert HashDoesNotMatch(messageHash);
        }
        if (usedHashes[messageHash]) {
            revert HashAlreadyUsed(messageHash);
        }
        usedHashes[messageHash] = true;
        _mint(msg.sender, 1);
    }

    /// @notice Paid mint
    /// @param v Parity of the y-coordinate of r
    /// @param r X-coordinate of r
    /// @param s S value of the signature
    /// @param msgLen Length of the unhashed message
    function mint(
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 msgLen,
        uint256 quantity
    ) external payable onlyEOA {
        if (salePhase != SalePhase.PAID && salePhase != SalePhase.OPEN) {
            revert SaleNotActive(salePhase, SalePhase.PAID);
        }
        if (quantity != 1 && quantity != 2) {
            revert InvalidQuantity(quantity);
        }
        if (totalSupply() + quantity > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }
        if (msg.value != mintPrice * quantity) {
            revert InsufficientPayment(msg.value, mintPrice, quantity);
        }
        if (!verifySignature(messageHash, v, r, s, msgLen, false)) {
            revert HashDoesNotMatch(messageHash);
        }
        if (usedHashes[messageHash]) {
            revert HashAlreadyUsed(messageHash);
        }
        usedHashes[messageHash] = true;
        _mint(msg.sender, quantity);
    }

    /// @notice Set the withdrawal address and set royalties to go to new withdrawal address
    /// @param _withdrawalAddress New address to send withdrawals
    function setWithdrawalAddress(address _withdrawalAddress) external onlyOwner {
        if (_withdrawalAddress == address(0)) {
            revert RejectZeroAddress();
        }
        withdrawalAddress = _withdrawalAddress;
        _setDefaultRoyalty(_withdrawalAddress, 500);
    }

    /// @notice Withdraw the ETH from the contract
    function withdrawETH() external onlyOwner {
        (bool sent,) = payable(withdrawalAddress).call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }

    /// @notice Verify the incoming hash from the server
    function verifySignature(
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 msgLen,
        bool isFree
    ) private view returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        bytes32 contractHash = keccak256(
            abi.encodePacked(
                prefix,
                Strings.toString(msgLen),
                string.concat(
                    Strings.toHexString(uint256(uint160(msg.sender)), 20), isFree ? "free" : "paid"
                )
            )
        );

        address signer = ecrecover(contractHash, v, r, s);
        if (signer != serverAddress) {
            revert SignerDoesNotMatchServer();
        }
        return contractHash == messageHash;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    /// @notice Set server address
    /// @param _serverAddress New server address
    function setServerAddress(address _serverAddress) external onlyOwner {
        serverAddress = _serverAddress;
    }
}