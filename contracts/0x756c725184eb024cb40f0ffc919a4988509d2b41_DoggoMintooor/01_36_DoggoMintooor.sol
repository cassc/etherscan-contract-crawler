// SPDX-License-Identifier: CC-BY-NC-ND-1.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";

import "./UniversalPaymentReceiver.sol";

contract DoggoMintooor is
    ERC2771Context,
    ERC721,
    Ownable,
    Pausable,
    UniversalPaymentReceiver
{
    struct metadata {
        string url;
    }

    mapping(uint256 => metadata) public _metadata;
    uint256 public nextTokenId = 0;

    // $6.96 USDC denominated in WEI units.
    uint256 public mintingFee = 6960000000000000000;

    address public _trustedForwarder;

    struct NFTGate {
        address erc1155;
        uint256 tokenId;
    }

    address public gateErc1155;
    uint256 public gateTokenId;

    constructor(
        MinimalForwarder forwarder,
        PaymentSettings memory paymentSettings,
        NFTGate memory _gate
    ) ERC2771Context(address(forwarder)) ERC721("DoggoMintooor", "DMR") {
        _trustedForwarder = address(forwarder);
        _configurePaymentSettings(paymentSettings);
        _setNFTGate(_gate.erc1155, _gate.tokenId);
    }

    modifier onlyNFTHolder() {
        if (gateErc1155 != address(0)) {
            require(
                IERC1155(gateErc1155).balanceOf(_msgSender(), gateTokenId) > 0,
                "DogMoneyAuctionHouse: !Holding genesis key"
            );
        }
        _;
    }

    function _acceptMoneyAndMintFor(
        string memory _url,
        IERC20 token,
        bytes memory swapPath,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address to
    ) internal {
        require(bytes(_url).length > 0, "Doggomintoor: Empty URL");

        uint256 amountInReserveCurrency = _acceptReserveCurrency(
            token,
            swapPath,
            amountIn,
            amountOutMinimum
        );

        // Check minting fee sent
        require(
            amountInReserveCurrency >= mintingFee,
            "Doggomintoor: Incorrect minting fee"
        );

        uint256 balance = reserveCurrency.balanceOf(address(this));
        reserveCurrency.transfer(fundsReceiver, balance);

        // Mint NFT to caller
        _metadata[nextTokenId].url = _url;
        _mint(to, nextTokenId);

        // Track token ID
        nextTokenId++;
    }

    function mint(
        string memory _url,
        IERC20 token,
        bytes memory swapPath,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external payable whenNotPaused onlyNFTHolder {
        _acceptMoneyAndMintFor(
            _url,
            token,
            swapPath,
            amountIn,
            amountOutMinimum,
            _msgSender()
        );
    }

    function mintFor(
        string memory _url,
        IERC20 token,
        bytes memory swapPath,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address to
    ) external payable whenNotPaused onlyNFTHolder {
        _acceptMoneyAndMintFor(
            _url,
            token,
            swapPath,
            amountIn,
            amountOutMinimum,
            to
        );
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);

        // Read custom tokenURI from metadata
        return _metadata[tokenId].url;
    }

    function setMintingFee(uint256 _mintingFee) external onlyOwner {
        mintingFee = _mintingFee;
    }

    function forceTokenURIChange(
        uint256 tokenId,
        string memory url
    ) external onlyOwner {
        _metadata[tokenId].url = url;
    }

    function forceTokenBurn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setFundsReceiver(
        address payable _fundsReceiver
    ) external onlyOwner {
        fundsReceiver = _fundsReceiver;
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    function _setNFTGate(address _erc1155, uint256 _tokenId) private {
        gateErc1155 = _erc1155;
        gateTokenId = _tokenId;
    }

    function setNFTGate(address _erc1155, uint256 _tokenId) external onlyOwner {
        _setNFTGate(_erc1155, _tokenId);
    }
}